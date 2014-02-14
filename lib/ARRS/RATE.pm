#!/usr/bin/perl -w

#==========================================================
#   Project:	ARRS
#
#   Filename:	RATE.pm
#
#   Date:		04/25/2002
#
#   Purpose:	Carrier Handling
#
#   Company:	Engage TMS
#
#   Author(s):	Kirk Aksdal
#					Leigh Bohannon
#
#==========================================================

{
	package ARRS::RATE;

	use strict;
	use ARRS::DBOBJECT;
	@ARRS::RATE::ISA = ("ARRS::DBOBJECT");

	sub new
	{
		my $proto = shift;
		my $class = ref($proto) || $proto;

		my $self = $class->SUPER::new(@_);

		$self->{'object_tablename'} = 'rate';
		$self->{'object_primarykey'} = 'rateid';
		$self->{'object_fieldlist'} = ['rateid','typeid','unitsstart','unitsstop','zonenumber','cost','costmin','costperweight'];

		bless($self, $class);
		return $self;
	}
}

1;
