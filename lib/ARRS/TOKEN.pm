#!/usr/bin/perl -w

#==========================================================
#   Project:	ARRS
#
#   Filename:	TOKEN
#
#   Date:		02/14/2002
#
#   Purpose:	Token Handling
#
#   Company:	Engage TMS
#
#   Author(s):	Kirk Aksdal
#					Leigh Bohannon
#
#==========================================================

{
	package ARRS::TOKEN;

	use strict;
	use ARRS::DBOBJECT;
	@ARRS::TOKEN::ISA = ("ARRS::DBOBJECT");

	use ARRS::COMMON;

	sub new
	{
		my $proto = shift;
		my $class = ref($proto) || $proto;

		my $self = $class->SUPER::new(@_);

		# Override these properties
		$self->{'object_tablename'} = 'token';
		$self->{'object_primarykey'} = 'tokenid';
		$self->{'object_fieldlist'} = ['tokenid','contactid','datecreated','dateexpires','ipaddress'];

		bless($self, $class);
		return $self;
	}

	sub IsOwner
	{
		my $self = shift;

		return 0;
	}
}

1;
