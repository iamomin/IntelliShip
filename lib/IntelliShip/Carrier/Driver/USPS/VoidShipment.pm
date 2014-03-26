package IntelliShip::Carrier::Driver::USPS::VoidShipment;

use Moose;

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
