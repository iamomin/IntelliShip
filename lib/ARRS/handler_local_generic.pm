	package ARRS::handler_local_generic;

	use strict;

	use ARRS::CARRIERHANDLER;
	@ARRS::handler_local_generic::ISA = ("ARRS::CARRIERHANDLER");

	use ARRS::AIRPORTTRANSIT;
	use ARRS::COMMON;
	use ARRS::CUSTOMERSERVICE;

	use Algorithm::LUHN qw(check_digit);
	use POSIX qw(ceil);

	sub new
	{
		my $proto = shift;
		my $class = ref($proto) || $proto;

		my ($DBRef, $Contact) = @_;

		my $self = $class->SUPER::new($DBRef,$Contact);

		bless($self, $class);
		return $self;
	}

	sub GetETADate
	{
		my $self = shift;
		my ($ETARef) = @_;

		$ETARef->{'transitdays'} = $self->GetTransitDays($ETARef);

		return $self->SUPER::GetETADate($ETARef);
	}

	sub GetTransitDays
	{
		my $self = shift;
		my ($ETARef) = @_;
		my $TransitDays;

		my $CS = new ARRS::CUSTOMERSERVICE($self->{'dbref'}, $self->{'customer'});
		$CS->{'object_issuper'} = 1;
		$CS->Load($ETARef->{'cs'}->{'field_customerserviceid'});
		$CS->{'object_issuper'} = 0;

		$ETARef->{'fromzip'} =~ s/^(\d{5})/$1/;
		$ETARef->{'tozip'} =~ s/^(\d{5})/$1/;

		if ( !defined($ETARef->{'tozip'}) || $ETARef->{'tozip'} eq '' )
		{
			return $TransitDays;
		}

		if ( $ETARef->{'carrierid'} eq '0000000000004' )
		{
			if
			(
				$ETARef->{'serviceid'} eq 'BAX0000000005' || $ETARef->{'serviceid'} eq 'BAX0000000006' ||
				$ETARef->{'serviceid'} eq 'BAX0000000017' || $ETARef->{'serviceid'} eq 'BAX0000000018' ||
				$ETARef->{'serviceid'} eq 'BAX0000000029' || $ETARef->{'serviceid'} eq 'BAX0000000030'
			)
			{
				$TransitDays = $self->GetAirportTransitDays($ETARef);
			}
			elsif ( $ETARef->{'serviceid'} eq 'BAXTRUCK00001' )
			{
				$TransitDays = $self->GetTLTransitDays($ETARef);
			}
		}
		elsif ( $ETARef->{'carrierid'} eq '0000000000006' )
		{
			# Transit for Conway LTLish services
			if ( $ETARef->{'serviceid'} eq 'CONWAY1000001'  )
			{
#				$TransitDays = $self->GetZipTransitDays($ETARef);
				$TransitDays = $self->GetAirportTransitDays($ETARef,1);
			}
		}
		elsif ( $ETARef->{'carrierid'} eq '0000000000008' )
		{
			$TransitDays = $self->GetAirportTransitDays($ETARef);
		}
		elsif ( $ETARef->{'carrierid'} eq '0000000000009' )
		{
			if ( $ETARef->{'serviceid'} eq 'EGLTRUCK00001' )
			{
				$TransitDays = $self->GetTLTransitDays($ETARef);
			}
		}
		elsif ( $ETARef->{'carrierid'} eq '0000000000012' )
		{
			$TransitDays = $self->GetZipTransitDays($ETARef);
		}
		elsif ( $ETARef->{'carrierid'} eq '0000000000015' )
		{
			if ( $ETARef->{'serviceid'} =~ /ROADWAYEXP/ )
			{
				$TransitDays = $self->GetZipTransitDays($ETARef);
			}
			elsif ( $ETARef->{'serviceid'} eq 'ROADWAYTRUCK1' || $ETARef->{'serviceid'} eq 'ROADWAYTRUCK2' )
			{
				$TransitDays = $self->GetTLTransitDays($ETARef);
			}
		}
		elsif ( $ETARef->{'carrierid'} eq '0000000000025' )
		{
#			if ( $ETARef->{'serviceid'} eq 'ROADWAYAIR013' || $ETARef->{'serviceid'} eq 'ROADWAYAIR014' )
#			{
#				$TransitDays = $self->GetAirportTransitDays($ETARef,'roadway',1);
#			}
		}
		elsif ( $ETARef->{'carrierid'} eq '0000000000033' )
		{
			$TransitDays = $self->GetAirportTransitDays($ETARef);
		}
		elsif ( $ETARef->{'carrierid'} eq 'SEFL000000001' )
		{
			$TransitDays = $self->GetAirportTransitDays($ETARef,'sefl');
		}
		elsif ( $ETARef->{'carrierid'} eq 'WATKINS000001' )
		{
			$TransitDays = $self->GetAirportTransitDays($ETARef,1);
		}
		elsif ( $ETARef->{'carrierid'} eq '0000000000005' )
		{
			$TransitDays = $self->GetAirportTransitDays($ETARef,1);
		}
		elsif ( $ETARef->{'carrierid'} eq 'DFL0000000001' )
		{
			$TransitDays = $self->GetAirportTransitDays($ETARef,1);
		}
		elsif ( $ETARef->{'carrierid'} eq 'ECLIPSE000001' && $ETARef->{'serviceid'} eq 'ECLIPSETL0001')
		{
			$TransitDays = $self->GetTLTransitDays($ETARef);
		}
		elsif ( $ETARef->{'carrierid'} eq 'PITTOHIOEXPRS' )
		{
			$TransitDays = $self->GetZipTransitDays($ETARef);
		}
		elsif ( $ETARef->{'carrierid'} eq '0000000000011' )
		{
			$TransitDays = $self->GetZipTransitDays($ETARef);
		}
		elsif ( $ETARef->{'carrierid'} eq 'OLDDOMINION01' )
		{
			$TransitDays = $self->GetZipTransitDays($ETARef);
		}
		elsif ( $ETARef->{'carrierid'} eq 'ATC0000000001' )
		{
			$TransitDays = $self->GetZipTransitDays($ETARef);
		}
		elsif ( $ETARef->{'carrierid'} eq 'CUSTCOM000001' )
		{
			$TransitDays = $self->GetZipTransitDays($ETARef);
		}
		elsif ( $ETARef->{'carrierid'} eq 'LME0000000001' )
		{
			$TransitDays = $self->GetZipTransitDays($ETARef);
		}
		elsif ( $ETARef->{'carrierid'} eq 'DOHRN00000001' )
		{
			$TransitDays = $self->GetZipTransitDays($ETARef);
		}
		elsif ( $ETARef->{'carrierid'} eq 'AVERITTEXP001' )
		{
			$TransitDays = $self->GetZipTransitDays($ETARef);
		}
		# For now at least, make sure this goes last - to make sure carrier specific ones get hit first.
		elsif ( $CS->GetCSValue('modetypeid') == 12 )
		{
			$TransitDays = $self->GetTLTransitDays($ETARef);
		}
		# Put nothing here...go above this elsif if you need to add to the conditional
#warn "TransitDays=$TransitDays";
		return $TransitDays;
	}

	sub GetZipTransitDays()
	{
		my $self = shift;
		my ($ETARef) = @_;

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
		";

# This should be unnecessary - service winowwing is taking place upstream (usually more than one service needs this type of transit
# for a given carrier...having to put db entries for each service would be silly).  Kirk 2006-08-04
#		if ( defined($ETARef->{'serviceid'}) && $ETARef->{'serviceid'} ne '' )
#		{
#			$TransitSQL .= "AND serviceid = '$ETARef->{'serviceid'}'";
#		}

		my $STH = $self->{'dbref'}->prepare($TransitSQL)
			or TraceBack("Could not prepare transittime sql statement",1);

		$STH->execute
			or TraceBack("Could not execute transittime sql statement",1);

		return $STH->fetchrow_array();
	}

	sub GetAirportTransitDays()
	{
		my $self = shift;
		my ($ETARef,$ExtraTransit) = @_;

		my $AirportTransit = new ARRS::AIRPORTTRANSIT($self->{'dbref'}, $self->{'customer'});

		return $AirportTransit->GetAirportToAirportTransitTime(
			$ETARef->{'fromzip'},
			$ETARef->{'tozip'},
			$ETARef->{'carrierid'},
			$ExtraTransit
		);
	}

	 sub DimCheck
   {
      my $self = shift;
      my ($Length,$Width,$Height,$DimFactor,$ServiceID) = @_;

      if
      (
         defined($Length) && $Length ne '' &&
         defined($Height) && $Height ne '' &&
         defined($Width) && $Width ne ''
      )
      {
         if ( $Width > 48 )
         {
            return 0;
         }

         if ( $Length > 48 )
         {
            return 0;
         }

			if ( $Height > 96 )
         {
            return 0;
         }
      }

      return 1;
   }

1
