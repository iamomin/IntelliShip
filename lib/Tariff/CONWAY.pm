#!/usr/bin/perl -w

#==========================================================
#   Project:	ARRS
#
#   Filename:	CONWAY.pm
#
#   Date:		12/27/2005
#
#   Purpose:	Calculate rates based on ConWay Tariff
#
#   Company:	Engage TMS
#
#   Author(s):	Kirk Aksdal
#					Leigh Bohannon
#
#==========================================================

{
	package Tariff::CONWAY;

	use strict;

	use ARRS::COMMON;
	use ARRS::IDBI;

	my $Debug = 0;

        our $DB_HANDLE = ARRS::IDBI->connect({
				dbname => 'conway',
				dbhost => 'localhost',
				dbuser => 'webuser',
				dbpassword => 'Byt#Yu2e',
				autocommit => 1
			});

	sub new
	{
		my $proto = shift;
		my $class = ref($proto) || $proto;

		my ($DBRef) = @_;

		my $self = {};

		if ( $DBRef )
		{
			$self->{'dbref'} = $DBRef;
		}
		else
		{
#			$self->{'dbref'} = ARRS::IDBI->connect({
#				dbname => 'conway',
#				dbhost => 'localhost',
#				dbuser => 'webuser',
#				dbpassword => 'Byt#Yu2e',
#				autocommit => 1
#			});
                        $self->{'dbref'} = $DB_HANDLE;
		}

		bless($self, $class);

		return $self;
	}

	sub GetBaseZipAndArbPointer
	{
		my $self = shift;
		my ($Zip,$Type) = @_;

		my $STH_SQL = "
			SELECT
				basezip,
				${Type}arb
			FROM
				point
			WHERE
				lowzip <= '$Zip'
				AND highzip >= '$Zip'
			LIMIT 1
		";
warn $STH_SQL if $Debug;
		my $STH = $self->{'dbref'}->prepare($STH_SQL)
			or die "Could not prepare point data select sql statement";

		$STH->execute()
			or die "Could not execute point data select sql statement";

		my ($BaseZip,$ArbPointer) = $STH->fetchrow_array();
warn "|$BaseZip|$ArbPointer|" if $Debug;
		$STH->finish();

		return($BaseZip,$ArbPointer);
	}

	sub GetRateSectionAndBasis
	{
		my $self = shift;
		my ($OriginZip,$DestinZip) = @_;

		my $STH_SQL = "
			SELECT
				ratesection,
				basis
			FROM
				lane
			WHERE
				originzip = '$OriginZip'
				AND destinzip = '$DestinZip'
			LIMIT 1
		";
warn $STH_SQL if $Debug;
		my $STH = $self->{'dbref'}->prepare($STH_SQL)
			or die "Could not prepare lane data select sql statement";

		$STH->execute()
			or die "Could not execute lane data select sql statement";

		my ($RateSection,$Basis) = $STH->fetchrow_array();
warn "|$RateSection|$Basis|" if $Debug;
		$STH->finish();

		return($RateSection,$Basis);
	}

	sub GetRateAndMC
	{
		my $self = shift;
		my ($RateNumber,$Basis,$Class) = @_;

		my $STH_SQL = "
			SELECT
				rt$RateNumber,
				mc1
			FROM
				longrate
			WHERE
				basis = '$Basis'
				AND class = '$Class'
			LIMIT 1
		";
warn $STH_SQL if $Debug;
		my $STH = $self->{'dbref'}->prepare($STH_SQL)
			or die "Could not prepare longrate data select sql statement";

		$STH->execute()
			or die "Could not execute longrate data select sql statement";

		my ($Rate,$MC) = $STH->fetchrow_array();
warn "|$Rate|$MC|" if $Debug;
		$STH->finish();

		return($Rate,$MC);
	}

	sub GetAMC
	{
		my $self = shift;
		my ($RateSection,$Class) = @_;

		my $STH_SQL = "
			SELECT
				amc
			FROM
				factor
			WHERE
				ratesection = '$RateSection'
				AND class = '$Class'
			LIMIT 1
		";
warn $STH_SQL if $Debug;
		my $STH = $self->{'dbref'}->prepare($STH_SQL)
			or die "Could not prepare amc data select sql statement";

		$STH->execute()
			or die "Could not execute amc data select sql statement";

		my ($AMC) = $STH->fetchrow_array();
warn "|$AMC|" if $Debug;
		$STH->finish();

		return($AMC);
	}

	sub GetArbs
	{
		my $self = shift;
		my ($RateNumber,$Basis) = @_;

		my $STH_SQL = "
			SELECT
				mcarb1,
				wtarb$RateNumber
			FROM
				arbitrary
			WHERE
				basis = '$Basis'
			LIMIT 1
		";
warn $STH_SQL if $Debug;
		my $STH = $self->{'dbref'}->prepare($STH_SQL)
			or die "Could not prepare arbitrary data select sql statement";

		$STH->execute()
			or die "Could not execute arbitrary data select sql statement";

		my ($ArbRate,$ArbMC) = $STH->fetchrow_array();
warn "|$ArbRate|$ArbMC|" if $Debug;
		$STH->finish();

		$ArbRate = ( defined($ArbRate) && $ArbRate > 0 ) ? $ArbRate : 1;
		$ArbMC = ( defined($ArbMC) && $ArbMC > 0 ) ? $ArbMC : 1;

		return($ArbRate,$ArbMC);
	}


	sub GetCost
	{
		my $self = shift;
		my ($Weight,$DiscountPercent,$Class,$OriginZip,$DestZip) = @_;
warn "|$Weight|$DiscountPercent|$Class|$OriginZip|$DestZip|" if $Debug;

		# Get point data for shipment
		my ($OriginBaseZip,$OriginArbPointer) = $self->GetBaseZipAndArbPointer($OriginZip,'origin');
		my ($DestinBaseZip,$DestinArbPointer) = $self->GetBaseZipAndArbPointer($DestZip,'destin');

		# Get lane data for shipment
		my ($RateSection,$Basis) = $self->GetRateSectionAndBasis($OriginBaseZip,$DestinBaseZip);

		# Get rate data for shipment
		if ( my $RateNumber = $self->GetRateNumber($Weight) )
		{
			# Straight weight rating
			my ($Rate,$MC) = $self->GetRateAndMC($RateNumber,$Basis,$Class);
			my ($OriginArbRate,$OriginArbMC) = $self->GetArbs($RateNumber,$OriginArbPointer);
			my ($DestinArbRate,$DestinArbMC) = $self->GetArbs($RateNumber,$DestinArbPointer);

			my $Cost = sprintf("%.2f", ($Rate * $OriginArbRate * $DestinArbRate * $Weight));
			$MC = sprintf("%.2f", ($MC * $OriginArbMC * $DestinArbMC));

			$Cost = $Cost > $MC ? $Cost : $MC;

warn "|$Cost|$MC|" if $Debug;
			# Defecit Weight Rating
			my $NextRateNumber = $RateNumber + 1;
			my ($NextRate,$NextMC) = $self->GetRateAndMC($NextRateNumber,$Basis,$Class);
			my ($OriginNextArbRate,$OriginNextArbMC) = $self->GetArbs($NextRateNumber,$OriginArbPointer);
			my ($DestinNextArbRate,$DestinNextArbMC) = $self->GetArbs($NextRateNumber,$DestinArbPointer);

			my $NextWeight = $self->GetNextWeight($Weight);
			my $NextCost = sprintf("%.2f", ($NextRate * $OriginNextArbRate * $DestinNextArbRate * $NextWeight));
			$NextMC = sprintf("%.2f", ($NextMC * $OriginNextArbMC * $DestinNextArbMC));

			$NextCost = $NextCost > $NextMC ? $NextCost : $NextMC;

			# Figure if we're using straight or defecit rating
			$Cost = $Cost < $NextCost ? $Cost : $NextCost;
			$Cost = sprintf("%.2f", ( (1 - $DiscountPercent) * $Cost));
warn "|$NextRate|$NextMC|" if $Debug;

			# Get AMC
			my $AMC = $self->GetAMC($RateSection,$Class);

			# Figure whether to use AMC or Cost
			$Cost = $Cost > $AMC ? $Cost : $AMC;

warn "|$Cost|" if $Debug;
			return $Cost;
		}
		else
		{
			return undef;
		}
	}

	sub GetRateNumber
	{
		my $self = shift;
		my ($Weight) = @_;

		if ( $Weight >= 0 && $Weight <= 499 )
		{
			return 1;
		}
		elsif ( $Weight >= 500 && $Weight <= 999 )
		{
			return 2;
		}
		elsif ( $Weight >= 1000 && $Weight <= 1999 )
		{
			return 3;
		}
		elsif ( $Weight >= 2000 && $Weight <= 4999 )
		{
			return 4;
		}
		elsif ( $Weight >= 5000 && $Weight <= 9999 )
		{
			return 5;
		}
		elsif ( $Weight >= 10000 && $Weight <= 14999 )
		{
			return 6;
		}
		elsif ( $Weight >= 15000 && $Weight <= 19999 )
		{
			return 7;
		}
		elsif ( $Weight >= 20000 && $Weight <= 24999 )
		{
			return 8;
		}
		elsif ( $Weight >= 25000 && $Weight <= 29999 )
		{
			return 9;
		}
		elsif ( $Weight >= 30000 && $Weight <= 39999 )
		{
			return 10;
		}
		else
		{
			return undef;
		}
	}

	sub GetNextWeight
	{
		my $self = shift;
		my ($Weight) = @_;

		if ( $Weight >= 0 && $Weight <= 499 )
		{
			return 500;
		}
		elsif ( $Weight >= 500 && $Weight <= 999 )
		{
			return 1000;
		}
		elsif ( $Weight >= 1000 && $Weight <= 1999 )
		{
			return 2000;
		}
		elsif ( $Weight >= 2000 && $Weight <= 4999 )
		{
			return 5000;
		}
		elsif ( $Weight >= 5000 && $Weight <= 9999 )
		{
			return 10000;
		}
		elsif ( $Weight >= 10000 && $Weight <= 14999 )
		{
			return 15000;
		}
		elsif ( $Weight >= 15000 && $Weight <= 19999 )
		{
			return 20000;
		}
		elsif ( $Weight >= 20000 && $Weight <= 24999 )
		{
			return 25000;
		}
		elsif ( $Weight >= 25000 && $Weight <= 29999 )
		{
			return 30000;
		}
		else
		{
			return undef;
		}
	}
}
1

