#!/usr/bin/perl -w

#==========================================================
#   Project:	ARRS
#
#   Filename:	ROADWAY.pm
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
	package Tariff::ROADWAY;

	use strict;
	use ARRS::COMMON;
	use ARRS::IDBI;

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
			$self->{'dbref'} = ARRS::IDBI->connect({
				dbname => 'roadway',
				dbhost => 'localhost',
				dbuser => 'webuser',
				dbpassword => 'Byt#Yu2e',
				autocommit => 1
			});
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
		";

		my $STH = $self->{'dbref'}->prepare($STH_SQL)

			or die "Could not prepare Czar Lite select sql statement";

		$STH->execute()
			or die "Could not execute Czar Lite select sql statement";

		my $RoadwayData = $STH->fetchrow_hashref();

		$STH->finish();

		($RoadwayData->{'weightclass'},$RoadwayData->{'nextweightclass'},$RoadwayData->{'nextwtclassminwt'}) =
			$self->GetWeightClassInfo($Weight);

		return $RoadwayData;
	}

	sub GetCost
	{
		my $self = shift;
		my ($Weight,$DiscountPercent,$Class,$OriginZip,$DestZip) = @_;
		my $Cost = -1;
#print STDERR "$Weight|$DiscountPercent|$Class|$OriginZip|$DestZip\n";
		# If we have 0 weight, don't return a cost...
		if ( $Weight == 0 ) { return undef }

		# Kludge for Technicolor
		if ( $Class == 77 ) { $Class = 77.5 }

		# Out of range for roadway
		if ( $Weight > 29999 )
		{
			# Disco the DB on our way out
			$self->{'dbref'}->disconnect();
			return $Cost;
		}

		my $RoadwayData = $self->GetData($OriginZip,$DestZip,$Weight);

		my @ArbitraryFactors = $self->GetArbitraryFactorList($OriginZip,$DestZip);

		my $MinCharge = $RoadwayData->{'1mc'};

		foreach my $ArbitraryFactor (@ArbitraryFactors)
		{
			my ($ArbitraryFactorData) = $self->GetArbitraryFactor($ArbitraryFactor);

			if ( $ArbitraryFactorData->{'1mc_type'} eq '%' )
			{
				$MinCharge = $MinCharge + ( $MinCharge * $ArbitraryFactorData->{'1mc'} );
			}
			elsif ( $ArbitraryFactorData->{'1mc_type'} eq '$' )
			{
				$MinCharge += $ArbitraryFactorData->{'1mc'};
			}

			if ( $ArbitraryFactorData->{$RoadwayData->{'weightclass'} . '_type'} eq '%' )
			{
				$RoadwayData->{$RoadwayData->{'weightclass'}} =
					$RoadwayData->{$RoadwayData->{'weightclass'}} +
					( $RoadwayData->{$RoadwayData->{'weightclass'}} * $ArbitraryFactorData->{$RoadwayData->{'weightclass'}});
			}
			elsif ( $ArbitraryFactorData->{$RoadwayData->{'weightclass'} . '_type'} eq '$' )
			{
				$RoadwayData->{$RoadwayData->{'weightclass'}} += $ArbitraryFactorData->{$RoadwayData->{'weightclass'}};
			}

			if ( defined($RoadwayData->{'nextweightclass'}) )
			{
				if ( $ArbitraryFactorData->{$RoadwayData->{'nextweightclass'} . '_type'} eq '%' )
				{
					$RoadwayData->{$RoadwayData->{'nextweightclass'}} =
						$RoadwayData->{$RoadwayData->{'nextweightclass'}} +
						( $RoadwayData->{$RoadwayData->{'nextweightclass'}} * $ArbitraryFactorData->{$RoadwayData->{'nextweightclass'}});
				}
				elsif ( $ArbitraryFactorData->{$RoadwayData->{'nextweightclass'} . '_type'} eq '$' )
				{
					$RoadwayData->{$RoadwayData->{'nextweightclass'}} += $ArbitraryFactorData->{$RoadwayData->{'nextweightclass'}};
				}
			}
		}

		my ($WeightClassCost,$NextWeightClassCost) = $self->GetWeightClassCosts($Weight,$RoadwayData);

		$WeightClassCost *= $self->GetClassFactor($RoadwayData->{'weightclass'},$Class,$RoadwayData->{'classfactortable'});

		if ( defined($RoadwayData->{'nextweightclass'}) )
		{
			$NextWeightClassCost *= $self->GetClassFactor($RoadwayData->{'nextweightclass'},$Class,$RoadwayData->{'classfactortable'});
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
#print STDERR "$Cost\n";
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
		my ($Weight,$RoadwayData) = @_;

		my $WeightClassCost;
		my $NextWeightClassCost;

		$WeightClassCost = ($RoadwayData->{$RoadwayData->{'weightclass'}} * $Weight) / 100;

		if ( defined($RoadwayData->{'nextweightclass'}) && $RoadwayData->{'nextweightclass'} ne '' )
		{
			$NextWeightClassCost =
				($RoadwayData->{$RoadwayData->{'nextweightclass'}} * $RoadwayData->{'nextwtclassminwt'}) / 100;
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

		my $WeightClass;
		my $NextWeightClass;
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
			$NextWeightClass = '20m';
			$NextWtClassMinWt = 20000;
		}
		elsif ( $Weight >= 20000 && $Weight <= 29999 )
		{
			$WeightClass = '20m';
		}

		return ($WeightClass,$NextWeightClass,$NextWtClassMinWt);
	}

	sub GetArbitraryFactorList
	{
		my $self = shift;
		my ($OriginZip,$DestZip) = @_;
		my @ArbitraryFactors = ();

		# Origin and destination split for speed reasons
		# Origin factors
		my $OriginSQL = "
			SELECT
				arbitraryfactor
			FROM
				arbitraryfactorzip
			WHERE
				originbegin <= '$OriginZip'
				AND originend >= '$OriginZip'
		";

		my $STH_Origin = $self->{'dbref'}->prepare($OriginSQL)
			or die "Could not prepare arbitrary factor sql statement";

		$STH_Origin->execute
			or die "Could not execute arbitrary factor sql statement";

		while ( my ($ArbitraryFactor) = $STH_Origin->fetchrow_array() )
		{
			push(@ArbitraryFactors,$ArbitraryFactor);
		}

		$STH_Origin->finish();

		# Destination factors
		my $DestSQL = "
			SELECT
				arbitraryfactor
			FROM
				arbitraryfactorzip
			WHERE
				destbegin <= '$DestZip'
				AND destend >= '$DestZip'
		";

		my $STH_Dest = $self->{'dbref'}->prepare($DestSQL)
			or die "Could not prepare arbitrary factor sql statement";

		$STH_Dest->execute
			or die "Could not execute arbitrary factor sql statement";

		while ( my ($ArbitraryFactor) = $STH_Dest->fetchrow_array() )
		{
			push(@ArbitraryFactors,$ArbitraryFactor);
		}

		$STH_Dest->finish();

		return @ArbitraryFactors;
	}

	sub GetArbitraryFactor
	{
		my $self = shift;
		my ($ArbitraryFactorNumber) = @_;

		my $SQL = "
			SELECT
				*
			FROM
				arbitraryfactor
			WHERE
				arbitraryfactor = '$ArbitraryFactorNumber'
		";

		my $STH = $self->{'dbref'}->prepare($SQL)
			or die "Could not prepare arbitrary factor sql statement";

		$STH->execute
			or die "Could not execute arbitrary factor sql statement";

		my ($ArbitraryFactor) = $STH->fetchrow_hashref();

		$STH->finish();

		return ($ArbitraryFactor);
	}

	sub GetClassFactor
	{
		my $self = shift;
		my ($WeightClass,$Class,$FactorTableNumber) = @_;
		my $ClassFactor;

		$Class =~ s/\./_/;

		if ( defined($FactorTableNumber) && $FactorTableNumber ne '' )
		{
			my $SQL = "
				SELECT
					class$Class
				FROM
					classfactor
				WHERE
					weightclass = '$WeightClass'
					AND factortablenumber = '$FactorTableNumber'
			";

			my $STH = $self->{'dbref'}->prepare($SQL)
				or die "Could not prepare class factor sql statement";

			$STH->execute
				or die "Could not execute class factor sql statement";

			($ClassFactor) = $STH->fetchrow_array();

			$STH->finish();
		}

		return ($ClassFactor);
	}
}
1

