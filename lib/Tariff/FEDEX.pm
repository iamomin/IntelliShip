#!/usr/bin/perl -w

#==========================================================
#   Project:	ARRS
#
#   Filename:	FEDEX.pm
#
#   Date:		04/14/2014
#
#   Purpose:	Rate against our Fedex Ship Manager Server
#
#   Company:	Engage Technology
#
#   Author(s):	Leigh Bohannon
#
#==========================================================

{
	package Tariff::FEDEX;

	use strict;

	use ARRS::COMMON;
	use ARRS::IDBI;
	use LWP::UserAgent;
	use HTTP::Request::Common;
	use ARRS::CUSTOMERSERVICE;
	use POSIX qw(ceil);
	use IntelliShip::MyConfig;

	my $Debug = 0;
	my $config = IntelliShip::MyConfig->get_ARRS_configuration;

	sub new
	{
		my $proto = shift;
		my $class = ref($proto) || $proto;

		my $self = {};

	  $self->{'dbref'} = ARRS::IDBI->connect({
		 dbname	  => 'arrs',
		 dbhost	  => 'localhost',
		 dbuser	  => 'webuser',
		 dbpassword  => 'Byt#Yu2e',
		 autocommit  => 1
	  });

		bless($self, $class);

		return $self;
	}

	sub GetAssCode
   {
	  my $self = shift;
	  my ($csid,$serviceid,$name) = @_;
warn "FEDEX GetAssCode($csid,$serviceid,$name)";

	  my $SQL = "
		 SELECT DISTINCT
			asscode,ownertypeid
		 FROM
			assdata
		 WHERE
			( (ownerid = ? AND ownertypeid = 4) OR (ownerid = ? AND ownertypeid = 3) )
			AND assname = ?
		 ORDER BY ownertypeid desc
	  ";

		my $STH = $self->{'dbref'}->prepare($SQL)
		 or die "Could not prepare asscode select sql statement";

	  $STH->execute($csid,$serviceid,$name)
		 or die "Could not execute asscode select sql statement";

	  my ($code,$ownertypeid) = $STH->fetchrow_array();

	  $STH->finish();
warn "FEDEX GetAssCode returns asscode=$code";
	  return $code;
	}

	sub GetCost
	{
		my $self = shift;
		my ($Weight,$DiscountPercent,$Class,$OriginZip,$DestZip,$SCAC,$DateShipped,$Required_Asses,$FileID,$ClientID,$CSID,$ServiceID,$ToCountry,$CustomerID,$DimHeight,$DimWidth,$DimLength) = @_;

		my $Benchmark = 0;
		my $S_ = &Benchmark() if $Benchmark;
		warn "FEDEX->GetCost()->$Weight,$DiscountPercent,$Class,$OriginZip,$DestZip,$SCAC,$DateShipped,$Required_Asses,$ClientID,$CSID,$ServiceID,$ToCountry";

		my $Cost = -1;
		my $days = 0;
		my $errorcode = 0;
warn "FedEx GetTransit()";
warn "CUSTOMERID: $CustomerID";
		my $CS = new ARRS::CUSTOMERSERVICE($self->{'dbref'}, $self->{'contact'});
		$CS->{'object_issuper'} = 1;
		$CS->Load($CSID);

	  my $AcctNum = $CS->GetCSValue('webaccount',undef,$CustomerID);
	  my $MeterNum = $CS->GetCSValue('meternumber',undef,$CustomerID);
		$CS->{'object_issuper'} = 0;



		($days,$Cost,$errorcode) = $self->GetTransit($SCAC,$OriginZip,$DestZip,$Weight,$Class,$DateShipped,$Required_Asses,$FileID,$ClientID,$CSID,$ServiceID,$ToCountry,$AcctNum,$MeterNum,$DimHeight,$DimWidth,$DimLength);
		#if ( my ($days,$origintype,$destintype,$errorcode,$method,$transitscac,$transitcarrier) = $self->GetTransit($SCAC,$OriginZip,$DestZip,$Weight,$Class,$DateShipped) )
		if ( $days )
		{
			if ( $errorcode )
			{
				warn "ERRORCODE=>$errorcode";
			}
 	}
 	else
 	{
		#warn "NO eFreight TRANSIT => SCAC-$SCAC";
 	}

		warn "FEDEX, return cost $Cost transit=$days for $SCAC" if $Benchmark;
		&Benchmark($S_,"FEDEX: $SCAC - \$$Cost") if $Benchmark;

		return ($Cost,$days);
	}

	sub GetTransit
	{
		my $self = shift;

		my ($scac,$oazip,$dazip,$weight,$class,$dateshipped,$required_asses,$fileid,$clientid,$csid,$serviceid,$tocountry,$acctnum,$meternum,$height,$width,$length) = @_;
		if ( !$fileid ) { $fileid = 'test' }
		warn "FEDEX: GetTrasit($scac,$oazip,$dazip,$weight,$class,$dateshipped,$required_asses,$fileid,$clientid,$csid,$serviceid,$tocountry,$acctnum,$meternum)";

		my $path = "$config->{BASE_PATH}/bin/run";
	  my $file = $fileid . ".info";
		my $File = $path . "/" . $file;
		my $Days = 0;
		my $cost = -1;
		my $ErrorCode;
		my $yyyymmdd = $dateshipped;
		warn "FEDEX: FILE=$File";
=b
		if ( $File && -r $File )
		{
			open(FILE,$File)
			or &TraceBack("Cannot open $File",1);

			while(<FILE>)
		{
				$_ =~ s/\n//;

			my ($Scac,$Transit,$PriceLineHaul)= split("\t",$_);

				warn "FEDEX ($scac) FILE VALUES |$Scac|$Transit|$PriceLineHaul|";

				if ( $Scac eq uc($scac) )
				{
					$Days = $Transit;
					$cost = $PriceLineHaul;
					warn "FEDEX SAVE: |$Days|$cost|";
					last;
				}
		}

			close(FILE);
		}
		else
		{
=cut
warn "ELSE No session file so GetTransit()=>$scac,$oazip,$dazip,$weight,$dateshipped";
			# only use 5 digits.  won't rate with zip plus 4
		if ( defined($oazip) && $oazip !~ /^\d{5}$/ )
		{
			$oazip = substr($oazip,0,5);

		}

		if ( defined($dazip) && $dazip !~ /^\d{5}$/ )
		{
			$dazip = substr($dazip,0,5);
		}

			$dateshipped =~ s/(\d\d\d\d)(\d\d)(\d\d)/$2-$3-$1/;
			$dateshipped =~ s/-//g;
warn "dateshipped: $dateshipped";


			# Allow for LTR type packages (0 weight)
		my $PackageType = "01";
		if ($weight == 0)
		{
			$PackageType = "06";
			#$weight = "1.0";
		}



		# Shipment string prefix.
		my $ShipmentString = '0,"025"';
		 #9  => "$oazip", #Sender Postal Code


		my %ShipData = (
			 1    => "$fileid",     # unique id sent and also returned in response
			 9    => "$oazip",              # Sender Postal Code
			 20   => "$acctnum",    # Recipient Postal Code
			 24	  => "$yyyymmdd",	# Ship Date
			 17   => "$dazip",      # Recipient Postal Code
			 23   => "1",           # Pay Type
			 50   => "$tocountry",  # Recipient Country Code
			 117  => "US",          # Sender Country Code
			 498  => "$meternum",   # Required - Meter #
			 1090 => "USD",
			 1234 => "1",           # Rate Quote and Route
			 1273 => $PackageType,  # packagetype
			);

			 #DIMs
			if ( $height )
			{
			$ShipData{'57'} = $height; #Required for heavyweight
			$ShipData{'58'} = $width; #Required for heavyweight
			$ShipData{'59'} = $length; #Required for heavyweight
			# round up for api acceptance
			$ShipData{'57'} = ceil($ShipData{'57'});
			$ShipData{'58'} = ceil($ShipData{'58'});
			$ShipData{'59'} = ceil($ShipData{'59'});
			}

			if ( $tocountry ne 'US' )
			{
			# add intl fields
			#$ShipData{'15'} = "Madrid";
			#$ShipData{'18'} = "555-555-5555";
			#$ShipData{'80'} = "$CgiRef->{'manufacturecountry'}";
			#$ShipData{'80'} = "US";
			#$ShipData{'70'} = "$CgiRef->{'dutypaytype'}";
			#$ShipData{'70'} = "1";
			#$ShipData{'70'} = "1";
			#$ShipData{'1958'} = "Box";
			#$ShipData{'74'}   = "IT";
			#$ShipData{'73'}   = "$CgiRef->{'partiestotransaction'}";
			#$ShipData{'79'}   = "$CgiRef->{'extcd'}";
			#$ShipData{'413'} = "$CgiRef->{'naftaflag'}";
			#$ShipData{'73'}   = "";
			#$ShipData{'79'}   = "";
			#$ShipData{'413'} = "";
			#$ShipData{'1271'} = ""; # SLAC
			#$ShipData{'1272'} = ""; # Booking number


			}
		 #3062  => "4", #ratetype
		 #24	=> "$dateshipped", # Ship date
			if ( $serviceid eq '0000000000004' )
			{
			$ShipData{'1274'}  = "92"; #FedEx Service Type
			}
			elsif ( $serviceid eq '0000000000006' )
			{
			$ShipData{'1274'}  = "03"; #FedEx Service Type
			}
			elsif ( $serviceid eq '0000000000002' )
			{
			$ShipData{'1274'}  = "01"; #FedEx Service Type
			}
			elsif ( $serviceid eq '0000000000007' )
			{
			$ShipData{'1274'}  = "20"; #FedEx Service Type
			}
			elsif ( $serviceid eq '0000000000005' )
			{
			$ShipData{'1274'}  = "05"; #FedEx Service Type
			}
			elsif ( $serviceid eq 'FEDEXNFO00000' )
			{
			$ShipData{'1274'}  = "06"; #FedEx Service Type
			}
			elsif ( $serviceid eq '0000000000201' )
			{
			$ShipData{'1274'}  = "70"; #FedEx Service Type
			}
			elsif ( $serviceid eq '0000000000202' )
			{
			$ShipData{'1274'}  = "80"; #FedEx Service Type
			}
			elsif ( $serviceid eq '0000000000203' )
			{
			$ShipData{'1274'}  = "83"; #FedEx Service Type
			}
			elsif ( $serviceid eq '0000000000301' )
			{
			$ShipData{'1274'}  = "01"; #FedEx Service Type
			}
			elsif ( $serviceid eq '0000000000302' )
			{
			$ShipData{'1274'}  = "03"; #FedEx Service Type
			}
		#$ShipData{'75'}   = "LBS";   # (KGS) Weight Units
		#$ShipData{'69'} = $insurance; #Declared Value/Carriage Value
			#$ShipData{'74'}   = "$CgiRef->{'destinationcountry'}";

			#Total Package Weight this field has 2 implied decimals.  Multiplying by 100 just puts things to rights.  Kirk  2006-09-12
		$ShipData{'1670'} = ceil($weight * 100);

			foreach my $key (sort {$a <=> $b} (keys(%ShipData)))
		{
			# Push the key/value onto the string, if value exists (null value except in suffix tag is a no-no)
			if( defined($ShipData{$key}) && $ShipData{$key} ne '' )
			{
				$ShipData{$key} =~ s/`/\\`/g;
				$ShipData{$key} =~ s/"/%22/g;
					warn "$key,\"$ShipData{$key}\"";

				$ShipmentString .= "$key,\"$ShipData{$key}\"";
 		  }
			}
		# Shipment string suffix
		$ShipmentString .= '99,""';
			#WarnHashRefValues(\%ShipData);
warn "SEND: ".$ShipmentString;

			my $ShipmentReturn = $self->ProcessLocalRequest($ShipmentString);
warn "RECEIVE: ".$ShipmentReturn;

			# Check return string for errors;
		if ( $ShipmentReturn =~ /"2,"\w+?"/ )
		{
			my ($ErrorCode) = $ShipmentReturn =~ /"2,"(\w+?)"/;
			my ($ErrorMessage) = $ShipmentReturn =~ /"3,"(.*?)"/;
				warn "FedEx Rate/Route Error Response:  $ErrorCode: $ErrorMessage";
		}
		elsif ( $ShipmentReturn =~ /ERROR:(.*)\n/ )
		{
			warn "FedEx Rate/Route Error Response: " . $1;
		}

			my ($NetCharge) = $ShipmentReturn =~ /"37,"(\d+?)"/;
			my ($TotalSurcharges) = $ShipmentReturn =~ /"35,"(\d+?)"/;
			#$cost = sprintf("%.2f", ($NetCharge - $TotalSurcharges));
			($Days) = $ShipmentReturn =~ /"3058,"(\d+?)"/;
			if(!$Days || $Days eq '')
			{
				$Days = 0;
				my ($shipByDate) = $ShipmentReturn =~ /"409,"(\w+?)"/;
				warn "########## shipByDate: $shipByDate";
				if($shipByDate && $shipByDate ne '')
				{
					my $mm =  substr($dateshipped, 0,2);
					my $dd =  substr($dateshipped, 2,2);
					my $yyyy =  substr($dateshipped, 4,4);
					my $fds = "$yyyy/$mm/$dd";
					warn "########## formatted dateshipped: $fds";
					$Days = IntelliShip::DateUtils->get_delta_days($fds, $shipByDate);
					warn "########## Days: $Days";
				}
			}

			$cost = ($NetCharge - $TotalSurcharges);
			$cost =~ s/(\d+)(\d{2})/$1\.$2/;

#warn "NetCharge |$NetCharge|";
#warn "TotalSurcharges |$TotalSurcharges|";

			if ( $cost == 0 ) { $cost = undef }
			# Build the shipment object to pass back to service
		#my ($TrackingNumber) = $ShipmentReturn =~ /"29,"(\w+?)"/;
		#my ($PrinterString) = $ShipmentReturn =~ /188,"(.*\nP1\nN\n)"/s;

				#open(FILE, ">$path/$file")
			#	or die "Could not open $path/$file: $!";

					#print FILE "$keyHash{$k}[$i]->{CarrierSCAC}\t$keyHash{$k}[$i]->{ServiceLevel}\t$keyHash{$k}[$i]->{PriceLineHaul}\n" if $keyHash{$k}[$i];
					#warn "$keyHash{$k}[$i]->{CarrierSCAC}\t$keyHash{$k}[$i]->{ServiceLevel}\t$keyHash{$k}[$i]->{PriceLineHaul}\n" if $keyHash{$k}[$i];
						#if ( $keyHash{$k}[$i]->{CarrierSCAC} && uc($scac) eq "$keyHash{$k}[$i]->{CarrierSCAC}" )
						#{
						#	$Days = "$keyHash{$k}[$i]->{ServiceLevel}";
						#	$cost = "$keyHash{$k}[$i]->{PriceLineHaul}";
						#}

				#close(FILE);
		#}

	warn "FEDEX RETURN DAYS|COST: |$Days|$cost|";
	return ($Days,$cost,$ErrorCode);
}

	sub ProcessLocalRequest
	{
	  my $self = shift;
	  my ($Request) = @_;

	  #$Request = '0,"025"1,"Rate All Services"15,"collierville"16,"tn"17,"38017"18,"9015551212"23,"1"50,"US"117,"US"498,""1090,"USD"1234,"1"1273,"01"1274,""1670,"100"3062,""99,""';
		#warn $Request;

		my $Host = '216.198.214.5';
	  my $Port = "2000";
	  use Net::Telnet;
	  my $telnet = Net::Telnet->new(Host=>$Host,Port=>$Port,Timeout=>"10");

	  $telnet->print($Request);
	  my ($Pre,$Match) = $telnet->waitfor(Match => '/99,""/');
	  #warn "Match-$Match";
	  #warn "Pre-$Pre";

	  #Response = 0,"125"1,"8EY94LY9FXMV9"10,"494036924"33,"A1"34,"19545"35,"393"36,"14948"37,"4990"60,"49"194,"THU"409,"26Jun14"431,"N"498,"253301"574,"A1"1086,"43"1090,"USD"1092,"7"1133,"1"1273,"01"1274,"03"1393,"393"1507,"1951"1519,"20540"1525,"17501"1528,"22491"1690,"N"1981,"4:30 PM"1992,"00"3076,""4565,""4568,"0"4912,""4913,""4915,""99,""
	  return $Pre.$Match."\n";
	}

}

1
