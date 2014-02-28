package IntelliShip::Carrier::Driver::USPS::ShipOrder;

use Moose;
use XML::Simple;
use Data::Dumper;
use LWP::UserAgent;
use IntelliShip::DateUtils;
use HTTP::Request::Common;
use IntelliShip::MyConfig;

BEGIN { extends 'IntelliShip::Carrier::Driver'; }

sub process_request
	{
	my $self = shift;

	my $CO = $self->CO;
	my $Customer = $CO->customer;
	my $shipmentData = $self->data;

	$self->log("Process USPS Ship Order");

	#$self->log("Shipment Data" .Dumper($shipmentData));

	$shipmentData->{'dateshipped'} = $shipmentData->{'datetoship'};
	$shipmentData->{'datetoship'} = IntelliShip::DateUtils->format_to_yyyymmdd($shipmentData->{'datetoship'});

	my $reqest = <<END;
<?xml version="1.0" encoding="UTF-8" ?>
<DeliveryConfirmationV4.0Request USERID="667ENGAG1719" PASSWORD="044BD12WF954">
<Revision>2</Revision>
<ImageParameters />
<FromName>Prashant</FromName>
<FromFirm> $shipmentData->{'customername'}</FromFirm>
<FromAddress1>$shipmentData->{'branchaddress1'}</FromAddress1>
<FromAddress2>$shipmentData->{'branchaddress2'}</FromAddress2>
<FromCity>$shipmentData->{'branchaddresscity'}</FromCity>
<FromState>$shipmentData->{'branchaddressstate'}</FromState>
<FromZip5>$shipmentData->{'branchaddresszip'}</FromZip5>
<FromZip4/>
<ToName>Imran</ToName>
<ToFirm>$shipmentData->{'addressname'}</ToFirm>
<ToAddress1>$shipmentData->{'address1'}</ToAddress1>
<ToAddress2>$shipmentData->{'address2'}</ToAddress2>
<ToCity>$shipmentData->{'addresscity'}</ToCity>
<ToState>$shipmentData->{'addressstate'}</ToState>
<ToZip5>$shipmentData->{'addresszip'}</ToZip5>
<ToZip4 />
<ToPOBoxFlag></ToPOBoxFlag>
<WeightInOunces>10</WeightInOunces>
<ServiceType>First Class</ServiceType>
<SeparateReceiptPage>False</SeparateReceiptPage>
<ImageType>TIF</ImageType>
<AddressServiceRequested>False</AddressServiceRequested>
<HoldForManifest>N</HoldForManifest>
<Container>NONRECTANGULAR</Container>
<Size>LARGE</Size>
<Width>7</Width>
<Length>20.5</Length>
<Height>15</Height>
<Girth>60</Girth>
<ReturnCommitments>true</ReturnCommitments>
</DeliveryConfirmationV4.0Request>
END

	$self->log("Shipment Data" .Dumper($reqest));

	my $url = 'https://secure.shippingapis.com/' . (IntelliShip::MyConfig->getDomain eq 'PRODUCTION' ? 'ShippingAPI.dll' : 'ShippingAPITest.dll');
	$self->log("Sending request to URL: " . $url);

	my $shupment_request = {
			httpurl => $url,
			API => 'DeliveryConfirmationV4',
			XML => $reqest
		};

	$self->log("Shipment Request" .Dumper($shupment_request));

	my $UserAgent = LWP::UserAgent->new();
	my $response = $UserAgent->request(
			POST $shupment_request->{'httpurl'},
			Content_Type  => 'text/html',
			Content       => [%$shupment_request]
			);

	unless ($response)
		{
		$self->log("USPS: Unable to access USPS site");
		$self->add_error("No response received from USPS");
		return $shipmentData;
		}

	$self->log( "### RESPONSE IS SUCCESS: " . $response->is_success);
	#$self->log( "### RESPONSE DETAILS: " . Dumper $response->content);

	my $xml = new XML::Simple;

	my $XMLResponse = $xml->XMLin($response->content);

	my $PrinterString = $XMLResponse->{DeliveryConfirmationLabel};
	my $TrackingNumber =$XMLResponse->{DeliveryConfirmationNumber};

	$self->log("PrinterString: " . $PrinterString);

	#$PrinterString = $self->TagPrinterString($PrinterString,$shipmentData->{'ordernumber'});

	$shipmentData->{'tracking1'} = $TrackingNumber;
	$shipmentData->{'printerstring'} = $PrinterString;
	$shipmentData->{'weight'} = $shipmentData->{'enteredweight'};

	$self->log("### shipmentData ###: " . Dumper $shipmentData);

	$self->insert_shipment($shipmentData);
	$self->response->printer_string($PrinterString);
	}

__PACKAGE__->meta()->make_immutable();

no Moose;

1;

__END__