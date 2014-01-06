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
	my $is_route = 0;
	$is_route = 1 if ($params->{'route'} == 1);

	my $freightcharges = 0;
	$self->context->log->debug("deliverymethod :". $params->{'deliverymethod'});
	$freightcharges = 1 if ($params->{'deliverymethod'} eq 'collect');
	$freightcharges = 2 if ($params->{'deliverymethod'} eq '3rdparty');

	$self->context->log->debug("freightcharges :". $freightcharges);
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
			$c->stash->{IS_ROUTE} = 1;
			$detail_hash->{'delivery'} = $estimated_date;
			$detail_hash->{'shipment_charge'} = $shipment_charge;
			$detail_hash->{'days'} = IntelliShip::DateUtils->get_delta_days(IntelliShip::DateUtils->current_date, $estimated_date);
			}

		push(@$carrier_service_list_loop, $detail_hash);
		}

	$c->stash->{CARRIER_SERVICE_LIST_LOOP} = $carrier_service_list_loop;
	$c->stash->{CARRIERSERVICE_LIST} = 1;
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
