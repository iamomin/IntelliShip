package IntelliShip::Controller::Customer::Ajax;
use Moose;
use Data::Dumper;
use namespace::autoclean;
use IntelliShip::HTTP;
use IntelliShip::Utils;
use IntelliShip::DateUtils;
use IntelliShip::Arrs::API;

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
	}

sub get_HTML :Private
	{
	my $self = shift;
	my $c = $self->context;

	my $action = $c->req->param('action');
	if ($action eq 'get_my_customer_list')
		{
		$self->get_my_customer_list;
		}
	elsif ($action eq 'get_customer_carriers')
		{
		$self->get_customer_carriers;
		}
	elsif ($action eq 'costatus_chkbox')
		{
		$self->set_costatus_chkbox;
		}

	$c->stash(template => "templates/customer/ajax.tt");
	}

sub get_my_customer_list
	{
	my $self = shift;
	my $c = $self->context;
	$c->stash->{mycustomers_loop} = $self->get_select_list('MY_CUSTOMERS');
	}

sub get_customer_carriers
	{
	my $self = shift;
	my $c = $self->context;
	$c->stash->{CUSTOMER_CARRIERS} = 1;
	$c->stash->{CARRIER_LIST} = $self->get_select_list('CUSTOMER_CARRIERS', $c->req->params);
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
	if ($params->{'action'} eq 'get_city_state')
		{
		$dataHash = $self->get_city_state;
		}
	elsif ($params->{'action'} eq 'get_address_detail')
		{
		$dataHash = $self->get_address_detail;
		}
	elsif ($params->{'action'} eq 'validate_department')
		{
		$dataHash = $self->validate_department;
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

sub get_city_state :Private
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	my $address = $params->{'zipcode'};
	   $address .= ',' . $params->{'city'} if $params->{'city'};
	   $address .= ',' . $params->{'state'} if $params->{'state'};
	   $address .= ',' . $params->{'country'} if $params->{'country'};

	my $URI = 'address=' . $address . '&sensor=true&eventtime=' . IntelliShip::DateUtils->timestamp;
	#$c->log->debug("URI: " . $URI);

	my $HTTP = IntelliShip::HTTP->new;
	$HTTP->method('GET');
	$HTTP->host_production('maps.googleapis.com/maps/api/geocode/xml');
	$HTTP->uri_production($URI);
	$HTTP->timeout('30');

	my $result = $HTTP->send;
	my $responseDS = IntelliShip::Utils->parse_XML($result);
	#$c->log->debug("get_city_state result : " . Dumper $result);
	#$c->log->debug("get_city_state responseDS : " . Dumper $responseDS);

	my ($address1, $address2, $city, $state, $zip, $country);
	if ($responseDS->{'GeocodeResponse'}->{'status'} eq 'OK')
		{
		my $geocodeResponse = $responseDS->{'GeocodeResponse'}->{'result'};
		my $GeoCodes     = (ref $geocodeResponse eq 'ARRAY' ? $geocodeResponse : [$geocodeResponse]);
		foreach my $GeoCode (@$GeoCodes)
			{
			my $formatted_address = $GeoCode->{'formatted_address'};
			my $address_components = $GeoCode->{'address_component'};

			foreach my $component (@$address_components)
				{
				#$c->log->debug("ref component->{type}: " . ref $component->{type});
				$component->{type} = join(' | ', @{$component->{type}}) if (ref $component->{type}) =~ /array/gi;
				#$c->log->debug("component->{type}: " . $component->{type});

				$city = $component->{short_name} if $component->{type} =~ /locality/;
				$state = $component->{short_name} if $component->{type} =~ /administrative_area_level_1/;
				$zip = $component->{short_name} if $component->{type} =~ /postal_code/;
				$country = $component->{short_name} if $component->{type} =~ /country/;
				}

			last if $zip == $params->{'zipcode'};
			}
		}

	$c->log->debug("address1: $address1, address2: $address2, city: $city, state: $state, zip: $zip, country: $country");

	return { city => $city, state => $state, zip => $zip, country => $country };
	}

sub get_address_detail :Private
	{
	my $self = shift;
	my $c = $self->context;
	my $CO = $self->context->model('MyDBI::Co')->find({ coid => $c->req->params->{'referenceid'} });
	my $Address = $self->context->model('MyDBI::Address')->find({addressid => $CO->addressid}); 

	return { addressname => $Address->addressname, address1 => $Address->address1, address2 => $Address->address2, city => $Address->city, state => $Address->state, zip => $Address->zip, country => $Address->country, contactname => $CO->contactname, contactphone => $CO->contactphone, extcustnum => $CO->extcustnum, shipmentnotification => $CO->shipmentnotification};
	}

sub validate_department :Private
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	my $WHERE = { 
				customerid => $params->{'customerid'}, 
				field => 'department', 
				fieldvalue => $params->{'term'}
				};

	my $department_found = $c->model('MyDBI::Droplistdata')->search($WHERE)->count;

	unless ($department_found)
		{
		## If no department found for customer then bypass the validations
		delete $WHERE->{'fieldvalue'};
		$department_found = ($c->model('MyDBI::Droplistdata')->search($WHERE)->count == 0);
		}

	return { COUNT => $department_found };
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
