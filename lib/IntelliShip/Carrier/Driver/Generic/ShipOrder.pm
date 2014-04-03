package IntelliShip::Carrier::Driver::Generic::ShipOrder;

use Moose;
use POSIX;
use Date::Manip;
use Data::Dumper;
use IntelliShip::Utils;
use IntelliShip::MyConfig;
use IntelliShip::DateUtils;

BEGIN { extends 'IntelliShip::Carrier::Driver'; }

sub process_request
	{
	my $self = shift;
	my $CO = $self->CO;
	my $Customer = $CO->customer;
	my $shipmentData = $self->data;
	my $Contact = $CO->contact;


	$self->log("Process Generic Ship Order");

	if ($shipmentData->{'tracking1'})
		{
		$shipmentData->{'manualtrackingflag'} = 1;
		}
	else
		{
		$shipmentData->{'tracking1'} = $self->GetCarrierTrackingNumber;
		}

	$self->log("___ TRACKING1: " . $shipmentData->{'tracking1'});

	my $weight = $CO->total_weight;
	$weight = $CO->estimatedweight if !$weight && $CO->estimatedweight;

	$shipmentData->{'weight'} = $weight ? $weight : $shipmentData->{'enteredweight'};

	if ($shipmentData->{'datetoship'})
		{
		$shipmentData->{'dateshipped'} = $shipmentData->{'datetoship'};
		}

	$shipmentData->{'truncd_custnum'}     = substr($shipmentData->{'custnum'}, 0, 16);
	$shipmentData->{'truncd_addressname'} = substr($shipmentData->{'addressname'}, 0, 16);

	$shipmentData->{'zonenumber'} = $self->API->get_zone_number(
			$shipmentData->{'branchaddresszip'},
			$shipmentData->{'addresszip'},
			$shipmentData->{'branchaddressstate'},
			$shipmentData->{'addressstate'},
			$shipmentData->{'branchaddresscountry'},
			$shipmentData->{'addresscountry'});

	$self->log("___ Zone Nubmer: " . $shipmentData->{'zonenumber'});

	my $Shipment = $self->insert_shipment($shipmentData);

	$shipmentData->{'chargeamount'} = $Shipment->total_charge;

	# Note user supplied tracking numbers
	if ( defined($shipmentData->{'manualtrackingflag'}) && $shipmentData->{'manualtrackingflag'} == 1 )
		{
		my $noteData = { ownerid => $Shipment->shipmentid };
		$noteData->{'note'}         = $shipmentData->{'tracking1'} . ' Input By ' . $self->contact->username;
		$noteData->{'contactid'}    = $self->contact->contactid;
		$noteData->{'notestypeid'}  = 1300;
		$noteData->{'datehappened'} = IntelliShip::DateUtils->get_timestamp_with_time_zone;

		$self->model('MyDBI::Note')->new($noteData)->insert;
		}

	my @packages = $Shipment->packages;
	my ($package_count,$current_count,$PrinterString) = (0,1,'');
	$package_count += $_->quantity foreach @packages;

	$self->log("___ total package count: " . $package_count);

	foreach my $Package (@packages)
		{
		foreach (my $count=1; $count <= $Package->quantity; $count++)
			{
			$shipmentData->{'quantitydisplay'} = $current_count++ . ' of ' . $package_count;
			$shipmentData->{'weightdisplay'}   = $Package->dimweight > $Package->weight ? $Package->dimweight: $Package->weight;
			$PrinterString .= $self->get_EPL($shipmentData);
			}
		}

	$self->response->printer_string($PrinterString);
	}

sub GetCarrierTrackingNumber
	{
	my $self = shift;
	my $CO = $self->CO;
	my $Customer = $CO->customer;
	my $shipmentData = $self->data;

	my $TrackingNumber = '';

	# Figure tracking number, by carrier
	if ( $shipmentData->{'carrierid'} eq '0000000000004' )
		{
		my $SeqName = 'tracking_bax_seq';
		$TrackingNumber = $self->BuildMod7Tracking($SeqName);
		}
	elsif ( $shipmentData->{'carrierid'} eq '0000000000005' )
		{
		my $SeqName='tracking_fedexfreight_seq';
		$TrackingNumber = $self->BuildMod7Tracking($SeqName);
		}
	elsif ( $shipmentData->{'carrierid'} eq '0000000000006' )
		{
		# The way Vought does SOPs (all its 'customers' under one ID), only the main Vought ID gets here,
		# so we need to use the actual login values instead of the passed-in values
		##my $customer_id = $self->{'customer'}->GetValueHashRef()->{'customerid'};
		my $SeqName='tracking_conway_seq';

		$TrackingNumber = $self->BuildMod7Tracking($SeqName);
		}
	elsif ( $shipmentData->{'carrierid'} eq '0000000000008' )
		{
		my $SeqName = 'tracking_overnite_seq';
		$TrackingNumber = $self->BuildMod7Tracking($SeqName);
		}
	elsif ( $shipmentData->{'carrierid'} eq '0000000000013' )
		{
		my $SeqName='tracking_cfi_seq';
		$TrackingNumber = $self->Build9DigitTracking($SeqName);
		}
	elsif ( $shipmentData->{'carrierid'} eq '0000000000014' )
		{
		my $SeqName='tracking_cti_seq';
		$TrackingNumber = $self->BuildMod7Tracking($SeqName);
		}
	elsif ( $shipmentData->{'carrierid'} eq '0000000000015' || $shipmentData->{'carrierid'} eq '0000000000025' || $shipmentData->{'carrierid'} eq '0000000000011' )
		{
		my $SeqName = 'tracking_roadway_seq';
		$TrackingNumber = $self->BuildRoadwayTracking($SeqName);
		}
	elsif ( $shipmentData->{'carrierid'} eq '0000000000017' )
		{
		my $SeqName='tracking_bulldog_seq';
		$TrackingNumber = $self->Build9DigitTracking($SeqName);
		}
	elsif ( $shipmentData->{'carrierid'} eq '0000000000018' )
		{
		my $SeqName='tracking_rpm_seq';
		$TrackingNumber = $self->Build9DigitTracking($SeqName);
		}
	elsif ( $shipmentData->{'carrierid'} eq '0000000000019' )
		{
		my $SeqName='tracking_frontline_seq';
		$TrackingNumber = $self->Build9DigitTracking($SeqName);
		}
	elsif ( $shipmentData->{'carrierid'} eq '0000000000021' )
		{
		my $SeqName='tracking_atlanticfreight_seq';
		$TrackingNumber = $self->BuildTracking($SeqName);
		}
	elsif ( $shipmentData->{'carrierid'} eq '0000000000022' )
		{
		my $SeqName='tracking_eastwest_seq';
		$TrackingNumber = $self->BuildTracking($SeqName);
		}
	elsif ( $shipmentData->{'carrierid'} eq '0000000000023' )
		{
		my $SeqName='tracking_bullet_seq';
		$TrackingNumber = $self->BuildTracking($SeqName);
		}
	elsif ( $shipmentData->{'carrierid'} eq '0000000000026' )
		{
		my $SeqName = 'tracking_griley_seq';
		my $CheckSeqName = 'tracking_griley_checksum_seq';
		$TrackingNumber = $self->model('MyTracking')->sequence_number($SeqName) . $self->model('MyTracking')->sequence_number($CheckSeqName);
		}
	elsif ( $shipmentData->{'carrierid'} eq '0000000000031' )
		{
		if ( $Customer eq '8DTRVZJQQ43JD' )
			{
			my $SeqName='tracking_mach1_econo_seq';
			$TrackingNumber = 'LAX' . $self->BuildTracking($SeqName);
			}
		else
			{
			my $SeqName='tracking_mach1_seq';
			$TrackingNumber = 'LAX' . $self->BuildTracking($SeqName);
			}
		}
	elsif ( $shipmentData->{'carrierid'} eq '0000000000032' )
		{
		my $SeqName='tracking_integres_seq';
		$TrackingNumber = $self->BuildTracking($SeqName);
		}
	elsif ( $shipmentData->{'carrierid'} eq '0000000000033' )
		{
		}
	elsif ( $shipmentData->{'carrierid'} eq 'SEFL000000001' )
		{
		$TrackingNumber = $self->BuildTracking('tracking_sefl_seq');
		}
	elsif ( $shipmentData->{'carrierid'} eq 'WATKINS000001' )
		{
		$TrackingNumber = 'DLS' . $self->BuildTracking('tracking_watkins_seq');
		}
	elsif ( $shipmentData->{'carrierid'} eq 'OMNILOGISTICS' )
		{
		$TrackingNumber = $self->BuildTracking('tracking_omni_seq');
		}
	elsif ( $shipmentData->{'carrierid'} eq 'ASPEN00000001' )
		{
		$TrackingNumber = $self->BuildTracking('tracking_aspen_seq');
		}
	elsif ( $shipmentData->{'carrierid'} eq 'UPSSCS0000001' )
		{
		$TrackingNumber = $self->BuildUPSSCSTracking('tracking_upsscs_seq');
		}
	elsif ( $shipmentData->{'carrierid'} eq 'PITTOHIOEXPRS' )
		{
		$TrackingNumber = $self->BuildTracking('tracking_pittohio_seq');
		}
	elsif ( $shipmentData->{'carrierid'} eq 'AVERITTEXP001' )
		{
		$TrackingNumber = '122 ';

		if ( $self->{'customer'}->GetValueHashRef->{'customerid'} eq '8E3BZG21YNCVE' )
			{
			$TrackingNumber .= $self->BuildTracking('tracking_1pgl_averitt_seq');
			}
		elsif ( $self->{'customer'}->GetValueHashRef->{'customerid'} eq '8E3BZG5EFDB2H' )
			{
			$TrackingNumber .= $self->BuildTracking('tracking_2pgl_averitt_seq');
			}
		elsif ( $self->{'customer'}->GetValueHashRef->{'customerid'} eq '8E35DGQRW04C3' )
			{
			$TrackingNumber .= $self->BuildTracking('tracking_3pgl_averitt_seq');
			}
		else
			{
			$TrackingNumber = $self->BuildEngageTracking;
			}
		}
	elsif ( $shipmentData->{'carrierid'} eq 'DOHRN00000001' )
		{
		$TrackingNumber = $self->BuildTracking('tracking_dohrn_seq');
		}
	elsif ( $shipmentData->{'carrierid'} eq 'SMTL000000001' )
		{
		$TrackingNumber = '00' . $self->BuildTracking('tracking_smtl_seq') . '0';
		}
	elsif ( $shipmentData->{'serviceid'} eq 'OAKHARBOR0002' )
		{
		## visionship and garvey per pallet
		if ( $Customer eq '8ENTPLT6MAKSR' || $Customer eq '8ETB4XNGZB4KB' )
			{
			my $SeqName='tracking_oakharbor_vs_seq';
			$TrackingNumber = $self->BuildTracking($SeqName);
			}
		else
			{
			$TrackingNumber = $self->BuildEngageTracking;
			}
		}
	else
		{
		$TrackingNumber = $self->BuildEngageTracking;
		}

	return $TrackingNumber;
	}

sub BuildTracking
	{
	my $self = shift;
	my $Sequence = shift;

	return($self->model('MyTracking')->sequence_number($Sequence)); ## Change according to our convention
	}

sub BuildMod7Tracking
	{
	my $self = shift;
	my $Sequence = shift;

	my $TrackingNumber = $self->model('MyTracking')->sequence_number($Sequence);## Change according to our convention
	my $Checksum = $TrackingNumber % 7;

	$TrackingNumber = $TrackingNumber . $Checksum;

	return $TrackingNumber;
	}

sub Build9DigitTracking
	{
	my $self = shift;
	my $Sequence = shift;

	my $TrackingNumber = $self->model('MyTracking')->sequence_number($Sequence); ## Change according to our convention

	while ( $TrackingNumber !~ /\d{9}/ )
		{
		$TrackingNumber = '0' . $TrackingNumber;
		}

	return $TrackingNumber;
	}

sub BuildMod10Tracking
	{
	my $self = shift;
	my $Sequence = shift;

	my $TrackingNumber = $self->model('MyTracking')->sequence_number($Sequence);
	my $Checksum = check_digit($TrackingNumber);

	$TrackingNumber = $TrackingNumber . $Checksum;

	return $TrackingNumber;
	}

sub BuildMod11Tracking
	{
	my $self = shift;
	my $Sequence = shift;

	my $TrackingNumber = $self->model('MyTracking')->sequence_number($Sequence);
	$TrackingNumber = $TrackingNumber . $self->Mod11Checksum($TrackingNumber);

	return $TrackingNumber;
	}

sub BuildRoadwayTracking
	{
	my $self = shift;
	my $Sequence = shift;

	my $TrackingNumber = $self->model('MyTracking')->sequence_number($Sequence);
	my ($Prefix,$Base) = $TrackingNumber =~ /(\d{3})(\d{6})/;
	my $Checksum = $self->Mod11Checksum($Base);

	$TrackingNumber = "$Prefix-$Base-$Checksum";

	return $TrackingNumber;
	}

sub Mod11Checksum
	{
	my $self = shift;
	my $number =  shift;

	my $Remainder = $number % 11;

	my $Checksum;
	if ( $Remainder == 0 )
		{
		$Checksum = 0;
		}
	elsif ( $Remainder == 1 )
		{
		$Checksum = 'X';
		}
	else
		{
		$Checksum = 11 - $Remainder;
		}

	return $Checksum;
	}

sub BuildUPSSCSTracking
	{
	my $self = shift;
	my $Sequence = shift;

	my $TrackingNumber = $self->model('MyTracking')->sequence_number($Sequence);

	my $Remainder = $TrackingNumber % 11;

	my $Checksum;
	if ( $Remainder == 10 )
		{
		$Checksum = 'T';
		}
	else
		{
		$Checksum = $Remainder;
		}

	$TrackingNumber = $TrackingNumber . $Checksum;

	return $TrackingNumber;
	}

sub BuildEngageTracking
	{
	my $self = shift;

	my $shipmentData = $self->data;

	$self->CheckTrackingSequence($shipmentData->{'carrierid'});

	## Get sequence
	my $Sequence = $self->model('MyTracking')->sequence_number('generic_' . lc($shipmentData->{'carrierid'}) . '_seq');
	$Sequence = ('0' x (5 - length $Sequence)) . $Sequence;

	my $CarrierName= IntelliShip::Arrs::API->get_hashref('CARRIER',$shipmentData->{'carrierid'})->{'carriername'};

	my @words = split (/\s/,$CarrierName);
	my $count = 0;
	my ($char1,$char2,$char3);
	foreach my $word (@words)
		{
		$count++;
		## take the 1st and last char of the 1st word of carriername
		 if ( $count == 1 )
			{
			$char1 = substr($word,0,1);
			$char2 = substr($word,-1,1);
			}
		## take the 1st char of second word of carriername if exists
		elsif ( $count == 2 )
			{
			$char3 = substr($word,0,1);
			}
		}

	## Prepend 'V' for Vought, 'R' for remel, to avoid pro# collisions
	my $hostname = IntelliShip::MyConfig->getHostname;

	my $server_prefix = '';
	if ( $hostname =~ /atx01web04/i )
		{
		$server_prefix = 'V';
		}
	elsif ( $hostname =~ /rml/i )
		{
		$server_prefix = 'R';
		}

	my ($Year,$Month,$Day) = split(/\-/, IntelliShip::DateUtils->current_date('-'));

	my $from_state = $shipmentData->{'branchaddressstate'};
	my $to_state   =  $shipmentData->{'addressstate'};
	## Put it all together
	my $TrackingNumber = uc($server_prefix . $char1 . $char2 . $char3 . $from_state . $to_state . $Year . $Month . $Sequence);

	return $TrackingNumber;
	}

sub CheckTrackingSequence
	{
	my $self = shift;
	my $SeqID = shift;
	$SeqID = lc $SeqID;
	my $MyTracking = $self->model('MyTracking');
	my $STH = $MyTracking->select("SELECT relname FROM pg_statio_user_sequences WHERE relname = 'generic_${SeqID}_seq'");
	$MyTracking->dbh->do("CREATE SEQUENCE generic_${SeqID}_seq MINVALUE 1 MAXVALUE 99999") unless $STH->numrows;
	}

__PACKAGE__->meta()->make_immutable();

no Moose;

1;

__END__

UPSSCS0000001  :  UPS