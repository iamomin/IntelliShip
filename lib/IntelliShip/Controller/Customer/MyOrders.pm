package IntelliShip::Controller::Customer::MyOrders;
use Moose;
use Switch;
use namespace::autoclean;
use Data::Dumper;

BEGIN { extends 'IntelliShip::Controller::Customer::Order'; }

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
	if ($do_value eq 'review')
		{
		$self->review_order;
		}
	else
		{
		$self->display_my_orders;
		}
	}

my $TITLE = {
	''        => 'Not Shipped',
	'shipped' => 'Recently Shipped',
	'voided'  => 'Recently Voided',
	};

sub display_my_orders :Private
	{
	my $self = shift;
	my $c = $self->context;

	$self->populate_my_order_list;

	$c->stash->{view_list} = [
			{ name => 'Not Shipped', value => '' },
			{ name => 'Recently Shipped', value => 'shipped' },
			{ name => 'Recently Voided', value => 'voided' },
			];

	$c->stash->{recordsperpage_list} = $self->get_select_list('RECORDS_PER_PAGE');

	$c->stash(template => "templates/customer/my-orders.tt");
	}

sub populate_my_order_list
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	my $view = $params->{'view'} || "";
	my $SQL;
	if ($view eq 'shipped')
		{
		$SQL = $self->get_shipped_sql;
		}
	elsif ($view eq 'voided')
		{
		$SQL = $self->get_voided_sql;
		}
	else
		{
		$SQL = $self->get_not_shipped_sql; ## Not shipped / Open orders
		}

	#$c->log->debug("MY ORDER SQL : " . $SQL);

	my $myDBI = $c->model("MyDBI");
	my $sth = $myDBI->select($SQL);

	#$c->log->debug("TOTAL ORDERS FOUND: " . $sth->numrows);

	my $myorder_list = [];
	for (my $row=0; $row < $sth->numrows; $row++)
		{
		my $row_data = $sth->fetchrow($row);
		($row_data->{'a_class'}, $row_data->{'a_text'}) = $self->get_condition_info(0,$row_data->{'condition'});
		push(@$myorder_list, $row_data);
		}

	my $my_orders_batches = $self->process_pagination($myorder_list);
	my $first_batch = $my_orders_batches->[0];

	$myorder_list = [splice @$myorder_list, 0, scalar @$first_batch] if $first_batch;

	$c->stash->{myorder_list} = $myorder_list;
	$c->stash->{myorder_list_count} = @$myorder_list;
	$c->stash->{myorder_batches} = $my_orders_batches;

	$c->stash($params);
	$c->stash->{MY_ORDERS} = 1;
	$c->stash->{refresh_interval_sec} = 60;
	$c->stash->{list_title} = $TITLE->{$params->{'view'}} if $params->{'view'};
	}

sub process_pagination
	{
	my $self = shift;
	my $my_orders = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	$c->log->debug("PROCESS PAGINATION");

	my $batch_size = (defined $params->{records_per_page} ? int $params->{records_per_page} : 100);
	$c->stash->{records_per_page} = $batch_size;

	my @matching_ids = map { $_->{coid} } @$my_orders;
	my $my_orders_batch = $self->spawn_batches(\@matching_ids,$batch_size);

	$c->log->debug("TOTAL PAGES: " . @$my_orders_batch);
	#$c->log->debug("TOTAL PAGES: " . Dumper $my_orders_batch);

	$c->stash->{no_batches} = @$my_orders_batch == 0;

	return $my_orders_batch;
	}

sub get_not_shipped_sql :Private
	{
	my $self = shift;

	my $c = $self->context;
	my $params = $c->req->params;

	my $CustomerID = $self->customer->customerid;

	my $and_coid_in_sql = $self->get_coid_in_sql;
	my $and_COTypeID_SQL = $self->get_co_type_sql;
	my $and_AllowedExtCustNum_SQL = $self->get_allowed_ext_cust_num_sql;

	my $SQL_1 = "
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
		co
		INNER JOIN customer cu ON cu.customerid = co.customerid AND cu.customerid = '$CustomerID'
		INNER JOIN address oa ON cu.addressid = oa.addressid
		INNER JOIN address da ON co.addressid = da.addressid
	 WHERE
		co.statusid in (1,50,300,999,100)
		$and_coid_in_sql
		AND keep = 0
		AND (isdropship is null or isdropship = 0)
		$and_COTypeID_SQL
		$and_AllowedExtCustNum_SQL
	";

	if ($params->{'view'} and $params->{'view'} eq 'openorders')
		{
		$SQL_1 .= " AND (daterouted is not null or datepacked is not null) ";
		}

	# add drop ship sql
	my $SQL_2 = "
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
		co
		INNER JOIN customer cu ON cu.customerid = co.customerid AND cu.customerid = '$CustomerID'
		INNER JOIN address oa ON cu.addressid = oa.addressid
		INNER JOIN address da ON co.addressid = da.addressid
	 WHERE
		co.statusid in (1,50,300,999,100)
		$and_coid_in_sql
		AND keep = 0
		AND co.isdropship = 1
		$and_COTypeID_SQL
		$and_AllowedExtCustNum_SQL
	";

	if ($params->{'view'} and $params->{'view'} eq 'openorders')
		{
		$SQL_2 .= " AND (daterouted is not null or datepacked is not null) ";
		}

	my $SQL = "
	$SQL_1
	UNION
	$SQL_2
	";

	return $SQL;
	}

sub get_shipped_sql :Private
	{
	my $self = shift;

	my $c = $self->context;
	my $params = $c->req->params;
	my $Customer = $self->customer;
	my $Contact = $self->contact;

	my $CustomerID = $Customer->customerid;
	my $and_coid_in_sql = $self->get_coid_in_sql;
	my $and_AllowedExtCustNum_SQL = $self->get_allowed_ext_cust_num_sql;

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
			shipment s
			INNER JOIN co ON s.coid = co.coid AND co.customerid = '$CustomerID'
			INNER JOIN address oa ON oa.addressid = s.addressidorigin
			INNER JOIN address da ON da.addressid = s.addressiddestin
		WHERE
			s.statusid IN (10,100)
			$and_coid_in_sql
			AND s.dateshipped IS NOT NULL
			AND (s.dateshipped - interval '5 days') <= date('now')
			$and_AllowedExtCustNum_SQL
	";

	return $SQL;
	}

sub get_voided_sql :Private
	{
	my $self = shift;

	my $c = $self->context;
	my $params = $c->req->params;
	my $Customer = $self->customer;
	my $Contact = $self->contact;

	my $CustomerID = $Customer->customerid;
	my $and_coid_in_sql = $self->get_coid_in_sql;
	my $and_COTypeID_SQL = $self->get_co_type_sql;
	my $and_AllowedExtCustNum_SQL = $self->get_allowed_ext_cust_num_sql;

	my $SQL_1 = "
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
			shipment s
			INNER JOIN co ON co.coid = s.coid AND co.customerid = '$CustomerID'
			INNER JOIN address oa ON oa.addressid = s.addressidorigin
			INNER JOIN address da ON da.addressid = s.addressiddestin
		WHERE
			s.statusid IN (5,6,7)
			$and_coid_in_sql
			AND s.dateshipped IS NOT NULL
			AND s.dateshipped >= (date('now') - interval '5 days')
			$and_COTypeID_SQL
			$and_AllowedExtCustNum_SQL
	";

	my $SQL_2 = "
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
			co
			INNER JOIN customer cu ON cu.customerid = co.customerid AND cu.customerid = '$CustomerID'
			INNER JOIN address oa ON cu.addressid = oa.addressid
			INNER JOIN address da ON co.addressid = da.addressid
		WHERE
			co.statusid = 200
			$and_coid_in_sql
			AND (isdropship is null or isdropship = 0)
			$and_COTypeID_SQL
			$and_AllowedExtCustNum_SQL
	";

	my $SQL_3 = "
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
			co
			INNER JOIN customer cu ON cu.customerid = co.customerid AND cu.customerid = '$CustomerID'
			INNER JOIN address oa ON cu.addressid = oa.addressid
			INNER JOIN address da ON co.addressid = da.addressid
		WHERE
			co.statusid = 200
			$and_coid_in_sql
			AND co.isdropship = 1
			$and_COTypeID_SQL
			$and_AllowedExtCustNum_SQL
	";

	my $SQL = "
	$SQL_1
	UNION
	$SQL_2
	UNION
	$SQL_3
	";

	return $SQL;
	}

sub get_co_type_sql :Private
	{
	my $self = shift;
	my $Contact = $self->contact;

	my $login_level = $Contact->get_contact_data_value('loginlevel');
	my $COType = ($login_level == 35 or $login_level == 40) ? 2 : 1;

	return "AND cotypeid = " . $COType;
	}

sub get_coid_in_sql
	{
	my $self = shift;
	my $params = $self->context->req->params;
	return ($params->{'coids'} ? "AND co.coid IN ('" . join("','", split(',', $params->{'coids'})) . "') " : "") ;
	}

sub get_allowed_ext_cust_num_sql :Private
	{
	my $self = shift;
	my $Contact = $self->contact;
	my $arr = $Contact->get_restricted_values('extcustnum') if $Contact->is_restricted;
	return ($arr ? "AND upper(co.extcustnum) IN (" . join(',', @$arr) . ")" : '');
	}

sub review_order :Private
	{
	my $self = shift;
	$self->populate_order;
	}

sub ajax :Local
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	$c->log->debug("SETTINGS MYORDER AJAX");

	$self->populate_my_order_list;

	$c->stash->{ajax} = 1;
	$c->stash(template => "templates/customer/my-orders.tt");
	}

sub get_condition_info
	{
	my $self = shift;
	my $IndicatorType = shift || 0;
	my $Condition = shift;

	my $dataHash = {};

	switch ($IndicatorType)
		{
		## indicator text
		case 1
			{
			switch ($Condition)
				{
				case 1 { $dataHash->{'conditioncolor'} = '#FF0000'; $dataHash->{'conditiontext'} = 'Routed'   } # Red
				case 2 { $dataHash->{'conditioncolor'} = '#FF6600'; $dataHash->{'conditiontext'} = 'Packed'   } # Orange
				case 3 { $dataHash->{'conditioncolor'} = '#9900FF'; $dataHash->{'conditiontext'} = 'Received' } # Yellow/Purple
				case 4 { $dataHash->{'conditioncolor'} = '#66CC33'; $dataHash->{'conditiontext'} = 'Entered'  } # Green
				case 5 { $dataHash->{'conditioncolor'} = '#0000CC'; $dataHash->{'conditiontext'} = 'Shipped'  } # Blue
				case 6 { $dataHash->{'conditioncolor'} = '#666666'; $dataHash->{'conditiontext'} = 'Voided'   } # Black
				else   { $dataHash->{'conditioncolor'} = '#000000'; $dataHash->{'conditiontext'} = 'Unknown'  } # Default
				}
			}
		## indicator graphic text
		case 2
			{
				switch ($Condition)
					{
					case 1 { $dataHash->{'conditioncolor'} = 'Green-Routed' }
					case 2 { $dataHash->{'conditioncolor'} = 'Yellow-Packed' }
					case 3 { $dataHash->{'conditioncolor'} = 'Orange-Received' }
					case 4 { $dataHash->{'conditioncolor'} = 'Red-Entered' }
					case 5 { $dataHash->{'conditioncolor'} = 'Shipped-Blue' }
					case 6 { $dataHash->{'conditioncolor'} = 'Voided-Black' }
					else   { $dataHash->{'conditioncolor'} = 'Unknown-Unknown' }
					}
			}
		## indicator balls
		else
			{
				switch ($Condition)
					{
					case 1 { $dataHash->{'conditioncolor'} = 'red'    ; $dataHash->{'conditiontext'} = '!'   }
					case 2 { $dataHash->{'conditioncolor'} = 'orange' ; $dataHash->{'conditiontext'} = '!'   }
					case 3 { $dataHash->{'conditioncolor'} = 'yellow' ; $dataHash->{'conditiontext'} = '&Delta;' }
					case 4 { $dataHash->{'conditioncolor'} = 'green'  ; $dataHash->{'conditiontext'} = '&#10004;'  }
					case 5 { $dataHash->{'conditioncolor'} = 'blue'   ; $dataHash->{'conditiontext'} = '&#10004;'  }
					case 6 { $dataHash->{'conditioncolor'} = 'black'  ; $dataHash->{'conditiontext'} = '&#10004;'   }
					else   { $dataHash->{'conditioncolor'} = 'unknown'; $dataHash->{'conditiontext'} = 'Unknown'  }
				}
			}
		}

	$dataHash->{'conditiontext'} = '';
	return ($dataHash->{'conditioncolor'},$dataHash->{'conditiontext'});
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
