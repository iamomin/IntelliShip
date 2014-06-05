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

	my $action = $c->req->param('action') || '';
	if ($action eq 'display_international')
		{
		$self->set_international_details;
		}
	elsif ($action eq 'get_special_service_list')
		{
		$self->get_special_service_list;
		}
	elsif ($action eq 'get_carrier_service_list')
		{
		$self->get_carrier_service_list;
		}
	elsif ($action eq 'third_party_delivery')
		{
		$self->get_third_party_delivery;
		}
	elsif ($action eq 'get_country_states')
		{
		$self->get_country_states;
		}
	elsif ($action eq 'generate_packing_list')
		{
		$self->generate_packing_list;
		}
	elsif ($action eq 'generate_bill_of_lading')
		{
		$self->generate_bill_of_lading;
		}
	elsif ($action eq 'generate_commercial_invoice')
		{
		$self->generate_commercial_invoice;
		}
	elsif ($action eq 'get_consolidate_orders_list')
		{
		$self->get_consolidate_orders_list;
		}

	$c->stash(template => "templates/customer/order-ajax.tt") unless $c->stash->{template};
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
	elsif ($action eq 'add_package_product_row')
		{
		$dataHash = $self->add_package_product_row;
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
	elsif ($action eq 'send_email_notification')
		{
		$dataHash = $self->send_email_notification;
		}
	elsif ($action eq 'mark_shipment_as_printed')
		{
		$dataHash = $self->mark_shipment_as_printed;
		}
	elsif ($action eq 'search_ordernumber')
		{
		$dataHash = $self->search_ordernumber;
		}
	elsif ($action eq 'get_dim_weight')
		{
		$dataHash = $self->get_dim_weight;
		}
	elsif ($action eq 'generate_packing_list')
		{
		$dataHash = $self->prepare_packing_list_details;
		}
	elsif ($action eq 'generate_bill_of_lading')
		{
		$dataHash = $self->prepare_BOL;
		}
	elsif ($action eq 'generate_commercial_invoice')
		{
		$dataHash = $self->prepare_com_inv;
		}
	elsif ($action eq 'ship')
		{
		$dataHash = $self->ship_to_carrier;
		}
	elsif ($action eq 'cancel_shipment')
		{
		$dataHash = $self->cancel_shipment;
		}
	elsif ($action eq 'consolidate_orders')
		{
		$dataHash = $self->consolidate_orders;
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

sub set_international_details
	{
	my $self = shift;
	my $c = $self->context;

	my $CO = $self->get_order;
	my $params = $c->req->params;

	$c->stash->{INTERNATIONAL} = 1;

	$c->stash->{countrylist_loop}     = $self->get_select_list('COUNTRY');
	$c->stash->{currencylist_loop}    = $self->get_select_list('CURRENCY');
	$c->stash->{dimentionlist_loop}   = $self->get_select_list('UNIT_OF_MEASURE');
	$c->stash->{termsofsalelist_loop} = $self->get_select_list('TERMS_OF_SALE_LIST');
	$c->stash->{dutypaytypelist_loop} = $self->get_select_list('DUTY_PAY_TYPE_LIST');

	$c->stash->{termsofsale}           = $CO->termsofsale;
	$c->stash->{dutyaccount}           = $CO->dutyaccount;
	$c->stash->{dutypaytype}           = $CO->dutypaytype;
	$c->stash->{manufacturecountry}    = $CO->manufacturecountry ? $CO->manufacturecountry : "US";
	$c->stash->{destinationcountry}    = $CO->destinationcountry ? $CO->destinationcountry : "US";
	$c->stash->{partiestotransaction}  = $CO->partiestotransaction;

	$c->stash->{commodityquantity}     = $CO->commodityquantity;
	$c->stash->{commodityunits}        = $CO->commodityunits ? $CO->commodityunits : "PCS";
	$c->stash->{commoditycustomsvalue} = $CO->commoditycustomsvalue ? $CO->commoditycustomsvalue :"0.00";
	$c->stash->{commodityunitvalue}    = $CO->commodityunitvalue ? $CO->commodityunitvalue :"0.00";
	$c->stash->{currencytype}          = $CO->currencytype ? $CO->currencytype : "USD";

	$c->stash->{printcominv}           = $self->contact->get_contact_data_value('defaultcomminv');
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

	my $ToAddress = $CO->destination_address;
	my $addresscode = $ToAddress->addresscode;

	my $carrier_Details = $self->API->get_carrrier_service_rate_list($CO, $Contact, $Customer, $addresscode);
	#$c->log->debug("API get_carrrier_service_rate_list: " . Dumper($carrier_Details));

	my ($CS_list_1, $CS_list_2, $CS_charge_details) = ([], [], {});
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

			my $date_to_ship = $CO->datetoship if IntelliShip::DateUtils->is_valid_date($CO->datetoship);
			$date_to_ship = IntelliShip::DateUtils->get_formatted_timestamp unless $date_to_ship;
			$detail_hash->{'days'} = IntelliShip::DateUtils->get_business_days_between_two_dates($date_to_ship,$estimated_date);

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
			push(@$SHIPMENT_CHARGE_DETAILS, { text => 'Freight' , value => '$' . sprintf("%.2f",$freightcharges) }) if $freightcharges;
			push(@$SHIPMENT_CHARGE_DETAILS, { text => 'Fuel' , value => '$' . sprintf("%.2f",$fuelcharges) }) if $fuelcharges;
			push(@$SHIPMENT_CHARGE_DETAILS, { text => 'Declared Value Insurance' , value => '$' . sprintf("%.2f",$DVI_Charge) }) if $DVI_Charge;
			push(@$SHIPMENT_CHARGE_DETAILS, { text => 'Freight Insurance' , value => '$' . sprintf("%.2f",$FI_Charge) }) if $FI_Charge;
			#push(@$SHIPMENT_CHARGE_DETAILS, { hr => 1 });

			my $SC_charge = $self->populate_special_services_charge($SHIPMENT_CHARGE_DETAILS,$customerserviceid,$freightcharges);

			$CS_charge_details->{$customerserviceid} = "Freight:$freightcharges|Fuel:$fuelcharges|Declared Value Insurance:$DVI_Charge|Freight Insurance:$FI_Charge";

			$detail_hash->{'freight_charge'} = sprintf("%.2f",($freightcharges || '0'));
			$detail_hash->{'other_charge'} = sprintf("%.2f",(($fuelcharges+$DVI_Charge+$FI_Charge+$SC_charge) || '0'));

			$detail_hash->{'SHIPMENT_CHARGE_DETAILS'} = $SHIPMENT_CHARGE_DETAILS;
			#$c->log->debug("SHIPMENT_CHARGE_DETAILS :". Dumper($SHIPMENT_CHARGE_DETAILS));
			}

		($detail_hash->{'shipment_charge'} =~ /\d+/ and $detail_hash->{'shipment_charge'} > 0) ? push(@$CS_list_1, $detail_hash) : push(@$CS_list_2, $detail_hash);
		}

	$c->stash->{CARRIER_SERVICE_LIST} = 1;
	$c->stash->{ONLY_TABLE} = 1;

	#$c->log->debug("CS_list_1: ". Dumper($CS_list_1));
	if ($CO->has_carrier_service_details and $params->{'action'} ne 'get_carrier_service_list')
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

		$c->stash->{TAB} = 'r';
		$c->stash->{CARRIER_SERVICE_LIST_LOOP} = $self->get_recommened_carrier_service(\@sortByDays,\@sortByCharge,$CS_list_2);
		$c->stash->{recommendedcarrierlist} = $c->forward($c->view('Ajax'), "render", [ "templates/customer/order-ajax.tt" ]);
		$c->stash->{CARRIER_SERVICE_LIST_LOOP}->[0]->{checked} = 0;

		$c->stash->{TAB} = 't';
		$c->stash->{CARRIER_SERVICE_LIST_LOOP} = [@sortByDays, @$CS_list_2];
		$c->stash->{transitdayscarrierlist} = $c->forward($c->view('Ajax'), "render", [ "templates/customer/order-ajax.tt" ]);

		$c->stash->{TAB} = 'v';
		$c->stash->{CARRIER_SERVICE_LIST_LOOP} = [@sortByCharge, @$CS_list_2];
		$c->stash->{viewallcarrierlist} = $c->forward($c->view('Ajax'), "render", [ "templates/customer/order-ajax.tt" ]);
		}

	$c->stash->{CS_CHARGE_HASH} = IntelliShip::Utils->jsonify($CS_charge_details);

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

sub get_country_states :Private
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	my $statelist_loop = $self->get_select_list('STATE', { country => $params->{'country'} });
	$c->stash->{statelist_loop} = $statelist_loop if @$statelist_loop > 1;
	$c->stash->{control_name}   = $params->{'control'};
	$c->stash->{COUNTRY_STATES} = 1;
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

sub populate_special_services_charge
	{
	my $self = shift;
	my $SHIPMENT_CHARGE_DETAILS = shift;
	my $csid = shift;
	my $freightcharges = shift;

	my $c = $self->context;
	my $Customer = $self->customer;

	my $CO  = $self->get_order;
	my @arr = $CO->assessorials;

	my $SC_charge = 0;
	foreach my $AssData (@arr)
		{
		my $chargeDetails = $self->API->get_assessorial_charge($csid,$CO->total_weight,$CO->total_quantity,$AssData->assname,$Customer->customerid,$freightcharges);

		$c->log->debug("CSID: $csid, Service: " . $AssData->assname . ", Charge: " . $chargeDetails->{'value'});

		next unless $chargeDetails->{'value'};

		push(@$SHIPMENT_CHARGE_DETAILS, { text => $AssData->assdisplay, value => '$' . sprintf("%.2f",$chargeDetails->{'value'}) });
		$SC_charge += $chargeDetails->{'value'};
		}

	return $SC_charge;
	}

sub get_sku_detail :Private
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	my $where = { customerid => $self->customer->customerid, customerskuid => $params->{'sku_id'} };

	my @sku = $c->model("MyDBI::Productsku")->search($where);
	my $SkuObj = $sku[0];

	my $response_hash = {};
	if ($SkuObj)
		{
		$response_hash->{'description'} = $SkuObj->description;
		$response_hash->{'unittypeid'} = $SkuObj->unittypeid;
		$response_hash->{'weight'} = $SkuObj->weight;
		$response_hash->{'length'} = $SkuObj->length;
		$response_hash->{'width'} = $SkuObj->width;
		$response_hash->{'height'} = $SkuObj->height;
		$response_hash->{'nmfc'} = $SkuObj->nmfc;
		$response_hash->{'class'} = $SkuObj->class;
		$response_hash->{'unittypeid'} = $SkuObj->unittypeid;
		$response_hash->{'unitofmeasure'} = $SkuObj->unitofmeasure;
		$response_hash->{'value'} = $SkuObj->value;
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

sub add_package_product_row :Private
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	my $flag = uc($params->{'detail_type'}) . '_DETAIL_ROW';

	$c->stash($params);
	if (my $UnitType = $c->model('MyDBI::UnitType')->find({ unittypeid => $params->{'unittypeid'} }))
		{
		$c->stash->{PACKAGE_TYPE} = uc $UnitType->unittypename;
		$c->stash->{dimlength} = $UnitType->dimlength;
		$c->stash->{dimwidth}  = $UnitType->dimwidth;
		$c->stash->{dimheight} = $UnitType->dimheight;
		}

	$c->stash->{WEIGHT_TYPE} = $self->contact->customer->weighttype if $params->{'detail_type'} eq 'package';
	$c->stash->{measureunit_loop} = $self->get_select_list('DIMENTION') unless $c->stash->{measureunit_loop};
	$c->stash->{classlist_loop} = $self->get_select_list('CLASS') unless $c->stash->{classlist_loop};
	$c->stash->{PACKAGE_INDEX} = $params->{'row_ID'} || 1;
	$c->stash->{ROW_COUNT} = $params->{'row_ID'} || 1;
	$c->stash->{one_page} = 1;
	$c->stash->{$flag} = 1;

	my $row_HTML = $c->forward($c->view('Ajax'), "render", [ "templates/customer/order-shipment-package.tt" ]);

	$c->stash->{$flag} = 0;

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

sub send_email_notification
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	$self->SendShipNotification($c->model('MyDBI::Shipment')->find({ shipmentid => $params->{shipmentid} }));

	return { EMAIL_SENT => 1};
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

	if ($Shipment->has_pickup_request)
		{
		$self->send_pickup_request($Shipment);
		}

	$c->log->debug("... Marked shipment $params->{shipmentid} as 'Printed'");

	#$self->SendShipNotification($Shipment);

	my $response = { UPDATED => 1};

	my $return_capability = $CO->return;
	$return_capability =~ s/\s+//;
	if ($return_capability ne '')
		{
		$c->log->debug("... Return capability found");
		$response->{RETURN_SHIPMENT} = 1;
		my $RetCO = $self->create_return_shipment($CO);
		$response->{RET_COID} = $RetCO->coid;
		}

	return $response;
	}

sub search_ordernumber :Private
	{
	my $self = shift;

	my $c = $self->context;
	my $params = $c->req->params;

	my @cos = $c->model('MyDBI::Co')->search({ customerid => $self->customer->customerid, ordernumber => $params->{'ordernumber'}, coid => { '!=' => $params->{'coid'} }});
	my $CO = $cos[0] if @cos;
	my $resDS = { ORDER_FOUND => 0 };
	if ($CO)
		{
		$resDS->{ORDER_FOUND} = 1;
		$resDS->{COID} = $CO->coid;
		}
	return $resDS;
	}

sub get_dim_weight
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	my $csid      = $params->{CSID};
	my $dimlength = $params->{dimlength};
	my $dimwidth  = $params->{dimwidth};
	my $dimheight = $params->{dimheight};

	my $dimWeight = $self->API->get_dim_weight($csid, $dimlength, $dimwidth, $dimheight) || 0;

	$c->log->debug("... DIM WEIGHT: " . $dimWeight);

	return { dimweight => $dimWeight, row => $params->{'row'} };
	}

sub prepare_packing_list_details
	{
	my $self = shift;
	my $HTML = $self->generate_packing_list;
	#$self->context->log->debug("Ajax.pm generate_packing_list : " . $HTML);
	return { PACKING_LIST => $HTML };
	}

sub prepare_BOL
	{
	my $self = shift;
	my $HTML = $self->generate_bill_of_lading;
	#$self->context->log->debug("Ajax.pm generate_bill_of_lading : " . $HTML);
	return { BOL => $HTML };
	}

sub prepare_com_inv
	{
	my $self = shift;
	my $HTML = $self->generate_commercial_invoice;
	$self->context->log->debug("Ajax.pm generate_commercial_invoice : " . $HTML);
	return { ComInv => $HTML };
	}

sub ship_to_carrier
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	my @shipmentids;

	$self->save_order;

	if ($params->{'consolidate'} == 1 && !$params->{'combine'})
		{
		$c->log->debug("... CONSOLIDATE");
		my $consolidatedOrders = {};

		my $CO = $self->get_order;
		my @packages = $CO->packages;

		foreach my $Package (@packages)
			{
			my $key = $Package->originalcoid;
			$consolidatedOrders->{$key} = {} unless $consolidatedOrders->{$key};

			$consolidatedOrders->{$key}->{'packages'} = [] unless $consolidatedOrders->{$key}->{'packages'};
			push(@{$consolidatedOrders->{$key}->{'packages'}},$Package);

			$consolidatedOrders->{$key}->{'enteredweight'} = 0 unless $consolidatedOrders->{$key}->{'enteredweight'};
			$consolidatedOrders->{$key}->{'dimweight'} = 0 unless $consolidatedOrders->{$key}->{'dimweight'};
			$consolidatedOrders->{$key}->{'quantity'} = 0 unless $consolidatedOrders->{$key}->{'quantity'};

			$consolidatedOrders->{$key}->{'enteredweight'} += $Package->weight;
			$consolidatedOrders->{$key}->{'dimweight'} += $Package->dimweight;
			$consolidatedOrders->{$key}->{'quantity'} += $Package->quantity;
			}

		foreach my $COID (keys %$consolidatedOrders)
			{
			my $DummyCO = $c->model('MyDBI::Co')->new($CO->{_column_data});
			$DummyCO->coid($self->get_token_id);

			my $packages = $consolidatedOrders->{$COID}->{'packages'};
			foreach my $Package (@$packages)
				{
				my $DummyPackage = $c->model('MyDBI::Packprodata')->new($Package->{_column_data});
				$DummyPackage->packprodataid($self->get_token_id);
				$DummyPackage->ownerid($DummyCO->coid);
				$DummyPackage->insert;

				my @products = $Package->products;
				foreach my $Product (@products)
					{
					my $DummyProduct = $c->model('MyDBI::Packprodata')->new($Product->{_column_data});
					$DummyProduct->packprodataid($self->get_token_id);
					$DummyProduct->ownerid($Package->packprodataid);
					$DummyProduct->insert;
					}

				if (!$DummyCO->ordernumber && $Package->originalcoid)
					{
					$DummyCO->ordernumber($Package->originalcoid);
					}
				}

			$DummyCO->insert;
			$c->log->debug("... DummyCO, coid : " . $DummyCO->coid);

			$params->{'enteredweight'} = $consolidatedOrders->{$COID}->{'enteredweight'};
			$params->{'dimweight'} = $consolidatedOrders->{$COID}->{'dimweight'};
			$params->{'quantity'} = $consolidatedOrders->{$COID}->{'quantity'};

			$c->log->debug("... enteredweight: " . $params->{'enteredweight'});
			$c->log->debug("... dimweight    : " . $params->{'dimweight'});
			$c->log->debug("... quantity     : " . $params->{'quantity'});

			$c->stash->{CO} = $DummyCO;

			## SHIP ORDER
			push @shipmentids, $self->SHIP_ORDER;

			$DummyCO->archive_order;
			}
		}
	else
		{
		## SHIP ORDER
		push @shipmentids, $self->SHIP_ORDER;
		}

	my $response = { SUCCESS => 0 };
	$response->{shipmentid} = join('_',@shipmentids);
	$c->log->debug("... shipmentid: " . $response->{'shipmentid'});

	if ($self->has_errors)
		{
		$response->{error} = $self->errors->[0];
		}
	else
		{
		$response->{SUCCESS} = 1;
		}

	return $response;
	}

sub cancel_shipment
	{
	my $self = shift;
	my $shipment_id = $self->context->req->params->{'shipmentid'};
	my @shipmentids = split('_',$shipment_id);
	$self->VOID_SHIPMENT($_) foreach @shipmentids;
	return { voided => 1 };
	}

sub get_consolidate_orders_list
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	IntelliShip::Utils->hash_decode($params);

	my $CO = $self->get_order;
	my $CustomerID = $self->customer->customerid;

	$self->save_CO_details;

	my $DestinationAddressID;
	if ($params->{'toaddress1'})
		{
		## Save address details
		$self->save_address;
		my $ToAddress = $CO->to_address;
		$DestinationAddressID = $ToAddress->addressid;
		}
	else
		{
		return $c->stash->{MESSAGE} = 'Please select destination address to consolidate matching orders';
		}

	my $OrderSQL = "SELECT
				coid,
				CASE
				WHEN daterouted is not null THEN 1
				WHEN datepacked is not null THEN 2
				WHEN datereceived is not null THEN 3
				WHEN daterouted is null and datepacked is null and datereceived is null THEN 4 END
				as condition
			FROM
				co
			WHERE
				co.addressid = '$DestinationAddressID'
				AND co.customerid = '$CustomerID'
				AND (co.combine = 0 OR co.combine IS NULL)
				AND statusid not in (5,6,7,200)
		";

	if ($self->customer->get_contact_data_value('dateconsolidation'))
		{
		$OrderSQL .= " AND (daterouted is not null OR datepacked is not null OR datereceived is not null) ";
		}

	if ( $self->contact->is_restricted)
		{
		my $RestrictedDataRow = $c->model('MyDBI')->select("
			SELECT
				fieldvalue
			FROM
				restrictcontact
			WHERE
				contactid = '" . $self->contact->contactid . "'
				AND fieldname = 'extcustnum'
		");

		while ( my ($Value) = $RestrictedDataRow->fetchrow_array() )
			{
			$OrderSQL .= " AND upper(co.extcustnum) in " ."'" . uc($Value) . "',";
			}
		}

	$OrderSQL .= " ORDER BY condition,ordernumber";

	#$c->log->debug("OrderSQL: " . $OrderSQL);

	my $STH = $c->model('MyDBI')->select($OrderSQL);

	my $consolidate_order_list = [];
	if ($STH->numrows)
		{
		my $arr = $STH->query_data;
		#$c->log->debug("CO IDs: " . Dumper $arr);
		my @COS = $c->model('MyDBI::CO')->search({ coid => $arr });

		foreach my $CO (@COS)
			{
			if ($params->{coid} ne $CO->coid && $CO->packages->count == 0) ## Don't include any order which don't have package details
				{
				next;
				}

			push(@$consolidate_order_list, {
				coid         => $CO->coid,
				ordernumber  => $CO->ordernumber,
				carrier      => $CO->extcarrier,
				service      => $CO->extservice,
				datetoship   => IntelliShip::DateUtils->american_date($CO->datetoship),
				dateneeded   => IntelliShip::DateUtils->american_date($CO->dateneeded),
				toAddress    => $CO->to_address,
				packagecount => $CO->packages->count,
				productcount => $CO->product_count,
				});
			}
		}

	$c->log->debug("Total Orders Found: " . @$consolidate_order_list);

	if (@$consolidate_order_list <= 1)
		{
		$consolidate_order_list = undef;
		$c->stash->{MESSAGE} = 'No matching orders found to consolidate';
		}

	$c->stash($params);
	$c->stash->{consolidate_order_list} = $consolidate_order_list;
	}

sub consolidate_orders
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;
	my $CO = $self->get_order;

	$c->stash->{ROW_COUNT} = 0;

	my @arr = $CO->packages;
	my $Package;
	if (@arr)
		{
		$Package = $arr[0];
		}
	else
		{
		$Package = $c->model("MyDBI::Packprodata")->new({
				packprodataid => $self->get_token_id,
				ownerid       => $CO->coid,
				ownertypeid   => 1000,
				datatypeid    => 1000,
				}) ;

		$Package->insert;
		}

	my $Coids = (ref $params->{'coids'} eq 'ARRAY' ? $params->{'coids'} : [$params->{'coids'}]);

	$c->log->debug("...Total Coids: " . @$Coids);

	my @packages;
	if ($params->{'combine'} == 1)
		{
		$c->log->debug("..... COMBINE");

		foreach my $coid (@$Coids)
			{
			my $CoObj = $c->model('MyDBI::Co')->find({ coid => $coid});
			my @arrs = $CoObj->packages;
			foreach (@arrs)
				{
				foreach my $Product ($_->products)
					{
					$Product->ownerid($Package->packprodataid);
					$Product->update;
					}
				}
			}

		push(@packages, { PACKAGE => $Package });
		}
	else
		{
		foreach my $coid (@$Coids)
			{
			my $CoObj = $c->model('MyDBI::Co')->find({ coid => $coid});
			my @arrs = $CoObj->packages;
			push(@packages, { CO => $CoObj, PACKAGE => $_ } ) foreach @arrs;
			}
		}

	$c->log->debug("Total No of Packages: " . @packages);

	my $package_detail_section_HTML = '';

	my $OriginalCO = $self->get_order;
	foreach (@packages)
		{
		my ($cCO,$Package) = ($_->{CO},$_->{PACKAGE});

		$c->stash->{SHIPPER_NUMBER} = $cCO->ordernumber if $cCO && $Package->datatypeid == 1000;
		$package_detail_section_HTML .= $self->add_package_detail_row($Package);
		}

	$c->stash($params);
	$c->stash->{CO} = $OriginalCO;
	$c->stash->{coids} = join(',', @$Coids);
	$c->stash->{CONSOLIDATED_PACKAGE} = $package_detail_section_HTML;

	my $HTML = $c->forward($c->view('Ajax'), "render", [ "templates/customer/order-ajax.tt" ]);

	return { HTML => $HTML };
	}

=encoding utf8

=head1 AUTHOR

root

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
