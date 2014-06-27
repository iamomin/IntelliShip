package IntelliShip::Carrier::Driver::FedEx::PickupRequest;

use Moose;
use Data::Dumper;
use LWP::UserAgent;
use IntelliShip::Utils;

BEGIN { extends 'IntelliShip::Carrier::Driver'; }

#my $URL = 'https://wsbeta.fedex.com/web-services';
my $URL = 'https://ws.fedex.com:443/web-services';

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

	$PickupRequest->{PackageLocation} = 'FRONT';
	$PickupRequest->{CompanyCloseTime} = '20:00:00';
	$PickupRequest->{PackageCount} = $Shipment->total_quantity;
	$PickupRequest->{TotalWeightUnits} = 'LB';
	$PickupRequest->{TotalWeightValue} = $Shipment->total_weight;

	$PickupRequest->{webaccount}   = $CustomerService->{'webaccount'};
	$PickupRequest->{meternumber}  = $CustomerService->{'meternumber'};
	$PickupRequest->{DispatchDate} = $Shipment->datepacked;

	#my $CarrierCodes = {
	#	'XXX' => 'FDXC',
	#	'FES' => 'FDXE',
	#	'FGD' => 'FDXG',
	#	'YYY' => 'FXCC',
	#	'ZZZ' => 'FXFR',
	#	'FES' => 'FXSP',
	#	};

	my ($ResponseCode,$Message,$CustomerTransactionId,$ConfirmationNumber,$next_day_pickup_reqeust,$Location);

	if ($Shipment->service =~ /Ground/i)
		{
		$PickupRequest->{CarrierCode} = 'FDXE';
		$next_day_pickup_reqeust = 1;
		}
	else
		{
		my $sth = $self->myDBI->select("SELECT datepacked FROM shipment WHERE shipmentid='" . $Shipment->shipmentid . "'");
		my ($dispatchdate,$timepacked) = split(/\ /,$sth->fetchrow(0)->{'datepacked'}) if $sth->numrows;
		$PickupRequest->{DispatchDate} = $dispatchdate;

		$PickupRequest->{CarrierCode} = 'FDXG';
		($ResponseCode,$Message,$CustomerTransactionId,$ConfirmationNumber) = $self->send_same_day_pickup_request($PickupRequest);
		$next_day_pickup_reqeust = 1 unless $ResponseCode =~ /0000/;
		}

	if ($next_day_pickup_reqeust)
		{
		my $sth = $self->myDBI->select("SELECT datepacked + interval '1 day' as datepacked FROM shipment WHERE shipmentid='" . $Shipment->shipmentid . "'");
		my ($datepacked,$timepacked) = split(/\ /,$sth->fetchrow(0)->{'datepacked'}) if $sth->numrows;

		## Send pickup request time to the next day 9AM morning
		$datepacked .= 'T09:00:00.1234'; ## 2014-05-15T09:00:00.1234

		$PickupRequest->{ReadyTimestamp} = $datepacked;

		($ResponseCode,$Message,$CustomerTransactionId,$ConfirmationNumber,$Location) = $self->send_pickup_dispatch_reqeust($PickupRequest);
		}

	$self->note_confirmation_number($Shipment,$ConfirmationNumber,$Location) if $ConfirmationNumber;

	$CustomerTransactionId = $PickupRequest->{CustomerTransactionId} unless $CustomerTransactionId;

	$self->log("... ResponseCode   :   " . $ResponseCode . " CustomerTransactionId : " . $CustomerTransactionId);

	$self->SendDispatchNotification('Pickup');
	#$self->SendPickUpNotification($ResponseCode, $Message, $CustomerTransactionId, $ConfirmationNumber);
	}

sub send_same_day_pickup_request
	{
	my $self = shift;
	my $DATA = shift;

	my $PASSWORD = 'yZatPfw3ZNBe7ucOGjKqIzevt';
	my $XML_request = <<END;
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:q0="http://fedex.com/ws/pickup/v6">
  <SOAP-ENV:Body>
    <q0:PickupAvailabilityRequest>
        <q0:WebAuthenticationDetail>
            <q0:UserCredential>
                <q0:Key>I4nV8IlyPI3TkOA8</q0:Key>
                <q0:Password>yZatPfw3ZNBe7ucOGjKqIzevt</q0:Password>
            </q0:UserCredential>
        </q0:WebAuthenticationDetail>
        <q0:ClientDetail>
            <q0:AccountNumber>$DATA->{'webaccount'}</q0:AccountNumber>
            <q0:MeterNumber>$DATA->{'meternumber'}</q0:MeterNumber>
        </q0:ClientDetail>
        <q0:Version>
            <q0:ServiceId>disp</q0:ServiceId>
                <q0:Major>6</q0:Major>
                <q0:Intermediate>0</q0:Intermediate>
                <q0:Minor>0</q0:Minor>
        </q0:Version>
        <q0:AccountNumber>
            <q0:Type>FEDEX_EXPRESS</q0:Type>
        </q0:AccountNumber>
        <q0:PickupAddress>
            <q0:StreetLines>$DATA->{'StreetLines'}</q0:StreetLines>
            <q0:City>$DATA->{'City'}</q0:City>
            <q0:StateOrProvinceCode>$DATA->{'StateOrProvinceCode'}</q0:StateOrProvinceCode>
            <q0:PostalCode>$DATA->{'PostalCode'}</q0:PostalCode>
            <q0:CountryCode>$DATA->{'CountryCode'}</q0:CountryCode>
        <q0:Residential>false</q0:Residential>
        </q0:PickupAddress>
        <q0:PickupRequestType>SAME_DAY</q0:PickupRequestType>
        <q0:DispatchDate>$DATA->{'DispatchDate'}</q0:DispatchDate>
        <q0:NumberOfBusinessDays>1</q0:NumberOfBusinessDays>
        <q0:PackageReadyTime>08:00:00</q0:PackageReadyTime>
        <q0:CustomerCloseTime>18:00:00</q0:CustomerCloseTime>
        <q0:Carriers>FDXE</q0:Carriers>
    </q0:PickupAvailabilityRequest>
 </SOAP-ENV:Body>
</SOAP-ENV:Envelope>
END

	$XML_request =~ s/\n+//g;
	$XML_request =~ s/\s{2}//g;

	$self->log("... SAME DAY Pickup REQUEST: " . $XML_request);

	my $UA = LWP::UserAgent->new;
	my $Response = $UA->post($URL, Content_Type => 'text/xml', Content => $XML_request);

	unless ($Response)
		{
		$self->add_error("FedEx PickupAvailabilityReply: Unable to access FedEx site");
		return undef;
		}

	#$self->log("Response->is_success: " . $Response->is_success);
	unless ($Response->is_success)
		{
		$self->add_error("FedEx.PickupAvailabilityReply. Error: " . $Response->status_line);
		return undef;
		}

	$self->log("FedEx SAME_DAY PickupAvailabilityReply: " . $Response->content);

	my $responseDS = IntelliShip::Utils->parse_XML($Response->content);

	my $NotificationRef = $responseDS->{'soapenv:Envelope'}{'soapenv:Body'}{'v6:PickupAvailabilityReply'}{'v6:Notifications'};

	my ($Message,$ResponseCode) = ("","");

	if (ref $NotificationRef eq 'ARRAY')
		{
		foreach my $msg (@$NotificationRef)
			{
			$Message      = $Message . "<br>" . $msg->{'v6:Message'};
			$ResponseCode = $ResponseCode  . "<br>" . $msg->{'v6:Code'};
			}

		$Message      = $Message . "<br>";
		$ResponseCode = $ResponseCode  . "<br>";
		}
	else
		{
		$Message      = $NotificationRef->{'v6:Message'};
		$ResponseCode = $NotificationRef->{'v6:Code'};
		}

	return ($ResponseCode,$Message);
	}

sub send_pickup_dispatch_reqeust
	{
	my $self = shift;
	my $DATA = shift;

	my $XML_request = $self->get_XML_v6($DATA);

	$XML_request =~ s/\n+//g;
	$XML_request =~ s/\s{2}//g;

	$self->log("... Pickup REQUEST: " . $XML_request);

	my $UA = LWP::UserAgent->new;
	my $Response = $UA->post($URL, Content_Type => 'text/xml', Content => $XML_request);

	unless ($Response)
		{
		$self->add_error("FedEx CreatePickupReply: Unable to access FedEx site");
		return undef;
		}

	#$self->log("Response->is_success: " . $Response->is_success);
	unless ($Response->is_success)
		{
		$self->add_error("FedEx.CreatePickupReply. Error: " . $Response->status_line);
		return undef;
		}

	$self->log("FedEx CreatePickupReply: " . $Response->content);

	my $responseDS = IntelliShip::Utils->parse_XML($Response->content);

	my $NotificationRef = $responseDS->{'soapenv:Envelope'}{'soapenv:Body'}{'v6:CreatePickupReply'}{'v6:Notifications'};

	my ($Message,$ResponseCode) = ("","");

	if (ref $NotificationRef eq 'ARRAY')
		{
		foreach my $msg (@$NotificationRef)
			{
			$Message      = $Message . "<br>" . $msg->{'v6:Message'};
			$ResponseCode = $ResponseCode  . "<br>" . $msg->{'v6:Code'};
			}

		$Message      = $Message . "<br>";
		$ResponseCode = $ResponseCode  . "<br>";
		}
	else
		{
		$Message      = $NotificationRef->{'v6:Message'};
		$ResponseCode = $NotificationRef->{'v6:Code'};
		}

	my $CustomerTransactionId = $responseDS->{'soapenv:Envelope'}{'soapenv:Body'}{'v6:CreatePickupReply'}{'ns1:TransactionDetail'}{'ns1:CustomerTransactionId'}. "<br>";
	my $ConfirmationNumber    = $responseDS->{'soapenv:Envelope'}{'soapenv:Body'}{'v6:CreatePickupReply'}{'v6:PickupConfirmationNumber'}{'content'};
	my $Location    = $responseDS->{'soapenv:Envelope'}{'soapenv:Body'}{'v6:CreatePickupReply'}{'v6:Location'}{'content'};
	return ($ResponseCode,$Message,$CustomerTransactionId,$ConfirmationNumber,$Location);
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

	$self->log("... Pickup REQUEST: " . $XML_request);

	return $XML_request;
	}

__PACKAGE__->meta()->make_immutable();

no Moose;

1;

__END__
