#!/usr/bin/perl -w

#==========================================================
#   Project:	ARRS
#
#   Filename:	AIRPORTCODE.pm
#
#   Date:		08/18/2006
#
#   Purpose:	Airportcode table data handling
#
#   Company:	Engage TMS
#
#   Author(s):	Kirk Aksdal
#					Leigh Bohannon
#
#==========================================================

{
	package ARRS::AIRPORTCODE;

	use strict;

	use ARRS::DBOBJECT;
	@ARRS::AIRPORTCODE::ISA = ("ARRS::DBOBJECT");

	sub new
	{
		my $proto = shift;
		my $class = ref($proto) || $proto;

		my $self = $class->SUPER::new(@_);

		$self->{'object_tablename'} = 'airportcode';
		$self->{'object_primarykey'} = 'airportcodeid';
		$self->{'object_fieldlist'} = ['airportcodeid','carrierid','postalcode','airportcode','extratransit'];

		bless($self, $class);
		return $self;
	}

	sub GetExtraTransitTime
	{
		my $self = shift;
		my ($CarrierID,$PostalCode,$AirportCode) = @_;

		$self->{'object_issuper'} = 1;
		$self->LowLevelLoadAdvanced(undef,{carrierid=>$CarrierID,postalcode=>$PostalCode,airportcode=>$AirportCode});
		$self->{'object_issuper'} = 0;

		return $self->{'field_extratransit'};
	}
}

1;
