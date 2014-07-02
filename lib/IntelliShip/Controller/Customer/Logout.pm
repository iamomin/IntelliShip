package IntelliShip::Controller::Customer::Logout;
use Moose;
use namespace::autoclean;

BEGIN { extends 'IntelliShip::Controller::Customer'; }

=head1 NAME

IntelliShip::Controller::Customer::Logout - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    #$c->response->body('Matched IntelliShip::Controller::Customer::Logout in Customer::Logout.');

	if ($self->token)
		{
		$c->log->debug('@@@@@@@@ DELETING TOKEN ID: ' . $self->token->tokenid);
		$self->token->delete;
		$self->token(undef);

		$c->response->cookies->{'TokenID'} = { value => '', expires => '-20M' };
		}

	my $URI;
	## SSO logout for Motorola
	if ($ENV{HTTP_HOST} =~ /motorolasolutions/i)
		{
		$URI = $c->uri_for('https://converge.motorolasolutions.com/groups/global-procurement-intelliship-support-group');
		}
	else
		{
		$URI = $c->uri_for('/customer/login');
		}

	return $c->response->redirect($URI);
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
