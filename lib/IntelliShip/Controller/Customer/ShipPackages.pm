package IntelliShip::Controller::Customer::ShipPackages;
use Moose;
use Data::Dumper;
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

	my $do_value = $params->{'do'} || '';

	if ($do_value eq 'shippackages')
		{
		my $COIDList = (ref $params->{'coids'} eq 'ARRAY' ? $params->{'coids'} : [$params->{'coids'}]);
		$c->stash->{COIDS} = $COIDList;
		$self->load_order;
		}
	else
		{
		$self->setup_ship_packages;
		}
	}

sub ajax :Local
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	if ($params->{'multiordershipment'})
		{
		$self->load_multiple_order;
		}

	$c->stash(template => "templates/customer/ship-packages.tt");
	}

sub setup_ship_packages :Private
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;
	$c->stash(template => "templates/customer/ship-packages.tt");
	}

sub load_multiple_order :Private
	{
	my $self = shift;
	my $c = $self->context;

	my $params = $c->req->params;
	my $Contact = $self->contact;
	my $Customer = $self->customer;

	$c->stash->{MULTIORDER_DISPLAY} = 1;

	my $CustomerID = $Customer->customerid;
	my $ordernumber = $params->{'ordernumber'};

	my @arr = $c->model('MyDBI::CO')->search({ ordernumber => $params->{ordernumber}});
	my $CO = $arr[0] if @arr;

	return unless $CO;

	my $Address   = $CO->to_address;
	my $AddressID = $Address->addressid;
	my $cotypeid  = $self->get_co_type;

	my $SQL = "
		SELECT
			coid,
			ordernumber
		FROM
			co
		WHERE
			co.addressid = '$AddressID'
			AND co.customerid = '$CustomerID'
			AND (co.combine = 0 OR co.combine IS NULL)
			AND statusid not in (5,6,7,200)
			AND cotypeid = $cotypeid
		";

	if ($Contact->is_restricted)
		{
		my $extValues = $Contact->get_restricted_values('extcustnum');
		$SQL .= " AND upper(co.extcustnum) IN ('" . join("', '", @$extValues) . "' ) ";
		}

	 $SQL .= " ORDER BY ordernumber";

	$c->log->debug("SQL: " . $SQL);

	my $sth = $c->model("MyDBI")->select($SQL);

	$c->log->debug("Total Rows: " . $sth->numrows);

	if ($sth->numrows)
		{
		my $multi_order_list = $sth->query_data ;
		$c->log->debug("DATA: " . Dumper($multi_order_list));
		my $matching_orders = [];
		push(@$matching_orders, { coid => $_->[0], ordernumber => $_->[1] }) foreach @$multi_order_list;
		$c->stash->{multi_order_list} = $matching_orders;
		}

	$c->stash->{address_info} = $Address;
	}

sub load_order :Private
	{
	my $self = shift;
	my $c = $self->context;

	my $params = $c->req->params;
	my $Contact = $self->contact;

	unless ($self->fetch_valid_order)
		{
		$c->stash(ERROR => "Order not found");
		return $self->setup_ship_packages;
		}

	my $CO = $c->stash->{CO};

	if ($params->{'multiordershipment'} and $params->{'coids'})
		{
		$params->{'coids'} = $c->stash->{COIDS};
		}
	else
		{
		$params->{'coid'} = $CO->coid;
		}

	$params->{'packprodata'} = "datainmultiplrorder";

	my $Address = $CO->to_address;

	$c->stash->{CONSOLIDATE} = 1;

	$self->quickship;

	#if ( $self->get_co_type == 2 && $Contact->is_restricted() )
	#	{
	#	$CgiRef->{'screen'} = 'vendorpo';
	#	}
	#else
	#	{
	#	$c->stash->{totalquantity} = $params->{'quantity'};
	#	$CgiRef->{'totalquantity'} = $CgiRef->{'quantity'};
    #
	#	$CgiRef->{'singleordershipment'} = $self->{'customer'}->GetCustomerValue('singleordershipment');
    #
	#	# Sort out cotype (regular order or PO)
	#	$c->stash->{cotypeid} = $self->get_co_type($Contact);
	#	#$CgiRef->{'cotypeid'} = $self->GetCOType($CgiRef->{'contactid'});
    #
	#	my $ordernumber = $CO->ordernumber;
	#	my $statusid = $CO->statusid;
	#	if ( defined($ordernumber) && $ordernumber ne '' )
	#		{
	#		$c->stash->{ordernumber} = $ordernumber;
	#		}
    #
	#	if ( $params->{'singleordershipment'} && $statusid != 1 )
	#		{
	#		#$CgiRef->{'screen'} = 'myorders';
	#		#$CgiRef->{'searchtype'} = 'ordernumber';
	#		#$CgiRef->{'view'} = 'search';
	#		#$CgiRef->{'search'} = $CgiRef->{'ordernumber'};
	#		$self->quickship;
	#		}
	#	elsif ( $self->{'customer'}->{'autoprocess'} && ( !defined($CgiRef->{'overrideautoprocess'}) || $CgiRef->{'overrideautoprocess'} ne '1' ) )
	#		{
	#		#$CgiRef->{'screen'} = 'autoshipping';
	#		#$CgiRef->{'action'} = 'shiporder';
	#		#$Return = 0;
	#		}
	#	else
	#		{
	#		#$CgiRef->{'screen'} = 'shipconfirm';
	#		}
    #
	#	$self->quickship;
	#	}
	}

sub fetch_valid_order :Private
	{
	my $self = shift;
	my $c = $self->context;

	my $params = $c->req->params;
	my $Contact = $self->contact;

	IntelliShip::Utils->trim_hash_ref_values($params);

	my $cotypeid = $self->get_co_type;
	my $ordernumber = $params->{'ordernumber'} || '';

	my $customerid = $self->customer->customerid;

	my $WHERE = {
			customerid => $customerid,
			ordernumber => uc($ordernumber),
			cotypeid => $cotypeid
			};

	$WHERE->{extcustnum} = $Contact->get_restricted_values('extcustnum') if $Contact->is_restricted;

	my @cos = $c->model('MyDBI::Co')->search($WHERE);

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
		$c->req->params->{do} = undef;
		$c->req->params->{coid} = $CO->coid;
		$c->log->debug("CO found, id: " . $CO->coid);
		return 1;
		}

	$c->log->debug("ShipPackages: CO NOT FOUND");

	return undef;
	}

sub get_co_type
	{
	my $self = shift;
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
