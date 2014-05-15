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

	$self->log("Shipment Data" .Dumper($shipmentData));

	my ($API_name,$XML_request) = ('','');

	if ($shipmentData->{'servicecode'} eq 'USPSF')
		{
		$XML_request = $self->get_FirstClass_xml_request;
		$API_name = 'DeliveryConfirmationV4';
		}
	elsif ($shipmentData->{'servicecode'} eq 'USTPO')
		{
		$XML_request = $self->get_StandardPost_xml_request;
		$API_name = 'DeliveryConfirmationV4';
		}
	elsif ($shipmentData->{'servicecode'} =~ /(UPRIORITY|USPSPMFRE|USPSPMPFRE|USPSPMSFRB|USPSPMMFRB|USPSPMLFRB)/)
		{
		$XML_request = $self->get_PriorityMail_xml_request;
		$API_name = 'DeliveryConfirmationV4';
		}
	elsif ($shipmentData->{'servicecode'} eq 'USPSMM')
		{
		$XML_request = $self->get_MediaMail_xml_request;
		$API_name = 'DeliveryConfirmationV4';
		}
	elsif ($shipmentData->{'servicecode'} eq 'USPSLM')
		{
		$XML_request = $self->get_LibraryMail_xml_request;
		$API_name = 'DeliveryConfirmationV4';
		}
	elsif ($shipmentData->{'servicecode'} =~ /(UPME|USPSPMEFRE|USPSPMEPFRE|USPSPMEFRB)/)
		{
		$XML_request = $self->get_PriorityMailExpress_xml_request;
		$API_name = 'ExpressMailLabel';
		}

	my $url = 'https://secure.shippingapis.com/' . (IntelliShip::MyConfig->getDomain eq 'PRODUCTION' ? 'ShippingAPI.dll' : 'ShippingAPITest.dll');
	$self->log("Sending request to URL: " . $url);

	unless ($XML_request)
		{
		$self->add_error("This service is under construction. Please try another service.");
		return;
		}

	my $responseDS = $self->Call_API($url, $XML_request, $API_name);

	return unless $responseDS;

	## Check Commitment Days from USPS
	$self->Check_USPS_Commitment;

	my $TrackingNumber;

	if ($shipmentData->{'servicecode'} eq 'UPME' or $shipmentData->{'servicecode'} eq 'USPSPMEFRE' or $shipmentData->{'servicecode'} eq 'USPSPMEPFRE' or $shipmentData->{'servicecode'} eq 'USPSPMEFRB')
		{
		$TrackingNumber =$responseDS->{EMConfirmationNumber};
		$self->log("EMConfirmationNumber: ".$TrackingNumber);
		}
	else
		{
		$TrackingNumber =$responseDS->{DeliveryConfirmationNumber};
		$self->log("DeliveryConfirmationNumber: ".$TrackingNumber);
		}

	$shipmentData->{'barcodedata'} = $TrackingNumber ;

	$TrackingNumber = substr ($TrackingNumber, -22);

	my $Electronic  = substr ($TrackingNumber, 7,6);
	$self->log("Electronic: ".$Electronic);

	$self->log("TrackingNumber: ".$TrackingNumber);

	$shipmentData->{'tracking1'}    = $TrackingNumber;
	$shipmentData->{'ElectronicRateApproved'}    = $Electronic;
	$shipmentData->{'weight'}       = $shipmentData->{'enteredweight'};
	$shipmentData->{'RDC'}          = $responseDS->{RDC};
	$shipmentData->{'CarrierRoute'} = $responseDS->{CarrierRoute};
	unless ($shipmentData->{'expectedDelivery'})
		{
		$shipmentData->{'expectedDelivery'} = $responseDS->{Commitment}->{ScheduledDeliveryDate} if  $responseDS->{Commitment}->{ScheduledDeliveryDate};
		$shipmentData->{'expectedDelivery'} = IntelliShip::DateUtils->american_date($shipmentData->{'expectedDelivery'}) if $shipmentData->{'expectedDelivery'};
		}

	$shipmentData->{'commintmentName'} = uc($responseDS->{Commitment}->{CommitmentName}) if  $responseDS->{Commitment}->{CommitmentName};

	my $raw_string = $self->get_EPL($shipmentData);
	my $PrinterString = $raw_string;

	$shipmentData->{'printerstring'} = $PrinterString;

	$self->insert_shipment($shipmentData);
	$self->response->printer_string($PrinterString);
	}

sub get_FirstClass_xml_request
	{
	my $self = shift;
	my $shipmentData = $self->data;
	my $CO = $self->CO;
	my $Contact = $CO->contact;

	$self->log("### Get XML Request for First Class Mail ###: " );
	#$self->log("### Get XML Request ###: " . Dumper $shipmentData);

		$shipmentData->{serviceType} = 'First Class';

	#$self->log("### Service Type" .$shipmentData->{serviceType} );

	#$shipmentData->{FromName} =  $Contact->firstname.' '.$Contact->lastname;
	$shipmentData->{'weightinounces'} = $shipmentData->{'enteredweight'};

	#$shipmentData->{'dimheight'} = $shipmentData->{'dimheight'} ? $shipmentData->{'dimheight'} : 10;
	#$shipmentData->{'dimwidth'} = $shipmentData->{'dimwidth'} ? $shipmentData->{'dimwidth'} : 10;
	#$shipmentData->{'dimlength'} = $shipmentData->{'dimlength'} ? $shipmentData->{'dimlength'} : 10;

	#$self->log("Senders Name ". $shipmentData->{FromName});

	if ($shipmentData->{'dimheight'} > 12 or $shipmentData->{'dimwidth'} > 12 or $shipmentData->{'dimlength'} >12)
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
<FromName>$shipmentData->{'oacontactname'}</FromName>
<FromFirm>$shipmentData->{'customername'}</FromFirm>
<FromAddress1>$shipmentData->{'branchaddress2'}</FromAddress1>
<FromAddress2>$shipmentData->{'branchaddress1'}</FromAddress2>
<FromCity>$shipmentData->{'branchaddresscity'}</FromCity>
<FromState>$shipmentData->{'branchaddressstate'}</FromState>
<FromZip5>$shipmentData->{'branchaddresszip'}</FromZip5>
<FromZip4/>
<ToName>$shipmentData->{'contactname'}</ToName>
<ToFirm>$shipmentData->{'addressname'}</ToFirm>
<ToAddress1>$shipmentData->{'address2'}</ToAddress1>
<ToAddress2>$shipmentData->{'address1'}</ToAddress2>
<ToCity>$shipmentData->{'addresscity'}</ToCity>
<ToState>$shipmentData->{'addressstate'}</ToState>
<ToZip5>$shipmentData->{'addresszip'}</ToZip5>
<ToZip4/>
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

	#$self->log("... XML Request Data:  " . $XML_request);

	return $XML_request;
	}

sub get_StandardPost_xml_request
	{
	my $self = shift;
	my $shipmentData = $self->data;
	my $CO = $self->CO;
	my $Contact = $CO->contact;

	$self->log("### Get XML Request for Standar Post ###: " );
	#$self->log("### Get XML Request ###: " . Dumper $shipmentData);

		$shipmentData->{serviceType} = 'Standard Post';

	#$self->log("### Service Type" .$shipmentData->{serviceType} );

	#$shipmentData->{FromName} =  $Contact->firstname.' '.$Contact->lastname;
	$shipmentData->{'weightinounces'} = $shipmentData->{'enteredweight'};

	#$shipmentData->{'dimheight'} = $shipmentData->{'dimheight'} ? $shipmentData->{'dimheight'} : 10;
	#$shipmentData->{'dimwidth'} = $shipmentData->{'dimwidth'} ? $shipmentData->{'dimwidth'} : 10;
	#$shipmentData->{'dimlength'} = $shipmentData->{'dimlength'} ? $shipmentData->{'dimlength'} : 10;

	#$self->log("Senders Name ". $shipmentData->{FromName});

	if ($shipmentData->{'dimheight'} > 12 or $shipmentData->{'dimwidth'} > 12 or $shipmentData->{'dimlength'} >12)
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
<ImageParameters/>
<FromName>$shipmentData->{'oacontactname'}</FromName>
<FromFirm>$shipmentData->{'customername'}</FromFirm>
<FromAddress1>$shipmentData->{'branchaddress2'}</FromAddress1>
<FromAddress2>$shipmentData->{'branchaddress1'}</FromAddress2>
<FromCity>$shipmentData->{'branchaddresscity'}</FromCity>
<FromState>$shipmentData->{'branchaddressstate'}</FromState>
<FromZip5>$shipmentData->{'branchaddresszip'}</FromZip5>
<FromZip4/>
<ToName>$shipmentData->{'contactname'}</ToName>
<ToFirm>$shipmentData->{'addressname'}</ToFirm>
<ToAddress1>$shipmentData->{'address2'}</ToAddress1>
<ToAddress2>$shipmentData->{'address1'}</ToAddress2>
<ToCity>$shipmentData->{'addresscity'}</ToCity>
<ToState>$shipmentData->{'addressstate'}</ToState>
<ToZip5>$shipmentData->{'addresszip'}</ToZip5>
<ToZip4/>
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
<GroundOnly>True</GroundOnly>
</DeliveryConfirmationV4.0Request>
END

	#$self->log("... XML Request Data:  " . $XML_request);

	return $XML_request;
	}

my $containerTypeHash = {
	USPSPMFRE  => 'FLAT RATE ENVELOPE',
	USPSPMPFRE => 'PADDED FLAT RATE ENVELOPE',
	USPSPMSFRB => 'SM FLAT RATE BOX',
	USPSPMMFRB => 'MD FLAT RATE BOX',
	USPSPMLFRB => 'LG FLAT RATE BOX',

	USPSPMEFRE  => 'FLAT RATE ENVELOPE',
	USPSPMEPFRE => 'PADDED FLAT RATE ENVELOPE',
	USPSPMEFRB  => 'FLAT RATE BOX',
	};

sub get_PriorityMail_xml_request
	{
	my $self = shift;
	my $shipmentData = $self->data;
	my $CO = $self->CO;
	my $Contact = $CO->contact;

	$self->log("### Get XML Request for Priority Mail ###: " );
	#$self->log("### Get XML Request ###: " . Dumper $shipmentData);

		$shipmentData->{serviceType} = 'Priority';

	#$self->log("### Service Type" .$shipmentData->{serviceType} );

	#$shipmentData->{FromName} =  $Contact->firstname.' '.$Contact->lastname;
	$shipmentData->{'weightinounces'} = $shipmentData->{'enteredweight'};

	#$shipmentData->{'dimheight'} = $shipmentData->{'dimheight'} ? $shipmentData->{'dimheight'} : 10;
	#$shipmentData->{'dimwidth'} = $shipmentData->{'dimwidth'} ? $shipmentData->{'dimwidth'} : 10;
	#$shipmentData->{'dimlength'} = $shipmentData->{'dimlength'} ? $shipmentData->{'dimlength'} : 10;

	#$self->log("Senders Name ". $shipmentData->{FromName});

	if ($shipmentData->{'servicecode'} eq 'USPSPMLFRB')
		{
		$shipmentData->{'packagesize'} = 'REGULAR';
		}
	elsif ($shipmentData->{'dimheight'} > 12 or $shipmentData->{'dimwidth'} > 12 or $shipmentData->{'dimlength'} > 12)
		{
		$shipmentData->{'packagesize'} = 'LARGE';
		}
	else
		{
		$shipmentData->{'packagesize'} = 'REGULAR';
		}

	if ($shipmentData->{'packagesize'} eq 'LARGE')
		{
		$shipmentData->{'containerType'} = 'RECTANGULAR';
		}
	else
		{
		$shipmentData->{'containerType'} = 'VARIABLE';
		}

	my $containter_type = $containerTypeHash->{$shipmentData->{'servicecode'}};
	$shipmentData->{'containerType'} = $containter_type if $containter_type;

	my $XML_request = <<END;
<?xml version="1.0" encoding="UTF-8" ?>
<DeliveryConfirmationV4.0Request USERID="667ENGAG1719" PASSWORD="044BD12WF954">
<Revision>2</Revision>
<ImageParameters/>
<FromName>$shipmentData->{'oacontactname'}</FromName>
<FromFirm>$shipmentData->{'customername'}</FromFirm>
<FromAddress1>$shipmentData->{'branchaddress2'}</FromAddress1>
<FromAddress2>$shipmentData->{'branchaddress1'}</FromAddress2>
<FromCity>$shipmentData->{'branchaddresscity'}</FromCity>
<FromState>$shipmentData->{'branchaddressstate'}</FromState>
<FromZip5>$shipmentData->{'branchaddresszip'}</FromZip5>
<FromZip4/>
<ToName>$shipmentData->{'contactname'}</ToName>
<ToFirm>$shipmentData->{'addressname'}</ToFirm>
<ToAddress1>$shipmentData->{'address2'}</ToAddress1>
<ToAddress2>$shipmentData->{'address1'}</ToAddress2>
<ToCity>$shipmentData->{'addresscity'}</ToCity>
<ToState>$shipmentData->{'addressstate'}</ToState>
<ToZip5>$shipmentData->{'addresszip'}</ToZip5>
<ToZip4/>
<WeightInOunces>$shipmentData->{'weightinounces'}</WeightInOunces>
<ServiceType>$shipmentData->{serviceType}</ServiceType>
<SeparateReceiptPage>True</SeparateReceiptPage>
<ImageType>TIF</ImageType>
<AddressServiceRequested>False</AddressServiceRequested>
<HoldForManifest>N</HoldForManifest>
<Container>$shipmentData->{'containerType'}</Container>
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

sub get_MediaMail_xml_request
	{
	my $self = shift;
	my $shipmentData = $self->data;
	my $CO = $self->CO;
	my $Contact = $CO->contact;

	$self->log("### Get XML Request for Priority Mail ###: " );
	#$self->log("### Get XML Request ###: " . Dumper $shipmentData);

	$shipmentData->{serviceType} = 'Media Mail';

	#$self->log("### Service Type" .$shipmentData->{serviceType} );

	#$shipmentData->{FromName} =  $Contact->firstname.' '.$Contact->lastname;
	$shipmentData->{'weightinounces'} = $shipmentData->{'enteredweight'};

	#$shipmentData->{'dimheight'} = $shipmentData->{'dimheight'} ? $shipmentData->{'dimheight'} : 10;
	#$shipmentData->{'dimwidth'} = $shipmentData->{'dimwidth'} ? $shipmentData->{'dimwidth'} : 10;
	#$shipmentData->{'dimlength'} = $shipmentData->{'dimlength'} ? $shipmentData->{'dimlength'} : 10;

	#$self->log("Senders Name ". $shipmentData->{FromName});

	if ($shipmentData->{'dimheight'} > 12 or $shipmentData->{'dimwidth'} > 12 or $shipmentData->{'dimlength'} >12)
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
<ImageParameters/>
<FromName>$shipmentData->{'oacontactname'}</FromName>
<FromFirm>$shipmentData->{'customername'}</FromFirm>
<FromAddress1>$shipmentData->{'branchaddress2'}</FromAddress1>
<FromAddress2>$shipmentData->{'branchaddress1'}</FromAddress2>
<FromCity>$shipmentData->{'branchaddresscity'}</FromCity>
<FromState>$shipmentData->{'branchaddressstate'}</FromState>
<FromZip5>$shipmentData->{'branchaddresszip'}</FromZip5>
<FromZip4/>
<ToName>$shipmentData->{'contactname'}</ToName>
<ToFirm>$shipmentData->{'addressname'}</ToFirm>
<ToAddress1>$shipmentData->{'address2'}</ToAddress1>
<ToAddress2>$shipmentData->{'address1'}</ToAddress2>
<ToCity>$shipmentData->{'addresscity'}</ToCity>
<ToState>$shipmentData->{'addressstate'}</ToState>
<ToZip5>$shipmentData->{'addresszip'}</ToZip5>
<ToZip4/>
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

	#$self->log("... XML Request Data:  " . $XML_request);

	return $XML_request;
	}

sub get_LibraryMail_xml_request
	{
	my $self = shift;
	my $shipmentData = $self->data;
	my $CO = $self->CO;
	my $Contact = $CO->contact;

	$self->log("### Get XML Request for Library Mail ###: " );
	#$self->log("### Get XML Request ###: " . Dumper $shipmentData);

	$shipmentData->{serviceType} = 'Library Mail';

	#$self->log("### Service Type" .$shipmentData->{serviceType} );

	#$shipmentData->{FromName} =  $Contact->firstname.' '.$Contact->lastname;
	$shipmentData->{'weightinounces'} = $shipmentData->{'enteredweight'};

	#$shipmentData->{'dimheight'} = $shipmentData->{'dimheight'} ? $shipmentData->{'dimheight'} : 10;
	#$shipmentData->{'dimwidth'} = $shipmentData->{'dimwidth'} ? $shipmentData->{'dimwidth'} : 10;
	#$shipmentData->{'dimlength'} = $shipmentData->{'dimlength'} ? $shipmentData->{'dimlength'} : 10;

	#$self->log("Senders Name ". $shipmentData->{FromName});

	if ($shipmentData->{'dimheight'} > 12 or $shipmentData->{'dimwidth'} > 12 or $shipmentData->{'dimlength'} >12)
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
<ImageParameters/>
<FromName>$shipmentData->{'oacontactname'}</FromName>
<FromFirm>$shipmentData->{'customername'}</FromFirm>
<FromAddress1>$shipmentData->{'branchaddress2'}</FromAddress1>
<FromAddress2>$shipmentData->{'branchaddress1'}</FromAddress2>
<FromCity>$shipmentData->{'branchaddresscity'}</FromCity>
<FromState>$shipmentData->{'branchaddressstate'}</FromState>
<FromZip5>$shipmentData->{'branchaddresszip'}</FromZip5>
<FromZip4/>
<ToName>$shipmentData->{'contactname'}</ToName>
<ToFirm>$shipmentData->{'addressname'}</ToFirm>
<ToAddress1>$shipmentData->{'address2'}</ToAddress1>
<ToAddress2>$shipmentData->{'address1'}</ToAddress2>
<ToCity>$shipmentData->{'addresscity'}</ToCity>
<ToState>$shipmentData->{'addressstate'}</ToState>
<ToZip5>$shipmentData->{'addresszip'}</ToZip5>
<ToZip4/>
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

	#$self->log("... XML Request Data:  " . $XML_request);

	return $XML_request;
	}

sub get_PriorityMailExpress_xml_request
	{
	my $self = shift;
	my $shipmentData = $self->data;
	my $CO = $self->CO;
	my $Contact = $CO->contact;

	#$self->log("### Get XML Request for Standar Post ###: " );
	#$self->log("### Get XML Request ###: " . Dumper $shipmentData);

	$shipmentData->{serviceType} = 'Standard Post';

	#$self->log("### Service Type" .$shipmentData->{serviceType} );

	$shipmentData->{'FromFirstName'} =  $Contact->firstname;
	$shipmentData->{'FromLastName'} = $Contact->lastname;
	$shipmentData->{FromName} =  $Contact->firstname.' '.$Contact->lastname;
	$shipmentData->{'weightinounces'} = $shipmentData->{'enteredweight'};

	#$shipmentData->{'dimheight'} = $shipmentData->{'dimheight'} ? $shipmentData->{'dimheight'} : 10;
	#$shipmentData->{'dimwidth'} = $shipmentData->{'dimwidth'} ? $shipmentData->{'dimwidth'} : 10;
	#$shipmentData->{'dimlength'} = $shipmentData->{'dimlength'} ? $shipmentData->{'dimlength'} : 10;

	#$self->log("Senders Name ". $shipmentData->{FromName});

	if ($shipmentData->{'dimheight'} > 12 or $shipmentData->{'dimwidth'} > 12 or $shipmentData->{'dimlength'} >12)
		{
		$shipmentData->{'packagesize'} = 'LARGE';
		}
	else
		{
		$shipmentData->{'packagesize'} = 'REGULAR';
		}

	if ($shipmentData->{'packagesize'} eq 'LARGE')
		{
		$shipmentData->{'containerType'} = 'RECTANGULAR';
		}
	else
		{
		$shipmentData->{'containerType'} = 'VARIABLE';
		}

	my $containter_type = $containerTypeHash->{$shipmentData->{'servicecode'}};
	$shipmentData->{'containerType'} = $containter_type if $containter_type;

	my $XML_request = <<END;
<?xml version="1.0" encoding="UTF-8" ?>
<ExpressMailLabelRequest USERID="667ENGAG1719">
<Option />
<Revision>2</Revision>
<EMCAAccount />
<EMCAPassword />
<ImageParameters />
<FromFirstName>$shipmentData->{FromFirstName}</FromFirstName>
<FromLastName>$shipmentData->{FromLastName}</FromLastName>
<FromFirm>$shipmentData->{'customername'}</FromFirm>
<FromAddress1>$shipmentData->{'branchaddress2'}</FromAddress1>
<FromAddress2>$shipmentData->{'branchaddress1'}</FromAddress2>
<FromCity>$shipmentData->{'branchaddresscity'}</FromCity>
<FromState>$shipmentData->{'branchaddressstate'}</FromState>
<FromZip5>$shipmentData->{'branchaddresszip'}</FromZip5>
<FromZip4/>
<FromPhone>2125551234</FromPhone>
<ToFirstName>Janice</ToFirstName>
<ToLastName>Dickens</ToLastName>
<ToFirm>$shipmentData->{'addressname'}</ToFirm>
<ToAddress1>$shipmentData->{'address2'}</ToAddress1>
<ToAddress2>$shipmentData->{'address1'}</ToAddress2>
<ToCity>$shipmentData->{'addresscity'}</ToCity>
<ToState>$shipmentData->{'addressstate'}</ToState>
<ToZip5>$shipmentData->{'addresszip'}</ToZip5>
<ToZip4 />
<ToPhone>2125551234</ToPhone>
<WeightInOunces>$shipmentData->{'weightinounces'}</WeightInOunces>
<SundayHolidayDelivery/>
<StandardizeAddress/>
<WaiverOfSignature/>
<NoWeekend/>
<SeparateReceiptPage>True</SeparateReceiptPage>
<POZipCode>$shipmentData->{'addresszip'}</POZipCode>
<FacilityType>DDU</FacilityType>
<ImageType>PDF</ImageType>
<CustomerRefNo/>
<SenderName>$shipmentData->{FromName}</SenderName>
<SenderEMail>$shipmentData->{'fromemail'}</SenderEMail>
<RecipientName>$shipmentData->{'contactname'}</RecipientName>
<RecipientEMail>$shipmentData->{'toemail'}</RecipientEMail>
<HoldForManifest/>
<CommercialPrice>false</CommercialPrice>
<InsuredAmount>425.00</InsuredAmount>
<Container>$shipmentData->{'containerType'}</Container>
<Size>$shipmentData->{'packagesize'}</Size>
<Width>$shipmentData->{'dimheight'}</Width>
<Length>$shipmentData->{'dimwidth'}</Length>
<Height>$shipmentData->{'dimlength'}</Height>
<ReturnCommitments>true</ReturnCommitments>
</ExpressMailLabelRequest>
END

	$self->log("... XML Request Data:  " . $XML_request);

	return $XML_request;
	}

sub Check_USPS_Commitment
	{
	my $self = shift;
	my $shipmentData = $self->data;
	my $url = 'http://production.shippingapis.com/ShippingAPITest.dll';

	if ($shipmentData->{'servicecode'} =~ /(UPME|USPSPMEFRE|USPSPMEPFRE|USPSPMEFRB)/)
		{
		my $XML_request = $self->get_Commitment_XML('ExpressMailCommitment');
		my $responseDS = $self->Call_API($url, $XML_request, 'ExpressMailCommitment');

		return unless $responseDS;

		my $Commitement = (ref $responseDS->{Commitment} eq 'ARRAY' ? $responseDS->{Commitment} : [$responseDS->{Commitment}]);

		#$self->log("commintmentName " .$Commitement->[0]->{CommitmentName});

		$shipmentData->{'commintmentName'} = uc($Commitement->[0]->{CommitmentName}) if  $Commitement->[0]->{CommitmentName};
		$shipmentData->{'CommitmentTime'} = $Commitement->[0]->{CommitmentTime} if  $Commitement->[0]->{CommitmentTime};

		#$self->log("Date1 " .$shipmentData->{'datetoship'});
		my $Days = substr ($shipmentData->{'commintmentName'}, 0,1);
		#$self->log("Day " .$Days);
		$shipmentData->{'expectedDelivery'} = IntelliShip::DateUtils->get_future_business_date($shipmentData->{'dateshipped'},$Days,0,0);
		#$self->log("Date1 " .$shipmentData->{'expectedDelivery'} );
		}
	elsif ($shipmentData->{'servicecode'} =~ /(UPRIORITY|USPSPMFRE|USPSPMPFRE|USPSPMSFRB|USPSPMMFRB|USPSPMLFRB)/)
		{
		my $XML_request = $self->get_Commitment_XML('PriorityMail');
		my $responseDS = $self->Call_API($url, $XML_request, 'PriorityMail');

		return unless $responseDS;

		my $Days = $responseDS->{Days};
		$self->log("Day " .$Days);
		$shipmentData->{'expectedDelivery'} = IntelliShip::DateUtils->get_future_business_date($shipmentData->{'dateshipped'},$Days,0,0);
		$self->log("expectedDelivery " .$shipmentData->{'expectedDelivery'} );
		}
	}

sub get_Commitment_XML
	{
	my $self = shift;
	my $API_NAME = shift;
	my $shipmentData = $self->data;
	my $API_REQUEST_TAG = $API_NAME . 'Request';

	my $XML_request = <<END;
<?xml version="1.0" encoding="UTF-8" ?>
<$API_REQUEST_TAG USERID="667ENGAG1719">
<OriginZIP>$shipmentData->{'branchaddresszip'}</OriginZIP>
<DestinationZIP>$shipmentData->{'addresszip'}</DestinationZIP>
<Date>$shipmentData->{'datetoship'}</Date>
</$API_REQUEST_TAG>
END
	}

sub Call_API
	{
	my $self = shift;
	my $URL = shift;
	my $XML = shift;
	my $API_NAME = shift;
	my $shipmentData = $self->data;
	my $API_REQUEST_TAG = $API_NAME . 'Request';

	$self->log( "... USPS XML REQUEST: " . $XML);

	my $shupment_request = {
			httpurl => $URL,
			API => $API_NAME,
			XML => $XML
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
		return;
		}

	$self->log( "... RESPONSE DETAILS: " . Dumper $response->content);

	my $xml = new XML::Simple;

	my $responseDS = $xml->XMLin($response->content);

	if ( $responseDS->{Number} and $responseDS->{Description})
		{
		my $msg = "Carrier Response Error: ".$responseDS->{Number}. " : ". $responseDS->{Description};
		$self->add_error($msg);
		$self->log($msg);
		return;
		}

	if ($responseDS->{Number} and $responseDS->{Description})
		{
		my $msg = "Carrier Response Error: ".$responseDS->{Number}. " : ". $responseDS->{Description};
		$self->add_error($msg);
		$self->log($msg);
		return;
		}

	return $responseDS;
	}

__PACKAGE__->meta()->make_immutable();

no Moose;

1;

__END__