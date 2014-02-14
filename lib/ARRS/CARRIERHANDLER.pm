#!/usr/bin/perl -w

#==========================================================
#   Project:	ARRS
#
#   Filename:	CARRIERHANDLER.pm
#
#   Date:		04/24/2002
#
#   Purpose:	Generic Carrier Handling
#
#   Company:	Engage TMS
#
#   Author(s):	Kirk Aksdal
#					Leigh Bohannon
#
#==========================================================

{
	package ARRS::CARRIERHANDLER;

	use strict;

	use ARRS::COMMON;

	use Date::Manip qw(ParseDate UnixDate);
	use POSIX qw(ceil);

	sub new
	{
		my $proto = shift;
		my $class = ref($proto) || $proto;

		my $self = {};
		($self->{'dbref'}, $self->{'contact'}) = @_;

		bless($self, $class);
		return $self;
	}

	sub GetETADate
	{
		my $self = shift;
		my ($ETARef) = @_;
		my $ETADate;

		# Use the calc'd carrier transit days, if available, otherwise, use the service.timeneededmax value
		my $TransitDays = $ETARef->{'transitdays'} ? $ETARef->{'transitdays'} : $ETARef->{'timeneededmax'};

		# Get day of week for date needed (for sat/sun delivery issues)
		if ( $ETARef->{'dateneeded'} )
		{
			my $SaturdayDelivery = $ETARef->{'cs'}->GetCSValue('satdelivery');
			my $SundayDelivery = $ETARef->{'cs'}->GetCSValue('sundelivery');

			# If this is a sat/sun delivery, and the service has sat/sun delivery, see if the eta lines up
			if
			(
				( $ETARef->{'downeeded'} eq 'Sat' && $SaturdayDelivery ) ||
				( $ETARef->{'downeeded'} eq 'Sun' && $SundayDelivery )
			)
			{
				# Arbitrarily add an extra day to sunday delivery next day shipments
				$TransitDays ++ if ( $SundayDelivery && $TransitDays == 1 );
				$ETADate = GetFutureDate($ETARef->{'datetoship'},$TransitDays);

				my $ParsedETADate = ParseDate($ETADate);
				my $ETADOW = UnixDate($ParsedETADate, "%a");

				unless ( $ETADOW eq $ETARef->{'downeeded'} )
				{
					undef($ETADate);
				}
			}
		}

		# Calc ETA date, based on ship date, transit days, and possible CS sat/sun transit
		if ( !$ETADate )
		{
			$ETADate = GetFutureBusinessDate(
				$ETARef->{'datetoship'},
				$TransitDays,
				$ETARef->{'cs'}->GetCSValue('sattransit'),
				$ETARef->{'cs'}->GetCSValue('suntransit'),
				$ETARef->{'downeeded'},
				$ETARef->{'norm_datetoship'},
			);
		}

		return $ETADate;
	}

	sub GetTLTransitDays
	{
		my $self = shift;
		my ($ETARef) = @_;

		require ARRS::ZIPMILEAGE;
		my $ZipMileage = new ARRS::ZIPMILEAGE($self->{'dbref'},$self->{'contact'});
		my $ShipmentMileage = $ZipMileage->GetMileage($ETARef->{'fromzip'},$ETARef->{'tozip'});
		my $ServiceMultiplier;

		if ( $ShipmentMileage <= 500 )
		{
			$ServiceMultiplier = 1.1
		}
		elsif ( $ETARef->{'servicename'} =~ /Team/ )
		{
			$ServiceMultiplier = 1.25
		}
		# This is the 'single' case - assume this failing all else.
		else
		{
			$ServiceMultiplier = 1.95
		}

		if ( $ServiceMultiplier)
		{
			my $TransitMinutes = $ServiceMultiplier * $ShipmentMileage;
			my $TransitHours = $TransitMinutes/60;
			my $TransitDays = ceil($TransitHours/24);

			return $TransitDays;
		}
		else
		{
			return undef;
		}
	}

	sub GetCarrierUnitType
	{
		my $self = shift;
		my ($Carrier,$UnitType) = @_;

		my $SQL = "
			SELECT
				${Carrier}unittype
			FROM
				unittype
			WHERE
				unittypename = '$UnitType'
		";

		my $STH = $self->{'dbref'}->{'aos'}->prepare($SQL)
			or die "Cannot prepare comment select sql statement";

		$STH->execute()
			or die "Cannot execute comment select sql statement";

		my ($CarrierUnitType) = $STH->fetchrow_array();

		$STH->finish();

		return $CarrierUnitType;
	}

	sub GetDateYYYYMMDD
	{
		my $self = shift;
		my ($date_string) = @_;

		if ( defined($date_string) && $date_string ne '' )
		{
			$date_string =~ s/(\d{2})\/(\d{2})\/(\d{4})/$3-$1-$2/;
		}
		else
		{
			my ($current_day, $current_month, $current_year) = (localtime)[3,4,5];
			$current_year = $current_year + 1900;
			$current_month = $current_month + 1;

			if ( $current_month !~ /\d\d/ ) { $current_month = "0" . $current_month; }
			if ( $current_day !~ /\d\d/ ) { $current_day = "0" . $current_day; }

			$date_string = $current_year . '-' . $current_month . '-' . $current_day;
		}

		return($date_string);
	}

	sub DimCheck
	{
		my $self = shift;

		return 1;
	}

	sub GetDimWeight
	{
		my $self = shift;
		my ($DimLength,$DimWidth,$DimHeight,$DimFactor) = @_;

		if
		(
			defined($DimLength) && $DimLength ne '' &&
			defined($DimWidth) && $DimWidth ne '' &&
			defined($DimLength) && $DimLength ne '' &&
			defined($DimFactor) && $DimFactor ne '' && $DimFactor > 0
		)
		{
			return(ceil ( ( $DimLength * $DimWidth * $DimHeight) / $DimFactor));
		}
		else
		{
			return (undef);
		}
	}

	sub GetTotalDims
	{
		my $self = shift;
		my @Dims = @_;

		my @SortedDims = sort {$b <=> $a} (@Dims);

		my $Length = shift(@SortedDims);
		my $Width = shift(@SortedDims);
		my $Height = shift(@SortedDims);

		return $Length + 2 * $Width + 2 * $Height;
	}

	# Dim Length presumably the longest dimension
	sub GetDimLength
	{
		my $self = shift;
		my @Dims = @_;

		my @SortedDims = sort {$b <=> $a} (@Dims);

		return shift(@SortedDims);
	}
}
1
