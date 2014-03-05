package IntelliShip::Carrier::Driver::UPS::ShipOrder;

use Moose;
use Date::Manip;
use Data::Dumper;
use IntelliShip::Utils;
use IntelliShip::DateUtils;

BEGIN { extends 'IntelliShip::Carrier::Driver'; }

sub process_request
	{
	my $self = shift;

	my $CO = $self->CO;
	my $c = $self->context;
	my $Customer = $CO->customer;
	my $shipmentData = $self->data;

	if ($shipmentData->{'addresscountry'} eq 'USA')
		{
		$shipmentData->{'addresscountry'} = 'US';
		}

	if ($shipmentData->{'datetoship'})
		{
		$shipmentData->{'dateshipped'} = $shipmentData->{'datetoship'};
		}
    #
	#if (!defined($shipmentData->{'webaccount'}) or $shipmentData->{'webaccount'} eq '')
	#	{
	#	return (undef,'Missing Account Number');
	#	}
	#if (!defined($shipmentData->{'addresscity'}) or $shipmentData->{'addresscity'} eq '')
	#	{
	#	return (undef,'UPS Local: Unable To Ship Without A Destination City');
	#	}
	#if (!defined($shipmentData->{'addresszip'}) or $shipmentData->{'addresszip'} eq '')
	#	{
	#	return (undef,'UPS Local: Unable To Ship Without A Destination Zip Code');
	#	}
	#if (defined($shipmentData->{'insurance'}) and $shipmentData->{'insurance'} > 1000)
	#	{
	#	return (undef,'UPS Local: Unable To Ship With Declared Value Greater Than $1,000');
	#	}
	#if ($shipmentData->{'addresscountry'} eq 'US')
	#	{
	#	if ((!defined($shipmentData->{'address1'}) or $shipmentData->{'address1'} eq '') and (!defined($shipmentData->{'address2'}) or $shipmentData->{'address2'} eq ''))
	#		{
	#		return (undef,'UPS Local: Unable To Ship Without A Destination Address');
	#		}
	#	elsif (!defined($shipmentData->{'address1'}) or $shipmentData->{'address1'} eq '')
	#		{
	#		$shipmentData->{'address1'} = $shipmentData->{'address2'};
	#		}
	#	elsif ($shipmentData->{'address1'} eq '')
	#		{
	#		return (undef,'UPS Local: Unable To Ship Without A Destination Address');
	#		}
	#	elsif (defined($shipmentData->{'addresszip'}) and $shipmentData->{'addresszip'} !~ /\d{5}(\-\d{4})?/)
	#		{
	#		return (undef,'UPS Local: Invalid Destination Zip Code');
	#		}
	#	}

	my $ServiceCode = $self->service->{'servicecode'};
	if ($ServiceCode == '15')
		{
		if (   !$shipmentData->{'contactname'}
			or !$shipmentData->{'contactphone'}
			or !$shipmentData->{'oacontactname'}
			or !$shipmentData->{'oacontactphone'})
			{
			#return (undef,'UPS Local: Early A.M. Delivery Requires Contact Name & Number for Consignor and Consignee');
			}
		}

	# if (defined($shipmentData->{'dryice'}) and $shipmentData->{'dryice'} eq 'on' and (!defined($shipmentData->{'dryicewt'}) or $shipmentData->{'dryicewt'} eq ''))
		# {
		# return (undef,'UPS Local: Weight of Dry Ice Required for Shipments containing Dry Ice.');
		# }

	# # Push everything through DefaultTo...if undefined, set to ''
	# foreach my $key (keys(%$CgiRef))
		# {
		# $CgiRef->{$key} = DefaultTo($CgiRef->{$key}, '');
		# }

	my $numericaccount;
	if (defined($shipmentData->{'billingaccount'}) and $shipmentData->{'billingaccount'} ne '')
		{
		$shipmentData->{'billingaccount'} = uc($shipmentData->{'billingaccount'});
		$numericaccount = $self->convert_string($shipmentData->{'billingaccount'});
		}
	elsif (defined($shipmentData->{'webaccount'}) and $shipmentData->{'webaccount'} ne '')
		{
		$shipmentData->{'webaccount'} = uc($shipmentData->{'webaccount'});
		$numericaccount = $self->convert_string($shipmentData->{'webaccount'});
		}

	my $numericservice = $self->convert_string($ServiceCode);
	my $referencenumber = '99999';# $self->{'dbref'}->seqnumber('ups_refnum_seq');
	while (length($referencenumber) < 7)
		{
		$referencenumber = "0".$referencenumber;
		}

	my $checkvar = $numericaccount.$numericservice.$referencenumber;
	my ($o1,$e1,$o2,$e2,$o3,$e3,$o4,$e4,$o5,$e5,$o6,$e6,$o7,$e7,$o8) = split("",$checkvar);

	#Create check digit
	my $oddtotal = ($o1 + $o2 + $o3 + $o4 + $o5 + $o6 + $o7 + $o8);
	my $evens = ($e1 + $e2 + $e3 + $e4 + $e5 + $e6 + $e7);
	my $eventotal = $evens * 2;

	my $total = $oddtotal + $eventotal;
	my $a = $total + 9;
	my $b = $a/10;
	$b = int($b);
	my $next = $b * 10;

	my $check_digit = ($next - $total);
	if ($check_digit == 10){ $check_digit = 0; }

	unless ($shipmentData->{'tracking1'})
		{
		if (defined($shipmentData->{'billingaccount'}) and $shipmentData->{'billingaccount'} ne '')
			{
			$shipmentData->{'tracking1'} = "1Z".$shipmentData->{'billingaccount'}.$ServiceCode.$referencenumber.$check_digit;
			}
		elsif (defined($shipmentData->{'webaccount'}) and $shipmentData->{'webaccount'} ne '')
			{
			$shipmentData->{'tracking1'} = "1Z".$shipmentData->{'webaccount'}.$ServiceCode.$referencenumber.$check_digit;
			}
		}
	else
		{
		# this is a manually entered trackingnumber
		$shipmentData->{'manualtrackingflag'} = 1;

		# validate it's length
		if (length($shipmentData->{'tracking1'}) != 11 and length($shipmentData->{'tracking1'}) != 18)
			{
			return (undef,"Invalid UPS Tracking Number (" . $shipmentData->{'tracking1'} . ")");
			}

		# validate the checksum on the manually entered trakcing number
		if (length($shipmentData->{'tracking1'}) == 18 and !$self->validate_check_digit($shipmentData->{'tracking1'}))
			{
			return (undef,"Tracking Number Failed Check Digit Validation (" . $shipmentData->{'tracking1'} . ")");
			}
		}

	if ( $shipmentData->{'totalquantity'} >= $shipmentData->{'quantity'} )
		{
		$shipmentData->{'currentpiece'} = $shipmentData->{'totalquantity'} - $shipmentData->{'quantity'};

		if ( $shipmentData->{'quantity'} > 0 )
			{
			$shipmentData->{'currentpiece'} ++;
			}
		}

	# calculate shipment number.  presumably only needed for international but calcing for all
	# a multi piece shipment uses a single shipment number
	if ( $shipmentData->{'currentpiece'} == 1 )
		{
		$shipmentData->{'shipmentnumber'} = $self->CalculateShipmentNumber($shipmentData->{'tracking1'});
		}

	$shipmentData->{'weight'} = $shipmentData->{'enteredweight'};

	$self->insert_shipment($shipmentData);

	my $PrinterString = $self->BuildPrinterString($shipmentData);
	$self->response->printer_string($PrinterString);
	}

sub CalculateShipmentNumber
	{
	my $self = shift;
	my $trackingnumber = shift;

	my $base = substr($trackingnumber,10,7);
	my $acct_split1 = substr($trackingnumber,2,4);
	my $acct_split2 = substr($trackingnumber,6,2);

	$self->log("Base: $base\tAcct Num: $acct_split1 $acct_split2");

	my $calc1 = floor($base / 26**4);
	my $calc2 = ($base - (9 * 26**4)) / 26**3;
	$calc2 = floor($calc2);
	my $calc3 = ($base - (9 * 26**4) - (16 * 26**3)) / 26**2;
	$calc3 = floor($calc3);
	my $calc4 = ($base - (9 * 26**4) - (16 * 26**3) - (8 * 26**2)) / 26;
	$calc4 = floor($calc4);
	my $calc5 = $base - (9 * 26**4) - (16 * 26**3) - (8 * 26**2) - (22*26);
	$calc5 = floor($calc5);

	$self->log("calcs|$calc1|$calc2|$calc3|$calc4|$calc5|");

	my $value1 = $self->ConvertForBase26($calc1);
	my $value2 = $self->ConvertForBase26($calc2);
	my $value3 = $self->ConvertForBase26($calc3);
	my $value4 = $self->ConvertForBase26($calc4);
	my $value5 = $self->ConvertForBase26($calc5);

	return $acct_split1 . " " . $acct_split2 . $value1 . $value2 . " " . $value3 . $value4 . $value5;
	}

sub ConvertForBase26
	{
	my $self = shift;
	my $number = shift;

	my %Convert = (
		'0', '3',
		'1', '4',
		'2', '7',
		'3', '8',
		'4', '9',
		'5', 'B',
		'6', 'C',
		'7', 'D',
		'8', 'F',
		'9', 'G',
		'10', 'H',
		'11', 'J',
		'12', 'K',
		'13', 'L',
		'14', 'M',
		'15', 'N',
		'16', 'P',
		'17', 'Q',
		'18', 'R',
		'19', 'S',
		'20', 'T',
		'21', 'V',
		'22', 'W',
		'23', 'X',
		'24', 'Y',
		'25', 'Z',
		);

	my $converted_number = $Convert{$number};

	return $converted_number;
	}

sub convert_string
	{
	my $self = shift;
	my $string = shift;
	my $converted;

	my %Convert = (
			'A', '2',
			'B', '3',
			'C', '4',
			'D', '5',
			'E', '6',
			'F', '7',
			'G', '8',
			'H', '9',
			'I', '0',
			'J', '1',
			'K', '2',
			'L', '3',
			'M', '4',
			'N', '5',
			'O', '6',
			'P', '7',
			'Q', '8',
			'R', '9',
			'S', '0',
			'T', '1',
			'U', '2',
			'V', '3',
			'W', '4',
			'X', '5',
			'Y', '6',
			'Z', '7',
			'0', '0',
			'1', '1',
			'2', '2',
			'3', '3',
			'4', '4',
			'5', '5',
			'6', '6',
			'7', '7',
			'8', '8',
			'9', '9',
		);

	my @chars = split (//,$string);
	foreach my $char (@chars)
		{
		$converted .= $Convert{$char};
		}
	return $converted;
	}

sub validate_check_digit
	{
	my $self = shift;
	my $trackingnumber = shift;

	my $Account = substr($trackingnumber,2,6);
	my $ServiceCode = substr($trackingnumber,8,2);
	my $Sequence = substr($trackingnumber,10,7);
	my $CheckDigit = substr($trackingnumber,17,1);

	my $numericaccount = $self->convert_string($Account);
	my $numericservice = $self->convert_string($ServiceCode);

	my $checkvar = $numericaccount.$numericservice.$Sequence;
	my ($o1,$e1,$o2,$e2,$o3,$e3,$o4,$e4,$o5,$e5,$o6,$e6,$o7,$e7,$o8) = split("",$checkvar);

	#Create check digit
	my $oddtotal = ($o1 + $o2 + $o3 + $o4 + $o5 + $o6 + $o7 + $o8);
	my $evens = ($e1 + $e2 + $e3 + $e4 + $e5 + $e6 + $e7);
	my $eventotal = $evens * 2;

	my $total = $oddtotal + $eventotal;
	my $a = $total + 9;
	my $b = $a/10;
	$b = int($b);
	my $next = $b * 10;

	my $check_digit = ($next - $total);
	if ($check_digit == 10){ $check_digit = 0; }

	return 1 if ($check_digit == $CheckDigit);
	return 0;
	}

sub BuildPrinterString
	{
	my $self = shift;
	my $CgiRef = shift;

	$CgiRef->{'maxicity'} = $CgiRef->{'addresscity'};
	$CgiRef->{'maxiaddress'} = $CgiRef->{'address1'};
	if ($CgiRef->{'address2'})
		{
		$CgiRef->{'maxiaddress'} .= " ".$CgiRef->{'address2'};
		}
	$CgiRef->{'maxiaddress'} = substr($CgiRef->{'maxiaddress'},0,35);

	# Prepare information for the postal code bar code
	my $barcodezip = $CgiRef->{'addresszip'};
	$barcodezip =~ s/-//g;
	$barcodezip =~ s/ //g;
	if ( ($CgiRef->{'branchaddresscountry'} eq 'US' || $CgiRef->{'branchaddresscountry'} eq '' )
			&& ( $CgiRef->{'addresscountry'} eq 'US' || $CgiRef->{'addresscountry'} eq '' ) )
		{
		$CgiRef->{'barcodezip'} = "420";
		}
	else
		{
		$CgiRef->{'barcodezip'} = "421";
		}
	$CgiRef->{'barcodezip'} .= $barcodezip;

	# Prepare information for maxicode
	my $barcodezip5 = substr($barcodezip,0,5);
	my $barcodezip4 = substr($barcodezip,5,4);
	if (!defined($barcodezip4) || length($barcodezip4) < 4)
		{
		$barcodezip4 = '0000';
		}

	$CgiRef->{'maxicode_zip5'} = $barcodezip5;
	$CgiRef->{'maxicode_zip4'} = $barcodezip4;

	my $maxicode_tracking1 = substr($CgiRef->{'tracking1'},10,8);
	$CgiRef->{'maxicode_tracking1'} = "1Z".$maxicode_tracking1;
	my $day   = substr($CgiRef->{'maxi_dateshipped'},3,2);
	my $month = substr($CgiRef->{'maxi_dateshipped'},0,2);
	my $year  = substr ($CgiRef->{'maxi_dateshipped'},6,4);

	&Date_Init();

	my $secs = Date_SecsSince1970($month,$day,$year,10,00,00);

	$CgiRef->{'julianpickup'} = $self->julianDate($secs);
	#pad julianpickup day to 3 chars
	$CgiRef->{'julianpickup'} = "0". $CgiRef->{'julianpickup'} if $CgiRef->{'julianpickup'} <= 99;

	($CgiRef->{'shipdate'},$CgiRef->{'maxi_dateshipped'}) = $self->FormatShipDate;

	##################################################################
	## Build EPL
	##################################################################
	my @service_lines = ();
	my $serviceicon = $CgiRef->{'serviceicon'};
	if ($CgiRef->{'serviceicon'} eq '  ')
		{
		push (@service_lines, "A645,630,0,4,3,4,R,\"$serviceicon\"");
		}
	else
		{
		push (@service_lines, "A645,630,0,4,3,4,N,\"$serviceicon\"");
		}

	if ( defined($CgiRef->{'intldoc'}) && $CgiRef->{'intldoc'} ne '' )
		{
		push(@service_lines,"A670,1025,0,3,2,2,N,\"$CgiRef->{'intldoc'}\"");
		}
	else
		{
		push(@service_lines,"A670,1025,0,3,2,2,,INV");
		push(@service_lines,"A670,1050,0,2,1,1,N,POA");
		}

	push (@service_lines,"P1\nR0,0\n.");

	if ( $CgiRef->{'enteredweight'} == 0 )
		{
		$CgiRef->{'displayweight'} = "LTR";
		$CgiRef->{'maxi_weight'} = 1;
		$CgiRef->{'intldoc'} = "EDI-DOC";
		}
	else
		{
		$CgiRef->{'displayweight'} = $CgiRef->{'enteredweight'}. "  LBS";
		$CgiRef->{'maxi_weight'} = $CgiRef->{'enteredweight'};
		}

	my $raw_string = $self->get_EPL($CgiRef);

	my @string_lines = split("\n",$raw_string);

	push (@string_lines,@service_lines);

	#if ($CgiRef->{'stream'})
	#	{
	#	my $stream = $CgiRef->{'stream'};
    #
	#	$stream = $DISPLAY->TranslateString($stream,$CgiRef);
	#	push(@string_lines,split(/\~/,$stream));
	#	}

	my $printer_string = '';
	foreach my $line (@string_lines)
		{
		$printer_string .= "$line\n";
		}

	$self->log($printer_string);
	return $printer_string;
	}

sub FormatShipDate
	{
	my $self = shift;
	my $shipmentid = $self->response->shipment->shipmentid if $self->response->shipment;

	return unless $shipmentid;

	my $SQL = "
		SELECT
			to_char(dateshipped,'DD MON YYYY') as label_dateshipped,
			to_char(dateshipped,'MM/DD/YYYY') as maxi_dateshipped
		FROM
			shipment
		WHERE
			shipmentid = '$shipmentid'
		";

	my $STH = $self->myDBI->select($SQL);
	my $DATA = $STH->fetchrow(0);
	my ($label_dateshipped,$maxi_dateshipped) = ($DATA->{label_dateshipped},$DATA->{maxi_dateshipped});

	return ($label_dateshipped,$maxi_dateshipped);
	}

#************************************************************************
#****   Pass in the date, in seconds, of the day you want the       *****
#****   julian date for.  If your localtime() returns the year day  *****
#****   return that, otherwise figure out the julian date.          *****
#************************************************************************

sub julianDate
	{
	my $self = shift;
	my $dateInSeconds = shift;

	my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday);
	my @theJulianDate = ( 0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334 );

	($sec, $min, $hour, $mday, $mon, $year, $wday, $yday) = localtime($dateInSeconds);
	if ($yday)
		{
		return ($yday+1);
		}
	else
		{
		return ($theJulianDate[$mon] + $mday + $self->leapDay($year,$mon,$mday));
		}
	}

#************************************************************************
#****   Return 1 if we are after the leap day in a leap year.       *****
#************************************************************************

sub leapDay
	{
	my $self = shift;
	my $year = shift;
	my $month = shift;
	my $day = shift;

	return 0 if $year % 4;

	if (!($year % 100))
		{
		# years that are multiples of 100
		# are not leap years
		return 0 if $year % 400;
		}
	if ($month < 2)
		{
		return 0;
		}
	elsif ($month == 2 && $day < 29)
		{
		return 0;
		}
	else
		{
		return 1;
		}
	}

__PACKAGE__->meta()->make_immutable();

no Moose;

1;

__END__