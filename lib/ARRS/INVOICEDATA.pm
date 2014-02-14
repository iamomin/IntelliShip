#!/usr/bin/perl -w

#==========================================================
#   Project:	ARRS
#
#   Filename:	INVOICEDATA.pm
#
#   Date:		02/07/2011
#
#   Purpose:	Handling of invoicedata table
#
#   Company:	Engage TMS
#
#   Author(s):	Kirk Aksdal
#					Leigh Bohannon
#
#==========================================================

{
	package ARRS::INVOICEDATA;

	use strict;

	my $config; BEGIN {$config = do "/opt/engage/arrs/arrs.conf";}

	use ARRS::DBOBJECT;
	@ARRS::INVOICEDATA::ISA = ("ARRS::DBOBJECT");

	use ARRS::COMMON;

	use POSIX qw(strftime);

	sub new
	{
		my $proto = shift;
		my $class = ref($proto) || $proto;

		my $self = $class->SUPER::new(@_);

		$self->{'object_tablename'} = 'invoicedata';
		$self->{'object_primarykey'} = 'invoicedataid';
		$self->{'object_fieldlist'} = ['invoicedataid','sopid','carrierid','invoicedate','batchnumber','datecreated','freightcharges'];

		bless($self, $class);
		return $self;
	}

	sub CreateOrLoadCommit
	{
		my $self = shift;
		my ($DataRef) = @_;

		my $SQL = "
			SELECT
				invoicedataid
			FROM
				invoicedata
			WHERE
				sopid = '$DataRef->{'sopid'}'
				AND carrierid = '$DataRef->{'carrierid'}'
				AND batchnumber = '$DataRef->{'batchnumber'}'
				AND invoicedate = date('$DataRef->{'invoicedate'}')
		";

		my $STH = $self->{'object_dbref'}->prepare($SQL)
			or die "Could not prepare get invoicedataid";

		$STH->execute()
			or die "Could not execute get invoicedataid";

		if ( ($DataRef->{'invoicedataid'}) = $STH->fetchrow_array() )
		{
			# Reset datecreated on update
			$DataRef->{'datecreated'} = strftime("%Y-%m-%d %H:%M:%S", localtime(time));
		}

		$STH->finish();

		return $self->SUPER::CreateOrLoadCommit($DataRef);
	}
}

1;
