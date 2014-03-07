#!/usr/bin/perl -w

#==========================================================
#   Project:	ARRS
#
#   Filename:	FEDEXFREIGHT.pm
#
#   Date:		02/22/2006
#
#   Purpose:	Calculate rates based on FedEx Freight Tariff
#
#   Company:	Engage TMS
#
#   Author(s):	Kirk Aksdal
#					Leigh Bohannon
#
#==========================================================

{
	package Tariff::DAYTON;

	use strict;
	use ARRS::COMMON;
	use ARRS::IDBI;

	my $Debug = 0;

        our $DB_HANDLE = ARRS::IDBI->connect({
			dbname => 'dayton',
			dbhost => 'localhost',
			dbuser => 'webuser',
			dbpassword => 'Byt#Yu2e',
			autocommit => 1
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

	sub GetRateNumAndTerritory
	{
		my $self = shift;
		my ($FromZip,$ToZip) = @_;

		my ($Zip1,$Zip2);

		if ( $FromZip < $ToZip )
		{
			$Zip1 = $FromZip;
			$Zip2 = $ToZip;
		}
		else
		{
			$Zip1 = $ToZip;
			$Zip2 = $FromZip;
		}

		my ($ZipPrefix1) = $Zip1 =~ /(\d{3})\d{2}/;
		my ($ZipPrefix2) = $Zip2 =~ /(\d{3})\d{2}/;


		my $STH_SQL = "
			SELECT
				ratebasenumber,
				territorycode
			FROM
				matrix
			WHERE
				lowzip = '$ZipPrefix1'
				AND highzip = '$ZipPrefix2'
		";

		my $STH = $self->{'dbref'}->prepare($STH_SQL)
			or die "Could not prepare ratenum/territory data select sql statement";

		$STH->execute()
			or die "Could not execute ratenum/territory data select sql statement";

		my ($RateNum,$Territory) = $STH->fetchrow_array();

		$STH->finish();

		return ($RateNum,$Territory);
	}

	sub GetRate
	{
		my $self = shift;
		my ($RateNumber,$Territory,$Class) = @_;

		my $STH_SQL = "
			SELECT
				*
			FROM
				rate
			WHERE
				ratebasenumber = '$RateNumber'
				AND territorycode = '$Territory'
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

	sub GetLane
	{
		my $self = shift;
		my ($OriginZip,$DestZip) = @_;

		my $STH_SQL = "
			SELECT
				adjnumber
			FROM
				lane
			WHERE
				originbegin <= '$OriginZip'
				AND originend >= '$OriginZip'
				AND destinbegin <= '$DestZip'
				AND destinend >= '$DestZip'
		";

		my $STH = $self->{'dbref'}->prepare($STH_SQL)
			or die "Could not prepare lane select sql statement";

		$STH->execute()
			or die "Could not execute lane select sql statement";

		my ($AdjNumber) = $STH->fetchrow_array();

		$STH->finish();

		return $AdjNumber;
	}

	sub GetAdjustment
	{
		my $self = shift;
		my ($AdjNumber,$Class) = @_;

		if ( $AdjNumber )
		{
			my $STH_SQL = "
				SELECT
					*
				FROM
					adjust
				WHERE
					adjnumber = '$AdjNumber'
			";

			my $STH = $self->{'dbref'}->prepare($STH_SQL)
				or die "Could not prepare adjustment data select sql statement";

			$STH->execute()
				or die "Could not execute adjustment data select sql statement";

			my $AdjRef = $STH->fetchrow_hashref();

			$STH->finish();

			return $AdjRef
		}
	}

	sub GetCost
	{
		my $self = shift;
		my ($Weight,$DiscountPercent,$Class,$OriginZip,$DestZip) = @_;
		my $Cost = -1;

      # Get weight class info
      my $WtClassRef = $self->GetWeightClassInfo($Weight);
		if ( $Debug ) { WarnHashRefValues($WtClassRef) }

		# Get tariff number
		my ($RateNum,$Territory) = $self->GetRateNumAndTerritory($OriginZip,$DestZip);

		# Get rate info
		my $RateRef = $self->GetRate($RateNum,$Territory,$Class);
		if ( $Debug ) { WarnHashRefValues($RateRef) }

		my $ClassCost = sprintf("%.2f",($RateRef->{$WtClassRef->{'class'}} * $Weight * ( 1 - $DiscountPercent )));
		my $MinCharge = sprintf("%.2f",($RateRef->{'mc'} * ( 1 - $DiscountPercent )));
		if ( $Debug ) { warn "Class Cost: $ClassCost, Class: $WtClassRef->{'class'}, MinCharge: $MinCharge"; }

		# Get cost for next class
      my $NextClassCost = 0;
      if ( $Weight < 99999 )
      {
			$NextClassCost = sprintf("%.2f",($RateRef->{$WtClassRef->{'nextclass'}} * $WtClassRef->{'nextminwt'} * ( 1 - $DiscountPercent )));
         if ( $Debug ) { warn "Next Class Cost: $NextClassCost, Next Class: $WtClassRef->{'nextclass'}"; }
      }

		# Factor in adjustments
		if ( my $AdjRef = $self->GetAdjustment($self->GetLane($OriginZip,$DestZip),$Class) )
		{
			if ( $Debug ) { WarnHashRefValues($AdjRef) }
			$MinCharge = sprintf("%.2f",($MinCharge * $AdjRef->{'mc'}));
			$ClassCost = sprintf("%.2f",($ClassCost * $AdjRef->{$WtClassRef->{'class'}}));
			$NextClassCost = sprintf("%.2f",($NextClassCost * $AdjRef->{$WtClassRef->{'nextclass'}}));
		}

		# Take the cheaper of the real class cost or the next class cost
		$Cost = $ClassCost < $NextClassCost ? $ClassCost : $NextClassCost;

		# Take the more expensive of the cost or the min charge
		$Cost = $Cost > $MinCharge ? $Cost : $MinCharge;

		return $Cost;
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
}
1

