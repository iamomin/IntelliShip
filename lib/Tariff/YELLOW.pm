#!/usr/bin/perl -w

#==========================================================
#   Project:	ARRS
#
#   Filename:	YELLOW.pm
#
#   Date:		03/02/2006
#
#   Purpose:	Calculate rates based on Yellow Tariff
#
#   Company:	Engage TMS
#
#   Author(s):	Kirk Aksdal
#					Leigh Bohannon
#
#==========================================================

{
	package Tariff::YELLOW;

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
			dbname => 'yellow',
			dbhost => 'localhost',
			dbuser => 'webuser',
			dbpassword => 'Byt#Yu2e',
			autocommit => 1
		});

		bless($self, $class);

		return $self;
	}

	sub GetZipSuffix
	{
		my $self = shift;
		my ($Zip) = @_;

		my $STH_SQL = "
			SELECT
				zipsuffix
			FROM
				zipsuffix
			WHERE
				lowzip <= '$Zip'
				AND highzip >= '$Zip'
		";

		my $STH = $self->{'dbref'}->prepare($STH_SQL)
			or die "Could not prepare zipsuffix select sql statement";

		$STH->execute()
			or die "Could not execute zipsuffix select sql statement";

		my ($ZipSuffix) = $STH->fetchrow_array();

		$STH->finish();

		$ZipSuffix = $ZipSuffix ? $ZipSuffix : 'A';

		return $ZipSuffix;
	}

	sub GetClassRef
	{
		my $self = shift;
		my ($Class,$ClassConID,$Type) = @_;

		my $STH_SQL = "
			SELECT
				*
			FROM
				class
			WHERE
				class = '$Class'
				AND classconid = '$ClassConID'
		";

		if ( $Type )
		{
			$STH_SQL .= " AND type = '$Type'";
		}
		else
		{
			$STH_SQL .= " AND type IS NULL";
		}
#warn $STH_SQL;
		my $STH = $self->{'dbref'}->prepare($STH_SQL)
			or die "Could not prepare class select sql statement";

		$STH->execute()
			or die "Could not execute class select sql statement";

		my $ClassRef = $STH->fetchrow_hashref();

		$STH->finish();

		return $ClassRef;
	}

	sub GetRateRef
	{
		my $self = shift;
		my ($OriginZip,$DestZip,$OriginSuffix,$DestSuffix,$Rerate) = @_;

		my ($OriginZone) = $OriginZip =~ /^(\w{3})/;
		my ($DestZone) = $DestZip =~ /^(\w{3})/;

		my $STH_SQL = "
			SELECT
				*
			FROM
				baserate
			WHERE
				originzone = '$OriginZone'
				AND destinzone = '$DestZone'
		";

		if ( $OriginSuffix )
		{
			$STH_SQL .= "AND originsuffix = '$OriginSuffix'"
		}

		if ( $DestSuffix )
		{
			$STH_SQL .= "AND destinsuffix = '$DestSuffix'"
		}
#warn $STH_SQL;
		my $STH = $self->{'dbref'}->prepare($STH_SQL)
			or die "Could not prepare baserate select sql statement";

		$STH->execute()
			or die "Could not execute baserate select sql statement";

		my $RateRef = $STH->fetchrow_hashref();

		$STH->finish();

		if ( ( $RateRef->{'originsuffix'} || $RateRef->{'destinsuffix'} ) && !$Rerate )
		{
			$OriginSuffix = $RateRef->{'originsuffix'} ? $self->GetZipSuffix($OriginZip) : undef;
			$DestSuffix = $RateRef->{'destinsuffix'} ? $self->GetZipSuffix($DestZip) : undef;

			$RateRef = $self->GetRateRef($OriginZip,$DestZip,$OriginSuffix,$DestSuffix,1);
		}

		return $RateRef
	}

	sub GetCost
	{
		my $self = shift;
		my ($Weight,$DiscountPercent,$Class,$OriginZip,$DestZip) = @_;
		my $Cost = -1;

		# US/Canadian (to or from) shipment flag
		my $USCanadian = $self->GetUSCanadian($OriginZip,$DestZip);

		# Get basrate ref
		my $RateRef = $self->GetRateRef($OriginZip,$DestZip);

		# Get class ref
		my $ClassRef;
		my $NextClassRef;
		my $LTLRef;
		my $TLRef;

		if ( $RateRef->{'classconid'} )
		{
			$ClassRef = $self->GetClassRef($Class,$RateRef->{'classconid'});
			$NextClassRef = $ClassRef;
		}

		if ( $RateRef->{'ltlid'} )
		{
			$LTLRef = $self->GetClassRef($Class,$RateRef->{'ltlid'},'L');
		}

		if ( $RateRef->{'tlid'} )
		{
			$TLRef = $self->GetClassRef($Class,$RateRef->{'tlid'},'T');
		}

      # Get weight class info
      my $WtClassRef = $self->GetWeightClassInfo($Weight);
		if ( $Debug ) { WarnHashRefValues($WtClassRef) }

		if ( $RateRef->{'ltlid'} && $RateRef->{'tlid'} )
		{
			my $Type = $self->GetTLOrLTL($WtClassRef->{'class'});
			if ( $Type eq 'LTL' )
			{
				$ClassRef = $LTLRef;
			}
			elsif ( $Type eq 'TL' )
			{
				$ClassRef = $TLRef;
			}

			my $NextType = $self->GetTLOrLTL($WtClassRef->{'nextclass'});
			if ( $NextType eq 'LTL' )
			{
				$NextClassRef = $LTLRef;
			}
			elsif ( $NextType eq 'TL' )
			{
				$NextClassRef = $TLRef;
			}
		}

		# If class conversion factor = 0 for m20m, m30m, or m40m, need to drop a weight factor until we get a non-zerof value
		# Apply to both rates and class factors.
		$WtClassRef->{'class'} = $self->GetAdjustedWeightClass($ClassRef,$WtClassRef->{'class'});
		$WtClassRef->{'nextclass'} = $self->GetAdjustedWeightClass($ClassRef,$WtClassRef->{'nextclass'});

		my $AdjRef = $self->GetAdjRef($OriginZip,$DestZip);

		my $ClassRate = sprintf("%.4f",(($RateRef->{$WtClassRef->{'class'}} + $AdjRef->{$WtClassRef->{'class'}} ) * $ClassRef->{$WtClassRef->{'class'}}));
		my $ClassCost = sprintf("%.2f", $ClassRate * $Weight * ( 1 - $DiscountPercent ));
		my $MinCharge = sprintf("%.2f",($RateRef->{'mc'} * ( 1 - $DiscountPercent )));
		if ( $Debug ) { warn "Class Cost: $ClassCost, Class: $WtClassRef->{'class'}, MinCharge: $MinCharge"; }

		# Get cost for next class
      my $NextClassCost = 0;
      if ( $Weight < 99999 && $RateRef->{$WtClassRef->{'nextclass'}} )
      {
			my $NextClassRate = sprintf("%.4f",(($RateRef->{$WtClassRef->{'nextclass'}} + $AdjRef->{$WtClassRef->{'nextclass'}} ) * $NextClassRef->{$WtClassRef->{'nextclass'}}));
			$NextClassCost = sprintf("%.2f",($NextClassRate * $WtClassRef->{'nextminwt'} * ( 1 - $DiscountPercent )));
         if ( $Debug ) { warn "Next Class Cost: $NextClassCost, Next Class: $WtClassRef->{'nextclass'}"; }
      }

		# Take the cheaper of the real class cost or the next class cost
		if ( $NextClassCost > 0 )
		{
			$Cost = $ClassCost < $NextClassCost ? $ClassCost : $NextClassCost;
		}
		else
		{
			$Cost = $ClassCost;
		}

		# Take the more expensive of the cost or the min charge
		$Cost = $Cost > $MinCharge ? $Cost : $MinCharge;

		# Take the more expensive of the cost or the amc
		$Cost = $Cost > $RateRef->{'amc'} ? $Cost : $RateRef->{'amc'};

		return $Cost;
	}

	sub GetAdjustedWeightClass
	{
		my $self = shift;
		my ($ClassRef,$WeightClass) = @_;

		my ($ClassNumber) = $WeightClass =~ /(\d+)/;

		while ( $ClassRef->{$WeightClass} == 0 && $ClassNumber >= 20 )
		{
			$ClassNumber = $ClassNumber - 10;
			$WeightClass = "m${ClassNumber}m";
		}

		return $WeightClass;
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

	sub GetUSCanadian
	{
		my $self = shift;
		my ($FromZip,$ToZip) = @_;

		if ( $FromZip =~ /[A-Z]/ || $ToZip =~ /[A-Z]/ )
		{
			return 1;
		}
		else
		{
			return 0;
		}
	}

	sub GetTLOrLTL
	{
		my $self = shift;
		my ($WeightClass) = @_;

		if
		(
			$WeightClass eq 'l5c' ||
			$WeightClass eq 'm5c' ||
			$WeightClass eq 'm1m' ||
			$WeightClass eq 'm2m' ||
			$WeightClass eq 'm5m' ||
			$WeightClass eq 'm10m'
		)
		{
			return 'LTL';
		}
		elsif
		(
			$WeightClass eq 'm20m' ||
			$WeightClass eq 'm30m' ||
			$WeightClass eq 'm40m'
		)
		{
			return 'TL';
		}

	}

	sub GetAdjRef
	{
		my $self = shift;
		my ($FromZip,$ToZip) = @_;

		my $STH_SQL = "
			SELECT
				*
			FROM
				adjustment
			WHERE
				originzone = '$FromZip'
				OR
				destinzone = '$ToZip'
		";

		my $STH = $self->{'dbref'}->prepare($STH_SQL)
			or die "Could not prepare adjustment select sql statement";

		$STH->execute()
			or die "Could not execute adjustment select sql statement";

		my ($AdjRef) = $STH->fetchrow_hashref();

		$STH->finish();

		if ( !$AdjRef ) { $AdjRef = { mc=>0,l5c=>0,m5c=>0,m1m=>0,m2m=>0,m5m=>0,m10m=>0,m20m=>0,m30m=>0,m40m=>0} }

		return $AdjRef;
	}
}
1

