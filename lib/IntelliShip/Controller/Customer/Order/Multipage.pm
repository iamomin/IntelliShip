package IntelliShip::Controller::Customer::Order::Multipage;
use Moose;
use namespace::autoclean;
use IntelliShip::Controller::Customer::Ajax;

BEGIN { extends 'IntelliShip::Controller::Customer::Order'; }

=head1 NAME

IntelliShip::Controller::Customer::Order::Multipage - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    #$c->response->body('Matched IntelliShip::Controller::Customer::Order::Multipage in Customer::Order::Multipage.');

	my $do_value = $c->req->param('do') || '';
	if ($do_value eq 'step1')
		{
		$self->complete_step1;
		}
	elsif ($do_value eq 'step2')
		{
		$self->complete_step2;
		}
	elsif ($do_value eq 'step3')
		{
		$self->complete_step3;
		}
	elsif ($do_value eq 'cancel')
		{
		$self->cancel_order;
		}
	elsif ($do_value eq 'shipment')
		{
		$self->setup_package_detail;
		}
	else
		{
		$self->setup_address;
		}
}

sub complete_step1
	{
	my $self = shift;
	$self->save_address;
	$self->save_CO_details;
	$self->setup_package_detail;
	}

sub complete_step2
	{
	my $self = shift;
	$self->save_package_product_details;
	$self->save_CO_details;
	$self->setup_review;
	}

sub complete_step3
	{
	my $self = shift;
	$self->save_CO_details;
	$self->setup_address;
	}

sub setup_address
	{
	my $self = shift;
	my $c = $self->context;

	$c->stash->{ordernumber} = $self->get_order->coid;
	$c->stash->{customer} = $self->customer;
	$c->stash->{customerAddress} = $self->customer->address;
	$c->stash->{customerlist_loop} = $self->get_select_list('CUSTOMER');
	$c->stash->{countrylist_loop} = $self->get_select_list('COUNTRY');
	$c->stash->{statelist_loop} = $self->get_select_list('US_STATES');
	$c->stash->{tooltips} = $self->get_tooltips;

	if ($c->req->param('do') eq 'address')
		{
		$c->stash->{populate} = 'address';
		$self->populate_order;
		}

	$c->stash(template => "templates/customer/order-address.tt");
	}

sub setup_package_detail
	{
	my $self = shift;
	my $c = $self->context;
	$c->log->debug("__ SETUP PACKAGE DETAIL");
	$c->stash->{packageunittype_loop} = $self->get_select_list('UNIT_TYPE');

	my $CO = $self->get_order;
	my $Customer = $self->customer;
	#$c->log->debug("CA : " . $Customer->address->country);
	#$c->log->debug("COA: " . $CO->to_address->country);
	if ($Customer->address->country ne $CO->to_address->country)
		{
		$c->log->debug("... customer address and drop address not same, INTERNATIONAL shipment");
		my $CA = IntelliShip::Controller::Customer::Ajax->new;
		$CA->context($c);
		$CA->set_international_details;
		$c->stash->{INTERNATIONAL_AND_COMMODITY} = $c->forward($c->view('Ajax'), "render", [ "templates/customer/ajax.tt" ]);
		}

	$c->stash->{tooltips} = $self->get_tooltips;

	$c->stash->{populate} = 'shipment';
	$self->populate_order;

	$c->stash(template => "templates/customer/order-shipment.tt");
	}

sub setup_review
	{
	my $self = shift;
	my $c = $self->context;

	$c->stash->{populate} = 'summary';
	$self->populate_order;

	$c->stash->{deliverymethod_loop} = $self->get_select_list('DELIVERY_METHOD');
	$c->stash->{specialservice_loop} = $self->get_select_list('SPECIAL_SERVICE');

	$c->stash->{deliverymethod} = "prepaid";
	$c->stash(template => "templates/customer/order-summary.tt");
	}

sub cancel_order
	{
	my $self = shift;
	$self->void_shipment;
	$self->setup_address;
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
