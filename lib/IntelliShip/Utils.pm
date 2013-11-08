package IntelliShip::Utils;

use strict;
use bignum;

=pod

=head1 NAME

IntelliShip::Utils

=head1 DESCRIPTION

Collection of various utilitarian methods.

=head1 METHODS

=cut

sub new
	{
	my $self = shift;
	my $obref = {};

	bless $obref, $self;

	return $obref;
	}


1;

__END__