package IntelliShip::Controller::Customer::MyOrders;
use Moose;
use namespace::autoclean;

BEGIN { extends 'IntelliShip::Controller::Customer'; }

=head1 NAME

IntelliShip::Controller::Customer::MyOrders - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
	my ( $self, $c ) = @_;
	my $params = $c->req->params;

	#$c->response->body('Matched IntelliShip::Controller::Customer::MyOrders in Customer::MyOrders.');
	my $do_value = $params->{'do'} || '';
	if ($do_value eq 'xxx')
		{
		}
	else
		{
		$self->display_my_orders;
		}

	$c->stash(template => "templates/customer/my-orders.tt");
	}

sub display_my_orders
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	my $SQL;
	if ($params->{'view'} eq 'shipped')
		{
		$SQL = $self->get_shipped_sql;
		}
	elsif ($params->{'view'} eq 'voided')
		{
		$SQL = $self->get_voided_sql;
		}
	else
		{
		$SQL = $self->get_not_shipped_sql; ## Not shipped / Open orders
		}

	$c->log->debug("MY ORDER SQL : " . $SQL);

	my $myDBI = $c->model("MyDBI");
	my $sth = $myDBI->select($SQL);

	$c->log->debug("TOTAL ORDERS FOUND: " . $sth->numrows);

	my $myorder_list = [];
	for (my $row=0; $row < $sth->numrows; $row++)
		{
		my $row_data = $sth->fetchrow($row);

		push(@$myorder_list, $row_data);
		}

	$c->stash->{myorder_list} = $myorder_list;
	}


sub get_not_shipped_sql
	{
	my $self = shift;

	my $c = $self->context;
	my $params = $c->req->params;

	my $CustomerID = $self->customer->customerid;

	my $COTypeIDSQL = $self->get_co_type_sql;
	my $AllowedExtCustNumSQL = $self->get_allowed_ext_cust_num_sql;

	my $SQL = "
		SELECT
		co.coid,
		co.ordernumber,
		da.addressname as customername,
				CASE
				WHEN co.isinbound is null or co.isinbound=0 THEN oa.city || ', ' || oa.state
				WHEN co.isinbound = 1 THEN da.city || ', ' || da.state END
			as origin,
			CASE
				WHEN co.isinbound is null or co.isinbound=0 THEN da.city || ', ' || da.state
				WHEN co.isinbound = 1 THEN oa.city || ', ' || oa.state END
			as destin,
		co.extservice as service,
		to_char(coalesce(co.daterouted,co.datepacked,co.datereceived,co.datecreated), 'MM/DD/YY') as date,
		to_char(co.dateneeded,'MM/DD/YY') as duedate,
		to_char(co.datecreated,'MM/DD/YY') as podate,
		co.extcarrier as carrier,
		co.mode as mode,
		co.custref3,
		CASE
			WHEN co.daterouted is not null THEN 1
			WHEN co.datepacked is not null THEN 2
			WHEN co.datereceived is not null THEN 3
			WHEN co.daterouted is null and co.datepacked is null and co.datereceived is null THEN 4 END
		as condition,
		CASE
			WHEN co.isinbound is null or co.isinbound =0 THEN da.addressname
			WHEN co.isinbound = 1 THEN oa.addressname END
		as shiptoname,
		CASE
			WHEN co.isinbound is null or co.isinbound =0 THEN oa.addressname
			WHEN co.isinbound = 1 THEN da.addressname END
		as shipfromname,
		'' as dateshipped,
			co.extcustnum
	 FROM
		customer cu,
		co,
		address oa,
		address da
	 WHERE
		cu.customerid = co.customerid
		AND cu.addressid = oa.addressid
		AND co.addressid = da.addressid
		AND cu.customerid = '$CustomerID'
		AND co.statusid in (1,50,300,999,100)
		AND keep = 0
		AND (isdropship is null or isdropship = 0)
	";

	# Add cotypeid sql
	$SQL .= $COTypeIDSQL;

	if ($params->{'view'} eq 'openorders')
		{
		$SQL .= " AND (daterouted is not null or datepacked is not null) ";
		}

	if ($params->{'restrictedcontact'} and $params->{'restrictedcontact'} > 0)
		{
		$SQL .= " AND upper(co.extcustnum) in " . $AllowedExtCustNumSQL;
		}

	# add drop ship sql
	$SQL .= "
		UNION
	 	SELECT
		co.coid,
		co.ordernumber,
		da.addressname as customername,
		oa.city || ', ' || oa.state as origin,
		da.city || ', ' || da.state as destin,
		co.extservice as service,
		to_char(coalesce(co.daterouted,co.datepacked,co.datereceived,co.datecreated), 'MM/DD/YY') as date,
		to_char(co.dateneeded,'MM/DD/YY') as duedate,
		to_char(co.datecreated,'MM/DD/YY') as podate,
		co.extcarrier as carrier,
		co.mode as mode,
		co.custref3,
		CASE
			WHEN co.daterouted is not null THEN 1
			WHEN co.datepacked is not null THEN 2
			WHEN co.datereceived is not null THEN 3
			WHEN co.daterouted is null and co.datepacked is null and co.datereceived is null THEN 4 END
		as condition,
		da.addressname as shiptoname,
		oa.addressname as shipfromname,
		'' as dateshipped,
			co.extcustnum
	 FROM
		customer cu,
		co,
		address oa,
		address da
	 WHERE
		cu.customerid = co.customerid
		AND co.dropaddressid = oa.addressid
		AND co.addressid = da.addressid
		AND cu.customerid = '$CustomerID'
		AND co.statusid in (1,50,300,999,100)
		AND keep = 0
		AND co.isdropship = 1
	";

	# Add cotypeid sql
	$SQL .= $COTypeIDSQL;

	if ($params->{'view'} eq 'openorders')
		{
		$SQL .= " AND (daterouted is not null or datepacked is not null) ";
		}

	if ($params->{'restrictedcontact'} and $params->{'restrictedcontact'} > 0)
		{
		$SQL .= " AND upper(co.extcustnum) in " . $AllowedExtCustNumSQL;
		}

	return $SQL;
	}

sub get_shipped_sql
	{
	my $self = shift;

	my $c = $self->context;
	my $params = $c->req->params;
	my $Customer = $self->customer;
	my $Contact = $self->contact;

	my $CustomerID = $Customer->customerid;

	my $COTypeIDSQL = $self->get_co_type_sql;
	my $AllowedExtCustNumSQL = $self->get_allowed_ext_cust_num_sql;

	my $SQL = "
		SELECT
			co.coid,
			co.ordernumber,
			da.addressname as customername,
			oa.city || ', ' || oa.state as origin,
			da.city || ', ' || da.state as destin,
			to_char(s.dateshipped,'MM/DD/YY') as dateshipped,
			to_char(s.dateshipped,'MM/DD/YY') as date,
			to_char(s.datedue,'MM/DD/YY') as duedate,
			to_char(co.datecreated,'MM/DD/YY') as podate,
			s.service,
			s.carrier,
			s.tracking1 as tracking1,
			s.mode,
			5 as condition,
			s.shipmentid,
			coalesce(s.custref3,co.custref3) as custref3,
			da.addressname as shiptoname,
			oa.addressname as shipfromname,
			s.custnum as extcustnum,
			s.podname,
			to_char(s.datedelivered,'MM/DD/YY') as datedelivered
		FROM
			shipment s,
			co,
			address oa,
			address da
		WHERE
			s.coid = co.coid
			AND s.addressidorigin = oa.addressid
			AND s.addressiddestin = da.addressid
			AND co.customerid = '$CustomerID'
			AND s.dateshipped IS NOT NULL
			AND (s.dateshipped - interval '5 days') <= date('now')
			AND s.statusid in (10,100)
	";

	if ($Contact->is_restricted)
		{
		$SQL .= " AND upper(s.custnum) in " . $AllowedExtCustNumSQL;
		}

	return $SQL;
	}

sub get_voided_sql
	{
	my $self = shift;

	my $c = $self->context;
	my $params = $c->req->params;
	my $Customer = $self->customer;
	my $Contact = $self->contact;

	my $COTypeIDSQL = $self->get_co_type_sql;
	my $AllowedExtCustNumSQL = $self->get_allowed_ext_cust_num_sql;

	my $CustomerID = $Customer->customerid;

	my $SQL = "
		SELECT
			co.coid,
			co.ordernumber,
			da.addressname as customername,
			oa.city || ', ' || oa.state as origin,
			da.city || ', ' || da.state as destin,
			to_char(s.dateshipped,'MM/DD/YY') as dateshipped,
			to_char(s.dateshipped,'MM/DD/YY') as date,
			to_char(s.datedue,'MM/DD/YY') as duedate,
			to_char(co.datecreated,'MM/DD/YY') as podate,
			s.service,
			s.carrier,
			s.tracking1 as tracking1,
			s.mode,
			6 as condition,
			s.shipmentid,
			coalesce(s.custref3,co.custref3) as custref3,
			da.addressname as shiptoname,
			oa.addressname as shipfromname,
			s.custnum as extcustnum,
			s.podname,
			to_char(s.datedelivered,'MM/DD/YY') as datedelivered
		FROM
			shipment s,
			co,
			address oa,
			address da
		WHERE
			s.coid = co.coid
			AND s.addressidorigin = oa.addressid
			AND s.addressiddestin = da.addressid
			AND co.customerid = '$CustomerID'
			AND s.dateshipped IS NOT NULL
			AND s.dateshipped >= (date('now') - interval '5 days')
			AND s.statusid in (5,6,7)
	";

	# Add cotypeid sql
	$SQL .= $COTypeIDSQL;

	if ($Contact->is_restricted)
		{
		$SQL .= " AND upper(s.custnum) in " . $AllowedExtCustNumSQL;
		}

	$SQL .= "
		UNION
		SELECT
			co.coid,
			co.ordernumber,
			da.addressname as customername,
			CASE
				WHEN co.isinbound is null or co.isinbound=0 THEN oa.city || ', ' || oa.state
				WHEN co.isinbound = 1 THEN da.city || ', ' || da.state END
			as origin,
			CASE
				WHEN co.isinbound is null or co.isinbound=0 THEN da.city || ', ' || da.state
				WHEN co.isinbound = 1 THEN oa.city || ', ' || oa.state END
			as destin,
			'' as dateshipped,
			to_char(coalesce(co.daterouted,co.datepacked,co.datereceived,co.datecreated), 'MM/DD/YY') as date,
			to_char(co.dateneeded,'MM/DD/YY') as duedate,
			to_char(co.datecreated,'MM/DD/YY') as podate,
			co.extservice as service,
			co.extcarrier as carrier,
			'' as tracking1,
			co.mode as mode,
			6 as condition,
			'' as shipmentid,
			co.custref3,
			CASE
			WHEN co.isinbound is null or co.isinbound =0 THEN da.addressname
			WHEN co.isinbound = 1 THEN oa.addressname END
		as shiptoname,
			CASE
			WHEN co.isinbound is null or co.isinbound =0 THEN oa.addressname
			WHEN co.isinbound = 1 THEN da.addressname END
		as shipfromname,
			co.extcustnum,
			'' as podname,
			'' as datedelivered
		FROM
			customer cu,
			co,
			address oa,
			address da
		WHERE
			cu.customerid = co.customerid
			AND cu.addressid = oa.addressid
			AND co.addressid = da.addressid
			AND cu.customerid = ?
			AND co.statusid = 200
			AND (isdropship is null or isdropship = 0)
	";

	# Add cotypeid sql
	$SQL .= $COTypeIDSQL;

	if ($Contact->is_restricted)
		{
		$SQL .= " AND upper(co.extcustnum) in " . $AllowedExtCustNumSQL;
		}

	$SQL .= "
		UNION
		SELECT
			co.coid,
			co.ordernumber,
			da.addressname as customername,
			oa.city || ', ' || oa.state as origin,
		da.city || ', ' || da.state as destin,
			'' as dateshipped,
			to_char(coalesce(co.daterouted,co.datepacked,co.datereceived,co.datecreated), 'MM/DD/YY') as date,
			to_char(co.dateneeded,'MM/DD/YY') as duedate,
			to_char(co.datecreated,'MM/DD/YY') as podate,
			co.extservice as service,
			co.extcarrier as carrier,
			'' as tracking1,
			co.mode as mode,
			6 as condition,
			'' as shipmentid,
			co.custref3,
		da.addressname as shiptoname,
		oa.addressname as shipfromname,
			co.extcustnum,
			'' as podname,
			'' as datedelivered
		FROM
			customer cu,
			co,
			address oa,
			address da
		WHERE
			cu.customerid = co.customerid
			AND co.dropaddressid = oa.addressid
			AND co.addressid = da.addressid
			AND cu.customerid = ?
			AND co.statusid = 200
			AND co.isdropship = 1
	";

	# Add cotypeid sql
	$SQL .= $COTypeIDSQL;

	if ($Contact->is_restricted)
		{
		$SQL .= " AND upper(co.extcustnum) in " . $AllowedExtCustNumSQL;
		}

	return $SQL;
	}

sub get_co_type_sql :Private
	{
	my $self = shift;
	my $Contact = $self->contact;

	my $login_level = $Contact->get_contact_data_value('loginlevel');
	my $COType = ($login_level == 35 or $login_level == 40) ? 2 : 1;

	return " AND cotypeid = " . $COType;
	}

sub get_allowed_ext_cust_num_sql :Private
	{
	my $self = shift;
	my $Contact = $self->contact;
	my $arr = $Contact->get_restricted_values('extcustnum') if $Contact->is_restricted;
	return ($arr ? " AND upper(co.extcustnum) IN (" . join(',', @$arr) . ")" : '');
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
