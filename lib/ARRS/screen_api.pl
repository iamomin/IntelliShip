#!/usr/bin/perl -w

#####################################################################
##
##	module SCREEN
##
##	  This screen handler is the guts of the EngageTMS ARRS API
##
#####################################################################

{
	package ARRS::screen_api;

	use strict;
	use ARRS::GENERICSCREEN;
	@ARRS::screen_api::ISA = ("ARRS::GENERICSCREEN");

	use ARRS;
	use ARRS::COMMON;

	sub new
	{
		my $proto = shift;
		my $class = ref($proto) || $proto;
		my ($DBRef, $Contact) = @_;

		my $self = $class->SUPER::new($DBRef,$Contact);

		bless($self, $class);
		return $self;
	}

	sub HandleErrors
	{
		my $self = shift;
		my ($CgiRef) = @_;

		return (0, $CgiRef);
	}

	sub HandleDisplay
	{
		my $self = shift;
		my ($CgiRef) = @_;

		my $ARRS = new ARRS();
		my $ReturnRef = $ARRS->APICall($CgiRef);

		$CgiRef->{'returnstring'} = $self->BuildReturnString($ReturnRef);

		return (1,$CgiRef);
	}

	sub HandleStates
	{
		my $self = shift;
		my ($CgiRef) = @_;

		my $Return = 1;

		return ($Return, $CgiRef);

	}

	sub BuildReturnString
	{
		my $self = shift;
		my ($Ref) = @_;
		my $ReturnString = '';

		foreach my $Key (sort(keys(%$Ref)))
		{
			if ( defined($Ref->{$Key}) && $Ref->{$Key} ne '' )
			{
				$ReturnString .= "$Key: " . $Ref->{$Key} . "\n";
			}
		}

		return $ReturnString;
	}
}
1;
