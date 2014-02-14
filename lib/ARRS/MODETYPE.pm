#!/usr/bin/perl -w

#==========================================================
#   Project:	ARRS
#
#   Filename:	MODETYPE.pm
#
#   Date:		12/29/2005
#
#   Purpose:	Handling of modetypes
#
#   Company:	Engage TMS
#
#   Author(s):	Kirk Aksdal
#					Leigh Bohannon
#
#==========================================================

{
	package ARRS::MODETYPE;

	use strict;
	use ARRS::DBOBJECT;
	@ARRS::MODETYPE::ISA = ("ARRS::DBOBJECT");

	sub new
	{
		my $proto = shift;
		my $class = ref($proto) || $proto;

		my $self = $class->SUPER::new(@_);

		$self->{'object_tablename'} = 'modetype';
		$self->{'object_primarykey'} = 'modetypeid';
		$self->{'object_fieldlist'} = ['modetypeid','mode'];

		bless($self, $class);
		return $self;
	}

	sub GetMode
	{
		my $self = shift;
		my ($CarrierName,$ServiceName) = @_;

		my $SQLString = "
			SELECT
				mode
			FROM
				carrier c,
				service s,
				modetype m
			WHERE
				c.carrierid = s.carrierid
				AND s.modetypeid = m.modetypeid
				AND upper(c.carriername) = upper(?)
				AND upper(s.servicename) = upper(?)
		";

		my $sth = $self->{'object_dbref'}->prepare($SQLString)
			or die "Could not prepare SQL statement";

		$sth->execute($CarrierName,$ServiceName)
			or die "Cannot execute sql statement";

		my ($Mode) = $sth->fetchrow_array();

		$sth->finish();

		if ( !defined($Mode) || $Mode eq '' ) { $Mode = undef; }

		return($Mode);
	}
}

1;
