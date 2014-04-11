#!/usr/bin/perl -w

#==========================================================
#   Project:	ARRS
#
#   Filename:	AIPORTTRANSIT.pm
#
#   Date:		08/06/2004
#
#   Purpose:	Airport-Airport Transit Handling
#
#   Company:	Engage TMS
#
#   Author(s):	Kirk Aksdal
#					Leight Bohannon
#
#==========================================================

{
	package ARRS::AIRPORTTRANSIT;

	use strict;

	use ARRS::DBOBJECT;
	@ARRS::AIRPORTTRANSIT::ISA = ("ARRS::DBOBJECT");

	use ARRS::AIRPORTCODE;
	use ARRS::COMMON;

	sub new
	{
		my $proto = shift;
		my $class = ref($proto) || $proto;

		my $self = $class->SUPER::new(@_);

		$self->{'object_tablename'} = 'airporttransit';
		$self->{'object_primarykey'} = 'airporttransitid';
		$self->{'object_fieldlist'} = ['airporttransitid','carrierid','origincode','destcode','transittime'];

		bless($self, $class);
		return $self;
	}

	sub GetAirportToAirportTransitTime
	{
		my $self = shift;
		my ($FromZip,$ToZip,$CarrierID,$ExtraTransit) = @_;
		my $AirportToAirportTransitTime = 0;
		my ($OriginCode,$DestCode);

		my $TransitSQL = "
			SELECT
				transittime,
				origincode,
				destcode
			FROM
				airporttransit at
			WHERE
				at.carrierid = '$CarrierID'
				AND at.origincode =
				(
					SELECT
						airportcode
					FROM
						airportcode
					WHERE
						carrierid = '$CarrierID'
						AND postalcode = '$FromZip'
				)
				AND at.destcode =
				(
					SELECT
						airportcode
					FROM
						airportcode
					WHERE
						carrierid = '$CarrierID'
						AND postalcode = '$ToZip'
				)
		";

		my $STH = $self->{'object_dbref'}->prepare($TransitSQL)
			or TraceBack("Could not prepare transittime sql statement",1);

		$STH->execute
			or TraceBack("Could not execute transittime sql statement",1);

		if ( ($AirportToAirportTransitTime,$OriginCode,$DestCode) = $STH->fetchrow_array() )
		{
			# Add in extra transit time as spec'd by the carrier
			if ( $ExtraTransit )
			{
				my $APC = new ARRS::AIRPORTCODE($self->{'object_dbref'}, $self->{'contact'});

				$AirportToAirportTransitTime += $APC->GetExtraTransitTime($CarrierID,$FromZip,$OriginCode);
				$AirportToAirportTransitTime += $APC->GetExtraTransitTime($CarrierID,$ToZip,$DestCode);
			}
		}

		return $AirportToAirportTransitTime;
	}
}

1;
