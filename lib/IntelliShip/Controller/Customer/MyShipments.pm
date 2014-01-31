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

	$c->stash->{date_list} = [
			{ name => 'Today', value => 'today' },
			{ name => 'This Week', value => 'this_week' },
			{ name => 'This Month', value => 'this_month' },
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

my $TITLE ;
my $TITLE_DATE = {
	'today' => 'Today',
	'this_week'  => 'This Week',
	'this_month'  => 'This Month',
	};

sub populate_my_shipment_list :Private
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;
	my $SQL;

	my $do_value = $params->{'do'} || '';
	if ($do_value eq 'batchoptions')
		{
		#$self->batch_options;
		}
	else
		{
		$SQL = $self->get_shipped_sql;
		}

	my $myDBI = $c->model("MyDBI");
	my $sth = $myDBI->select($SQL);

	my $myshipment_list = [];
	for (my $row=0; $row < $sth->numrows; $row++)
		{
		my $row_data = $sth->fetchrow($row);
		($row_data->{'a_class'}, $row_data->{'a_text'}) = IntelliShip::Utils->get_status_ui_info(0,$row_data->{'condition'});
		push(@$myshipment_list, $row_data);
		}

	my $my_shipments_batches = $self->process_pagination($myshipment_list);
	my $first_batch = $my_shipments_batches->[0];
	$myshipment_list = [splice @$myshipment_list, 0, scalar @$first_batch] if $first_batch;
	$c->stash->{myshipment_list} = $myshipment_list;
	$c->stash->{myshipment_list_count} = @$myshipment_list;
	$c->stash->{myshipment_batches} = $my_shipments_batches;

	$c->stash($params);
	$c->stash->{MY_SHIPMENTS} = 1;

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

	my ($date_shipped_sql,$search_by_term_sql);

	if (my $filter_value = $params->{'filter'})
		{
		$c->log->debug("Filter : " . $filter_value);
		$search_by_term_sql = "AND s.shipmentid = '$filter_value' OR s.tracking1 = '$filter_value' OR co.ordernumber = '$filter_value' ";
		}

	if (my $check_value = $params->{'date_apply'})
		{
		my $date_from= IntelliShip::DateUtils->get_db_format_date_time($params->{'datefrom'}) if $params->{'datefrom'};
		my $date_to= IntelliShip::DateUtils->get_db_format_date_time($params->{'dateto'}) if $params->{'dateto'};
		$date_shipped_sql = "AND s.dateshipped between  date_trunc('day',TIMESTAMP '$date_from') AND date_trunc('day',TIMESTAMP '$date_to') ";
		}
	else
		{
		my $view = $params->{'view_date'} || 'today';
		my $date_current = IntelliShip::DateUtils->get_timestamp_with_time_zone;
		if ($view eq 'this_week')
			{
			my $weekday =IntelliShip::DateUtils->get_day_of_week($date_current);
			$date_shipped_sql="AND (date_trunc('day',TIMESTAMP '$date_current') - s.dateshipped) <= (interval '$weekday days')";
			}
		elsif ($view eq 'this_month')
			{
			$c->log->debug("This month ");
			my $dd = substr($date_current, 8, 2)-1;
			$c->log->debug($dd);
			$date_shipped_sql="AND (date_trunc('day',TIMESTAMP '$date_current') - s.dateshipped) <= (interval '$dd days')";
			}
		elsif($view eq 'today' || '')
			{
			$date_shipped_sql = "AND s.dateshipped = date_trunc('day',TIMESTAMP '$date_current')";
			}
		}

	my $CustomerID = $Customer->customerid;

	my $and_shipment_in_sql = $self->get_shipmentid_in_sql;

	my $SQL = "
		SELECT
			s.shipmentid,
			co.coid,
			co.ordernumber,
			da.addressname as customername,
			oa.city || ', ' || oa.state as origin,
			da.city || ', ' || da.state as destin,
			to_char(s.dateshipped,'MM/DD/YY') as dateshipped,
			to_char(s.datedue,'MM/DD/YY') as duedate,
			s.tracking1 as tracking,
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
			$date_shipped_sql
			$search_by_term_sql
			AND s.datedelivered IS NULL
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
