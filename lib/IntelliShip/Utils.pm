package IntelliShip::Utils;

use strict;
use bignum;
use XML::Simple;

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
	elsif ( $Density >= 1 and $Density < 2 )
		{
		$FreightClass = 300;
		}
	elsif ( $Density >= 2 and $Density < 4 )
		{
		$FreightClass = 250;
		}
	elsif ( $Density >= 4 and $Density < 6 )
		{
		$FreightClass = 150;
		}
	elsif ( $Density >= 6 and $Density < 8 )
		{
		$FreightClass = 125;
		}
	elsif ( $Density >= 8 and $Density < 10 )
		{
		$FreightClass = 100;
		}
	elsif ( $Density >= 10 and $Density < 12 )
		{
		$FreightClass = 92.5;
		}
	elsif ( $Density >= 12 and $Density < 15 )
		{
		$FreightClass = 85;
		}
	elsif ( $Density >= 15 and $Density < 18 )
		{
		$FreightClass = 70;
		}
	elsif ( $Density >= 18 and $Density < 21 )
		{
		$FreightClass = 65;
		}
	elsif ( $Density >= 21 and $Density < 24 )
		{
		$FreightClass = 60;
		}
	elsif ( $Density >= 24 and $Density < 27 )
		{
		$FreightClass = 55;
		}
	elsif ( $Density >= 27 and $Density < 30 )
		{
		$FreightClass = 50;
		}

	return $FreightClass;
	}

sub hex_string
	{
	my $self = shift;
	my $string = shift;

	my %escapes;

	for (0..255)
		{
		$escapes{chr($_)} = sprintf("%%%02X", $_);
		}

	$string =~ s/([\x00-\x20\"#%;\@&=\*<>?{}\!\$\(\)|\\^~`\[\]\x7F-\xFF])/$escapes{$1}/g;
	$string =~ s/\+/\%2B/g;
	$string =~ s/ /+/g;

	return $string;
	}

sub parse_XML
	{
	my $self = shift;
	my $XML = shift;

	my $xs = XML::Simple->new(
		forcearray => 0,
		keeproot => 1,
		suppressempty => 1
		);

	my $xmlRequestDS = eval{ $xs->XMLin($XML) };

	if ($@)
		{
		print STDERR "\nXML Parse Error: " . $@;
		}

	return $xmlRequestDS;
	}

my $FILTER_CRITERIA_HASH = {
		'dateshipped'	=> 'Shipped Date',
		'carrier'		=> 'Carrier',
		'statusid'		=> 'Status',
		};

sub get_filter_value_from_key
	{
	my ($self,$key) = @_;
	my ($alias,$key) = split(/\./, $key) if $key =~ /\./g;
	return $FILTER_CRITERIA_HASH->{$key};
	}

sub jsonify
	{
	my $self = shift;
	my $struct = shift;
	my $json = [];
	if (ref($struct) eq "ARRAY")
		{
		my $list = [];
		foreach my $item (@$struct)
			{
				if (ref($item) eq "" ){
					$item = $self->clean_json_data($item);
					push @$list, "\"$item\"";
				}
				else{
					push @$list, $self->jsonify($item);
				}
			}
		return "[" . join(",",@$list) . "]";

		}
	elsif (ref($struct) eq "HASH")
		{
		my $list = [];
		foreach my $key (keys %$struct)
			{
			my $val = $struct->{$key};
			if (ref($val) eq "" )
				{
				$val = $self->clean_json_data($val);
				push @$list, "\"$key\":\"$val\"";
				}
			else
				{
				push @$list, "\"$key\":" . $self->jsonify($struct->{$key});
				}
			}
		return "{" . join(',',@$list) . "}";
		}
	}

sub clean_json_data
	{
	my $self = shift;
	my $item = shift;

	$item =~ s/"/\\"/g;
	$item =~ s/\t+//g;
	$item =~ s/\n+//g;
	$item =~ s/\r+//g;
	$item =~ s/^\s+//g;
	$item =~ s/\s+$//g;

	return $item;
	}

1;

__END__