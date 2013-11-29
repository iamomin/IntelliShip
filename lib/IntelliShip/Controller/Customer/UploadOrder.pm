package IntelliShip::Controller::Customer::UploadOrder;
use Moose;
use namespace::autoclean;

BEGIN { extends 'IntelliShip::Controller::Customer'; }

=head1 NAME

IntelliShip::Controller::Customer::UploadOrder - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;
	my $params = $c->req->params;

    #$c->response->body('Matched IntelliShip::Controller::Customer::UploadOrder in Customer::UploadOrder.');$c->log->debug("BATCH SHIPPINH");
	my $do_value = $params->{'do'} || '';
	if ($do_value eq 'batchship')
		{
		}
	else
		{
		$self->setup_upload_order;
		}
	}

sub setup_upload_order :Private
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;
	$c->stash(template => "templates/customer/upload-order.tt");
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
