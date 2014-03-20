#!/usr/bin/perl -w

#####################################################################
##
##	module SCREEN
##
##	Engage TMS, Inc screen interface.
##
#####################################################################

{
	package ARRS::ONLINE;

	use strict;
	use ARRS::CARRIER;
	use ARRS::COMMON;
	use ARRS::CSOVERRIDE;
	use ARRS::CUSTOMERSERVICE;
	use ARRS::ZIPMILEAGE;

	use Array::Compare;
	use Date::Calc qw(Delta_Days);
	use Date::Manip qw(ParseDate UnixDate);
	use IntelliShip::MyConfig;
        use Data::Dumper;

	my $Benchmark = 0;
	my $config = IntelliShip::MyConfig->get_ARRS_configuration;

	sub new
	{
		my $proto = shift;
		my $class = ref($proto) || $proto;

		my $self = {};

		($self->{'dbref'}, $self->{'contact'}) = @_;

		bless($self, $class);
		return $self;
	}

	sub GetServicesDropdown
	{
		my $self = shift;
		my ($CgiRef) = @_;
#warn "clientid: $CgiRef->{'clientid'}";
#WarnHashRefValues($CgiRef);
		my $Debug = 0;

		my $S1 = &Benchmark() if $Benchmark;

		$CgiRef->{'efreightid'} = $self->{'dbref'}->gettokenid();
		#warn "efreight fileid = $CgiRef->{'efreightid'}" if $Debug;

		my $qInternational = $CgiRef->{'intl'} ? $CgiRef->{'Intl'} : 0;

		if ( defined($CgiRef->{'tocountry'}) && $CgiRef->{'tocountry'} ne 'US' && $CgiRef->{'tocountry'} ne '' )
		{
			$qInternational = 1;
		}
		if ( defined($CgiRef->{'tostate'}) && $CgiRef->{'tostate'} eq 'PR' )
		{
			#warn "SET PR TO INTERNATIONAL";
			$qInternational = 1;
		}

		my $CalcETA = ( !$CgiRef->{'collect'} && !$CgiRef->{'thirdparty'} ) ? 1 : 0;
		my $CalcRate = ( !$CgiRef->{'collect'} && !$CgiRef->{'thirdparty'} ) ? 1 : 0;
		my $Sort = ( !$CgiRef->{'collect'} && !$CgiRef->{'thirdparty'} ) ? 1 : 0;

		# Standard Carriers/Services
		my $ListRef = {};
		my $Counter = 0;

		my $SQLString = "
			SELECT DISTINCT
				cs.customerserviceid,
				c.carriername || ' - ' || s.servicename,
				c.carrierid,
				s.timeneededmax,
				s.webhandlername,
				s.serviceid
			FROM
				customerservice cs,
				service s,
				carrier c
			WHERE
				cs.serviceid = s.serviceid
				AND s.carrierid = c.carrierid
		";

		# No CSID, route/rate everything
		if ( !$CgiRef->{'csid'} )
		{
			$SQLString .= "
				AND cs.customerid = '$CgiRef->{'sopid'}'
				AND s.international = $qInternational
			";
		}
		# Otherwise, just rate the csid in question
		else
		{
			$SQLString .= "
				AND cs.customerserviceid = '$CgiRef->{'csid'}'
			";
		}

		$SQLString .= "
			ORDER BY
				2
		";

		my $sth = $self->{'dbref'}->prepare($SQLString)
			or die "Could not prepare SQL statement";

		warn $SQLString if $Debug;

		$sth->execute()
			or die "Cannot execute carrier/service sql statement";

		my $CSIDs = '';
		my $CSNames = '';
		my $DefaultExists = 0;
		my $AutoDefaultExists = 0;
		my $DefaultCSID = '';
		my $DefaultCost = 0;
		my $DefaultTotalCost = 0;
		my $DefaultETA = '';

		my @CSIDs = ();
		push(@CSIDs,0);

		my @CostList = ();
		push(@CostList,0);

		my $CostWeightList = "'0',";

		my $LowCost = '';
		my $ETATotal = 0;
		my $CostTotal = 0;

		# Get Due date of week, for global use in ETA calcs (avoids a fairly spendy date parse for every service)
		if ( $CalcETA )
		{
			if ( $CgiRef->{'dateneeded'} )
			{
				my $ParsedDueDate = ParseDate($CgiRef->{'dateneeded'});
				$CgiRef->{'downeeded'} = UnixDate($ParsedDueDate, "%a");
			}

			my $ParsedShipDate = ParseDate($CgiRef->{'datetoship'});
			$CgiRef->{'norm_datetoship'} = UnixDate($ParsedShipDate, "%Q");
			$CgiRef->{'numeric_dowtoship'} = UnixDate($ParsedShipDate, "%w");
		}

		while ( my ($CSID, $CSName, $CarrierID, $TimeNeededMax, $HandlerName, $ServiceID) = $sth->fetchrow_array() )
		{
			# Allow customers to exclude specific CS's
			my $CSOverride = new ARRS::CSOVERRIDE($self->{'dbref'}, $self->{'contact'});
			if ( $CSOverride->ExcludeCS($CgiRef->{'customerid'},$CSID) )
			{
				next;
			}

			warn "ONLINE: $CSName " if $Debug;
			#warn "ONLINE: $CSName " if $CSID eq 'TOTALTRANSPO1';

			my $CS = new ARRS::CUSTOMERSERVICE($self->{'dbref'}, $self->{'contact'});
			$CS->Load($CSID);
			# If we get a list of assessorials - all selected services must have said assessorials
			if
			(
				$CgiRef->{'required_assessorials'} &&
				!$self->HasRequiredAssessorials($CS,$CgiRef->{'required_assessorials'})
			)
			{
				warn "EXCLUDED BASED ON REQUIRED ASSES: $CSName" if $Debug;
				#warn "EXCLUDED BASED ON REQUIRED ASSES: $CSName" if $CSID eq 'TOTALTRANSPO1';
				next;
			}

			# Collect/3p filtering
			if ( $CgiRef->{'collect'} )
			{
				my $CFCharge = $CS->GetCSValue('collectfreightcharge');

				if ( !defined($CFCharge) || $CFCharge eq '' )
				{
					warn "EXCLUDED BASED ON COLLECT FILTERING: $CSName" if $Debug;
					warn "EXCLUDED BASED ON COLLECT FILTERING: $CSName" if $CSID eq 'TOTALTRANSPO1';
					next;
				}
			}

			if ( $CgiRef->{'thirdparty'} )
			{
				my $TPCharge = $CS->GetCSValue('thirdpartyfreightcharge');

				if ( !defined($TPCharge) || $TPCharge eq '' )
				{
					warn "EXCLUDED BASED ON THIRD PARTY FILTERING: $CSName" if $Debug;
					warn "EXCLUDED BASED ON THIRD PARTY FILTERING: $CSName" if $CSID eq 'TOTALTRANSPO1' ;
					next;
				}
			}

			# Check if this service is ok to ship on the ship date - otherwise, skip it.
			if ( my $ValidShipDays = $CS->GetCSValue('validshipdays') )
			{
				if ( !$self->OkToShipOnShipDate($CgiRef->{'numeric_dowtoship'},$ValidShipDays) )
				{
					warn "EXCLUDED BASED ON DAY OF WEEK: $CSName" if $Debug;
					warn "EXCLUDED BASED ON DAY OF WEEK: $CSName" if $CSID eq 'TOTALTRANSPO1';
					next;
				}
			}

			# Int'l weight checks
			#if ( $qInternational )
			#{
			#}


			# See if we got a csid passed in
			if ( defined($CgiRef->{'csid'}) && $CSID eq $CgiRef->{'csid'}  && !$CgiRef->{'route'} )
			{
				$DefaultExists = 1;
				$DefaultCSID = $CSID;
			}

warn "STILL HERE0" if $Debug;
			my ($Cost,$ZoneNumber,$PackageCosts,$CostWeight,$TransitDays);
			if
			(
				$CalcRate &&
				(
					( defined($CgiRef->{'tozip'}) && $CgiRef->{'tozip'} ne '' ) ||
					( defined($CgiRef->{'tocountry'}) && $CgiRef->{'tocountry'} ne '' )
				)
			)
			{
				my $S3 = &Benchmark() if $Benchmark;
				($Cost,$ZoneNumber,$PackageCosts,$CostWeight,$TransitDays) = $CS->GetShipmentCosts($CgiRef);
warn "STILL HERE Got Costs $Cost - $TransitDays - $PackageCosts" if $Debug;

				$CostTotal += &Benchmark($S3,"Calculate Cost - $CSID, $CSName") if $Benchmark;

				if ( $CgiRef->{'customerserviceid'} && $CSID eq $CgiRef->{'customerserviceid'}  && $PackageCosts )
				{
					$DefaultTotalCost = 0;
					my (@AllCharges) = split(/::/,$PackageCosts);
					foreach my $PackageCharge(@AllCharges)
					{
						my @Charges = split(/-/,$PackageCharge);
						foreach my $charge(@Charges)
						{
							$DefaultTotalCost += $charge;
						}
					}
				}
			}
			$TimeNeededMax = $TransitDays ? $TransitDays : $TimeNeededMax;

			# Only calculate ETA Date here if we have a dateneeded
			my $ETADate;
			if ( $CalcETA && $CgiRef->{'dateneeded'} )
			#if ( $CalcETA )
			{
				# If we've got a servicecsdata timeneededmax, use it, otherwise, fall back to pure service level
				my $cs_timeneeded_max = $CS->GetCSValue('timeneededmax');
				$TimeNeededMax = $cs_timeneeded_max ? $cs_timeneeded_max : $TimeNeededMax;
				$TimeNeededMax = $TransitDays ? $TransitDays : $TimeNeededMax;

				my $S2 = &Benchmark() if $Benchmark;
				my $ETARef = {
					datetoship			=> $CgiRef->{'datetoship'},
					norm_datetoship	=> $CgiRef->{'norm_datetoship'},
					dateneeded			=> $CgiRef->{'dateneeded'},
					downeeded			=> $CgiRef->{'downeeded'},
					fromstate			=> $CgiRef->{'fromstate'},
					tostate				=> $CgiRef->{'tostate'},
					fromzip				=> $CgiRef->{'fromzip'},
					tozip					=> $CgiRef->{'tozip'},
					fromcountry			=> $CgiRef->{'fromcountry'},
					tocountry			=> $CgiRef->{'tocountry'},
					handlername			=> $HandlerName,
					carrierid			=> $CarrierID,
					serviceid			=> $ServiceID,
					servicename			=> $CSName,
					cs						=> $CS,
					timeneededmax		=> $TimeNeededMax,
				};


				$ETADate = $self->GetETADate($ETARef);

				if ( $CSID eq 'TOTALTRANSPO1' )
				{
					warn "etadate: $ETADate";
				}
				warn "ONLINE CALC/SET ETADate: $CSName - $HandlerName - $ETADate - $Cost - $TimeNeededMax" if $Debug;
				warn "ONLINE CALC/SET ETADate: $CSName - $HandlerName - $ETADate - $Cost - $TimeNeededMax" if $CSID eq 'TOTALTRANSPO1';

				$ETATotal += &Benchmark($S2,"Calculate ETA - $CSID, $CSName") if $Benchmark;
			}

			if
			(
				defined($Cost)
				||
				(
					$CarrierID eq '0000000000001'
					&&
					(
						( defined($CgiRef->{'tostate'}) )
						&&
						(
							$CgiRef->{'tostate'} eq 'HI'
							|| $CgiRef->{'tostate'} eq 'AK'
							|| $CgiRef->{'tostate'} eq 'PR'
							|| $CgiRef->{'tostate'} eq 'VI'
						)
					)
				)
#				If a customer doesn't have rates - show all services
				|| !$CgiRef->{'hasrates'}
#				Some services, we just always show
				|| $CS->GetCSValue('alwaysshow')
				|| !$CalcRate
			)
			{
				# If we've got a due date, eliminate the service as an automatic option
				# Though leave it for manual use.
				my $CSMeetsDueDate = 0;
warn "STILL HERE $Cost - $TimeNeededMax" if $Debug;

				#if ( $CalcETA && defined($CgiRef->{'dateneeded'}) && $CgiRef->{'dateneeded'} ne '' )
				if ( $CalcETA )
				{
warn "calceta=$CalcETA"  if $Debug;
					# Can this service make the due date?
					if ( defined($ETADate) && $ETADate ne '' && $ETADate ne '0' && defined($CgiRef->{'dateneeded'}) && $CgiRef->{'dateneeded'} ne '' )
					{
warn "can service meet eta?" if $Debug;
						my ($ETAMonth,$ETADay,$ETAYear) = $ETADate =~ /(\d{1,2})\/(\d{1,2})\/(\d{4})/;
						my @ETADate = ($ETAYear,$ETAMonth,$ETADay);

						$CgiRef->{'dateneeded'} = VerifyDate($CgiRef->{'dateneeded'});

						my ($DueMonth,$DueDay,$DueYear) = $CgiRef->{'dateneeded'} =~ /(\d{1,2})\/(\d{1,2})\/(\d{4})/;

						my @DueDate = ($DueYear,$DueMonth,$DueDay);

						# if the deliveron flag is used then the eta must equal the due date
						if ( defined($CgiRef->{'deliveron'}) && $CgiRef->{'deliveron'} == 1 )
						{
							if ( Delta_Days(@ETADate, @DueDate) == 0 )
							{
								$CSMeetsDueDate = 1;
							}
						}
						# otherwise, the eta can occur on or before the due date
						else
						{
							if ( Delta_Days(@ETADate, @DueDate) >= 0 )
							{
								$CSMeetsDueDate = 1;
							}
						}
					}
warn "CSMeetsDueDate=$CSMeetsDueDate" if $Debug;

					if ( !$CSMeetsDueDate && defined($CgiRef->{'dateneeded'}) && $CgiRef->{'dateneeded'} ne '' )
					{
						$CSName = '** ' . $CSName;
					}

					if ( defined($ETADate) && $ETADate ne '' )
					{
						$CSName .= " $ETADate";

						# If this thing is needed Sat/Sun, see if it's set to deliver on Sat/Sun, and flag it as such in the list
						if
						(
							defined($CgiRef->{'downeeded'}) &&
							( $CgiRef->{'downeeded'} eq 'Sat' || $CgiRef->{'downeeded'} eq 'Sun' )
						)
						{
							my $ParsedETADate = ParseDate($ETADate);
							my $ETADOW = UnixDate($ParsedETADate, "%a");

							if ( $ETADOW eq 'Sat' || $ETADOW eq 'Sun' )
							{
								my $DOWNeeded = ($ETADOW eq 'Sat') ? 'Saturday' : 'Sunday';
								$CSName .= " $DOWNeeded";
							}
						}
					}
				}

				# Auto CS Select
				# See if the current CS is the lowest cost cs (and will meet the due date)
				# Also need to check if it's the appropriate class for a class based service.
				if
				(
					( defined($Cost) && $Cost ne '' )
					&&
					(
						( $CgiRef->{'autocsselect'} && !$DefaultExists ) ||
						( $CgiRef->{'route'} )
					)
					&&
					$CSMeetsDueDate
					&&
					(
						( $CgiRef->{'allowraterecalc'} && $CgiRef->{'manroutingctrl'} )
						||
						! $CgiRef->{'manroutingctrl'}
					)
					&&
					(
						( !$CgiRef->{'isdropship'} && !$CgiRef->{'isinbound'} ) ||
						( $CgiRef->{'isdropship'} && $CS->GetCSValue('dropshipcapable') ) ||
						( $CgiRef->{'isinbound'} && $CS->GetCSValue('inboundcapable') )
					)
				)
				{
					# Current cost > last cost
					if
					(
						$LowCost eq '' ||
						( $Cost < $LowCost && $Cost > 0 ) ||
						( $LowCost == 0 && $Cost > 0 )
					)
					{
						$LowCost = $Cost;
						$AutoDefaultExists = 1;
						$DefaultCSID = $CSID;
						$DefaultCost = $Cost;
						$DefaultTotalCost = 0;
						if ( defined($ETADate) && $ETADate ne '' )
						{
							$DefaultETA = $ETADate;
						}

						my (@AllCharges) = split(/::/,$PackageCosts);
						foreach my $PackageCharge(@AllCharges)
						{
							my @Charges = split(/-/,$PackageCharge);
							foreach my $charge(@Charges)
							{
								$DefaultTotalCost += $charge;
							}
						}
#warn "default: $DefaultTotalCost";
					}
				}

				# If a customer has rates, display them (if cost and zone exist)
				if ( $CalcRate && $CgiRef->{'hasrates'} )
				{
					if ( defined($Cost) && $Cost ne '' && $Cost > 0 )
					{
						my $total_ass_cost = 0;
						# Get total cost of all assessorials, to be added to the droplist display
						my $S4 = &Benchmark() if $Benchmark;
						if ( $CgiRef->{'required_assessorials'} )
						{
#warn "ONLINE Call GetTotalAssCost customerid=$CgiRef->{'customerid'}";
#warn "STILL HERE $Cost - GetTotalAssCost" if $CSID eq 'TOTALTRANSPO1';
							$total_ass_cost = $self->GetTotalAssCost(
								$CS,
								$CgiRef->{'required_assessorials'},
								$CgiRef->{'aggregateweight'},
								$CgiRef->{'totalquantity'},
								$Cost,
								$CgiRef->{'customerid'}
							);
						}
						$CostTotal += &Benchmark($S4,"Add Assessorial To Cost - $CSID, $CSName") if $Benchmark;

						$Cost = $total_ass_cost ? ($Cost + $total_ass_cost) : $Cost;
						$Cost = sprintf("%02.2f", $Cost);

						$CSName .= '-$'.$Cost;
					}
					elsif ( !defined($Cost) || $Cost eq '' || $Cost eq '0' || $Cost == 0 )
					{
						$CSName .= '-$Quote';
					}

					if ( defined($ZoneNumber) && $ZoneNumber ne '' )
					{
						$CSName .= ' ('.$ZoneNumber.')';
					}
				}

				$ListRef->{$Counter++} = {
					'key' => $CSID,
					'value' => $CSName,
				};

				$CSIDs .= $CSID . "\t";
				$CSNames .= $CSName . "\t";
#warn "|$CSID|$PackageCosts|";
				push(@CSIDs,$CSID);
				push(@CostList,$PackageCosts);

				$CostWeightList .= "'$CostWeight'," if ( $CostWeight && $CostWeight >= 0 );
			}
		}

# This only applies to loginlevel 20 (Route only).  Currently no such logins exist.  Further, the shipconfirm
# interface sorts on dateneeded (make/miss), cost, carrier/service...so it's likely unnecessary.  Kirk 2009-04-16
#		if ( $Sort && $CgiRef->{'sortcslist'} )
#		{
#			($CSIDs,$CSNames) = $self->SortCSLists($CSIDs,$CSNames,$CgiRef->{'displaychargesincslist'});
#warn $CSIDs;
#warn $CSNames;
#		}

		print STDERR "Total ETA Calculation: $ETATotal\n" if $Benchmark;
		print STDERR "Total Cost Calculation: $CostTotal\n" if $Benchmark;

		if ( ! $DefaultExists && ! $AutoDefaultExists ) { undef($DefaultCSID); }
		$sth->finish();

		# Build up costlist string in a JS array suitable string;
		local $^W = 0;
		my $CostList = join("','",@CostList);
		local $^W = 1;

		$CostList = "'$CostList'";

#WarnHashRefValues($CgiRef);
		my $ReturnRef = {};
		$ReturnRef->{'csnames'} = $CSNames;
		$ReturnRef->{'csids'} = $CSIDs;
		$ReturnRef->{'costlist'} = $CostList;
		$ReturnRef->{'defaultcost'} = $DefaultCost;
		$ReturnRef->{'defaulttotalcost'} = $DefaultTotalCost;
		$ReturnRef->{'defaultcsid'} = $DefaultCSID;
		$ReturnRef->{'defaulteta'} = $DefaultETA;
		($ReturnRef->{'costweightlist'}) = $CostWeightList =~ /(.*),/;
		&Benchmark($S1,"Total Time For CS List") if $Benchmark;

		my $file = "$config->{BASE_PATH}/bin/run/$CgiRef->{'efreightid'}".".efreight";
		#unlink("$config->{BASE_PATH}/bin/run/$CgiRef->{'efreightid'}.efreight");

		return $ReturnRef;
	}

	sub SortCSLists
	{
		my $self = shift;
		my ($CSIDs,$CSNames,$DisplayCharges) = @_;
		my $SortedCSIDs;
		my $SortedCSNames;

		my @CSIDs = split(/\t/,$CSIDs);
		my @CSNames = split(/\t/,$CSNames);
		my @CSArray = ();

		# Push IDs and names onto an array, to keep them together through the sorting process
		for ( my $i; $i<scalar(@CSIDs); $i++ )
		{
			push(@CSArray,"$CSIDs[$i]:$CSNames[$i]");
		}

		# See pages 116-120 of the Perl Cookbook (2nd Ed) for info on this sorting technique
		my @SortedCSArray =
			map { $_->[0] }
			sort {
				$a->[2] cmp $b->[2] ||
				$a->[3] <=> $b->[3] ||
				$a->[1] cmp $b->[1]
			}
			map { [ $_, $self->SplitCSString($_) ] }
			@CSArray;

		foreach my $CS (@SortedCSArray)
		{
			my ($CSID,$CSName) = $CS =~ /(.*):(.*)/;

			if ( !$DisplayCharges )
			{
				$CSName =~ s/(.*)(-\$Quote.*|-\$\d+\.\d+.*)/$1/g
			}

			$SortedCSIDs .= $CSID . "\t";
			$SortedCSNames .= $CSName . "\t";
		}

		return $SortedCSIDs,$SortedCSNames;
	}

	sub SplitCSString
	{
		my $self = shift;
		my ($String) = @_;

		my ($CarrierService) = $String  =~ /:(.* - .*?)( \d{2}|-)/;
		my $Late = $CarrierService =~ s/\*\* //g;
		my ($Charge) = $String =~ /\$(Quote|\d+\.\d+)/;

		# Quote stuff needs to come at the end of the list - but 'Quote' messes with the comparison,
		# so give it an arbitrarily high value (that should never be seen in real charges).
		# Not ideal, but it's the best I've got for now - Kirk, 2006-06-22
		$Charge = $Charge eq 'Quote' ? 999999999 : $Charge;
#print STDERR "$CarrierService,$Late,$Charge\n";
		return $CarrierService,$Late,$Charge;
	}

	sub GetETADate
	{
		my $self = shift;
		my ($ETARef) = @_;
		my $ETADate;

		my $HandlerName = $ETARef->{'handlername'} || '';
		my $Handler;

		if (length $HandlerName)
		{
		warn "passed require of $config->{BASE_PATH}/lib/ARRS/$HandlerName";
		$HandlerName =~ s/\.pl//;
		$HandlerName = "ARRS::$HandlerName";

		print STDERR "\n[GetETADate] HandlerName: $HandlerName";
		eval "use $HandlerName;";

		if ($@)
			{
			warn "[Error] GetCarrierHandler eval Exception: $@";
			# other exception handling goes here...
			}

		$Handler = $HandlerName->new($self->{"dbref"}, $self->{"contact"});
		}
		else
		{
warn "HANDLERNAME: use CARRIERHANLDER";
   		use ARRS::CARRIERHANDLER;
		$Handler = new ARRS::CARRIERHANDLER($self->{'dbref'},$self->{'contact'});
		}

		unless ( ($ETADate) = $Handler->GetETADate($ETARef) )
		{
warn "undef etadate";
			undef($ETADate);
		}

		return $ETADate;
	}

	sub GetCSID
	{
		my $self = shift;
		my ($Ref) = @_;

		my $Carrier = $Ref->{'carrier'};
		my $Service = $Ref->{'service'};

		$Carrier =~ s/\'/\\\'/g;
		$Service =~ s/\'/\\\'/g;

		if ( $Ref->{'carrier'} && $Ref->{'service'} )
		{
			my $SQLString = "
				SELECT
					cs.customerserviceid
				FROM
					customerservice cs,
					service s,
					carrier c
				WHERE
					cs.customerid = '$Ref->{'sopid'}' AND
					cs.serviceid = s.serviceid AND
					(s.servicename ~* '^$Service\$' OR cs.servicenamealias ~* '^$Service\$') AND
					s.carrierid = c.carrierid AND
					(c.carriername ~* '^$Carrier\$' OR c.scac = '$Carrier' OR cs.scacalias = '$Carrier')
			";

			my $sth = $self->{'dbref'}->prepare($SQLString)
				or die "Could not prepare SQL statement";

			$sth->execute()
				or die "Could not execute SQL statement";

			my @CSIDs = ();

			while ( my ($CSID) = $sth->fetchrow_array )
			{
				push(@CSIDs,$CSID);
			}

			if ( scalar(@CSIDs) == 1 )
			{
				return {'csid' => $CSIDs[0]};
			}
			elsif ( scalar(@CSIDs) > 1 )
			{
				foreach my $CSID (@CSIDs)
				{
					my $CS = new ARRS::CUSTOMERSERVICE($self->{'dbref'}, $self->{'contact'});
					$CS->Load($CSID);

					my ($Cost) = $CS->GetShipmentCosts($Ref);

					if ( defined($Cost) && $Cost ne '' )
					{
						return {'csid' => $CSID};
					}
				}
			}
			else
			{
				return undef;
			}
		}

		return undef;
	}

	# This is a full droplist of carriers/services for a customer, regardless of class/int'l issues
	# Currently used for the void selection screen
	sub GetFullServiceDropdown
	{
		my $self = shift;
		my ($SOPID,$CustomerID) = @_;

		my $SQLString = "
			SELECT DISTINCT
				cs.customerserviceid,
				c.carriername || ' - ' || s.servicename
			FROM
				customerservice cs,
				service s,
				carrier c
			WHERE
				cs.customerid = '$SOPID'
				AND cs.serviceid = s.serviceid
				AND s.carrierid = c.carrierid
			ORDER BY
				2
		";

		my $sth = $self->{'dbref'}->prepare($SQLString)
			or die "Could not prepare SQL statement";

		$sth->execute()
			or die "Cannot execute carrier/service sql statement";

		my $ReturnRef = {};
		while ( my ($CSID,$CSName) = $sth->fetchrow_array() )
		{
			my $CSOverride = new ARRS::CSOVERRIDE($self->{'dbref'}, $self->{'contact'});
			if ( $CSOverride->ExcludeCS($CustomerID,$CSID) )
			{
				next;
			}

			$ReturnRef->{'csids'} .= "$CSID\t";
			$ReturnRef->{'csnames'} .= "$CSName\t";
		}

		$sth->finish();

		return $ReturnRef;
	}

	sub GetCarrierList
	{
		my $self = shift;
		my ($SOPID,$CustomerID) = @_;

		my $SQLString = "
			SELECT DISTINCT
				c.carrierid,
				c.carriername
			FROM
				customerservice cs,
				service s,
				carrier c
			WHERE
				cs.customerid = '$SOPID'
				AND cs.serviceid = s.serviceid
				AND s.carrierid = c.carrierid
			ORDER BY
				2
		";

		my $sth = $self->{'dbref'}->prepare($SQLString)
			or die "Could not prepare SQL statement";

		$sth->execute()
			or die "Cannot execute carrier/service sql statement";

		my $ReturnRef = {};
		while ( my ($CID,$CName) = $sth->fetchrow_array() )
		{
			my $Carrier = new ARRS::CARRIER($self->{'dbref'}, $self->{'contact'});
			$Carrier->Load($CID);

			if ( $Carrier->Exclude($SOPID,$CustomerID) )
			{
				next;
			}

			$ReturnRef->{'cids'} .= "$CID\t";
			$ReturnRef->{'cnames'} .= "$CName\t";
		}

		$sth->finish();

		return $ReturnRef;
	}

        sub GetCarrierServiceList
	{
		my $self = shift;
		my ($SOPID) = @_;

                warn "########## GetCarrierServiceList " . $SOPID;

		my $SQLString = "select 
                                    cs.customerserviceid, 
                                    c.carrierid, 
                                    c.carriername, 
                                    s.serviceid, 
                                    s.servicename, 
                                    cso.value
                                from 
                                    customerservice cs 
                                inner join 
                                    service s on cs.serviceid = s.serviceid 
                                inner join 
                                    carrier c on s.carrierid = c.carrierid 
                                left outer join 
                                    csoverride cso on (cs.customerserviceid = cso.customerserviceid and cso.datatypename = 'excludecs' and cso.value <> '1') 
                                where cs.customerid = '$SOPID' 
                                order by c.carriername, s.servicename;
		";


                #warn "######### \$SQLString $SQLString";
		my $sth = $self->{'dbref'}->prepare($SQLString)
			or die "Could not prepare SQL statement";

                
		$sth->execute()
			or die "Cannot execute carrier/service sql statement";

                
		my $ReturnRef = {};
		while ( my ($csid, $cid, $carriername, $sid, $servicename, $exclude) = $sth->fetchrow_array() )
		{
                        #warn "######### 3";
			if($exclude){next;}

                        my $carrier = $ReturnRef->{$cid};
                        if(!$carrier)
                        {
                            $carrier = {};
                            $carrier->{'carriername'} = $carriername;                            
                            my @arr = ();
                            $carrier->{'csrecords'} = \@arr;
                            $ReturnRef->{$cid} = $carrier;
                        }

                        my $csrecord = {};
                        $csrecord->{'csid'} = $csid;
                        $csrecord->{'sid'} = $sid;
                        $csrecord->{'servicename'} = $servicename;
                        push(@{$carrier->{'csrecords'}}, $csrecord);
                        
		}

		$sth->finish();

                #warn "########## ReturnRef: " . Dumper($ReturnRef);
		return $ReturnRef;
	}

        sub GetServiceTariff 
        {
            warn "########## 5";
            my $self = shift;
            my ($csid) = @_;

            warn "########## GetServiceTariff " . $csid;

            my $ReturnRef = {};
            my $CS = new ARRS::CUSTOMERSERVICE($self->{'dbref'}, $self->{'contact'});
            $CS->Load($csid);
            warn "########## 5.1";

            #Get all distinct zones for the CS
            my $zontypeid = $CS->GetValueHashRef()->{'zonetypeid'};
            warn "########## 5.2 : $zontypeid";
            my $SQLString = "select distinct zonenumber, char_length(zonenumber) || zonenumber as a from zone where typeid = '$zontypeid' order by a";
            
            warn "########## 5.3 : $SQLString";
            my $sth = $self->{'dbref'}->prepare($SQLString)
                    or die "Could not prepare SQL statement";


            $sth->execute()
                    or die "Cannot execute carrier/service sql statement";

            warn "########## 5.4";

            my @arr = ();
            while ( my ($zonenumber) = $sth->fetchrow_array() )
            {
                push(@arr, $zonenumber);
            }

            $sth->finish();
            $ReturnRef->{'zonenumbers'} = \@arr;
            warn "########## 5.5: " . Dumper(@arr);

            #Get rates for the zones
            my $ratetypeid = $CS->GetValueHashRef()->{'ratetypeid'};

            warn "########## 5.6: $ratetypeid";

            $SQLString = "select
                            rateid,
                            unitsstart, 
                            unitsstop,
                            zonenumber,
                            arcost, 
                            arcostmin,
                            arcostperwt,
                            arcostpermile,
                            arcostperunit, 
                            unittype
                          from rate 
                          where typeid = '$ratetypeid' 
                          and zonenumber in 
                          (
                            select distinct zonenumber 
                            from zone 
                            where typeid = '$zontypeid'
                            order by zonenumber
                          ) 
                          order by unitsstart, unitsstop, zonenumber";


            warn "######### \$SQLString $SQLString";
            my $sth2 = $self->{'dbref'}->prepare($SQLString)
                    or die "Could not prepare SQL statement";


            $sth2->execute()
                    or die "Cannot execute carrier/service sql statement";


            my @ratearray = ();
            while ( my ($rateid, $unitsstart, $unitsstop, 
                        $zonenumber, $arcost, $arcostmin, 
                        $arcostperwt, $arcostpermile, 
                        $arcostperunit, $unittype) = $sth2->fetchrow_array() )
            {
                    my $rate = {};                    
                    $rate->{'unitsstart'} = $unitsstart;
                    $rate->{'unitsstop'} = $unitsstop;
                    $rate->{'zonenumber'} = $zonenumber;
                    $rate->{'arcostmin'} = $arcostmin;
                    $rate->{'unittype'} = $unittype;
                    $rate->{'rateid'} = $rateid;

                    if($arcost)
                    {    
                        $rate->{'actualcost'} = $arcost;
                        $rate->{'costfield'} = 'arcost';
                    }
                    elsif($arcostperwt)
                    {    
                        $rate->{'actualcost'} = $arcostperwt;
                        $rate->{'costfield'} = 'arcostperwt';
                    }
                    elsif($arcostpermile)
                    {    
                        $rate->{'actualcost'} = $arcostpermile;
                        $rate->{'costfield'} = 'arcostpermile';
                    }
                    elsif($arcostperunit)
                    {    
                        $rate->{'actualcost'} = $arcostperunit;
                        $rate->{'costfield'} = 'arcostperunit';
                    }
                    
                    push(@ratearray, $rate);                    
            }

            $sth2->finish();
            $ReturnRef->{'ratearray'} = \@ratearray;

            #warn "########## ReturnRef: " . Dumper($ReturnRef);
            return $ReturnRef;
        }
        
	sub OkToShipOnShipDate
	{
		my $self = shift;
		my ($NumericDOW,$ValidShipDays) = @_;

		my @ValidShipDays = split(/,/,$ValidShipDays);

		foreach my $ShipDay (@ValidShipDays)
		{
			if ( $ShipDay == $NumericDOW )
			{
				return 1;
			}
		}

		return 0;
	}

	sub GetCustomersByCarrier
   {
      my $self = shift;
      my ($CarrierID) = @_;

      my $SQLString = "
         SELECT DISTINCT
            cs.customerid
         FROM
            carrier c,
            service s,
            customerservice cs
         WHERE
            c.carrierid = s.carrierid
            AND s.serviceid = cs.serviceid
            AND c.carrierid = '$CarrierID'
      ";

		my $sth = $self->{'dbref'}->prepare($SQLString)
         or die "Could not prepare SQL statement";

      $sth->execute()
         or die "Cannot execute carrier/service sql statement";

      my $ReturnRef = {};
      while ( my ($CustomerID) = $sth->fetchrow_array() )
      {
         $ReturnRef->{'customerid'} .= "$CustomerID\t";
      }

      $sth->finish();

      return $ReturnRef;
   }

	sub GetCarrierServiceName
	{
		my $self = shift;
		my ($GroupName,$ServiceCode) = @_;

		my $SQLString = "
			SELECT DISTINCT
				c.carriername,
				s.servicename
			FROM
				carrier c,
				service s
			WHERE
				c.groupname = '$GroupName'
				AND s.servicecode = '$ServiceCode'
				AND c.carrierid = s.carrierid
			";
#warn $SQLString;
		my $sth = $self->{'dbref'}->prepare($SQLString)
			or die "Could not prepare SQL statement";

		$sth->execute()
			or die "Cannot execute carrier/service sql statement";

		my $ReturnRef = {};

		my ($CarrierName,$ServiceName) = $sth->fetchrow_array();

		$sth->finish();

		return ($CarrierName,$ServiceName);
	}

	sub GetDHLConfigData
	{
		my $self = shift;

		my $sth = $self->{'dbref'}->prepare("
			SELECT
				upper(filename) as filename,
				filesize,
				to_char(filedatetime,'YYMMDD') as filedate,
				to_char(filedatetime,'HHMI') as filetime,
				to_char(effectivedate,'YYYYMMDD') as effectivedate
			FROM
				dhlconfig
			ORDER BY filename
		")
			or die "Could not prepare SQL statement";

		$sth->execute()
			or die "Cannot execute dhlconfig sql statement";

		my @ConfigData = ();


		while ( my $Ref= $sth->fetchrow_hashref() )
		{
			push(@ConfigData,$Ref);

		}

		$sth->finish();

		return (@ConfigData);
	}

	sub CalculateDHLDueDate
	{
		my $self = shift;
		use Date::Calc qw(Day_of_Week);

		my ($Service,$ShipDate,$OriginSAC,$DestinSAC) = @_;
#warn "ONLINE: $Service,$ShipDate,$OriginSAC,$DestinSAC";
		my $DueDate = '';
		my $LabelDueDate='';
		my $HubCode = '';
		my $TerminalCode = '';
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
		return ($DueDate,$LabelDueDate,$HubCode,$TerminalCode);
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

	sub GetDHLUSSAC
	{
		my $self = shift;
		my ($ZipCode,$City,$State) = @_;

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

	sub GetDHLINTLSAC
	{
		my $self = shift;
		my ($ZipCode,$CountryCode,$City,$State) = @_;
#warn "$ZipCode,$CountryCode,$City,$State";
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

	sub HasRequiredAssessorials
	{
		my $self = shift;
		my ($CS,$required_assessorials) = @_;

		my @cs_assessorials = $CS->GetCSAssessorialList();
		my @required_assessorials = split(/,/,$required_assessorials);

		# Check the intersection of our required assessorials with all the CS shippment data
		# (which will include assessorials that a CS has)
		my %original = ();
		my @intersection = ();

		map { $original{$_} = 1 } @required_assessorials;
		@intersection = grep { $original{$_} } @cs_assessorials;

		# If our CS shipment data contains the same assessorials as our required...it's ok to use the CS
		my $compare = Array::Compare->new;
		if ( $compare->compare(\@required_assessorials,\@intersection) )
		{
			return 1;
		}
		else
		{
			return 0;
		}
	}

	sub GetTotalAssCost
	{
		my $self = shift;
		my ($CS,$required_asses,$agg_weight,$total_quantity,$cost,$customerid) = @_;
#warn "ONLINE IN GetTotalAssCost customerid=$customerid";

		my $total_ass_cost = 0;

		my @asses = split(/,/,$required_asses);

		foreach my $ass (@asses)
		{
#warn "ONLINE IN GetTotalAssCost foreach ass=$ass";

			my $ass_cost = $CS->GetAssValue('ar',$ass,$agg_weight,$total_quantity,$cost,undef,undef,$customerid);

			$total_ass_cost += $ass_cost if $ass_cost;
		}

		return $total_ass_cost;
	}
}

1
