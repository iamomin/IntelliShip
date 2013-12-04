package IntelliShip::Controller::Customer::BatchShipping;
use Moose;
use namespace::autoclean;

BEGIN { extends 'IntelliShip::Controller::Customer'; }

=head1 NAME

IntelliShip::Controller::Customer::BatchShipping - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;
	my $params = $c->req->params;

    #$c->response->body('Matched IntelliShip::Controller::Customer::BatchShipping in Customer::BatchShipping.');
	$c->log->debug("BATCH SHIPPINH");
	my $do_value = $params->{'do'} || '';
	if ($do_value eq 'batchship')
		{
		}
	else
		{
		$self->setup;
		}
	}

sub setup :Private
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	$c->stash->{carrier_list} = $self->get_select_list('CARRIER');
	$c->stash->{carrierservice_list} = $self->get_select_list('CARRIER_SERVICE');
	$c->stash->{extcd_list} = $self->get_select_list('PRODUCT_DESCRIPTION');
	$c->stash->{customernumber_list} = $self->get_select_list('CUSTOMER_NUMBER');
	$c->stash->{department_list} = $self->get_select_list('DEPARTMENT');
	$c->stash->{destination_address_list} = $self->get_select_list('DESTINATION_ADDRESS');
	$c->stash->{destination_state_list} = $self->get_select_list('US_STATES');

	$c->stash(template => "templates/customer/batch-shipping.tt");
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
