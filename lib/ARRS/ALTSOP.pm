#!/usr/bin/perl -w

#==========================================================
#   Project:	ARRS
#
#   Filename:	ALTSOP.pm
#
#   Date:		08/25/2005
#
#   Purpose:	Handling of customer alternate SOPs
#
#   Company:	Engage TMS
#
#   Author(s):	Kirk Aksdal
#					Leigh Bohannon
#
#==========================================================

{
	package ARRS::ALTSOP;

	use strict;

	use ARRS::DBOBJECT;
	@ARRS::ALTSOP::ISA = ("ARRS::DBOBJECT");

	sub new
	{
		my $proto = shift;
		my $class = ref($proto) || $proto;

		my $self = $class->SUPER::new(@_);

		$self->{'object_tablename'} = 'altsop';
		$self->{'object_primarykey'} = 'altsopid';
		$self->{'object_fieldlist'} = ['altsopid','key','value','sopid','altbillingaddressid','customerid'];

		bless($self, $class);
		return $self;
	}
}

1;
