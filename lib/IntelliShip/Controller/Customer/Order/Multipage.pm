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
	elsif ($do_value eq 'shipment')
		{
		$self->setup_shipment_information;
		}
	elsif ($do_value eq 'address')
		{
		$self->edit_address_details;
		}
	elsif ($do_value eq 'ship')
		{
		$self->SHIP_ORDER;
		}
	elsif ($do_value eq 'review')
		{
		$self->review_order;
		}
	elsif ($do_value eq 'cancel')
		{
		$self->cancel_order;
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
	$self->setup_shipment_information;
	}

sub complete_step2
	{
	my $self = shift;
	$self->save_package_product_details;
	$self->save_CO_details;
	$self->save_special_services;
	$self->setup_carrier_service;
	}

sub edit_address_details
	{
	my $self = shift;
	$self->save_CO_details;
	$self->save_package_product_details if defined $self->context->req->params->{weight_1};
	$self->setup_address;
	}

sub review_order
	{
	my $self = shift;
	$self->save_address;
	$self->setup_carrier_service;
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
