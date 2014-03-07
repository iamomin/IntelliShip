#!/usr/bin/perl -w

#==========================================================
#   Project:	ARRS
#
#   Filename:	CZARLITE.pm
#
#   Date:		05/13/2008
#
#   Purpose:	Calculate rates based on Czar Lite Tariff
#
#   Company:	Engage TMS
#
#   Author(s):	Kirk Aksdal
#					Leigh Bohannon
#
#==========================================================

{
	package Tariff::CZARLITE;

	use strict;

	use ARRS::COMMON;
	use ARRS::IDBI;

        our $DB_HANDLE =  ARRS::IDBI->connect({
				dbname		=> 'czarlite',
				dbhost		=> 'localhost',
				dbuser		=> 'webuser',
				dbpassword	=> 'Byt#Yu2e',
				autocommit	=> 1
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
#			$self->{'dbref'} = ARRS::IDBI->connect({
#				dbname		=> 'czarlite',
#				dbhost		=> 'localhost',
#				dbuser		=> 'webuser',
#				dbpassword	=> 'Byt#Yu2e',
#				autocommit	=> 1
#			});
                        $self->{'dbref'} = $DB_HANDLE;
		}

		$self->{'ratetypeid'} = $RateTypeID ? $RateTypeID : 'CZARLITE00001';

		bless($self, $class);

		return $self;
	}

	sub GetData
	{
		my $self = shift;
		my ($OriginZip,$DestZip,$Class) = @_;

		my $STH_SQL = "
			SELECT
				*
			FROM
				rate
			WHERE
				ratetypeid = '$self->{'ratetypeid'}'
				AND originbegin <= '$OriginZip'
				AND originend >= '$OriginZip'
				AND destbegin <= '$DestZip'
				AND destend >= '$DestZip'
				AND class = '$Class'
		";

		my $STH = $self->{'dbref'}->prepare($STH_SQL)
			or die "Could not prepare Czar Lite select sql statement";

		$STH->execute()
			or die "Could not execute Czar Lite select sql statement";

		my $CzarLiteData = $STH->fetchrow_hashref();

		$STH->finish();

		return $CzarLiteData
	}

	sub GetCost
	{
		my $self = shift;
		my ($Weight,$DiscountPercent,$Class,$OriginZip,$DestZip) = @_;
		my $Cost = -1;

		# If we have 0 weight, don't return a cost...
		if ( $Weight == 0 ) { return undef }

		if ( $Class =~ /(\d+)\.\d+/ ) { $Class = $1 }

		my $CzarLiteData = $self->GetData($OriginZip,$DestZip,$Class);

		if ( !defined($CzarLiteData) || $CzarLiteData eq '' )
		{
			return 0;
		}

		my ($WeightClassCost,$NextWeightClassCost) = $self->GetWeightClassCosts($Weight,$CzarLiteData);

		# Compare actual weight class cost vs. next weight class cost.
		# Take the *lower* of the two.
		if
		(
			defined($NextWeightClassCost) &&
			$NextWeightClassCost > 0 &&
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
		my $MinCharge = $self->GetMinCharge($Weight,$CzarLiteData);

		if ( $Cost < $MinCharge )
		{
			$Cost = $MinCharge;
		}

		# Throw in discount
		my $CostPercent = (1 - $DiscountPercent);
		$Cost = $Cost * $CostPercent;

		# Set cost to two decimal places
		$Cost = sprintf("%02.2f", $Cost);

		return $Cost;
	}

	sub GetWeightClassCosts
	{
		my $self = shift;
		my ($Weight,$CzarLiteData) = @_;
		my $WeightClass = '';
		my $NextWeightClass = '';
		my $NextWtClassMinWt = 0;

		if ( $Weight >= 1 && $Weight <= 499 )
		{
			$WeightClass = 'l5c';
			$NextWeightClass = 'm5c';
			$NextWtClassMinWt = 500;
		}
		elsif ( $Weight >= 500 && $Weight <= 999 )
		{
			$WeightClass = 'm5c';
			$NextWeightClass = 'm1m';
			$NextWtClassMinWt = 1000;
		}
		elsif ( $Weight >= 1000 && $Weight <= 1999 )
		{
			$WeightClass = 'm1m';
			$NextWeightClass = 'm2m';
			$NextWtClassMinWt = 2000;
		}
		elsif ( $Weight >= 2000 && $Weight <= 4999 )
		{
			$WeightClass = 'm2m';
			$NextWeightClass = 'm5m';
			$NextWtClassMinWt = 5000;
		}
		elsif ( $Weight >= 5000 && $Weight <= 9999 )
		{
			$WeightClass = 'm5m';
			$NextWeightClass = 'm10m';
			$NextWtClassMinWt = 10000;
		}
		elsif ( $Weight >= 10000 && $Weight <= 19999 )
		{
			$WeightClass = 'm10m';
			$NextWeightClass = 'm20m';
			$NextWtClassMinWt = 20000;
		}
		elsif ( $Weight >= 20000 && $Weight <= 29999 )
		{
			$WeightClass = 'm20m';
			$NextWeightClass = 'm30m';
			$NextWtClassMinWt = 30000;
		}
		elsif ( $Weight >= 30000 && $Weight <= 39999 )
		{
			$WeightClass = 'm30m';
			$NextWeightClass = 'm40m';
			$NextWtClassMinWt = 40000;
		}
		elsif ( $Weight >= 40000 )
		{
			$WeightClass = 'm40m';
		}

		my $WeightClassCost;
		my $NextWeightClassCost;

		$WeightClassCost = ($CzarLiteData->{$WeightClass} * $Weight) / 100;

		if ( defined($NextWeightClass) && $NextWeightClass ne '' )
		{
			$NextWeightClassCost = ($CzarLiteData->{$NextWeightClass} * $NextWtClassMinWt) / 100;
		}
		else
		{
			undef($NextWeightClassCost);
		}

		return ($WeightClassCost,$NextWeightClassCost);
	}

	sub GetMinCharge
	{
		my $self = shift;
		my ($Weight,$CzarLiteData) = @_;
		my $MinCharge = 0;

		my ($territory_number,$territory_letter) = $CzarLiteData->{'rbno'} =~ /(\d+)([A-Z])/;

		if ( $territory_number > 10000 && $territory_letter eq 'A' )
		{
			if ( $Weight >= 1 && $Weight <= 99) { $MinCharge = $CzarLiteData->{'mc1'} }
			elsif ( $Weight >= 100 && $Weight <= 149) { $MinCharge = $CzarLiteData->{'mc2'} }
			elsif ( $Weight >= 150 && $Weight <= 199) { $MinCharge = $CzarLiteData->{'mc3'} }
			elsif ( $Weight >= 200 && $Weight <= 249) { $MinCharge = $CzarLiteData->{'mc4'} }
			elsif ( $Weight >= 250 && $Weight <= 299) { $MinCharge = $CzarLiteData->{'mc5'} }
			elsif ( $Weight >= 300 && $Weight <= 399) { $MinCharge = $CzarLiteData->{'mc6'} }
			elsif ( $Weight >= 400 && $Weight <= 499) { $MinCharge = $CzarLiteData->{'mc7'} }
			elsif ( $Weight >= 500 ) { $MinCharge = $CzarLiteData->{'mc8'} }
		}
		elsif ( $territory_letter eq 'H' )
		{
			if ( $Weight >= 1 && $Weight <= 149) { $MinCharge = $CzarLiteData->{'mc1'} }
			elsif ( $Weight >= 150 && $Weight <= 299) { $MinCharge = $CzarLiteData->{'mc2'} }
			elsif ( $Weight >= 300 ) { $MinCharge = $CzarLiteData->{'mc3'} }
		}
		elsif ( defined($CzarLiteData->{'mc1'}) && $CzarLiteData->{'mc1'} > 0 )
		{
			$MinCharge = $CzarLiteData->{'mc1'};
		}

		return $MinCharge;
	}
}
1
