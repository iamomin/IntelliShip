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

	$c->stash->{customerlist_loop} = $self->get_select_list('CUSTOMER');
	$c->stash->{countrylist_loop} = $self->get_select_list('COUNTRY');
	$c->stash->{statelist_loop} = $self->get_select_list('US_STATES');
	$c->stash->{specialservice_loop} = $self->get_select_list('SPECIAL_SERVICE');
    #$c->response->body('Matched IntelliShip::Controller::Customer::Order::New in Customer::Order::New.');
	$c->stash(template => "templates/customer/order.tt");
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
