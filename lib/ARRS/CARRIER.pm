#!/usr/bin/perl -w

#==========================================================
#   Project:	ARRS
#
#   Filename:	CARRIER.pm
#
#   Date:		04/25/2002
#
#   Purpose:	Carrier Handling
#
#   Company:	Engaeg TMS
#
#   Author(s):	Kirk Aksdal
#					Leigh Bohannon
#
#==========================================================

{
	package ARRS::CARRIER;

	use strict;

	use Data::Dumper;
	use ARRS::DBOBJECT;
	@ARRS::CARRIER::ISA = ("ARRS::DBOBJECT");

	use ARRS::COMMON;
	use ARRS::CSOVERRIDE;

	sub new
	{
		my $proto = shift;
		my $class = ref($proto) || $proto;

		my $self = $class->SUPER::new(@_);

		$self->{'object_tablename'} = 'carrier';
		$self->{'object_primarykey'} = 'carrierid';
		$self->{'object_fieldlist'} = ['carrierid','carriername','pickuprequest','groupname','halocarrierid','scac'];

		bless($self, $class);
		return $self;
	}

	sub Exclude
	{
		my $self = shift;
		my ($SOPID,$CustomerID) = @_;

		my $SQLString = "
			SELECT
				customerserviceid
			FROM
				customerservice cs,
				service s
			WHERE
				cs.serviceid = s.serviceid
				AND cs.customerid = '$SOPID'
				AND s.carrierid = '" . $self->{'field_carrierid'} . "'
		";

      my $sth = $self->{'object_dbref'}->prepare($SQLString)
         or die "Could not prepare SQL statement";

      $sth->execute()
         or die "Cannot execute carrier/customerservice sql statement";

      while ( my ($CSID) = $sth->fetchrow_array() )
      {
			# Allow carrier if the SOP has any unexcluded CS for the customer
			my $CSOverride = new ARRS::CSOVERRIDE($self->{'object_dbref'}, $self->{'object_contact'});
			if ( !$CSOverride->ExcludeCS($CustomerID,$CSID) )
			{
				return 0;
			}
      }

      $sth->finish();

		# If no unexcluded CS's, exclude the carrier
		return 1;
	}

	sub GetMyCarriers
		{
		my $self = shift;
		my ($CustomerID) = @_;

		my $SQL = "
			SELECT
				DISTINCT carriername
			FROM
				customerservice
				INNER JOIN service ON service.serviceid=customerservice.serviceid
				INNER JOIN carrier ON carrier.carrierid=service.carrierid
			WHERE
				customerid='$CustomerID'
			ORDER BY
				1";

		warn "\n.... GetMyCarriers: " . $SQL;
		my $STH = $self->{'dbref'}->{'aos'}->prepare($SQL) || die "Cannot prepare comment select sql statement";

		$STH->execute() || die "Cannot execute comment select sql statement";

		my ($Carriers) = $STH->fetchrow_array();

		$STH->finish();
		warn "\nCarriers: " . Dumper $Carriers;

		return $Carriers;
		}
}

1;
