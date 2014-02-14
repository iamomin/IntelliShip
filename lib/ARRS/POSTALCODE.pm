#!/usr/bin/perl -w

#==========================================================
#   Project:	ARRS
#
#   Filename:	POSTALCODE.pm
#
#   Date:		08/06/2003
#
#   Purpose:	Postalcode Handling
#
#   Company:	Engage TMS
#
#   Author(s):	Kirk Aksdal
#					Leigh Bohannon
#
#==========================================================

{
	package ARRS::POSTALCODE;

	use strict;
	use ARRS::DBOBJECT;
	@ARRS::POSTALCODE::ISA = ("ARRS::DBOBJECT");

	use ARRS::COMMON;

	sub new
	{
		my $proto = shift;
		my $class = ref($proto) || $proto;

		my $self = $class->SUPER::new(@_);

		$self->{'object_tablename'} = 'postalcode';
		$self->{'object_primarykey'} = 'postalcode';
		$self->{'object_fieldlist'} = ['province','city','lat','long','airportcode','baxairportcode','roadwayairportcode','roadwayextratransit'];

		bless($self, $class);
		return $self;
	}
}

1;
