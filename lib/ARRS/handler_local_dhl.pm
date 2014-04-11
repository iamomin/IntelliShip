	package ARRS::handler_local_dhl;

	use strict;

	use ARRS::CARRIERHANDLER
	@ARRS::handler_local_dhl::ISA = ("ARRS::CARRIERHANDLER");

	use ARRS::COMMON;

	use POSIX qw (ceil strftime);
	use MIME::Base64;
	use Date::Business;
	use Date::Manip qw(ParseDate UnixDate);
	use Date::Calc qw(Day_of_Week);

	sub new
	{
		my $proto = shift;
		my $class = ref($proto) || $proto;

		my ($DBRef, $Contact) = @_;

		my $self = $class->SUPER::new($DBRef,$Contact);

		bless($self, $class);
		return $self;
	}

	sub GetETADate
	{
		my $self = shift;
		my ($Ref) = @_;

		if ( !defined($Ref->{'tozip'}) || $Ref->{'tozip'} eq '' )
		{
			return;
		}

		$Ref->{'servicename'} =~ s/DHL - //;
		my $ETA = '';

		my $originzip = substr($Ref->{'fromzip'},0,5);
		my $OriginSAC = $self->GetUSSAC($originzip,$Ref->{'fromcity'},$Ref->{'fromstate'});

		my $destinzip = '';
		my $DestinSAC = '';

		if ($Ref->{'tocountry'} eq 'US')
      {
         $destinzip = substr($Ref->{'tozip'},0,5);
         $DestinSAC = $self->GetUSSAC($destinzip,$Ref->{'tocity'},$Ref->{'tostate'});
      }
      else
      {
         if ($Ref->{'tocountry'} eq 'CA')
         {
            $destinzip = substr($Ref->{'tozip'},0,3);
         }
         elsif ($Ref->{'tocountry'} eq 'GB')
         {
            my $gb_length = length($Ref->{'tozip'});
            my $substr_length = $gb_length - 3;
            $destinzip = substr($Ref->{'tozip'},0,$substr_length);
            if ($destinzip =~ /[a-zA-Z]$/)
            {
               my $length = length($destinzip);
               my $s_length = $length - 1;
               $destinzip = substr($destinzip,0,$s_length);
            }
         }
         else
         {
            $destinzip = $Ref->{'tozip'};
         }

         $DestinSAC = $self->GetIntlSAC($destinzip,$Ref->{'tocountry'},$Ref->{'tocity'},$Ref->{'tostate'});
      }

		$Ref->{'dateshipped'} = $self->GetDateYYYYMMDD($Ref->{'datetoship'});

		($ETA,$Ref->{'encdatedue'},$Ref->{'originhubcode'},$Ref->{'destterminalcode'},$Ref->{'transitdays'}) = $self->CalculateDueDate($Ref->{'servicename'},$Ref->{'dateshipped'},$OriginSAC,$DestinSAC);

		$ETA =~ s/(\d{4})(\d{2})(\d{2})/$2\/$3\/$1/;

		return $self->SUPER::GetETADate($Ref);
	}

	sub CalculateDueDate
	{
		my $self = shift;
		my ($Service,$ShipDate,$OriginSAC,$DestinSAC) = @_;
		my $DueDate = '';
		my $LabelDueDate='';
		my $HubCode = '';
		my $TerminalCode = '';
		my $ETATransitDays = 0;
#warn "SAC CODES: $OriginSAC,$DestinSAC Service=$Service";
		if ( $Service =~ /Second Day/ || $Service =~ /2DAY/ )
		{
			my $SQL = "
            SELECT
               servicestandard,airplusdays
            FROM
               dhluscityzipsvc
            WHERE
					serviceareacode = '$DestinSAC'
				LIMIT 1
            ";

      	my $STH = $self->{'dbref'}->prepare($SQL)
         	or die "Could not prepare sql";

      	$STH->execute()
         	or die "Cannot execute sql statement";

      	my ($ServiceStandard,$AirPlusDays) = $STH->fetchrow_array();

			$STH->finish();


			my $SQLH = "
				SELECT
					count(*)
				FROM
					dhlusholidays
				WHERE
					(serviceareacode='$DestinSAC')
					AND
					(
   					holidaydate = (timestamp '$ShipDate')
						OR holidaydate = (timestamp '$ShipDate' + interval '1 days')
						OR holidaydate = (timestamp '$ShipDate' + interval '2 days')
					)
				";

			my $STHH = $self->{'dbref'}->prepare($SQLH)
            or die "Could not prepare sql";

         $STHH->execute()
           	or die "Cannot execute sql statement";

         my ($HolidayCount) = $STHH->fetchrow_array();

         $STHH->finish();
			#warn "airplus: $AirPlusDays";
			#warn "holiday: $HolidayCount";
			my $offset = $AirPlusDays + $HolidayCount + 2;
			$ETATransitDays = $offset;
			my $normalized_date = UnixDate($ShipDate,"%Q%");
			#warn "Normalized Date: $normalized_date";
			#warn "OFFSET: $offset";
			$DueDate = new Date::Business(
				DATE     => $normalized_date,
				OFFSET   => $offset,
			);

         $DueDate = $DueDate->image();

         my ($year,$month,$day) = $DueDate =~ /(\d{4})(\d{2})(\d{2})/;
		#	warn "|$year|$month|$day|";
      	my $day_of_week = Day_of_Week($year,$month,$day);
		#	warn "Day of Week: |$day_of_week|";

			$LabelDueDate = $day . $self->FormatDOW($day_of_week);
		}
		elsif ( $Service =~ /Ground/i )
		{
			my $SQLO = "
            SELECT
               servicestandard,groundoriginplusdays
            FROM
               dhluscityzipsvc
            WHERE
					serviceareacode = '$OriginSAC'
				LIMIT 1
            ";

      	my $STHO = $self->{'dbref'}->prepare($SQLO)
         	or die "Could not prepare sql";

      	$STHO->execute()
         	or die "Cannot execute sql statement";
#warn "$SQLO";
      	my ($GOServiceStandard,$GroundOriginPlusDays) = $STHO->fetchrow_array();
#warn "|$GOServiceStandard|$GroundOriginPlusDays|";
			$STHO->finish();

			my $SQLD = "
            SELECT
               servicestandard,grounddestinplusdays
            FROM
               dhluscityzipsvc
            WHERE
					serviceareacode = '$DestinSAC'
				LIMIT 1
            ";
#warn "$SQLD";
      	my $STHD = $self->{'dbref'}->prepare($SQLD)
         	or die "Could not prepare sql";

      	$STHD->execute()
         	or die "Cannot execute sql statement";

      	my ($GDServiceStandard,$GroundDestinPlusDays) = $STHD->fetchrow_array();
#warn "|$GDServiceStandard|$GroundDestinPlusDays|";
			$STHD->finish();

			# Ground Transit Info
			my $SQLT = "
            SELECT
               transitdays,linehaulhub,linehaulterminal
            FROM
               dhlgroundtransit
            WHERE
					originservicecode = '$OriginSAC'
					AND destinservicecode = '$DestinSAC'
				LIMIT 1
            ";
#warn $SQLT;
      	my $STHT = $self->{'dbref'}->prepare($SQLT)
         	or die "Could not prepare sql";

      	$STHT->execute()
         	or die "Cannot execute sql statement";

      	(my $TransitDays,$HubCode,$TerminalCode) = $STHT->fetchrow_array();
#warn "$TransitDays|$HubCode|$TerminalCode|";
			$STHT->finish();


			my $SQLHG = "
				SELECT
					count(*)
				FROM
					dhlusholidays
				WHERE
					(serviceareacode='$DestinSAC')
					AND
					(
   					holidaydate = (timestamp '$ShipDate')
				";

			for ( my $i = 0; $i <= $TransitDays; $i++ )
         {
				$SQLHG .= "OR holidaydate = (timestamp '$ShipDate' + interval '$i days')";
         }

			$SQLHG .= ")";
#warn "$SQLHG";
			my $STHHG = $self->{'dbref'}->prepare($SQLHG)
            or die "Could not prepare sql";

         $STHHG->execute()
           	or die "Cannot execute sql statement";

         my ($HolidayCountG) = $STHHG->fetchrow_array();
#warn "$HolidayCountG";
         $STHHG->finish();
#warn "OPlus: |$GroundOriginPlusDays|$GroundDestinPlusDays|$HolidayCountG|$TransitDays|";

			# if Ground transit days = 0... ground is invalid... undef and return
			my $offset_g='';
#warn "Transit Days=$TransitDays";
			if ( $TransitDays == 0 )
			{
				return (undef,undef,undef,undef);
			}
			else
			{
				local $^W = 0;
				$offset_g = $GroundOriginPlusDays + $GroundDestinPlusDays + $HolidayCountG + $TransitDays;
				$ETATransitDays = $offset_g;
				local $^W = 1;
			}

			my $normalized_date_g= UnixDate($ShipDate,"%Q%");
			#warn "Normalized Date: $normalized_date";
			#warn "OFFSET: $offset";
			$DueDate = new Date::Business(
                  DATE     => $normalized_date_g,
                  OFFSET   => $offset_g,
               );

         $DueDate = $DueDate->image();

         my ($y,$m,$d) = $DueDate =~ /(\d{4})(\d{2})(\d{2})/;
#			warn "|$y|$m|$d|";

      	my $dayofweek = Day_of_Week($y,$m,$d);
#			warn "Day of Week: |$dayofweek|";
			my $XX = $self->FormatDOW($dayofweek);
			$LabelDueDate = $d . $XX;
			#$LabelDueDate = $d . $self->FormatDOW($dayofweek);
		}

		#warn "RETURN: $DueDate,$LabelDueDate,$HubCode,$TerminalCode";
		return ($DueDate,$LabelDueDate,$HubCode,$TerminalCode,$ETATransitDays);
	}

	sub FormatDOW
	{
		my $self = shift;
		my ($day) = @_;

		my $Converted_Day = '';

		if ($day eq '0')
		{
			$Converted_Day = 'SU';
		}
		elsif ($day eq '1')
		{
			$Converted_Day = 'MO';
		}
		elsif ($day eq '2')
		{
			$Converted_Day = 'TU';
		}
		elsif ($day eq '3')
		{
			$Converted_Day = 'WE';
		}
		elsif ($day eq '4')
		{
			$Converted_Day = 'TH';
		}
		elsif ($day eq '5')
		{
			$Converted_Day = 'FR';
		}
		elsif ($day eq '6')
		{
			$Converted_Day = 'SA';
		}

		return $Converted_Day;
	}

	sub GetIntlSAC
	{
		my $self = shift;
		my ($ZipCode,$CountryCode,$City,$State) = @_;

		my $SAC = '';

		#Step 1 - Make sure DHL services this country
      my $SQL = "
            SELECT
               countrycode,format
            FROM
               dhlcountry
            WHERE
               countrycode = '$CountryCode'
            ";

      my $STH = $self->{'dbref'}->prepare($SQL)
         or die "Could not prepare sql";

      $STH->execute()
         or die "Cannot execute sql statement";

		my ($ValidCountry,$ZipFormat) = $STH->fetchrow_array();
#warn $ValidCountry;
      $STH->finish();

		if (!defined($ValidCountry) || $ValidCountry eq '')
		{
			$SAC = "Invalid Country";
		}
		else # We have a valid country so continue
		{
			#First see if this is a country with a single SAC
			 my $SQLO = "
            SELECT
               serviceareacode
            FROM
               dhlintlpostal
            WHERE
               startingpostalcode = '000000000000'
					AND endingpostalcode = '999999999999'
					AND countrycode = '$CountryCode'
				LIMIT 1
            ";
#warn $SQLO;
      	my $STHO = $self->{'dbref'}->prepare($SQLO)
         	or die "Could not prepare sql";

      	$STHO->execute()
         	or die "Cannot execute sql statement";

      	$SAC = $STHO->fetchrow_array();

			$STHO->finish();

			if (!defined($SAC) || $SAC eq '')
			{

				# Step 2 - Query using the zip
			 	my $SQL2 = "
            	SELECT
               	serviceareacode
            	FROM
               	dhlintlpostal
            	WHERE
               	upper(startingpostalcode) <= upper('$ZipCode')
						AND upper(endingpostalcode) >= ('$ZipCode')
						AND countrycode = '$CountryCode'
					LIMIT 1
            	";
#warn $SQL2;
      		my $STH2 = $self->{'dbref'}->prepare($SQL2)
         		or die "Could not prepare sql";

      		$STH2->execute()
         		or die "Cannot execute sql statement";

      		$SAC = $STH2->fetchrow_array();

				$STH2->finish();
			}

			# Step 3
			if (!defined($SAC) && $SAC eq '')
			{
			 	my $SQL3 = "
            	SELECT
               	count(*)
            	FROM
               	dhlintlnonpostal
            	WHERE
               	upper(cityname) = upper('$City')
						AND countrycode = '$CountryCode'
            	";
#warn $SQL3;
      		my $STH3 = $self->{'dbref'}->prepare($SQL3)
         		or die "Could not prepare sql";

      		$STH3->execute()
         		or die "Cannot execute sql statement";

      		my $ResultCount = $STH3->fetchrow_array();

				$STH3->finish();

				if ($ResultCount == 1)
				{
					my $SQLC1 = "
               	SELECT
                  	serviceareacode
               	FROM
                  	dhlintlnonpostal
               	WHERE
                  	upper(cityname) = upper('$City')
                  	AND countrycode = '$CountryCode'
               	";
#warn $SQLC1;
            	my $STHC1 = $self->{'dbref'}->prepare($SQLC1)
               	or die "Could not prepare sql";

            	$STHC1->execute()
               	or die "Cannot execute sql statement";

            	$SAC = $STHC1->fetchrow_array();

            	$STHC1->finish();
				}
				# Step 4
				if ($ResultCount > 1 || $ResultCount == 0)
				{
					my $SQL4 = "
               	SELECT
                  	serviceareacode
               	FROM
                  	dhlintlnonpostal
               	WHERE
                  	upper(cityname) = upper('$City')
							AND upper(cityqualifier) = upper('$State')
                  	AND countrycode = '$CountryCode'
               	";
#warn $SQL4;
            	my $STH4 = $self->{'dbref'}->prepare($SQL4)
               	or die "Could not prepare sql";

            	$STH4->execute()
               	or die "Cannot execute sql statement";

            	$SAC = $STH4->fetchrow_array();

            	$STH4->finish();

					if (!defined($SAC) || $SAC eq '')
					{
						# Step 5 & 6 combined (Steps are the same except for special criteria for China (CN))
						my $FinalTryCity;
						if ( $CountryCode eq 'CN' )
						{
#warn "SETTING CN CITY NAME";
							$FinalTryCity = '-UNLISTED CITIES ' . $City;
						}
						else
						{
							$FinalTryCity = '-UNLISTED CITIES';
						}

						 my $SQL5 = "
                  	SELECT
                     	serviceareacode
                  	FROM
                     	dhlintlnonpostal
                  	WHERE
                     	upper(cityname) like  upper('$FinalTryCity%')
                     	AND countrycode = '$CountryCode'
                  	";
#warn $SQL5;
               	my $STH5 = $self->{'dbref'}->prepare($SQL5)
                  	or die "Could not prepare sql";

               	$STH5->execute()
                  	or die "Cannot execute sql statement";

               	$SAC = $STH5->fetchrow_array();

               	$STH5->finish();

						if (!defined($SAC) || $SAC eq '')
						{
							$SAC = "NONE";
						}

					}
				}
			}
		} # end valid country else
#warn "FINAL INTL SAC: $SAC";
		return $SAC;

	} # end GetIntlSAC

	sub GetUSSAC
	{
		my $self = shift;
		my ($ZipCode,$City,$State) = @_;
#warn "$ZipCode,$City,$State";
		my $SAC = '';
		my $Counter = 0;
		my $Counter3 = 0;
      my $RecordRef = {};
      my $RecordRef3 = {};

		#Step 1
		my $SQL = "
				SELECT
					*
				FROM
					dhluscityzipsvc
				WHERE
					postalcode = '$ZipCode'
				";
#warn $SQL;
		my $STH = $self->{'dbref'}->prepare($SQL)
			or die "Could not prepare SAC sql";

		$STH->execute()
			or die "Cannot execute sql statement";

		while ( my $Records = $STH->fetchrow_hashref )
		{
   		$RecordRef->{$Counter++} = $Records;
		}

		$STH->finish();
		# We got nothing... this is an unroutable shipment
		if ($Counter == 0)
		{
			$SAC = "NONE";
		}
		# No need to go any further... we got a single record return
		elsif ($Counter == 1)
		{
#warn "Single Match: $SAC";
			foreach my $key (keys(%$RecordRef))
			{
				my $K = $RecordRef->{$key};
				$SAC = $K->{'serviceareacode'};
			}
		}
		# Step 2: We got multiple records returned so we need to continue
		else
		{
#warn "Going to Step 2";
			# Step 2: See if fields 4-8 are the same for all returned records
			my $count = 0;
			my $flag = '';
			my ($field4,$field5,$field6,$field7,$field8);
			my $S = {};

			foreach my $keyref (keys(%$RecordRef))
			{
				$S = $RecordRef->{$keyref};
				$count++;

				local $^W = 0;
				if ($count > 1)
				{
					if ( $S->{'serviceareacode'} ne $field4 ||
						  $S->{'servicestandard'} ne $field5 ||
						  $S->{'airplusdays'} ne $field6 ||
						  $S->{'groundoriginplusdays'} ne $field7 ||
						  $S->{'grounddestplusdays'} ne $field8
						)
					{
						$flag = "NOPE";
					}
				}
				else
				{
					$SAC = $S->{'serviceareacode'};
				}
				local $^W = 1;

				$field4 = $S->{'serviceareacode'};
				$field5 = $S->{'servicestandard'};
				$field6 = $S->{'airplusdays'};
				$field7 = $S->{'groundoriginplusdays'};
				$field8 = $S->{'grounddestplusdays'};
			}

			if ($flag ne '' && $flag eq 'NOPE')
			{
				$SAC = '';
				# Step 3: We had differing info in our records so we must continue
				my $SQL3 = "
            SELECT
               *
            FROM
               dhluscityzipsvc
            WHERE
               upper(city) = upper('$City')
					AND upper(state) = upper('$State')
            ";

				 my $STH3 = $self->{'dbref'}->prepare($SQL3)
        	 		or die "Could not prepare SAC sql";

      		$STH3->execute()
         		or die "Cannot execute sql statement";

				while ( my $Records3 = $STH3->fetchrow_hashref )
      		{
         		$RecordRef3->{$Counter3++} = $Records3;
      		}

      		$STH3->finish();
				 # We got nothing... this is an unroutable shipment

				if ($Counter3 == 0)
      		{
         		$SAC = "NONE";
      		}
      		# No need to go any further... we got a single record return
      		elsif ($Counter == 1)
      		{
         		$SAC = $RecordRef->{'serviceareacode'};
      		}
      		else
      		{
         		# Step 3 cont.: See if fields 4-8 are the same for all returned records
         		my $count3 = 0;
         		my $flag3 = '';
         		my ($f4,$f5,$f6,$f7,$f8);
					my $S3 = {};
         		foreach my $keyref3 (keys(%$RecordRef3))
         		{
            		$S3 = $RecordRef3->{$keyref3};
            		$count3++;

            		if ($count3 > 1)
            		{
               		if ( $S3->{'serviceareacode'} ne $f4 ||
                    		$S3->{'servicestandard'} ne $f5 ||
                    		$S3->{'airplusdays'} ne $f6 ||
                    		$S3->{'groundoriginplusdays'} ne $f7 ||
                    		$S3->{'grounddestplusdays'} ne $f8
                  		)
               		{
                  		$flag3 = "NOPE";
               		}
            		}

            		$f4 = $S3->{'serviceareacode'};
            		$f5 = $S3->{'servicestandard'};
            		$f6 = $S3->{'airplusdays'};
            		$f7 = $S3->{'groundoriginplusdays'};
            		$f8 = $S3->{'grounddestplusdays'};
         		}

					if ($flag3 ne '' && $flag3 eq 'NOPE')
         		{
						# Step 4: Still don't have any thing so query based on zip and city to get sac
						my $SQL4 = "
            			SELECT
               			serviceareacode
            			FROM
               			dhluscityzipsvc
            			WHERE
               			upper(city) = upper('$City')
               			AND postalcode = '$ZipCode'
							LIMIT 1
            			";

             		my $STH4 = $self->{'dbref'}->prepare($SQL4)
               		or die "Could not prepare SAC4 sql";

            		$STH4->execute()
               		or die "Cannot execute SAC4 sql statement";

            		$SAC = $STH4->fetchrow_array();

            		$STH4->finish();

						if (!defined($SAC) || $SAC eq '')
						{
							$SAC = 'NONE';
						}

					}
					else
					{
						# Set the SAC based on results from step 3
						$SAC = $S3->{'serviceareacode'};
					}
				}
			}
		}
#warn "FINAL SAC: $SAC";
		return $SAC;
	}

1;
