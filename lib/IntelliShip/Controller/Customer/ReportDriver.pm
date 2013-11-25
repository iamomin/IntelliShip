package IntelliShip::Controller::Customer::ReportDriver;
use Moose;
use Data::Dumper;
use namespace::autoclean;
use IntelliShip::DateUtils;

BEGIN { extends 'IntelliShip::Controller::Customer'; }

sub make_report
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	if ($params->{'report'} eq 'CUSTOMER')
		{
		return $self->generate_customer_report;
		}
	elsif ($params->{'report'} eq 'SHIPMENT')
		{
		return $self->generate_shipment_report;
		}
	#else
	#	{
	#	$self->error([{MESSAGE => 'Unable To Run Requested Report'}]);
	#	}
	}

sub generate_customer_report
	{
	my $self= shift;
	my $c = $self->context;
	my $params = $c->req->params;

	my $Contact = $self->contact;
	my $Customer = $self->customer;

	}

sub generate_shipment_report
	{
	my $self= shift;

	my $c = $self->context;
	my $params = $c->req->params;

	my $Contact  = $self->contact;
	my $Customer = $self->customer;
	my $Address  = $Customer->address;

	my ($carrier,@carriers);
	unless ($params->{'carriers'} eq 'all')
		{
		@carriers = split(/\,/, $params->{'carriers'});
		}

	my $start_date = IntelliShip::DateUtils->get_db_format_date_time($params->{'startdate'});
	my $stop_date  = IntelliShip::DateUtils->get_db_format_date_time($params->{'enddate'});
	my $customerid = $Customer->customerid;
	my $contactid  = $Contact->contactid;

	$c->log->debug("Filter Criteria, start_date: " . $start_date . ", stop_date: " . $stop_date . ", customerid: " . $customerid . ", contactid: " . $contactid . ", Carriers: " . Dumper(@carriers));

	my ($report_heading_loop, $report_output_row_loop, $filter_criteria)= ([],[],'');

	$report_heading_loop = [
				{name => 'shipment id'},
				{name => 'weight'},
				{name => 'date delivered'},
				{name => 'pod name'},
				{name => 'dim weight'},
				{name => 'tracking 1'},
				{name => 'cost'},
				{name => 'date shipped'},
#				{name => 'commodityquantity'},
#				{name => 'username'},
#				{name => 'addressname'},
#				{name => 'address1'},
#				{name => 'addresscity'},
#				{name => 'addressstate'},
#				{name => 'addresszip'},
#				{name => 'addressidorigin'},
#				{name => 'ordernumber'},
#				{name => 'zonenumber'},
#				{name => 'currentdate'},
#				{name => 'contactname'},
#				{name => 'custnum'},
#				{name => 'ppd.dimlength'},
#				{name => 'ppd.dimwidth'},
#				{name => 'ppd.dimheight'},
#				{name => 'customerserviceid'},
#				{name => 'custref3'},
#				{name => 'carriername'},
#				{name => 'servicename'},
#				{name => 'customerid'},
			];

	## check for restricted login
	my $and_allowed_extcustnum_sql = '';
	if ($Contact->is_restricted)
		{
		my $values =  $Contact->get_restricted_values('extcustnum');
		$and_allowed_extcustnum_sql = " AND co.extcustnum IN (" . join(',', @$values) . ") " if $values;
		}

	## restrict cotypeid based on returncapability
	my $and_co_type_id_sql = '';
	my $return_capability = $Contact->get_contact_data_value('returncapability');
	if ($return_capability == 2)
		{
		$and_co_type_id_sql = " AND cotypeid = 2 ";
		}
	elsif ($return_capability == 0)
		{
		$and_co_type_id_sql = " AND cotypeid = 1 ";
		}
	else
		{
		$and_co_type_id_sql = " AND cotypeid in (1,2) ";
		}

	my $report_SQL_1 = '';
	if (!$carrier or $carrier !~ /^OTHER_/)
		{
		my ($and_carrier_sql,$and_customerid_sql,$and_username_sql) = ('','','');
		if ($carrier)
			{
			#my $CarrierName = &APIRequest({action=>'GetValueHashRef',module=>'CARRIER',moduleid=>$carrier,field=>'carriername'})->{'carriername'};
			#$and_carrier_sql .= "AND sh.carrier = '$CarrierName'";
			}
		if ($customerid)
			{
			$and_customerid_sql .= "AND c.customerid = '$customerid'";
			}
		unless ($Customer->superuser)
			{
			$and_username_sql .= "AND c.username = '" . $Customer->username . "'";
			}

		$report_SQL_1 = "
			SELECT
				sh.shipmentid,
				sh.weight,
				sh.datedelivered,
				sh.podname,
				sh.dimweight,
				sh.tracking1,
				sh.cost,
				sh.dateshipped,
				sh.commodityquantity,
				c.username,
				a.addressname,
				a.address1,
				a.city as addresscity,
				a.state as addressstate,
				a.zip as addresszip,
				sh.addressidorigin,
				co.ordernumber,
				sh.zonenumber,
				date(timestamp 'now') as current_date,
				sh.contactname,
				sh.custnum,
				ppd.dimlength,
				ppd.dimwidth,
				ppd.dimheight,
				sh.customerserviceid,
				sh.custref3,
				sh.carrier as carriername,
				sh.service as servicename,
				c.customerid
			FROM
				shipment sh
				INNER JOIN co ON co.coid = sh.coid
				INNER JOIN customer c ON co.customerid = c.customerid
				INNER JOIN address a ON a.addressid = sh.addressiddestin
				INNER JOIN packprodata ppd ON sh.shipmentid = ppd.ownerid
			WHERE
				sh.dateshipped >= timestamp '$start_date 00:00:00'
				AND sh.dateshipped <= timestamp '$stop_date 23:59:59'
				AND (sh.statusid = 10 OR sh.statusid = 100)
				AND ppd.ownertypeid = 2000
				AND ppd.datatypeid = 1000
				$and_carrier_sql
				$and_customerid_sql
				$and_username_sql
				$and_co_type_id_sql
				$and_allowed_extcustnum_sql
			";
		}

	my $report_SQL_2;
	if (!$carrier or $carrier =~ /^OTHER_/)
		{
		my ($join_other_sql,$and_other_name_sql) = ('','');
		if ($carrier and $carrier =~ /^OTHER_(\w+)/)
			{
			my $other_id =  $1;
			$join_other_sql = " other o INNER JOIN ON o.othername = sh.carrier ";
			my @arr = $Customer->others({ otherid => $other_id });
			 if (@arr)
				{
				my $Other = $arr[0];
				$and_other_name_sql = " AND o.othername = '" . $Other->othername . "' ";
				}
			}

		my ($and_customerid_sql,$and_username_sql);
		if (length $customerid)
			{
			$and_customerid_sql .= " AND c.customerid = '$customerid'";
			}
		unless ($Customer->superuser)
			{
			$and_username_sql .= " AND c.username = '" . $Customer->username . "'";
			}

		$report_SQL_2 .= "
			SELECT
				sh.shipmentid,
				sh.weight,
				sh.datedelivered,
				sh.podname,
				sh.dimweight,
				sh.tracking1,
				sh.cost,
				sh.dateshipped,
				sh.commodityquantity,
				c.username,
				a.addressname,
				a.address1,
				a.city as addresscity,
				a.state as addressstate,
				a.zip as addresszip,
				sh.addressidorigin,
				co.ordernumber,
				sh.zonenumber,
				date(timestamp 'now') as current_date,
				sh.contactname,
				sh.custnum,
				ppd.dimlength,
				ppd.dimwidth,
				ppd.dimheight,
				sh.customerserviceid,
				sh.custref3,
				sh.carrier as carriername,
				sh.service as servicename,
				c.customerid
			FROM
				shipment sh
				INNER JOIN co ON co.coid=sh.coid
				INNER JOIN customer c ON co.customerid = c.customerid
				INNER JOIN address a ON a.addressid = sh.addressiddestin
				INNER JOIN packprodata ppd ON sh.shipmentid = ppd.ownerid
				$join_other_sql
			WHERE
				sh.dateshipped >= timestamp '$start_date 00:00:00'
				AND sh.dateshipped <= timestamp '$stop_date 23:59:59'
				AND (sh.statusid = 10 OR sh.statusid = 100)
				AND ppd.ownertypeid = 2000
				AND ppd.datatypeid = 1000
				$and_other_name_sql
				$and_allowed_extcustnum_sql
				$and_customerid_sql
				$and_username_sql
				";
		}

	my $report_SQL;
	if ($report_SQL_1 and $report_SQL_2)
		{
		$report_SQL = $report_SQL_1 . "\nUNION\n" . $report_SQL_2;
		}
	else
		{
		$report_SQL = $report_SQL_1 if $report_SQL_1;
		$report_SQL = $report_SQL_2 if $report_SQL_2;
		}

	$report_SQL .= " ORDER BY 3,2,4 ";

######################################## ADDED FOR TESTING PURPOSE ########################################
$report_SQL = "
			SELECT
				sh.shipmentid,
				sh.weight,
				sh.datedelivered,
				sh.podname,
				sh.dimweight,
				sh.tracking1,
				sh.cost,
				sh.dateshipped,
				sh.commodityquantity,
				c.username,
				a.addressname,
				a.address1,
				a.city as addresscity,
				a.state as addressstate,
				a.zip as addresszip,
				sh.addressidorigin,
				co.ordernumber,
				sh.zonenumber,
				date(timestamp 'now') as current_date,
				sh.contactname,
				sh.custnum,
				ppd.dimlength,
				ppd.dimwidth,
				ppd.dimheight,
				sh.customerserviceid,
				sh.custref3,
				sh.carrier as carriername,
				sh.service as servicename,
				c.customerid
			FROM
				shipment sh
				INNER JOIN co ON co.coid = sh.coid
				INNER JOIN customer c ON co.customerid = c.customerid
				INNER JOIN address a ON a.addressid = sh.addressiddestin
				INNER JOIN packprodata ppd ON sh.shipmentid = ppd.ownerid
			ORDER BY 3,2,4
			LIMIT 50
			";
###########################################################################################################

	#$c->log->debug("REPORT SQL: \n" . $report_SQL);
	my $report_sth = $c->model('MyDBI')->select($report_SQL);

	$c->log->debug("TOTAL RECORDS: " . $report_sth->numrows);

	for (my $row=0; $row < $report_sth->numrows; $row++)
		{
		my $row_data = $report_sth->fetchrow($row);

		#$c->log->debug("row_data: " . Dumper $row_data);

		if ( $row_data->{'customerserviceid'} )
			{
=as
			my $CSRef = &APIRequest({
					action	=> 'GetCSShippingValues',
					csid	=> $row_data->{'customerserviceid'},
					customerid => $row_data->{'customerid'}
				});
			$row_data->{'webaccount'} = $CSRef->{'webaccount'};
=cut
			$row_data->{'webaccount'} = 'IMRAN_ARRRS';
			}

		## Load up origin addr info
		$row_data->{'shipper_name'} = $Address->addressname;
		$row_data->{'shipper_city'} = $Address->city;
		$row_data->{'shipper_state'} = $Address->state;

		# The Excel module does NOT like undefined variables...need to stuff the undef'd ones with something
		$row_data->{'weight'} = $row_data->{'weight'} || "";
		$row_data->{'dimweight'} = $row_data->{'dimweight'} || "";
		$row_data->{'carriername'} = $row_data->{'carriername'} || "";
		$row_data->{'zonenumber'} = $row_data->{'zonenumber'} || "";
		$row_data->{'servicename'} = $row_data->{'servicename'} || "";
		$row_data->{'tracking1'} = $row_data->{'tracking1'} || "";
 		$row_data->{'cost'} = $row_data->{'cost'} || "";
		$row_data->{'dateshipped'} = $row_data->{'dateshipped'} || "";
		$row_data->{'commodityquantity'} = $row_data->{'commodityquantity'} || 1;
		$row_data->{'username'} = $row_data->{'username'} || "";
		$row_data->{'webaccount'} = $row_data->{'webaccount'} || "";
		$row_data->{'shipper_name'} = $row_data->{'shipper_name'} || "";
		$row_data->{'shipper_city'} = $row_data->{'shipper_city'} || "";
		$row_data->{'shipper_state'} = $row_data->{'shipper_state'} || "";
		$row_data->{'shipper_zip'} = $row_data->{'shipper_zip'} || "";
		$row_data->{'addressname'} = $row_data->{'addressname'} || "UNKNOWN";
		$row_data->{'address1'} = $row_data->{'address1'} || "UNKNOWN";
		$row_data->{'addresscity'} = $row_data->{'addresscity'} || "UNKNOWN";
		$row_data->{'addressstate'} = $row_data->{'addressstate'} || "UNKNOWN";
		$row_data->{'addresszip'} = $row_data->{'addresszip'} || "UNKNOWN";
		$row_data->{'datedelivered'} = $row_data->{'datedelivered'} || "";
		$row_data->{'podname'} = $row_data->{'podname'} || "";
		$row_data->{'ordernumber'} = $row_data->{'ordernumber'} || "";
		$row_data->{'contactname'} = $row_data->{'contactname'} || "";
		$row_data->{'custnum'} = $row_data->{'custnum'} || "";

		my ($date, $time) = split(/ /,$row_data->{'dateshipped'});
		$row_data->{'dateshipped'} = $date;

		$row_data->{'datedelivered'} = $row_data->{'datedelivered'} =~ /(.*)-\d{2}$/;

		my $ShipmentChargeCost;
		## Get Accessorial charges (non-freight) for shipment
		if (my $Shipment = $c->model('MyDBI::Shipment')->find({ shipmentid => $row_data->{'shipmentid'} }))
			{
			$row_data->{'othercharges'} = $Shipment->get_assessorial_charges();

			$ShipmentChargeCost = $Shipment->get_freight_charges;
			}

		my $ShipmentCost = length $row_data->{'cost'} ? $row_data->{'cost'} : 0;

		if ($ShipmentChargeCost > 0)
			{
			$row_data->{'cost'} = $ShipmentChargeCost;
			}
		elsif ($ShipmentCost > 0)
			{
			$row_data->{'cost'} = $ShipmentCost;
			}

		# Build dim string
		$row_data->{'dims'} = $row_data->{'dimlength'};
		$row_data->{'dims'} .= 'x' . $row_data->{'dimwidth'} if $row_data->{'dims'} and $row_data->{'dimwidth'};
		$row_data->{'dims'} .= 'x' . $row_data->{'dimheight'} if $row_data->{'dims'} and $row_data->{'dimheight'};
		$row_data->{'dims'} = '' unless $row_data->{'dims'};

		my $report_output_column_loop = [
				{ value => $row_data->{'shipmentid'} },
				{ value => $row_data->{'weight'} },
				{ value => $row_data->{'datedelivered'} },
				{ value => $row_data->{'podname'} },
				{ value => $row_data->{'dimweight'} },
				{ value => $row_data->{'tracking1'} },
				{ value => $row_data->{'cost'} },
				{ value => IntelliShip::DateUtils->american_date($row_data->{'dateshipped'}) },
			];

		push(@$report_output_row_loop, $report_output_column_loop);

		## Keep the browser from timing out.
		# print "\n";
		# STDOUT->autoflush(1);
		}

	my $filter_criteria_loop = $self->get_filter_criteria_hash_arr($filter_criteria);

	return ($report_heading_loop , $report_output_row_loop , $filter_criteria_loop);
	}
=cut
sub generate_card_transaction_report
	{
	my $self = shift;
	my $params = $self->params;

	my ($start_tdate, $end_tdate) = $self->get_start_and_end_date('tdate');

	$self->check_for_valid_date_range('tdate', $start_tdate, $end_tdate);

	if ($self->has_errors)
		{
		return undef;
		}

	my ($report_heading_loop, $report_output_row_loop, $report_output_column_loop, $filter_criteria)= ([],[],[],undef);

	$filter_criteria .= " and tdate >= '$start_tdate' and tdate <= '$end_tdate' " if ($start_tdate and $end_tdate);
	$filter_criteria .= " and gcard = '" . $self->company->merid . $params->{'gcard'} . "' " if ($params->{'gcard'} ne '');
	$filter_criteria .= $self->session->param('report_filter_criteria') if ($self->session->param('report_name') eq $params->{'reportname'} and ($params->{'sort_by'} ne '' or $params->{'do'} eq 'email'));

	$report_heading_loop = [	{NAME => 'date' , COLUMN_NAME => 'tdate'},
								{NAME => 'time' , COLUMN_NAME => 'ttime'},
								{NAME => 'terminal' , COLUMN_NAME => 'tterm'},
								{NAME => 'transact id' , COLUMN_NAME => 'tid'},
								{NAME => 'card number' , COLUMN_NAME => 'gcard'},
								{NAME => 'description' , COLUMN_NAME => 'tdesc'},
								{NAME => 'amount' , COLUMN_NAME => 'tamount'},
								{NAME => 'balance' , COLUMN_NAME => 'tbal'},
								{NAME => 'comment' , COLUMN_NAME => 'tcomment'}];

	#######################################################################
	# GIFT CARD TRANSACTION HISTORY SEARCH LOGIC DEPENDS ON THE MERID FIELD
	#######################################################################

	my $CardTransaction = TicketProWebGift::CardTransaction->new;
	$CardTransaction->tid($self->company->merid);

	my $card_transaction_array = $CardTransaction->search($filter_criteria , $self->get_order_by_column);

	##############################################

	foreach my $CT (@$card_transaction_array)
		{
		$report_output_column_loop = [	{
										VALUE => TicketProWebGift::Display::Utils->get_american_date($CT->tdate),
										ALIGN => 'CENTER',
										},
										{
										VALUE => $CT->ttime,
										ALIGN => 'CENTER',
										},
										{
										VALUE => $CT->tterm,
										ALIGN => 'CENTER',
										},
										{
										VALUE => $CT->tid,
										ALIGN => 'CENTER',
										},
										{
										VALUE => substr($CT->gcard, 5),
										ALIGN => 'CENTER',
										},
										{
										VALUE => $CT->tdesc,
										ALIGN => 'LEFT',
										},
										{
										VALUE => $CT->tamount,
										ALIGN => 'RIGHT',
										},
										{
										VALUE => $CT->tbal,
										ALIGN => 'RIGHT',
										},
										{
										VALUE => $CT->tcomment,
										ALIGN => 'LEFT',
										},];

		push(@$report_output_row_loop , {REPORT_OUTPUT_COLUMN_LOOP => $report_output_column_loop});
		}

	my $filter_criteria_loop = $self->get_filter_criteria_hash_arr($filter_criteria);

	return ($report_heading_loop , $report_output_row_loop , $filter_criteria_loop);
	}

sub generate_audit_information_report
	{
	my $self = shift;
	my $params = $self->params;

	my ($start_auditdate, $end_auditdate) = $self->get_start_and_end_date('auditdate');

	$self->check_for_valid_date_range('auditdate', $start_auditdate, $end_auditdate);

	if ($self->has_errors)
		{
		return undef;
		}

	my ($report_heading_loop, $report_output_row_loop, $report_output_column_loop, $filter_criteria)= ([],[],[],undef);

	$filter_criteria .= " and auditdate >= '$start_auditdate' and auditdate <= '$end_auditdate' " if ($start_auditdate and $end_auditdate);
	$filter_criteria .= " and auditdesc like '%" . $params->{'auditdesc'} . "%' " if ($params->{'auditdesc'} ne '');
	$filter_criteria .= " and audittype = '" . $params->{'audittype'} . "'" if ($params->{'audittype'} ne '');
	$filter_criteria .= " and auditid = '" . $params->{'auditid'} . "'" if ($params->{'auditid'} ne '');

	$filter_criteria = $self->session->param('report_filter_criteria') if ($self->session->param('report_name') eq $params->{'reportname'} and ($params->{'sort_by'} ne '' or $params->{'do'} eq 'email'));

	$report_heading_loop = [	{NAME => 'Date' , COLUMN_NAME => 'auditdate'},
								{NAME => 'Time' , COLUMN_NAME => 'audittime'},
								{NAME => 'Audit Type' , COLUMN_NAME => 'audittype'},
								{NAME => 'Audit ID' , COLUMN_NAME => 'auditid'},
								{NAME => 'Terminal' , COLUMN_NAME => 'auditterm'},
								{NAME => 'Description' , COLUMN_NAME => 'auditdesc'},
							];

	my $SrchAudit = TicketProWebGift::Audit->new;

	unless ($self->company->login eq 'ticketpro' and int($self->terminal) == 0)
		{
		$SrchAudit->auditid($self->company->merid);
		}

	my $audit_arr = $SrchAudit->search($filter_criteria, $self->get_order_by_column);

	foreach my $A (@$audit_arr)
		{
		$report_output_column_loop = [	{
										VALUE => TicketProWebGift::Display::Utils->get_american_date($A->auditdate),
										ALIGN => 'CENTER',
										},
										{
										VALUE => $A->audittime,
										ALIGN => 'CENTER',
										},
										{
										VALUE => $A->audittype,
										ALIGN => 'CENTER',
										},
										{
										VALUE => $A->auditid,
										ALIGN => 'CENTER',
										},
										{
										VALUE => $A->auditterm,
										ALIGN => 'CENTER',
										},
										{
										VALUE =>  $A->auditdesc,
										ALIGN => 'LEFT',
										},];

		push(@$report_output_row_loop , {REPORT_OUTPUT_COLUMN_LOOP => $report_output_column_loop});
		}

	my $filter_criteria_loop = $self->get_filter_criteria_hash_arr($filter_criteria);

	return ($report_heading_loop , $report_output_row_loop , $filter_criteria_loop);
	}

sub generate_gift_card_status_report
	{
	my $self = shift;
	my $params = $self->params;

	my ($report_heading_loop, $report_output_row_loop, $report_output_column_loop)= ([],[],[]);

	$report_heading_loop = [	{NAME => 'Company ID'},
								{NAME => 'Company Name'},
								{NAME => 'Merchant ID'},
								{NAME => 'Card Status'},
								{NAME => 'Total Gift Cards'},];

	my $CS = TicketProWebGift::Company->new;
	my $company_array = $CS->search;

	foreach my $C (@$company_array)
		{
		my $SrchGC = TicketProWebGift::GCard->new;
		my $filter_criteria = " and gcard like " . $SrchGC->like($C->merid, 'left');
		my $gift_card_arr = $SrchGC->search($filter_criteria . " and edate > '" . TicketProWebGift::Display::Utils->get_current_date . "'");
		my $c_number = 0 unless ($gift_card_arr);
		$c_number = scalar @$gift_card_arr if ($gift_card_arr);

		$report_output_column_loop = [	{
										VALUE => $C->id,
										ALIGN => 'CENTER',
										ROWSPAN => 2,
										},
										{
										VALUE => $C->name,
										ALIGN => 'LEFT',
										ROWSPAN => 2,
										},
										{
										VALUE => $C->merid,
										ALIGN => 'CENTER',
										ROWSPAN => 2,
										},
										{
										VALUE => 'Active',
										ALIGN => 'CENTER',
										},
										{
										VALUE => $c_number,
										ALIGN => 'CENTER',
										},];

		push(@$report_output_row_loop , {REPORT_OUTPUT_COLUMN_LOOP => $report_output_column_loop});

		my $gift_card_arr = $SrchGC->search($filter_criteria . " and edate <= '" . TicketProWebGift::Display::Utils->get_current_date . "'");
		my $c_number = 0 unless ($gift_card_arr);
		$c_number = scalar @$gift_card_arr if ($gift_card_arr);

		$report_output_column_loop = [	{
										VALUE => 'Expired',
										ALIGN => 'CENTER',
										},
										{
										VALUE => $c_number,
										ALIGN => 'CENTER',
										},];

		push(@$report_output_row_loop , {REPORT_OUTPUT_COLUMN_LOOP => $report_output_column_loop});
		}

	return ($report_heading_loop , $report_output_row_loop , undef);
	}

sub generate_transaction_summary_report
	{
	my $self = shift;
	my $params = $self->params;

	my ($start_tdate, $end_tdate) = $self->get_start_and_end_date('tdate');

	$self->check_for_valid_date_range('tdate', $start_tdate, $end_tdate);

	if ($self->has_errors)
		{
		return undef;
		}

	my ($report_heading_loop, $report_output_row_loop, $report_output_column_loop, $filter_criteria)= ([],[],[],undef);

	if ($start_tdate and $end_tdate)
		{
		$filter_criteria .= " and tdate >= '$start_tdate' and tdate <= '$end_tdate' ";
		}
	else
		{
		$filter_criteria .= " and tdate = '" . TicketProWebGift::Display::Utils->get_current_date . "' ";
		}

	$report_heading_loop = [{NAME => 'Transaction Type'},
							{NAME => 'Total Amount'},
							{NAME => 'Total Transactions'},
							];

	my $CardTransaction = TicketProWebGift::CardTransaction->new;
	$CardTransaction->tid($self->company->merid);

	#########################################################
	$CardTransaction->tdesc(TicketProWebGift::Display::Utils->get_type_of_transaction(&CARD_ACTIVATE));
	my $card_transaction_array = $CardTransaction->search($filter_criteria , $self->get_order_by_column);

	my $ttl_amount = 0;
	foreach my $CT (@$card_transaction_array)
		{
		$ttl_amount += $CT->tamount;
		}

	$report_output_column_loop = [	{
									VALUE => TicketProWebGift::Display::Utils->get_type_of_transaction(&CARD_ACTIVATE),
									ALIGN => 'CENTER',
									},
									{
									VALUE => '$' . $self->format_number($ttl_amount),
									ALIGN => 'CENTER',
									},
									{
									VALUE => scalar @$card_transaction_array,
									ALIGN => 'CENTER',
									},
								];

	push(@$report_output_row_loop , {REPORT_OUTPUT_COLUMN_LOOP => $report_output_column_loop});

	#########################################################
	$CardTransaction->tdesc(TicketProWebGift::Display::Utils->get_type_of_transaction(&CARD_LOAD));
	my $card_transaction_array = $CardTransaction->search($filter_criteria , $self->get_order_by_column);

	$ttl_amount = 0;
	foreach my $CT (@$card_transaction_array)
		{
		$ttl_amount += $CT->tamount;
		}

	$report_output_column_loop = [	{
									VALUE => TicketProWebGift::Display::Utils->get_type_of_transaction(&CARD_LOAD),
									ALIGN => 'CENTER',
									},
									{
									VALUE => '$' . $self->format_number($ttl_amount),
									ALIGN => 'CENTER',
									},
									{
									VALUE => scalar @$card_transaction_array,
									ALIGN => 'CENTER',
									},
								];

	push(@$report_output_row_loop , {REPORT_OUTPUT_COLUMN_LOOP => $report_output_column_loop});

	#########################################################
	$CardTransaction->tdesc(TicketProWebGift::Display::Utils->get_type_of_transaction(&CARD_SALE));
	my $card_transaction_array = $CardTransaction->search($filter_criteria , $self->get_order_by_column);

	$ttl_amount = 0;
	foreach my $CT (@$card_transaction_array)
		{
		$ttl_amount += $CT->tamount;
		}

	$report_output_column_loop = [	{
									VALUE => TicketProWebGift::Display::Utils->get_type_of_transaction(&CARD_SALE),
									ALIGN => 'CENTER',
									},
									{
									VALUE => '$' . $self->format_number($ttl_amount),
									ALIGN => 'CENTER',
									},
									{
									VALUE => scalar @$card_transaction_array,
									ALIGN => 'CENTER',
									},
								];

	push(@$report_output_row_loop , {REPORT_OUTPUT_COLUMN_LOOP => $report_output_column_loop});

	#########################################################
	$CardTransaction->tdesc(TicketProWebGift::Display::Utils->get_type_of_transaction(&CARD_CREDIT));
	my $card_transaction_array = $CardTransaction->search($filter_criteria , $self->get_order_by_column);

	$ttl_amount = 0;
	foreach my $CT (@$card_transaction_array)
		{
		$ttl_amount += $CT->tamount;
		}

	$report_output_column_loop = [	{
									VALUE => TicketProWebGift::Display::Utils->get_type_of_transaction(&CARD_CREDIT),
									ALIGN => 'CENTER',
									},
									{
									VALUE => '$' . $self->format_number($ttl_amount),
									ALIGN => 'CENTER',
									},
									{
									VALUE => scalar @$card_transaction_array,
									ALIGN => 'CENTER',
									},
								];

	push(@$report_output_row_loop , {REPORT_OUTPUT_COLUMN_LOOP => $report_output_column_loop});

	#########################################################

	my $filter_criteria_loop = $self->get_filter_criteria_hash_arr($filter_criteria);

	return ($report_heading_loop , $report_output_row_loop , $filter_criteria_loop);
	}

sub generate_billing_report
	{
	my $self = shift;
	my $params = $self->params;

	my ($start_tdate, $end_tdate) = $self->get_start_and_end_date('tdate');

	$self->check_for_valid_date_range('tdate', $start_tdate, $end_tdate);

	if ($self->has_errors)
		{
		return undef;
		}

	my ($report_heading_loop, $report_output_row_loop, $report_output_column_loop, $filter_criteria)= ([],[],[],undef);

	if ($start_tdate and $end_tdate)
		{
		$filter_criteria .= " and tdate >= '$start_tdate' and tdate <= '$end_tdate' ";
		}
	else
		{
		$start_tdate = substr(TicketProWebGift::Display::Utils->get_current_date, 0, 8) . '01';
		$end_tdate = TicketProWebGift::Display::Utils->get_current_date;
		$filter_criteria .= " and tdate >= '$start_tdate' and tdate <= '$end_tdate' ";
		}

	$report_heading_loop = [{NAME => 'Company'},
							{NAME => 'Cents / Transaction'},
							{NAME => 'Transaction Type'},
							{NAME => 'Total Transactions'},
							{NAME => 'Total Amount'},
							];
	my $CS = TicketProWebGift::Company->new;
	my $company_array = $CS->search;

	foreach my $C (@$company_array)
		{
		my $CardTransaction = TicketProWebGift::CardTransaction->new;
		$CardTransaction->tid($C->merid);

		#########################################################
		$CardTransaction->tdesc(TicketProWebGift::Display::Utils->get_type_of_transaction(&CARD_ACTIVATE));
		my $card_transaction_array = $CardTransaction->search($filter_criteria , $self->get_order_by_column);

		my $net_amount = 0;
		my ($ttl_amount, $ttl_transaction) = (0, 0);
		$ttl_transaction = scalar @$card_transaction_array if ($card_transaction_array);
		$ttl_amount = $C->cpt * $ttl_transaction;
		$net_amount += $ttl_amount;

		$report_output_column_loop = [	{
										VALUE => $C->name,
										ALIGN => 'LEFT',
										ROWSPAN => 4,
										},
										{
										VALUE => $C->cpt,
										ALIGN => 'CENTER',
										ROWSPAN => 4,
										},
										{
										VALUE => TicketProWebGift::Display::Utils->get_type_of_transaction(&CARD_ACTIVATE),
										ALIGN => 'CENTER',
										},
										{
										VALUE => $ttl_transaction,
										ALIGN => 'CENTER',
										},
										{
										VALUE => '$' . $self->covert_cents_to_dollar($ttl_amount),
										ALIGN => 'CENTER',
										},
									];

		push(@$report_output_row_loop , {REPORT_OUTPUT_COLUMN_LOOP => $report_output_column_loop});

		#########################################################
		$CardTransaction->tdesc(TicketProWebGift::Display::Utils->get_type_of_transaction(&CARD_LOAD));
		my $card_transaction_array = $CardTransaction->search($filter_criteria , $self->get_order_by_column);

		($ttl_amount, $ttl_transaction) = (0, 0);
		$ttl_transaction = scalar @$card_transaction_array if ($card_transaction_array);
		$ttl_amount = $C->cpt * $ttl_transaction;
		$net_amount += $ttl_amount;

		$report_output_column_loop = [	{
										VALUE => TicketProWebGift::Display::Utils->get_type_of_transaction(&CARD_LOAD),
										ALIGN => 'CENTER',
										},
										{
										VALUE => $ttl_transaction,
										ALIGN => 'CENTER',
										},
										{
										VALUE => '$' . $self->covert_cents_to_dollar($ttl_amount),
										ALIGN => 'CENTER',
										},
									];

		push(@$report_output_row_loop , {REPORT_OUTPUT_COLUMN_LOOP => $report_output_column_loop});

		#########################################################
		$CardTransaction->tdesc(TicketProWebGift::Display::Utils->get_type_of_transaction(&CARD_SALE));
		my $card_transaction_array = $CardTransaction->search($filter_criteria , $self->get_order_by_column);

		($ttl_amount, $ttl_transaction) = (0, 0);
		$ttl_transaction = scalar @$card_transaction_array if ($card_transaction_array);
		$ttl_amount = $C->cpt * $ttl_transaction;
		$net_amount += $ttl_amount;

		$report_output_column_loop = [	{
										VALUE => TicketProWebGift::Display::Utils->get_type_of_transaction(&CARD_SALE),
										ALIGN => 'CENTER',
										},
										{
										VALUE => $ttl_transaction,
										ALIGN => 'CENTER',
										},
										{
										VALUE => '$' . $self->covert_cents_to_dollar($ttl_amount),
										ALIGN => 'CENTER',
										},
									];

		push(@$report_output_row_loop , {REPORT_OUTPUT_COLUMN_LOOP => $report_output_column_loop});

		#########################################################
		$CardTransaction->tdesc(TicketProWebGift::Display::Utils->get_type_of_transaction(&CARD_CREDIT));
		my $card_transaction_array = $CardTransaction->search($filter_criteria , $self->get_order_by_column);

		($ttl_amount, $ttl_transaction) = (0, 0);
		$ttl_transaction = scalar @$card_transaction_array if ($card_transaction_array);
		$ttl_amount = $C->cpt * $ttl_transaction;
		$net_amount += $ttl_amount;

		$report_output_column_loop = [	{
										VALUE => TicketProWebGift::Display::Utils->get_type_of_transaction(&CARD_CREDIT),
										ALIGN => 'CENTER',
										},
										{
										VALUE => $ttl_transaction,
										ALIGN => 'CENTER',
										},
										{
										VALUE => '$' . $self->covert_cents_to_dollar($ttl_amount),
										ALIGN => 'CENTER',
										},
									];

		push(@$report_output_row_loop , {REPORT_OUTPUT_COLUMN_LOOP => $report_output_column_loop});
		#########################################################

		push(@$report_output_row_loop , {REPORT_OUTPUT_COLUMN_LOOP => [
													{VALUE => '&nbsp;' , COLSPAN => 2},
													{VALUE => '<B>Total Charge Amount</B>' , COLSPAN => 2, ALIGN => 'CENTER'},
													{VALUE => '<B>$' . $self->covert_cents_to_dollar($net_amount) . '</B>', ALIGN => 'CENTER'}
													]});
		}

	my $filter_criteria_loop = $self->get_filter_criteria_hash_arr($filter_criteria);

	return ($report_heading_loop , $report_output_row_loop , $filter_criteria_loop);
	}

sub generate_gift_card_information_report
	{
	my $self = shift;
	my $params = $self->params;

	my ($start_adate, $end_adate) = $self->get_start_and_end_date('adate');
	my ($start_ldate, $end_ldate) = $self->get_start_and_end_date('ldate');

	$self->check_for_valid_date_range('adate', $start_adate, $end_adate);
	$self->check_for_valid_date_range('ldate', $start_ldate, $end_ldate);

	if (($params->{'balance_gt'} ne '' and $params->{'balance_gt'} !~ m/^\d+$/) or ($params->{'balance_lt'} ne '' and $params->{'balance_lt'} !~ m/^\d+$/))
		{
		my $arr = $self->error if ($self->has_errors);
		push(@$arr , {MESSAGE => 'Invalid Numeric Range For Card Balance'});
		$self->error($arr);
		}

	if ($self->has_errors)
		{
		return undef;
		}

	my ($report_heading_loop, $report_output_row_loop, $report_output_column_loop, $filter_criteria)= ([],[],[],undef);

	$filter_criteria = " and gcard like '" . $self->company->merid . "%' ";	# VERY VERY IMPORTANT.
	$filter_criteria .= " and adate >= '$start_adate' and adate <= '$end_adate' " if ($start_adate and $end_adate);
	$filter_criteria .= " and ldate >= '$start_ldate' and ldate <= '$end_ldate' " if ($start_ldate and $end_ldate);

	$filter_criteria .= " and balance >= " . $params->{'balance_gt'} if ($params->{'balance_gt'} ne '');
	$filter_criteria .= " and balance <= " . $params->{'balance_lt'} if ($params->{'balance_lt'} ne '');

	$filter_criteria .= $self->session->param('report_filter_criteria') if ($self->session->param('report_name') eq $params->{'reportname'} and ($params->{'sort_by'} ne '' or $params->{'do'} eq 'email'));

	$report_heading_loop = [	{NAME => 'Card number' , COLUMN_NAME => 'gcard'},
								{NAME => 'Active date' , COLUMN_NAME => 'adate'},
								{NAME => 'Last used' , COLUMN_NAME => 'ldate'},
								{NAME => 'Expiry date' , COLUMN_NAME => 'edate'},
								{NAME => 'Balance' , COLUMN_NAME => 'balance'},
							];

	my $SrchGC = TicketProWebGift::GCard->new;
	my $gift_card_array = $SrchGC->search($filter_criteria, $self->get_order_by_column);

	foreach my $GCard (@$gift_card_array)
		{
		$report_output_column_loop = [	{
										VALUE => substr($GCard->gcard, 5),
										ALIGN => 'CENTER',
										},
										{
										VALUE => TicketProWebGift::Display::Utils->get_american_date($GCard->adate),
										ALIGN => 'CENTER',
										},
										{
										VALUE => TicketProWebGift::Display::Utils->get_american_date($GCard->ldate),
										ALIGN => 'CENTER',
										},
										{
										VALUE => TicketProWebGift::Display::Utils->get_american_date($GCard->edate),
										ALIGN => 'CENTER',
										},
										{
										VALUE => $GCard->balance,
										ALIGN => 'CENTER',
										}];

		push(@$report_output_row_loop , {REPORT_OUTPUT_COLUMN_LOOP => $report_output_column_loop});
		}
	
	my $filter_criteria_loop = $self->get_filter_criteria_hash_arr($filter_criteria);

	return ($report_heading_loop , $report_output_row_loop , $filter_criteria_loop);
	}

sub generate_customer_information_report
	{
	my $self = shift;
	my $params = $self->params;

	my ($start_actdate, $end_actdate) = $self->get_start_and_end_date('actdate');

	$self->check_for_valid_date_range('actdate', $start_actdate, $end_actdate);

	if ($self->has_errors)
		{
		return undef;
		}

	my ($report_heading_loop, $report_output_row_loop, $report_output_column_loop, $filter_criteria)= ([],[],[],undef);

	$filter_criteria .= " and cardnumber like '" . $self->company->merid . "%' ";	# VERY VERY IMPORTANT.
	$filter_criteria .= " and actdate >= '$start_actdate' and actdate <= '$end_actdate' " if ($start_actdate and $end_actdate);
	$filter_criteria .= " and status = '" . $params->{'status'} . "' " if ($params->{'status'} ne '');

	$filter_criteria = $self->session->param('report_filter_criteria') if ($self->session->param('report_name') eq $params->{'reportname'} and ($params->{'sort_by'} ne '' or $params->{'do'} eq 'email'));

	$report_heading_loop = [	{NAME => 'card' , COLUMN_NAME => 'cardnumber'},
								{NAME => 'name' , COLUMN_NAME => 'name'},
								{NAME => 'address 1' , COLUMN_NAME => 'address1'},
								{NAME => 'city' , COLUMN_NAME => 'city'},
								{NAME => 'zip' , COLUMN_NAME => 'zipcode'},
								{NAME => 'email' , COLUMN_NAME => 'email'},
								{NAME => 'Act date' , COLUMN_NAME => 'actdate'},
								{NAME => 'Exp Date' , COLUMN_NAME => 'expdate'},
								{NAME => 'status' , COLUMN_NAME => 'status'},];


	my $SrchUser = TicketProWebGift::User->new;
	my $user_array = $SrchUser->search($filter_criteria, $self->get_order_by_column);

	foreach my $U (@$user_array)
		{
		$report_output_column_loop = [	{
										VALUE => substr($U->cardnumber, 5),
										ALIGN => 'CENTER',
										},
										{
										VALUE => $U->name,
										ALIGN => 'LEFT',
										},
										{
										VALUE => $U->address1,
										ALIGN => 'LEFT',
										},
										{
										VALUE => $U->city,
										ALIGN => 'CENTER',
										},
										{
										VALUE => $U->zipcode,
										ALIGN => 'LEFT',
										},
										{
										VALUE => $U->email,
										ALIGN => 'LEFT',
										},
										{
										VALUE => TicketProWebGift::Display::Utils->get_american_date($U->actdate),
										ALIGN => 'CENTER',
										},
										{
										VALUE => TicketProWebGift::Display::Utils->get_american_date($U->expdate),
										ALIGN => 'CENTER',
										},
										{
										VALUE => $U->status,
										ALIGN => 'CENTER',
										},];

		push(@$report_output_row_loop , {REPORT_OUTPUT_COLUMN_LOOP => $report_output_column_loop});
		}
	my $filter_criteria_loop = $self->get_filter_criteria_hash_arr($filter_criteria);

	return ($report_heading_loop , $report_output_row_loop , $filter_criteria_loop);
	}

sub generate_customer_card_details_report
	{
	my $self = shift;
	my $params = $self->params;

	my ($report_heading_loop, $report_output_row_loop, $report_output_column_loop, $filter_criteria)= ([],[],[],undef);

	$filter_criteria = " and gcard like '" . $self->company->merid . "%' ";	# VERY VERY IMPORTANT.

	$report_heading_loop = [	{NAME => 'Card number', COLUMN_NAME => 'gcard'},
								{NAME => 'Active date'},
								{NAME => 'Last used'},
								{NAME => 'Customer Name'},
								{NAME => 'City'},
								{NAME => 'Zipcode'},
								{NAME => 'Email'},
								{NAME => 'Balance', COLUMN_NAME => 'balance'},
							];

	my $SrchGC = TicketProWebGift::GCard->new;
	my $gift_card_array = $SrchGC->search($filter_criteria, $self->get_order_by_column);

	my $User = TicketProWebGift::User->new;
	my $user_obj_array = $User->search(" and cardnumber like '" . $self->company->merid . "%' ");

	unless ($user_obj_array)
		{
		return ($report_heading_loop , $report_output_row_loop , undef);
		}

	my $user_hash = {};
	
	foreach my $U (@$user_obj_array)
		{
		$user_hash->{$U->cardnumber} = $U;
		}
	
	my $total_amount;
	
	foreach my $GCard (@$gift_card_array)
		{
		$User = $user_hash->{$GCard->gcard};
		$total_amount += $GCard->balance;
		
		$report_output_column_loop = [	{
										VALUE => substr($GCard->gcard, 5),
										ALIGN => 'CENTER',
										},
										{
										VALUE => TicketProWebGift::Display::Utils->get_american_date($GCard->adate),
										ALIGN => 'CENTER',
										},
										{
										VALUE => TicketProWebGift::Display::Utils->get_american_date($GCard->ldate),
										ALIGN => 'CENTER',
										},
										{
										VALUE => $User->name,
										ALIGN => 'LEFT',
										},
										{
										VALUE => $User->city,
										ALIGN => 'LEFT',
										},
										{
										VALUE => $User->zipcode,
										ALIGN => 'LEFT',
										},
										{
										VALUE => $User->email,
										ALIGN => 'LEFT',
										},
										{
										VALUE => $self->format_number($GCard->balance),
										ALIGN => 'CENTER',
										}];

		push(@$report_output_row_loop , {REPORT_OUTPUT_COLUMN_LOOP => $report_output_column_loop});
		}
	#########################################################
	
	push(@$report_output_row_loop , {REPORT_OUTPUT_COLUMN_LOOP => [{VALUE => '&nbsp;', COLSPAN => 8}]});
	push(@$report_output_row_loop , {REPORT_OUTPUT_COLUMN_LOOP => [
													{VALUE => '<B>Total number of cards</B>', ALIGN => 'CENTER', COLSPAN => 3},
													{VALUE => '<B>' . scalar(@$gift_card_array) . '</B>', ALIGN => 'CENTER'},
													{VALUE => '<B>Total Amount</B>', ALIGN => 'CENTER', COLSPAN => 3},
													{VALUE => '<B>$' . $self->format_number($total_amount) . '</B>', ALIGN => 'CENTER'}
													]});
	#########################################################
	my $filter_criteria_loop = $self->get_filter_criteria_hash_arr($filter_criteria);

	return ($report_heading_loop , $report_output_row_loop , $filter_criteria_loop);
	}

##########################################################################################################

sub get_start_and_end_date
	{
	my $self = shift;
	my $key_value = shift;

	unless ($key_value)
		{
		return undef ;
		}

	my $params = $self->params;

	my ($mm_key, $dd_key, $yy_key) = ($key_value . '_start_mm', $key_value . '_start_dd', $key_value . '_start_yy');
	my $start_date = $params->{$yy_key} . '-' . $params->{$mm_key} . '-' . $params->{$dd_key};

	($mm_key, $dd_key, $yy_key) = ($key_value . '_end_mm', $key_value . '_end_dd', $key_value . '_end_yy');
	my $end_date = $params->{$yy_key} . '-' . $params->{$mm_key} . '-' . $params->{$dd_key};

	$start_date = undef if ($start_date eq '--');
	$end_date = undef if ($end_date eq '--');

	return ($start_date, $end_date);
	}
=cut
sub get_filter_criteria_hash_arr
	{
	my $self = shift;
	my $filter_criteria = shift;

	$filter_criteria =~ s/^\ and\ //;

	my @filter_criteria_arr = split(' and ' , $filter_criteria);
	my $filter_criteria_hash_arr = [];

	foreach my $criteria (@filter_criteria_arr)
		{
		my ($key,$value);

		if ($criteria =~ m/\ >=\ /)
			{
			($key,$value) = split(' >= ' , $criteria);

			if ($value =~ m/^\d+$/)
				{
				$key = 'Start Range Of ' . TicketProWebGift::Display::Utils->get_filter_value_from_key($key);
				}
			else
				{
				$key = TicketProWebGift::Display::Utils->get_filter_value_from_key($key) . ' Begin';
				}
			}
		elsif ($criteria =~ m/\ <=\ /)
			{
			($key,$value) = split(' <= ' , $criteria);

			if ($value =~ m/^\d+$/)
				{
				$key = 'End Range Of ' . TicketProWebGift::Display::Utils->get_filter_value_from_key($key);
				}
			else
				{
				$key = TicketProWebGift::Display::Utils->get_filter_value_from_key($key) . ' End';
				}
			}
		elsif ($criteria =~ m/\ =\ /)
			{
			($key,$value) = split(' = ' , $criteria);
			$value = substr($value, 6) if ($key eq 'gcard'); # CARD NO CONTAINS QUOTE ADD 5+1 = 6
			$key = TicketProWebGift::Display::Utils->get_filter_value_from_key($key);
			}
		else
			{
			# SKIP RECORD IF NO ANY FILTER CRITERIA RECORD FOUND.
			next;
			}

		$value =~ s/^[\'\s]+//g;
		$value =~ s/[\'\s]+$//g;

		if (TicketProWebGift::Display::Utils->is_valid_date($value))
			{
			$value = TicketProWebGift::Display::Utils->get_american_date($value);
			}

		push(@$filter_criteria_hash_arr ,	{
												KEY => $key,
												VALUE => $value,
												});
		}

	return $filter_criteria_hash_arr;
	}

sub get_order_by_column
	{
	my $self = shift;
	my $params = $self->params;

	if ($params->{'sort_by'} eq '')
		{
		return undef;
		}
	else
		{
		return $params->{'sort_by'};
		}
	}

sub check_for_valid_date_range
	{
	my $self = shift;
	my $key = shift;
	my $start_date = shift;
	my $end_date = shift;

	return unless ($key or $start_date or $end_date);

	my $msg_arr = [];

	if ($self->has_errors)
		{
		$msg_arr = $self->error;
		}

	if (($start_date and $start_date !~ m/^\d+\-\d+\-\d+$/) or ($end_date and $end_date !~ m/^\d+\-\d+\-\d+$/))
		{
		push(@$msg_arr , {MESSAGE => 'Enter Numeric Value For ' . TicketProWebGift::Display::Utils->get_filter_value_from_key($key) . ' Date Range'});
		}
	elsif ($start_date =~ m/^\d+\-\d+\-\d+$/ and $end_date =~ m/^\d+\-\d+\-\d+$/ and
		!(TicketProWebGift::Display::Utils->is_valid_date($start_date) and
		 TicketProWebGift::Display::Utils->is_valid_date($end_date)))
		{
		push(@$msg_arr , {MESSAGE => 'Invalid Date Range For ' . TicketProWebGift::Display::Utils->get_filter_value_from_key($key)});
		}
	elsif (TicketProWebGift::Display::Utils->compare_date($start_date,$end_date) < 0)
		{
		push(@$msg_arr , {MESSAGE => 'Start Date Should Be Less Than End Date For ' . TicketProWebGift::Display::Utils->get_filter_value_from_key($key)});
		}

	$self->error($msg_arr);
	}

sub format_number
	{
	my $self = shift;
	my $number = shift;

	my ($w, $d) = split(/\./ , $number);

	$w = '0' x (3 - length $w) . $w;
	$d = $d . '0' x (2 - length $d);

	$number = $w . '.' . $d;

	return $number;
	}

sub covert_cents_to_dollar
	{
	my $self = shift;
	my $cents = shift;
	return $self->format_number($cents/100);
	}

1;

__END__
