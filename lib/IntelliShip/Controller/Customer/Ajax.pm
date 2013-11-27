package IntelliShip::Controller::Customer::Ajax;
use Moose;
use Data::Dumper;
use namespace::autoclean;
use IntelliShip::HTTP;
use IntelliShip::Utils;
use IntelliShip::DateUtils;

BEGIN { extends 'IntelliShip::Controller::Customer'; }

=head1 NAME

IntelliShip::Controller::Customer::Ajax - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0)
	{
	my ( $self, $c ) = @_;
	my $params = $c->req->params;

	if ($params->{'type'} eq 'HTML')
		{
		$self->get_HTML;
		}
	elsif ($params->{'type'} eq 'JSON')
		{
		$self->get_JSON_DATA;
		}

	$c->stash(template => "templates/customer/ajax.tt");
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
	elsif ($action eq 'customer_carrier_chkbox')
		{
		$self->set_customer_carrier_chkbox;
		}
	elsif ($action eq 'costatus_chkbox')
		{
		$self->set_costatus_chkbox;
		}
	}

sub set_international_details
	{
	my $self = shift;
	my $c = $self->context;

	$c->stash->{countrylist_loop} = $self->get_select_list('COUNTRY');
	$c->stash->{INTERNATIONAL} = 1;
	}

sub set_customer_carrier_chkbox
	{
	my $self = shift;
	my $c = $self->context;

	$c->stash->{CARRIER_LIST} = $self->get_select_list('CUSTOMER_SHIPMENT_CARRIER');
	}

sub set_costatus_chkbox
	{
	my $self = shift;
	my $c = $self->context;

	$c->stash->{COSTATUS_LIST} = $self->get_select_list('COSTATUS');
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
	elsif ($c->req->param('action') eq 'get_customer_service_list')
		{
		$dataHash = $self->get_customer_service_list;
		}
	elsif ($c->req->param('action') eq 'get_city_state')
		{
		$dataHash = $self->get_city_state;
		}

	#$c->log->debug("\n TO dataHash:  " . Dumper ($dataHash));
	my $json_response = $self->jsonify($dataHash);
	#$c->log->debug("\n TO json_response:  " . Dumper ($json_response));

	$c->stash->{JSON_DATA} = $json_response;
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

	$c->log->debug("Ajax : adjust_due_date");
	$c->log->debug("ship_date : $ship_date");
	$c->log->debug("due_date : $due_date");
	$c->log->debug("equal_offset : $equal_offset");
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

	$c->log->debug("adjusted_datetime : $adjusted_datetime");

	return { dateneeded => $adjusted_datetime };
	}

sub add_pkg_detail_row :Private
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	$c->stash->{PKG_DETAIL_ROW} = 1;
	$c->stash->{ROW_COUNT} = $params->{'row_ID'};
	$c->stash->{DETAIL_TYPE} = $params->{'detail_type'};
	$c->stash->{packageunittype_loop} = $self->get_select_list('UNIT_TYPE');

	#$self->context->log->debug("in add_new_row : row_HTML");
	my $row_HTML = $c->forward($c->view('Ajax'), "render", [ "templates/customer/ajax.tt" ]);
	$c->stash->{PKG_DETAIL_ROW} = 0;

	return { rowHTML => $row_HTML };
	}

sub set_third_party_delivery
	{
	my $self = shift;
	my $c = $self->context;

	$c->stash->{statelist_loop} = $self->get_select_list('US_STATES');
	$c->stash->{countrylist_loop} = $self->get_select_list('COUNTRY');
	$c->stash->{THIRD_PARTY_DELIVERY} = 1;
	my $row_HTML = $c->forward($c->view('Ajax'), "render", [ "templates/customer/ajax.tt" ]);
	$c->stash->{THIRD_PARTY_DELIVERY} = 0;

	#$self->context->log->debug("set_third_party_delivery : " . $row_HTML);
	return { rowHTML => $row_HTML };
	}

sub get_freight_class :Private
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	my $density = $params->{'density'};
	my $response_hash = {};
	if ( my $freight_class = IntelliShip::Utils->get_freight_class_from_density(undef,undef,undef,undef,$density))
		{
		$response_hash->{ 'freight_class'} = $freight_class;
		}
	else
		{
		$response_hash->{ 'freight_class'} = '0';
		}

	return $response_hash;
	}

sub get_city_state
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	my $address = $params->{'zipcode'};

	my $HTTP = IntelliShip::HTTP->new;
	$HTTP->method('GET');
	$HTTP->host_production('maps.googleapis.com/maps/api/geocode/xml');
	$HTTP->uri_production('address=' . $address . '&sensor=true');
	$HTTP->timeout('30');

	my $result = $HTTP->send;
	my $responseDS = IntelliShip::Utils->parse_XML($result);
	#$c->log->debug("get_city_state result : " . Dumper $result);
	#$c->log->debug("get_city_state responseDS : " . Dumper $responseDS);

	my ($address1, $address2, $city, $state, $zip, $country);
	if ($responseDS->{'GeocodeResponse'}->{'status'} eq 'OK')
		{
		my $geocodeResponse = $responseDS->{'GeocodeResponse'}->{'result'};
		my $formatted_address = $geocodeResponse->{'formatted_address'};
		my $address_components = $geocodeResponse->{'address_component'};

		foreach my $component (@$address_components)
			{
			#$c->log->debug("ref component->{type}: " . ref $component->{type});
			$component->{type} = join(' | ', @{$component->{type}}) if (ref $component->{type}) =~ /array/gi;
			#$c->log->debug("component->{type}: " . $component->{type});

			$address1 = $component->{short_name} if $component->{type} =~ /administrative_area_level_1/;
			$address2 = $component->{short_name} if $component->{type} =~ /locality/;
			$city = $component->{short_name} if $component->{type} =~ /administrative_area_level_2/;
			$state = $component->{short_name} if $component->{type} =~ /administrative_area_level_1/;
			$zip = $component->{short_name} if $component->{type} =~ /postal_code/;
			$country = $component->{short_name} if $component->{type} =~ /country/;
			;
			}
		}

	#$c->log->debug("address1: $address1, address2: $address2, city: $city, state: $state, zip: $zip, country: $country");

	return { address1 => $address1, address2 => $address2, city => $city, state => $state, zip => $zip, country => $country };
	}

sub get_customer_service_list
	{
	my $self = shift;
	my $c = $self->context;

	#return {} unless ($self->OrderHasWeight);

	my $carrier_service_list_loop = [
			{customerserviceid => 'xx', carrier => 'UPS',   service => 'Ground',         delivery => '11/29', shipment_charge => '11.50',},
			{customerserviceid => 'xx', carrier => 'FedEx', service => 'Ground',         delivery => '11/29', shipment_charge => '12.40',},
			{customerserviceid => 'xx', carrier => 'UPS',   service => '3-Day Select',   delivery => '11/28', shipment_charge => '16.50',},
			{customerserviceid => 'xx', carrier => 'FedEx', service => 'Express Server', delivery => '11/27', shipment_charge => '17.80',},
		];

	#my $carrier_service_list_loop = $self->get_carrrier_service_rate_list;

	$c->stash->{CARRIER_SERVICE_LIST_LOOP} = $carrier_service_list_loop;
	$c->stash->{CARRIERSERVICE_LIST} = 1;
	my $row_HTML = $c->forward($c->view('Ajax'), "render", [ "templates/customer/ajax.tt" ]);
	$c->stash->{CARRIERSERVICE_LIST} = 0;
	$c->log->debug("row_HTML: $row_HTML ");

	return { rowHTML => $row_HTML };
	}
=a
sub get_carrrier_service_rate_list
	{
	my $self = shift;
	my $c = $self->context;

	#my ($hash_customerserviceid, $defaultcsid, $packagecostlist, $CSShipmentValues, undef, $CSSecurityTypes, $defaultcsidtotalcost, $usingaltsop, $altsopid);
	my $RequestRef = {};
	$RequestRef->{'action'} = 'GetCSList';

	## Add support for dropship & inbound
	#if ( defined($CgiRef->{'isinbound'}) && $CgiRef->{'isinbound'} == 1 )
	#	{
	#	$RequestRef->{'fromzip'} = $CgiRef->{'addresszip'};
	#	$RequestRef->{'fromstate'} = $CgiRef->{'addressstate'};
	#	$RequestRef->{'fromcountry'} = $CgiRef->{'addresscountry'};
	#	$RequestRef->{'tozip'} = $CgiRef->{'branchaddresszip'};
	#	$RequestRef->{'tostate'} = $CgiRef->{'branchaddressstate'};
	#	$RequestRef->{'tocountry'} = $CgiRef->{'branchaddresscountry'};
	#	}
	#elsif ( defined($CgiRef->{'isdropship'}) && $CgiRef->{'isdropship'} == 1 )
	#	{
	#	$RequestRef->{'fromzip'} = $CgiRef->{'dropzip'};
	#	$RequestRef->{'fromstate'} = $CgiRef->{'dropstate'};
	#	$RequestRef->{'fromcountry'} = $CgiRef->{'dropcountry'};
	#	$RequestRef->{'tozip'} = $CgiRef->{'addresszip'};
	#	$RequestRef->{'tostate'} = $CgiRef->{'addressstate'};
	#	$RequestRef->{'tocountry'} = $CgiRef->{'addresscountry'};
	#	}
	#else
	#	{
	#	$RequestRef->{'fromzip'} = $CgiRef->{'branchaddresszip'};
	#	$RequestRef->{'fromstate'} = $CgiRef->{'branchaddressstate'};
	#	$RequestRef->{'fromcountry'} = $CgiRef->{'branchaddresscountry'};
	#	$RequestRef->{'tozip'} = $CgiRef->{'addresszip'};
	#	$RequestRef->{'tostate'} = $CgiRef->{'addressstate'};
	#	$RequestRef->{'tocountry'} = $CgiRef->{'addresscountry'};
	#	}

	$RequestRef->{'fromzip'} = $CgiRef->{'branchaddresszip'};
	$RequestRef->{'fromstate'} = $CgiRef->{'branchaddressstate'};
	$RequestRef->{'fromcountry'} = $CgiRef->{'branchaddresscountry'};
	$RequestRef->{'tozip'} = $CgiRef->{'addresszip'};
	$RequestRef->{'tostate'} = $CgiRef->{'addressstate'};
	$RequestRef->{'tocountry'} = $CgiRef->{'addresscountry'};

	$RequestRef->{'datetoship'} = $CgiRef->{'datetoship'};
	$RequestRef->{'dateneeded'} = $CgiRef->{'dateneeded'};

	$RequestRef->{'hasrates'} = $self->{'customer'}->GetValueHashRef()->{'hasrates'};
	$RequestRef->{'autocsselect'} = $CgiRef->{'autocsselect'};
	$RequestRef->{'allowraterecalc'} = $CgiRef->{'allowraterecalc'};
	$RequestRef->{'manroutingctrl'} = $CgiRef->{'manroutingctrl'};
	$RequestRef->{'clientid'} = $CgiRef->{'clientid'};

	if ($params->{'pkg_detail_row_count'} > 0)
		{
		my $total_row_count = $params->{'pkg_detail_row_count'};
		$total_row_count =~ s/^Package_Row_//;

		for (my $index=1; $index <= $total_row_count; $index++)
			{
			my $PackageIndex = $self->get_row_id($index);
			$PackageIndex =~ s/^rownum_id_//;

			$RequestRef->{'weightlist'}     .= $params->{'weight_' . $PackageIndex } . ",";
			$RequestRef->{'quantitylist'}   .= $params->{'weight_' . $PackageIndex } . ",";
			$RequestRef->{'unittypelist'}   .= $params->{'weight_' . $PackageIndex } . ",";
			$RequestRef->{'dimlengthlist'}  .= $params->{'weight_' . $PackageIndex } . ",";
			$RequestRef->{'dimwidthlist'}   .= $params->{'weight_' . $PackageIndex } . ",";
			$RequestRef->{'dimheightlist'}  .= $params->{'weight_' . $PackageIndex } . ",";
			$RequestRef->{'datatypeidlist'} .= $params->{'weight_' . $PackageIndex } . ",";
			}
		}

	$RequestRef->{'productcount'} = $params->{'pkg_detail_row_count'};
	$RequestRef->{'quantityxweight'} = $CgiRef->{'quantityxweight'};
	$RequestRef->{'productparadigm'} = $CgiRef->{'productparadigm'};

	# TODO: Implement route support
	#$RequestRef->{'route'} = ( $CgiRef->{'action'} eq 'route' || $CgiRef->{'routeflag'} ) ? 1 : undef;

	# Inbound and dropship flags
	# $RequestRef->{'isinbound'} = ( defined($CgiRef->{'isinbound'}) && $CgiRef->{'isinbound'} == 1 ) ? 1 : 0;
	# $RequestRef->{'isdropship'} = ( defined($CgiRef->{'isdropship'}) && $CgiRef->{'isdropship'} == 1 ) ? 1 : 0;

	# Collect and thirdparty flags
	$RequestRef->{'collect'} = ( defined($CgiRef->{'freightcharges'}) && $CgiRef->{'freightcharges'} == 1 ) ? 1 : 0;
	$RequestRef->{'thirdparty'} = ( defined($CgiRef->{'freightcharges'}) && $CgiRef->{'freightcharges'} == 2 ) ? 1 : 0;

	# Flag for sorting CS list in cost order - currently used for 'route only' login level
	$RequestRef->{'sortcslist'} = $CgiRef->{'loginlevel'} eq '20' ? 1 : 0;

	# Flag for attaching rates to CS listing - currently 'route only' login level doesn't get display
	$RequestRef->{'displaychargesincslist'} = $CgiRef->{'loginlevel'} eq '20' ? 0 : 1;

	# Need agg weight and total quantity for Assessorial calcs
	$RequestRef->{'aggregateweight'} = $CgiRef->{'aggregateweight'};
	$RequestRef->{'totalquantity'} = $CgiRef->{'totalquantity'};

	($RequestRef->{'sopid'}, my $UsingAltSOP, my $AltSOPID) = $self->GetSOPID($CgiRef);

	if ( my $AggFreightClass = $self->GetAggregateFreightClass($CgiRef) )
		{
		$RequestRef->{'class'} = $AggFreightClass;
		}
	elsif (my $FreightClass = $self->GetFreightClass($CgiRef->{'class'}, $CgiRef->{'classlist'}, $CgiRef->{'weight'}, $CgiRef->{'dimlength'}, $CgiRef->{'dimwidth'}, $CgiRef->{'dimlheight'}, $CgiRef->{'density'}))
		{
		$RequestRef->{'class'} = $FreightClass;
		}

	# Pass order csid in for rating on first pass - reclacs don't take this into account.
	if ( !$CgiRef->{'allowraterecalc'} )
		{
		my %CSRef = %$RequestRef;
		my $CSRef = \%CSRef;
		$CSRef->{'coid'} = $CgiRef->{'coid'};
		$RequestRef->{'csid'} = $self->GetCOCustomerService($CSRef);
		}


	$RequestRef->{'customerid'} = $self->{'customer'}->GetValueHashRef()->{'customerid'};

	$RequestRef->{'required_assessorials'} = $self->GetRequiredAssessorials($CgiRef);


	my $ReturnRef = &APIRequest($RequestRef);

	my @CSIDs = split(/\t/,$ReturnRef->{'csids'}) if defined($ReturnRef->{'csids'});
	my @CSNames = split(/\t/,$ReturnRef->{'csnames'}) if defined($ReturnRef->{'csnames'});

	my $ListRef = {};
	for ( my $i = 0; $i < scalar(@CSIDs); $i ++ )
		{
		$ListRef->{$i} = {'key' => $CSIDs[$i], 'value' => $CSNames[$i]};
		}

	if ( !$RequestRef->{'csid'} )
		{
		($ListRef,$ReturnRef) = $self->GetOtherCarrierData($ListRef,$ReturnRef,$RequestRef,scalar(@CSIDs));
		}

	my $DefaultCSID = $ReturnRef->{'defaultcsid'};
	my $DefaultCost = $CgiRef->{'loginlevel'} eq '20' ? undef : $ReturnRef->{'defaultcost'};
	my $DefaultTotalCost = $CgiRef->{'loginlevel'} eq '20' ? undef : $ReturnRef->{'defaulttotalcost'};

	my $CostList = $CgiRef->{'loginlevel'} eq '20' ? undef : $ReturnRef->{'costlist'};

	$RequestRef->{'action'} = 'GetCSJSArrays';
	$RequestRef->{'csids'} = $ReturnRef->{'csids'};

	my $CSDataRef = &APIRequest($RequestRef);

	# Slip the cost weight list into the cs data ref
	$CSDataRef->{'costweightlist'} = $ReturnRef->{'costweightlist'};

	my $CSSecurityTypes = {};
	return ($ListRef, $DefaultCSID, $CostList, $CSDataRef, $DefaultCost, $CSSecurityTypes, $DefaultTotalCost, $UsingAltSOP, $AltSOPID);
	}
=cut
sub jsonify
	{
	my $self = shift;
	my $struct = shift;
	my $json = [];
	if (ref($struct) eq "ARRAY")
		{
		my $list = [];
		foreach my $item (@$struct)
			{
				if (ref($item) eq "" ){
					$item = $self->clean_json_data($item);
					push @$list, "\"$item\"";
				}
				else{
					push @$list, $self->jsonify($item);
				}
			}
		return "[" . join(",",@$list) . "]";

		}
	elsif (ref($struct) eq "HASH")
		{
		my $list = [];
		foreach my $key (keys %$struct)
			{
			my $val = $struct->{$key};
			if (ref($val) eq "" )
				{
				$val = $self->clean_json_data($val);
				push @$list, "\"$key\":\"$val\"";
				}
			else
				{
				push @$list, "\"$key\":" . $self->jsonify($struct->{$key});
				}
			}
		return "{" . join(',',@$list) . "}";
		}
	}

sub clean_json_data
	{
	my $self = shift;
	my $item = shift;

	$item =~ s/"/\\"/g;
	$item =~ s/\t+//g;
	$item =~ s/\n+//g;
	$item =~ s/\r+//g;
	$item =~ s/^\s+//g;
	$item =~ s/\s+$//g;

	return $item;
	}

sub OrderHasWeight
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	my $total_row_count = $params->{'pkg_detail_row_count'};
	$total_row_count =~ s/^Package_Row_//;

	for (my $index=1; $index <= $total_row_count; $index++)
		{
		my $PackageIndex = $self->get_row_id($index);
		$PackageIndex =~ s/^rownum_id_//;

		next if ($params->{'type_' . $PackageIndex } eq 'product');


		return 1 if ($params->{'weight_' . $PackageIndex } and $params->{'weight_' . $PackageIndex } > 0);
		}
	return undef;
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
