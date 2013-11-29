package IntelliShip::Controller::Customer::ShipPackages;
use Moose;
use namespace::autoclean;

BEGIN { extends 'IntelliShip::Controller::Customer'; }

=head1 NAME

IntelliShip::Controller::Customer::ShipPackages - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;
	my $params = $c->req->params;

    #$c->response->body('Matched IntelliShip::Controller::Customer::ShipPackages in Customer::ShipPackages.');
	$c->log->debug("SHIP PACKAGES");
	my $do_value = $params->{'do'} || '';
	if ($do_value eq 'shippackages')
		{
		}
	else
		{
		$self->setup_ship_packages;
		}
	}

sub setup_ship_packages :Private
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;
	$c->stash(template => "templates/customer/ship-packages.tt");
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
