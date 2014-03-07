#!/usr/bin/perl -w

#==========================================================
#   Project:	ARRS
#
#   Filename:	WATKINS.pm
#
#   Date:		06/22/2005
#
#   Purpose:	Calculate rates based on Watkins Tariff
#
#   Company:	Engage TMS
#
#   Author(s):	Kirk Aksdal
#					Leigh Bohannon
#
#==========================================================

{
	package Tariff::WATKINS;

	use strict;
	use ARRS::COMMON;
	use ARRS::IDBI;

	use Math::BigFloat;

	my $Debug = 0;

        our $DB_HANDLE  = ARRS::IDBI->connect({
			dbname => 'watkins',
			dbhost => 'localhost',
			dbuser => 'webuser',
			dbpassword => 'Byt#Yu2e',
			autocommit => 1
		});

	sub new
	{
		my $proto = shift;
		my $class = ref($proto) || $proto;

		my ($RateTypeID) = @_;

		my $self = {};

		$self->{'dbref'} = $DB_HANDLE;

		$self->{'ratetypeid'} = $RateTypeID;

		bless($self, $class);

		return $self;
	}

	sub GetRateBase
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
				ratebase
			FROM
				base
			WHERE
				ziplo = '$ZipLo'
				AND ziphi = '$ZipHi'
		";

		my $STH = $self->{'dbref'}->prepare($STH_SQL)
			or die "Could not prepare mileage data select sql statement";

		$STH->execute()
			or die "Could not execute mileage data select sql statement";

		my ($RateBase) = $STH->fetchrow_array();

		$STH->finish();

		return $RateBase;
	}

	sub GetCost
	{
		my $self = shift;
		my ($Weight,$DiscountPercent,$Class,$OriginZip,$DestZip) = @_;
		my $Cost = -1;

		# If we have 0 weight, don't return a cost...
		if ( $Weight == 0 ) { return undef }

      # Get weight class info
      my $WtClassRef = $self->GetWeightClassInfo($Weight);
		if ( $Debug ) { WarnHashRefValues($WtClassRef) }

		# Get cost for current class
		my ($ClassCost,$MinCharge) =
			$self->ClassCost($Weight,$DiscountPercent,$Class,$OriginZip,$DestZip,$WtClassRef->{'class'});
		if ( $Debug ) { warn "Class Cost: $ClassCost, Class: $WtClassRef->{'class'}"; }

		# Get cost for next class
     	my $NextClassCost = 0;
     	if ( $Weight < 40000 )
     	{
			($NextClassCost) = $self->ClassCost($WtClassRef->{'nextminwt'},$DiscountPercent,$Class,$OriginZip,$DestZip,$WtClassRef->{'nextclass'});
        	if ( $Debug ) { warn "Next Class Cost: $NextClassCost, Next Class: $WtClassRef->{'nextclass'}"; }
     	}

		# Take the cheaper of the real class cost or the next class cost
		$Cost = $ClassCost < $NextClassCost ? $ClassCost : $NextClassCost;

		# Take the more expensive of the cost or the min charge
		$Cost = $Cost > $MinCharge ? $Cost : $MinCharge;

		$self->{'dbref'}->disconnect();

		return $Cost;
	}

	sub ClassCost
	{
		my $self = shift;
		my ($Weight,$DiscountPercent,$Class,$OriginZip,$DestZip,$WtClass) = @_;
		my $ClassCost = -1;

      # Get weight class info
		my $RateBase;

		if ( $RateBase = $self->GetRateBase($OriginZip,$DestZip) )
		{
			if ( $Debug ) { warn "RateBase: $RateBase" }
		}
		else
		{
			return (0,0);
		}

      # Get base rate and min charge
      my ($BaseRate,$MinCharge) = $self->GetRateAndMin($RateBase,$WtClass);
		$BaseRate = $self->HardRound($BaseRate/100,2);
		$MinCharge = $self->HardRound($MinCharge/100,2);
      if ( $Debug ) { warn "BASE: BaseRate - $BaseRate: MinCharge - $MinCharge" }

		# Get Adjustment list
		my @Adjustments = $self->GetAdjustmentsList($OriginZip,$DestZip,$Class,$WtClass);

		foreach my $AdjustmentNumber (@Adjustments)
		{
			my ($Adjustment,$AdjType) = $self->GetAdjustment($AdjustmentNumber,$Class,$WtClass);
      	if ( $Debug ) { warn "Adjustment: $Adjustment Adj Type: $AdjType" }

			if ( $AdjType == 1 )
			{
				$BaseRate = $self->HardRound($BaseRate + $Adjustment,2);
			}
			elsif ( $AdjType == 2 )
			{
				$BaseRate = $self->HardRound(($BaseRate * ($Adjustment/1000)),2);
			}

			my ($MCAdj,$MCAdjType) = $self->GetAdjustment($AdjustmentNumber,$Class,'min');
			if ( $MCAdjType == 1 )
			{
				$MinCharge = $self->HardRound(($MinCharge + $MCAdj),2);
			}
			elsif ( $MCAdjType == 2 )
			{
				$MinCharge = $self->HardRound(($MinCharge * ($MCAdj/1000)),2);
			}
		}
      if ( $Debug ) { warn "After Adjustments: BaseRate - $BaseRate: MinCharge - $MinCharge" }

		# Get Class factor
		my $ClassFactor = $self->GetClassFactor($RateBase,$Class,$WtClass);
      if ( $Debug ) { warn "Class Factor: $ClassFactor" }

		my $ClassRate = $self->HardRound($BaseRate * $ClassFactor,2);
      if ( $Debug ) { warn "After Class Factor: ClassRate - $ClassRate: MinCharge - $MinCharge" }

		# Get class cost
		$ClassCost = $self->HardRound(($ClassRate * $Weight/100),2);
		$ClassCost = $self->HardRound(($ClassCost * ( 1 - $DiscountPercent )),2);

		$MinCharge = $self->HardRound(($MinCharge * ( 1 - $DiscountPercent )),2);

		return ($ClassCost,$MinCharge);
	}

	sub GetRateAndMin
	{
		my $self = shift;
		my ($RateBase,$Class) = @_;

		my $STH_SQL = "
			SELECT
				$Class,
				mc
			FROM
				rate
			WHERE
				ratebase = '$RateBase'
		";

		my $STH = $self->{'dbref'}->prepare($STH_SQL)
			or die "Could not prepare mileage data select sql statement";

		$STH->execute()
			or die "Could not execute mileage data select sql statement";

		my ($Rate,$MinCharge) = $STH->fetchrow_array();

		$STH->finish();

		return ($Rate,$MinCharge);
	}

	sub GetClassFactor
	{
		my $self = shift;
		my ($RateBase,$Class,$WeightClass) = @_;

		$Class =~ s/\./_/;

		my $SQL = "
			SELECT
				c$Class
			FROM
				class
			WHERE
				weightclass = '$WeightClass'
				AND startratebase <= $RateBase
				AND endratebase >= $RateBase
		";

		my $STH = $self->{'dbref'}->prepare($SQL)
			or die "Could not prepare class factor sql statement";

		$STH->execute
			or warn "Could not execute class factor sql statement";

		my ($ClassFactor) = $STH->fetchrow_array();

		$STH->finish();

		return ($ClassFactor)
	}

	sub GetAdjustmentsList
	{
		my $self = shift;
		my ($Zip1,$Zip2) = @_;
		my @AdjustmentList;

		my $SQL = "
			SELECT
				adjtablenumber
			FROM
				zipadj
			WHERE
				zipheadstart <= '$Zip1'
				AND zipheadstop >= '$Zip1'
				AND zipsidestart <= '$Zip2'
				AND zipsidestop >= '$Zip2'
		";

		my $STH = $self->{'dbref'}->prepare($SQL)
			or die "Could not prepare class factor sql statement";

		$STH->execute
			or die "Could not execute class factor sql statement";

		while ( my ($Adjustment) = $STH->fetchrow_array() )
		{
			push(@AdjustmentList,$Adjustment);
		}

		$STH->finish();

		return (@AdjustmentList);
	}

	sub GetAdjustment
	{
		my $self = shift;
		my ($AdjNumber,$Class,$WeightClass) = @_;

		$Class =~ s/\./_/;

		my $SQL = "
			SELECT
				c$Class,
				type
			FROM
				adjustment
			WHERE
				adjtablenumber = '$AdjNumber'
				AND weightclass = '$WeightClass'
			ORDER BY
				type DESC
		";

		my $STH = $self->{'dbref'}->prepare($SQL)
			or warn "Could not prepare class factor sql statement";

		$STH->execute
			or warn "Could not execute class factor sql statement";

		my ($Adjustment,$Type) = $STH->fetchrow_array();

		$STH->finish();

		return ($Adjustment,$Type)
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

	sub HardRound
	{
		my $self = shift;
		my ($Number,$Places) = @_;

		my $RoundedNumber = Math::BigFloat->new($Number);

		return $RoundedNumber->ffround(-$Places,'inf');
	}
}
1
