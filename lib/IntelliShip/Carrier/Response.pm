package IntelliShip::Carrier::Response;

use Moose;
use Data::Dumper;
use IntelliShip::Utils;

BEGIN {

	extends 'IntelliShip::Errors';

	has 'shipment' => ( is => 'rw' );
	has 'printer_string' => ( is => 'rw' );

	has 'message' => ( is => 'rw' );
	has 'is_success' => ( is => 'rw' );
	has 'response_code' => ( is => 'rw' );
	}

__PACKAGE__->meta()->make_immutable();

no Moose;

1;

__END__