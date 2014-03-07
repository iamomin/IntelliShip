#!/usr/bin/perl -w

#==========================================================
#   Project:	ARRS
#
#   Filename:	EFREIGHT.pm
#
#   Date:		02/06/2013
#
#   Purpose:	 rates based on efreight.com soap calls
#
#   Company:	Engage Technology
#
#   Author(s):	Leigh Bohannon
#
#==========================================================

{
	package Tariff::EFREIGHT;

	use strict;

	use ARRS::COMMON;
	use ARRS::IDBI;
	use SOAP::Lite;
	use IntelliShip::MyConfig;
#	use SOAP::Lite ( +trace => 'debug' );

	my $Debug = 0;
	my $config = IntelliShip::MyConfig->get_ARRS_configuration;
        our $DB_HANDLE = ARRS::IDBI->connect({
         dbname      => 'arrs',
         dbhost      => 'localhost',
         dbuser      => 'webuser',
         dbpassword  => 'Byt#Yu2e',
         autocommit  => 1
      }); 
	sub new
	{
		my $proto = shift;
		my $class = ref($proto) || $proto;

		my $self = {};

                $self->{'dbref'} = $DB_HANDLE;

		bless($self, $class);

		return $self;
	}

	sub GetAssCode
   {
      my $self = shift;
      my ($csid,$serviceid,$name) = @_;
#warn "EFREIGHT GetAssCode($csid,$serviceid,$name)";

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
#warn "EFREIGHT GetAssCode returns asscode=$code";
      return $code;
   }

	sub GetCost
	{
		my $self = shift;
		my ($Weight,$DiscountPercent,$Class,$OriginZip,$DestZip,$SCAC,$DateShipped,$Required_Asses,$FileID,$ClientID,$CSID,$ServiceID) = @_;

		my $Benchmark = 0;
		my $S_ = &Benchmark() if $Benchmark;
		#warn "eFreight->GetCost()->$Weight,$DiscountPercent,$Class,$OriginZip,$DestZip,$SCAC,$DateShipped,$Required_Asses,$ClientID,$CSID,$ServiceID";

		my $Cost = -1;
		if ( !defined($SCAC) || $SCAC eq '' )
		{
			warn "eFreight=> NO SCAC CODE FOR RATING";
			return $Cost
		}

		my $days = 0;
		my $errorcode = 0;

		($days,$Cost,$errorcode) = $self->GetTransit($SCAC,$OriginZip,$DestZip,$Weight,$Class,$DateShipped,$Required_Asses,$FileID,$ClientID,$CSID,$ServiceID);
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

		#warn "EFREIGHT, return cost $Cost transit=$days for $SCAC" if $Benchmark;
		&Benchmark($S_,"EFREIGHT: $SCAC - \$$Cost") if $Benchmark;

		return ($Cost,$days);
	}

	sub GetTransit
	{
		my $self = shift;

		my ($scac,$oazip,$dazip,$weight,$class,$dateshipped,$required_asses,$fileid,$clientid,$csid,$serviceid) = @_;
		if ( !$fileid ) { $fileid = 'test' }
#		#warn "EFREIGHT: GetTrasit($scac,$oazip,$dazip,$weight,$class,$dateshipped,$required_asses,$fileid,$clientid,$csid,$serviceid)";

		my $path = "$config->{BASE_PATH}/bin/run";
		my $file = $fileid . ".efreight";
		my $File = $path . "/" . $file;
		my $Days = 0;
		my $cost = -1;
		my $ErrorCode;
		#warn "EFREIGHT: FILE=$File";
		if ( $File && -r $File )
		{
			open(FILE,$File)
         	or &TraceBack("Cannot open $File",1);

     		while(<FILE>)
      	{
				$_ =~ s/\n//;

         	my ($Scac,$Transit,$PriceLineHaul)= split("\t",$_);

				#warn "EFREIGHT ($scac) FILE VALUES |$Scac|$Transit|$PriceLineHaul|";

				if ( $Scac eq uc($scac) )
				{
					$Days = $Transit;
					$cost = $PriceLineHaul;
					#warn "EFREIGHT SAVE: |$Days|$cost|";
					last;
				}
      	}

			close(FILE);
		}
		else
		{
#warn "ELSE GetTransit=>$scac,$oazip,$dazip,$weight,$class,$dateshipped,$required_asses";
			#my $licensekey = '6E9A6C1E-C6C2-4170-887E-718A3DDE47F3';
   		#my $customerkey= '31762';
   		#my $url = 'http://91.189.44.97/EFS-WEBService/LTLWEBService.svc';
			# only use 5 digits.  won't rate with zip plus 4
      	# Zip needs to be 5 or 5+4
      	if ( defined($oazip) && $oazip !~ /^\d{5}$/ )
      	{
         	$oazip = substr($oazip,0,5);

      	}

      	if ( defined($dazip) && $dazip !~ /^\d{5}$/ )
      	{
         	$dazip = substr($dazip,0,5);
      	}

			my @RequiredAsses = ();
      	if ( defined($required_asses) && $required_asses ne '' )
      	{
         	my $ass_names = $required_asses;
        	 	my @ass_names = split(/,/,$ass_names);

         	foreach my $ass_name ( @ass_names )
         	{
            	my $AssCode = $self->GetAssCode($csid,$serviceid,$ass_name);
#warn "EFREIGHT  AssName=$ass_name asscode=$AssCode";

            	my $elem = SOAP::Data->name("Accessorial" => \SOAP::Data->value(
                  SOAP::Data->name('Code' => $AssCode)->prefix('fre')
                  ))->prefix('fre');

            	push(@RequiredAsses,$elem);
         	}
      	}

#warn "arrs|$oazip|$dazip|";
			my $licensekey = '6E9A6C1E-C6C2-4170-887E-718A3DDE47F3';
			my $customerkey = defined($clientid) && $clientid ne '' ? $clientid : '31930';
   		#my $url = 'http://91.189.44.97/LTLService/3/LTLWEBService.svc';
   		my $url = 'http://legacy.efsww.com/LTLService/3/LTLWEBService.svc';
#warn $customerkey;
			$dateshipped =~ s/(\d\d\d\d)(\d\d)(\d\d)/$2-$3-$1/;
			$dateshipped =~ s/-//g;
			my $soap = SOAP::Lite
      		->on_action( sub {sprintf '%sILTLService/%s', @_} )
      		->proxy( $url )
      		->encodingStyle('http://xml.apache.org/xml-soap/literalxml')
      		->readable(1);

   		my $serializer = $soap->serializer();
   		$serializer->register_ns('http://schemas.datacontract.org/2004/07/FreightLTL','fre');
   		$serializer->register_ns('http://tempuri.org/','tem');

   		my @params;

   		my $method = SOAP::Data->name('GetQuoteList')->prefix('tem');

			my $input = SOAP::Data
       	->name("request" => \SOAP::Data->value(
         	SOAP::Data->name("Authentication" => \SOAP::Data->value(
            	SOAP::Data->name('LicenseKey' => $licensekey)->prefix('fre')
         	))->prefix('fre'),
        	 SOAP::Data->name("Customer" => \SOAP::Data->value(
         	   SOAP::Data->name('CustomerKey' => $customerkey)->prefix('fre')
         	))->prefix('fre'),
				SOAP::Data->name("TariffDescription" => SOAP::Data->value(''))->prefix('fre'),
         	SOAP::Data->name("Origin" => \SOAP::Data->value(
            	SOAP::Data->name("Address" => \SOAP::Data->value(
               	SOAP::Data->name('PostalCode' => $oazip)->prefix('fre'),
               	SOAP::Data->name('CountryCode' => 'US')->prefix('fre')
            	))->prefix('fre')
         	))->prefix('fre'),
         	SOAP::Data->name("Destination" => \SOAP::Data->value(
            	SOAP::Data->name("Address" => \SOAP::Data->value(
               	SOAP::Data->name('PostalCode' => $dazip)->prefix('fre'),
               	SOAP::Data->name('CountryCode' => 'US')->prefix('fre')
            	))->prefix('fre')
         	))->prefix('fre'),
         	SOAP::Data->name("ItemsToShip" => \SOAP::Data->value(
            	SOAP::Data->name("QuoteListRequestItemToShip" => \SOAP::Data->value(
						SOAP::Data->name('Width' => '0')->prefix('fre'),
                  SOAP::Data->name('Height' => '0')->prefix('fre'),
                  SOAP::Data->name('Length' => '0')->prefix('fre'),
               	SOAP::Data->name('Weight' => $weight)->prefix('fre'),
               	SOAP::Data->name('FreightClass' => $class)->prefix('fre'),
                  SOAP::Data->name('HazardousMaterial' => '0')->prefix('fre'),
               	SOAP::Data->name('Quantity' => '1')->prefix('fre'),
 						SOAP::Data->name('Description' => 'Parts')->prefix('fre'),
                  SOAP::Data->name('Marks' => 'H8R7383')->prefix('fre'),
                  SOAP::Data->name('NMFC' => 'TB2433')->prefix('fre'),
                  SOAP::Data->name('SKU' => '901LP101')->prefix('fre'),
                  SOAP::Data->name('Packaging' => 'Pallet')->prefix('fre')->type(''),
                  SOAP::Data->name('QuantityHandlingUnits' => '1')->prefix('fre')
            	))->prefix('fre')
         	))->prefix('fre'),
				SOAP::Data->name("Accessorials" => \SOAP::Data->value(
               @RequiredAsses
            ))->prefix('fre'),
         	SOAP::Data->name("RateDate" => SOAP::Data->value($dateshipped))->prefix('fre'),
      	))->prefix('tem');

			push(@params,$input);

	   	my $som = $soap->call($method => @params);

			if ( $som->fault )
      	{
         	warn "EFREIGHT GetTransit faultstring=" . $som->fault->{'faultstring'} . "\n";
         	return 0;
      	}
      	else
			{
				open(FILE, ">$path/$file")
      			or die "Could not open $path/$file: $!";

				my %keyHash = %{ $som->body->{'GetQuoteListResponse'}->{'GetQuoteListResult'}->{'QuoteList'} };

      		foreach my $k (keys %keyHash)
      		{
					for ( my $i = 0; $i <= 19; $i++ )
         		{
         			print FILE "$keyHash{$k}[$i]->{CarrierSCAC}\t$keyHash{$k}[$i]->{ServiceLevel}\t$keyHash{$k}[$i]->{PriceLineHaul}\n" if $keyHash{$k}[$i];
						if ( $keyHash{$k}[$i]->{CarrierSCAC} && uc($scac) eq "$keyHash{$k}[$i]->{CarrierSCAC}" )
						{
							$Days = "$keyHash{$k}[$i]->{ServiceLevel}";
							$cost = "$keyHash{$k}[$i]->{PriceLineHaul}";
						}
					}
      		}

				close(FILE);
   		}
		}

	#warn "EFREIGHT RETURN DAYS|COST: |$Days|$cost|";
	return ($Days,$cost,$ErrorCode);
}


}
1

