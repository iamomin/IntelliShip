#!/usr/bin/perl -w

#==========================================================
#   Project:	ARRS
#
#   Filename:	CLASSDATA.pm
#
#   Date:		12/14/2005
#
#   Purpose:	CLASS table data handling
#
#   Company:	Engage TMS
#
#   Author(s):	Kirk Aksdal
#					Leigh Bohannon
#
#==========================================================

{
	package ARRS::CLASSDATA;

	use strict;

	use ARRS::DBOBJECT;
	@ARRS::CLASSDATA::ISA = ("ARRS::DBOBJECT");

	sub new
	{
		my $proto = shift;
		my $class = ref($proto) || $proto;

		my $self = $class->SUPER::new(@_);

		$self->{'object_tablename'} = 'classdata';
		$self->{'object_primarykey'} = 'classdataid';
		$self->{'object_fieldlist'} = ['classdataid','ownertypeid','ownerid','fak','classhigh','classlow','discountpercent'];

		bless($self, $class);
		return $self;
	}
}

1;
