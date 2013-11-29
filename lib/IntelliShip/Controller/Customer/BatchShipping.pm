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
		$self->setup_batch_shipping;
		}
	}

sub setup_batch_shipping :Private
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;
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
