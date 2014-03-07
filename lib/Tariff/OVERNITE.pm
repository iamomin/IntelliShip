#!/usr/bin/perl -w

#==========================================================
#   Project:	ARRS
#
#   Filename:	OVERNITE.pm
#
#   Date:		04/26/2004
#
#   Purpose:	Calculate rates based on Rocky Mountain Tariff
#
#   Company:	Engage TMS
#
#   Author(s):	Kirk Aksdal
#					Leigh Bohannon
#
#==========================================================

{
	package Tariff::OVERNITE;

	use strict;
	use ARRS::COMMON;
	use ARRS::IDBI;

        our $DB_HANDLE = ARRS::IDBI->connect({
				dbname => 'overnite',
				dbhost => 'localhost',
				dbuser => 'webuser',
				dbpassword => 'Byt#Yu2e',
				autocommit => 1
			});

	sub new
	{
		my $proto = shift;
		my $class = ref($proto) || $proto;

		my ($DBRef,$RateTypeID) = @_;

		my $self = {};

		if ( $DBRef )
		{
			$self->{'dbref'} = $DBRef;
		}
		else
		{
			$self->{'dbref'} = $DB_HANDLE;
		}

		$self->{'ratetypeid'} = $RateTypeID;

		bless($self, $class);

		return $self;
	}

	sub GetData
	{
		my $self = shift;
		my ($OriginZip,$DestZip,$Weight) = @_;

		my ($ShortOriginZip) = $OriginZip =~ /(\d{3})\d{2}/;
		my ($ShortDestZip) = $DestZip =~ /(\d{3})\d{2}/;

		my $STH_SQL = "
			SELECT
				*
			FROM
				baserate
			WHERE
				originzip = '$ShortOriginZip'
				AND destzip = '$ShortDestZip'
				AND ratetypeid = '$self->{'ratetypeid'}'
		";

		my $STH = $self->{'dbref'}->prepare($STH_SQL)

			or die "Could not prepare Czar Lite select sql statement";

		$STH->execute()
			or die "Could not execute Czar Lite select sql statement";

		my $OverniteData = $STH->fetchrow_hashref();

		$STH->finish();

		($OverniteData->{'weightclass'},$OverniteData->{'nextweightclass'},$OverniteData->{'nextwtclassminwt'}) =
			$self->GetWeightClassInfo($Weight);

		return $OverniteData;
	}

	sub GetCost
	{
		my $self = shift;
		my ($Weight,$DiscountPercent,$Class,$OriginZip,$DestZip) = @_;
		my $Cost = -1;

		# If we have 0 weight, don't return a cost...
		if ( $Weight == 0 ) { return undef }

		# Kludge for Technicolor
		if ( $Class == 77 ) { $Class = 77.5 }

		# Out of range for overnite
		if ( $Weight > 19999 )
		{
			# Disco the DB on our way out
			$self->{'dbref'}->disconnect();
			return $Cost;
		}

		my $OverniteData = $self->GetData($OriginZip,$DestZip,$Weight);

		my @ArbitraryFactors = $self->GetArbitraryFactorList($OriginZip,$DestZip);

		my $MinCharge = $OverniteData->{'1mc'};

		my $MinChargePercentAdj = 0;
		my $MinChargeDollarAdj = 0;
		my $WeightClassCostPercentAdj = 0;
		my $WeightClassCostDollarAdj = 0;
		my $NextWeightClassCostPercentAdj = 0;
		my $NextWeightClassCostDollarAdj = 0;

		foreach my $ArbitraryFactor (@ArbitraryFactors)
		{
			my ($ArbitraryFactorData) = $self->GetArbitraryFactor($ArbitraryFactor, $Class);

			# Percent adjustment
			if ( $ArbitraryFactorData->{'mc_adj_type'} eq '1' )
			{
				my $MCPercentAdj = $ArbitraryFactorData->{'mc_adj'} - 1;
				$MinChargePercentAdj += $MCPercentAdj;
			}
			# Dollar adjustment
			elsif ( $ArbitraryFactorData->{'mc_adj_type'} eq '2' )
			{
				$MinChargeDollarAdj += $ArbitraryFactorData->{'mc_adj'};
			}

			# Percent adjustment
			if ( $ArbitraryFactorData->{'rate_adj_type'} eq '1' )
			{
				my $WCCPercentAdj = $ArbitraryFactorData->{$OverniteData->{'weightclass'}} - 1;
				$WeightClassCostPercentAdj += $WCCPercentAdj;
			}
			# Dollar adjustment
			elsif ( $ArbitraryFactorData->{'rate_adj_type'} eq '2' )
			{
				$WeightClassCostDollarAdj += $ArbitraryFactorData->{$OverniteData->{'weightclass'}};
			}

			# Percent adjustment
			if ( defined($ArbitraryFactorData->{$OverniteData->{'nextweightclass'}}) && $ArbitraryFactorData->{'rate_adj_type'} eq '1' )
			{
				my $NWCCPercentAdj = $ArbitraryFactorData->{$OverniteData->{'nextweightclass'}} - 1;
				$NextWeightClassCostPercentAdj += $NWCCPercentAdj;
			}
			# Dollar adjustment
			elsif ( defined($ArbitraryFactorData->{$OverniteData->{'nextweightclass'}}) && $ArbitraryFactorData->{'rate_adj_type'} eq '2' )
			{
				$NextWeightClassCostDollarAdj += $ArbitraryFactorData->{$OverniteData->{'nextweightclass'}};
			}
		}

		if ( $MinChargeDollarAdj > 0 )
		{
			$MinCharge += $MinChargeDollarAdj;
		}

		if ( $MinChargePercentAdj > 0 )
		{
			$MinCharge *= ( $MinChargePercentAdj + 1 ) ;
		}

		if ( $WeightClassCostDollarAdj > 0 )
		{
			$OverniteData->{$OverniteData->{'weightclass'}} += $WeightClassCostDollarAdj;
		}

		if ( $WeightClassCostPercentAdj > 0 )
		{
			$OverniteData->{$OverniteData->{'weightclass'}} =
				( $OverniteData->{$OverniteData->{'weightclass'}} * ($WeightClassCostPercentAdj + 1) );
		}

		if ( $NextWeightClassCostDollarAdj > 0 )
		{
			$OverniteData->{$OverniteData->{'nextweightclass'}} += $NextWeightClassCostDollarAdj
		}

		if ( $NextWeightClassCostPercentAdj > 0 )
		{
			$OverniteData->{$OverniteData->{'nextweightclass'}} =
				( $OverniteData->{$OverniteData->{'nextweightclass'}} * ($NextWeightClassCostPercentAdj + 1) );
		}

		# Get weight class costs with rates modified by arbitrary factors
		my ($WeightClassCost,$NextWeightClassCost) = $self->GetWeightClassCosts($Weight,$OverniteData);

		# Modify weight class costs with class factors
		$WeightClassCost *= $self->GetClassFactor($OverniteData->{'weightclass'},$Class,$OverniteData->{'classfactortable'});

		if ( defined($OverniteData->{'nextweightclass'}) && $OverniteData->{'nextweightclass'} ne '' )
		{
			$NextWeightClassCost *= $self->GetClassFactor($OverniteData->{'nextweightclass'},$Class,$OverniteData->{'classfactortable'});
		}

		# Compare actual weight class cost vs. next weight class cost.
		# Take the *lower* of the two.
		if
		(
			defined($NextWeightClassCost) &&
			$NextWeightClassCost < $WeightClassCost
		)
		{
			$Cost = $NextWeightClassCost;
		}
		else
		{
			$Cost = $WeightClassCost;
		}

		# Compare current cost value with minimum charge.
		# Take the *higher* of the two.

		if ( $Cost < $MinCharge )
		{
			$Cost = $MinCharge;
		}

		# Throw in discount
		my $CostPercent = (1 - $DiscountPercent);
		$Cost = $Cost * $CostPercent;

		# Set cost to two decimal places
		$Cost = sprintf("%02.2f", $Cost);

		# Disco the DB on our way out
		$self->{'dbref'}->disconnect();

		return $Cost;
	}

	sub GetWeightClassCosts
	{
		my $self = shift;
		my ($Weight,$OverniteData) = @_;

		my $WeightClassCost;
		my $NextWeightClassCost;

		$WeightClassCost = ($OverniteData->{$OverniteData->{'weightclass'}} * $Weight) / 100;

		if ( defined($OverniteData->{'nextweightclass'}) && $OverniteData->{'nextweightclass'} ne '' )
		{
			$NextWeightClassCost =
				($OverniteData->{$OverniteData->{'nextweightclass'}} * $OverniteData->{'nextwtclassminwt'}) / 100;
		}
		else
		{
			undef($NextWeightClassCost);
		}

		return ($WeightClassCost,$NextWeightClassCost);
	}

	sub GetWeightClassInfo
	{
		my $self = shift;
		my ($Weight) = @_;

		my $WeightClass = '';
		my $NextWeightClass = '';
		my $NextWtClassMinWt = 0;

		if ( $Weight >= 1 && $Weight <= 499 )
		{
			$WeightClass = 'l5c';
			$NextWeightClass = '5c';
			$NextWtClassMinWt = 500;
		}
		elsif ( $Weight >= 500 && $Weight <= 999 )
		{
			$WeightClass = '5c';
			$NextWeightClass = '1m';
			$NextWtClassMinWt = 1000;
		}
		elsif ( $Weight >= 1000 && $Weight <= 1999 )
		{
			$WeightClass = '1m';
			$NextWeightClass = '2m';
			$NextWtClassMinWt = 2000;
		}
		elsif ( $Weight >= 2000 && $Weight <= 4999 )
		{
			$WeightClass = '2m';
			$NextWeightClass = '5m';
			$NextWtClassMinWt = 5000;
		}
		elsif ( $Weight >= 5000 && $Weight <= 9999 )
		{
			$WeightClass = '5m';
			$NextWeightClass = '10m';
			$NextWtClassMinWt = 10000;
		}
		elsif ( $Weight >= 10000 && $Weight <= 19999 )
		{
			$WeightClass = '10m';
		}

		return ($WeightClass,$NextWeightClass,$NextWtClassMinWt);
	}

	sub GetArbitraryFactorList
	{
		my $self = shift;
		my ($OriginZip,$DestZip) = @_;
		my @ArbitraryFactors = ();

		my $STH = $self->{'dbref'}->prepare("
			SELECT
				arbitraryfactor
			FROM
				arbitraryfactorzip
			WHERE
				(
					originbegin <= '$OriginZip' AND
					originend >= '$OriginZip' AND
					destbegin <= '$DestZip' AND
					destend >= '$DestZip'
				)
				AND ratetypeid = '$self->{'ratetypeid'}'
		")
			or die "Could not prepare arbitrary factor sql statement";

		$STH->execute
			or die "Could not execute arbitrary factor sql statement";

		while ( my ($ArbitraryFactor) = $STH->fetchrow_array() )
		{
			push(@ArbitraryFactors,$ArbitraryFactor);
		}

		$STH->finish();

		return @ArbitraryFactors;
	}

	sub GetArbitraryFactor
	{
		my $self = shift;
		my ($ArbitraryFactorNumber,$Class) = @_;

		$Class =~ s/\./_/g;

		my $SQL = "
			SELECT
				*
			FROM
				arbitraryfactor
			WHERE
				arbitraryfactor = '$ArbitraryFactorNumber'
				AND ratetypeid = '$self->{'ratetypeid'}'
		";

		my $STH = $self->{'dbref'}->prepare($SQL)
			or die "Could not prepare arbitrary factor sql statement";

		$STH->execute
			or die "Could not execute arbitrary factor sql statement";

		my $ArbitraryFactor = $STH->fetchrow_hashref();

		$STH->finish();

		my @WeightClassAdj = unpack ("A5 A5 A5 A5 A5 A5", $ArbitraryFactor->{'class' . $Class});

		$ArbitraryFactor->{'l5c'} = $WeightClassAdj[0]/10000;
		$ArbitraryFactor->{'5c'} = $WeightClassAdj[1]/10000;
		$ArbitraryFactor->{'1m'} = $WeightClassAdj[2]/10000;
		$ArbitraryFactor->{'2m'} = $WeightClassAdj[3]/10000;
		$ArbitraryFactor->{'5m'} = $WeightClassAdj[4]/10000;
		$ArbitraryFactor->{'10m'} = $WeightClassAdj[5]/10000;

		return ($ArbitraryFactor);
	}

	sub GetClassFactor
	{
		my $self = shift;
		my ($WeightClass,$Class,$FactorTableNumber) = @_;
		my $ClassFactor;

		if ( defined($FactorTableNumber) && $FactorTableNumber ne '' )
		{
			$Class =~ s/\./_/;

			my $SQL = "
				SELECT
					*
				FROM
					classfactor c
				WHERE
					factortablenumber = '$FactorTableNumber'
					AND freightclass = '$Class'
					AND ratetypeid = '$self->{'ratetypeid'}'
			";

			my $STH = $self->{'dbref'}->prepare($SQL)
				or die "Could not prepare class factor sql statement";

			$STH->execute
				or die "Could not execute class factor sql statement";

			my $ClassFactorRef = $STH->fetchrow_hashref();

			$ClassFactor = $ClassFactorRef->{$WeightClass};

			$STH->finish();
		}

		return ($ClassFactor);
	}
}
1

