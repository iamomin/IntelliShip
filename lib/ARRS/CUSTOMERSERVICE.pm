package ARRS::CUSTOMERSERVICE;

use strict;

use ARRS::DBOBJECT;
@ARRS::CUSTOMERSERVICE::ISA = ("ARRS::DBOBJECT");

use ARRS::AIRPORTTRANSIT;
use ARRS::COMMON;
use ARRS::CSOVERRIDE;
use ARRS::RATETYPE;
use ARRS::SERVICE;
use ARRS::ZIPMILEAGE;
use ARRS::ZONE;
use ARRS::ZONETYPE;
use POSIX qw(ceil);
use Date::Manip qw(Date_GetPrev DateCalc);
use IntelliShip::MyConfig;

my $Benchmark = 0;
my $BenchCSID = 'MAERSKDUGAN01';
my $config = IntelliShip::MyConfig->get_ARRS_configuration;

sub new
	{
		my $proto = shift;
		my $class = ref($proto) || $proto;

		my $self = $class->SUPER::new(@_);

		$self->{'object_tablename'} = 'customerservice';
		$self->{'object_primarykey'} = 'customerserviceid';
		$self->{'object_fieldlist'} = ['customerserviceid','zonetypeid','ratetypeid','serviceid','customerid','webusername','webpassword','webaccount', 'logicnumber', 'meternumber','fscrate','dimfactor','decvalinsrate','decvalinsmin','decvalinsmax','decvalinsmincharge','freightinsrate','freightinsincrement','decvalinsmaxperlb','carrieremail','pickuprequest','servicetypeid','allowcod','valuedependentrate','codfee','collectfreightcharge','guaranteeddelivery','saturdaysunday','liftgateservice','podservice','constructionsite','insidepickupdelivery','singleshipment','thirdpartyacct','aggregateweightcost','callforappointment','discountpercent','manifested','weekendupcharge','amc','sattransit','suntransit','maxtruckweight','alwaysshow','modetypeid'];

		bless($self, $class);
		return $self;
	}

sub GetZoneNumber
	{
		my $self = shift;
		my ($FromZip, $ToZip, $FromState, $ToState, $FromCountry, $ToCountry) = @_;

		# Check if this zone is exluded from the customerservice/service
		if
		(
			$self->ZoneIsExcluded($FromZip,$FromState) ||
			$self->ZoneIsExcluded($ToZip,$ToState)
		)
		{
			return undef;
		}

		# THIS IS A KLUDGE...INT'L SHIPPING IS BROKEN WITHOUT IT ATM.  FIX IT!
		# Basicaly, prices come up ok from shiporder to shipconfirm, but shipconfirm
		# to screen handler loses the From Country.
		if ( !defined($FromCountry) || $FromCountry eq '' ) { $FromCountry = 'US' }

		my $ZoneNumber = '';
		my $zonetypeid = $self->GetValueHashRef()->{'zonetypeid'};

		my $TransitTime = undef;

		if ( defined($zonetypeid) && $zonetypeid ne '' )
		{
			my $ZoneType = new ARRS::ZONETYPE($self->{'object_dbref'}, $self->{'object_contact'});
			$ZoneType->Load($zonetypeid);
			my $lookuptype = $ZoneType->GetValueHashRef()->{'lookuptype'};

			# Make sure we have all the right data for the zone lookup - if not, return undef
			# Zip Lookup
			if
			(
				defined($lookuptype) && $lookuptype eq '1'
				&&
				(
					!defined($FromZip) || $FromZip eq '' ||
					!defined($ToZip) || $ToZip eq ''
				)
			)
			{
				return undef;
			}
			# State Lookup
			elsif
			(
				defined($lookuptype) && $lookuptype eq '2'
				&&
				(
					!defined($FromState) || $FromState eq '' ||
					!defined($ToState) || $ToState eq ''
				)
			)
			{
				return undef;
			}
			# Country Lookup
			elsif
			(
				defined($lookuptype) && $lookuptype eq '3'
				&&
				(
					!defined($FromCountry) || $FromCountry eq '' ||
					!defined($ToCountry) || $ToCountry eq ''
				)
			)
			{
				return undef;
			}

			# 'Normal' zones
			if ( defined($lookuptype) && $lookuptype < '1000' )
			{
				my $SQLString = "
					SELECT
						zonenumber,
						transittime
					FROM
						zone z
					WHERE
						z.typeid = '$zonetypeid' AND
				";

				# State based zones
				if ( defined($lookuptype) && $lookuptype eq '2' )
				{
					$SQLString .= "
						z.originstate = '$FromState' AND
						z.deststate = '$ToState'
					";
				}
				# Country based zones
				elsif ( defined($lookuptype) && $lookuptype eq '3' )
				{
					$SQLString .= "
						z.origincountry = '$FromCountry' AND
						z.destcountry = '$ToCountry'
					";
				}
				# Hybrid postalcode/country based zones (first try postal, then try country)
				elsif ( defined($lookuptype) && $lookuptype eq '4' )
				{
					$FromCountry = $FromCountry ? $FromCountry : '';
					$ToCountry = $ToCountry ? $ToCountry : '';

					$SQLString = "
						SELECT
							coalesce(
								(
									SELECT
										zonenumber
									FROM
										zone z
									WHERE
										z.typeid = '$zonetypeid' AND
										z.originbegin <= '$FromZip' AND
										z.originend >= '$FromZip' AND
										z.destbegin <= '$ToZip' AND
										z.destend >= '$ToZip' AND
										z.origincountry = '$FromCountry' AND
										z.destcountry = '$ToCountry'
								), (
									SELECT
										zonenumber
									FROM
										zone z
									WHERE
										z.typeid = '$zonetypeid' AND
										z.originbegin IS NULL AND
										z.originend IS NULL AND
										z.destbegin IS NULL AND
										z.destend IS NULL AND
										z.origincountry = '$FromCountry' AND
										z.destcountry = '$ToCountry'
								)
							)
					";
				}
				# Hybrid postalcode/state based zones - with exclusionairy capability (0 zone value for exclusion)
				elsif ( defined($lookuptype) && $lookuptype eq '5' )
				{
					$SQLString = "
						SELECT
							coalesce(
								(
									SELECT
										zonenumber
									FROM
										zone z
									WHERE
										z.typeid = '$zonetypeid' AND
										z.originbegin <= '$FromZip' AND
										z.originend >= '$FromZip' AND
										z.destbegin <= '$ToZip' AND
										z.destend >= '$ToZip' AND
										z.originstate = '$FromState' AND
										z.deststate = '$ToState'
								), (
									SELECT
										zonenumber
									FROM
										zone z
									WHERE
										z.typeid = '$zonetypeid' AND
										z.originbegin IS NULL AND
										z.originend IS NULL AND
										z.destbegin IS NULL AND
										z.destend IS NULL AND
										z.originstate = '$FromState' AND
										z.deststate = '$ToState'
								)
							)
					";
				}
				# Postalcode based zones
				else
				{
					$SQLString .= "
						z.originbegin <= '$FromZip' AND
						z.originend >= '$FromZip' AND
						z.destbegin <= '$ToZip' AND
						z.destend >= '$ToZip'
					";
				}
	#warn $SQLString if $self->GetValueHashRef()->{'customerserviceid'} eq 'TOTALTRANSPO1';
	#warn $SQLString;
				my $sth = $self->{'object_dbref'}->prepare($SQLString)
					or die "Could not prepare SQL statement";

				$sth->execute()
					or die "Cannot execute sql statement";

				($ZoneNumber,$TransitTime) = $sth->fetchrow_array();

				$ZoneNumber = !$ZoneNumber ? undef : $ZoneNumber;
			}

			# Weird stuff (carrier/service specific, etc)
			if ( defined($lookuptype) && $lookuptype eq '1000' )
			{
				my $AirportTransit = new ARRS::AIRPORTTRANSIT($self->{'object_dbref'}, $self->{'object_contact'});

			unless
			(
				$ZoneNumber =
					$AirportTransit->GetAirportToAirportTransitTime(
					$FromZip,
					$ToZip,
					'0000000000004',
					'bax',
					0
					)
			)
				{
					undef($ZoneNumber);
				}
			}

			if ( (!defined($ZoneNumber) && $ToState eq 'PR') && ($zonetypeid eq 'FEDEXINTLECON' || $zonetypeid eq 'FEDEXINTLPRIO') )
			{
				$ZoneNumber = 'uspr';
			}
		}
		else
		{
			undef($ZoneNumber);
		}
	#warn $ZoneNumber if $self->GetValueHashRef()->{'customerserviceid'} eq 'MAERSKRDWY001';
	#warn "\nzonenumber=$ZoneNumber";
		return ($ZoneNumber,$TransitTime);
	}

sub GetCost
	{
		my $self = shift;
		my ($Weight,$RateTypeID,$FromZip,$ToZip,$FromState,$ToState,$FromCountry,$ToCountry,$Type,$Band,$ZoneNumber,$CWT,$DollarAmount,$Lookuptype,$Quantity,$Unittype,$Automated,$CustomerID,$date) = @_;


		# Get Zone Number, if it's not passed in
		if ( !$ZoneNumber )
		{
			($ZoneNumber) = $self->GetZoneNumber($FromZip, $ToZip, $FromState, $ToState, $FromCountry, $ToCountry);
		}
	#warn "\nGetCost: $Weight,$RateTypeID,$FromZip,$ToZip,$FromState,$ToState,$FromCountry,$ToCountry,$Type,$Band, zone=$ZoneNumber,$CWT,$DollarAmount,$Lookuptype,$Quantity,$Unittype,$Automated,$CustomerID,$date";

		if (!defined($ZoneNumber))
		{
			return (undef, undef);
		}

		# Get Cost
		# At this point, assume everything through here to be ar based - the 'type' (ar/ap) won't come in currently until
		# we get into the ratedata/banddata stuff below.  Other than one piddly entry, no one but Vought has any ap rates in the
		# system atm, so it shouldn't be an issue.  If we do end up needing to rely on ap-centric stuff here, we're going to
		# need 2 'types' - one for use here, one for use below.  Which we'll avoid if we can.  Might look into the feasability
		# of getting rid of the 'type' stuff entirely here, if it looks like we can go more base-rate centric.  Kirk 6/25/2008.
		my $SQLString = "
			SELECT
				arcost,
				arcostmin,
				arcostperwt,
				arcostpermile,
				arcostperunit,
				tier
			FROM
				rate r
			WHERE
				r.zonenumber = '$ZoneNumber' AND
				r.typeid = '$RateTypeID' AND
		";

		# Quantity based rating
		if ( $Lookuptype && $Lookuptype == 2 )
		{
			$Quantity = defined($Quantity) && $Quantity != 0 ? $Quantity : 1;
			$SQLString .= "
				r.unitsstart <= $Quantity AND
				r.unitsstop >= $Quantity
			";
		}
		# Normal weight based rating
		else
		{
			$SQLString .= "
				r.unitsstart <= $Weight AND
				r.unitsstop >= $Weight
			";
		}

		if ( $Unittype )
		{
			$SQLString .= "
				AND ( r.unittype = $Unittype or r.unittype IS NULL )
			";
		}

		# Hack so we can get proper CWT rating for HALO est AP.  This will likely have to be used by and/or
		# expanded on by the normal rating process...If we've got normal rate and cwt rate overlap, it
		# can have two records for the same ratetype/zone/weight...
		if ( defined($CWT) && $CWT == 0 )
		{
			$SQLString .= "
				AND r.arcost IS NOT NULL
			";
		}
		elsif ( defined($CWT) && $CWT == 1 )
		{
			$SQLString .= "
				AND r.arcostperwt IS NOT NULL
			";

			# If we're a UPS CWT, we need to get our CWT tier
			my $Service = new ARRS::SERVICE($self->{'object_dbref'}, $self->{'object_contact'});
			$Service->Load($self->GetValueHashRef()->{'serviceid'});
			if ( $Service->GetValueHashRef()->{'carrierid'} eq '0000000000003' )
			{
				my $CSOverride = new ARRS::CSOVERRIDE($self->{'object_dbref'}, $self->{'object_contact'});
				# Assume we *must* have a tier for UPS cwt rating
				if
				(
					$CSOverride->LowLevelLoadAdvanced(undef,{
						customerid		=> $CustomerID,
						customerserviceid => $self->GetValueHashRef()->{'customerserviceid'},
						datatypename	=> 'cwttier',
					})
				)
				{
					my $tier = $CSOverride->GetValueHashRef()->{'value'};

					$SQLString .= "
						AND r.tier = '$tier'
					";
				}
				# Otherwise, don't rate
				else
				{
					return (undef, undef);
				}
			}
		}

		if ( $date )
		{
			$SQLString .= "
				AND
					(
						( startdate <= date('$date') AND stopdate  >= date('$date') )
						OR
						( startdate IS NULL AND stopdate IS NULL )
					)
			";
		}

		$SQLString .= "
			ORDER BY
				startdate DESC,
				stopdate DESC
			LIMIT 1
		";
	#warn $SQLString;
	#warn $SQLString if $self->GetValueHashRef()->{'customerserviceid'} eq 'TOTALTRANSPO1';
		my $sth = $self->{'object_dbref'}->prepare($SQLString)
			or die "Could not prepare SQL statement";

		$sth->execute()
			or die "Cannot execute sql statement";

		my ($CostRef) = $sth->fetchrow_hashref();
	#WarnHashRefValues($CostRef);
		my $Cost;

		# CS has per lb rate + a flat cost (surcharge)
		if ( defined($CostRef->{'arcost'}) && defined($CostRef->{'arcostperwt'}) )
		{
			$Cost = $CostRef->{'arcost'} + ($CostRef->{'arcostperwt'} * $Weight);
		}
		# CS has a flat cost
		elsif ( defined($CostRef->{'arcost'}) )
		{
			$Cost = $CostRef->{'arcost'};
		}
		# CS has a per lb cost
		elsif ( defined($CostRef->{'arcostperwt'}) )
		{
			$Cost = $CostRef->{'arcostperwt'} * $Weight;
		}
		# CS has a per unit cost
		elsif ( defined($CostRef->{'arcostperunit'}) )
		{
			$Cost = $CostRef->{'arcostperunit'} * $Quantity;
	#warn "\ncost=$Cost per=$CostRef->{'arcostperunit'} qty=$Quantity";
		}
		# CS has a mileage based cost
		elsif ( defined($CostRef->{'arcostpermile'}) )
		{
			my $ZipMileage = new ARRS::ZIPMILEAGE($self->{'object_dbref'}, $self->{'object_contact'});

			my $ZipToZipMileage = $ZipMileage->GetMileage($FromZip,$ToZip);
	#warn "\ncs mileage/cost: mileage: $ZipToZipMileage  arcostpermile: $CostRef->{'arcostpermile'}";

			$Cost = $CostRef->{'arcostpermile'} * $ZipToZipMileage;
			$ZoneNumber = $ZipToZipMileage;
	#warn "\nCost: $Cost  ZoneNumber: $ZoneNumber";
		}
		else
		{
			undef($Cost);
		}

		if (defined($Cost))
		{
			# Check for rate percentage modifications and mins
			$Type = DefaultTo($Type,'ar');

	#warn "\n$self->{'field_customerserviceid'}|$Type|$Band" if $self->GetValueHashRef()->{'customerserviceid'} eq 'PGLFEDEX00004';
			# It is possible to pass in a band of 0, which is valid, but not true.
			# It should not try and get a default at that point.
			# A 0 band is meant to imply base rates.  It should trick the system into not doing
			# any other band ideas.
			if ( !defined($Band) || $Band eq '' )
			{
				if ( $DollarAmount )
				{
					$Band = $self->GetBand($Type,$DollarAmount,$date);
				}
				else
				{
					$Band = !$CWT ? $self->GetCSValue('defaultband') : $self->GetCSValue('defaultcwtband');
				}
			}

	#warn "\n$self->{'field_customerserviceid'}|$Type|$Band" if $self->GetValueHashRef()->{'customerserviceid'} eq 'MHEFEDEXES000';
			# If we're passed a 0 band, we do indeed not want to go here
			if ( $Band )
			{
				my ($DiscountPercent,$Min) = $self->GetRateData($Type,$Band,$Weight,$ZoneNumber,$CustomerID,$date,$CWT,$FromCountry,$ToCountry);
	#warn "\n$self->{'field_customerserviceid'}|$Type|$Band|$Cost|$DiscountPercent|$Min|$CWT" if $self->GetValueHashRef()->{'customerserviceid'} eq 'TOTALTRANSPO1';

				# If this isn't an AOS shipment, and the CS has a non-AOS penalty, then subract the penalty
				# from the percent.
				if ( !$Automated && ( my $DiscountPenalty = $self->GetCSValue('nonautomationpenalty') ) )
				{
					$DiscountPercent = $DiscountPercent - $DiscountPenalty;
				}

				if ( $DiscountPercent )
				{
					$Cost = $Cost * (1 - $DiscountPercent);
				}

				if ( $Min && $Min > $Cost )
				{
					$Cost = $Min;
				}
	#warn "\n$self->{'field_customerserviceid'}|$Type|$Band|$Cost|$DiscountPercent|$Min|$CWT" if $self->GetValueHashRef()->{'customerserviceid'} eq 'PGLFEDEX00001';
	#warn "\n$self->{'field_customerserviceid'}|$Type|$Band|$Cost|$DiscountPercent|$Min|$CWT";
			}
	#warn "\nADD MIN IF $CostRef->{'arcostmin'}";
			# Figure out normal (old) style minimums
			if ( defined($CostRef->{'arcostmin'}) && $CostRef->{'arcostmin'} > 0 && $CostRef->{'arcostmin'} > $Cost )
			{
				$Cost = $CostRef->{'arcostmin'};
			}

			$Cost = sprintf("%02.2f", $Cost);
	#warn "\nADDED MIN $Cost"
		}

		# Get Truckload max weight and see if the price needs to be bumped up for multiple trucks
	my $TLMaxWeight = $self->GetCSValue('maxtruckweight');

		if ( defined($Cost) && defined($Weight) && $TLMaxWeight > 0 )
		{
			my $TruckCount = $Weight / $TLMaxWeight;
			$TruckCount = ceil($TruckCount);

			$Cost = $Cost * $TruckCount;
		}

	#warn "\nGetCost returning: $Cost";

		return ($Cost, $ZoneNumber);
	}

sub GetShipmentCosts
	{
		my $self = shift;
		my ($ShipmentRef) = @_;
		#WarnHashRefValues($ShipmentRef);
		# Check if this CS/Service is inactive...if it is, return *immediately*
		return(undef,undef,undef) if $self->GetCSValue('inactive');
		#warn "\nGetShipmentCosts";
		my $AggregateWeight = 0;
		my $Cost;
		my $CostWeight;
		my $Zone = 0;
		my $PackageCosts = '';
		my $TransitDays = 0;

		# Bust various costing strings into arrays for ease of use.
		my @DimLengths = $self->BuildArrayFromJSString($ShipmentRef->{'dimlengthlist'});
		my @DimWidths = $self->BuildArrayFromJSString($ShipmentRef->{'dimwidthlist'});
		my @DimHeights = $self->BuildArrayFromJSString($ShipmentRef->{'dimheightlist'});
		my @Weights = $self->BuildArrayFromJSString($ShipmentRef->{'weightlist'});
		my @Quantities = $self->BuildArrayFromJSString($ShipmentRef->{'quantitylist'});
		my @UnitTypes = $self->BuildArrayFromJSString($ShipmentRef->{'unittypelist'});
		my @DataTypes = $self->BuildArrayFromJSString($ShipmentRef->{'datatypeidlist'});

		my @DimWeights = ();
		#warn $ShipmentRef->{'useaggweight'} if exists($ShipmentRef->{'useaggweight'});
		my $UseAggregateWeight = exists($ShipmentRef->{'useaggweight'}) ? $ShipmentRef->{'useaggweight'} : $self->GetCSValue('aggregateweightcost');
		#warn "\npulled from CS (useaggweight): $UseAggregateWeight" if $self->GetValueHashRef()->{'customerserviceid'} eq 'TOTALTRANSPO1';
		#my $FSCRate = $self->GetCSValue('fscrate');
		#(undef,undef,undef,undef,undef,my $FSCRate) = $self->GetAssData('ar','fscrate');
		#my ($type,$ass_name,$weight,$quantity,$freight_cost,$date_shipped,$ownertypeid,$customerid) = @_;

		(my $FSCRate) = $self->GetAssValue('ar','fscrate',undef,undef,undef,undef,undef,$ShipmentRef->{'customerid'});
		$FSCRate = $FSCRate ? $FSCRate : 0;

		my $CWT;
		my $TotalQuantity = 0;
		my $UnitType;
		my $DataType;
		#warn "\nproductcount = $ShipmentRef->{'productcount'} FSC = $FSCRate";
		# Iterate through product list
		if ( defined($ShipmentRef->{'productcount'}) && $ShipmentRef->{'productcount'} ne '' )
		{
			# If shipment quantity is over max or under min, return undef
			for ( my $i = 0; $i < scalar(@Quantities); $i ++ )
			{
				# Skip products
				next if ( $DataTypes[$i] && $DataTypes[$i] == 2000 );

				# Add packages
				$TotalQuantity += $Quantities[$i];
			}

			# Figure out unittype - make sure it's the same for all products (or unittype routing is not possible)
			my $ut_ref = {};
			for ( my $i = 0; $i < scalar(@UnitTypes); $i ++ )
			{
				# Skip products
				next if ( $DataTypes[$i] && $DataTypes[$i] == 2000 );

				$ut_ref->{$UnitTypes[$i]} = 1;
				$UnitType = $UnitTypes[$i];
			}
			$UnitType = scalar(keys(%$ut_ref)) == 1 ? $UnitType : undef;
			#warn "\nCS UnitType=$UnitType" if $self->GetValueHashRef()->{'customerserviceid'} eq 'TOTALTRANSPO1';

			my $MaxQuantity = $self->GetCSValue('maxquantity');
			my $MinQuantity = $self->GetCSValue('minquantity');

			if ( $MaxQuantity && $TotalQuantity > $MaxQuantity ) { return(undef,undef,undef) }
			if ( $MinQuantity && $TotalQuantity < $MinQuantity ) { return(undef,undef,undef) }
			# Build weight up for aggregate calcs - this works for both 'product' and 'package' paradigms
			if ( $UseAggregateWeight )
			{
				for ( my $i = 0; $i < $ShipmentRef->{'productcount'}; $i ++ )
				{
					# Skip products
					next if ( $DataTypes[$i] && $DataTypes[$i] == 2000 );
					$DimWeights[$i] = $self->GetDimWeight($DimLengths[$i],$DimWidths[$i],$DimHeights[$i]);
				}

				$AggregateWeight = $self->GetAggregateWeight(\@Weights,\@DimWeights,\@Quantities,\@DataTypes,$ShipmentRef->{'productcount'},$ShipmentRef->{'quantityxweight'});
			}

			# If any single package is > max package weight or < min package weight, return undef
			my $MaxPackageWeight = $self->GetCSValue('maxpackageweight');
			my $MinPackageWeight = $self->GetCSValue('minpackageweight');

			for ( my $i = 0; $i < $ShipmentRef->{'productcount'}; $i ++ )
			{
				# Skip products
				next if ( $DataTypes[$i] && $DataTypes[$i] == 2000 );

				my $Weight = !defined($DimWeights[$i]) || $Weights[$i] >= $DimWeights[$i] ? $Weights[$i] : $DimWeights[$i];
				if ( $MaxPackageWeight && $Weight > $MaxPackageWeight ) { return(undef,undef,undef) }
				if ( $MinPackageWeight && $Weight < $MinPackageWeight ) { return(undef,undef,undef) }
			}

			#warn "\nCS AggWeight (before flip check)" . $AggregateWeight if $self->GetValueHashRef()->{'customerserviceid'} eq 'TOTALTRANSPO1';
			# Set flag to use aggregate weight in calcs or not - this new nonsense deals with hybrid type cases, that flip from non-agg
			# to agg (like small pack that're non-agg until they hit CWT status)
			if ( $UseAggregateWeight > 1 )
			{
				#warn "\nin if useaggweight > 1..." if $self->GetValueHashRef()->{'customerserviceid'} eq 'TOTALTRANSPO1';
				# If agg weight < min agg weight, go back to non-agg calcs
				my $MinAggWeight = $self->GetCSValue('minaggweight');

				#warn "\nMinAggWeight = $MinAggWeight  AggWeight = $AggregateWeight" if $self->GetValueHashRef()->{'customerserviceid'} eq 'TOTALTRANSPO1';
				if ( !$MinAggWeight || $AggregateWeight < $MinAggWeight || $TotalQuantity == 1 )
				{
				#warn "\nUnset AggWeightFlag... go back to regular calc!!!" if $self->GetValueHashRef()->{'customerserviceid'} eq 'TOTALTRANSPO1';

					$UseAggregateWeight = 0
				}
				else
				{
					# Explicitly set packages for CWT rating
					$CWT = 1;

					# Hack for inconsistent (non cost per wt base) AP CWT ground
					undef($CWT) if $self->GetValueHashRef()->{'customerserviceid'} eq 'APCFEDEXGRND1';
				}
			}
			#warn "\n$self->{'field_customerserviceid'}|$UseAggregateWeight|$CWT" if $CWT;
			#warn "\n$self->{'field_customerserviceid'}|$UseAggregateWeight|" if !$CWT;
			# Get costs for non agg situations
			if ( !$UseAggregateWeight )
			{
			#warn "\nCS useaggregate=$UseAggregateWeight" if $self->GetValueHashRef()->{'customerserviceid'} eq 'TOTALTRANSPO1';

				($Cost,$Zone,$PackageCosts,$CostWeight,$TransitDays) = $self->GetPackageCosts(\@Weights,\@Quantities,\@DimLengths,\@DimWidths,\@DimHeights,\@DataTypes,$ShipmentRef);

			#warn "\nCS GetPackageCosts returned cost=$Cost";

			}
		}

		# Get aggregate cost and build JS array for aggregate calcs
		if ( $UseAggregateWeight )
		{
			if ( !defined($AggregateWeight) || $AggregateWeight eq '' || $AggregateWeight < 0 )
			{
				return(undef,undef,undef);
			}

			($Cost,$Zone,$CostWeight,$TransitDays) = $self->GetSuperCost($AggregateWeight,undef,undef,undef,$ShipmentRef,$CWT,$TotalQuantity,$UnitType);
			#warn "\nHERE: $Cost,$Zone,$CostWeight,$TransitDays";
			#warn "\nCS UseAggregateWeight: " . $UseAggregateWeight . " " . $Cost if $self->GetValueHashRef()->{'customerserviceid'} eq 'TOTALTRANSPO1';
			#warn $Cost if $self->GetValueHashRef()->{'customerserviceid'} eq 'TOTALTRANSPO1';

			# Set aggregate weight to '1' if it's 0, to deal with 0 weight packages
			$AggregateWeight = $AggregateWeight > 0 ? $AggregateWeight : 1;

			if ( defined($Cost) && $Cost ne '' && $Cost >= 0 )
			{
			#warn $Cost if $self->GetValueHashRef()->{'customerserviceid'} eq 'TOTALTRANSPO1';
				for ( my $i = 0; $i < $ShipmentRef->{'productcount'}; $i ++ )
				{
					# Skip products
					next if ( $DataTypes[$i] && $DataTypes[$i] == 2000 );

					# If dimcheck fails for any package (basically, dims bigger than we've got pricing for - more-or-less), return undef
					if ( !$self->DimCheck($DimLengths[$i],$DimWidths[$i],$DimHeights[$i]) )
					{
						return(undef,undef,undef,$AggregateWeight);
					}

					my $Weight = $Weights[$i];

					if ( defined($DimWeights[$i]) && $DimWeights[$i] > $Weight )
					{
						$Weight = $DimWeights[$i];
					}

					if ( $ShipmentRef->{'quantityxweight'} || ( $UseAggregateWeight == 2 && scalar(@Quantities) > 1 ) )
					{
						for ( my $j = 1; $j <= $Quantities[$i]; $j ++ )
						{
							my $PackageRatio = ($Weight * $Quantities[$i])/$AggregateWeight;

							# 0 weight shipments won't play well with other shipments (0 weight or otherwise).  There's at this point just no good
							# way to cost them out - we'll have to come up with a better fix for later.  For now, I'm just sort of assuming that 0
							# weight shipments will go by themselves.  Since it's Voyager that's intereseted at the moment, and they use the API
							# only, this is *probably* ok.  Things should ship fine, however. Kirk.
							my $PackageCost = $Weight > 0 ? sprintf("%02.2f",($Cost * $PackageRatio)/$Quantities[$i]) : sprintf("%02.2f",$Cost);
							my $PackageFSCCost = sprintf("%02.2f",$PackageCost * $FSCRate);

							$PackageCosts .= $PackageCost . "-" . $PackageFSCCost . "::";
						}
					}
					else
					{
						my $PackageCost = sprintf("%02.2f",$Cost);
						my $PackageFSCCost = sprintf("%02.2f",$PackageCost * $FSCRate);

						$PackageCosts .= $PackageCost . "-" . $PackageFSCCost . "::";
					}
				}
			}
		}

		# Bolt FSCRate onto the Cost (for use/display in the droplists)
		if ( !$ShipmentRef->{'excludefsc'} && $Cost && $Cost > 0 && $FSCRate && $FSCRate > 0 )
		{
			$Cost = sprintf("%02.2f",($Cost + ($Cost * $FSCRate)));
		}

		#warn "\nCS GetShipmentCosts returning: |$Cost|zone=$Zone|days=$TransitDays|";

		return ($Cost,$Zone,$PackageCosts,$CostWeight,$TransitDays);
	}

sub BuildArrayFromJSString
	{
		my $self = shift;
		my ($String) = @_;
		my @Array = ();

		if ( defined($String) && $String ne '' )
		{
			$String =~ s/'//g;
			@Array = split(/,/,$String);
		}

		return @Array;
	}

sub GetCSValue
	{
		my $self = shift;
		my ($ValueType,$AllowNull,$CustomerID) = @_;
		#warn "\n$ValueType GetCSValue";
		my $Value;

		my $CSID = $self->{'field_customerserviceid'};
		my $ServiceID = $self->{'field_serviceid'};

		# Allow for customer overrides of specific CS values
		my $CSOverride = new ARRS::CSOVERRIDE($self->{'object_dbref'}, $self->{'object_contact'});
		if
		(
			$CSOverride->LowLevelLoadAdvanced(undef,{
				customerid			=>	$CustomerID,
				customerserviceid	=>	$CSID,
				datatypename		=>	$ValueType
			})
		)
		{
			return $CSOverride->GetValueHashRef()->{'value'};
		}

		# Take cs value, if available, then take service value
		if ( $ValueType && $CSID && $ServiceID )
		{
			my $SQL = "
				SELECT
					coalesce
					(
						(SELECT value FROM servicecsdata WHERE ownerid = '$CSID' AND ownertypeid = 4 AND datatypename = '$ValueType' LIMIT 1),
						(SELECT value FROM servicecsdata WHERE ownerid = '$ServiceID' AND ownertypeid = 3 AND datatypename = '$ValueType' LIMIT 1)
					)
			";

			my $STH = $self->{'object_dbref'}->prepare($SQL)
			or die "Could not prepare SQL statement";

		$STH->execute()
			or die "Cannot execute sql statement";

			($Value) = $STH->fetchrow_array();

			$STH->finish();

			if ( (!defined($Value) || $Value eq '') && $ValueType eq 'webaccount' )
			{
				$Value = $self->{'field_webaccount'};
			}
		}
		else
		{
			my $Missing = '';
			if ( !$ValueType ) { $Missing .= '|ValueType|' }
			if ( !$CSID ) { $Missing .= '|CSID|' }
			if ( !$ServiceID ) { $Missing .= '|Service ID|' }

			TraceBack("Missing Variables: $Missing");
		}

		# If the allow null flag is set and we get no value (not even 0),
		# undef the value before return, if it's null
		if ( ( !defined($Value) || $Value eq '' ) && $AllowNull )
		{
			undef($Value);
		}
		# Otherwise, return 0
		elsif ( !defined($Value) || $Value eq '' )
		{
			$Value = 0;
		}

		return $Value;
	}

sub GetCSShippingValues
	{
		my $self = shift;
		my ($Ref) = @_;

		my $CSID = $Ref->{'csid'};

		my $ShipmentValueRef = {};

		my @ShipmentNoNullValues = qw(
			dimfactor
			decvalinsrate
			decvalinsmin
			decvalinsmax
			freightinsrate
			decvalinsmincharge
			freightinsincrement
			decvalinsmaxperlb
			pickuprequest
			servicetypeid
			allowcod
			valuedependentrate
			cutofftime
			dryice
			arassmarkup
			arfreightmarkup
			aggregateweightcost
		);

		my @ShipmentNullValues = qw(
			codfee
			collectfreightcharge
			guaranteeddelivery
			saturdaysunday
			liftgateservice
			podservice
			constructionsite
			insidepickupdelivery
			singleshipment
			callforappointment
			collectfreightcharge
			thirdpartyfreightcharge
			requirecollectaddress
			requirethirdpartyaddress
			webaccount
			meternumber
			displayhandler
			webhandlername
			baaddressid
		);

		my $CSIDLoaded = 0;
		if ( $self->Load($CSID) ) { $CSIDLoaded = 1; }

		foreach my $ValueType (@ShipmentNoNullValues)
		{
			if ( $CSIDLoaded )
			{
				$ShipmentValueRef->{$ValueType} = $self->GetCSValue($ValueType,undef,$Ref->{'customerid'});
			}
			else
			{
				$ShipmentValueRef->{$ValueType} = 0;
			}
		}

		foreach my $ValueType (@ShipmentNullValues)
		{
			if ( $CSIDLoaded )
			{
				my $Value = $self->GetCSValue($ValueType,1,$Ref->{'customerid'});
				$ShipmentValueRef->{$ValueType} = defined($Value) ? $Value : "";
			}
			else
			{
				$ShipmentValueRef->{$ValueType} = "";
			}
		}

		# FSC is in assessorials now...needs to be grabbed from there
		#(undef,undef,undef,undef,undef,$ShipmentValueRef->{'fscrate'}) = $self->GetAssData('ar','fscrate',$Ref->{'dateshipped'});
		($ShipmentValueRef->{'fscrate'}) = $self->GetAssValue('ar','fscrate',undef,undef,undef,undef,undef,$Ref->{'customerid'});
		$ShipmentValueRef->{'fscrate'} = $ShipmentValueRef->{'fscrate'} ? $ShipmentValueRef->{'fscrate'} : 0;
		#WarnHashRefValues($ShipmentValueRef) if $CSID eq 'TOTALTRANSPO1';
		return $ShipmentValueRef;
	}

sub GetCSJSArrays
	{
		my $self = shift;
		my ($Ref) = @_;

		my @CSIDs = split(/\t/,$Ref->{'csids'});
		unshift(@CSIDs,0);

		my $ShipmentValueRef = {};

		my @ShipmentValues = qw(inboundcapable modetypeid dropshipcapable defaultexclude);

		foreach my $CSID (@CSIDs)
		{
			my $CSIDLoaded = 0;
			if ( $self->Load($CSID) ) { $CSIDLoaded = 1; }

			foreach my $ValueType (@ShipmentValues)
			{
				if ( $CSIDLoaded )
				{
					my $Value = $self->GetCSValue($ValueType);
					$ShipmentValueRef->{"${ValueType}_list"} .= "'$Value',";
				}
				else
				{
					$ShipmentValueRef->{"${ValueType}_list"} .= "'0',";
				}
			}
		}

		foreach my $ValueType (@ShipmentValues)
		{
			chop($ShipmentValueRef->{"${ValueType}_list"});
		}

		return $ShipmentValueRef;
	}

sub GetDimWeight
	{
		my $self = shift;
		my ($DimLength,$DimWidth,$DimHeight) = @_;
		my $DimWeight;

		my $DimFactor = $self->GetCSValue('dimfactor');
		my $ServiceID = $self->GetValueHashRef()->{'serviceid'};

		#warn "\nGetDimWeight dimfactor=$DimFactor ServiceID=$ServiceID";
		my $Handler = $self->GetCarrierHandler();

		unless ( ($DimWeight) = $Handler->GetDimWeight($DimLength,$DimWidth,$DimHeight,$DimFactor,$ServiceID) )
			{
			undef($DimWeight);
			}
		#warn "\ndimweight returning |$DimWeight|";

		return $DimWeight;
	}

sub DimCheck
	{
		my $self = shift;
		my ($DimLength,$DimWidth,$DimHeight) = @_;

		my $Handler = $self->GetCarrierHandler();

		return $Handler->DimCheck($DimLength,$DimWidth,$DimHeight,$self->GetValueHashRef()->{'serviceid'});
	}

sub GetCarrierHandler
	{
	my $self = shift;

	my $Service = new ARRS::SERVICE($self->{'object_dbref'}, $self->{'object_contact'});
	$Service->Load($self->GetValueHashRef()->{'serviceid'});

	my $HandlerName = $Service->GetValueHashRef()->{'webhandlername'} || '';
	my $Handler;
	#warn "\nGetCarrierHandler handlername=$HandlerName at sevice level webhandlername";
	#if ( defined($HandlerName) && $HandlerName ne '' && -r "$config->{BASE_PATH}/lib/ARRS/$HandlerName" )
	if (length $HandlerName)
		{
		#warn "\npassed require of $config->{BASE_PATH}/lib/ARRS/$HandlerName";
		$HandlerName =~ s/\.pl//;
		$HandlerName = "ARRS::$HandlerName";

		#warn "\n[GetCarrierHandler] HandlerName: $HandlerName";
		eval "use $HandlerName;";

		if ($@)
			{
			#warn "\n[Error] GetCarrierHandler eval Exception: $@";
			warn "\n[Warn] Handler '$HandlerName' not found [CUSTOMERSERVICE]";
			# other exception handling goes here...
			}
		else
			{
			$Handler = $HandlerName->new($self->{"dbref"}, $self->{"contact"});
			#warn "\ndone with eval";
			}
		}

	unless ($Handler)
		{
		use ARRS::CARRIERHANDLER;
		$Handler = new ARRS::CARRIERHANDLER($self->{'dbref'},$self->{'contact'});
		}

	return $Handler;
	}

sub GetCarrierScac
	{
		my $self = shift;

		my $Service = new ARRS::SERVICE($self->{'object_dbref'}, $self->{'object_contact'});
		$Service->Load($self->GetValueHashRef()->{'serviceid'});

		my $Carrier = new ARRS::CARRIER($self->{'object_dbref'}, $self->{'object_contact'});
		$Carrier->Load($Service->GetValueHashRef()->{'carrierid'});

		my $scac = $Carrier->GetValueHashRef()->{'scac'};

		return $scac;
	}

sub GetCarrierServiceName
	{
		my $self = shift;
		my ($CustomerServiceID) = @_;

		my $SQL = "
			SELECT
				c.carriername,
				s.servicename
			FROM
				customerservice cs,
				service s,
				carrier c
			WHERE
				cs.serviceid = s.serviceid
				AND s.carrierid = c.carrierid
				AND cs.customerserviceid = ?
		";

		my $STH = $self->{'object_dbref'}->prepare($SQL)
		or die "Could not prepare SQL statement";

		$STH->execute($CustomerServiceID)
		or die "Cannot execute SQL statement";

		my ($CarrierName,$ServiceName) = $STH->fetchrow_array();

		$STH->finish();

		return ($CarrierName,$ServiceName);
	}

sub GetAggregateWeight
	{
		my $self = shift;
		my ($Weights,$DimWeights,$Quantities,$DataTypes,$Count,$QuantityXWeight) = @_;
		my @Weights = @$Weights;
		my @DimWeights = @$DimWeights;
		my @Quantities = @$Quantities;
		my @DataTypes = @$DataTypes;

		my $AggregateWeight = 0;

		for ( my $i = 0; $i < $Count; $i ++ )
		{
			# Skip products
			next if ( $DataTypes[$i] && $DataTypes[$i] == 2000 );

			my $Weight = $Weights[$i];

			if ( !defined($Weight) || $Weight eq '' ) { return undef }

			local $^W=0;
			if ( $QuantityXWeight )
			{
				$Weight = $Weight * $Quantities[$i];
			}
			local $^W=1;

			# Dim weight is always modified by quantity now.
			if ( defined($DimWeights[$i]) && $DimWeights[$i] > 0 )
			{
				$DimWeights[$i] = $Quantities[$i] > 0 ? $DimWeights[$i] * $Quantities[$i] : $DimWeights[$i];
				if ( $DimWeights[$i] > $Weight )
				{
					$Weight = $DimWeights[$i];
				}
			}

			$AggregateWeight += $Weight;
		}

		return $AggregateWeight;
	}

sub GetPackageCosts
	{
		my $self = shift;

		my ($Weights,$Quantities,$DimLengths,$DimWidths,$DimHeights,$DataTypes,$ShipmentRef,$RateHandlerName) = @_;
		my @Weights = @$Weights;
		my @Quantities = @$Quantities;
		my @DimLengths = @$DimLengths;
		my @DimWidths = @$DimWidths;
		my @DimHeights = @$DimHeights;
		my @DataTypes = @$DataTypes;

		my $Cost;
		my $Zone = 0;
		my $PackageCosts = '';
		my $TransitDays = 0;

		#my $FSCRate = $self->GetCSValue('fscrate');
		#(undef,undef,undef,undef,undef,my $FSCRate) = $self->GetAssData('ar','fscrate');
		(my $FSCRate) = $self->GetAssValue('ar','fscrate',undef,undef,undef,undef,undef,$ShipmentRef->{'customerid'});

		$FSCRate = $FSCRate ? $FSCRate : 0;
		#warn "\nFSCRATE=$FSCRate" if $self->GetValueHashRef->{'customerserviceid'} eq 'EFREIGHTDYLT0';

		my $CostWeight = 0;

		my $NullCost = 0;
		my $ZeroCost = 0;

		for ( my $i = 0; $i < $ShipmentRef->{'productcount'}; $i ++ )
		{
			# Skip products
			next if ( $DataTypes[$i] && $DataTypes[$i] == 2000 );

			my $PackageCost;
			my $PackageWeight;
			my $PackageCostWeight = 0;
			#warn "\nGetPackageCosts() each weight: $Weights[$i]" if $self->GetValueHashRef->{'customerserviceid'} eq 'TOTALTRANSPO1';

			if ( $ShipmentRef->{'quantityxweight'} )
			{
				$PackageWeight = $Weights[$i];
			}
			else
			{
				if ( defined($Quantities[$i]) && $Quantities[$i] > 0 )
				{
					$PackageWeight = ceil($Weights[$i]/$Quantities[$i]);
				}
				else
				{
					$PackageWeight = ceil($Weights[$i]);
				}
			}

			($PackageCost,$Zone,$PackageCostWeight,$TransitDays) = $self->GetSuperCost($PackageWeight,$DimLengths[$i],$DimWidths[$i],$DimHeights[$i],$ShipmentRef);
			#warn "\nHERE PACKAGE: $PackageCost,$Zone,$PackageCostWeight,$TransitDays";
			#warn "\nPackageCost=$PackageCost TransitDays=$TransitDays" if $self->GetValueHashRef()->{'customerserviceid'} eq 'TOTALTRANSPO1';

			# If we get a package cost & zone back that're both undef...the shipment can't use this service.
			if ( !$PackageCost && !$Zone )
			{
				$NullCost = 1;
			}
			# If we get a package back with 0 cost...the shipment has to go quote.
			elsif ( defined($PackageCost) && $PackageCost == 0 )
			{
				$ZeroCost = 1;
			}

			if ( $PackageCostWeight )
			{
				$CostWeight += $PackageCostWeight * $Quantities[$i];
			}

			if ( defined($PackageCost) && $PackageCost ne '' && $PackageCost >= 0 && !$NullCost && !$ZeroCost )
			{
				$Cost += $PackageCost * $Quantities[$i];

				for ( my $j = 1; $j <= $Quantities[$i]; $j ++ )
				{
					$PackageCost = sprintf("%02.2f",$PackageCost);
					my $PackageFSCCost = sprintf("%02.2f",$PackageCost * $FSCRate);
					#warn "\nGOTIT: |$PackageCost|$PackageFSCCost|";

					$PackageCosts .= $PackageCost . "-" . $PackageFSCCost . "::";
				}
			}
			else
			{
				if ( $NullCost )
				{
					undef($Cost);
					undef($Zone);
				}
				elsif ( $ZeroCost )
				{
					$Cost = 0;
				}
			}
		}

		if ( $Cost )
		{
			$Cost = sprintf("%02.2f",$Cost);
		}
		#warn "\nGetPackageCosts returning transit=$TransitDays";
		return($Cost,$Zone,$PackageCosts,$CostWeight,$TransitDays);
	}

sub GetSuperCost
	{
		my $self = shift;
		my ($Weight,$DimLength,$DimWidth,$DimHeight,$ShipmentRef,$CWT,$Quantity,$UnitType) = @_;
		#warn "\nGetSuperCost() Weight: $Weight" if $self->GetValueHashRef->{'customerserviceid'} eq 'TOTALTRANSPO1';
		#WarnHashRefValues($ShipmentRef);
		my $Zone;
		my $Cost = 0;
		my $TransitDays = 0;

		# Calc dim weight - use it if it's higher than the weight
		my $DimWeight = $self->GetDimWeight($DimLength,$DimWidth,$DimHeight);
		my $CostWeight = (defined($DimWeight) && $DimWeight > $Weight) ? $DimWeight : $Weight;

		# If we don't have a ratetype, kick back just the CostWeight
		if ( !$self->GetValueHashRef()->{'ratetypeid'} )
		{
		#warn "\nRETURN 0: no ratetypeid" if $self->GetValueHashRef->{'customerserviceid'} eq 'TOTALTRANSPO1';
			return(undef,undef,$CostWeight);
		}

		# If weight is less than cs min, return undef (assume below the min, service is unavailable)
		# If weight is greater than cs absolute max, return undef
		if
		(
			( $self->GetCSValue('minweight') && $Weight < $self->GetCSValue('minweight') ) ||
			( $self->GetCSValue('maxweightabs') && $Weight > $self->GetCSValue('maxweightabs') )
		)
		{
		#warn "\nRETURN 1: weight";
			return(undef,undef,$CostWeight);
		}

		# If weight is greater than cs max, return 0 (assume above the max, service is available on a 'quote' basis)
		if ( $self->GetCSValue('maxweight') && $Weight > $self->GetCSValue('maxweight') )
		{
		#warn "\nRETURN 2: maxweight";
			return(0,0,$CostWeight);
		}

		# If dimcheck fails (basically, dims bigger than we've got pricing for - more-or-less), return undef
		if ( !$self->DimCheck($DimLength,$DimWidth,$DimHeight) )
		{
		#warn "\nRETURN 3: dims";
			return(undef,undef,undef);
		}

		# Sort out ratetype issues
		my $RateTypeID = $self->GetValueHashRef()->{'ratetypeid'};

		# Check for Dim based ratetypeid
		if ( my $DimRateTypeID = $self->GetDimRateTypeID($DimLength,$DimWidth,$DimHeight,$Weight) )
		{
			$RateTypeID = $DimRateTypeID;
		}
		#warn "\nGetSuperCost ratetypeid: $RateTypeID" if $self->GetValueHashRef->{'customerserviceid'} eq 'TOTALTRANSPO1';

		# Check for cs/dimbased ratetypeid
		unless ( $RateTypeID )
		{
			# Give 0 cost to int'l shipments, so they go through the online process
			if ( $ShipmentRef->{'fromcountry'} eq 'US' && $ShipmentRef->{'tocountry'} eq 'US' )
			{
				return(undef,undef,$CostWeight);
			}
			else
			{
				return(0,undef,$CostWeight);
			}
		}
		#warn "\nCostWeight: $CostWeight" if $self->GetValueHashRef->{'customerserviceid'} eq 'TOTALTRANSPO1';
		my $RateType = new ARRS::RATETYPE($self->{'object_dbref'}, $self->{'object_contact'});

		my $RateHandlerName;
		my $Lookuptype;
		if ( $RateType->Load($RateTypeID) )
		{
			$RateHandlerName = $RateType->GetValueHashRef()->{'handler'};
			$Lookuptype = $RateType->GetValueHashRef()->{'lookuptype'};
		}
		#warn "\nGetSuperCost handler/lookuptype: $RateHandlerName  $Lookuptype";

		if ( !defined($RateHandlerName) || $RateHandlerName eq '' )
		{
			#warn "\nno ratehandler: weight=$Weight";
			if ( !defined($Weight) || $Weight eq '' ) { return(undef,undef,$CostWeight); }

			# Assume everything going through 'GetShipmentCosts' is coming through AOS.  Currently, this is true.
			# Possibly at some point, we may want AOS to pass the flag on its own.
			my $automated = 1;
			#warn "\nGO IN HERE: $Cost";

			($Cost) = $self->GetCost(
				$CostWeight,
				$RateTypeID,
				$ShipmentRef->{'fromzip'},
				$ShipmentRef->{'tozip'},
				$ShipmentRef->{'fromstate'},
				$ShipmentRef->{'tostate'},
				$ShipmentRef->{'fromcountry'},
				$ShipmentRef->{'tocountry'},
				undef,
				$ShipmentRef->{'band'},
				$ShipmentRef->{'zonenumber'},
				$CWT,
				undef,
				$Lookuptype,
				$Quantity,
				$UnitType,
				$automated,
				$ShipmentRef->{'customerid'},
				$ShipmentRef->{'dateshipped'},
			);

		#warn "\nGO OUT OF HERE: $Cost";

		}
		else
		{
		#warn "\nIN ELSE";
			# Return 0 cost for zips that are interline for the carrier, that require quote only for interline
			my $Service = new ARRS::SERVICE($self->{'object_dbref'}, $self->{'object_contact'});
			$Service->Load($self->GetValueHashRef()->{'serviceid'});

			foreach my $zip ($ShipmentRef->{'fromzip'},$ShipmentRef->{'tozip'})
			{
				my $STH = $self->{'object_dbref'}->prepare("
					SELECT
						quoteonly
					FROM
						interline
					WHERE
						carrierid = ?
						AND zipbegin <= ?
						AND zipend >= ?
				")
					or die "Could not prepare SQL statement";

				$STH->execute($Service->GetValueHashRef()->{'carrierid'},$zip,$zip)
					or die "Cannot execute sql statement";

				my ($QuoteOnly) = $STH->fetchrow_array();

				$STH->finish();

				if ( $QuoteOnly )
				{
					return(0,undef,$CostWeight);
				}
			}

			# Must have a class to rate the tariff based carriers
			my $Class = 0;
			my $Mode = $self->GetCSValue('servicetypeid');
warn "RATETYPEID=$RateTypeID";
			if ( $Mode == '1000' || $RateTypeID eq 'FDXSHPSERVAPI' )
			{
				# small package/parcel doesn't need a class
warn "Override Class requirement for Parcel" if $self->GetValueHashRef()->{'customerserviceid'} eq 'SPRINTFED0002';
			}
			elsif ( $ShipmentRef->{'class'} )
			{
warn "Has Class class=$ShipmentRef->{'class'}" if $self->GetValueHashRef()->{'customerserviceid'} eq 'SPRINTFED0002';

				unless ( $Class = $self->GetClassValue('fak',$ShipmentRef->{'class'},$ShipmentRef->{'class'}) )
				{
					$Class = $ShipmentRef->{'class'}
				}
			}
			else
			{
warn "NO Class return" if $self->GetValueHashRef()->{'customerserviceid'} eq 'SPRINTFED0002';
				return(undef,undef,$CostWeight);
			}

			# Check if tariff based carrier also has a zone for this cs.
			# If it does, but this shipment doesn't get a zone, kick back undef
			if
			(
				$self->GetValueHashRef()->{'zonetypeid'}
			)
			{
				($Zone) = $self->GetZoneNumber(
					$ShipmentRef->{'fromzip'},
					$ShipmentRef->{'tozip'},
					$ShipmentRef->{'fromstate'},
					$ShipmentRef->{'tostate'},
					$ShipmentRef->{'fromcountry'},
					$ShipmentRef->{'tocountry'}
				);
				#warn "\n$Zone|" . $self->GetValueHashRef()->{'customerserviceid'};
				if ( !$Zone )
				{
				#warn $Zone if $self->GetValueHashRef()->{'customerserviceid'} eq 'MAERSKRDWY001';
					return(undef,undef,$CostWeight);
				}
			}
			#warn $Zone if $self->GetValueHashRef()->{'customerserviceid'} eq 'MAERSKRDWY001';

			eval "require Tariff::$RateHandlerName";
			my $RateHandler = eval 'new Tariff::' . $RateHandlerName . '($ShipmentRef->{"dbref_' . lc($RateHandlerName) . '"},$RateTypeID)';
			#WarnHashRefValues($ShipmentRef);

			#warn "\n RateHandlerName: " . $RateHandlerName;

			my ($MarkupAmt,$MarkupPercent) = $self->GetCustomerMarkup($ShipmentRef);
			my $DiscountPercent = $self->GetDiscountPercent($ShipmentRef);
			my $ScacCode = $self->GetCarrierScac();
			#warn "\nRateHandlerName=$RateHandlerName";
			#warn "\nCarrier Scac=$ScacCode";
			($Cost,$TransitDays) = $RateHandler->GetCost(
				$CostWeight,
				$DiscountPercent,
				$Class,
				$ShipmentRef->{'fromzip'},
				$ShipmentRef->{'tozip'},
				$ScacCode,
				$ShipmentRef->{'norm_datetoship'},
				$ShipmentRef->{'required_assessorials'},
				$ShipmentRef->{'efreightid'},
				$ShipmentRef->{'clientid'},
				$self->{'field_customerserviceid'},
				$self->{'field_serviceid'},
				$ShipmentRef->{'tocountry'},
				$ShipmentRef->{'customerid'},
				$DimHeight,
				$DimWidth,
				$DimLength
			);

			unless ( defined($Cost) && $Cost ne '' && $Cost >= 0 )
			{
				return(undef,undef,$CostWeight);
			}

			# Add markup amt
			if ( defined($MarkupAmt) && $MarkupAmt > 0 )
			{
				$Cost += $MarkupAmt;
			}

			# Add markup percent
			if ( defined($MarkupPercent) && $MarkupPercent > 0 )
			{
				my $markup = $Cost * $MarkupPercent;
				$Cost += $markup;
			}
		}

		if ( defined($Cost) && $Cost ne '' )
		{
			if ( $Cost > 0 )
			{

				# Add geographic based freight charges
				if ( $self->GetCSValue('hasgeofreightcharges') )
				{
					$Cost += $self->GetGeoFreightCharges(
						$ShipmentRef->{'fromzip'},
						$ShipmentRef->{'tozip'},
						$ShipmentRef->{'fromstate'},
						$ShipmentRef->{'tostate'},
						$ShipmentRef->{'fromcountry'},
						$ShipmentRef->{'tocountry'}
					);
				}

				# Add weekend upcharges, if needed
				if ( $ShipmentRef->{'downeeded'} )
				{
					if ( $ShipmentRef->{'downeeded'} eq 'Sat' )
					{
						$Cost += $self->GetCSValue('satupcharge');
					}
					elsif ( $ShipmentRef->{'downeeded'} eq 'Sun' )
					{
						$Cost += $self->GetCSValue('sunupcharge');
					}
				}

				# Check for cs/s absolute minimum charge.  If it's higher than cost, it is the cost
				if
				(
					my $AMC = $self->GetAMC(
						$ShipmentRef->{'fromzip'},
						$ShipmentRef->{'tozip'},
						$ShipmentRef->{'fromstate'},
						$ShipmentRef->{'tostate'},
						$ShipmentRef->{'fromcountry'},
						$ShipmentRef->{'tocountry'}
					)
				)
				{
					if ( $AMC > $Cost )
					{
						$Cost = $AMC;
					}
				}
			}

			$Cost = sprintf("%02.2f",$Cost);
		}
		#warn "\nGetSuperCost: |$Cost|$Zone|$CostWeight|$TransitDays|";

		return ($Cost,$Zone,$CostWeight,$TransitDays);
	}

sub GetClassValue
	{
	my $self = shift;
		my ($CDColumn,$ClassLow,$ClassHigh) = @_;

		return unless $ClassLow or $ClassHigh;

		my $CSID = $self->GetValueHashRef()->{'customerserviceid'};
		my $ServiceID = $self->GetValueHashRef()->{'serviceid'};

		# Take cs, if available, then take service
		my $SQL = "
			SELECT
				coalesce
				(
					(
						SELECT $CDColumn FROM classdata
						WHERE ownerid = '$CSID' AND ownertypeid = 4 AND classlow <= $ClassLow AND classhigh >= $ClassHigh
					),
					(
						SELECT $CDColumn FROM classdata
						WHERE ownerid = '$ServiceID' AND ownertypeid = 3 AND classlow <= $ClassLow AND classhigh >= $ClassHigh
					)
				)
		";
	#warn "\n$SQL";

		my $STH = $self->{'object_dbref'}->prepare($SQL)
			or die "Could not prepare SQL statement";

		$STH->execute()
			or die "Cannot execute sql statement";

		my ($ClassValue) = $STH->fetchrow_array();

		$STH->finish();

	return $ClassValue;
	}

sub GetCustomerDiscount
	{
	my $self = shift;

		my ($customerid) = @_;
		my $serviceid = $self->GetValueHashRef()->{'serviceid'};

		# Take cs, if available, then take service
		my $SQL = "
			SELECT apdiscount from ratedata where ownertypeid=1 and ownerid = '$customerid' and apdiscount is not null
		";
	#warn $SQL;
		my $STH = $self->{'object_dbref'}->prepare($SQL)
			or die "Could not prepare SQL statement";

		$STH->execute()
			or die "Cannot execute sql statement";

		my ($Percent) = $STH->fetchrow_array();

		$STH->finish();
	#warn "\nDISCOUNT: $Percent";
	return $Percent;
	}

sub GetCustomerMarkup
	{
	my $self = shift;

		my ($ref) = @_;
		my $serviceid = $self->GetValueHashRef()->{'serviceid'};

		# Take cs, if available, then take service
		my $SQL = "
			SELECT freightmarkupamt,freightmarkuppercent from ratedata where ownertypeid=1 and ownerid = ? and (freightmarkupamt is not null or freightmarkuppercent is not null)
		";
		#warn $SQL;

		my $STH = $self->{'object_dbref'}->prepare($SQL)
			or die "Could not prepare SQL statement";

		$STH->execute($ref->{'customerid'})
			or die "Cannot execute sql statement";

		my ($markupamt,$markuppercent) = $STH->fetchrow_array();

		$STH->finish();

	return ($markupamt,$markuppercent);
	}

sub GetAssMarkup
	{
	my $self = shift;

		my ($customerid) = @_;
		my $serviceid = $self->GetValueHashRef()->{'serviceid'};

		# Take cs, if available, then take service
		my $SQL = "
			SELECT assmarkupamt,assmarkuppercent from assdata where ownertypeid=1 and ownerid = ? and (assmarkupamt is not null or assmarkuppercent is not null)
		";
		#warn $SQL;
		#warn $customerid;
		my $STH = $self->{'object_dbref'}->prepare($SQL)
			or die "Could not prepare SQL statement";

		$STH->execute($customerid)
			or die "Cannot execute sql statement";

		my ($markupamt,$markuppercent) = $STH->fetchrow_array();

		$STH->finish();

	return ($markupamt,$markuppercent);
	}

sub GetDiscountPercent
	{
		my $self = shift;
		my ($ShipmentRef) = @_;
		my $DiscountPercent;
		#warn "\nGetDiscountPercent";
		if
		(
			$self->GetCSValue('hasgeodiscountpercent') &&
			(
				$DiscountPercent = $self->GetGeoRateValue(
					'2000',
					'ardiscountpercent',
					$ShipmentRef->{'fromzip'},
					$ShipmentRef->{'tozip'},
					$ShipmentRef->{'fromstate'},
					$ShipmentRef->{'tostate'},
					$ShipmentRef->{'fromcountry'},
					$ShipmentRef->{'tocountry'}
				)
			)
		)
		{
			# Geographic based discount percent
		}
		elsif ( $DiscountPercent = $self->GetClassValue('discountpercent',$ShipmentRef->{'class'},$ShipmentRef->{'class'}) )
		{
			# Class based discount percent
		}
		elsif ( $DiscountPercent = $self->GetCustomerDiscount($ShipmentRef->{'customerid'}) )
		{
			# Class based discount percent
		}
		else
		{
			$DiscountPercent = $self->GetCSValue('discountpercent');
		}
		#warn "\nReturn DiscountPercent = $DiscountPercent";
		return $DiscountPercent;
	}

sub GetAMC
	{
		my $self = shift;
		my ($FromZip,$ToZip,$FromState,$ToState,$FromCountry,$ToCountry) = @_;
		my $AMC;

		unless
		(
			$self->GetCSValue('hasgeoamc') &&
			(
				$AMC = $self->GetGeoRateValue(
					'1000',
					'arcost',
					$FromZip,
					$ToZip,
					$FromState,
					$ToState,
					$FromCountry,
					$ToCountry
				)
			)
		)
		{
			$AMC = $self->GetCSValue('amc');
		}

		return $AMC;
	}

sub GetGeoFreightCharges
	{
		my $self = shift;
		my ($FromZip,$ToZip,$FromState,$ToState,$FromCountry,$ToCountry) = @_;
		my $GeoFreightCharges = 0;

		# Generic
		if ( my $GeneralCharges = $self->GetGeoRateValue('0','arcost',$FromZip,$ToZip,$FromState,$ToState,$FromCountry,$ToCountry) )
		{
			$GeoFreightCharges += $GeneralCharges;
		}

		# Origin (including beyonds)
		if ( my $OriginCharges = $self->GetGeoRateValue('10','arcost',$FromZip,$ToZip,$FromState,$ToState,$FromCountry,$ToCountry) )
		{
			$GeoFreightCharges += $OriginCharges;
		}

		# Destination (including beyonds)
		if ( my $DestCharges = $self->GetGeoRateValue('20','arcost',$FromZip,$ToZip,$FromState,$ToState,$FromCountry,$ToCountry) )
		{
			$GeoFreightCharges += $DestCharges;
		}

		return $GeoFreightCharges;
	}

sub GetGeoRateValue
	{
	my $self = shift;
		my ($GRTypeID,$GRColumn,$FromZip,$ToZip,$FromState,$ToState,$FromCountry,$ToCountry) = @_;

		my $CSID = $self->GetValueHashRef()->{'customerserviceid'};
		my $ServiceID = $self->GetValueHashRef()->{'serviceid'};

		my $OwnerID = '';

		# Allow for generic beyond table usable across multiple CS's
		if ( $GRTypeID == '10' || $GRTypeID == '20' )
		{
			$OwnerID = $self->GetCSValue('beyondownerid');
		}

		# Take cs, if available, then take service
		my $SQL = "
			SELECT
				coalesce
				(
		";

		if ( $OwnerID )
		{
			$SQL .= "
					(
						SELECT $GRColumn FROM georate WHERE ownerid = '$OwnerID' AND ownertypeid = 0 AND georatetypeid = '$GRTypeID' AND
							originbegin <= '$FromZip' AND originend >= '$FromZip' AND destbegin <= '$ToZip' AND destend >= '$ToZip'
						ORDER BY $GRColumn DESC LIMIT 1
					),
			";
		}

		$SQL .= "
					(
						SELECT $GRColumn FROM georate WHERE ownerid = '$CSID' AND ownertypeid = 4 AND georatetypeid = '$GRTypeID' AND
							originbegin <= '$FromZip' AND originend >= '$FromZip' AND destbegin <= '$ToZip' AND destend >= '$ToZip'
						ORDER BY $GRColumn DESC LIMIT 1
					),
					(
						SELECT $GRColumn FROM georate WHERE ownerid = '$ServiceID' AND ownertypeid = 3 AND georatetypeid = '$GRTypeID' AND
							originbegin <= '$FromZip' AND originend >= '$FromZip' AND destbegin <= '$ToZip' AND destend >= '$ToZip'
						ORDER BY $GRColumn DESC LIMIT 1
					),
		";

		if ( $OwnerID )
		{
			$SQL .= "
					(
						SELECT $GRColumn FROM georate WHERE ownerid = '$OwnerID' AND ownertypeid = 0 AND georatetypeid = '$GRTypeID' AND
							originstate = '$FromState' and deststate = '$ToState'
						ORDER BY $GRColumn DESC LIMIT 1
					),
			";
		}

		$SQL .= "
					(
						SELECT $GRColumn FROM georate WHERE ownerid = '$CSID' AND ownertypeid = 4 AND georatetypeid = '$GRTypeID' AND
							originstate = '$FromState' and deststate = '$ToState'
						ORDER BY $GRColumn DESC LIMIT 1
					),
					(
						SELECT $GRColumn FROM georate WHERE ownerid = '$ServiceID' AND ownertypeid = 3 AND georatetypeid = '$GRTypeID' AND
							originstate = '$FromState' and deststate = '$ToState'
						ORDER BY $GRColumn DESC LIMIT 1
					),
		";

		if ( $OwnerID )
		{
			$SQL .= "
					(
						SELECT $GRColumn FROM georate WHERE ownerid = '$OwnerID' AND ownertypeid = 0 AND georatetypeid = '$GRTypeID' AND
							originstate = '$FromState' and deststate = '$ToState'
						ORDER BY $GRColumn DESC LIMIT 1
					),
			";
		}

		$SQL .= "
					(
						SELECT $GRColumn FROM georate WHERE ownerid = '$CSID' AND ownertypeid = 4 AND georatetypeid = '$GRTypeID' AND
							origincountry = '$FromCountry' and destcountry = '$ToCountry'
						ORDER BY $GRColumn DESC LIMIT 1
					),
					(
						SELECT $GRColumn FROM georate WHERE ownerid = '$ServiceID' AND ownertypeid = 3 AND georatetypeid = '$GRTypeID' AND
							origincountry = '$FromCountry' and destcountry = '$ToCountry'
						ORDER BY $GRColumn DESC LIMIT 1
					)
				)
		";
		#warn $SQL;
		my $STH = $self->{'object_dbref'}->prepare($SQL)
			or die "Could not prepare SQL statement";

		$STH->execute()
			or die "Cannot execute sql statement";

		my ($GRValue) = $STH->fetchrow_array();

		$STH->finish();

	return $GRValue;
	}

sub GetDimRateTypeID
	{
		my $self = shift;
		my ($DimLength,$DimWidth,$DimHeight,$Weight) = @_;
		my $CSID = $self->GetValueHashRef()->{'customerserviceid'};

		# Nothing to do without dims - return false
		unless ( $DimLength && $DimWidth && $DimHeight && $Weight ) { return 0 }

		my ($LargestDim) = sort {$b <=> $a} ($DimLength, $DimWidth, $DimHeight);
		my $TotalDims = $DimLength + $DimWidth + $DimHeight;

		if ( $TotalDims > 213 && $Weight > 400 )
		{
			if ( $CSID eq 'VOUGHTMACCAR1' )
			{
				return 'VOUGHTMACCAR4';
			}
			elsif ( $CSID eq 'VOUGHTMACCAR2' )
			{
				return 'VOUGHTMACCAR5';
			}
			elsif ( $CSID eq 'VOUGHTMACCAR3' )
			{
				return 'VOUGHTMACCAR6';
			}
			elsif ( $CSID eq 'ECLIPSE000011' )
			{
				return 'VOUGHTECLIPS9';
			}
			elsif ( $CSID eq 'ECLIPSE000013' )
			{
				return 'VOUGHTECLIP10';
			}
			elsif ( $CSID eq 'ECLIPSE000015' )
			{
				return 'VOUGHTECLIP11';
			}
			elsif ( $CSID eq 'VOUGHTOMNI006' )
			{
				return 'VOUGHTOMNI009';
			}
			elsif ( $CSID eq 'VOUGHTOMNI007' )
			{
				return 'VOUGHTOMNI010';
			}
			elsif ( $CSID eq 'VOUGHTOMNI008' )
			{
				return 'VOUGHTOMNI011';
			}
			elsif ( $CSID eq 'VOUGHTSEKO001' )
			{
				return 'VOUGHTSEKO004';
			}
			elsif ( $CSID eq 'VOUGHTSEKO002' )
			{
				return 'VOUGHTSEKO005';
			}
			elsif ( $CSID eq 'VOUGHTSEKO003' )
			{
				return 'VOUGHTSEKO006';
			}
		}
		elsif ( $TotalDims > 213 && $Weight <= 400 )
		{
			if ( $CSID eq 'VOUGHTMACCAR1' )
			{
				return 'VOUGHTMACCAR7';
			}
			elsif ( $CSID eq 'VOUGHTMACCAR2' )
			{
				return 'VOUGHTMACCAR8';
			}
			elsif ( $CSID eq 'VOUGHTMACCAR3' )
			{
				return 'VOUGHTMACCAR9';
			}
			elsif ( $CSID eq 'ECLIPSE000011' )
			{
				return 'VOUGHTECLIP12';
			}
			elsif ( $CSID eq 'ECLIPSE000013' )
			{
				return 'VOUGHTECLIP13';
			}
			elsif ( $CSID eq 'ECLIPSE000015' )
			{
				return 'VOUGHTECLIP14';
			}
			elsif ( $CSID eq 'VOUGHTOMNI006' )
			{
				return 'VOUGHTOMNI012';
			}
			elsif ( $CSID eq 'VOUGHTOMNI007' )
			{
				return 'VOUGHTOMNI013';
			}
			elsif ( $CSID eq 'VOUGHTOMNI008' )
			{
				return 'VOUGHTOMNI014';
			}
			elsif ( $CSID eq 'VOUGHTSEKO001' )
			{
				return 'VOUGHTSEKO007';
			}
			elsif ( $CSID eq 'VOUGHTSEKO002' )
			{
				return 'VOUGHTSEKO008';
			}
			elsif ( $CSID eq 'VOUGHTSEKO003' )
			{
				return 'VOUGHTSEKO009';
			}
		}
		elsif ( $LargestDim >= 119 )
		{
			if ( $CSID eq 'VOUGHTMACCAR1' )
			{
				return 'VOUGHTMACCA10';
			}
			elsif ( $CSID eq 'VOUGHTMACCAR2' )
			{
				return 'VOUGHTMACCA11';
			}
			elsif ( $CSID eq 'VOUGHTMACCAR3' )
			{
				return 'VOUGHTMACCA12';
			}
			elsif ( $CSID eq 'ECLIPSE000011' )
			{
				return 'VOUGHTECLIP15';
			}
			elsif ( $CSID eq 'ECLIPSE000013' )
			{
				return 'VOUGHTECLIP16';
			}
			elsif ( $CSID eq 'ECLIPSE000015' )
			{
				return 'VOUGHTECLIP17';
			}
			elsif ( $CSID eq 'VOUGHTOMNI006' )
			{
				return 'VOUGHTOMNI015';
			}
			elsif ( $CSID eq 'VOUGHTOMNI007' )
			{
				return 'VOUGHTOMNI016';
			}
			elsif ( $CSID eq 'VOUGHTOMNI008' )
			{
				return 'VOUGHTOMNI017';
			}
			elsif ( $CSID eq 'VOUGHTSEKO001' )
			{
				return 'VOUGHTSEKO010';
			}
			elsif ( $CSID eq 'VOUGHTSEKO002' )
			{
				return 'VOUGHTSEKO011';
			}
			elsif ( $CSID eq 'VOUGHTSEKO003' )
			{
				return 'VOUGHTSEKO012';
			}
		}

		return 0;
	}

sub GetRateData
	{
		my $self = shift;
		my ($type,$band,$weight,$zone,$customerid,$date,$cwt,$from_country,$to_country) = @_;

		my $CSID = $self->{'field_customerserviceid'};
		my $ServiceID = $self->{'field_serviceid'};

		# Sort out import/export direction UPS rates will be different depending on direction
		my $intl_type;
		if ( $from_country && $to_country && ( $from_country ne 'US' || $to_country ne 'US' ) )
		{
			# Intl type = 1 for export, 2 for import
			my $intl_type = ( $from_country eq 'US' && $to_country ne 'US' ) ? 1 : 2;
		}

		# To allow for customers linked to other customers' SOPs, but to have their own discount percents (e.g. FedEx),
		# add the customerid to the ratedata for customer data that is doing the linking.  It's important to leave the original
		# customer SOP alone (no customerid)
		local $^W=0;

		my $common_discount_select = "SELECT ${type}discount FROM ratedata WHERE ownerid =";
		my $common_min_select = "SELECT ${type}min FROM ratedata WHERE ownerid =";
		#my $common_where = "AND band = '$band' AND unitsstart <= '$weight' AND unitsstop >= '$weight' AND customerid";
		my $common_where = "AND band = '$band' AND unitsstart <= '$weight' AND unitsstop >= '$weight'";
		my $order_by = "ORDER BY startdate DESC, stopdate DESC";

		if ( $date )
		{
			$common_where .= " AND ( ( startdate <= date('$date') AND stopdate  >= date('$date') ) OR ( startdate IS NULL AND stopdate IS NULL ))";
		}

		if ( $cwt )
		{
			$common_where .= " AND cwt = 1";
		}

		if ( $intl_type )
		{
			$common_where .= " AND intltype = $intl_type";
		}

		$common_where .= " AND customerid";

		my $zone_where = "AND zone = $zone";

		my $SQL = "
			SELECT
				coalesce
				(
					($common_discount_select '$CSID' AND ownertypeid = 4 $common_where = '$customerid' AND zone = '$zone' $order_by LIMIT 1),
					($common_discount_select '$ServiceID' AND ownertypeid = 3 $common_where = '$customerid' AND zone = '$zone' $order_by LIMIT 1),
					($common_discount_select '$CSID' AND ownertypeid = 4 $common_where IS NULL AND zone = '$zone' $order_by LIMIT 1),
					($common_discount_select '$ServiceID' AND ownertypeid = 3 $common_where IS NULL AND zone = '$zone' $order_by LIMIT 1),
					($common_discount_select '$CSID' AND ownertypeid = 4 $common_where = '$customerid' AND zone IS NULL $order_by LIMIT 1),
					($common_discount_select '$ServiceID' AND ownertypeid = 3 $common_where = '$customerid' AND zone IS NULL $order_by LIMIT 1),
					($common_discount_select '$CSID' AND ownertypeid = 4 $common_where IS NULL AND zone IS NULL $order_by LIMIT 1),
					($common_discount_select '$ServiceID' AND ownertypeid = 3 $common_where IS NULL AND zone IS NULL $order_by LIMIT 1)
				) as discountpercent,
				coalesce
				(
					($common_min_select '$CSID' AND ownertypeid = 4 $common_where = '$customerid' AND zone = '$zone' $order_by LIMIT 1),
					($common_min_select '$ServiceID' AND ownertypeid = 3 $common_where = '$customerid' AND zone = '$zone' $order_by LIMIT 1),
					($common_min_select '$CSID' AND ownertypeid = 4 $common_where IS NULL AND zone = '$zone' $order_by LIMIT 1),
					($common_min_select '$ServiceID' AND ownertypeid = 3 $common_where IS NULL AND zone = '$zone' $order_by LIMIT 1),
					($common_min_select '$CSID' AND ownertypeid = 4 $common_where = '$customerid' AND zone IS NULL $order_by LIMIT 1),
					($common_min_select '$ServiceID' AND ownertypeid = 3 $common_where = '$customerid' AND zone IS NULL $order_by LIMIT 1),
					($common_min_select '$CSID' AND ownertypeid = 4 $common_where IS NULL AND zone IS NULL $order_by LIMIT 1),
					($common_min_select '$ServiceID' AND ownertypeid = 3 $common_where IS NULL AND zone IS NULL $order_by LIMIT 1)
				) as min
		";
		local $^W=1;

		#warn $SQL;

		my $STH = $self->{'object_dbref'}->prepare($SQL)
			or die "Could not prepare SQL statement";

		$STH->execute()
			or die "Cannot execute sql statement";

		my ($discount_percent,$min) = $STH->fetchrow_array();

		$STH->finish();
		#warn "\n$discount_percent,$min";
		return ($discount_percent,$min);
	}

sub GetBand
	{
		my $self = shift;
		my ($type,$date) = @_;

		my $dollar_amount = $self->GetBandDollars($date);
		my $CSID = $self->{'field_customerserviceid'};
		my $ServiceID = $self->{'field_serviceid'};

		my $date_where = '';
		if ( $date )
		{
			$date_where .= " AND ( ( startdate <= date('$date') AND stopdate  >= date('$date') ) OR ( startdate IS NULL AND stopdate IS NULL ))";
		}

		my $SQL = "
			SELECT
				coalesce
				(
					(SELECT band FROM banddata WHERE ownerid = '$CSID' AND ownertypeid = 4 AND bandtype = '$type' AND dollarstart <= '$dollar_amount' AND dollarstop >= '$dollar_amount' $date_where LIMIT 1),
					(SELECT band FROM banddata WHERE ownerid = '$ServiceID' AND ownertypeid = 3 AND bandtype = '$type' AND dollarstart <= '$dollar_amount' AND dollarstop >= '$dollar_amount' $date_where LIMIT 1)
				)
		";

		#warn $SQL if $CSID eq 'MHEFEDEXES000';
		my $STH = $self->{'object_dbref'}->prepare($SQL)
			or die "Could not prepare SQL statement";

		$STH->execute()
			or die "Cannot execute sql statement";

		my ($band) = $STH->fetchrow_array();

		$STH->finish();

		return ($band,$dollar_amount);
	}

sub GetBandDollars
	{
		my $self = shift;
		my ($date) = @_;

		my $Service = new ARRS::SERVICE($self->{'object_dbref'}, $self->{'object_contact'});
		$Service->Load($self->GetValueHashRef()->{'serviceid'});

		my $sop_id = $self->{'field_customerid'};
		my $carrier_id = $Service->GetValueHashRef()->{'carrierid'};

		my $SQL = "
			SELECT
				startdate,
				stopdate,
				defaultcharges,
				bandstartweek,
				bandmaxweek
			FROM
				ratesummary
			WHERE
				sopid = '$sop_id'
				AND carrierid = '$carrier_id'
				AND startdate <= date('$date')
				AND stopdate  >= date('$date')
		";

		my $STH = $self->{'object_dbref'}->prepare($SQL)
			or die "Could not prepare SQL statement";

		$STH->execute()
			or die "Cannot execute sql statement";

		my $rs_ref = $STH->fetchrow_hashref();

		$STH->finish();

		my ($band_weeks,$start_date,$stop_date) = $self->GetBandDates(
			$date,$rs_ref->{'startdate'},
			$rs_ref->{'bandstartweek'},
			$rs_ref->{'bandmaxweek'}
		);

		if ( $band_weeks > $rs_ref->{'bandstartweek'} )
		{
			my $avg_weeks = $band_weeks - $rs_ref->{'bandstartweek'};
			return $self->GetInvFreightCharges($sop_id,$carrier_id,$start_date,$stop_date,$avg_weeks);
		}
		else
		{
			return $rs_ref->{'defaultcharges'};
		}
	}

sub GetBandDates
	{
		my $self = shift;
		my ($date,$start_date,$bs_week,$max_weeks) = @_;

		# Get the date delta between the rate start date, and the date we're interested
		# in rating (invoice date, for UPS)
		my $date_delta = &GetDeltaDays($start_date,$date);

		# Figure out what 'week' we're in.
		my $current_week = ceil($date_delta/7);

		# If current week is <= bandstart week, just return the week.  No date calc needed.
		return ($current_week) if $current_week <= $bs_week;

		# Saturday (week end) for week previus to '$date' (inv date, most likely)
		my $band_stop_date = &VerifyDate(&Date_GetPrev($date,'Sat',0));
		my $weeks = 0;

		# Weeks < max_weeks, calc max weeks
		if ( $current_week - $bs_week <= $max_weeks )
		{
			$weeks = $current_week - $bs_week;
		}
		# Otherwise, use max weeks
		else
		{
			$weeks = $max_weeks
		}

		# Number of days to the start of the band
		my $days = ($weeks * 7) - 1;
		my $band_start_date = &VerifyDate(&DateCalc($band_stop_date,"- $days days"));

		return ($current_week,$band_start_date,$band_stop_date);
	}

sub GetInvFreightCharges
	{
		my $self = shift;
		my ($sop_id,$carrier_id,$start_date,$stop_date,$avg_weeks) = @_;

		# Assume one set of invoice freight charges per week
		my $SQL = "
			SELECT
				SUM(freightcharges)
			FROM
				invoicedata
			WHERE
				sopid = '$sop_id'
				AND carrierid = '$carrier_id'
				AND invoicedate >= date('$start_date')
				AND invoicedate <= date('$stop_date')
		";

		my $STH = $self->{'object_dbref'}->prepare($SQL)
			or die "Could not prepare SQL statement";

		$STH->execute()
			or die "Cannot execute sql statement";

		my ($freight_charges) = $STH->fetchrow_array();

		$STH->finish();

		# Send back weekly average for band dollars
		return ($freight_charges/$avg_weeks);
	}

sub ZoneIsExcluded
	{
		my $self = shift;
		my ($zip,$state) = @_;

		my $CSID = $self->{'field_customerserviceid'};
		my $ServiceID = $self->{'field_serviceid'};

		$zip = $zip ? $zip : '';
		$state = $state ? $state : '';

		my $SQL = "
			SELECT
				coalesce
				(
					(SELECT zoneexclusionid FROM zoneexclusion WHERE ownerid = '$CSID' AND ownertypeid = 4 AND ( (zipstart <= '$zip' AND zipstop >= '$zip') OR state = '$state' ) LIMIT 1),
					(SELECT zoneexclusionid FROM zoneexclusion WHERE ownerid = '$ServiceID' AND ownertypeid = 3 AND ( (zipstart <= '$zip' AND zipstop >= '$zip') OR state = '$state' ) LIMIT 1)
				)
		";

		my $STH = $self->{'object_dbref'}->prepare($SQL)
			or die "Could not prepare SQL statement";

		$STH->execute()
			or die "Cannot execute sql statement";

		my ($zoneexclusionid) = $STH->fetchrow_array();

		$STH->finish();

		return ($zoneexclusionid);
	}

sub GetAssValue
	{
		my $self = shift;
		my ($type,$ass_name,$weight,$quantity,$freight_cost,$date_shipped,$ownertypeid,$customerid) = @_;
	#warn "\nGetAssValue name=$ass_name freight=$freight_cost";
	#warn "\nGetAssValue name=$ass_name freight=$freight_cost customerid=$customerid" if $self->GetValueHashRef->{'customerserviceid'} eq 'EFREIGHTDYLT0';

		my ($markupamt,$markuppercent) = $self->GetAssMarkup($customerid);

		my ($cost,$costmin,$costperwt,$costperunit,$costmax,$costpercent) =
			$self->GetAssData($type,$ass_name,$date_shipped,$ownertypeid,$markupamt,$markuppercent);

		# override "cost" with csoveride value if one exists
	my $CSOverride = new ARRS::CSOVERRIDE($self->{'object_dbref'}, $self->{'object_contact'});
	if
	(
		$CSOverride->LowLevelLoadAdvanced(undef,{
			customerid		=> $customerid,
			customerserviceid => $self->{'field_customerserviceid'},
			datatypename	=> $ass_name
		})
	)
	{
			if ( $ass_name eq 'fscrate' )
			{
			$costpercent = $CSOverride->GetValueHashRef()->{'value'};
			}
			else
			{
			$cost = $CSOverride->GetValueHashRef()->{'value'};
			}
	#warn "\nLOADED FROM CSOVERRIDE: $costpercent" if $self->GetValueHashRef->{'customerserviceid'} eq 'EFREIGHTDYLT0';
	}

	#warn "\nGetAssValue name=$ass_name cost=$cost costpercent=$costpercent";

		my $ass_cost = $cost if $cost;
		$ass_cost += $costperwt * $weight if $costperwt;
		$ass_cost += $costperunit * $quantity if $costperunit;

		# Add markups amt
		# percent markup from assdata table
		if ( defined($costpercent) && $costpercent ne '' && $costpercent ne '0' && defined($freight_cost) && $freight_cost ne '' )
		{
			$ass_cost += $freight_cost * $costpercent if $costpercent;
		}
		# flat markup and markup percent set in custcondata
		else
		{
			if ( defined($ass_cost) && $ass_cost ne '0' && $ass_cost ne '' && defined($markupamt) && $markupamt > 0 )
			{
				#warn "\nAdd flat markup";
				$ass_cost += $markupamt;
			}

			# Add markup percent
			if ( defined($ass_cost) && $ass_cost ne '0' && $ass_cost ne '' && defined($markuppercent) && $markuppercent > 0 )
			{
				#warn "\nAdd percent markup";
				my $markup = $ass_cost * $markuppercent;
				$ass_cost += $markup;
			}
		}

		$ass_cost = ($ass_cost && $costmin && $costmin > $ass_cost) ? $costmin : $ass_cost;
		$ass_cost = ($ass_cost && $costmax && $ass_cost > $costmax) ? $costmax : $ass_cost;
		#warn "\nafter min/max: $ass_cost";

		$ass_cost = sprintf("%02.2f", $ass_cost) if $ass_cost;

		#warn "\nGetAssValue returning cost=$ass_cost ass=$ass_name";
		#warn "\nGetAssValue returning cost=$ass_cost ass=$ass_name" if $self->GetValueHashRef->{'customerserviceid'} eq 'EFREIGHTDYLT0';
		$ass_cost = $ass_name eq 'fscrate' ? $costpercent : $ass_cost;
		return ($ass_cost);
	}

sub GetAssData
	{
		my $self = shift;
		my ($type,$ass_name,$date,$specd_ot_id) = @_;

		my $CSID = $self->{'field_customerserviceid'};
		my $ServiceID = $self->{'field_serviceid'};
		#warn "\n$type,$ass_name,$date,$specd_ot_id,$CSID,$ServiceID" if $self->GetValueHashRef->{'customerserviceid'} eq 'EFREIGHTDYLT0';

		my @ownertypeids = $specd_ot_id ? ($specd_ot_id) : qw(4 3);

		my $SQL = "
			SELECT
		";

		$date = $date ? $date : $self->{'object_dbref'}->gettimestamp();

		foreach my $field qw(cost costmin costperwt costperunit costmax costpercent)
		{
			$SQL .= "
				coalesce
				(";

			foreach my $ownertypeid (@ownertypeids)
			{
				my $ID = $ownertypeid == 4 ? $CSID : $ServiceID;

				$SQL .= "
					(
						SELECT
							${type}$field
						FROM
							assdata
						WHERE
							ownerid = '$ID'
							AND ownertypeid = '$ownertypeid'
							AND assname = '$ass_name'
							AND
							(
								( startdate <= date('$date') AND stopdate  >= date('$date') )
								OR
								( startdate IS NULL AND stopdate IS NULL )
							)
						ORDER BY
							startdate,
							stopdate
						LIMIT 1
					),";
			}

			chop $SQL;

			$SQL .= "
				) as $field,";
		}

		chop $SQL;
		#warn $SQL;

		my $STH = $self->{'object_dbref'}->prepare($SQL)
			or die "Could not prepare SQL statement";

		$STH->execute()
			or die "Cannot execute sql statement";
		my ($cost,$costmin,$costperwt,$costperunit,$costmax,$costpercent) = $STH->fetchrow_array();

		$STH->finish();
	#warn "\nGetAssData returning... assname=$ass_name min=$costmin,percent=$costpercent";

		return ($cost,$costmin,$costperwt,$costperunit,$costmax,$costpercent);
	}

sub GetCSAssessorialList
	{
		my $self = shift;

		my $CSID = $self->{'field_customerserviceid'};
		my $ServiceID = $self->{'field_serviceid'};

		my $STH = $self->{'object_dbref'}->prepare("
			SELECT DISTINCT
				assname
			FROM
				assdata
			WHERE
				(ownerid=? AND ownertypeid=4)
				OR
				(ownerid=? AND ownertypeid=3)
		")
			or die "Cannot execute sql statement";

		$STH->execute($CSID,$ServiceID)
			or die "Cannot execute sql statement";

		my @assessorials = ();

		while ( my ($assessorial) = $STH->fetchrow_array() )
		{
			push(@assessorials,$assessorial);
		}

		$STH->finish();

		return @assessorials;
	}

sub GetAssCode
	{
		my $self = shift;
		my ($csid,$ass_name) = @_;

		my $CSID = $self->{'field_customerserviceid'};
		my $ServiceID = $self->{'field_serviceid'};

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

		my $STH = $self->{'object_dbref'}->prepare($SQL)
			or die "Could not prepare SQL statement";

		$STH->execute($CSID,$ServiceID,$ass_name)
			or die "Cannot execute sql statement";
		#warn "\n".$SQL;
		#warn "\n$CSID,$ServiceID,$ass_name";

		my ($asscode,$ownertypeid) = $STH->fetchrow_array();
		#warn "ARRS CS->GetAssCode() returns asscode=$asscode";
		$STH->finish();

		return ($asscode);
	}

1;

__END__