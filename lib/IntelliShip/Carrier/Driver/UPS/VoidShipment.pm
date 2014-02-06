package IntelliShip::Carrier::Driver::UPS::VoidShipment;

use Moose;
use Data::Dumper;
use IntelliShip::Utils;
use IntelliShip::DateUtils;

BEGIN { extends 'IntelliShip::Carrier::Driver'; }

sub process_request
	{
	my $self = shift;
	my $c = $self->context;
	my $Shipment = $self->SHIPMENT;

	$self->void_shipment;

	return $Shipment;
	}

__PACKAGE__->meta()->make_immutable();

no Moose;

1;

__END__
