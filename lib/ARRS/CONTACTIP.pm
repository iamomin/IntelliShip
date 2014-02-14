#!/usr/bin/perl -w

#==========================================================
#   Project:	ARRS
#
#   Filename:	CONTACTIP.pm
#
#   Date:		10/12/2004
#
#   Purpose:	contactip handling
#
#   Company:	Engage TMS
#
#   Author(s):	Kirk Aksdal
#					Leigh Bohannon
#
#==========================================================

{
	package ARRS::CONTACTIP;

	use strict;

	use ARRS::DBOBJECT;
	@ARRS::CONTACTIP::ISA = ("ARRS::DBOBJECT");

	sub new
	{
		my $proto = shift;
		my $class = ref($proto) || $proto;

		my $self = $class->SUPER::new(@_);

		$self->{'object_tablename'} = 'contactip';
		$self->{'object_primarykey'} = 'contactipid';
		$self->{'object_fieldlist'} = ['contactipid','contactid','ipaddress'];

		bless($self, $class);
		return $self;
	}

	sub IsOwner
	{
		my $self = shift;

		return 1;
	}

	sub GetIPCount
	{
		my $self = shift;

		my $STH = $self->{'object_dbref'}->prepare("SELECT count(*) FROM contactip WHERE contactid=?")
			or die ("Could not prepare IPCount SQL");

		$STH->execute($self->{'object_contact'}->{'field_contactid'})
			or die ("Could not execute IPCount SQL");

		my ($IPCount) = $STH->fetchrow_array();

		$STH->finish();

		if ( !defined($IPCount) || $IPCount eq '' )
		{
			$IPCount = 0;
		}

		return $IPCount;
	}
}

1;
