	package ARRS::handler_local_fedex;

	use strict;

	use ARRS::CARRIERHANDLER;
	@ARRS::handler_local_fedex::ISA = ("ARRS::CARRIERHANDLER");

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

			($ETARef->{'transitdays'}) = $STH->fetchrow_array();
		}

		return $self->SUPER::GetETADate($ETARef);
	}

1
