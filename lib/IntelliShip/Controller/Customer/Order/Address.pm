package IntelliShip::Controller::Customer::Order::Address;
use Moose;
use Data::Dumper;
use namespace::autoclean;
use IntelliShip::DateUtils;

BEGIN { extends 'IntelliShip::Controller::Customer::Order'; }

=head1 NAME

IntelliShip::Controller::Customer::Order::Address - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    #$c->response->body('Matched IntelliShip::Controller::Customer::Order::Address in Customer::Order::Address.');

	#$c->stash->{addresslist} = $c->model("MyDBI::Address")->search({'country' => 'IN'});
	#$c->stash(addresslist => [$c->model('MyDBI::Assdata')->all]);
	#$c->log->debug("\n Address : " . Dumper $c->model("MyDBI::Address")->search({'country' => 'IN'}));

	if ($c->req->param('do') eq 'add')
		{
		$self->add;
		}
	else
		{
		$self->setup;
		}

	$c->stash(template => "templates/customer/order-address.tt");
}

sub setup :Local
	{
	my $self = shift;
	my $c = $self->context;

	if (length $c->req->param('fromcountry') or length $c->req->param('tocountry'))
		{
		}

	$c->stash->{customerlist_loop} = $self->get_select_list('CUSTOMER');
	$c->stash->{countrylist_loop} = $self->get_select_list('COUNTRY');
	$c->stash->{statelist_loop} = $self->get_select_list('US_STATES');
	}

sub add :Local
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	$c->log->debug("\n In Add PARAMS:\n" . Dumper $params);

	my $Order = $self->get_order;

	unless ($Order)
		{
		return $self->setup;
		}

	my $where = {
		addressname => $params->{'toname'},
		address1    => $params->{'toaddress1'},
		address2    => $params->{'toaddress2'},
		city        => $params->{'tocity'},
		state       => $params->{'tostate'},
		zip         => $params->{'tozip'},
		country     => $params->{'tocountry'},
		};

	my $existingAddress = $c->model("MyDBI::Address")->search($where)->count;
	if ($existingAddress)
		{
		$c->log->debug("\n TO ADDRESS:\n" . Dumper $existingAddress);
		}
	else
		{
		my $ToAddress = {
			addressid   => IntelliShip::DateUtils->timestamp,
			addressname => $params->{'toname'},
			address1    => $params->{'toaddress1'},
			address2    => $params->{'toaddress2'},
			city        => $params->{'tocity'},
			state       => $params->{'tostate'},
			zip         => $params->{'tozip'},
			country     => $params->{'tocountry'},
			};

		my $Address = $c->model("MyDBI::Address")->new($ToAddress);
		$Address->set_address_code_details;
		$Address->insert;
		}
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
