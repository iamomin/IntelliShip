	package ARRS::handler_web_airborne;

	use strict;

	use ARRS::CARRIERHANDLER;
	@ARRS::handler_web_airborne::ISA = ("ARRS::CARRIERHANDLER");

	use ARRS::AIRPORTCODE;
	use ARRS::COMMON;

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

		# Get DB transit (zip->zip) for ground
		if ( $ETARef->{'serviceid'} eq '0000000000109' )
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

			($ETARef->{'transitdays'}) = $STH->fetchrow_array();
		}
		# Use timeneededmax for all other services
		else
		{
			$ETARef->{'transitdays'} = $ETARef->{'timeneededmax'};
		}

		# Bolt on extra days for origin and destination zips
		my $APC = new ARRS::AIRPORTCODE($self->{'dbref'}, $self->{'contact'});
		$APC->{'object_issuper'} = 1;
		$ETARef->{'transitdays'} += $APC->LowLevelLoadAdvanced(undef,{carrierid=>$ETARef->{'carrierid'},postalcode=>$ETARef->{'fromzip'}});
		$ETARef->{'transitdays'} += $APC->LowLevelLoadAdvanced(undef,{carrierid=>$ETARef->{'carrierid'},postalcode=>$ETARef->{'tozip'}});
		$APC->{'object_issuper'} = 0;

		return $self->SUPER::GetETADate($ETARef);
	}

1
