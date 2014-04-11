	package ARRS::handler_remote_fedex;

	use strict;

	use ARRS::CARRIERHANDLER;
	@ARRS::handler_remote_fedex::ISA = ("ARRS::CARRIERHANDLER");

	use ARRS::COMMON;
	use ARRS::SERVICE;

	use POSIX qw(ceil);

	my $Debug = 0;

	sub new
	{
		my $proto = shift;
		my $class = ref($proto) || $proto;

		my ($DBRef, $Customer) = @_;
		my $self = $class->SUPER::new($DBRef,$Customer);

		bless($self, $class);
		return $self;
	}

	sub GetETADate
	{
		my $self = shift;
		my ($ETARef) = @_;

		my $Service = new ARRS::SERVICE($self->{'dbref'},$self->{'contact'});

		# Only do this for PO, 2D, GD
		if
		(
			$ETARef->{'serviceid'} eq '0000000000002' ||
			$ETARef->{'serviceid'} eq '0000000000004' ||
			$ETARef->{'serviceid'} eq '0000000000006'
		)
		{
			my $TransitSQL = "
				SELECT
					transittime
				FROM
					ziptransittime
				WHERE
					carrierid = '$ETARef->{'carrierid'}'
					AND originbegin <= '$ETARef->{'fromzip'}'
					AND originend >= '$ETARef->{'fromzip'}'
					AND destbegin <= '$ETARef->{'tozip'}'
					AND destend >= '$ETARef->{'tozip'}'
					AND serviceid = '$ETARef->{'serviceid'}'
			";

			my $STH = $self->{'dbref'}->prepare($TransitSQL)
				or TraceBack("Could not prepare transittime sql statement",1);

			$STH->execute
				or TraceBack("Could not execute transittime sql statement",1);

			if ( ($ETARef->{'transitdays'}) = $STH->fetchrow_array() )
			{
				# Don't do anything...but if we don't get transitdays from here, go off of zone,
				# which we have to get.
			}
			else
			{
				if
				(
					$ETARef->{'serviceid'} eq '0000000000004' &&
					( my ($zone_number) = $ETARef->{'cs'}->GetZoneNumber($ETARef->{'fromzip'},$ETARef->{'tozip'}) )
				)
				{
					if ( $zone_number == 2 || $zone_number == 3 )
					{
						$ETARef->{'transitdays'} = 1;
					}
					elsif ( $zone_number == 4 || $zone_number == 5 )
					{
						$ETARef->{'transitdays'} = 2;
					}
					elsif ( $zone_number == 6 || $zone_number == 7 )
					{
						$ETARef->{'transitdays'} = 3;
					}
					elsif ( $zone_number == 8 || $zone_number == 9 )
					{
						$ETARef->{'transitdays'} = 4;
					}
					elsif ( $zone_number == 10 || $zone_number == 14 )
					{
						$ETARef->{'transitdays'} = 5;
					}
					elsif ( $zone_number >= 15 )
					{
						$ETARef->{'transitdays'} = 6;
					}
				}
			}
		}
		elsif
		(
			$Service->Load($ETARef->{'serviceid'}) &&
			$Service->GetValueHashRef()->{'international'} == 1
		)
		{
			(undef,$ETARef->{'transitdays'}) =
				$ETARef->{'cs'}->GetZoneNumber($ETARef->{'fromcountry'},$ETARef->{'tocountry'});
		}

		return $self->SUPER::GetETADate($ETARef);
	}

1
