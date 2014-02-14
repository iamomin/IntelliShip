#!/usr/bin/perl -w

#==========================================================
#   Project:	ARRS
#
#   Filename:	RATETYPE.pm
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
	package ARRS::RATETYPE;

	use strict;
	use ARRS::DBOBJECT;
	@ARRS::RATETYPE::ISA = ("ARRS::DBOBJECT");

	sub new
	{
		my $proto = shift;
		my $class = ref($proto) || $proto;

		my $self = $class->SUPER::new(@_);

		$self->{'object_tablename'} = 'ratetype';
		$self->{'object_primarykey'} = 'typeid';
		$self->{'object_fieldlist'} = ['typeid','serviceid','ratetypename','handler','lookuptype'];

		bless($self, $class);
		return $self;
	}

	sub UploadRates
	{

		my $self = shift;

		my ($CgiRef, $RateFileName) = @_;

		#warn "In upload rates\n";
		my $File = $CgiRef->{'cgi'}->param($RateFileName);

		my $RateText = '';

		my $Buffer = '';
		while (read($File, $Buffer, 1024))
		{
			$RateText .= $Buffer;
		}

		$self->{'dbref'}->do("
			DELETE FROM
				rate
			WHERE
				typeid = ?
		", undef, $self->{'typeid'});

		for my $Line (split("\n", $RateText))
		{
			$Line =~ s/\r//g;
			$Line =~ s/\n//g;

			my $Data = {};
			(
				$Data->{'zonenumber'},
				$Data->{'unitsstart'},
				$Data->{'unitsstop'},
				$Data->{'cost'}
			) = split("\t", $Line);

			$Data->{'typeid'} = $self->{'typeid'};
			my $PKey = $self->{'dbref'}->gettokenid();
			$Data->{'rateid'} = $PKey;

			$self->{'dbref'}->insertrecord(
				'rate',
				'rateid',
				$Data
			);
		}

		$self->{'dbref'}->commit();
	}
}

1;
