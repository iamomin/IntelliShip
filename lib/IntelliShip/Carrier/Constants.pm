package IntelliShip::Carrier::Constants;

use Moose;
BEGIN { extends 'Exporter'; }

our $VERSION = 1.0;

our @EXPORT = qw(
	CARRIER_UPS
	CARRIER_DHL
	CARRIER_USPS
	CARRIER_FEDEX

	REQUEST_TYPE_SHIP_ORDER
	REQUEST_TYPE_VOID_SHIPMENT
	);

use constant CARRIER_UPS => "UPS";
use constant CARRIER_DHL => "DHL";
use constant CARRIER_USPS => "USPS";
use constant CARRIER_FEDEX => "FedEx";

use constant REQUEST_TYPE_SHIP_ORDER => "ShipOrder";
use constant REQUEST_TYPE_VOID_SHIPMENT => "VoidShipment";

__PACKAGE__->meta()->make_immutable();

no Moose;

1;

__END__