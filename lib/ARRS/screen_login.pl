#!/usr/bin/perl -w

#####################################################################
##
##	module SCREEN
##
##	Engage TMS screen interface.
##
#####################################################################

{
	package ARRS::screen_login;

	use strict;

	my $config; BEGIN {$config = do "/opt/engage/arrs/arrs.conf";}

	use ARRS::GENERICSCREEN;
	@ARRS::screen_login::ISA = ("ARRS::GENERICSCREEN");

	use ARRS::CONTACT;

	sub new
	{
		my $proto = shift;
		my $class = ref($proto) || $proto;

		my ($DBRef, $SystemUser) = @_;

		my $self = $class->SUPER::new($DBRef,$SystemUser);

		bless($self, $class);
		return $self;
	}

	sub DESTROY
	{
	}

	sub HandleDisplay
	{
		my $self = shift;
		my ($CgiRef) = @_;

		return (1, $CgiRef);
	}

	sub HandleStates
	{
		my $self = shift;

		my ($CgiRef) = @_;

		$CgiRef->{'tokenid'} = $self->{'contact'}->TokenID();

		return (1, $CgiRef);
	}
}
1;
