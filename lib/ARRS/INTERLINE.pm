#!/usr/bin/perl -w

#==========================================================
#   Project:	ARRS
#
#   Filename:	INTERLINE.pm
#
#   Date:		10/31/2007
#
#   Purpose:	Handling of interline zip table
#
#   Company:	Engage TMS
#
#   Author(s):	Kirk Aksdal
#					Leigh Bohannon
#
#==========================================================

{
	package ARRS::INTERLINE;

	use strict;
	use ARRS::DBOBJECT;
	@ARRS::INTERLINE::ISA = ("ARRS::DBOBJECT");

	sub new
	{
		my $proto = shift;
		my $class = ref($proto) || $proto;

		my $self = $class->SUPER::new(@_);

		$self->{'object_tablename'} = 'interline';
		$self->{'object_primarykey'} = 'interlineid';
		$self->{'object_fieldlist'} = ['interlineid','carrierid','zipbegin','zipend','quoteonly'];

		bless($self, $class);
		return $self;
	}
}

1;
