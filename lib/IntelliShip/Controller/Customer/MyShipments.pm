package IntelliShip::Controller::Customer::MyShipments;
use Moose;
use Data::Dumper;
use IntelliShip::Utils;
use namespace::autoclean;

BEGIN { extends 'IntelliShip::Controller::Customer'; }

=head1 NAME

IntelliShip::Controller::Customer::MyShipments - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    #$c->response->body('Matched IntelliShip::Controller::Customer::MyShipment in Customer::MyShipment.');

	$self->populate_my_shipment_list;

	$c->stash->{view_list} = [
			{ name => 'Shipped', value => 'shipped' },
			{ name => 'Delivered', value => 'delivered' },
			];

	$c->stash->{recordsperpage_list} = $self->get_select_list('RECORDS_PER_PAGE');

	$c->stash(template => "templates/customer/my-shipments.tt");
}

sub ajax :Local
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	$c->log->debug("SETTINGS SIHPMENT AJAX");

	$self->populate_my_shipment_list;

	$c->stash->{ajax} = 1;
	$c->stash(template => "templates/customer/my-shipments.tt");
	}

my $TITLE = {
	'shipped' => 'Shipped',
	'delivered'  => 'Delivered',
	};

sub populate_my_shipment_list :Private
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	my $view = $params->{'view'} || 'shipped';
	my $SQL;
	if ($view eq 'shipped')
		{
		$SQL = $self->get_shipped_sql;
		}
	else
		{
		$SQL = $self->get_delivered_sql;
		}

	my $myDBI = $c->model("MyDBI");
	#$c->log->debug("SQL: " . $SQL);
	my $sth = $myDBI->select($SQL);
	#$c->log->debug("sth->numrows: " . $sth->numrows);

	my $myshipment_list = [];
	for (my $row=0; $row < $sth->numrows; $row++)
		{
		my $row_data = $sth->fetchrow($row);
		($row_data->{'a_class'}, $row_data->{'a_text'}) = IntelliShip::Utils->get_status_ui_info(0,$row_data->{'condition'});
		push(@$myshipment_list, $row_data);
		}

	my $my_shipments_batches = $self->process_pagination('shipmentid',$myshipment_list);
	my $first_batch = $my_shipments_batches->[0];
	$myshipment_list = [splice @$myshipment_list, 0, scalar @$first_batch] if $first_batch;
	$c->stash->{myshipment_list} = $myshipment_list;
	$c->stash->{myshipment_list_count} = @$myshipment_list;
	$c->stash->{myshipment_batches} = $my_shipments_batches;

	$c->stash($params);
	$c->stash->{MY_SHIPMENTS} = 1;
	$c->stash->{refresh_interval_sec} = 60;
	$c->stash->{view_datedelivered} = ($params->{'view'} and $params->{'view'} eq 'delivered');
	$c->stash->{list_title} = $TITLE->{$params->{'view'}} if $params->{'view'};
	}

sub get_shipped_sql :Private
	{
	my $self = shift;

	my $c = $self->context;
	my $params = $c->req->params;
	my $Customer = $self->customer;
	my $Contact = $self->contact;

	my $CustomerID = $Customer->customerid;

	my $and_shipment_in_sql = $self->get_shipmentid_in_sql;

	my $SQL = "
		SELECT
			s.shipmentid,
			co.coid,
			da.addressname as customername,
			oa.city || ', ' || oa.state as origin,
			da.city || ', ' || da.state as destin,
			to_char(s.dateshipped,'MM/DD/YY') as dateshipped,
			to_char(s.datedue,'MM/DD/YY') as duedate,
			s.service,
			s.cost,
			s.carrier,
			s.mode,
			4 as condition,
			da.addressname as shiptoname,
			oa.addressname as shipfromname,
			to_char(s.datedelivered,'MM/DD/YY') as datedelivered
		FROM
			shipment s
			INNER JOIN co ON s.coid = co.coid AND co.customerid = '$CustomerID'
			INNER JOIN address oa ON oa.addressid = s.addressidorigin
			INNER JOIN address da ON da.addressid = s.addressiddestin
		WHERE
			s.dateshipped IS NOT NULL
			$and_shipment_in_sql
			AND s.datedelivered IS NULL
			AND (s.dateshipped - interval '5 days') <= date('now')
	";

	return $SQL;
	}

sub get_delivered_sql :Private
	{
	my $self = shift;

	my $c = $self->context;
	my $params = $c->req->params;
	my $Customer = $self->customer;
	my $Contact = $self->contact;

	my $CustomerID = $Customer->customerid;

	my $and_shipment_in_sql = $self->get_shipmentid_in_sql;

	my $SQL = "
		SELECT
			s.shipmentid,
			co.coid,
			da.addressname as customername,
			oa.city || ', ' || oa.state as origin,
			da.city || ', ' || da.state as destin,
			to_char(s.dateshipped,'MM/DD/YY') as dateshipped,
			s.service,
			s.cost,
			s.carrier,
			s.mode,
			5 as condition,
			da.addressname as shiptoname,
			oa.addressname as shipfromname,
			to_char(s.datedelivered,'MM/DD/YY') as datedelivered
		FROM
			shipment s
			INNER JOIN co ON s.coid = co.coid AND co.customerid = '$CustomerID'
			INNER JOIN address oa ON oa.addressid = s.addressidorigin
			INNER JOIN address da ON da.addressid = s.addressiddestin
		WHERE
			s.dateshipped IS NOT NULL
			$and_shipment_in_sql
			AND s.datedelivered IS NOT NULL
			AND (s.datedelivered - interval '5 days') <= date('now')
	";

	return $SQL;
	}

sub get_shipmentid_in_sql :Private
	{
	my $self = shift;
	my $params = $self->context->req->params;
	return ($params->{'shipmentids'} ? "AND s.shipmentid IN ('" . join("','", split(',', $params->{'shipmentids'})) . "') " : "") ;
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
