package IntelliShip::Controller::Customer::Order::Ajax;
use Moose;
use Data::Dumper;
use namespace::autoclean;
use IntelliShip::HTTP;
use IntelliShip::Utils;
use IntelliShip::DateUtils;

BEGIN { extends 'IntelliShip::Controller::Customer::Order'; }

=head1 NAME

IntelliShip::Controller::Customer::Order::Ajax - Catalyst Controller

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

	$c->stash(template => "templates/customer/order-ajax.tt");
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
	elsif ($action eq 'carrier_list')
		{
		$self->set_carrier_list;
		}
	}

sub set_international_details
	{
	my $self = shift;
	my $c = $self->context;

	$c->stash->{countrylist_loop} = $self->get_select_list('COUNTRY');
	$c->stash->{INTERNATIONAL} = 1;
	}

sub set_carrier_list
	{
	my $self = shift;
	my $c = $self->context;

	$c->stash->{CARRIER_LIST} = $self->get_select_list('CARRIER');
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
	my $row_HTML = $c->forward($c->view('Ajax'), "render", [ "templates/customer/order-ajax.tt" ]);
	$c->stash->{PKG_DETAIL_ROW} = 0;

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
		$self->context->log->debug("add_new_row : freight_class : |" . $freight_class."|");
		$response_hash->{ 'freight_class'} = $freight_class;
		}
	else
		{
		$response_hash->{ 'freight_class'} = '0';
		}

	return $response_hash;
	}

sub set_third_party_delivery
	{
	my $self = shift;
	my $c = $self->context;

	$c->stash->{statelist_loop} = $self->get_select_list('US_STATES');
	$c->stash->{countrylist_loop} = $self->get_select_list('COUNTRY');
	$c->stash->{THIRD_PARTY_DELIVERY} = 1;
	my $row_HTML = $c->forward($c->view('Ajax'), "render", [ "templates/customer/order-ajax.tt" ]);
	$c->stash->{THIRD_PARTY_DELIVERY} = 0;

	return { rowHTML => $row_HTML };
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

=encoding utf8

=head1 AUTHOR

root

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
