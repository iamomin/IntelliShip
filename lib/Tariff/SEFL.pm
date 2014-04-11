#!/usr/bin/perl -w

#==========================================================
#   Project:	ARRS
#
#   Filename:	SEFL.pm
#
#   Date:		06/21/2005
#
#   Purpose:	Calculate rates based on SEFL Tariff
#
#   Company:	Engage TMS
#
#   Author(s):	Kirk Aksdal
#					Leigh Bohannon
#
#==========================================================

{
	package Tariff::SEFL;

	use strict;
	use ARRS::COMMON;
	use ARRS::IDBI;

	my $Debug = 0;

	sub new
	{
		my $proto = shift;
		my $class = ref($proto) || $proto;

		my ($DBRef,$RateTypeID,$EffDate) = @_;

		my $self = {};

		if ( $DBRef )
		{
			$self->{'dbref'} = $DBRef;
		}
		else
		{
			$self->{'dbref'} = ARRS::IDBI->connect({
				dbname => 'sefl',
				dbhost => 'localhost',
				dbuser => 'webuser',
				dbpassword => 'Byt#Yu2e',
				autocommit => 1
			});
		}

		$self->{'effdate'} = $EffDate ? $EffDate : '09899785';

		bless($self, $class);

		return $self;
	}

	sub GetMileageData
	{
		my $self = shift;
		my ($Zip1,$Zip2) = @_;

		my ($ShortZip1) = $Zip1 =~ /(\d{3})\d{2}/;
		my ($ShortZip2) = $Zip2 =~ /(\d{3})\d{2}/;

		my $ZipLo = $ShortZip1;
		my $ZipHi = $ShortZip2;

		if ( $ShortZip2 < $ShortZip1 )
		{
			$ZipLo = $ShortZip2;
			$ZipHi = $ShortZip1;
		}

		my $STH_SQL = "
			SELECT
				*
			FROM
				mileage
			WHERE
				ziplo = '$ZipLo'
				AND ziphi = '$ZipHi'
				AND effdate >= '$self->{'effdate'}'
			ORDER BY effdate
			LIMIT 1
		";
#warn $STH_SQL;
		my $STH = $self->{'dbref'}->prepare($STH_SQL)
			or die "Could not prepare mileage data select sql statement";

		$STH->execute()
			or die "Could not execute mileage data select sql statement";

		my $MileageData = $STH->fetchrow_hashref();

		$STH->finish();

		return $MileageData;
	}

	sub GetCost
	{
		my $self = shift;
		my ($Weight,$DiscountPercent,$Class,$OriginZip,$DestZip) = @_;

		# If we have 0 weight, don't return a cost...
		if ( $Weight == 0 ) { return undef }

		# Get milage data for shipment
		my $MileageData = $self->GetMileageData($OriginZip,$DestZip);

		if ( $Debug ) { WarnHashRefValues($MileageData) }

		# Get weight class info
		my $WtClassRef = $self->GetWeightClassInfo($Weight);

		# Get base rate and min charge
		my ($BaseRate,$MinCharge) = $self->GetRateAndMin($MileageData,$WtClassRef->{'minwt'},$WtClassRef->{'maxwt'});
		if ( $Debug ) { warn "BASE: BaseRate - $BaseRate: MinCharge - $MinCharge"; }

		# Get base rate and min charge for next weight break (though the min charge apparently won't change across weight breaks)
		my ($NextBaseRate,$NextMinCharge);
		if ( $Weight < 40000 )
		{
			($NextBaseRate,$NextMinCharge) = $self->GetRateAndMin($MileageData,$WtClassRef->{'nextminwt'},$WtClassRef->{'nextmaxwt'});
			if ( $Debug ) { warn "BASE NEXT: BaseRate - $NextBaseRate: MinCharge - $NextMinCharge"; }
		}

		# Get lane adjustments
		if ( my ($Percent,$MCPercent) = $self->GetLaneAdj($OriginZip,$DestZip) )
		{
			$BaseRate = defined($Percent) && $Percent > 0 ? sprintf("%.4f", ($BaseRate * $Percent)) : sprintf("%.4f", $BaseRate);
			$NextBaseRate = defined($Percent) && $Percent > 0 ? sprintf("%.4f", ($NextBaseRate * $Percent)) : sprintf("%.4f", $NextBaseRate);
			$MinCharge = defined($MCPercent) && $MCPercent > 0 ? sprintf("%.2f", ($MinCharge * $MCPercent)) : sprintf("%.2f", $MinCharge);
		}
		if ( $Debug ) { warn "LANE ADJ: Rate - $BaseRate: NextRate - $NextBaseRate: MinCharge - $MinCharge"; }

		# Get class factor adjustments
		if ( my ($ClassAdjFactor) = $self->GetClassAdj($MileageData->{'bureau'},$Class) )
		{
			$BaseRate = defined($ClassAdjFactor) ? sprintf("%.4f", ($BaseRate * $ClassAdjFactor)) : sprintf("%.4f", $BaseRate);
			$NextBaseRate = defined($ClassAdjFactor) ? sprintf("%.4f", ($NextBaseRate * $ClassAdjFactor)) : sprintf("%.4f", $NextBaseRate);
		}
		if ( $Debug ) { warn "CLASS ADJ: Rate - $BaseRate: NextRate - $NextBaseRate"; }

		# Get origin rate adjustments
		if ( my ($MCPercentAdj,$MCFlatAdj) = $self->GetArbitraryAdj($OriginZip,0,'O') )
		{
			$MinCharge = $MCPercentAdj ? sprintf("%.2f", ($MinCharge * $MCPercentAdj)) : sprintf("%.2f", $MinCharge);
			$MinCharge = $MCFlatAdj ? sprintf("%.2f", ($MinCharge + ($MCFlatAdj*100))) : sprintf("%.2f", $MinCharge);

			if ( $Debug ) { warn "Origin MC Arbitrary Adj: Percent - $MCPercentAdj: Flat - $MCFlatAdj" }
		}

		if ( my ($PercentAdj,$FlatAdj) = $self->GetArbitraryAdj($OriginZip,$Weight,'O') )
		{
			$BaseRate = $PercentAdj ? sprintf("%.4f", ($BaseRate * $PercentAdj)) : sprintf("%.4f", $BaseRate);
			$BaseRate = $FlatAdj ? sprintf("%.4f", ($BaseRate + $FlatAdj)) : sprintf("%.4f", $BaseRate);

			if ( $Debug ) { warn "Origin Arbitrary Adj: Percent - $PercentAdj: Flat - $FlatAdj" }
		}

		if ( my ($PercentAdj,$FlatAdj) = $self->GetArbitraryAdj($OriginZip,$WtClassRef->{'nextminwt'},'O') )
		{
			$NextBaseRate = $PercentAdj ? sprintf("%.4f", ($NextBaseRate * $PercentAdj)) : sprintf("%.4f", $NextBaseRate);
			$NextBaseRate = $FlatAdj ? sprintf("%.4f", ($NextBaseRate + $FlatAdj)) : sprintf("%.4f", $NextBaseRate);

			if ( $Debug ) { warn "Next Origin Arbitrary Adj: Percent - $PercentAdj: Flat - $FlatAdj" }
		}

		# Get destination rate adjustments
		if ( my ($MCPercentAdj,$MCFlatAdj) = $self->GetArbitraryAdj($DestZip,0,'I') )
		{
			$MinCharge = $MCPercentAdj ? sprintf("%.2f", ($MinCharge * $MCPercentAdj)) : sprintf("%.2f", $MinCharge);
			$MinCharge = $MCFlatAdj ? sprintf("%.2f", ($MinCharge + ($MCFlatAdj*100))) : sprintf("%.2f", $MinCharge);

			if ( $Debug ) { warn "Dest MC Arbitrary Adj: Percent - $MCPercentAdj: Flat - $MCFlatAdj" }
		}

		if ( my ($PercentAdj,$FlatAdj) = $self->GetArbitraryAdj($DestZip,$Weight,'I') )
		{
			$BaseRate = $PercentAdj ? sprintf("%.4f", ($BaseRate * $PercentAdj)) : sprintf("%.4f", $BaseRate);
			$BaseRate = $FlatAdj ? sprintf("%.4f", ($BaseRate + $FlatAdj)) : sprintf("%.4f", $BaseRate);

			if ( $Debug ) { warn "Dest Arbitrary Adj: Percent - $PercentAdj: Flat - $FlatAdj" }
		}

		if ( my ($PercentAdj,$FlatAdj) = $self->GetArbitraryAdj($DestZip,$WtClassRef->{'nextminwt'},'I') )
		{
			$NextBaseRate = $PercentAdj ? sprintf("%.4f", ($NextBaseRate * $PercentAdj)) : sprintf("%.4f", $NextBaseRate);
			$NextBaseRate = $FlatAdj ? sprintf("%.4f", ($NextBaseRate + $FlatAdj)) : sprintf("%.4f", $NextBaseRate);

			if ( $Debug ) { warn "Next Dest Arbitrary Adj: Percent - $PercentAdj: Flat - $FlatAdj" }
		}

		if ( $Debug ) { warn "Arbitrary ADJ: Rate - $BaseRate: NextRate - $NextBaseRate: MinCharge - $MinCharge"; }

		# Calculate final base charges
		my $BaseCharge = sprintf("%.2f",( $BaseRate * $Weight ));
		my $NextBaseCharge = sprintf("%.2f",( $NextBaseRate * $WtClassRef->{'nextminwt'} ));

		if ( $Debug ) { warn "Base Final Charges: Charge - $BaseCharge: NextCharge - $NextBaseCharge: MinCharge - $MinCharge"; }

		# Calculate discounted charges
		my $ChargePercent = 1 - $DiscountPercent;

		my $DiscountMC = sprintf("%.2f",( $MinCharge * $ChargePercent ) );
		my $DiscountCharge = sprintf("%.2f",( $BaseCharge * $ChargePercent ) );
		my $DiscountNextCharge = sprintf("%.2f",( $NextBaseCharge * $ChargePercent ) );

		if ( $Debug ) { warn "Discount Final Charges: Charge - $DiscountCharge: NextCharge - $DiscountNextCharge: MinCharge - $DiscountMC"; }

		my $FinalCost = $DiscountCharge < $DiscountNextCharge ? $DiscountCharge : $DiscountNextCharge;

		$self->{'dbref'}->disconnect();

		if ( $FinalCost > $DiscountMC )
		{
			return $FinalCost;
		}
		else
		{
			return $DiscountMC;
		}
	}

	sub GetRateAndMin
	{
		my $self = shift;
		my ($MileageData,$WeightMin,$WeightMax) = @_;

		my $STH_SQL = "
			SELECT
				rate,
				mincharge
			FROM
				rate
			WHERE
				bureau = '$MileageData->{'bureau'}'
				AND rbn = '$MileageData->{'rbn'}'
				AND wtbrklo = '$WeightMin'
				AND wtbrkhi = '$WeightMax'
				AND effdate >= '$self->{'effdate'}'
			ORDER BY effdate
			LIMIT 1
		";
#warn $STH_SQL;
		my $STH = $self->{'dbref'}->prepare($STH_SQL)
			or die "Could not prepare mileage data select sql statement";

		$STH->execute()
			or die "Could not execute mileage data select sql statement";

		my ($Rate,$MinCharge) = $STH->fetchrow_array();

		$STH->finish();

		return ($Rate,$MinCharge);
	}

	sub GetLaneAdj
	{
		my $self = shift;
		my ($FromZip,$ToZip) = @_;

		my $STH_SQL = "
			SELECT
				percent,
				mcpercent
			FROM
				laneadj
			WHERE
				fromziplo <= '$FromZip'
				AND fromziphi >= '$FromZip'
				AND toziplo <= '$ToZip'
				AND toziphi >= '$ToZip'
				AND effdate >= '$self->{'effdate'}'
			ORDER BY effdate
			LIMIT 1
		";
#warn $STH_SQL;
		my $STH = $self->{'dbref'}->prepare($STH_SQL)
			or die "Could not prepare mileage data select sql statement";

		$STH->execute()
			or die "Could not execute mileage data select sql statement";

		my ($Percent,$MinPercent) = $STH->fetchrow_array();

		$STH->finish();

		return ($Percent,$MinPercent);
	}

	sub GetClassAdj
	{
		my $self = shift;
		my ($Bureau,$Class) = @_;

		my $STH_SQL = "
			SELECT
				classadjfactor
			FROM
				classadj
			WHERE
				bureau = '$Bureau'
				AND class = '$Class'
				AND effdate >= '$self->{'effdate'}'
			ORDER BY effdate
			LIMIT 1
		";

		my $STH = $self->{'dbref'}->prepare($STH_SQL)
			or die "Could not prepare mileage data select sql statement";

		$STH->execute()
			or die "Could not execute mileage data select sql statement";

		my ($ClassAdjFactor) = $STH->fetchrow_array();

		$STH->finish();

		return ($ClassAdjFactor);
	}

	sub GetArbitraryAdj
	{
		my $self = shift;
		my ($Zip,$Weight,$Direction) = @_;
		my ($PercentAdj, $FlatAdj);

		foreach my $IOB ('B',$Direction)
		{
			my $STH_SQL = "
				SELECT
					percentadj,
					flatadj
				FROM
					arbitraryadj
				WHERE
					ziplo <= '$Zip'
					AND ziphi >= '$Zip'
					AND wtbrklo <= '$Weight'
					AND wtbrkhi >= '$Weight'
					AND iob = '$IOB'
					AND effdate >= '$self->{'effdate'}'
			ORDER BY effdate
				LIMIT 1
			";

			my $STH = $self->{'dbref'}->prepare($STH_SQL)
				or die "Could not prepare mileage data select sql statement";

			$STH->execute()
				or die "Could not execute mileage data select sql statement";

			if ( ($PercentAdj,$FlatAdj) = $STH->fetchrow_array() )
			{
				last;
			}
		}

		if ( $PercentAdj || $FlatAdj )
		{
			return ($PercentAdj,$FlatAdj);
		}
		else
		{
			return (1,0);
		}
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

		if ( $Weight >= 0 && $Weight <= 499 )
		{
			$WeightClass = 'l5c';
			$NextWeightClass = 'm5c';
			$WtClassMinWt = 0;
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
			$NextWtClassMaxWt = 49999;
		}
		elsif ( $Weight >= 40000 && $Weight <= 49999 )
		{
			$WeightClass = 'm40m';
			$WtClassMinWt = 40000;
			$WtClassMaxWt = 49999;
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
}
1

