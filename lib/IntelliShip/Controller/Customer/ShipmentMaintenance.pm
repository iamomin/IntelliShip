package IntelliShip::Controller::Customer::ShipmentMaintenance;
use Moose;
use IO::File;
use Data::Dumper;
use namespace::autoclean;

BEGIN { extends 'IntelliShip::Controller::Customer'; }

=head1 NAME

IntelliShip::Controller::Customer::ShipmentMaintenance - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;
	my $params = $c->req->params;

    #$c->response->body('Matched IntelliShip::Controller::Customer::ShipmentMaintenance in Customer::ShipmentMaintenance.');
	$c->log->debug("Shipment Maintenance");

	my $do_value = $params->{'do'} || '';
	if ($do_value eq 'Submit')
		{
		$self->setup_report;
		}
	else
		{
		$self->setup_dispaly;
		}
	}

sub setup_dispaly :Private
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	$c->stash->{SETUP_SCREEN} = 1;
	$c->stash->{carrierservice_list} = $self->get_carrier_services_list;
	$c->stash(template => "templates/customer/shipment-maintenance.tt");
	}

sub get_carrier_services_list
	{
	my $self = shift;

	my $c = $self->context;
	my $myDBI = $c->model("MyDBI");
	my $Customer = $self->customer;

	my $list = [];

	my $carrierservicesql = "SELECT 
								shipment.carrier, shipment.service
							FROM shipment
							inner join co on shipment.coid = co.coid 
							and co.customerid = '" . $self->customer->customerid . "'
							and shipment.statusid in (10,100) 
							WHERE 
								shipment.carrier <> '' and shipment.service <> '' 
								and (date(shipment.dateshipped) = date(timestamp 'now') or date(shipment.datecreated) = date(timestamp 'now'))
								group by shipment.carrier, shipment.service";

	my $carrierservice_sth = $myDBI->select($carrierservicesql);
	for (my $row=0; $row < $carrierservice_sth->numrows; $row++)
		{
		my $data = $carrierservice_sth->fetchrow($row);
		push(@$list, { value => $data->{'carrier'} . '-' . $data->{'service'}, name => $data->{'carrier'} . '-' . $data->{'service'} });
		}

	my $othercarriersql = "SELECT 
								DISTINCT shipment.otherid, othername 
							FROM shipment 
							INNER JOIN co on shipment.coid = co.coid
								and shipment.statusid in (10,100) 
								and co.customerid = '" . $self->customer->customerid . "'
							INNER JOIN other on other.otherid = shipment.otherid
							WHERE 
								(date(shipment.dateshipped) = date(timestamp 'now') or date(shipment.datecreated) = date(timestamp 'now'))
								and othername <> ''";

	my $othercarrier_sth = $myDBI->select($othercarriersql);
	for (my $row=0; $row < $othercarrier_sth->numrows; $row++)
		{
		my $data = $othercarrier_sth->fetchrow($row);
		push(@$list, { value => 'OTHER_' . $data->{'otherid'}, name => $data->{'othername'} });
		}

	my $manifestcarriersql = "SELECT 
									DISTINCT manifest.carrier
								FROM manifest 
								INNER JOIN manifestshipment on manifestshipment.manifestid = manifest.manifestid 
									and manifest.halovoiddate is null
								INNER JOIN shipment on manifestshipment.shipmentid = shipment.shipmentid 
								INNER JOIN co on shipment.coid = co.coid 
									and co.customerid = '" . $self->customer->customerid . "'
								WHERE manifest.carrier <> ''";

	my $manifestcarrier_sth = $myDBI->select($manifestcarriersql);
	for (my $row=0; $row < $manifestcarrier_sth->numrows; $row++)
		{
		my $data = $manifestcarrier_sth->fetchrow($row);
		my $carrier_name = $self->get_carrier_name($data->{'carrier'});
		next unless ($carrier_name);
		push(@$list, { value => 'MANIFEST_' . $data->{'carrier'}, name => 'MANIFEST - ' . $carrier_name });
		}

	return $list;
	}

sub get_carrier_name
	{
	my $self = shift;
	my $carrier_id = shift;

	my $c = $self->context;
	my $params = $c->req->params;
	my $myDBI = $c->model("MyArrs");

	my $SQL = "SELECT carriername from carrier where carrierid = '" . $carrier_id . "'";
	my $sth = $myDBI->select($SQL);
	if ($sth->numrows > 0)
		{
		my $data = $sth->fetchrow(0);
		return $data->{'carriername'};
		}
	}

sub setup_report
	{
	my $self = shift;

	my $c = $self->context;
	my $params = $c->req->params;
	my $myDBI = $c->model("MyDBI");

	my $Contact  = $self->contact;
	my $Customer = $self->customer;
	my $shipment_list = [];

	# check for restricted login
	my $and_AllowedExtCustNum_SQL = $self->get_allowed_ext_cust_num_sql;

	# Set our cotypeid sql to be used later
	my $and_co_type_id_sql;
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

	my $where;
	my $is_manifest = 0;
	my $csid = $params->{'csid'};
	if ($params->{'trackingnumber'} and length($params->{'trackingnumber'}) > 0)
		{
		$where = " shipment.tracking1= '" . $params->{'trackingnumber'} . "' ";
		}
	elsif ($csid =~ /^OTHER_/)
		{
		$csid =~ s/^OTHER_//;
		$where = " shipment.otherid = '" . $csid . "' ";
		}
	elsif ($csid =~ /^MANIFEST_/ )
		{
		$is_manifest = 1;
		$csid =~ s/^MANIFEST_//;
		$where = " manifest.carrier = '" . $csid . "' ";
		}
	else
		{
		my ($carrier,$service) = split(" - ",$csid);
		$where = " shipment.carrier = '" . $carrier . "'";
		$where .= " and shipment.service = '" . $service . "' ";
		}

	my $SQL;
	if ($is_manifest)
		{
		$c->stash->{IS_MANIFEST} = 1  if ($is_manifest);
		$SQL = "SELECT 
					DISTINCT manifest.manifestid, 'manifest' as coid, manifest.datecreated
				FROM
					manifest
					INNER JOIN manifestshipment on manifestshipment.manifestid = manifest.manifestid and manifest.halovoiddate is null
					INNER JOIN shipment on manifestshipment.shipmentid = shipment.shipmentid 
					INNER JOIN co on shipment.coid = co.coid and co.customerid = '" . $self->customer->customerid . "'
				WHERE 
					$where
					 ORDER BY manifest.datecreated desc";
		}
	else
		{
		$c->log->debug("Shipment Maintenance, we are here ");
		$c->stash->{IS_CARRIER} = 1;
		$SQL = "SELECT 
					shipment.shipmentid, co.coid
				FROM
					shipment
				INNER JOIN co on shipment.coid = co.coid and shipment.statusid in (10,100)
				WHERE 
					(
						date(shipment.dateshipped) = date(timestamp 'now') or 
						date(shipment.datecreated) = date(timestamp 'now')
					) 
				and co.customerid = '" . $self->customer->customerid . "'
				and $where
				$and_AllowedExtCustNum_SQL
				$and_co_type_id_sql
				 ORDER BY dateshipped desc";
		}

	my $sth = $myDBI->select($SQL);
	for (my $row=0; $row < $sth->numrows; $row++)
		{
		my $data = $sth->fetchrow($row);
		my $coid = $data->{'coid'};

		if ($coid eq 'manifest')
			{
			my $ManifestValues = {};
			my $manifestid = $data->{'manifestid'};

			my $Manifest =  $c->model('MyDBI::Manifest')->find({manifestid => $manifestid});
			# $c->log->debug("Manifest count is " . scalar @Manifest);

			# my $Manifest = $Manifest[0];

			$ManifestValues->{'tracking1'}     = $Manifest->manifestname;
			$ManifestValues->{'manifestid'}    = $Manifest->manifestid;
			#$ManifestValues->{'datecreated'}       = IntelliShip::DateUtils->american_date($Manifest->datecreated);
			$ManifestValues->{'carrier'}       = $csid;
			$ManifestValues->{'reprintscreen'} = 'reprintmanifest';

			# my $manifest_reprint_file = "$config->{BASE_PATH}/html/print/manifest/$Manifest->{'manifestid'}";
			# if ( -e $manifest_reprint_file )
			# 	{
			# 	$ManifestValues->{'reprint'} = 1;
			# 	}

			push(@$shipment_list, $ManifestValues);
			}
		else
			{
			my $ShipmentValues = {};
			my $shipmentid = $data->{'shipmentid'};

			my $CO = $c->model('MyDBI::Co')->find({coid => $coid});
			my $Shipment = $c->model('MyDBI::Shipment')->find({shipmentid => $shipmentid});
			my $Address = $c->model('MyDBI::Address')->find({addressiddestin => $Shipment->addressiddestin});

			$ShipmentValues->{'ordernumber'} = $CO->ordernumber;
			$ShipmentValues->{'carrier'} = $Shipment->carrier;
			$ShipmentValues->{'service'} = $Shipment->service;
			$ShipmentValues->{'shipdate'} = $Shipment->clientdatecreated;
			$ShipmentValues->{'addressname'} = $Address->addressname;
			$ShipmentValues->{'citystate'} = $Address->city . ', ' . $Address->state;

			my $label_reprint_file = IntelliShip::MyConfig->file_directory . "/html/print/label/" . $ShipmentValues->shipmentid;
			my $bol_reprint_file = IntelliShip::MyConfig->file_directory . "/html/print/bol/" . $ShipmentValues->shipmentid;
			my $po_reprint_file = IntelliShip::MyConfig->file_directory . "/html/print/po/" . $ShipmentValues->shipmentid;
			my $cominv_reprint_file = IntelliShip::MyConfig->file_directory . "/html/print/cominv/" . $ShipmentValues->shipmentid;
			my $packinglist_reprint_file = IntelliShip::MyConfig->file_directory . "/html/print/packinglist/" . $ShipmentValues->shipmentid;

			if ( -e $label_reprint_file || -e $bol_reprint_file || -e $po_reprint_file || -e $cominv_reprint_file )
				{
				$ShipmentValues->{'reprint'} = 1;
				}

			if ( -e $label_reprint_file )
				{
				$ShipmentValues->{'reprintscreen'} = 'reprintlabel';
				}
			elsif ( -e $bol_reprint_file )
				{
				$ShipmentValues->{'reprintscreen'} = 'bol_reprint';
				}
			elsif ( -e $po_reprint_file )
				{
				$ShipmentValues->{'reprintscreen'} = 'po_reprint';
				}
			elsif ( -e $cominv_reprint_file )
				{
				$ShipmentValues->{'reprintscreen'} = 'cominv_reprint';
				}
			elsif ( -e $packinglist_reprint_file )
				{
				$ShipmentValues->{'reprintscreen'} = 'packinglist_reprint';
				}

			push(@$shipment_list, $ShipmentValues);
			}
		}

	$c->stash->{shipment_list} = $shipment_list;
	$c->stash->{shipment_list_count} = @$shipment_list;

	$c->stash(template => "templates/customer/shipment-maintenance.tt");
	}

sub get_allowed_ext_cust_num_sql :Private
	{
	my $self = shift;
	my $Contact = $self->contact;
	my $arr = $Contact->get_restricted_values('extcustnum') if $Contact->is_restricted;
	return ($arr ? "AND upper(co.extcustnum) IN (" . join(',', @$arr) . ")" : '');
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
