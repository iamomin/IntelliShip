#!/usr/bin/perl -w

#==========================================================
#   Project:	ARRS
#
#   Filename:	ZONETYPE.pm
#
#   Date:		04/25/2002
#
#   Purpose:	Zonetype Handling
#
#   Company:	Engage TMS
#
#   Author(s):	Kirk Aksdal
#					Leigh Bohannon
#
#==========================================================

{
	package ARRS::ZONETYPE;

	use strict;

	my $config; BEGIN {$config = do "/opt/engage/arrs/arrs.conf";}

	use ARRS::DBOBJECT;
	@ARRS::ZONETYPE::ISA = ("ARRS::DBOBJECT");

	sub new
	{
		my $proto = shift;
		my $class = ref($proto) || $proto;

		my $self = $class->SUPER::new(@_);

		$self->{'object_tablename'} = 'zonetype';
		$self->{'object_primarykey'} = 'typeid';
		$self->{'object_fieldlist'} = ['typeid', 'serviceid', 'zonetypename', 'logiczonetable', 'lookuptype'];

		bless($self, $class);
		return $self;
	}

	sub UploadZones
	{
		my $self = shift;

		my ($CgiRef, $ZoneFileName) = @_;

		my $File = $CgiRef->{'cgi'}->param($ZoneFileName);

		my $ZoneText = '';

		my $Buffer = '';
		while (read($File, $Buffer, 1024))
		{
			$ZoneText .= $Buffer;
		}

		$self->{'dbref'}->do("
			DELETE FROM
				zone
			WHERE
				typeid = ?
		", undef, $self->{'typeid'});


		for my $Line (split("\n", $ZoneText))
		{
			$Line =~ s/\r//g;
			$Line =~ s/\n//g;

			my $Data = {};
			(
				$Data->{'originbegin'},
				$Data->{'originend'},
				$Data->{'destbegin'},
				$Data->{'destend'},
				$Data->{'zonenumber'}
			) = split("\t", $Line);

			$Data->{'typeid'} = $self->{'typeid'};
			my $PKey = $self->{'dbref'}->gettokenid();

			$Data->{'zoneid'} = $PKey;

			$self->{'dbref'}->insertrecord(
				'zone',
				'zoneid',
				$Data
			);
		}

		$self->{'dbref'}->commit();
	}


}

1;
