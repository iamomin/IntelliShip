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

	$self->save_order;

	my $CO = $self->get_order;
	my $Contact = $self->contact;
	my $Customer = $self->customer;

	my $APIRequest = IntelliShip::Arrs::API->new;
	$APIRequest->context($c);
	my $carrier_Details = $APIRequest->get_carrrier_service_rate_list($CO, $Contact, $Customer);

	my ($CS_list_1, $CS_list_2) = ([], []);
	foreach my $customerserviceid (keys %$carrier_Details)
		{
		my $CSData = $carrier_Details->{$customerserviceid};

		my @carrier_service = split(/ - /,$CSData->{'NAME'});
		my $carrier = $carrier_service[0];

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
						};

		if ($CO->freightcharges == 0) # PREPAID
			{
			$c->stash->{IS_PREPAID} = 1;
			$detail_hash->{'delivery'} = $estimated_date;
			$shipment_charge =~ s/\$//;
			$detail_hash->{'shipment_charge'} = $shipment_charge;
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

					$freightcharges += $CostBreakDown[0] if $CostBreakDown[0] =~ /\d+/;
					$fuelcharges += $CostBreakDown[1] if $CostBreakDown[1] =~ /\d+/;
					}
				}

			my ($totalquantity, $aggregateweight) = $self->get_estimated_quantity_and_weight;
			my $DVI_Charge = $self->calculate_declared_value_insurance($CSData->{'key'}, $aggregateweight);
			my $FI_Charge = $self->calculate_freight_insurance($CSData->{'key'}, $totalquantity);

			my $SHIPMENT_CHARGE_DETAILS = [];
			push(@$SHIPMENT_CHARGE_DETAILS, { text => 'Freight Charges' , value => '$' . sprintf("%.2f",$freightcharges) }) if $freightcharges;
			push(@$SHIPMENT_CHARGE_DETAILS, { text => 'Fuel Charges' , value => '$' . sprintf("%.2f",$fuelcharges) }) if $fuelcharges;
			push(@$SHIPMENT_CHARGE_DETAILS, { text => 'Declared Value Insurance' , value => '$' . sprintf("%.2f",$DVI_Charge) }) if $DVI_Charge;
			push(@$SHIPMENT_CHARGE_DETAILS, { text => 'Freight Insurance' , value => '$' . sprintf("%.2f",$FI_Charge) }) if $FI_Charge;
			push(@$SHIPMENT_CHARGE_DETAILS, { hr => 1 });
			push(@$SHIPMENT_CHARGE_DETAILS, { text => 'Est Total Charge' , value => '<green>$' . sprintf("%.2f",$detail_hash->{'shipment_charge'}) . '</green>' });

			$detail_hash->{'SHIPMENT_CHARGE_DETAILS'} = $SHIPMENT_CHARGE_DETAILS;
			#$self->context->log->debug("SHIPMENT_CHARGE_DETAILS :". Dumper($SHIPMENT_CHARGE_DETAILS));
			}

		$detail_hash->{'shipment_charge'} =~ s/Quote//;
		$detail_hash->{'shipment_charge'} =~ /\d+/ ? push(@$CS_list_1, $detail_hash) : push(@$CS_list_2, $detail_hash);
		}

	my @sortByDays = sort { $a->{days} <=> $b->{days} || $a->{shipment_charge} <=> $b->{shipment_charge} } @$CS_list_1;
	my @sortByCharge = sort { $a->{shipment_charge} <=> $b->{shipment_charge} || $a->{days} <=> $b->{days} } @$CS_list_1;

	$c->stash->{CARRIERSERVICE_LIST} = 1;
	$c->stash->{ONLY_TABLE} = 1;

	$c->stash->{CARRIER_SERVICE_LIST_LOOP} = [$sortByDays[0]];
	$c->stash->{recommendedcarrierlist} = $c->forward($c->view('Ajax'), "render", [ "templates/customer/order-ajax.tt" ]);

	$c->stash->{CARRIER_SERVICE_LIST_LOOP} = [@sortByDays, @$CS_list_2];
	$c->stash->{transitdayscarrierlist} = $c->forward($c->view('Ajax'), "render", [ "templates/customer/order-ajax.tt" ]);

	$c->stash->{CARRIER_SERVICE_LIST_LOOP} = [@sortByCharge, @$CS_list_2];
	$c->stash->{viewallcarrierlist} = $c->forward($c->view('Ajax'), "render", [ "templates/customer/order-ajax.tt" ]);

	$c->stash->{CARRIER_SERVICE_LIST_LOOP} = undef;
	$c->stash->{ONLY_TABLE} = 0;
	}

sub get_third_party_delivery
	{
	my $self = shift;
	my $c = $self->context;

	if (my @thirdpartyaccts = $self->customer->thirdpartyaccts)
		{
		my $tp_list = [];
		push (@$tp_list, { tpcompanyname => $_->tpcompanyname, tpdetails => $_->tpaddress1.'|'.$_->tpaddress2.'|'.$_->tpcity.'|'.$_->tpstate.'|'.$_->tpzip.'|'.$_->tpcountry.'|'.$_->tpacctnumber }) foreach @thirdpartyaccts;
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
	if ($params->{'action'} eq 'get_sku_detail')
		{
		$dataHash = $self->get_sku_detail;
		}
	elsif ($params->{'action'} eq 'adjust_due_date')
		{
		$dataHash = $self->adjust_due_date;
		}
	elsif ($params->{'action'} eq 'add_pkg_detail_row')
		{
		$dataHash = $self->add_pkg_detail_row;
		}
	elsif ($params->{'action'} eq 'get_freight_class')
		{
		$dataHash = $self->get_freight_class;
		}
	elsif ($c->req->param('action') eq 'third_party_delivery')
		{
		$dataHash = $self->set_third_party_delivery;
		}
	elsif ($c->req->param('action') eq 'get_city_state')
		{
		$dataHash = $self->get_city_state;
		}
	elsif ($c->req->param('action') eq 'get_address_detail')
		{
		$dataHash = $self->get_address_detail;
		}
	elsif ($c->req->param('action') eq 'save_special_services')
		{
		$dataHash = $self->update_special_services;
		}
	elsif ($c->req->param('action') eq 'save_third_party_info')
		{
		$dataHash = $self->save_third_party_info;
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

	my $row_HTML = $c->forward($c->view('Ajax'), "render", [ "templates/customer/order-ajax.tt" ]);
	#$self->context->log->debug("add_pkg_detail_row : " . $row_HTML);
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

=encoding utf8

=head1 AUTHOR

root

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
