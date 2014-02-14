#!/usr/bin/perl -w

#==========================================================
#   Project:	ARRS
#
#   Filename:	ASSDATA.pm
#
#   Date:		07/14/2008
#
#   Purpose:	Handling of assessorial data
#
#   Company:	Engage TMS
#
#   Author(s):	Kirk Aksdal
#					Leigh Bohannon
#
#==========================================================

{
	package ARRS::ASSDATA;

	use strict;

	use ARRS::DBOBJECT;
	@ARRS::ASSDATA::ISA = ("ARRS::DBOBJECT");

	use ARRS::COMMON;

	use Date::Manip qw(ParseDate UnixDate DateCalc);

	sub new
	{
		my $proto = shift;
		my $class = ref($proto) || $proto;

		my $self = $class->SUPER::new(@_);

		$self->{'object_tablename'} = 'assdata';
		$self->{'object_primarykey'} = 'assdataid';
		$self->{'object_fieldlist'} = [
			'assdataid','ownertypeid','ownerid','assname','assdisplay','asstypeid',
			'arcost','arcostmin','arcostperwt','apcost','apcostmin','apcostperwt',
			'arcostperunit','arcostmax','apcostperunit','apcostmax','arcostpercent',
			'apcostpercent','startdate','stopdate','datecreated','datehalocreated'
		];

		bless($self, $class);
		return $self;
	}

	sub GetSOPAssListing
	{
		my $self = shift;
		my ($SOPID) = @_;
		my $ASS_names = '';
		my $ASS_displays = '';

		my $STH_CS_list = $self->{'object_dbref'}->prepare("
			SELECT DISTINCT
				assname,
				assdisplay
			FROM
				assdata
			WHERE
				(
					( ownerid in (SELECT customerserviceid FROM customerservice WHERE customerid = ?) AND ownertypeid = 4 ) OR
					( ownerid in (SELECT serviceid FROM customerservice WHERE customerid = ?) AND ownertypeid = 3 )
				)
				AND assdisplay IS NOT NULL
			ORDER BY
				assname,
				assdisplay
		")
			or TraceBack("Could not prepare SOP Ass Listing");

		$STH_CS_list->execute($SOPID,$SOPID)
			or TraceBack("Could not execute SOP Ass Listing");

		while ( my ($assname,$assdisplay) = $STH_CS_list->fetchrow_array() )
		{
			$ASS_names		.= "$assname\t";
			$ASS_displays	.= "$assdisplay\t";
		}

		chop ($ASS_names,$ASS_displays);

		$STH_CS_list->finish();

		return { assessorial_names => $ASS_names, assessorial_display => $ASS_displays };
	}

	sub GetExistingID
	{
		my $self = shift;
		my ($OwnerTypeID,$OwnerID,$AssName,$StartDate,$StopDate) = @_;

		my $start_sql = $StartDate ? "= '$StartDate'" : 'IS NULL';
		my $stop_sql = $StopDate ? "= '$StopDate'" : 'IS NULL';

		my $SQL = "
			SELECT
				assdataid
			FROM
				assdata
			WHERE
				ownertypeid = '$OwnerTypeID'
				AND ownerid = '$OwnerID'
				AND assname = '$AssName'
				AND startdate $start_sql
				AND stopdate $stop_sql
		";

		my $STH = $self->{'object_dbref'}->prepare($SQL)
			or die "Could not prepare GetExistingID select";

		$STH->execute()
			or die "Could not execute GetExistingID select";

		my ($DataID) = $STH->fetchrow_array();

		$STH->finish();

		return $DataID
	}

	sub CreateOrLoadCommit
	{
		my $self = shift;
		my ($DataRef) = @_;

		# If we have a start date, we need a stop date.
		# If there isn't one, arbitrarily set one for 1 year from the start date.

		if ( $DataRef->{'startdate'} && !$DataRef->{'stopdate'} )
		{
			my $parsed_start = ParseDate($DataRef->{'startdate'});
			$DataRef->{'stopdate'} = UnixDate(DateCalc($parsed_start,'+ 1 year'),"%D");
		}

		return $self->SUPER::CreateOrLoadCommit($DataRef);
	}
}

1;
