package IntelliShip::Carrier::Driver::FedEx::ShipOrder;

use Moose;
use Data::Dumper;
use IntelliShip::Utils;


BEGIN { extends 'IntelliShip::Carrier::Shipment::Driver'; }

sub process_request
	{
	my $self = shift;

	###############################
	# The incoming variables
	###############################
	$CgiRef->{'carrier'} = 'Fedex';
	$CgiRef = TrimHashRefValues($CgiRef);

	if ($CgiRef->{'addresscountry'} eq 'USA')
	{
		$CgiRef->{'addresscountry'} = 'US';
	}

	$CgiRef->{'commodityweight'} = $CgiRef->{'enteredweight'};

	# Hardwire in a shipdate (= current date) so that all demos and such will work properly
	my $ShipDate = $self->GetWebShipDate($CgiRef->{'datetoship'});
	$CgiRef->{'dateshipped'} = $CgiRef->{'datetoship'};

	if ( $CgiRef->{'enteredweight'} !~ /\.\d+/ ) { $CgiRef->{'enteredweight'} .= ".0"; }

	my $insurance;
	if ( defined($CgiRef->{'insurance'}) && $CgiRef->{'insurance'} =~ /\./ )
	{
		# search/replace simultaneously.
		($insurance = $CgiRef->{'insurance'}) =~ s/\.//;
	}

	$CgiRef->{'oacontactphone'} =~ s/-//g;

	# Attempt to distill Remel's various phone formats into something fedex will take
	my $ContactPhone = $CgiRef->{'contactphone'};
	$ContactPhone =~ s/-//g;
	$ContactPhone =~ s/\s+//g;
	$ContactPhone =~ s/\(//g;
	$ContactPhone =~ s/\)//g;

	if ( $CgiRef->{'addresscountry'} eq 'US' || $CgiRef->{'addresscountry'} eq 'CA' )
	{
		($ContactPhone) = $ContactPhone =~ /^(\d{10})/;
	}

	# Allow for LTR type packages (0 weight)
	my $PackageType = "01";
	if ($CgiRef->{'enteredweight'} == 0)
	{
		$PackageType = "06";
		$CgiRef->{'enteredweight'} = "1.0";
		$CgiRef->{'commodityweight'} = "1.0";
	}

	# Hardwire 'Total Customs Value' to be the same as 'Commodity Customs Value'
	my $commoditycustomsvalue;
	if ( $CgiRef->{'commoditycustomsvalue'} )
	{
		if ( $CgiRef->{'commoditycustomsvalue'} =~ /\./ )
		{
			# search/replace simultaneously.
			($commoditycustomsvalue = $CgiRef->{'commoditycustomsvalue'}) =~ s/\.//;
		}
		elsif ( $CgiRef->{'commoditycustomsvalue'} !~ /\./ )
		{
			$commoditycustomsvalue = $CgiRef->{'commoditycustomsvalue'} . '00';
		}
	}
#warn "cgi=$CgiRef->{'commoditycustomsvalue'} ccv=$commoditycustomsvalue";
	# Hardwire 'Unit Quantity' to 'Commodity Number of Pieces'
	$CgiRef->{'unitquantity'} = $CgiRef->{'commodityquantity'};

	# 3rd Party Billing
	my $AccountNumber = "";
	my $BillingType = "";

	if ( defined($CgiRef->{'billingaccount'}) && $CgiRef->{'billingaccount'} ne '' )
	{
		$AccountNumber = $CgiRef->{'billingaccount'};
		$BillingType = 3;
	}
	else
	{
		$AccountNumber = $CgiRef->{'webaccount'};
		$BillingType = 1;
	}

	$AccountNumber =~ s/[-| ]//g;
#warn $CgiRef->{'webaccount'} . " " . $CgiRef->{'meternumber'};
	# Pop reference field with 'Order# - Customer#'
	$CgiRef->{'refnumber'} = $CgiRef->{'ordernumber'};
	if ( defined($CgiRef->{'ponumber'}) && $CgiRef->{'ponumber'} ne '' )
  {
     $CgiRef->{'refnumber'} .= " - $CgiRef->{'ponumber'}";
  }
	elsif ( defined($CgiRef->{'custnum'}) && $CgiRef->{'custnum'} ne '' )
	{
		$CgiRef->{'refnumber'} .= " - $CgiRef->{'custnum'}";
	}

	# Strip non-numeric from ssnein field
	if ( defined($CgiRef->{'ssnein'}) && $CgiRef->{'ssnein'} ne '' )
	{
		$CgiRef->{'ssnein'} =~ s/\D//g;
	}

	# Strip non alpha-numeric from harmonized code field
	if ( defined($CgiRef->{'harmonizedcode'}) && $CgiRef->{'harmonizedcode'} ne '' )
	{
		$CgiRef->{'harmonizedcode'} =~ s/[^a-zA-Z0-9]//g;
	}

	# Hash with data to build up shipping string that we'll transmit to FedEx
	local $^W = 0;

	my %ShipData = (
		# Generic
		4		=>	"$CgiRef->{'customername'}", 	#Sender company
		5		=>	"$CgiRef->{'branchaddress1'}",	#Sender Addr1
		6		=> "$CgiRef->{'branchaddress2'}",	#Sender Addr2 -> but only if pop'd.  Probly pull from ref.
		7		=> "$CgiRef->{'branchaddresscity'}",	#Sender City
		8		=>	"$CgiRef->{'branchaddressstate'}",	#Sender State
		9		=>	"$CgiRef->{'branchaddresszip'}",	#Sender Postal Code
		11		=>	"$CgiRef->{'addressname'}",	#Recipient Company
		12		=>	"$CgiRef->{'contactname'}",	#Recipient contactname
		13		=>	"$CgiRef->{'address1'}",	#Recipient Addr1
		14		=>	"$CgiRef->{'address2'}",	#Recipient Addr2
		15		=>	"$CgiRef->{'addresscity'}",	#Recipient City
		16		=>	"$CgiRef->{'addressstate'}",	#Recipient State
		17		=>	"$CgiRef->{'addresszip'}",	#Recipient Postal Code
		18		=>	"$ContactPhone",	#Recipient Phone Number
		20		=> "$AccountNumber", #Payer Account Number
		23		=>	"$BillingType",	#Pay Type
		25		=>	"$CgiRef->{'refnumber'}",	#Reference Number
		117	=>	"US",	#Sender Country Code
		183	=>	"$CgiRef->{'oacontactphone'}",	#Sender Phone Number
		498	=>	"$CgiRef->{'meternumber'}",	#Required - Meter #
		1119	=>	"Y",
		24		=> "$ShipDate", # Ship date
		1273	=>	"$PackageType",	#FedEx Packaging Type
		1274	=>	"$CgiRef->{'webname'}",	#FedEx Service Type

	# New printer stuff
		187	=>	"299",
		);

		# fedex says this has to do with hazardous - 20121112
		#if ( $CgiRef->{'international'} )
		#{
		#	$ShipData{'1391'} = "2";	#Client Revision Indicator
		#}
		$ShipData{'1670'} = ceil($CgiRef->{'enteredweight'} * 100);	#Total Package Weight this field has 2 implied decimals.  Multiplying by 100 just puts things to rights.  Kirk  2006-09-12
	
		$ShipData{'75'}	= "$CgiRef->{'weighttype'}";	#Weight Units
		$ShipData{'69'} = $insurance; #Declared Value/Carriage Value
	
		# Heavy
		$ShipData{'57'}	= "$CgiRef->{'dimheight'}"; #Required for heavyweight
		$ShipData{'58'}	= "$CgiRef->{'dimwidth'}"; #Required for heavyweight
		$ShipData{'59'}	= "$CgiRef->{'dimlength'}"; #Required for heavyweight
	
		# International
		$ShipData{'1090'} = "$CgiRef->{'currencytype'}";
		$ShipData{'74'}	= "$CgiRef->{'destinationcountry'}";
	
		if ( $CgiRef->{'international'} )
		{
			$ShipData{'80'} = "$CgiRef->{'manufacturecountry'}";
			$ShipData{'70'} = "$CgiRef->{'dutypaytype'}";
			$ShipData{'1958'} = "Box";
		}
	
		$ShipData{'71'} = "$CgiRef->{'dutyaccount'}";
	
		if ( $CgiRef->{'international'} )
		{
			$ShipData{'72'}	= "$CgiRef->{'termsofsale'}";
			$ShipData{'414'} = "$CgiRef->{'commodityunits'}";
			$ShipData{'119'} = $commoditycustomsvalue;
		}
	
		$ShipData{'76'} = "$CgiRef->{'commodityquantity'}";
		$ShipData{'82'}	= "$CgiRef->{'unitquantity'}";
	
		if ( $CgiRef->{'international'} )
		{
			$ShipData{'73'}	= "$CgiRef->{'partiestotransaction'}";
			$ShipData{'79'}	= "$CgiRef->{'extcd'}";
		}
	
		$ShipData{'81'} = "$CgiRef->{'harmonizedcode'}";
	
		if ( $CgiRef->{'international'} )
		{
			$ShipData{'413'} = "$CgiRef->{'naftaflag'}";
		}
	
		$ShipData{'1139'} = "$CgiRef->{'ssnein'}";
		$ShipData{'50'}	= "$CgiRef->{'addresscountry'}"; #Recipient Country Code
	
		# fedex says is obsolete (201211112)
		##if ( $CgiRef->{'international'} )
		##{
		##	$ShipData{'1349'} = "S";
		##}
	
		# International Heavy
		$ShipData{'1271'} = "$CgiRef->{'slac'}"; # SLAC
		$ShipData{'1272'} = "$CgiRef->{'bookingnumber'}"; # Booking number
	
		# fedex says these are for hazardous not international.  changed 20121112
		##if ( $CgiRef->{'international'} )
		if ( $CgiRef->{'hazardous'} )
		{
			$ShipData{'456'} = 1;
			$ShipData{'466'} =	1;
			$ShipData{'471'} =	'L';
		}
		# Hazardous - fedex says that this is DG commodity count
		if ( $CgiRef->{'hazardous'} )
		{
			$ShipData{'1932'}	=	1;
		}
		##else
		##{
		##	$ShipData{'1932'}	=	0;
		##}

		# Saturday Delivery
		if ( $CgiRef->{'dateneeded'} )
		{
			my $ParsedDueDate = ParseDate($CgiRef->{'dateneeded'});
			my $DOWNeeded = UnixDate($ParsedDueDate, "%a");

			if ( $DOWNeeded eq 'Sat' )
			{
				$ShipData{'1266'} = 'Y'
			}
		}

		# Hazardous
		if ( $CgiRef->{'hazardous'} == 1 )
		{
			$ShipData{'1331'}	=	"A", #Hazardous Flag
			$ShipData{'451'}	=	$CgiRef->{'dgunnum'},
			$ShipData{'461'}	=	$CgiRef->{'dgpkgtype'},
			$ShipData{'476'}	=	$CgiRef->{'dgpkginstructions'},
			$ShipData{'484'}	=	$ContactPhone,
			$ShipData{'489'}	=	$CgiRef->{'dgpackinggroup'},
			$ShipData{'1903'}	=	$CgiRef->{'description'}, # Dangerous Goods Proper Ship Name
			$ShipData{'1918'}	=	$CgiRef->{'contactname'}, # Dangerous Goods Signatory
			$ShipData{'1922'}	=	$CgiRef->{'addresscity'}, # Dangerous Goods Signatory Location
			$ShipData{'485'}	=	$CgiRef->{'contacttitle'}, # Dangerous Goods Signatory Title
		}

		my $CO = new CO($self->{'dbref'}, $self->{'customer'});
		$CO->Load($CgiRef->{'coid'});
		$CgiRef->{'rtaddressid'} = $CO->GetValueHashRef()->{'rtaddressid'};
		$CgiRef->{'rtcontact'} = $CO->GetValueHashRef()->{'rtcontact'};
		$CgiRef->{'rtphone'} = $CO->GetValueHashRef()->{'rtphone'};

		if ( defined($CgiRef->{'rtaddressid'}) && $CgiRef->{'rtaddressid'} ne '' )
      {

			if ( !defined($CgiRef->{'rtphone'}) || $CgiRef->{'rtphone'} eq '' )
			{
				my $Customer = new CUSTOMER($self->{'dbref'}, $self->{'customer'});

      		if ($Customer->Load($self->{'customer'}->GetValueHashRef()->{'customerid'}))
      		{
         		$CgiRef->{'rtphone'} = $Customer->{'phone'};
         		$CgiRef->{'rtcontact'} = $Customer->{'contact'};
      		}
			}

			$CgiRef->{'rtphone'} =~ s/\.//g;
			$CgiRef->{'rtphone'} =~ s/\///g;
			$CgiRef->{'rtphone'} =~ s/\)//g;
			$CgiRef->{'rtphone'} =~ s/\(//g;
         $CgiRef->{'rtphone'} =~ s/ //g;

         my $Address = new ADDRESS($self->{'dbref'}, $self->{'customer'});
         $Address->Load($CgiRef->{'rtaddressid'});
			my $rtAddress = $Address->GetValueHashRef();

			#$CgiRef->{'rtaddressname'} = $rtAddress->{'addressname'};
			#$CgiRef->{'rtaddress1'} = $rtAddress->{'address1'};
			#$CgiRef->{'rtaddress2'} = $rtAddress->{'address2'};
			#$CgiRef->{'rtcity'} = $rtAddress->{'city'};
			#$CgiRef->{'rtstate'} = $rtAddress->{'state'};
			#$CgiRef->{'rtzip'} = $rtAddress->{'zip'};
			#$CgiRef->{'rtcountry'} = $rtAddress->{'country'};
		$ShipData{'1586'} = "Y",
		$ShipData{'1485'} = "$CgiRef->{'rtcontact'}",
		$ShipData{'1492'} = "$CgiRef->{'rtphone'}",
		$ShipData{'1486'} = "$rtAddress->{'addressname'}",
		$ShipData{'1487'} = "$rtAddress->{'address1'}",
		$ShipData{'1488'} = "$rtAddress->{'address2'}",
		$ShipData{'1489'} = "$rtAddress->{'city'}",
		$ShipData{'1490'} = "$rtAddress->{'state'}",
		$ShipData{'1491'} = "$rtAddress->{'zip'}",
		$ShipData{'1585'} = "$rtAddress->{'country'}",
		}
		local $^W = 1;
	#warnHashRefValues($CgiRef);
		# Build the shipment setring
		# Note - double quotes (") get escaped *within* their string.  This is needed since we're 'echo'ing
		# where we pipe it to the fedex program.
	#my $Temp = \%ShipData;
	#warnHashRefValues($Temp);
		# Shipment string prefix.
		my $ShipmentString = '0,"020"';
		foreach my $key (sort {$a <=> $b} (keys(%ShipData)))
		{
			# Push the key/value onto the string, if value exists (null value except in suffix tag
			# is a no-no).
			if( defined($ShipData{$key}) && $ShipData{$key} ne '' )
			{
				$ShipData{$key} =~ s/`/\\`/g;
				$ShipData{$key} =~ s/"/%22/g;

				$ShipmentString .= "$key,\"$ShipData{$key}\"";
			}
		}
		# Shipment string suffix
		$ShipmentString .= '99,""';
	#warnHashRefValues(\%ShipData);
		# Pass shipment string to fedex, and get the return value
	#		my $DebugStartString = "ATOM REQUEST (" . $self->{'customer'}->GetTokenID() ."): [Atom Start]";
	#		&Log($self->{'logfile'},$DebugStartString,$CgiRef->{'ipaddress'});
		&Benchmark($S1,'FedEx Pre Atom') if $Benchmark;

		my $S0 = &Benchmark();
	#warn "|$ShipmentString|";

		my $ShipmentReturn = $self->ProcessLocalRequest($ShipmentString);
	#warn "|$ShipmentReturn|";

		my $td = &Benchmark($S0,undef,1);

		my $S2 = &Benchmark();

	#		my $DebugStopString = "ATOM DEBUG (" . $self->{'customer'}->GetTokenID() ."): [Atom time = $td]";
	#		&Log($self->{'logfile'},$DebugStopString,$CgiRef->{'ipaddress'});

		# Check return string for errors;
		if ( $ShipmentReturn =~ /"2,"\w+?"/ )
		{
			my ($ErrorCode) = $ShipmentReturn =~ /"2,"(\w+?)"/;
			my ($ErrorMessage) = $ShipmentReturn =~ /"3,"(.*?)"/;

			$CgiRef->{'errorstring'} = "Error - $ErrorCode: $ErrorMessage";

			if ( $ErrorCode eq 'F010' || $ErrorCode eq '1237' || $ErrorCode eq '4057' || $ErrorCode eq '5031' || $ErrorCode eq '5043' || $ErrorCode eq '6011' || $ErrorCode eq '6015' || $ErrorCode eq '8020' || $ErrorCode eq '6026')
			{
				$CgiRef->{'errorcode'} = 'badzone';
			}

			return $CgiRef;
		}
		elsif ( $ShipmentReturn =~ /ERROR:(.*)\n/ )
		{
			$CgiRef->{'errorstring'} = $1;
			$CgiRef->{'screen'} = 'shipconfirm';

			return $CgiRef;
		}
	#warn $ShipmentReturn;
		# Build the shipment object to pass back to service
		my ($TrackingNumber) = $ShipmentReturn =~ /"29,"(\w+?)"/;
		my $PrinterString;
		($PrinterString) = $ShipmentReturn =~ /188,"(.*\nP1\nN\n)"/s;

		if ( !defined($PrinterString) || $PrinterString eq '' )
		{
			my $ua = LWP::UserAgent->new;
      	$ua->agent("Mozilla/4.08");

			my $req_url = "http://216.198.214.5/$TrackingNumber";
      	my $req = new HTTP::Request("GET" => $req_url);

      	my $Response = $ua->request($req);

      	my $String = $Response->as_string;
			$String =~ s/\x0c//;
			$String =~ s/\r//g;
	#warn $String;
			$PrinterString = $String;
		}

		$PrinterString = $self->TagPrinterString($PrinterString,$CgiRef->{'ordernumber'});
	#warn $PrinterString;

		$CgiRef->{'tracking1'} = $TrackingNumber;
		$CgiRef->{'printerstring'} = $PrinterString;
		$CgiRef->{'weight'} = $CgiRef->{'enteredweight'};

		my $S3 = &Benchmark() if $Benchmark;
		my $Shipment = new SHIPMENT($self->{'dbref'}, $self->{'customer'});
		$Shipment->CreateOrLoadCommit($CgiRef);
		&Benchmark($S3,'FedEx Create Shipment') if $Benchmark;

		$Shipment->{'printerstring'} = $PrinterString;

		&Benchmark($S2,'FedEx Post Atom') if $Benchmark;

		return $Shipment;
	}

__PACKAGE__->meta()->make_immutable();

no Moose;

1;

__END__