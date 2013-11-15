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

sub get_freight_class_from_density
	{
	my $self = shift;
	my ($Weight,$DimLength,$DimWidth,$DimHeight,$Density) = @_;

	if (length $Density == 0)
		{
		if ($DimLength > 0 and $DimWidth > 0 and $DimHeight > 0)
			{
			$Density = int(($Weight/($DimLength * $DimWidth * $DimHeight)) * 1728);
			}
		else
			{
			return 0;
			}
		}

	my $FreightClass;
	if ( $Density < 1 )
		{
		$FreightClass = 400;
		}
	elsif ( $Density >= 1 && $Density < 2 )
		{
		$FreightClass = 300;
		}
	elsif ( $Density >= 2 && $Density < 4 )
		{
		$FreightClass = 250;
		}
	elsif ( $Density >= 4 && $Density < 6 )
		{
		$FreightClass = 150;
		}
	elsif ( $Density >= 6 && $Density < 8 )
		{
		$FreightClass = 125;
		}
	elsif ( $Density >= 8 && $Density < 10 )
		{
		$FreightClass = 100;
		}
	elsif ( $Density >= 10 && $Density < 12 )
		{
		$FreightClass = 92.5;
		}
	elsif ( $Density >= 12 && $Density < 15 )
		{
		$FreightClass = 85;
		}
	elsif ( $Density >= 15 && $Density < 18 )
		{
		$FreightClass = 70;
		}
	elsif ( $Density >= 18 && $Density < 21 )
		{
		$FreightClass = 65;
		}
	elsif ( $Density >= 21 && $Density < 24 )
		{
		$FreightClass = 60;
		}
	elsif ( $Density >= 24 && $Density < 27 )
		{
		$FreightClass = 55;
		}
	elsif ( $Density >= 27 && $Density < 30 )
		{
		$FreightClass = 50;
		}

	return $FreightClass;
	}

1;

__END__