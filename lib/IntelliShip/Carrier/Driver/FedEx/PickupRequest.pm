package IntelliShip::Carrier::Driver::FedEx::PickupRequest;

use Moose;
use Data::Dumper;
use LWP::UserAgent;

BEGIN { extends 'IntelliShip::Carrier::Driver'; }

sub process_request
	{
	my $self = shift;

	my $c = $self->context;
	my $CO = $self->CO;
	my $Shipment = $self->SHIPMENT;


	my $CustomerService = $self->customerservice;
	my $Service = $self->service;

	$self->log("Process PickupRequest");


	my $PickupRequest = {
		CustomerTransactionId => $Shipment->coid . '-' . $Shipment->shipmentid . '-' . $Shipment->customerserviceid,
		PersonName            => $Shipment->contactname,
		PhoneNumber           => $Shipment->contactphone,
		};

	# Get 'from' information
	my $FromAddress = $Shipment->origin_address;

	$PickupRequest->{CompanyName} = $FromAddress->addressname;
	$PickupRequest->{StreetLines} = $FromAddress->address1;
	$PickupRequest->{BuildingPartDescription} = $FromAddress->address2;
	$PickupRequest->{City} = $FromAddress->city;
	$PickupRequest->{StateOrProvinceCode} = $FromAddress->state;
	$PickupRequest->{PostalCode} = $FromAddress->zip;
	$PickupRequest->{CountryCode} = $FromAddress->country;

	$PickupRequest->{ReadyTimestamp} = $Shipment->datepacked;
	$PickupRequest->{PackageLocation} = 'FRONT';
	$PickupRequest->{CompanyCloseTime} = '20:00:00';
	$PickupRequest->{PackageCount} = $Shipment->total_quantity;
	$PickupRequest->{TotalWeightUnits} = 'LB';
	$PickupRequest->{TotalWeightValue} = $Shipment->total_weight;

	$PickupRequest->{webaccount} = $CustomerService->{'webaccount'};
	$PickupRequest->{meternumber} = $CustomerService->{'meternumber'};

	my $CarrierCodes = {
		'XXX' => 'FDXC',
		'FES' => 'FDXE',
		'FGD' => 'FDXG',
		'YYY' => 'FXCC',
		'ZZZ' => 'FXFR',
		'FES' => 'FXSP',
		};

	$PickupRequest->{CarrierCode} = 'FDXE';

	$self->log("....PickupRequest : " . Dumper $PickupRequest);

	my $XMLString = $self->get_XML_v6($PickupRequest);

	## Send request to FedEx
	##my $URL = 'https://fedex.com/ws/pickup/v6/';
	#my $URL = 'https://wsbeta.fedex.com/web-services';
	my $URL = 'https://ws.fedex.com:443/web-services';
	my $UA = LWP::UserAgent->new();
	#warn "\nURL: " . $URL;
	my $Response = $UA->post($URL, Content_Type => 'text/xml', Content => $XMLString);

	unless ($Response)
		{
		$self->add_error("FedEx CreatePickupRequest: Unable to access FedEx site");
		return 0;
		}

	#warn "\nResponse->is_success: " . $Response->is_success;
	unless ($Response->is_success)
		{
		$self->add_error("FedEx.CreatePickupRequest. Error: " . $Response->status_line);
		return 0;
		}

	$self->log("FedEx CreatePickup ResponseString: " . $Response->content);

	$self->SendPickUpEmail();

	return 1;
	}

sub get_XML_v6
	{
	my $self = shift;
	my $DATA = shift;

	#my $KEY = 'UxLTyJQXOfbugKrv';
	#my $PASSWORD = 'RV8jsHTfHzyctQeRbCuofy00q';
	#my $METER = '118601941';
	#my $ACCOUNT = '510087240';
	my $KEY = 'I4nV8IlyPI3TkOA8';
	my $PASSWORD = 'yZatPfw3ZNBe7ucOGjKqIzevt';
	#my $METER = '106298713';
	#my $ACCOUNT = '501929301';
	#my $ACCOUNT = '494036924';
	#my $METER = '253301';

	my $XML_request = <<END;
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns1="http://fedex.com/ws/pickup/v6">
  <SOAP-ENV:Body>
    <ns1:CreatePickupRequest>
      <ns1:WebAuthenticationDetail>
        <ns1:UserCredential>
          <ns1:Key>$KEY</ns1:Key>
          <ns1:Password>$PASSWORD</ns1:Password>
        </ns1:UserCredential>
      </ns1:WebAuthenticationDetail>
      <ns1:ClientDetail>
        <ns1:AccountNumber>$DATA->{'webaccount'}</ns1:AccountNumber>
        <ns1:MeterNumber>$DATA->{'meternumber'}</ns1:MeterNumber>
      </ns1:ClientDetail>
      <ns1:TransactionDetail>
        <ns1:CustomerTransactionId>$DATA->{'CustomerTransactionId'}</ns1:CustomerTransactionId>
      </ns1:TransactionDetail>
      <ns1:Version>
        <ns1:ServiceId>disp</ns1:ServiceId>
        <ns1:Major>6</ns1:Major>
        <ns1:Intermediate>0</ns1:Intermediate>
        <ns1:Minor>0</ns1:Minor>
      </ns1:Version>
      <ns1:OriginDetail>
        <ns1:PickupLocation>
          <ns1:Contact>
            <ns1:PersonName>$DATA->{'PersonName'}</ns1:PersonName>
            <ns1:CompanyName>$DATA->{'CompanyName'}</ns1:CompanyName>
            <ns1:PhoneNumber>$DATA->{'PhoneNumber'}</ns1:PhoneNumber>
          </ns1:Contact>
          <ns1:Address>
            <ns1:StreetLines>$DATA->{'StreetLines'}</ns1:StreetLines>
            <ns1:City>$DATA->{'City'}</ns1:City>
            <ns1:StateOrProvinceCode>$DATA->{'StateOrProvinceCode'}</ns1:StateOrProvinceCode>
            <ns1:PostalCode>$DATA->{'PostalCode'}</ns1:PostalCode>
            <ns1:CountryCode>$DATA->{'CountryCode'}</ns1:CountryCode>
          </ns1:Address>
        </ns1:PickupLocation>
        <ns1:PackageLocation>$DATA->{'PackageLocation'}</ns1:PackageLocation>
        <ns1:BuildingPartDescription>$DATA->{'BuildingPartDescription'}</ns1:BuildingPartDescription>
        <ns1:ReadyTimestamp>$DATA->{'ReadyTimestamp'}</ns1:ReadyTimestamp>
        <ns1:CompanyCloseTime>$DATA->{'CompanyCloseTime'}</ns1:CompanyCloseTime>
      </ns1:OriginDetail>
      <ns1:PackageCount>$DATA->{'PackageCount'}</ns1:PackageCount>
      <ns1:TotalWeight>
        <ns1:Units>$DATA->{'TotalWeightUnits'}</ns1:Units>
        <ns1:Value>$DATA->{'TotalWeightValue'}</ns1:Value>
      </ns1:TotalWeight>
      <ns1:CarrierCode>$DATA->{'CarrierCode'}</ns1:CarrierCode>
    </ns1:CreatePickupRequest>
  </SOAP-ENV:Body>
</SOAP-ENV:Envelope>
END

	$XML_request =~ s/\n+//g;
	$XML_request =~ s/\s{2}//g;

	#warn "\n... Pickup REQUEST: " . $XML_request;

	return $XML_request;
	}

__PACKAGE__->meta()->make_immutable();

no Moose;

1;

__END__
