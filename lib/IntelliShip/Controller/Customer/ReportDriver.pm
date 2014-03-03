package IntelliShip::Controller::Customer::ReportDriver;
use Moose;
use Data::Dumper;
use namespace::autoclean;
use IntelliShip::Utils;
use IntelliShip::DateUtils;

BEGIN {

	extends 'IntelliShip::Errors';

	has 'context' => ( is => 'rw' );
	has 'contact' => ( is => 'rw' );
	has 'customer' => ( is => 'rw' );

	has 'arrs_api_context' => ( is => 'rw' );

	}

sub API
	{
	my $self = shift;

	unless ($self->arrs_api_context)
		{
		my $APIRequest = IntelliShip::Arrs::API->new;
		$APIRequest->context($self->context);
		$self->arrs_api_context($APIRequest);
		}

	return $self->arrs_api_context;
	}

sub make_report
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	if ($params->{'report'} eq 'SHIPMENT')
		{
		return $self->generate_shipment_report;
		}
	elsif ($params->{'report'} eq 'MANIFEST')
		{
		return $self->generate_manifest_report;
		}
	elsif ($params->{'report'} eq 'SUMMARY_SERVICE')
		{
		return $self->generate_summary_service_report;
		}
	elsif ($params->{'report'} eq 'EOD')
		{
		return $self->generate_eod_report;
		}
	#else
	#	{
	#	$self->error([{MESSAGE => 'Unable To Run Requested Report'}]);
	#	}
	}

sub generate_shipment_report
	{
	my $self= shift;

	my $c = $self->context;
	my $params = $c->req->params;

	#$c->log->debug("Ref Param: " . $_ . " => " . ref $params->{$_}) foreach keys %$params;

	my $Contact  = $self->contact;
	my $Customer = $self->customer;
	my $Address  = $Customer->address;

	my $carriers;
	unless ($params->{'carriers'} =~ /all/i)
		{
		$carriers= (ref $params->{'carriers'} eq 'ARRAY' ? $params->{'carriers'} : [$params->{'carriers'}]);
		}

	my $start_date = IntelliShip::DateUtils->get_db_format_date($params->{'startdate'});
	my $stop_date  = IntelliShip::DateUtils->get_db_format_date($params->{'enddate'});

	$c->log->debug("Filter Criteria, start_date: " . $start_date .
					", stop_date: " . $stop_date .
					", customerid: " . $Customer->customerid .
					", Carriers: " . Dumper($params->{'carriers'}));

	my ($report_heading_loop, $report_output_row_loop)= ([],[]);

	my $and_customerid_sql = " AND c.customerid = '" . $Customer->customerid . "'";
	my $and_start_date_sql = " AND sh.dateshipped >= timestamp '$start_date 00:00:00' ";
	my $and_stop_date_sql = " AND sh.dateshipped <= timestamp '$stop_date 23:59:59' ";

	my $and_status_id_sql = " AND sh.statusid IN (10,100) ";
	my $and_ownertypeid_sql = " AND ppd.ownertypeid = 2000 ";
	my $and_datatypeid_sql = " AND ppd.datatypeid = 1000 ";

	my $and_carrier_sql = $self->get_carrier_sql;

	my $and_username_sql = '';
	unless ($Customer->superuser)
		{
		$and_username_sql .= " AND c.username = '" . $Customer->username . "'";
		}
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
		$and_co_type_id_sql = " AND cotypeid IN (1,2) ";
		}

	my $WHERE;

	my $report_OUTPUT_fields = "";
	if ($params->{'format'} eq 'CSV')
		{
		$report_heading_loop = [
				{name => 'weight'},
				{name => 'dim weight'},
				{name => 'dims'},
				{name => 'carrier name'},
				{name => 'zone'},
				{name => 'service name'},
				{name => 'Airbill#'},
				{name => 'freight charge'},
				{name => 'other charges'},
				{name => 'total charges'},
				{name => 'est pick up date'},
				{name => 'commodity quantity'},
				{name => 'shipper number'},
				{name => 'shipper name'},
				{name => 'shipper city'},
				{name => 'shipper state'},
				{name => 'deliver date'},
				{name => 'signed for by'},
				{name => 'receiver company'},
				{name => 'receiver address'},
				{name => 'receiver city'},
				{name => 'receiver state'},
				{name => 'receiver zip'},
				{name => 'receiver contact'},
				{name => 'order number'},
				{name => 'customer number'},
			];

		$report_OUTPUT_fields = "
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
				";
		}
	else
		{
		$report_heading_loop = [
				{name => 'order number'},
				{name => 'receiver address'},
				{name => 'tracking number'},
				{name => 'zone'},
				{name => 'service level'},
				{name => 'zip/zone'},
				{name => 'billing weight'},
				{name => 'total charges'},
				{name => 'date shipped'},
			];

		$report_OUTPUT_fields = "
				sh.shipmentid,
				co.ordernumber,
				sh.tracking1,
				a.addressname || ' ' || a.address1 || ' ' || a.city || ' ' || a.state || ' ' || a.zip as receiveraddress,
				sh.zonenumber,
				substring(a.zip from 1 for 3) || '/' || a.state as zipzone,
				sh.service as servicename,
				sh.weight,
				sh.cost,
				sh.dateshipped,
				sh.carrier as carriername
				";
		}
	my $report_SQL_1 = '';
	if (!grep(/^OTHER_/, @$carriers))
		{
		$WHERE =
				$and_customerid_sql .
				$and_start_date_sql .
				$and_stop_date_sql .
				$and_status_id_sql .
				$and_ownertypeid_sql .
				$and_datatypeid_sql .
				$and_username_sql .
				$and_co_type_id_sql .
				$and_allowed_extcustnum_sql .
				$and_carrier_sql;

		$WHERE =~ s/^\ *AND//;
		$WHERE = " WHERE " . $WHERE if $WHERE;

		$report_SQL_1 = "
			SELECT
				$report_OUTPUT_fields
			FROM
				shipment sh
				INNER JOIN co ON co.coid = sh.coid
				INNER JOIN customer c ON co.customerid = c.customerid
				INNER JOIN address a ON a.addressid = sh.addressiddestin
				INNER JOIN packprodata ppd ON sh.shipmentid = ppd.ownerid
			$WHERE
			";
		}

	my $report_SQL_2;
	if (grep(/^OTHER_/, @$carriers))
		{
		my ($join_other_sql,$and_other_name_in_sql) = ('','');

		my @matched_carriers = split(/\,/, @$carriers);
		$_ =~ s/^\s+|\s+$//g foreach @matched_carriers;

		my @other_carriers;
		$_ =~ m/^OTHER_(\w+)/ and push(@other_carriers, $1)  foreach @matched_carriers;
		if (@other_carriers)
			{
			$join_other_sql = " other o INNER JOIN ON o.othername = sh.carrier ";

			my @other_names;
			foreach my $other_id (@other_carriers)
				{
				my @Others = $Customer->others({ otherid => $other_id });
				push(@other_names, $_->othername) foreach @Others;
				}

			$and_other_name_in_sql = " AND o.othername IN (" . join(',', @other_names) . ") "if @other_names;
			}

		$WHERE =
				$and_customerid_sql .
				$and_start_date_sql .
				$and_stop_date_sql .
				$and_status_id_sql .
				$and_ownertypeid_sql .
				$and_datatypeid_sql .
				$and_username_sql .
				$and_other_name_in_sql .
				$and_allowed_extcustnum_sql;

		$WHERE =~ s/^\ *AND//;
		$WHERE = " WHERE " . $WHERE if $WHERE;
		$report_SQL_2 .= "
			SELECT
				$report_OUTPUT_fields
			FROM
				shipment sh
				INNER JOIN co ON co.coid=sh.coid
				INNER JOIN customer c ON co.customerid = c.customerid
				INNER JOIN address a ON a.addressid = sh.addressiddestin
				INNER JOIN packprodata ppd ON sh.shipmentid = ppd.ownerid
				$join_other_sql
			$WHERE
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

	#$c->log->debug("SHIPMENT REPORT SQL: \n" . $report_SQL);

	my $report_sth = $c->model('MyDBI')->select($report_SQL);

	#$c->log->debug("TOTAL RECORDS: " . $report_sth->numrows);

	my $weight_sum = 0;
	my $dimweight_sum = 0;
	my $tot_chg_sum = 0;
	my $other_chg_sum = 0;
	my $commodity_sum = 0;
	my $distinctCarriers = {};
	my $ship_count = $report_sth->numrows;

	for (my $row=0; $row < $report_sth->numrows; $row++)
		{
		my $row_data = $report_sth->fetchrow($row);

		$distinctCarriers->{$row_data->{'carriername'}} = 1;

		#$c->log->debug("row_data: " . Dumper $row_data);
		my ($date, $time) = split(/ /,$row_data->{'dateshipped'});
		$row_data->{'dateshipped'} = $date;

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

		my $report_output_column_loop = [];
		if ($params->{'format'} eq 'CSV')
			{
			if ( $row_data->{'customerserviceid'} )
				{
				my $CSRef = $self->API->get_CS_shipping_values($row_data->{'customerserviceid'},$row_data->{'customerid'});
				$row_data->{'webaccount'} = $CSRef->{'webaccount'};
				#$c->log->debug("get_CS_shipping_values: " . Dumper $CSRef);
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

			$row_data->{'datedelivered'} = $row_data->{'datedelivered'} =~ /(.*)-\d{2}$/;

			# Build dim string
			$row_data->{'dims'} = $row_data->{'dimlength'};
			$row_data->{'dims'} .= 'x' . $row_data->{'dimwidth'} if $row_data->{'dims'} and $row_data->{'dimwidth'};
			$row_data->{'dims'} .= 'x' . $row_data->{'dimheight'} if $row_data->{'dims'} and $row_data->{'dimheight'};
			$row_data->{'dims'} = '' unless $row_data->{'dims'};

			$report_output_column_loop = [
					{ value => $row_data->{'weight'} },
					{ value => $row_data->{'dimweight'} },
					{ value => $row_data->{'dims'} },
					{ value => $row_data->{'carriername'} },
					{ value => $row_data->{'zonenumber'} },
					{ value => $row_data->{'servicename'} },
					{ value => $row_data->{'tracking1'} },
					{ value => $row_data->{'cost'}, align => 'right', currency => '$' },
					{ value => $row_data->{'othercharges'}, align => 'right', currency => '$' },
					{ value => $row_data->{'cost'} + $row_data->{'othercharges'}, align => 'right', currency => '$' },
					{ value => IntelliShip::DateUtils->american_date($row_data->{'dateshipped'}) },
					{ value => $row_data->{'commodityquantity'} },
					{ value => $row_data->{'webaccount'} },
					{ value => $row_data->{'shipper_name'} },
					{ value => $row_data->{'shipper_city'} },
					{ value => $row_data->{'shipper_state'} },
					{ value => $row_data->{'datedelivered'} },
					{ value => $row_data->{'podname'} },
					{ value => $row_data->{'addressname'} },
					{ value => $row_data->{'address1'} },
					{ value => $row_data->{'addresscity'} },
					{ value => $row_data->{'addressstate'} },
					{ value => $row_data->{'addresszip'} },
					{ value => $row_data->{'contactname'} },
					{ value => $row_data->{'ordernumber'} },
					{ value => $row_data->{'custnum'} },
				];
			}
		else
			{
			$row_data->{'weight'} = $row_data->{'weight'} || "";
			$row_data->{'zonenumber'} = $row_data->{'zonenumber'} || "";
			$row_data->{'servicename'} = $row_data->{'servicename'} || "";
			$row_data->{'tracking1'} = $row_data->{'tracking1'} || "";
			$row_data->{'cost'} = $row_data->{'cost'} || "";
			$row_data->{'dateshipped'} = $row_data->{'dateshipped'} || "";
			$row_data->{'receiveraddress'} = $row_data->{'receiveraddress'} || "UNKNOWN";
			$row_data->{'ordernumber'} = $row_data->{'ordernumber'} || "";
			$row_data->{'zipzone'} = $row_data->{'zipzone'} || "";

			$report_output_column_loop = [
					{ value => $row_data->{'ordernumber'} },
					{ value => $row_data->{'receiveraddress'} }	,
					{ value => $row_data->{'tracking1'} },
					{ value => $row_data->{'zonenumber'} },
					{ value => $row_data->{'servicename'} },
					{ value => $row_data->{'zipzone'} },
					{ value => $row_data->{'weight'} , align => 'right'},
					{ value => $row_data->{'cost'} + $row_data->{'othercharges'}, align => 'right', currency => '$' },
					{ value => IntelliShip::DateUtils->american_date($row_data->{'dateshipped'}) }
				];
			}

		push(@$report_output_row_loop, $report_output_column_loop);

		$weight_sum += $row_data->{'weight'};
		$dimweight_sum += $row_data->{'dimweight'};
		$tot_chg_sum += $row_data->{'cost'};
		$other_chg_sum += $row_data->{'othercharges'};
		$commodity_sum += $row_data->{'commodityquantity'};

		## Keep the browser from timing out.
		# print "\n";
		# STDOUT->autoflush(1);
		}
		my $report_summary_row_loop = [];

		if ($params->{'format'} eq 'CSV')
			{
			$report_summary_row_loop = [
					{ value => $weight_sum, grandtotal => '1' },
					{ value => $dimweight_sum, grandtotal => '1'},
					{ value => '' , grandtotal => '1'},
					{ value => '' , grandtotal => '1'},
					{ value => '' , grandtotal => '1'},
					{ value => '' , grandtotal => '1'},
					{ value => '' , grandtotal => '1'},
					{ value => $tot_chg_sum, align => 'right', currency => '$' , grandtotal => '1'},
					{ value => $other_chg_sum, align => 'right', currency => '$' , grandtotal => '1'},
					{ value => $tot_chg_sum + $other_chg_sum, align => 'right', currency => '$' , grandtotal => '1'},
					{ value => '' , grandtotal => '1'},
					{ value => $commodity_sum , grandtotal => '1'},
					{ value => '' , grandtotal => '1'},
					{ value => '' , grandtotal => '1'},
					{ value => '' , grandtotal => '1'},
					{ value => '' , grandtotal => '1'},
					{ value => '' , grandtotal => '1'},
					{ value => '' , grandtotal => '1'},
					{ value => '' , grandtotal => '1'},
					{ value => '' , grandtotal => '1'},
					{ value => '' , grandtotal => '1'},
					{ value => '' , grandtotal => '1'},
					{ value => '' , grandtotal => '1'},
					{ value => '' , grandtotal => '1'},
					{ value => '' , grandtotal => '1'},
					{ value => '' , grandtotal => '1'},
				];
			}
		else
			{
			$report_summary_row_loop = [
					{ value => 'Total Shipments '. scalar @$report_output_row_loop },
					{ value => '' },
					{ value => '' },
					{ value => '' },
					{ value => '' },
					{ value => '' },
					{ value => $weight_sum, align => 'right' },
					{ value => $tot_chg_sum + $other_chg_sum, align => 'right', currency => '$' },
					{ value => '' }
				];
			}
	push(@$report_output_row_loop, $report_summary_row_loop);

	$WHERE .= " AND carrier = " . join(',', (keys %$distinctCarriers) ) if $params->{'carriers'} eq 'all';

	my $filter_criteria_loop = $self->get_filter_details($WHERE);

	return ($report_heading_loop , $report_output_row_loop , $filter_criteria_loop);
	}

sub generate_manifest_report
	{
	my $self= shift;
	my $c = $self->context;
	my $params = $c->req->params;

	my $Contact = $self->contact;
	my $Customer = $self->customer;

	$self->add_error("Report under consutruction, will be available soon. Thank you!");

	my ($report_heading_loop, $report_output_row_loop, $filter_criteria_loop)= ([],[],[]);
	return ($report_heading_loop , $report_output_row_loop , $filter_criteria_loop);
	}

sub generate_summary_service_report
	{
	my $self= shift;
	my $c = $self->context;
	my $params = $c->req->params;

	my $Contact = $self->contact;
	my $Customer = $self->customer;

	my $carriers;
	unless ($params->{'carriers'} =~ /all/i)
		{
		$carriers= (ref $params->{'carriers'} eq 'ARRAY' ? $params->{'carriers'} : [$params->{'carriers'}]);
		}

	my $start_date = IntelliShip::DateUtils->get_db_format_date($params->{'startdate'});
	my $stop_date  = IntelliShip::DateUtils->get_db_format_date($params->{'enddate'});

	$c->log->debug("Filter Criteria, start_date: " . $start_date .
					", stop_date: " . $stop_date .
					", customerid: " . $Customer->customerid .
					", Carriers: " . Dumper($params->{'carriers'}));

	my ($report_heading_loop, $report_output_row_loop)= ([],[]);

	$report_heading_loop = [
				{name => 'carrier'},
				{name => 'service'},
				{name => 'shipments'},
				{name => 'total charge'},
				{name => 'total weight'},
			];


	my $and_customerid_sql = " AND co.customerid = '" . $Customer->customerid . "'";
	my $and_start_date_sql = " AND sh.dateshipped >= timestamp '$start_date 00:00:00' ";
	my $and_stop_date_sql = " AND sh.dateshipped <= timestamp '$stop_date 23:59:59' ";

	my $and_status_id_sql = $self->get_co_status_sql;
	my $and_carrier_sql = $self->get_carrier_sql;

	my $WHERE =
			$and_customerid_sql .
			$and_start_date_sql .
			$and_stop_date_sql .
			$and_status_id_sql .
			$and_carrier_sql;

	$WHERE =~ s/^\ *AND//;
	$WHERE = " WHERE " . $WHERE if $WHERE;

	my $report_SQL = "
		SELECT
			sh.shipmentid,
			sh.carrier as carriername,
			sh.service
		FROM
			shipment sh
			INNER JOIN co ON co.coid = sh.coid
		$WHERE
		ORDER BY
			2,1
	";

	#$c->log->debug("SUMMARY SERVICE REPORT SQL: \n" . $report_SQL);

	my $report_sth = $c->model('MyDBI')->select($report_SQL);

	my $summaryDetails = {};
	my $distinctCarriers = {};
	for (my $row=0; $row < $report_sth->numrows; $row++)
		{
		my $row_data = $report_sth->fetchrow($row);
		$distinctCarriers->{$row_data->{'carriername'}} = 1;
		my $Shipment = $c->model('MyDBI::Shipment')->find({ shipmentid => $row_data->{shipmentid} });

		$summaryDetails->{$row_data->{'carriername'}} = {} unless $summaryDetails->{$row_data->{'carriername'}};
		$summaryDetails->{$row_data->{'carriername'}}->{$row_data->{'service'}} = {} unless $summaryDetails->{$row_data->{'carriername'}}->{$row_data->{'service'}};
		$summaryDetails->{$row_data->{'carriername'}}->{$row_data->{'service'}}->{'TTL_WEIGHT'} += $Shipment->total_weight;
		$summaryDetails->{$row_data->{'carriername'}}->{$row_data->{'service'}}->{'TTL_CHARGE'} += $Shipment->total_charge;
		$summaryDetails->{$row_data->{'carriername'}}->{$row_data->{'service'}}->{'TTL_COUNT'} += 1;
		}

	#$c->log->debug("%$summaryDetails: " . Dumper $summaryDetails);

	my $grand_total_shipment = 0;
	my $grand_total_charge = 0;
	my $grand_total_weight = 0;
	foreach my $carrier (keys %$summaryDetails)
		{
		my $total_shipment = 0;
		my $total_charge = 0;
		my $total_weight = 0;
		push(@$report_output_row_loop, [
					{ value => $carrier, carriername => '1' },
					{ value => '' },
					{ value => '' },
					{ value => '' },
					{ value => '' },
				]);

		my $serviceHash = $summaryDetails->{$carrier};
		foreach my $service (keys %$serviceHash)
			{
			my $dataHash = $serviceHash->{$service};
			my $report_output_column_loop = [
					{ value => '' },
					{ value => $service },
					{ value => $dataHash->{'TTL_COUNT'} },
					{ value => $dataHash->{'TTL_CHARGE'}, align => 'right', currency => '$' },
					{ value => $dataHash->{'TTL_WEIGHT'}, align => 'right' },

				];
			$total_shipment	+= $dataHash->{'TTL_COUNT'};
			$total_charge	+= $dataHash->{'TTL_CHARGE'};
			$total_weight	+= $dataHash->{'TTL_WEIGHT'};

			push(@$report_output_row_loop, $report_output_column_loop);
			}

		# Add Total Row
		push(@$report_output_row_loop, [
					{ value => $carrier. ' Total', carriertotal => '1' },
					{ value => '', carriertotal => '1' },
					{ value => $total_shipment, carriertotal => '1' },
					{ value => $total_charge, align => 'right', currency => '$', carriertotal => '1' },
					{ value => $total_weight, align => 'right', carriertotal => '1' },
				]);
		# Update Grand Total
		$grand_total_shipment	+= $total_shipment;
		$grand_total_charge		+= $total_charge;
		$grand_total_weight		+= $total_weight;

		# Add Blank Row
		push(@$report_output_row_loop, [
					{ value => '' },
					{ value => '' },
					{ value => '' },
					{ value => '' },
					{ value => '' },
				]);
		}

	# Add Grand Total Row
	push(@$report_output_row_loop, [
					{ value => 'Grand Total', grandtotal => '1'},
					{ value => '' , grandtotal => '1'},
					{ value => $grand_total_shipment , grandtotal => '1'},
					{ value => $grand_total_charge, align => 'right', currency => '$' , grandtotal => '1'},
					{ value => $grand_total_weight, align => 'right' , grandtotal => '1'},
				]);

	$WHERE .= " AND carrier = " . join(',', (keys %$distinctCarriers) ) if $params->{'carriers'} eq 'all';

	my $filter_criteria_loop = $self->get_filter_details($WHERE);

	return ($report_heading_loop , $report_output_row_loop , $filter_criteria_loop);
	}

sub generate_eod_report
	{
	my $self= shift;
	my $c = $self->context;
	my $params = $c->req->params;

	my $Contact = $self->contact;
	my $Customer = $self->customer;

	}

sub get_filter_details
	{
	my $self= shift;
	my $filter_criteria = shift;

	my $c = $self->context;
	my $params = $c->req->params;


	#if ($params->{'report'} eq 'SHIPMENT')
	#	{
	#	#
	#	}
	$filter_criteria =~ s/\s*WHERE\s*//i;
	my $filter_criteria_hash_arr = [];
	my @filter_criteria_arr = split(' AND ' , $filter_criteria);

	foreach my $criteria (@filter_criteria_arr)
		{
		$criteria =~ s/^\s+//;
		$criteria =~ s/\s+$//;
		my ($key,$value);

		if ($criteria =~ m/\ >=\ /)
			{
			($key,$value) = split(' >= ' , $criteria);

			if ($value =~ m/^\d+$/)
				{
				$key = 'Start Range Of ' . IntelliShip::Utils->get_filter_value_from_key($key);
				}
			else
				{
				$value =~ s/\ *timestamp\ *//;
				$key = IntelliShip::Utils->get_filter_value_from_key($key) . ' Begin';
				}
			}
		elsif ($criteria =~ m/\ <=\ /)
			{
			($key,$value) = split(' <= ' , $criteria);

			if ($value =~ m/^\d+$/)
				{
				$key = 'End Range Of ' . IntelliShip::Utils->get_filter_value_from_key($key);
				}
			else
				{
				$value =~ s/\ *timestamp\ *//;
				$key = IntelliShip::Utils->get_filter_value_from_key($key) . ' End';
				}
			}
		elsif ($criteria =~ m/\ =\ /)
			{
			($key,$value) = split(' = ' , $criteria);
			$key = IntelliShip::Utils->get_filter_value_from_key($key);
			}
		elsif ($criteria =~ m/\ IN\ /i)
			{
			($key,$value) = split(' IN ' , $criteria);
			$value =~ s/\(//;
			$value =~ s/\)//;
			$value =~ s/\'\,\'/\,\ /g;
			$key = IntelliShip::Utils->get_filter_value_from_key($key);
			}
		else
			{
			# SKIP RECORD IF NO ANY FILTER CRITERIA RECORD FOUND.
			next;
			}

		$value = $self->get_value_description($key, $value);

		next unless $key and $value;

		push(@$filter_criteria_hash_arr , { KEY => $key, VALUE => $value });
		}

	return $filter_criteria_hash_arr;
	}

sub get_value_description
	{
	my $self = shift;
	my $key = shift || '';
	my $value = shift;

	$value =~ s/(^[\'\s]+|[\'\s]+$)//g;

	if ($key =~ /Status/i)
		{
		my $WHERE = { statusid => ($value =~ /,/ ? [ split(',' , $value) ] : $value) };
		$value = join(", ", map { $_->costatusname } $self->context->model('MyDBI::Costatus')->search($WHERE));
		}
	elsif ($value =~ /^\d{4}\-\d{2}\-\d{2}/ and IntelliShip::DateUtils->is_valid_date($value))
		{
		$value = IntelliShip::DateUtils->american_date_time($value);
		}

	return $value;
	}

sub get_carrier_sql
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	if ($params->{'carriers'} eq 'all')
		{
		return '';
		}

	my $and_carrier_sql;
	if (ref $params->{'carriers'} eq 'ARRAY')
		{
		$and_carrier_sql = " AND sh.carrier IN ('" . join("','", @{$params->{'carriers'}}) . "') ";
		}
	else
		{
		$and_carrier_sql = " AND sh.carrier = '" . $params->{'carriers'} . "' ";
		}
	return $and_carrier_sql;
	}

sub get_co_status_sql
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	my $and_status_id_sql = ' AND sh.statusid IN (10,100) ';

	return $and_status_id_sql if (ref $params->{'costatus'} eq 'ARRAY' and grep(/all/, @{$params->{'costatus'}})) or  $params->{'costatus'} eq 'all';

	if (ref $params->{'costatus'} eq 'ARRAY')
		{
		$and_status_id_sql = " AND sh.statusid IN ('" . join("','", @{$params->{'costatus'}}) . "') ";
		}
	else
		{
		$and_status_id_sql = " AND sh.statusid = '" . $params->{'costatus'} . "' ";
		}

	return $and_status_id_sql;
	}

__PACKAGE__->meta->make_immutable;

1;

__END__