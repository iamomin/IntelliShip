package IntelliShip::Carrier::Driver::Generic::ShipOrder;

use Moose;
use POSIX;
use Date::Manip;
use Data::Dumper;
use IntelliShip::Utils;
use Sys::Hostname;
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

	# Push everything through DefaultTo...if undefined, set to ''
	#foreach my $key (keys(%$shipmentData))
	#{
	#	$shipmentData->{$key} = DefaultTo($shipmentData->{$key}, '');
	#}

	if ( !$shipmentData->{'tracking1'} )
	{
	$shipmentData->{'tracking1'} = $self->GetCarrierTrackingNumber;
	}
	else
	{
	$shipmentData->{'manualtrackingflag'} = 1;
	}

	$self->log("___ TRACKING1: " . $shipmentData->{'tracking1'});

	my $weight = $CO->total_weight;
	if ( !$weight && $CO->estimatedweight )
		{
		$weight = $CO->estimatedweight;
		}
	$shipmentData->{'weight'} = $weight ? $weight : $shipmentData->{'enteredweight'};

	$shipmentData->{'weight'} = $shipmentData->{'enteredweight'};
	if ($shipmentData->{'datetoship'})
		{
		$shipmentData->{'dateshipped'} = $shipmentData->{'datetoship'};
		}

	my $Shipment = $self->insert_shipment($shipmentData);

	# Note user supplied tracking numbers
	if ( defined($shipmentData->{'manualtrackingflag'}) && $shipmentData->{'manualtrackingflag'} == 1 )
	{
		# Add note to notes table
		my $Notes = new NOTES($self->{'dbref'},$self->{'customer'});
		my $noteData = {};

		#my $ContactName = $Contact->username;

		$noteData->{'ownerid'} = $Shipment->shipmentid;
		$noteData->{'note'} = $shipmentData->{'tracking1'} . ' Input By ' . $Contact->username;
		$noteData->{'contactid'} = $Contact;
		$noteData->{'notestypeid'} = 1300;
		$noteData->{'datehappened'} = $self->{'dbref'}->gettimestamp();
		my $Note = IntelliShip::DateUtils->get_timestamp_with_time_zone();
		$Note->insert;
	}

	my $PrinterString = $self->BuildPrinterString($shipmentData);
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
	#elsif ( $shipmentData->{'carrierid'} eq '0000000000011' )
	#{
	#	if ( $CustomerID eq '8DD167GSXZEZ3' )
	#		{
	#		my $SeqName='tracking_yellow_rwv_seq';
	#		$TrackingNumber = $self->BuildMod11Tracking($SeqName);
	#		}
	#		else
	#		{
	#		my $SeqName='tracking_yellow_seq';
	#		$TrackingNumber = $self->Build9DigitTracking($SeqName);
	#		}
	#	}
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
		$TrackingNumber = $self->{'tracking_dbref'}->seqnumber($SeqName) . $self->{'tracking_dbref'}->seqnumber($CheckSeqName);
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
		# visionship and garvey per pallet
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
=b
		elsif
		(
			$shipmentData->{'carrierid'} eq 'YELLOWSTONE01' || $shipmentData->{'carrierid'} eq 'SOUTHERNPRIDE' || $shipmentData->{'carrierid'} eq 'TRIPLEA000001' ||
			$shipmentData->{'carrierid'} eq 'TECHTRANSPORT' || $shipmentData->{'carrierid'} eq 'CELADON000001' || $shipmentData->{'carrierid'} eq 'ARROWTRUCKING' ||
			$shipmentData->{'carrierid'} eq 'SWIFTRANS0001' || $shipmentData->{'carrierid'} eq 'MELTON0000001' || $shipmentData->{'carrierid'} eq 'MEGATRUX00001' ||
			$shipmentData->{'carrierid'} eq 'ECLIPSE000001' || $shipmentData->{'carrierid'} eq 'SBA0000000001' || $shipmentData->{'carrierid'} eq 'UNIONPACIFIC1' ||
			$shipmentData->{'carrierid'} eq 'BNSF000000001' || $shipmentData->{'carrierid'} eq 'VOUGHT0000001' || $shipmentData->{'carrierid'} eq 'DANIELCOMPANY' ||
			$shipmentData->{'carrierid'} eq 'SONKERTRUCKIN' || $shipmentData->{'carrierid'} eq '0000000000010' || $shipmentData->{'carrierid'} eq '0000000000012' ||
			$shipmentData->{'carrierid'} eq '0000000000016' || $shipmentData->{'carrierid'} eq '0000000000020' || $shipmentData->{'carrierid'} eq '0000000000024' ||
			$shipmentData->{'carrierid'} eq '0000000000027' || $shipmentData->{'carrierid'} eq '0000000000028' || $shipmentData->{'carrierid'} eq '0000000000029' ||
			$shipmentData->{'carrierid'} eq '0000000000030' || $shipmentData->{'carrierid'} eq '0000000000034' || $shipmentData->{'carrierid'} eq '0000000000035' ||
			$shipmentData->{'carrierid'} eq '0000000000036' || $shipmentData->{'carrierid'} eq '0000000000037' || $shipmentData->{'carrierid'} eq '0000000000038' ||
			$shipmentData->{'carrierid'} eq '0000000000039' || $shipmentData->{'carrierid'} eq '0000000000040' || $shipmentData->{'carrierid'} eq '0000000000041' ||
			$shipmentData->{'carrierid'} eq '0000000000043' || $shipmentData->{'carrierid'} eq '0000000000044' || $shipmentData->{'carrierid'} eq '0000000000045' ||
			$shipmentData->{'carrierid'} eq '0000000000046' || $shipmentData->{'carrierid'} eq 'AMTREX0000001' || $shipmentData->{'carrierid'} eq 'WRDS000000001' ||
			$shipmentData->{'carrierid'} eq 'DFL0000000001' || $shipmentData->{'carrierid'} eq 'ADP0000000001' || $shipmentData->{'carrierid'} eq 'SEI0000000001' ||
			$shipmentData->{'carrierid'} eq 'TOWNEAIRFRT01' || $shipmentData->{'carrierid'} eq 'GANDHXPRESS01' || $shipmentData->{'carrierid'} eq 'NTC0000000001' ||
			$shipmentData->{'carrierid'} eq 'OHF0000000001' || $shipmentData->{'carrierid'} eq 'SUNBELTEXPRES' || $shipmentData->{'carrierid'} eq 'AVIATIONEXPRS' ||
			$shipmentData->{'carrierid'} eq 'BESTWAY000001' || $shipmentData->{'carrierid'} eq 'MILLER0000001' || $shipmentData->{'carrierid'} eq 'VOUGHT0000002' ||
			$shipmentData->{'carrierid'} eq 'VOUGHT0000003' || $shipmentData->{'carrierid'} eq 'FFE0000000001' || $shipmentData->{'carrierid'} eq 'NYK0000000001' ||
			$shipmentData->{'carrierid'} eq 'DHE0000000001' || $shipmentData->{'carrierid'} eq 'QTRANS0000001' || $shipmentData->{'carrierid'} eq 'TRACE00000001' ||
			$shipmentData->{'carrierid'} eq 'HWFARREN00001' || $shipmentData->{'carrierid'} eq 'ABFFREIGHT001' || $shipmentData->{'carrierid'} eq 'ABFFREIGHT001' ||
			$shipmentData->{'carrierid'} eq 'JETENGINE0001' || $shipmentData->{'carrierid'} eq 'HOLMES0000001' || $shipmentData->{'carrierid'} eq 'COMBINED00001' ||
			$shipmentData->{'carrierid'} eq 'SMOKEYPOINT01' || $shipmentData->{'carrierid'} eq 'DAILYEXPRESS1' || $shipmentData->{'carrierid'} eq 'ESTESEXPRESS1' ||
			$shipmentData->{'carrierid'} eq 'UPSG000000001' || $shipmentData->{'carrierid'} eq 'OLDDOMINION01' || $shipmentData->{'carrierid'} eq 'SEKO000000001' ||
			$shipmentData->{'carrierid'} eq 'CROSSROADS001' || $shipmentData->{'carrierid'} eq 'ZILLY00000001' || $shipmentData->{'carrierid'} eq 'PROTRANSPORT1' ||
			$shipmentData->{'carrierid'} eq 'HEAVYSPEC0001' || $shipmentData->{'carrierid'} eq 'BOATMAN000001' || $shipmentData->{'carrierid'} eq 'RTJSPECIAL001' ||
			$shipmentData->{'carrierid'} eq 'CONTRANSLOGIS' || $shipmentData->{'carrierid'} eq 'STEVENSGL0001' || $shipmentData->{'carrierid'} eq 'BOBBRINKS0001' ||
			$shipmentData->{'carrierid'} eq 'ARTISAN000001' || $shipmentData->{'carrierid'} eq 'XCELLERATED01' || $shipmentData->{'carrierid'} eq 'DALLASMAVIS01' ||
			$shipmentData->{'carrierid'} eq 'TQTRANSPORT01' || $shipmentData->{'carrierid'} eq 'HOLMESJACKON1' || $shipmentData->{'carrierid'} eq 'TENNSTEELHAUL' ||
			$shipmentData->{'carrierid'} eq 'DDITRANSPORT1' || $shipmentData->{'carrierid'} eq 'FLECRAILROAD1' || $shipmentData->{'carrierid'} eq 'DDSTRUCKING01' ||
			$shipmentData->{'carrierid'} eq 'LANDSTAREXPS1' || $shipmentData->{'carrierid'} eq 'SOCALTRANSPRT' || $shipmentData->{'carrierid'} eq 'ALEXANDER0001' ||
			$shipmentData->{'carrierid'} eq 'SCHENKER00001' || $shipmentData->{'carrierid'} eq 'EXPEDITORS001' || $shipmentData->{'carrierid'} eq 'QUALITYEXPRES' ||
			$shipmentData->{'carrierid'} eq 'WARDTRUCKING1' || $shipmentData->{'carrierid'} eq 'IMAGINELOG001' || $shipmentData->{'carrierid'} eq 'BEARTRANSP001' ||
			$shipmentData->{'carrierid'} eq 'ACIMOTORCAR01' || $shipmentData->{'carrierid'} eq 'DUGANTRUCKLN1' || $shipmentData->{'carrierid'} eq 'AMTREXTL00001' ||
			$shipmentData->{'carrierid'} eq 'LME0000000001' || $shipmentData->{'carrierid'} eq 'QSC00000OTHER' || $shipmentData->{'carrierid'} eq 'DAYLIGHTTRANS' ||
			$shipmentData->{'carrierid'} eq 'CARGOBROKERS1' || $shipmentData->{'carrierid'} eq 'DART000000001' || $shipmentData->{'carrierid'} eq 'CORTRANS00001' ||
			$shipmentData->{'carrierid'} eq 'LONESTAR00001' || $shipmentData->{'carrierid'} eq 'NETWORKCOUR01' || $shipmentData->{'carrierid'} eq 'SAIA000000001' ||
			$shipmentData->{'carrierid'} eq 'DUGAN00000001' || $shipmentData->{'carrierid'} eq 'YELLOWEXACT01' || $shipmentData->{'carrierid'} eq 'MIDSTATES0001' ||
			$shipmentData->{'carrierid'} eq 'RANDL00000001' || $shipmentData->{'carrierid'} eq 'ACIMOTORFRT01' || $shipmentData->{'carrierid'} eq 'ATC0000000001' ||
			$shipmentData->{'carrierid'} eq 'CRST000000001' || $shipmentData->{'carrierid'} eq 'SMTL000000001' || $shipmentData->{'carrierid'} eq 'CUSTCOM000001' ||
			$shipmentData->{'carrierid'} eq 'USPS000000001' || $shipmentData->{'carrierid'} eq 'AFSDEMOCARTLB' || $shipmentData->{'carrierid'} eq 'AFSDEMOCALTLB' ||
			$shipmentData->{'carrierid'} eq 'AFSDEMOCARTLA' || $shipmentData->{'carrierid'} eq 'AFSDEMOCALTLA' || $shipmentData->{'carrierid'} eq 'AFSDEMOCALTLC' ||
			$shipmentData->{'carrierid'} eq 'VISIONSHIP001'
		)
		{
			$TrackingNumber = $self->BuildEngageTracking($FromState,$ToState,$shipmentData->{'carrierid'});
		}
=cut

	return $TrackingNumber;
	}

sub BuildTracking
	{
	my $self = shift;
	my $Sequence = shift;

	return($self->DBI('tracking')->seqnumber($Sequence)); ## Change according to our convention
	}

sub BuildMod7Tracking
	{
	my $self = shift;
	my $Sequence = shift;

	my $TrackingNumber = $self->DBI('tracking')->seqnumber($Sequence);## Change according to our convention
	my $Checksum = $TrackingNumber % 7;

	$TrackingNumber = $TrackingNumber . $Checksum;

	return $TrackingNumber;
	}


sub Build9DigitTracking
	{
	my $self = shift;
	my $Sequence = shift;

	my $TrackingNumber =$self->DBI('tracking')->seqnumber($Sequence); ## Change according to our convention

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

	my $TrackingNumber = $self->DBI('tracking')->seqnumber($Sequence);
	my $Checksum = check_digit($TrackingNumber);

	$TrackingNumber = $TrackingNumber . $Checksum;

	return $TrackingNumber;
	}

sub BuildMod11Tracking
	{
	my $self = shift;
	my $Sequence = shift;

	my $TrackingNumber = $self->DBI('tracking')->seqnumber($Sequence);
	$TrackingNumber = $TrackingNumber . $self->Mod11Checksum($TrackingNumber);

	return $TrackingNumber;
	}

sub BuildRoadwayTracking
	{
	my $self = shift;
	my $Sequence = shift;

	my $TrackingNumber = $self->DBI('tracking')->seqnumber($Sequence);
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

	my $TrackingNumber = $self->{'tracking_dbref'}->seqnumber($Sequence);

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
	# Changes Are To be done...
	my $self = shift;
	my $shipmentData = $self->data;
	my $CO = $self->CO;
	my $Contact = $CO->contact;

	if ( !$self->CheckTrackingSeq(lc( $shipmentData->{'carrierid'})) )
		{
		$self->CreateTrackingSeq(lc($shipmentData->{'carrierid'}))
		}

	# Get sequence
	my $Sequence = $self->model('MyTracking')->sequence_number('generic_' . lc($shipmentData->{'carrierid'}) . '_seq');
	while ( length($Sequence) < 5 ) { $Sequence = '0' . $Sequence }

	# Parse out month (2 digit) and year (last digit)
	my ($Month,$Year) = (localtime)[4,5];

	$Month++;
	$Month = $Month =~ /\d{2}/ ? $Month : '0' . $Month;

	$Year += 1900;
	$Year =~ s/\d{3}(\d)/$1/;

	#my $CarrierName = &APIRequest({action=>'GetValueHashRef',module=>'CARRIER',moduleid=>$shipmentData->{'carrierid'} ,field=>'carriername'})->{'carriername'};

	my $CarrierName= IntelliShip::Arrs::API->get_hashref('CARRIER',$shipmentData->{'carrierid'})->{'carriername'};

	my @words = split (/\s/,$CarrierName);
	my $count = 0;
	my ($char1,$char2,$char3);
	foreach my $word (@words)
		{
		$count++;
		# take the 1st and last char of the 1st word of carriername
		 if ( $count == 1 )
			{
			$char1 = substr($word,0,1);
			$char2 = substr($word,-1,1);
			}
		# take the 1st char of second word of carriername if exists
		elsif ( $count == 2 )
			{
			$char3 = substr($word,0,1);
			}
		}

		# Prepend 'V' for Vought, 'R' for remel, to avoid pro# collisions
		my $hostname = hostname();

	my $server_prefix = '';
	if ( $hostname eq 'atx01web04' )
		{
		$server_prefix = 'V';
		}
	elsif ( $hostname =~ /rml/ )
		{
		$server_prefix = 'R';
		}

	# Put it all together
	my $TrackingNumber = $server_prefix . uc($char1) . uc($char2) . uc($char3) . $shipmentData->{'branchaddressstate'} . $shipmentData->{'addressstate'} . $Year . $Month . $Sequence;

	return $TrackingNumber;
	}

sub CheckTrackingSeq
	{
	my $self = shift;
	my $SeqID = shift;
	#Get list of generic tracking sequence names
	my $STH = $self->model('MyTracking')->select("SELECT relname FROM pg_statio_user_sequences ORDER BY relname");
	return $STH->numrows;
	}

sub CreateTrackingSeq
	{
	my $self = shift;
	my $SeqID = shift;

	$self->model('MyTracking')->dbh->do("CREATE SEQUENCE generic_${SeqID}_seq MINVALUE 1 MAXVALUE 99999");
	}


__PACKAGE__->meta()->make_immutable();

no Moose;

1;

__END__

