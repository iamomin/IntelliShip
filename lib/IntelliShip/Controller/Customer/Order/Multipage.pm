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
	elsif ($do_value eq 'shipment')
		{
		$self->setup_package_detail;
		}
	elsif ($do_value eq 'cancel')
		{
		$self->cancel_order;
		}
	elsif ($do_value eq 'ship')
		{
		$self->ship_order;
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
	$self->setup_carrier_service;
	}

sub complete_step3
	{
	my $self = shift;
	$self->save_CO_details;
	$self->setup_address;
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
