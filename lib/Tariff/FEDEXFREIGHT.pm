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
	package Tariff::FEDEXFREIGHT;

	use strict;
	use ARRS::COMMON;
	use ARRS::IDBI;

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

		my $STH_SQL = "
			SELECT
				tariffnumber
			FROM
				tariff
			WHERE
				originzip = '$FromZip'
				AND destzip = '$ToZip'
		";

		my $STH = $self->{'dbref'}->prepare($STH_SQL)
			or die "Could not prepare tariff number data select sql statement";

		$STH->execute()
			or die "Could not execute tariff number data select sql statement";

		my ($TariffNumber) = $STH->fetchrow_array();

		$STH->finish();

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
		my ($Weight,$DiscountPercent,$Class,$OriginZip,$DestZip) = @_;
		my $Cost = -1;

      # Get weight class info
      my $WtClassRef = $self->GetWeightClassInfo($Weight);
		if ( $Debug ) { WarnHashRefValues($WtClassRef) }

		# Get tariff number
		my $TariffNumber = $self->GetTariffNumber($self->GetNormalizedZip($OriginZip),$self->GetNormalizedZip($DestZip));

		# Get rate info
		my $RateRef = $self->GetRate($TariffNumber,$Class);

		my $ClassCost = sprintf("%.2f",($RateRef->{$WtClassRef->{'class'}} * $Weight * ( 1 - $DiscountPercent )));
		my $MinCharge = sprintf("%.2f",($self->GetMinCharge($Weight,$RateRef) * ( 1 - $DiscountPercent )));
		if ( $Debug ) { warn "Class Cost: $ClassCost, Class: $WtClassRef->{'class'}, MinCharge: $MinCharge"; }

		# Get cost for next class
      my $NextClassCost = 0;
      if ( $Weight < 99999 )
      {
			$NextClassCost = sprintf("%.2f",($RateRef->{$WtClassRef->{'nextclass'}} * $WtClassRef->{'nextminwt'} * ( 1 - $DiscountPercent )));
         if ( $Debug ) { warn "Next Class Cost: $NextClassCost, Next Class: $WtClassRef->{'nextclass'}"; }
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

