package IntelliShip::Controller::Customer::Order::Ajax;
use Moose;
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
	elsif ($c->req->param('action') eq 'get_customer_service_list')
		{
		$self->get_carrier_service_list;
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

sub get_carrier_service_list
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	if ($params->{'do'} eq 'step3')
		{
		$self->save_special_services;
		}
	else
		{
		#$self->save_order;
		}

	my $CO = $self->get_order;
	my $Contact = $self->contact;
	my $Customer = $self->customer;

	my $is_route = $params->{'route'} || 0;

	my $freightcharges = 0;
	#$self->context->log->debug("deliverymethod :". $params->{'deliverymethod'});
	$freightcharges = 1 if ($params->{'deliverymethod'} eq 'collect');
	$freightcharges = 2 if ($params->{'deliverymethod'} eq '3rdparty');

	#$self->context->log->debug("freightcharges :". $freightcharges);
	my $carrier_service_list_loop = [];

	my $APIRequest = IntelliShip::Arrs::API->new;
	$APIRequest->context($c);
	my ($response,$cs_data_ref, $carrier_list) = $APIRequest->get_carrrier_service_rate_list($CO,$Contact,$Customer, $is_route,$freightcharges);

	# my $DefaultCSID = $response->{'defaultcsid'};
	# my $DefaultCost = $Contact->login_level == 20 ? undef : $response->{'defaultcost'};
	# my $DefaultTotalCost = $Contact->login_level == 20 ? undef : $response->{'defaulttotalcost'};
	# my $CostList = $Contact->login_level == 20 ? undef : $response->{'costlist'};

	foreach my $Key (sort{$a<=>$b}(keys(%$carrier_list)))
		{
		my $CSData = $carrier_list->{$Key};

		my @carrier_service = split(/ - /,$CSData->{'value'});
		my $carrier = $carrier_service[0];

		my ($service, $estimated_date,$shipment_charge);
		if (scalar @carrier_service == 2)
			{
			my @service_namae = split(/-/,$carrier_service[1]);
			$service = $service_namae[0];
			$shipment_charge = $service_namae[1];
			}
		elsif (scalar @carrier_service == 3)
			{
			my @service_namae = split(/-/,$carrier_service[2]);
			$service = $carrier_service[1] . ' - ' . $service_namae[0];
			$shipment_charge = $service_namae[1];
			}

		if ($service =~ /\//)
			{
			my @service_est_date = split(/ /,$service);
			$estimated_date = pop(@service_est_date);

			$service = join(' ',@service_est_date);
			}

		my $detail_hash = {
							customerserviceid => $CSData->{'key'},
							carrier => $carrier,
							service => $service,
						};

		if ($is_route)
			{
			$c->stash->{IS_PREPAID} = 1;
			$detail_hash->{'delivery'} = $estimated_date;
			$detail_hash->{'shipment_charge'} = $shipment_charge;
			$detail_hash->{'days'} = IntelliShip::DateUtils->get_delta_days(IntelliShip::DateUtils->current_date, $estimated_date);
			}

		push(@$carrier_service_list_loop, $detail_hash);
		}

	$c->stash->{CARRIER_SERVICE_LIST_LOOP} = $carrier_service_list_loop;
	$c->stash->{CARRIERSERVICE_LIST} = 1;
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

	#$self->context->log->debug("in add_new_row : row_HTML");
	my $row_HTML = $c->forward($c->view('Ajax'), "render", [ "templates/customer/order-ajax.tt" ]);
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

=encoding utf8

=head1 AUTHOR

root

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
