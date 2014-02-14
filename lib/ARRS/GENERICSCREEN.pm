#!/usr/bin/perl -w

#####################################################################
##
##	module SCREEN
##
##	Engage TMS screen interface.
##
#####################################################################

{
	package ARRS::GENERICSCREEN;

	use strict;

	use ARRS::COMMON;

	use Date::Calc qw(Delta_Days);
	use Date::Manip qw(ParseDate UnixDate);
	use POSIX qw(strftime ceil);

	sub new
	{
		my $proto = shift;
		my $class = ref($proto) || $proto;

		my $self = {};
		($self->{'dbref'}, $self->{'contact'}) = @_;

		bless($self, $class);
		return $self;
	}

	sub HandleErrors
	{
		my $self = shift;

		my ($Return) = @_;

		return (0, $Return);
	}

	sub HandleStates
	{
		my $self = shift;

		my ($Return) = @_;

		return (1, $Return);
	}

	sub HandleDisplay
	{
		my $self = shift;

		my ($Return) = @_;

		if ($Return->{'screen'} ne 'login')
      {
         $Return = $self->BuildMenu($Return);
      }

		return (1,$Return);
	}

	sub IsShipDatePassed
	{
		my $self = shift;
		my ($datetoship) = @_;

		my $datetoship_is_passed = 0;

		if ( defined($datetoship) && $datetoship ne '' )
		{
			$datetoship = VerifyDate($datetoship);
			my ($month,$day,$year) = $datetoship =~ /(\d{2})\/(\d{2})\/(\d{4})/;
			my @datetoship = ($year,$month,$day);
			my @currentdate = split(/:/,strftime("%Y:%m:%d", localtime(time)));

			if ( Delta_Days(@currentdate, @datetoship) < 0 )
			{
				$datetoship_is_passed = 1;
			}
		}

		return $datetoship_is_passed;
	}
}

1;
