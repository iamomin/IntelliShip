#!/usr/bin/perl -w

#==========================================================
#   Project:	ARRS
#
#   Filename:	SERVICECSDATA.pm
#
#   Date:		09/23/2005
#
#   Purpose:	Serivce/Customerservice data table Handling
#
#   Company:	Engage TMS
#
#   Author(s):	Kirk Aksdal
#					Leigh Bohannon
#
#==========================================================

{
	package ARRS::SERVICECSDATA;

	use strict;
	use ARRS::DBOBJECT;
	@ARRS::SERVICECSDATA::ISA = ("ARRS::DBOBJECT");

	use ARRS::COMMON;

	sub new
	{
		my $proto = shift;
		my $class = ref($proto) || $proto;

		my $self = $class->SUPER::new(@_);

		$self->{'object_tablename'} = 'servicecsdata';
		$self->{'object_primarykey'} = 'servicecsdataid';
		$self->{'object_fieldlist'} = ['servicecsdataid','ownertypeid','ownerid','datatypeid','datatypename','value','datecreated','datehalocreated'];

		bless($self, $class);
		return $self;
	}

	sub GetExistingID
	{
		my $self = shift;
		my ($OwnerTypeID,$OwnerID,$DataTypeName) = @_;

		my $SQL = "
			SELECT
				servicecsdataid
			FROM
				servicecsdata
			WHERE
				ownertypeid = '$OwnerTypeID'
				AND ownerid = '$OwnerID'
				AND datatypename = '$DataTypeName'
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

      if
      (
         defined($DataRef->{$self->{'object_primarykey'}}) &&
         $DataRef->{$self->{'object_primarykey'}} ne '' &&
         $self->Load($DataRef->{$self->{'object_primarykey'}})
      )
      {
			# If we didn't get a value, delete the existing record
			if ( !defined($DataRef->{'value'}) || $DataRef->{'value'} eq '' )
			{
         	$self->Delete();
			}
			else
			{
         	$self->SetValuesArray(%$DataRef);
			}

         return $self->Commit();
      }
      else
      {
			if ( !defined($DataRef->{'value'}) || $DataRef->{'value'} eq '' )
			{
         	return;
			}
			else
			{
         	$self->SetValuesArray(%$DataRef);
         	return $self->Create();
			}
      }
	}
}

1;
