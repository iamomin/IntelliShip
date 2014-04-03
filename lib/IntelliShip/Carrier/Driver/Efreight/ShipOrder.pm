package IntelliShip::Carrier::Driver::Efreight::ShipOrder;

use Moose;
use SOAP::Lite;
use Data::Dumper;
use IntelliShip::Utils;
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
	my $Contact = $CO->contact;

	$self->log("Process eFreight Ship Order");

	$self->log("Shipment Data" .Dumper($shipmentData));

	my $fromzip = $shipmentData->{'branchaddresszip'};
	my $tozip = $shipmentData->{'addresszip'};
	# Zip needs to be 5
	if ( defined($shipmentData->{'branchaddresszip'}) && $shipmentData->{'branchaddresszip'} !~ /^\d{5}$/ )
		{
		$fromzip = substr($shipmentData->{'branchaddresszip'},0,5);
		}

	if ( defined($shipmentData->{'addresszip'}) && $shipmentData->{'addresszip'} !~ /^\d{5}$/ )
		{
		$tozip = substr($shipmentData->{'addresszip'},0,5);
		}

	# my $clientid = $self->{'customer'}->GetCustomerValue('clientid');
	 my $clientid = $Customer->get_contact_data_value('clientid');
	$self->log("clientid ".$clientid);

	my $carrierdetials = $self->API->get_hashref('CARRIER',$shipmentData->{'carrierid'});

	#my $SCAC = &APIRequest({action=>'GetValueHashRef',module=>'CARRIER',moduleid=>$shipmentData->{'carrierid'},field=>'scac'})->{'scac'};

	my $SCAC = $carrierdetials->{'scac'};
	$self->log("SCAC ".$SCAC);
	#my $CarrierName = &APIRequest({action=>'GetValueHashRef',module=>'CARRIER',moduleid=>$shipmentData->{'carrierid'},field=>'carriername'})->{'carriername'};

	my $CarrierName = $carrierdetials->{'carriername'};
	$self->log("CarrierName ".$CarrierName);
	if ( !$shipmentData->{'tracking1'} )
		{
		}
	else
		{
		$shipmentData->{'manualtrackingflag'} = 1;
		}

	my @RequiredAsses = ();
	if ( $shipmentData->{'required_assessorials'} )
		{
		my $ass_names = $shipmentData->{'required_assessorials'};
		my @ass_names = split(/,/,$ass_names);

		foreach my $ass_name ( @ass_names )
			{
			my $AssCode = $self->API->get_assocerial_code($shipmentData->{'customerserviceid'},$ass_name);
			#warn "AssName=$ass_name asscode=$AssCode";
			$self->log(" AssName=$ass_name asscode=$AssCode ");
			my $elem = SOAP::Data->name("Accessorial" => \SOAP::Data->value(
			SOAP::Data->name('Code' => $AssCode)->prefix('fre')
			))->prefix('fre');

			push(@RequiredAsses,$elem);
			}
		}

	# Need to get the weight...CO->GetWeight tries packages, then co.estimatedweight.
	# if neither exist, try falling back to entered weight.

	my $weight = $CO->total_weight;
	if ( !$weight && $CO->estimatedweight )
		{
		$weight = $CO->estimatedweight;
		}
	$shipmentData->{'weight'} = $weight ? $weight : $shipmentData->{'enteredweight'};

	if ( defined($shipmentData->{'datetoship'}) && $shipmentData->{'datetoship'} ne '' )
		{
		$shipmentData->{'dateshipped'} = $shipmentData->{'datetoship'};
		}

	## call webservice
	#warn "GetTransit=>$scac,$oazip,$dazip,$weight,$class,$dateshipped,$required_asses";

	my $licensekey = '6E9A6C1E-C6C2-4170-887E-718A3DDE47F3';
	my $customerkey = defined($clientid) && $clientid ne '' ? $clientid : '31930';
	my $url = 'http://legacy.efsww.com/LTLService/3/LTLWEBService.svc';
	#my $url = 'http://www.efsww.com/LTLService/3/LTLWEBService.svc';
	#my $url = 'http://192.168.55.49:8058/LTLService/9/LTLWEBService.svc';
	#warn "clientid: $customerkey";
	my $dateshipped = $shipmentData->{'dateshipped'};
	$dateshipped =~ s/\///g;

	my $soap = SOAP::Lite
		->on_action( sub {sprintf '%sILTLService/%s', @_} )
		->proxy( $url )
		->encodingStyle('http://xml.apache.org/xml-soap/literalxml')
		->readable(1);

	my $serializer = $soap->serializer();
	$serializer->register_ns('http://schemas.datacontract.org/2004/07/FreightLTL','fre');
	$serializer->register_ns('http://tempuri.org/','tem');

	my $method = SOAP::Data->name('BookOrder')->prefix('tem');

	my $input = SOAP::Data->name("request" => \SOAP::Data->value(
		SOAP::Data->name("Authentication" => \SOAP::Data->value(
			SOAP::Data->name('LicenseKey' => $licensekey)->prefix('fre')
			))->prefix('fre'),
		SOAP::Data->name("Customer" => \SOAP::Data->value(
			SOAP::Data->name('CustomerKey' => $customerkey)->prefix('fre')
			))->prefix('fre'),
		SOAP::Data->name("POnumber" => SOAP::Data->value("$shipmentData->{'ponumber'}"))->prefix('fre'),
		SOAP::Data->name("ShipperReferenceNumber" => SOAP::Data->value("$shipmentData->{'ordernumber'}"))->prefix('fre'),
		SOAP::Data->name("SCAC" => SOAP::Data->value($SCAC))->prefix('fre'),
		SOAP::Data->name("SelectedQuote" => \SOAP::Data->value(
			SOAP::Data->name('CarrierSCAC' => $SCAC)->prefix('fre'),
			SOAP::Data->name('CarrierName' => "$CarrierName")->prefix('fre'),
			SOAP::Data->name('TariffDescription' => "")->prefix('fre'),
			SOAP::Data->name('ServiceLevel' => "1")->prefix('fre'),
			SOAP::Data->name('OriginServiceType' => "")->prefix('fre'),
			SOAP::Data->name('DestinationServiceType' => "")->prefix('fre'),
			SOAP::Data->name('PriceLineHaul' => "0")->prefix('fre'),
			SOAP::Data->name('AmountLineHaulDiscount' => "0")->prefix('fre'),
			SOAP::Data->name('PriceFuelSurcharge' => "0")->prefix('fre'),
			SOAP::Data->name('PercentFuelSurcharge' => "0")->prefix('fre'),
			SOAP::Data->name("Accessorials" => \SOAP::Data->value( @RequiredAsses ))->prefix('fre'),
			SOAP::Data->name('PriceTotal' => "0")->prefix('fre'),
			SOAP::Data->name('ErrorMessage' => "")->prefix('fre'),
			 ))->prefix('fre'),
		SOAP::Data->name("PickupInformation" => \SOAP::Data->value(
			SOAP::Data->name("Address" => \SOAP::Data->value(
				SOAP::Data->name('CompanyName' => "$shipmentData->{'customername'}")->prefix('fre'),
				SOAP::Data->name('Address1' => "$shipmentData->{'branchaddress1'}")->prefix('fre'),
				SOAP::Data->name('Address2' => "$shipmentData->{'branchaddress2'}")->prefix('fre'),
				SOAP::Data->name('City' => "$shipmentData->{'branchaddresscity'}")->prefix('fre'),
				SOAP::Data->name('State' => "$shipmentData->{'branchaddressstate'}")->prefix('fre'),
				SOAP::Data->name('ZipCode' => "$fromzip")->prefix('fre'),
				SOAP::Data->name('CountryCode' => "$shipmentData->{'branchaddresscountry'}")->prefix('fre'),
				SOAP::Data->name('Phone' => "")->prefix('fre'),
				SOAP::Data->name('Email' => "")->prefix('fre'),
				))->prefix('fre'),
			SOAP::Data->name("SecondAddress" => \SOAP::Data->value(
				SOAP::Data->name('CompanyName' => "")->prefix('fre'),
				SOAP::Data->name('Address1' => "")->prefix('fre'),
				SOAP::Data->name('Address2' => "")->prefix('fre'),
				SOAP::Data->name('City' => "")->prefix('fre'),
				SOAP::Data->name('State' => "")->prefix('fre'),
				SOAP::Data->name('ZipCode' => "")->prefix('fre'),
				SOAP::Data->name('CountryCode' => "")->prefix('fre'),
				SOAP::Data->name('Phone' => "")->prefix('fre'),
				SOAP::Data->name('Email' => "")->prefix('fre')
				))->prefix('fre'),
			SOAP::Data->name("Contact" => \SOAP::Data->value(
				SOAP::Data->name('FirstName' => "")->prefix('fre'),
				SOAP::Data->name('LastName' => "")->prefix('fre'),
				SOAP::Data->name('Email' => "")->prefix('fre'),
				SOAP::Data->name('Phone1' => "")->prefix('fre'),
				SOAP::Data->name('Phone2' => "")->prefix('fre')
				))->prefix('fre'),
			SOAP::Data->name("RequestedServiceDateTime" => SOAP::Data->value($dateshipped))->prefix('fre')
		))->prefix('fre'),
		SOAP::Data->name("DeliveryInformation" => \SOAP::Data->value(
			SOAP::Data->name("Address" => \SOAP::Data->value(
				SOAP::Data->name('CompanyName' => "$shipmentData->{'addressname'}")->prefix('fre'),
				SOAP::Data->name('Address1' => "$shipmentData->{'address1'}")->prefix('fre'),
				SOAP::Data->name('Address2' => "$shipmentData->{'address2'}")->prefix('fre'),
				SOAP::Data->name('City' => "$shipmentData->{'addresscity'}")->prefix('fre'),
				SOAP::Data->name('State' => "$shipmentData->{'addressstate'}")->prefix('fre'),
				SOAP::Data->name('ZipCode' => "$tozip")->prefix('fre'),
				SOAP::Data->name('CountryCode' => "$shipmentData->{'addresscountry'}")->prefix('fre'),
				SOAP::Data->name('Phone' => "")->prefix('fre'),
				SOAP::Data->name('Email' => "")->prefix('fre')
				))->prefix('fre'),
			SOAP::Data->name("SecondAddress" => \SOAP::Data->value(
				SOAP::Data->name('CompanyName' => "")->prefix('fre'),
				SOAP::Data->name('Address1' => "")->prefix('fre'),
				SOAP::Data->name('Address2' => "")->prefix('fre'),
				SOAP::Data->name('City' => "")->prefix('fre'),
				SOAP::Data->name('State' => "")->prefix('fre'),
				SOAP::Data->name('ZipCode' => "")->prefix('fre'),
				SOAP::Data->name('CountryCode' => "")->prefix('fre'),
				SOAP::Data->name('Phone' => "")->prefix('fre'),
				SOAP::Data->name('Email' => "")->prefix('fre')
				))->prefix('fre'),
			SOAP::Data->name("Contact" => \SOAP::Data->value(
				SOAP::Data->name('FirstName' => "")->prefix('fre'),
				SOAP::Data->name('LastName' => "")->prefix('fre'),
				SOAP::Data->name('Email' => "")->prefix('fre'),
				SOAP::Data->name('Phone1' => "")->prefix('fre'),
				SOAP::Data->name('Phone2' => "")->prefix('fre')
				))->prefix('fre')
			))->prefix('fre'),
		 SOAP::Data->name("ItemsToShip" => \SOAP::Data->value(
			SOAP::Data->name("QuoteListRequestItemToShip" => \SOAP::Data->value(
				SOAP::Data->name('Width' => '0')->prefix('fre'),
				SOAP::Data->name('Height' => '0')->prefix('fre'),
				SOAP::Data->name('Length' => '0')->prefix('fre'),
				SOAP::Data->name('Weight' => "$shipmentData->{'weight'}")->prefix('fre')->type('float'),
				SOAP::Data->name('FreightClass' => "$shipmentData->{'class_1'}")->prefix('fre'),
				SOAP::Data->name('HazardousMaterial' => '0')->prefix('fre'),
				SOAP::Data->name('Quantity' => '1')->prefix('fre'),
				SOAP::Data->name('Description' => 'Parts')->prefix('fre'),
				SOAP::Data->name('Marks' => 'H8R7383')->prefix('fre'),
				SOAP::Data->name('NMFC' => 'TB2433')->prefix('fre'),
				SOAP::Data->name('SKU' => '901LP101')->prefix('fre'),
				SOAP::Data->name('Packaging' => 'Pallet')->prefix('fre')->type(''),
				SOAP::Data->name('QuantityHandlingUnits' => '1')->prefix('fre')
				))->prefix('fre')
			))->prefix('fre'),
		))->prefix('tem');

	my @params = ($input);

	#$self->log(" Request   = ".Dumper $input);

	my $som = $soap->call($method => @params);

	if ( $som->fault )
		{
		#warn "EFREIGHT GetTransit faultstring=" . $som->fault->{'faultstring'} . "\n";
		$self->add_error("EFREIGHT GetTransit faultstring= ".$som->fault->{'faultstring'} );
		$self->log("EFREIGHT GetTransit faultstring= ".$som->fault->{'faultstring'} );
		return 0;
		}
	else
		{
		my %keyHash = %{ $som->body->{'BookOrderResponse'}->{'BookOrderResult'} };
		$self->log(" Response  = ".Dumper %keyHash);
		foreach my $k (keys %keyHash)
			{
			if ( $k eq 'OrderID' && defined($keyHash{$k}) && $keyHash{$k} ne '' )
				{
				$shipmentData->{'tracking1'} = $keyHash{$k};
				$self->log(" Tracking number = ".$shipmentData->{'tracking1'});
				}
			elsif ( $k =~ /errormessage/i && defined($keyHash{$k}) && $keyHash{$k} ne '' )
				{
				$shipmentData->{'action'} = 'error';
				$shipmentData->{'errorstring'} = $keyHash{$k};
				#warn "efreight ERROR: $k=$keyHash{$k}\n";
				$self->log(" efreight ERROR: $k=$keyHash{$k}\n");
				}
			}
		}

	IntelliShip::Utils->generate_UCC_128_barcode($shipmentData->{'tracking1'});

	## Create Shipment Record
	my $Shipment = $self->insert_shipment($shipmentData);

	#$Shipment->{'action'} = $CgiRef->{'errorstring'};
	#$Shipment->{'errorstring'} = $shipmentData->{'errorstring'};

	# Note user supplied tracking numbers
	if ( defined($shipmentData->{'manualtrackingflag'}) && $shipmentData->{'manualtrackingflag'} == 1 )
		{
		# Add note to notes table
		my $Notes = new NOTES($self->{'dbref'},$self->{'customer'});
		my $noteData = {};

		$noteData->{'ownerid'} = $Shipment->shipmentid;
		$noteData->{'note'} = $shipmentData->{'tracking1'} . ' Input By ' . $Contact->username;
		$noteData->{'contactid'} = $Contact;
		$noteData->{'notestypeid'} = 1300;
		$noteData->{'datehappened'} = $self->{'dbref'}->gettimestamp();
		my $Note = IntelliShip::DateUtils->get_timestamp_with_time_zone();
		$Note->insert;
		}

	my $PrinterString = $self->BuildPrinterString($shipmentData);
	$self->response->printer_string($PrinterString);
	}

__PACKAGE__->meta()->make_immutable();

no Moose;

1;

__END__