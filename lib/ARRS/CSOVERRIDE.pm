#!/usr/bin/perl -w

#==========================================================
#   Project:	ARRS
#
#   Filename:	CSOVERRIDE.pm
#
#   Date:		02/27/2007
#
#   Purpose:	CS Override Data handling (allowing
#					customer specific data to overrirde CS
#					values)
#
#   Company:	Engage TMS
#
#   Author(s):	Kirk Aksdal
#					Leigh Bohannon
#
#==========================================================

{
	package ARRS::CSOVERRIDE;

	use strict;

	use ARRS::DBOBJECT;
	@ARRS::CSOVERRIDE::ISA = ("ARRS::DBOBJECT");

	use ARRS::COMMON;

	sub new
	{
		my $proto = shift;
		my $class = ref($proto) || $proto;

		my $self = $class->SUPER::new(@_);

		$self->{'object_tablename'} = 'csoverride';
		$self->{'object_primarykey'} = 'csoverrideid';
		$self->{'object_fieldlist'} = ['csoverrideid','customerid','customerserviceid','datatypeid','datatypename','value'];

		bless($self, $class);
		return $self;
	}

	sub ExcludeCS
	{
		my $self = shift;
		my ($CustomerID,$CSID) = @_;

		return $self->LowLevelLoadAdvanced(
			undef,
			{
				customerid			=> $CustomerID,
				customerserviceid	=>	$CSID,
				datatypename		=>	'excludecs',
			}
		);
	}
}

1;
