#!/usr/bin/perl -w

#==========================================================
#   Project:	ARRS
#
#   Filename:	ZONE.pm
#
#   Date:		04/25/2002
#
#   Purpose:	Zone Handling
#
#   Company:	Engage TMS
#
#   Author(s):	Kirk Aksdal
#					Leigh Bohannon
#
#==========================================================

{
	package ARRS::ZONE;

	use strict;

	my $config; BEGIN {$config = do "/opt/engage/arrs/arrs.conf";}

	use ARRS::DBOBJECT;
	@ARRS::ZONE::ISA = ("ARRS::DBOBJECT");

	use ARRS::COMMON;

	sub new
	{
		my $proto = shift;
		my $class = ref($proto) || $proto;

		my $self = $class->SUPER::new(@_);

		$self->{'object_tablename'} = 'zone';
		$self->{'object_primarykey'} = 'zoneid';
		$self->{'object_fieldlist'} = [
			'zoneid','typeid','originbegin','originend','destbegin','destend','originstate',
			'deststate','origincountry','destcountry','zonenumber','transittime'
		];

		bless($self, $class);
		return $self;
	}

	sub Create
	{
		my $self = shift;

		my @ZipFields = qw(field_destbegin field_destend field_originbegin field_originend);

		# Make sure if we get 'short' zips (under 5 digits, to left pad with zeroes)
		foreach my $ZipField (@ZipFields)
		{
			while ( length($self->{$ZipField}) < 5 ) { $self->{$ZipField} = '0' . $self->{$ZipField}; }
		}

		return $self->SUPER::Create();
	}

	sub Delete
	{
		my $self = shift;
		my ($ZoneRef) = @_;

		my $SQLString = "
			SELECT
				zoneid,
				typeid,
				originbegin,
				originend,
				destbegin,
				destend,
				zonenumber
			FROM
				zone z
			WHERE
				z.typeid = ? AND
				z.originbegin <= ? AND
				z.originend >= ? AND
				z.destbegin <= ? AND
				z.destend >= ?
		";

		my $sth = $self->{'object_dbref'}->prepare($SQLString)
			or die "Could not prepare SQL statement";

		$sth->execute($ZoneRef->{'typeid'}, $ZoneRef->{'fromzip'}, $ZoneRef->{'fromzip'}, $ZoneRef->{'tozip'}, $ZoneRef->{'tozip'})
			or die "Cannot execute sql statement";

		# If the zip/zone exists - cut it out.
		if ( my ($ZoneID, $TypeID, $OriginBegin, $OriginEnd, $DestBegin, $DestEnd, $ZoneNumber) = $sth->fetchrow_array() )
		{
			# Set variables that any newly created zones will have in common
			my $ZoneCommon = {
				'typeid'			=>	$TypeID,
				'originbegin'	=>	$OriginBegin,
				'originend'		=> $OriginEnd,
				'zonenumber'	=>	$ZoneNumber,
			};

			# Delete existing zone, regardless
			$self->{'object_dbref'}->do("
				DELETE FROM
					zone
				WHERE
					zoneid = ?
			", undef, $ZoneID)
				or die "Cannot do sql statement";

			# Address Zip is the zone range
			if ( $DestBegin == $ZoneRef->{'tozip'} && $DestEnd == $ZoneRef->{'tozip'} )
			{
					# Previous delete handles this case
			}
			# Address Zip is at the beginning of the zone range
			elsif ( $DestBegin == $ZoneRef->{'tozip'} )
			{
				$DestBegin++;

				my $DestZone = new ARRS::ZONE($self->{'object_dbref'}, $self->{'object_contact'});

				$ZoneCommon->{'destbegin'} = $DestBegin;
				$ZoneCommon->{'destend'} = $DestEnd;

				$DestZone->SetValues($ZoneCommon);
				$DestZone->Create();
			}
			# Address Zip is at the end of the zone range
			elsif ( $DestEnd == $ZoneRef->{'tozip'} )
			{
				$DestEnd--;

				my $DestZone = new ARRS::ZONE($self->{'object_dbref'}, $self->{'object_contact'});

				$ZoneCommon->{'destbegin'} = $DestBegin;
				$ZoneCommon->{'destend'} = $DestEnd;

				$DestZone->SetValues($ZoneCommon);
				$DestZone->Create();
			}
			# Address Zip is in the middle of the zone range
			elsif ( $DestBegin < $ZoneRef->{'tozip'} && $DestEnd > $ZoneRef->{'tozip'} )
			{
				# Zone 1 values
				my $Dest1Begin = $DestBegin;
				my $Dest1End = $ZoneRef->{'tozip'} - 1;
				$ZoneCommon->{'destbegin'} = $Dest1Begin;
				$ZoneCommon->{'destend'} = $Dest1End;

				my $Dest1Zone = new ARRS::ZONE($self->{'object_dbref'}, $self->{'object_contact'});
				$Dest1Zone->SetValues($ZoneCommon);
				$Dest1Zone->Create();

				# Zone 2 values
				my $Dest2Begin = $ZoneRef->{'tozip'} + 1;
				my $Dest2End = $DestEnd;
				$ZoneCommon->{'destbegin'} = $Dest2Begin;
				$ZoneCommon->{'destend'} = $Dest2End;

				my $Dest2Zone = new ARRS::ZONE($self->{'object_dbref'}, $self->{'object_contact'});
				$Dest2Zone->SetValues($ZoneCommon);
				$Dest2Zone->Create();
			}

			$self->{'object_dbref'}->commit();
		}

		$sth->finish();

		return { refreturn => 1 }
	}
}

1;
