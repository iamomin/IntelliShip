package IntelliShip::Controller::Customer::MyShipments;
use Moose;
use Data::Dumper;
use IntelliShip::Utils;
use namespace::autoclean;
use IntelliShip::Carrier::Constants;

BEGIN { extends 'IntelliShip::Controller::Customer::Order'; }

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

	$c->log->debug("SIHPMENT AJAX");

	if ($params->{'type'} eq 'HTML')
		{
		$self->get_HTML;
		}
	elsif ($params->{'type'} eq 'JSON')
		{
		$self->get_JSON_DATA;
		}
	}

sub get_JSON_DATA :Private
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	my $dataHash;

	my $action = $params->{'action'} || '';
	if ($action eq 'void_shipment')
		{
		$dataHash = $self->process_void_shipment;
		}
	elsif ($action eq 'track')
		{
		#$operation_sql = "AND s.tracking1 = '$row_data'";
		}

	$c->log->debug("\n TO dataHash:  " . Dumper ($dataHash));
	my $json_DATA = IntelliShip::Utils->jsonify($dataHash);
	$c->log->debug("\n TO json_DATA:  " . Dumper ($json_DATA));
	$c->response->body($json_DATA);
	}

sub get_HTML :Private
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	my $action = $params->{'action'} || '';
	if ($action eq 'refresh')
		{
		$self->populate_my_shipment_list;
		}
	elsif ( $action eq 'show_shipment_summary' )
		{
		$self->show_shipment_summary;
		}
	elsif ( $action eq 'reprint_label' )
		{
		$self->reprint_label;
		}

	$c->stash($params);
	$c->stash(template => "templates/customer/my-shipments.tt") unless $c->stash->{template};
	}

my $TITLE ;
my $TITLE_DATE = {
	'today' => 'Today',
	'this_week'  => 'This Week',
	'this_month'  => 'This Month',
	};

sub reprint_label :Private
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	my $Shipment = $c->model('MyDBI::Shipment')->find({ shipmentid => $params->{'shipmentid'} });

	return unless $Shipment;

	my $label_file = IntelliShip::MyConfig->label_file_directory . '/' . $Shipment->shipmentid;
	   $label_file = IntelliShip::MyConfig->label_image_directory . '/'.$Shipment->shipmentid . '.jpg' unless -e $label_file;

	$c->log->debug("... shipment found, label_file: " . $label_file);

	my $HTML;
	if ($label_file =~ /JPG/i)
		{
		$c->stash->{LABEL_IMG} = '/label/' . $Shipment->shipmentid . '.jpg';
		}
	else
		{
		my $FILE = new IO::File;
		unless (open ($FILE,$label_file))
			{
			$c->log->debug("*** Label String Save Error: " . $!);
			return;
			}
		my @lines = <$FILE>;
		close $FILE;

		my $PrinterString = join("\n",@lines);

		$self->setup_raw_label($Shipment, $PrinterString);
		}

	$c->stash->{REPRINT_LABEL} = 1;
	$c->stash(template => "templates/customer/order-label.tt");
	}

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

		$row_data->{'tracking_url'} = IntelliShip::Utils->get_tracking_URL($row_data->{'carrier'}, $row_data->{'tracking'});
		push(@$myshipment_list, $row_data);
		}
=as
	my $my_shipments_batches = $self->process_pagination($myshipment_list);
	$c->stash->{myshipment_batches} = $my_shipments_batches;

	my $first_batch = $my_shipments_batches->[0];
	$myshipment_list = [splice @$myshipment_list, 0, scalar @$first_batch] if $first_batch;
=cut

	$c->stash->{myshipment_list} = $myshipment_list;
	$c->stash->{myshipment_list_count} = @$myshipment_list;

	my $todays_date = IntelliShip::DateUtils->current_date;
	$c->log->debug("Todays date " . $todays_date);
	$c->stash->{todays_date} = $todays_date;
	$c->stash($params);
	$c->stash->{MY_SHIPMENTS} = 1;

	$c->stash->{view_datedelivered} = ($params->{'view'} and $params->{'view'} eq 'delivered');
	$c->stash->{list_title} = $TITLE->{$params->{'view'}} if $params->{'view'};
	}

sub get_search_by_term_sql
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	return unless $params->{'filter'};

	IntelliShip::Utils->hash_decode($params);

	my $COLUMN_MAPPING = {
		tracking     => 's.tracking1',
		ordernumber  => 'co.ordernumber',
		customername => 'da.addressname',
		origin       => '(oa.city || oa.state)',
		destination  => '(da.city || da.state)',
		shipdate     => 'to_char(s.dateshipped ,\'mm/dd/yy\')',
		duedate      => 'to_char(s.datedue,\'mm/dd/yy\')',
		carrier      => 's.carrier',
		mode         => 's.mode'
		};

	my @arrSearchByTerm;
	my @searchParts = split(' ', $params->{'filter'});

	foreach my $term (@searchParts)
		{
		foreach my $filter_value (keys %$params)
			{
			next unless $filter_value =~ /filter_(.+)$/;
			my $filter = $1;
			my $field = $COLUMN_MAPPING->{$filter};
			next unless $field;
			push(@arrSearchByTerm," $field LIKE '%$term%'");
			}
		}

	my $search_by_term_sql = " AND ( " . join(' OR ', @arrSearchByTerm) . " )" if @arrSearchByTerm;
	$c->log->debug("... search_by_term_sql: " . $search_by_term_sql);
	return $search_by_term_sql || '';
	}

sub get_shipped_sql :Private
	{
	my $self = shift;

	my $c = $self->context;
	my $params = $c->req->params;
	my $Customer = $self->customer;
	my $Contact = $self->contact;


	my $and_search_by_term_sql = $self->get_search_by_term_sql;

	my $and_date_shipped_sql = '';
	if ($params->{'date_apply'})
		{
		my $date_from = IntelliShip::DateUtils->get_db_format_date_time($params->{'datefrom'}) if $params->{'datefrom'};
		my $date_to   = IntelliShip::DateUtils->get_db_format_date_time($params->{'dateto'}) if $params->{'dateto'};
		$and_date_shipped_sql = "AND s.dateshipped BETWEEN  date_trunc('day', TIMESTAMP '$date_from') AND date_trunc('day', TIMESTAMP '$date_to') ";
		}
	else
		{
		my $view = $params->{'view_date'} || 'today';
		my $current_timestamp_with_time_zone = IntelliShip::DateUtils->get_timestamp_with_time_zone;
		if ($view eq 'this_week')
			{
			my $weekday = IntelliShip::DateUtils->get_day_of_week($current_timestamp_with_time_zone);
			$and_date_shipped_sql = "AND (date_trunc('day',TIMESTAMP '$current_timestamp_with_time_zone') - s.dateshipped) <= (interval '$weekday days')";
			}
		elsif ($view eq 'this_month')
			{
			my $dd = substr($current_timestamp_with_time_zone, 8, 2) - 1;
			$and_date_shipped_sql = "AND (date_trunc('day',TIMESTAMP '$current_timestamp_with_time_zone') - s.dateshipped) <= (interval '$dd days')";
			}
		else
			{
			$and_date_shipped_sql = "AND date_trunc('day', s.dateshipped) = date_trunc('day', TIMESTAMP '$current_timestamp_with_time_zone')";
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
			to_char(s.dateshipped,'mm/dd/yy') as dateshipped,
			to_char(s.datedue,'mm/dd/yy') as duedate,
			s.tracking1 as tracking,
			s.service,
			s.cost,
			s.carrier,
			s.mode,
			CASE
			WHEN s.statusid = 7THEN 6
			ELSE 4
			END
			as condition,
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
			$and_date_shipped_sql
			$and_search_by_term_sql
			AND s.datedelivered IS NULL
		ORDER BY
			dateshipped DESC, customername ASC
		";

	#$c->log->debug("SHIPMENT SQL: " . $SQL);

	return $SQL;
	}

sub get_shipmentid_in_sql :Private
	{
	my $self = shift;
	my $params = $self->context->req->params;
	return ($params->{'shipmentids'} ? "AND s.shipmentid IN ('" . join("','", split(',', $params->{'shipmentids'})) . "') " : "") ;
	}

sub process_void_shipment
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	my $shipmentids =  (ref $params->{'shipmentids'} eq 'ARRAY' ? $params->{'shipmentids'} : [$params->{'shipmentids'}]);
	$shipmentids =  [split /\,/, $params->{'shipmentids'}] if $params->{'shipmentids'} =~ /\,/;

	return {} unless @$shipmentids;

	$c->log->debug("PROCESS_VOID_SHIPMENT, total shipments to be voided " . Dumper $shipmentids);

	my $voided_shipments = [];
	foreach my $shipment_id (@$shipmentids)
		{
		push(@$voided_shipments, $shipment_id) if $self->VOID_SHIPMENT($shipment_id);
		}

	return { voided => $voided_shipments , is_success => (@$shipmentids == @$voided_shipments) };
	}

sub VOID_SHIPMENT :Private
	{
	my $self = shift;
	my $shipment_id = shift;

	my $c = $self->context;
	my $params = $c->req->params;
	my $Customer = $self->customer;
	my $Contact = $self->contact;

	$c->log->debug("VOID_SHIPMENT, ID: " . $shipment_id);

	# Set shipment to void status, for later processing
	my $Shipment = $c->model('MyDBI::Shipment')->find({ shipmentid => $shipment_id});
	$Shipment->statusid(5); ## Void Shipment
	$Shipment->update;

	$c->log->debug("statusid in shipment updated to " . $Shipment->statusid);

	# Set co to 'unshipped' status
	my $CO = $Shipment->CO;
	$CO->statusid(1); ## Void Shipment
	$CO->update;

	$c->log->debug("statusid in CO updated to " . $CO->statusid);

	my $OrderNumber = $CO->ordernumber;
	$c->log->debug("Order number " . $OrderNumber);

	## Remove product counts from pick & pack CO shipped product counts
	my @packages = $Shipment->packages;
	foreach my $Package (@packages)
		{
		$Package->products->delete;
		$Package->delete;
		}

	# Delete any associated orders
	$c->log->debug("Flush SHIPMENT CO ASSOC");
	$Shipment->shipmentcoassocs->delete;

	# Check if the shipment had a pickuprequest sent.  If it did, cancel it.

	# set a couple of values to pass to the pickup cancel request if they were passed in
	if ( defined($self->{'customerid'}) && $self->{'customerid'} ne '' )
		{
		$Shipment->{'customerid'} = $self->{'customerid'};
		}
	if ( defined($self->{'customername'}) && $self->{'customername'} ne '' )
		{
		$Shipment->{'customername'} = $self->{'customername'};
		}

	###################################################################
	## Process void shipment down through the carrrier handler
	###################################################################
	my $Handler = IntelliShip::Carrier::Handler->new;
	$Handler->request_type(&REQUEST_TYPE_VOID_SHIPMENT);
	$Handler->token($self->get_login_token);
	$Handler->context($self->context);
	$Handler->customer($self->customer);
	$Handler->carrier($Shipment->carrier);
	$Handler->CO($CO);
	$Handler->SHIPMENT($Shipment);

	my $Response = $Handler->process_request({
					NO_TOKEN_OPTION => 1
					});

	# Process errors
	unless ($Response->is_success)
		{
		$c->log->debug("SHIPMENT TO CARRIER FAILED: " . $Response->message);
		$c->log->debug("RESPONSE CODE: " . $Response->response_code);
		#return $self->display_error_details($Response->message);
		return undef;
		}

	$c->log->debug("VOID SHIPMENT PROCESSED SUCCESSFULLY");

	# Send Email Alert to LossPrevention Email
	# If the customer has an email address, check to see if the shipment address is different # from the co address (and send an email, if it is)
	my $ToEmail = $Customer->losspreventemail;
	my $CustomerName = $Customer->customername;
	if ($ToEmail)
		{
		my $OriginalAddress = $CO->to_address;
		$self->SendShipmentVoidEmail($OriginalAddress,$Shipment);
		}

	## Add note to notes table

	my $ContactName = $Contact->username;

	my $noteData = { ownerid => $Shipment->shipmentid };
	$noteData->{'notesid'} = $self->get_token_id;
	$noteData->{'note'} = 'Voided By ' . $ContactName;
	$noteData->{'contactid'} = $Contact->contactid;
	$noteData->{'notestypeid'} = 900;
	$noteData->{'datehappened'} = IntelliShip::DateUtils->get_timestamp_with_time_zone();

	$c->log->debug("noteData" . Dumper $noteData);

	my $Note = $c->model('MyDBI::Note')->new($noteData);
	$Note->insert;

	return 1;
	}

sub SendShipmentVoidEmail
	{
	my $self = shift;
	my $OriginalAddress = shift;
	my $Shipment = shift;
	my $Customer = $self->customer;
	my $OrderNumber='';

	return;

	my $TrackingNumber = $Shipment->tracking1;
	my ($CarrierName,$ServiceName) = $self->API->get_carrier_service_name($Shipment->customerserviceid);
	my $EmailInfo = {};
	$EmailInfo->{'fromemail'} = "intelliship\@intelliship.engagetechnology.com";
	$EmailInfo->{'fromname'} = 'NOC';
	$EmailInfo->{'toemail'} = $self->customerlosspreventemail;;
	$EmailInfo->{'toname'} = '';
	$EmailInfo->{'subject'}	='WARNING: ' . $self->customer->customername . ', ' . $CarrierName . ' ' . $ServiceName . ' ' . $TrackingNumber . ' (Voided By ' . $self->contact->contact->full_name  . '/' . $self->{'ipaddress'} . ')' ;
	#$EmailInfo->{'cc'} = 'noc@engagetechnology.com';
	my $ServerType; # 1 = production, 2 = beta, 3 = dev

	if ( $ServerType == 1 )
		{
		$EmailInfo->{'subject'} =  "TEST " . $EmailInfo->{'subject'};
		}

	my $Body = 'ShipmentID: ' . $Shipment->shipmentid . "\n" . $self->customer->customername . "\n" . $CarrierName . " " . $ServiceName . "\n" . $TrackingNumber . "\n" . " " . $OrderNumber . "\n" . "\n\n\n";
	}

sub show_shipment_summary: Private
	{
	my $self = shift;

	my $c = $self->context;
	my $params = $c->req->params;

	if (my $Shipment = $c->model('MyDBI::Shipment')->find({ shipmentid => $params->{shipmentid}}))
		{
		my $shipmentSummary = {
			customerAddress => $Shipment->origin_address,
			toAddress       => $Shipment->destination_address,
			shipmentinfo    => $Shipment,
			coinfo          => $Shipment->CO,
			shipdate        => IntelliShip::DateUtils->american_date($Shipment->dateshipped),
			duedate         => IntelliShip::DateUtils->american_date($Shipment->datedue),
			carrier         => $Shipment->carrier,
			packagedetails  => $Shipment->package_details,
			};

		$c->stash($shipmentSummary);
		}

	$c->stash(template => "templates/customer/shipment-summary.tt");
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
