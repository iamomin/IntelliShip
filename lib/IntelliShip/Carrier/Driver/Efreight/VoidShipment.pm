package IntelliShip::Carrier::Driver::Efreight::VoidShipment;

use Moose;

BEGIN { extends 'IntelliShip::Carrier::Driver'; }

sub process_request
	{
	my $self = shift;
	my $c = $self->context;
	my $Shipment = $self->SHIPMENT;

	$Shipment->statusid('6'); ## Voiding
	$Shipment->update;

	$self->void_shipment;

	return $Shipment;
	}

__PACKAGE__->meta()->make_immutable();

no Moose;

1;

__END__
