package IntelliShip::Carrier::Constants;

use Moose;
BEGIN { extends 'Exporter'; }

our $VERSION = 1.0;

our @EXPORT = qw(
	CARRIER_FEDEX

	);

use constant CARRIER_FEDEX => "FedEx";

__PACKAGE__->meta()->make_immutable();

no Moose;

1;

__END__