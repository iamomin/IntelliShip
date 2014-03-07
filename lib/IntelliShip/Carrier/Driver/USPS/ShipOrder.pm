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

	my $XML_request = $self->get_xml_request;

	my $url = 'https://secure.shippingapis.com/' . (IntelliShip::MyConfig->getDomain eq 'PRODUCTION' ? 'ShippingAPI.dll' : 'ShippingAPITest.dll');
	$self->log("Sending request to URL: " . $url);

	my $API = 'DeliveryConfirmationV4';
	my $shupment_request = {
			httpurl => $url,
			API => $API,
			XML => $XML_request
		};

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

	#$self->log( "### RESPONSE IS SUCCESS: " . $response->is_success);
	#$self->log( "### RESPONSE DETAILS: " . Dumper $response->content);

	my $xml = new XML::Simple;

	my $XMLResponse = $xml->XMLin($response->content);

	if( $XMLResponse->{Number} and $XMLResponse->{Description})
		{
		$self->log("USPS: Shipment information is no valid");
		$self->add_error( $XMLResponse->{Description});
		return $shipmentData;
		}

	my $TrackingNumber =$XMLResponse->{DeliveryConfirmationNumber};
	$self->log("DeliveryConfirmationNumber: ".$TrackingNumber);

	$shipmentData->{'barcodedata'} = $TrackingNumber ;
	
	$TrackingNumber = substr ($TrackingNumber, -22);
	$self->log("TrackingNumber: ".$TrackingNumber);

	$shipmentData->{'tracking1'}    = $TrackingNumber;
	$shipmentData->{'weight'}       = $shipmentData->{'enteredweight'};
	$shipmentData->{'RDC'}          = $XMLResponse->{RDC};
	$shipmentData->{'CarrierRoute'} = $XMLResponse->{CarrierRoute};

	my $raw_string = $self->get_EPL($shipmentData);
	my $PrinterString = $raw_string;
	$shipmentData->{'printerstring'} = $PrinterString;

	$self->insert_shipment($shipmentData);
	$self->response->printer_string($PrinterString);
	}

sub get_xml_request
	{
	my $self = shift;
	my $shipmentData = $self->data;
	my $CO = $self->CO;
	my $Contact = $CO->contact;

	$self->log("### Get XML Request ###: " );
	#$self->log("### Get XML Request ###: " . Dumper $shipmentData);

	if ($shipmentData->{servicecode} eq 'USPSF')
		{
		$shipmentData->{serviceType} = 'First Class';
		}
	elsif($shipmentData->{servicecode} eq 'ST')
		{
		$shipmentData->{serviceType} = 'Standard Post';
		}
	else
		{
		$self->log("Invalid Service Type");
		$self->add_error("Invalid Service Type");
		return $shipmentData;
		}

	#$self->log("### Service Type" .$shipmentData->{serviceType} );

	$shipmentData->{FromName} =  $Contact->firstname.' '.$Contact->lastname;
	$shipmentData->{'weightinounces'} = $shipmentData->{'enteredweight'};
	$shipmentData->{'dimheight'} = $shipmentData->{'dimheight'} ? $shipmentData->{'dimheight'} : 10;
	$shipmentData->{'dimwidth'} = $shipmentData->{'dimwidth'} ? $shipmentData->{'dimwidth'} : 10;
	$shipmentData->{'dimlength'} = $shipmentData->{'dimlength'} ? $shipmentData->{'dimlength'} : 10;

	#$self->log("Senders Name ". $shipmentData->{FromName});

	if($shipmentData->{'dimheight'} > 12 or $shipmentData->{'dimwidth'} > 12 or $shipmentData->{'dimlength'} >12)
		{
		$shipmentData->{'packagesize'} = 'LARGE';
		}
	else
		{
		$shipmentData->{'packagesize'} = 'REGULAR';
		}

	my $XML_request = <<END;
<?xml version="1.0" encoding="UTF-8" ?>
<DeliveryConfirmationV4.0Request USERID="667ENGAG1719" PASSWORD="044BD12WF954">
<Revision>2</Revision>
<ImageParameters />
<FromName>$shipmentData->{FromName}</FromName>
<FromFirm>$shipmentData->{'customername'}</FromFirm>
<FromAddress1>$shipmentData->{'branchaddress1'}</FromAddress1>
<FromAddress2>$shipmentData->{'branchaddress2'}</FromAddress2>
<FromCity>$shipmentData->{'branchaddresscity'}</FromCity>
<FromState>$shipmentData->{'branchaddressstate'}</FromState>
<FromZip5>$shipmentData->{'branchaddresszip'}</FromZip5>
<FromZip4/>
<ToName>$shipmentData->{'contactname'}</ToName>
<ToFirm>$shipmentData->{'addressname'}</ToFirm>
<ToAddress1>$shipmentData->{'address1'}</ToAddress1>
<ToAddress2>$shipmentData->{'address2'}</ToAddress2>
<ToCity>$shipmentData->{'addresscity'}</ToCity>
<ToState>$shipmentData->{'addressstate'}</ToState>
<ToZip5>$shipmentData->{'addresszip'}</ToZip5>
<ToZip4 />
<WeightInOunces>$shipmentData->{'weightinounces'}</WeightInOunces>
<ServiceType>$shipmentData->{serviceType}</ServiceType>
<SeparateReceiptPage>True</SeparateReceiptPage>
<ImageType>TIF</ImageType>
<AddressServiceRequested>False</AddressServiceRequested>
<HoldForManifest>N</HoldForManifest>
<Size>$shipmentData->{'packagesize'}</Size>
<Width>$shipmentData->{'dimheight'}</Width>
<Length>$shipmentData->{'dimwidth'}</Length>
<Height>$shipmentData->{'dimlength'}</Height>
<ReturnCommitments>true</ReturnCommitments>
</DeliveryConfirmationV4.0Request>
END

	$self->log("... XML Request Data:  " . $XML_request);

	return $XML_request;
	}

__PACKAGE__->meta()->make_immutable();

no Moose;

1;

__END__