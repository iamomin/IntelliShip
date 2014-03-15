package IntelliShip::Controller::Customer::Order::Ajax;
use Moose;
use Data::Dumper;
use namespace::autoclean;

BEGIN { extends 'IntelliShip::Controller::Customer::Order','IntelliShip::Controller::Customer::Ajax'; }

=head1 NAME

IntelliShip::Controller::Customer::Order::Ajax - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    #$c->response->body('Matched IntelliShip::Controller::Customer::Order::Ajax in Customer::Order::Ajax.');

	my $params = $c->req->params;

	if ($params->{'type'} eq 'HTML')
		{
		$self->get_HTML;
		}
	elsif ($params->{'type'} eq 'JSON')
		{
		$self->get_JSON_DATA;
		}
}

sub get_HTML :Private
	{
	my $self = shift;
	my $c = $self->context;

	my $action = $c->req->param('action');
	if ($action eq 'display_international')
		{
		$self->set_international_details;
		}
	elsif ($c->req->param('action') eq 'get_special_service_list')
		{
		$self->get_special_service_list;
		}
	elsif ($c->req->param('action') eq 'get_carrier_service_list')
		{
		$self->get_carrier_service_list;
		}
	elsif ($c->req->param('action') eq 'third_party_delivery')
		{
		$self->get_third_party_delivery;
		}

	$c->stash(template => "templates/customer/order-ajax.tt");
	}

sub set_international_details
	{
	my $self = shift;
	my $c = $self->context;

	$c->stash->{INTERNATIONAL} = 1;
	$c->stash->{countrylist_loop} = $self->get_select_list('COUNTRY');
	$c->stash->{currencylist_loop} = $self->get_select_list('CURRENCY');
	$c->stash->{dimentionlist_loop} = $self->get_select_list('DIMENTION');
	}

sub get_special_service_list
	{
	my $self = shift;
	my $c = $self->context;

	my $CO = $self->get_order;
	my @special_services = $CO->assessorials;
	my %serviceHash =  map { $_->assname => 1 } @special_services;

	my $special_service_loop = $self->get_select_list('SPECIAL_SERVICE');

	#$c->log->debug("special_service_loop: " . Dumper($special_service_loop));
	#$c->log->debug("serviceHash: " . Dumper(%serviceHash));

	foreach my $dataHash (@$special_service_loop)
		{
		$dataHash->{'checked'} = 'CHECKED' if $serviceHash{$dataHash->{'value'}};
		}

	$c->stash->{SPECIAL_SERVICE} = 1;
	$c->stash->{specialservice_loop} = $special_service_loop;
	}

sub get_carrier_service_list
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	IntelliShip::Utils->hash_decode($params);

	$self->save_order;

	my $CO = $self->get_order;
	my $Contact = $self->contact;
	my $Customer = $self->customer;

	my $carrier_Details = $self->API->get_carrrier_service_rate_list($CO, $Contact, $Customer);
	#$c->log->debug("API get_carrrier_service_rate_list: " . Dumper($carrier_Details));

	my ($CS_list_1, $CS_list_2) = ([], []);
	foreach my $customerserviceid (keys %$carrier_Details)
		{
		my $CSData = $carrier_Details->{$customerserviceid};

		my @carrier_service = split(/ - /,$CSData->{'NAME'});
		my $carrier = $carrier_service[0];
		my $no_on_time;
		if ($carrier =~ /^\*+\s/)
			{
			#$c->log->debug("CSData: " . Dumper($CSData));
			$carrier =~ s/^\*+\s//;
			$no_on_time = 1;
			}

		my ($service, $estimated_date, $shipment_charge);
		if (@carrier_service == 2)
			{
			my @serviceParts = split(/-/, $carrier_service[1]);
			$service = $serviceParts[0];
			$shipment_charge = $serviceParts[1];
			}
		elsif (@carrier_service == 3)
			{
			my @serviceParts = split(/-/, $carrier_service[2]);
			$service = $carrier_service[1] . ' - ' . $serviceParts[0];
			$shipment_charge = $serviceParts[1];
			}

		if ($service =~ /\//)
			{
			my @service_est_date = split(/ /,$service);
			$estimated_date = pop(@service_est_date);
			$service = join(' ',@service_est_date);
			}

		my $detail_hash = {
						customerserviceid => $customerserviceid,
						carrier => $carrier,
						service => $service,
						no_on_time => $no_on_time,
						};

		$shipment_charge =~ s/\$// if $shipment_charge;
		$detail_hash->{'shipment_charge'} = $shipment_charge || '0';

		if ($CO->freightcharges == 0) # PREPAID
			{
			$c->stash->{IS_PREPAID} = 1;
			$detail_hash->{'delivery'} = $estimated_date;

			$detail_hash->{'days'} = IntelliShip::DateUtils->get_delta_days(IntelliShip::DateUtils->current_date, $estimated_date);

			my ($freightcharges,$fuelcharges) = (0,0);
			if ( defined $CSData->{'COST_DETAILS'} and $shipment_charge !~ /Quote/ )
				{
				## Step 1 :: Split cost of Individual package
				my $packages_cost = $CSData->{'COST_DETAILS'};
				$packages_cost =~ s/\'//g;

				my @individual_package_costs = split('::', $CSData->{'COST_DETAILS'});
				## Step 2 :: Break Down Cost
				foreach my $package_cost (@individual_package_costs)
					{
					next unless (length $package_cost > 0);
					my @CostBreakDown = split('-',$package_cost);
					$CostBreakDown[0] =~ s/\'// if $CostBreakDown[0];
					$CostBreakDown[1] =~ s/\'// if $CostBreakDown[1];

					$freightcharges += $CostBreakDown[0] if $CostBreakDown[0] and $CostBreakDown[0] =~ /\d+/;
					$fuelcharges += $CostBreakDown[1] if $CostBreakDown[1] and $CostBreakDown[1] =~ /\d+/;
					}
				}

			my ($totalquantity, $aggregateweight) = $self->get_estimated_quantity_and_weight;
			my $DVI_Charge = $self->calculate_declared_value_insurance($CSData->{'key'}, $aggregateweight);
			my $FI_Charge = $self->calculate_freight_insurance($CSData->{'key'}, $totalquantity);

			#$detail_hash->{'shipment_charge'} =~ s/Quote//;

			my $SHIPMENT_CHARGE_DETAILS = [];
			push(@$SHIPMENT_CHARGE_DETAILS, { text => 'Freight Charges' , value => '$' . sprintf("%.2f",$freightcharges) }) if $freightcharges;
			push(@$SHIPMENT_CHARGE_DETAILS, { text => 'Fuel Charges' , value => '$' . sprintf("%.2f",$fuelcharges) }) if $fuelcharges;
			push(@$SHIPMENT_CHARGE_DETAILS, { text => 'Declared Value Insurance' , value => '$' . sprintf("%.2f",$DVI_Charge) }) if $DVI_Charge;
			push(@$SHIPMENT_CHARGE_DETAILS, { text => 'Freight Insurance' , value => '$' . sprintf("%.2f",$FI_Charge) }) if $FI_Charge;
			#push(@$SHIPMENT_CHARGE_DETAILS, { hr => 1 });

			#$detail_hash->{'freight_charge'} = $freightcharges || '0';
			$detail_hash->{'freight_charge'} = sprintf("%.2f",($freightcharges || '0'));
			#$detail_hash->{'other_charge'} = ($fuelcharges+$DVI_Charge+$FI_Charge) || '0';
			$detail_hash->{'other_charge'} = sprintf("%.2f",(($fuelcharges+$DVI_Charge+$FI_Charge) || '0'));

			#if ($detail_hash->{'shipment_charge'} =~ /Quote/)
			#	{
			#	push(@$SHIPMENT_CHARGE_DETAILS, { text => 'Est Total Charge' , value => '<green>' . $detail_hash->{'shipment_charge'} . '</green>' });
			#	}
			#else
			#	{
			#	push(@$SHIPMENT_CHARGE_DETAILS, { text => 'Est Total Charge' , value => '<green>$' . sprintf("%.2f",$detail_hash->{'shipment_charge'}) . '</green>' });
			#	}

			$detail_hash->{'SHIPMENT_CHARGE_DETAILS'} = $SHIPMENT_CHARGE_DETAILS;
			#$c->log->debug("SHIPMENT_CHARGE_DETAILS :". Dumper($SHIPMENT_CHARGE_DETAILS));
			}

		($detail_hash->{'shipment_charge'} =~ /\d+/ and $detail_hash->{'shipment_charge'} > 0) ? push(@$CS_list_1, $detail_hash) : push(@$CS_list_2, $detail_hash);
		}

	$c->stash->{CARRIERSERVICE_LIST} = 1;
	$c->stash->{ONLY_TABLE} = 1;

	#$c->log->debug("CS_list_1: ". Dumper($CS_list_1));
	if ($CO->has_carrier_service_details)
		{
		my @selected_carrier_service = grep { uc($_->{carrier}) eq uc($CO->extcarrier) and uc($_->{service}) eq uc($CO->extservice) } @$CS_list_1;
		$selected_carrier_service[0]->{checked} = 1 if @selected_carrier_service;
		$c->stash->{CARRIER_SERVICE_LIST_LOOP} = [@selected_carrier_service];

		my $selected_carrier_html = $c->forward($c->view('Ajax'), "render", [ "templates/customer/order-ajax.tt" ]);
		#$c->log->debug("selected_carrier_html: ". $selected_carrier_html);
		$c->stash->{recommendedcarrierlist}  = $selected_carrier_html;

		$selected_carrier_html =~ s/CHECKED//;
		$c->stash->{transitdayscarrierlist}  = $selected_carrier_html;
		$c->stash->{viewallcarrierlist}      = $selected_carrier_html;
		}
	else
		{
		my @sortByDays = sort { $a->{days} <=> $b->{days} || $a->{shipment_charge} <=> $b->{shipment_charge} } @$CS_list_1;
		my @sortByCharge = sort { $a->{shipment_charge} <=> $b->{shipment_charge} || $a->{days} <=> $b->{days} } @$CS_list_1;

		$c->stash->{CARRIER_SERVICE_LIST_LOOP} = $self->get_recommened_carrier_service(\@sortByDays,\@sortByCharge,$CS_list_2);
		$c->stash->{recommendedcarrierlist} = $c->forward($c->view('Ajax'), "render", [ "templates/customer/order-ajax.tt" ]);
		$c->stash->{CARRIER_SERVICE_LIST_LOOP}->[0]->{checked} = 0;

		$c->stash->{CARRIER_SERVICE_LIST_LOOP} = [@sortByDays, @$CS_list_2];
		$c->stash->{transitdayscarrierlist} = $c->forward($c->view('Ajax'), "render", [ "templates/customer/order-ajax.tt" ]);

		$c->stash->{CARRIER_SERVICE_LIST_LOOP} = [@sortByCharge, @$CS_list_2];
		$c->stash->{viewallcarrierlist} = $c->forward($c->view('Ajax'), "render", [ "templates/customer/order-ajax.tt" ]);
		}

	$c->stash->{CARRIER_SERVICE_LIST_LOOP} = undef;
	$c->stash->{ONLY_TABLE} = 0;
	}

sub get_recommened_carrier_service :Private
	{
	my $self = shift;
	my $sortByDays = shift;
	my $sortByCharge = shift;
	my $otherCarriers = shift;

	my $c = $self->context;
	my $CO = $self->get_order;

	my $recommended = [];

	my $days_needed = IntelliShip::DateUtils->get_delta_days($CO->dateneeded);
	$days_needed *= -1 if $days_needed < 0;

	my @withindays = grep { $_->{days} <= $days_needed } @$sortByDays;
	#$c->log->debug("withindays: ". Dumper(@withindays));

	my @price_asc = sort { $a->{shipment_charge} <=> $b->{shipment_charge} } @withindays;

	push(@$recommended, $price_asc[0]) if @price_asc;
	push(@$recommended, $sortByCharge->[0]) unless (@$recommended);
	push(@$recommended, $otherCarriers->[0]) unless (@$recommended);

	$recommended->[0]->{checked} = 1;
	#$c->log->debug("recommended: ". Dumper($recommended));
	return $recommended;
	}

sub get_third_party_delivery :Private
	{
	my $self = shift;
	my $c = $self->context;

	if (my @thirdpartyaccts = $self->customer->thirdpartyaccts)
		{
		my $tp_list = [];
		foreach (@thirdpartyaccts)
			{
			push (@$tp_list, {
				thirdpartyacctid => $_->thirdpartyacctid,
				tpcompanyname => $_->tpcompanyname,
				tpdetails => $_->tpcompanyname.'|'.$_->tpaddress1.'|'.$_->tpaddress2.'|'.$_->tpcity.'|'.$_->tpstate.'|'.$_->tpzip.'|'.$_->tpcountry.'|'.$_->tpacctnumber
				});
			}
		$c->stash->{thirdpartyaccts_loop} = $tp_list;
		}

	$c->stash->{statelist_loop} = $self->get_select_list('US_STATES');
	$c->stash->{countrylist_loop} = $self->get_select_list('COUNTRY');
	$c->stash->{THIRD_PARTY_DELIVERY} = 1;
	}

sub get_estimated_quantity_and_weight
	{
	my $self = shift;
	my $CO = $self->get_order;

	my ($totalquantity, $aggregateweight);
	my @packages = $CO->package_details;
	foreach my $PackProData (@packages)
		{
		$totalquantity += $PackProData->quantity;
		$aggregateweight += $PackProData->weight;
		}

	return ($totalquantity,$aggregateweight);
	}

sub calculate_declared_value_insurance
	{
	my $self = shift;
	my $csid = shift;
	my $aggregateweight = shift;

	my $c = $self->context;
	my $Customer = $self->customer;

	my $DeclaredValue = 0;

	my $CSValueRef = $self->API->get_CS_shipping_values($csid, $Customer->customerid);

	my $DVI_Rate = $CSValueRef->{'decvalinsrate'} || 0;
	my $DVI_Min = $CSValueRef->{'decvalinsmin'} || 0;
	my $DVI_Max = $CSValueRef->{'decvalinsmax'} || 0;
	my $DVI_MaxPerlb = $CSValueRef->{'decvalinsmaxperlb'} || 0;
	my $DVI_MinCharge = $CSValueRef->{'decvalinsmincharge'} || 0;

	unless ($DVI_Max > 0)
		{
		$DVI_Max = $DVI_MaxPerlb * $aggregateweight if ($DVI_MaxPerlb > 0);
		}

	# If we don't have any DVI values at all, don't calculate a rate (even by default)
	return 0 if ( $DVI_Rate == 0 and $DVI_Max == 0 and $DVI_MinCharge == 0 );

	# Check to see if DVI charge is greater than the max for the service
	return("Not Available") if ($DeclaredValue > $DVI_Max);

	if ($DeclaredValue > 0 and $DVI_Rate > 0 and $DeclaredValue > $DVI_Min)
		{
		my $DeclaredValueCharge = $DVI_Rate * (($DeclaredValue - $DVI_Min)/100);
		$DeclaredValueCharge = $DVI_MinCharge if ($DeclaredValueCharge < $DVI_MinCharge);
		return $DeclaredValueCharge;
		}
	else
		{
		return 0;
		}
	}

sub calculate_freight_insurance
	{
	my $self = shift;
	my $csid = shift;
	my $totalquantity = shift;

	my $c = $self->context;
	my $Customer = $self->customer;

	my $FreightInsurance = 0;

	my $CSValueRef = $self->API->get_CS_shipping_values($csid, $Customer->customerid);
	my $FI_Rate = $CSValueRef->{'freightinsrate'};
	my $FI_Increment = $CSValueRef->{'freightinsincrement'};

	# If we don't have any FI values at all, don't calculate a rate (even by default)
	return 0 unless ($FI_Rate and $FI_Increment);

	if ($FreightInsurance > 0 and $FI_Rate > 0)
		{
		my $FreightInsuranceCharge = 0;

		if ($FI_Increment != -1)
			{
			$FreightInsuranceCharge = $FI_Rate * ($FreightInsurance/$FI_Increment);
			}
			else
			{
			$FreightInsuranceCharge = $FI_Rate * $totalquantity;
			}

		return $FreightInsuranceCharge;
		}

	return 0;
	}

sub get_JSON_DATA :Private
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	my $dataHash;
	my $action = $c->req->param('action') || '';
	if ($action eq 'get_address_detail')
		{
		$dataHash = $self->get_address_detail;
		}
	elsif ($action eq 'get_sku_detail')
		{
		$dataHash = $self->get_sku_detail;
		}
	elsif ($action eq 'adjust_due_date')
		{
		$dataHash = $self->adjust_due_date;
		}
	elsif ($action eq 'add_pkg_detail_row')
		{
		$dataHash = $self->add_pkg_detail_row;
		}
	elsif ($action eq 'get_freight_class')
		{
		$dataHash = $self->get_freight_class;
		}
	elsif ($action eq 'third_party_delivery')
		{
		$dataHash = $self->set_third_party_delivery;
		}
	elsif ($action eq 'get_city_state')
		{
		$dataHash = $self->get_city_state;
		}
	elsif ($action eq 'save_special_services')
		{
		$dataHash = $self->update_special_services;
		}
	elsif ($action eq 'save_third_party_info')
		{
		$dataHash = $self->save_third_party_info;
		}
	elsif ($action eq 'mark_shipment_as_printed')
		{
		$dataHash = $self->mark_shipment_as_printed;
		}
	elsif ($action eq 'search_ordernumber')
		{
		$dataHash = $self->search_ordernumber;
		}
	else
		{
		$dataHash = { error => '[Unknown request] Something went wrong, please contact support.' };
		}

	#$c->log->debug("\n TO dataHash:  " . Dumper ($dataHash));
	my $json_DATA = IntelliShip::Utils->jsonify($dataHash);
	#$c->log->debug("\n TO json_DATA:  " . Dumper ($json_DATA));
	$c->response->body($json_DATA);
	}

sub get_sku_detail :Private
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	my $where = {customerskuid => $params->{'sku_id'}};

	my @sku = $c->model("MyDBI::Productsku")->search($where);
	my $SkuObj = $sku[0];

	my $response_hash = {};
	if ($SkuObj)
		{
		$response_hash->{'description'} = $SkuObj->description;
		$response_hash->{'weight'} = $SkuObj->weight;
		$response_hash->{'length'} = $SkuObj->length;
		$response_hash->{'width'} = $SkuObj->width;
		$response_hash->{'height'} = $SkuObj->height;
		$response_hash->{'nmfc'} = $SkuObj->nmfc;
		$response_hash->{'class'} = $SkuObj->class;
		$response_hash->{'unittypeid'} = $SkuObj->unittypeid;
		$response_hash->{'unitofmeasure'} = $SkuObj->unitofmeasure;
		}
	else
		{
		$response_hash->{'error'} = "Sku not found";
		}

	return $response_hash;
	}

sub adjust_due_date
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	my $ship_date = $params->{shipdate};
	my $due_date = $params->{duedate};
	my $equal_offset = $params->{offset};
	my $less_than_offset = $params->{lessthanoffset};

	#$c->log->debug("Ajax : adjust_due_date");
	#$c->log->debug("ship_date : $ship_date");
	#$c->log->debug("due_date : $due_date");
	#$c->log->debug("equal_offset : $equal_offset");
	#$c->log->debug("less_than_offset : $less_than_offset");

	my $delta_days = IntelliShip::DateUtils->get_delta_days($ship_date,$due_date);

	$c->log->debug("delta_days : $delta_days");

	my ($offset, $adjusted_datetime);
	if ( $delta_days == 0 and length $equal_offset )
		{
		$offset = $equal_offset;
		}
	elsif ( $delta_days < 0 and length $less_than_offset )
		{
		$offset = $less_than_offset;
		}
	else
		{
		$adjusted_datetime = $due_date;
		}

	$adjusted_datetime = IntelliShip::DateUtils->get_future_business_date($ship_date, $offset) if $offset;

	#$c->log->debug("adjusted_datetime : $adjusted_datetime");

	return { dateneeded => $adjusted_datetime };
	}

sub add_pkg_detail_row :Private
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	$c->stash->{one_page} = 1;
	$c->stash->{PKG_DETAIL_ROW} = 1;
	$c->stash->{ROW_COUNT} = $params->{'row_ID'};
	$c->stash->{DETAIL_TYPE} = $params->{'detail_type'};
	$c->stash->{packageunittype_loop} = $self->get_select_list('UNIT_TYPE');

	$c->stash->{unittype} = ($params->{'detail_type'} eq 'package' ? $self->contact->default_package_type : $self->contact->default_product_type);

	my $row_HTML = $c->forward($c->view('Ajax'), "render", [ "templates/customer/order-ajax.tt" ]);
	#$c->log->debug("add_pkg_detail_row : " . $row_HTML);
	$c->stash->{PKG_DETAIL_ROW} = 0;

	return { rowHTML => $row_HTML };
	}

sub set_third_party_delivery
	{
	my $self = shift;
	my $c = $self->context;

	$self->get_third_party_delivery;
	my $row_HTML = $c->forward($c->view('Ajax'), "render", [ "templates/customer/order-ajax.tt" ]);
	$c->stash->{THIRD_PARTY_DELIVERY} = 0;

	#$self->context->log->debug("set_third_party_delivery : " . $row_HTML);
	return { rowHTML => $row_HTML };
	}

sub get_freight_class :Private
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;
	my $response_hash = { freight_class => IntelliShip::Utils->get_freight_class_from_density(undef,undef,undef,undef,$params->{'density'}) };
	#$c->log->debug("response_hash : " . Dumper $response_hash);
	return $response_hash;
	}

sub update_special_services
	{
	my $self = shift;
	$self->save_special_services;
	return { UPDATED => 1};
	}

sub save_third_party_info
	{
	my $self = shift;
	$self->save_third_party_details;
	return { UPDATED => 1};
	}

sub mark_shipment_as_printed
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	my $CO = $self->get_order;

	my $Shipment = $c->model('MyDBI::Shipment')->find({ shipmentid => $params->{shipmentid}, coid => $params->{coid} });
	$Shipment->statusid('100'); ## Printed
	$Shipment->update;

	$c->log->debug("... Marked shipment $params->{shipmentid} as 'Printed'");
	return { UPDATED => 1};
	}

sub search_ordernumber :Private
	{
	my $self = shift;

	my $c = $self->context;
	my $params = $c->req->params;

	my @cos = $c->model('MyDBI::Co')->search({ ordernumber => $params->{'ordernumber'}, coid => { '!=' => $params->{'coid'} }});
	my $CO = $cos[0] if @cos;
	my $resDS = { ORDER_FOUND => 0 };
	if ($CO)
		{
		$resDS->{ORDER_FOUND} = 1;
		$resDS->{COID} = $CO->coid;
		}
	return $resDS;
	}

=as
sub search_address_details
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;
	my $Customer = $self->customer;

	my $LookupValue = $params=>{term} || '';
	my $Direction = $params=>{direction} || 'to';

	my $CustomerID = $Customer->customerid;
	my $smart_address_book = $Customer->smartaddressbook || 0; # 0 = keep only 1,2,3 etc is interval

	my $smart_address_book_sql = '( keep = 1 )';
	if ($smart_address_book > 0)
		{
		$smart_address_book_sql = "( keep = 1 OR date(datecreated) > date(timestamp 'now' + '- $smart_address_book days'))";
		}

	# join to addresses table on either addressid or dropaddressid to split into origin/destination
	#my $AddressJoin;
	#if ($Direction eq 'from')
	#	{
	#	$AddressJoin = "co.dropaddressid = address.addressid";
	#	}
	#else
	#	{
	#	$AddressJoin = "co.addressid = address.addressid";
	#	}

	my $LookupSQL = '';
	if (length $LookupValue)
		{
		$LookupSQL = " addressname ~* '^$LookupValue' AND ";
		}

	my $extcustnum_field = '';
	$extcustnum_field = "extcustnum," if $CustomerID =~ /VOUGHT/;

	my $OrderBy;
	if ($CustomerID =~ /VOUGHT/)
		{
		$OrderBy = "extcustnum, addressname, address1, address2, city";
		}
	else
		{
		$OrderBy = "addressname, address1, address2, city";
		}

	my $SQL = "
	SELECT
		DISTINCT ON (addressname)
		address.addressid
	FROM
		co
		INNER JOIN
		address
		ON co.addressid = address.addressid AND co.customerid = '$CustomerID'
	WHERE
		co.cotypeid in (1,2,10) AND
		address.addressname <> '' AND
		$smart_address_book_sql
	ORDER BY
		$OrderBy
	";
	$c->log->debug("SEARCH_ADDRESS_DETAILS: " . $SQL);
	my $sth = $self->model->('MyDBI')->select($SQL);
	my $arr = [];
	push(@$arr, $_->[0]) foreach @{$sth->query_data};
	#$c->log->debug("jsonify: " . IntelliShip::Utils->jsonify($arr));
	$c->response->body(IntelliShip::Utils->jsonify($arr));

	my $SQL2 = "SELECT
		DISTINCT ON ($extcustnum_field, addressname, address1, address2, city, state, zip, country)
		coid as addressid,
		addressname,
		address1,
		address2,
		city,
		state,
		zip,
		country,
		contactname,
		contactphone,
		extcustnum,
		shipmentnotification,
		deliverynotification
	FROM
		co
		INNER JOIN
		address a
		ON co.addressid = a.addressid AND co.customerid = '$CustomerID'
	WHERE
		co.cotypeid in (1,2,10) AND
		$WHERE
		$OrderBy
	";

	$ReturnRef->{'hash_addressid'} = $self->{'dbref'}->{'aos'}->getdropdownref($SQL);
	my $OptionString = '<option value=\"0\">Select One</option>';

	my $STH = $self->model->('MyDBI')->select($SQL);
	my $AddressCount = 0;
	while ( my ($AddressID,$AddressValue) = $STH->fetchrow_array() )
		{
		$AddressCount++;
		$AddressValue = $self->JSEscape($AddressValue);

		$OptionString .= '<option value="' . $AddressID . '">' . $AddressValue . '</option>';
		}

	$STH->finish();

	# If there were no addresses set to reflect no results
	if ( $AddressCount == 0 )
		{
		$OptionString = '<option value="0">No Results</option>';
		}

	my $STH2 = $self->{'dbref'}->{'aos'}->prepare($SQL2)
	or &TraceBack("Could not prepare sql statement", 1);

	$STH2->execute()
	or &TraceBack("Could not prepare sql statement", 1);

	my @AddressID = ();
	my @Company = ();
	my @Contact = ();
	my @Phone = ();
	my @Address1 = ();
	my @Address2 = ();
	my @City = ();
	my @Province = ();
	my @PostalCode = ();
	my @Country = ();
	my @CustNum = ();
	my @ShipNotify = ();
	my @DeliverNotify = ();

	while ( my $AddressRef = $STH2->fetchrow_hashref )
		{
		foreach my $key(keys(%$AddressRef))
			{
			$AddressRef->{$key} = $self->JSEscape($AddressRef->{$key});

			if ($AddressRef->{'country'} eq 'US' and $AddressRef->{'state'} =~ /^\w{2}$/)
				{
				$AddressRef->{'state'} = uc($AddressRef->{'state'});
				}
			}

		# Turn off local warnings...who cares if we're missing 'address2', for instance
		local $^W = 0;
		push(@AddressID, $AddressRef->{'addressid'});
		push(@Company, $AddressRef->{'addressname'});
		push(@Contact, $AddressRef->{'contactname'});
		push(@Phone, $AddressRef->{'contactphone'});
		push(@Address1, $AddressRef->{'address1'});
		push(@Address2, $AddressRef->{'address2'});
		push(@City, $AddressRef->{'city'});
		push(@Province, $AddressRef->{'state'});
		push(@PostalCode, $AddressRef->{'zip'});
		push(@Country, $AddressRef->{'country'});
		push(@CustNum, $AddressRef->{'extcustnum'});
		push(@ShipNotify, $AddressRef->{'shipmentnotification'});
		push(@DeliverNotify, $AddressRef->{'deliverynotification'});
		local $^W = 1;
		}

	$STH2->finish();

	local $^W = 0;
	$ReturnRef->{'addressvaluelist'} = join( '^', @AddressID);
	$ReturnRef->{'companylist'} = join( '^', @Company);
	$ReturnRef->{'contactlist'} = join( '^', @Contact);
	$ReturnRef->{'phonelist'} = join( '^', @Phone);
	$ReturnRef->{'address1list'} = join( '^', @Address1);
	$ReturnRef->{'address2list'} = join( '^', @Address2);
	$ReturnRef->{'citylist'} = join( '^', @City);
	$ReturnRef->{'provincelist'} = join( '^', @Province);
	$ReturnRef->{'postalcodelist'} = join( '^', @PostalCode);
	$ReturnRef->{'countrylist'} = join( '^', @Country);
	$ReturnRef->{'custnumlist'} = join( '^', @CustNum);
	$ReturnRef->{'shipnotifylist'} = join( '^', @ShipNotify);
	$ReturnRef->{'delivernotifylist'} = join( '^', @DeliverNotify);
	local $^W = 1;

	return $OptionString."\t".$ReturnRef->{'addressvaluelist'}."\t".$ReturnRef->{'companylist'}."\t".$ReturnRef->{'contactlist'}."\t".$ReturnRef->{'phonelist'}."\t".$ReturnRef->{'address1list'}."\t".$ReturnRef->{'address2list'}."\t".$ReturnRef->{'citylist'}."\t".$ReturnRef->{'provincelist'}."\t".$ReturnRef->{'postalcodelist'}."\t".$ReturnRef->{'countrylist'}."\t".$ReturnRef->{'custnumlist'}."\t".$ReturnRef->{'shipnotifylist'}."\t".$ReturnRef->{'delivernotifylist'};

	}
=cut

=encoding utf8

=head1 AUTHOR

root

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
