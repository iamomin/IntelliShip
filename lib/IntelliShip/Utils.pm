package IntelliShip::Utils;

use strict;
use Switch;
#use bignum;
use XML::Simple;
use Email::Valid;

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

sub check_for_directory
	{
	my $self = shift;
	my $destination_dir = shift;

	my @dirs = split(/\//,$destination_dir);

	my $qualified_location;
	foreach my $dir (@dirs)
		{
		next unless $dir;
		$qualified_location .= '/' . $dir;
		mkdir $qualified_location or return unless stat $qualified_location;
		}

	return $qualified_location;
	}

sub is_valid_email
	{
	my $self = shift;
	my $email = shift;
	return Email::Valid->address($email);
	}

sub trim_hash_ref_values ## Trims all multiple internal whitespace down to a single space
	{
	my $self = shift;
	my $HashRef = shift;

	foreach my $Key (keys %$HashRef)
		{
		$HashRef->{$Key} =~ s/(.*?)\s*$/$1/;
		$HashRef->{$Key} =~ s/^\s*(.*)/$1/;
		$HashRef->{$Key} =~ s/\\//;
		$HashRef->{$Key} =~ s/\s+/ /g;
		}

	return $HashRef;
	}

my $SHIPMENT_CHARGE_NAMES = {
	freightcharge => 'Freight Charge',
	fuelsurcharge => 'Fuel Surcharge',
	declaredvalueinsurancecharge => 'Declared Value Insurance Charge',
	freightinsurancecharge => 'Freight Insurance Charge',
	codfeecharge => 'COD Fee Charge',
	collectfreightcharge => 'Collect Freight Charge',
	singleshipmentcharge => 'Single Shipment Charge',
	podservicecharge => 'POD Service Charge'
	};

sub get_shipment_charge_display_name
	{
	my $self = shift;
	my $ChargeType = shift;
	return $SHIPMENT_CHARGE_NAMES->{$ChargeType};
	}

sub get_status_ui_info
	{
	my $self = shift;
	my $IndicatorType = shift || 0;
	my $Condition = shift;

	my $dataHash = {};

	switch ($IndicatorType)
		{
		## indicator text
		case 1
			{
			switch ($Condition)
				{
				case 1 { $dataHash->{'conditioncolor'} = '#FF0000'; $dataHash->{'conditiontext'} = 'Routed'   } # Red
				case 2 { $dataHash->{'conditioncolor'} = '#FF6600'; $dataHash->{'conditiontext'} = 'Packed'   } # Orange
				case 3 { $dataHash->{'conditioncolor'} = '#9900FF'; $dataHash->{'conditiontext'} = 'Received' } # Yellow/Purple
				case 4 { $dataHash->{'conditioncolor'} = '#66CC33'; $dataHash->{'conditiontext'} = 'Entered'  } # Green
				case 5 { $dataHash->{'conditioncolor'} = '#0000CC'; $dataHash->{'conditiontext'} = 'Shipped'  } # Blue
				case 6 { $dataHash->{'conditioncolor'} = '#666666'; $dataHash->{'conditiontext'} = 'Voided'   } # Black
				else   { $dataHash->{'conditioncolor'} = '#000000'; $dataHash->{'conditiontext'} = 'Unknown'  } # Default
				}
			}
		## indicator graphic text
		case 2
			{
				switch ($Condition)
					{
					case 1 { $dataHash->{'conditioncolor'} = 'Green-Routed' }
					case 2 { $dataHash->{'conditioncolor'} = 'Yellow-Packed' }
					case 3 { $dataHash->{'conditioncolor'} = 'Orange-Received' }
					case 4 { $dataHash->{'conditioncolor'} = 'Red-Entered' }
					case 5 { $dataHash->{'conditioncolor'} = 'Shipped-Blue' }
					case 6 { $dataHash->{'conditioncolor'} = 'Voided-Black' }
					else   { $dataHash->{'conditioncolor'} = 'Unknown-Unknown' }
					}
			}
		## indicator balls
		else
			{
				switch ($Condition)
					{
					case 1 { $dataHash->{'conditioncolor'} = 'red'    ; $dataHash->{'conditiontext'} = '!'   }
					case 2 { $dataHash->{'conditioncolor'} = 'orange' ; $dataHash->{'conditiontext'} = '!'   }
					case 3 { $dataHash->{'conditioncolor'} = 'yellow' ; $dataHash->{'conditiontext'} = '&Delta;' }
					case 4 { $dataHash->{'conditioncolor'} = 'green'  ; $dataHash->{'conditiontext'} = '&#10004;'  }
					case 5 { $dataHash->{'conditioncolor'} = 'blue'   ; $dataHash->{'conditiontext'} = '&#10004;'  }
					case 6 { $dataHash->{'conditioncolor'} = 'black'  ; $dataHash->{'conditiontext'} = '&#10004;'   }
					else   { $dataHash->{'conditioncolor'} = 'unknown'; $dataHash->{'conditiontext'} = 'Unknown'  }
				}
			}
		}

	$dataHash->{'conditiontext'} = '';
	return ($dataHash->{'conditioncolor'},$dataHash->{'conditiontext'});
	}

1;

__END__