package IntelliShip::Controller::Customer::ShipPackages;
use Moose;
use namespace::autoclean;

BEGIN { extends 'IntelliShip::Controller::Customer::Order'; }

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
		$self->load_order;
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

sub load_order :Private
	{
	my $self = shift;

	my $c = $self->context;
	my $params = $c->req->params;

	return unless $self->is_valid_detail;

	$self->setup_quickship_page;
	}

sub is_valid_detail :Private
	{
	my $self = shift;

	my $c = $self->context;
	my $params = $c->req->params;
	IntelliShip::Utils->trim_hash_ref_values($params);

	my $cotypeid = $self->get_co_type;
	if (!$self->find_order($params->{'ordernumber'},$cotypeid))
		{
		$c->stash($params);

		$c->stash(ERROR => "Order not found");
		$c->stash(template => "templates/customer/ship-packages.tt");
		return undef;
		}

	return 1;
	}

sub find_order
	{
	my $self = shift;
	my $ordernumber = shift;
	my $cotypeid = shift || 1;

	my $c = $self->context;

	my $customerid = $self->customer->customerid;

	return $c->stash->{CO} if $c->stash->{CO};

	my @r_c = $c->model('MyDBI::Restrictcontact')->search({contactid => $self->contact->contactid, fieldname => 'extcustnum'});

	my $allowed_ext_cust_nums = [];
	push(@$allowed_ext_cust_nums, $_->{'fieldvalue'}) foreach @r_c;

	my @cos = $c->model('MyDBI::Co')->search({
						customerid => $customerid,
						ordernumber => uc($ordernumber),
						cotypeid => $cotypeid,
						extcustnum => $allowed_ext_cust_nums
						});

	unless (@cos)
		{
		my $strippedordernumber =  $ordernumber;
		$strippedordernumber =~ s/^0*//g;

		@cos = $c->model('MyDBI::Co')->search({
						customerid => $customerid,
						ordernumber => uc($strippedordernumber),
						cotypeid => $cotypeid
						});
		}

	if (@cos)
		{
		my $CO = $cos[0];
		$c->stash->{CO} = $CO;
		return $CO;
		}
	}

sub get_co_type
	{
	my $self = shift;
	my $c = $self->context;
	my $Contact = $self->contact;

	my $cotypeid = 1;
	if ($Contact->login_level == 35 or $Contact->login_level == 40)
		{
		$cotypeid = 2; # If contact is PO loginlevel (35 or 40), set cotype to PO
		}

	return $cotypeid;
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
