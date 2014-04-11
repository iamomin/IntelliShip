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

	my $licensekey  = '6E9A6C1E-C6C2-4170-887E-718A3DDE47F3';
	my $customerkey = '31930';
	my $url = 'http://legacy.efsww.com/LTLService/3/LTLWEBService.svc';
	#my $url = 'http://www.efsww.com/LTLService/3/LTLWEBService.svc';
	#my $url = 'http://192.168.55.49:8058/LTLService/9/LTLWEBService.svc';
	my $soap = SOAP::Lite
	->on_action( sub {sprintf '%sILTLService/%s', @_} )
	->proxy( $url )
	->encodingStyle('http://xml.apache.org/xml-soap/literalxml')
	->readable(1);

	my $serializer = $soap->serializer();
	$serializer->register_ns('http://schemas.datacontract.org/2004/07/FreightLTL','fre');
	$serializer->register_ns('http://tempuri.org/','tem');

	my $method = SOAP::Data->name('SetOrderStatus')->prefix('tem');
	my $trackingnumber = $Shipment->tracking1;

	my $input = SOAP::Data
	->name("request" => \SOAP::Data->value(
	SOAP::Data->name("Authentication" => \SOAP::Data->value(
		SOAP::Data->name('LicenseKey' => $licensekey)->prefix('fre')
	))->prefix('fre'),
	SOAP::Data->name("Customer" => \SOAP::Data->value(
		SOAP::Data->name('CustomerKey' => $customerkey)->prefix('fre')
	))->prefix('fre'),
	SOAP::Data->name("OrderNumber" => SOAP::Data->value($trackingnumber))->prefix('fre'),
	SOAP::Data->name("NewOrderStatus" => SOAP::Data->value('OrderCancelledByCustomer'))->prefix('fre'),
	))->prefix('tem');

	my @params;
	push(@params,$input);

	my $som = $soap->call($method => @params);

	$self->void_shipment;

	return $Shipment;
	}

__PACKAGE__->meta()->make_immutable();

no Moose;

1;

__END__
