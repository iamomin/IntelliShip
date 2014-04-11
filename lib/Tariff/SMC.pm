#!/usr/bin/perl -w

#==========================================================
#   Project:	ARRS
#
#   Filename:	SMC.pm
#
#   Date:		01/28/2013
#
#   Purpose:	Calculate rates based on SMC3 Tariff
#
#   Company:	Engage Technology
#
#   Author(s):	Kirk Aksdal
#					Leigh Bohannon
#
#==========================================================

{
	package Tariff::SMC;

	use strict;
	use ARRS::COMMON;
	use ARRS::IDBI;
	use SOAP::Lite;
	#use SOAP::Lite ( +trace => 'debug' );


	my $Debug = 0;

	sub new
	{
		my $proto = shift;
		my $class = ref($proto) || $proto;

		my $self = {};

		$self->{'dbref'} = ARRS::IDBI->connect({
			dbname => 'fedexfreight',
			dbhost => 'localhost',
			dbuser => 'webuser',
			dbpassword => 'Byt#Yu2e',
			autocommit => 1
		});

		bless($self, $class);

		return $self;
	}

	sub GetNormalizedZip
	{
		my $self = shift;
		my ($Zip) = @_;

		my $STH_SQL = "
			SELECT
				normalizedzip
			FROM
				zip
			WHERE
				lowzip <= '$Zip'
				AND highzip >= '$Zip'
		";

		my $STH = $self->{'dbref'}->prepare($STH_SQL)
			or die "Could not prepare normalized zip data select sql statement";

		$STH->execute()
			or die "Could not execute normalized zip data select sql statement";

		my ($NormalizedZip) = $STH->fetchrow_array();

		$STH->finish();

		return $NormalizedZip;
	}

	sub GetTariffNumber
	{
		my $self = shift;
		my ($FromZip,$ToZip) = @_;


		my ($TariffNumber);
		$TariffNumber = 'DEMOLTLA';
		#warn "SMC Tariff Number: $TariffNumber";

		return $TariffNumber;
	}

	sub GetRate
	{
		my $self = shift;
		my ($TariffNumber,$Class) = @_;

		my $STH_SQL = "
			SELECT
				*
			FROM
				rate
			WHERE
				tariffnumber = '$TariffNumber'
				AND class = '$Class'
		";

		my $STH = $self->{'dbref'}->prepare($STH_SQL)
			or die "Could not prepare rate data select sql statement";

		$STH->execute()
			or die "Could not execute rate data select sql statement";

		my $RateRef = $STH->fetchrow_hashref();

		$STH->finish();

		return $RateRef
	}

	sub GetCost
	{
		my $self = shift;
		my ($Weight,$DiscountPercent,$Class,$OriginZip,$DestZip,$SCAC) = @_;
#warn "SMC->GetCost()->$Weight,$DiscountPercent,$Class,$OriginZip,$DestZip,$SCAC";

		my $Cost = -1;
		if ( !defined($SCAC) || $SCAC eq '' )
		{
			warn "SMC=> NO SCAC CODE FOR RATING";
			return $Cost
		}

  		if ( my ($days,$origintype,$destintype,$errorcode,$method,$transitscac,$transitcarrier) = $self->GetTransit($SCAC,$OriginZip,$DestZip) )
  		{
     		if ( $errorcode )
     		{
        		warn "ERRORCODE=>$errorcode\n";
  	 		}
     		elsif ( $transitscac )
     		{
      		### This is a match but use days to determine if meets due date
         	### Also includes indirect options on origin and destination
         	## get price
         	$Cost = $self->LTLRate($OriginZip,$DestZip,$SCAC,$Weight,$Class,$DiscountPercent);

         	my $otransittype = $origintype eq 'I' ? 'Indirect' : 'Direct';
         	my $dtransittype = $destintype eq 'I' ? 'Indirect' : 'Direct';

			 	#warn "SCAC-$SCAC TransitDays-$days mode-$method origin-$otransittype destin-$dtransittype transitscac-$transitscac Charge=$charge \n";
			 	warn "SCAC-$SCAC TransitDays-$days mode-$method origin-$otransittype destin-$dtransittype transitscac-$transitscac\n";
      	}
      	else
      	{
        		#warn "NO TRANSIT => SCAC-$SCAC\n";
      	}
   	}
   	else
   	{
      	#warn "NO TRANSIT => SCAC-$SCAC \n";
   	}

		return $Cost;
	}

	sub LTLRate
	{
		my $self = shift;
   	my ($OriginZip,$DestZip,$SCAC,$Weight,$Class,$DiscountPercent) = @_;
		my $Cost = -1;

		my $api_licensekey_cc = 'hXu7j6b5Ag7k';
   	my $api_licensekey_rw = 'o89J62EL1Zh2';
  	 	my $api_username = 'bwood@myvisionship.com';
   	my $api_password = 'oX7aN7P7';
   	my $URL = 'http://demo.smc3.com/AdminManager/services/RateWareXL';

  	 	my $request = SOAP::Lite->new();
   	$request->proxy($URL);
   	$request->default_ns('urn:RateWareXL');
   	$request->autotype(0);

   	my $serializer = $request->serializer();
   	$serializer->register_ns( 'http://webservices.smc.com', 'web' );
   	$serializer->register_ns( 'http://web.ltl.smc.com', 'web1' );

   	my $authHeader = SOAP::Header->new(
      	name =>'web:AuthenticationToken',
      	value => {'web:licenseKey' => $api_licensekey_rw, 'web:password' => $api_password, 'web:username' => $api_username },
   	);

   	my @params = ($authHeader);
   	#my $service = 'LTLRateShipmentSimple';
   	my $service = 'LTLRateShipment';
   	my $namespace = 'http://demo.smc3.com/AdminManager/services/RateWareXL#' . $service;
  	 	my $method = SOAP::Data->name($service)->attr({'xmlns' => $namespace});

	 	my $input = SOAP::Data
        ->name("web.LTLRateShipmentRequest" => \SOAP::Data->value(
                  SOAP::Data->name('web1:destinationCountry')->value('USA'),
                  SOAP::Data->name('web1:destinationPostalCode')->value($DestZip),
                  SOAP::Data->name("web1:details" => \SOAP::Data->value(
                  SOAP::Data->name("web1:LTLRequestDetail" => \SOAP::Data->value(
                        SOAP::Data->name('web1:nmfcClass' => $Class),
                        SOAP::Data->name('web1:weight' => $Weight) )))),
                  SOAP::Data->name('web1:originCountry')->value('USA'),
                  SOAP::Data->name('web1:originPostalCode')->value($OriginZip),
                  SOAP::Data->name('web1:shipmentDateCCYYMMDD')->value('20130128'),
                  SOAP::Data->name('web1:shipmentID')->value('123456'),
                  SOAP::Data->name('web1:tariffName')->value('DEMOLTLA'),
                  SOAP::Data->name('web1:useSingleShipmentCharges')->value('N'),
                  SOAP::Data->name('web1:rateAdjustmentFactor')->value($DiscountPercent),
                  SOAP::Data->name('web1:useDiscounts')->value('Y'),
                  SOAP::Data->name('web1:discountApplication')->value('C'),
         ));

   	push(@params,$input);

   	my $responsetag = $service . 'Response';
   	my $responsetag2 = $responsetag;

   	my $result = $request->call($method => @params);

   	if ( $result->fault )
   	{
		  	warn "SMC Rating failure faultstring=" . $result->fault->{'faultstring'} . "\n";
      	return 0;
   	}
   	else
   	{
      	if ( $result->body && $result->body->{$responsetag}->{$responsetag2} )
      	{
         	my %keyHash = %{ $result->body->{$responsetag}->{$responsetag2} };

         	foreach my $k (keys %keyHash)
         	{
            	#print "name=$k   value=$keyHash{$k}\n";
            	if ( $k eq 'totalCharge' )
            	{
               	$Cost = $keyHash{$k};
            	}
					else
					{
						#warn $keyHash{$k};
					}
         	}
      	}
   	}

		return $Cost;
	}

	sub GetTransit
	{
		my $self = shift;

   	my ($scac,$oazip,$dazip) = @_;

		$scac = lc($scac);

	   my $apiname = 'CarrierConnectWS';
   	my $api_licensekey = 'hXu7j6b5Ag7k';
   	my $api_username = 'bwood@myvisionship.com';
   	my $api_password = 'oX7aN7P7';
   	my $URL = 'http://demo.smc3.com/AdminManager/services/' . $apiname;

   	my $request = SOAP::Lite->new();
   	$request->proxy($URL);
   	$request->default_ns('urn:'.$apiname);
   	$request->autotype(0);
   	#$request->readable(1);

   	my $serializer = $request->serializer();
   	$serializer->register_ns( 'http://webservices.smc.com', 'web' );
   	$serializer->register_ns( 'http://shipments.commons.smc.com', 'ship' );

   	my $authHeader = SOAP::Header->new(
      	name =>'web:AuthenticationToken',
      	value => {'web:licenseKey' => $api_licensekey, 'web:password' => $api_password, 'web:username' => $api_username },
  	 	);

   	my @params = ($authHeader);

  		my $service = 'Transit';
  	 	my $namespace = 'http://demo.smc3.com/AdminManager/services/' . $apiname . '#' . $service;
   	$request->on_action( sub { $namespace } );
   	my $method = SOAP::Data->name('web:'.$service);

    	my $input = SOAP::Data
        ->name("web:TransitRequest" => \SOAP::Data->value(
         SOAP::Data->name("ship:scacs" => \SOAP::Data->value(
                     SOAP::Data->name("ship:ScacRequest" => \SOAP::Data->value(
                        SOAP::Data->name('ship:method' => 'LTL'),
                        SOAP::Data->name('ship:scac' => $scac) ))
                     #,
                     #SOAP::Data->name("ship:ScacRequest" => \SOAP::Data->value(
                       # SOAP::Data->name('ship:method' => 'TL'),
                       # SOAP::Data->name('ship:scac' => $scac) ))

         )),
         SOAP::Data->name("ship:destination" => \SOAP::Data->value(
                        SOAP::Data->name('ship:countryCode' => 'USA'),
                        SOAP::Data->name('ship:postalCode' => $oazip),
         )),
         SOAP::Data->name("ship:origin" => \SOAP::Data->value(
                        SOAP::Data->name('ship:countryCode' => 'USA'),
                        SOAP::Data->name('ship:postalCode' => $dazip),
         )),
         SOAP::Data->name("ship:shipmentID" => SOAP::Data->value(undef)->attr({'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance'}))
      ));

		push(@params,$input);

   	my $responsetag = $service . 'Response';
   	my $responsetag2 = $responsetag;
   	my $responsetag3 = 'scacResponses';

   	my $result = $request->call($method => @params);

   	my ($Days,$OriginType,$DestinType,$ErrorCode,$Method,$Scac,$CarrierName);

	 	if ( $result->fault )
   	{
		  	warn "SMC GetTransit faultstring=" . $result->fault->{'faultstring'} . "\n";
      	return 0;
   	}
   	else
   	{
      	my %keyHash = %{ $result->body->{$responsetag}->{$responsetag2}->{$responsetag3}->{'ScacResponse'} };

      	foreach my $k (keys %keyHash)
      	{
         	if ( $k eq 'days' )
         	{
            	$Days = $keyHash{$k};
        	 	}
         	elsif ( $k eq 'method' )
         	{
            	$Method = $keyHash{$k};
         	}
         	elsif ( $k eq 'scac' )
         	{
            	$Scac = $keyHash{$k};
         	}
         	elsif ( $k eq 'name' )
         	{
            	$CarrierName = $keyHash{$k};
         	}
        	 	elsif ( $k =~ /errorcode/i )
         	{
            	$ErrorCode = $keyHash{$k};
         	}
         	elsif ( $k =~ /destinationServiceType/i || $k =~ /originServiceType/i )
  				{
            	if ( $k =~ /destin/i )
           	 	{
               	$DestinType = $keyHash{$k};
            	}
            	else
            	{
               	$OriginType = $keyHash{$k};
            	}
         	}
         	else
         	{
            	#warn "Not using $k=$keyHash{$k}\n";
         	}
      	}
   	}
#warn "GET TRANSIT RETURN $Days,$OriginType,$DestinType,$ErrorCode,$Method,$Scac,$CarrierName";
	return ($Days,$OriginType,$DestinType,$ErrorCode,$Method,$Scac,$CarrierName);
}


	sub GetWeightClassInfo
	{
		my $self = shift;
		my ($Weight) = @_;

		my $WeightClass = '';
		my $NextWeightClass = '';
		my $WtClassMinWt = 0;
		my $WtClassMaxWt = 0;
		my $NextWtClassMinWt = 0;
		my $NextWtClassMaxWt = 0;

		if ( $Weight >= 1 && $Weight <= 499 )
		{
			$WeightClass = 'l5c';
			$NextWeightClass = 'm5c';
			$WtClassMinWt = 1;
			$WtClassMaxWt = 499;
			$NextWtClassMinWt = 500;
			$NextWtClassMaxWt = 999;
		}
		elsif ( $Weight >= 500 && $Weight <= 999 )
		{
			$WeightClass = 'm5c';
			$NextWeightClass = 'm1m';
			$WtClassMinWt = 500;
			$WtClassMaxWt = 999;
			$NextWtClassMinWt = 1000;
			$NextWtClassMaxWt = 1999;
		}
		elsif ( $Weight >= 1000 && $Weight <= 1999 )
		{
			$WeightClass = 'm1m';
			$NextWeightClass = 'm2m';
			$WtClassMinWt = 1000;
			$WtClassMaxWt = 1999;
			$NextWtClassMinWt = 2000;
			$NextWtClassMaxWt = 4999;
		}
		elsif ( $Weight >= 2000 && $Weight <= 4999 )
		{
			$WeightClass = 'm2m';
			$NextWeightClass = 'm5m';
			$WtClassMinWt = 2000;
			$WtClassMaxWt = 4999;
			$NextWtClassMinWt = 5000;
			$NextWtClassMaxWt = 9999;
		}
		elsif ( $Weight >= 5000 && $Weight <= 9999 )
		{
			$WeightClass = 'm5m';
			$NextWeightClass = 'm10m';
			$WtClassMinWt = 5000;
			$WtClassMaxWt = 9999;
			$NextWtClassMinWt = 10000;
			$NextWtClassMaxWt = 19999;
		}
		elsif ( $Weight >= 10000 && $Weight <= 19999 )
		{
			$WeightClass = 'm10m';
			$NextWeightClass = 'm20m';
			$WtClassMinWt = 10000;
			$WtClassMaxWt = 19999;
			$NextWtClassMinWt = 20000;
			$NextWtClassMaxWt = 29999;
		}
		elsif ( $Weight >= 20000 && $Weight <= 29999 )
		{
			$WeightClass = 'm20m';
			$NextWeightClass = 'm30m';
			$WtClassMinWt = 20000;
			$WtClassMaxWt = 29999;
			$NextWtClassMinWt = 30000;
			$NextWtClassMaxWt = 39999;
		}
		elsif ( $Weight >= 30000 && $Weight <= 39999 )
		{
			$WeightClass = 'm30m';
			$NextWeightClass = 'm40m';
			$WtClassMinWt = 30000;
			$WtClassMaxWt = 39999;
			$NextWtClassMinWt = 40000;
			$NextWtClassMaxWt = 99999;
		}
		elsif ( $Weight >= 40000 && $Weight <= 99999 )
		{
			$WeightClass = 'm40m';
			$WtClassMinWt = 40000;
			$WtClassMaxWt = 99999;
		}

		my $WtClassRef = {};

		$WtClassRef->{'class'} = $WeightClass;
		$WtClassRef->{'nextclass'} = $NextWeightClass;
		$WtClassRef->{'minwt'} = $WtClassMinWt;
		$WtClassRef->{'maxwt'} = $WtClassMaxWt;
		$WtClassRef->{'nextminwt'} = $NextWtClassMinWt;
		$WtClassRef->{'nextmaxwt'} = $NextWtClassMaxWt;

		return $WtClassRef;
	}

	sub GetMinCharge
	{
		my $self = shift;
		my ($Weight,$RateRef) = @_;

		if ( $Weight >= 1 && $Weight <= 300 )
		{
			return $RateRef->{'mc1'};
		}
		elsif ( $Weight >= 301 && $Weight <= 400 )
		{
			return $RateRef->{'mc2'};
		}
		elsif ( $Weight >= 401 && $Weight <= 500 )
		{
			return $RateRef->{'mc3'};
		}
		elsif ( $Weight >= 501 && $Weight <= 99999 )
		{
			return $RateRef->{'mc4'};
		}
	}
}
1

