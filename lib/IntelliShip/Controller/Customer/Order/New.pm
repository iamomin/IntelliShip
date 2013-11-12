package IntelliShip::Controller::Customer::Order::New;
use Moose;
use namespace::autoclean;

BEGIN { extends 'IntelliShip::Controller::Customer::Order'; }

=head1 NAME

IntelliShip::Controller::Customer::Order::New - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;
    #$c->response->body('Matched IntelliShip::Controller::Customer::Order::New in Customer::Order::New.');

	my $do_value = $c->req->param('do') || '';

	if ($do_value eq 'add')
		{
		$self->add;
		}
	elsif ( $do_value eq 'quick')
		{
		}
	else
		{
		$self->setup;
		}

	$c->stash(template => "templates/customer/order.tt");
}

sub setup :Private
	{
    my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	($params->{'ordernumber'},$params->{'hasautoordernumber'}) = $self->get_auto_order_number($params->{'ordernumber'});

	$c->stash->{ordernumber} = $params->{'ordernumber'};
	$c->stash->{customer} = $self->customer;
	$c->stash->{customerAddress} = $self->customer->address;
	$c->stash->{customerlist_loop} = $self->get_select_list('CUSTOMER');
	$c->stash->{countrylist_loop} = $self->get_select_list('COUNTRY');
	$c->stash->{statelist_loop} = $self->get_select_list('US_STATES');
	$c->stash->{specialservice_loop} = $self->get_select_list('SPECIAL_SERVICE');
	$c->stash->{packageunittype_loop} = $self->get_select_list('PACKAGE_UNIT_TYPE');
	$c->stash->{deliverymethod_loop} = $self->get_select_list('DELIVERY_METHOD');

	$c->stash->{default_country} = "US";
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
