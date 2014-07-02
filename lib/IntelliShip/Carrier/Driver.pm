package IntelliShip::Carrier::Driver;

use Moose;
use ARRS::IDBI;
use Data::Dumper;
use IntelliShip::Utils;
use IntelliShip::MyConfig;
use IntelliShip::DateUtils;
use IntelliShip::Arrs::API;
use IntelliShip::Carrier::EPLTemplates;
BEGIN {

	extends 'IntelliShip::Errors';

	has 'API'                 => ( is => 'rw' );
	has 'CO'                  => ( is => 'rw' );
	has 'SHIPMENT'            => ( is => 'rw' );
	has 'context'             => ( is => 'rw' );
	has 'carrier'             => ( is => 'rw' );
	has 'contact'             => ( is => 'rw' );
	has 'MYDBI_ref'           => ( is => 'rw' );
	has 'DB_ref'              => ( is => 'rw' );
	has 'data'                => ( is => 'rw' );
	has 'customerservice'     => ( is => 'rw' );
	has 'service'             => ( is => 'rw' );
	has 'response'            => ( is => 'rw' );
	has 'destination_address' => ( is => 'rw' );

	$Data::Dumper::Sortkeys = 1;
	}

sub model
	{
	my $self = shift;
	my $model = shift;

	if ($self->context)
		{
		return $self->context->model($model);
		}
	}

sub myDBI
	{
	my $self = shift;
	$self->MYDBI_ref($self->model('MyDBI')) unless $self->MYDBI_ref;
	return $self->MYDBI_ref if $self->MYDBI_ref;
	}

sub DBI
	{
	my $self = shift;
	my $dbname = shift;
	my $DB_REF = $self->DB_ref || {};
	$self->DB_ref($DB_REF) unless $self->DB_ref;
	$DB_REF->{$dbname} = ARRS::IDBI->connect({ dbname => $dbname }) unless $DB_REF->{$dbname};
	return $DB_REF->{$dbname};
	}

sub get_token_id
	{
	my $self = shift;
	return $self->context->controller->get_token_id;
	}

sub process_request
	{
	my $self = shift;
	}

sub void_shipment
	{
	my $self = shift;

	$self->log("SET SHIPMENT STATUS TO VOID");

	my $Shipment = $self->SHIPMENT;
	my $CO = $Shipment->CO;

	$Shipment->statusid(7); ## Void Shipment complete
	$Shipment->update;

	## Delete any associated orders
	$Shipment->shipmentcoassocs->delete;

	#$CO->delete_all_package_details;

	## Set CO to 'unshipped' status
	## Flush carrier and service details
	$CO->statusid(1);
	$CO->reset;
	$CO->update;
	}

my $EPL_TEMPLATES = {
	USPSF		=> 'get_USPS_EPL_1',
	USTPO		=> 'get_USPS_EPL_2',
	UPRIORITY	=> 'get_USPS_EPL_3',
	USPSMM		=> 'get_USPS_EPL_4',
	USPSLM		=> 'get_USPS_EPL_5',
	UPME		=> 'get_USPS_EPL_6',
	USPSPMFRE	=> 'get_USPS_EPL_3',
	USPSPMPFRE	=> 'get_USPS_EPL_3',
	USPSPMSFRB	=> 'get_USPS_EPL_3',
	USPSPMMFRB	=> 'get_USPS_EPL_3',
	USPSPMLFRB	=> 'get_USPS_EPL_3',
	USPSPMEFRE	=> 'get_USPS_EPL_6',
	USPSPMEPFRE	=> 'get_USPS_EPL_6',
	USPSPMEFRB	=> 'get_USPS_EPL_6',
	};

sub get_EPL
	{
	my $self = shift;
	my $DATA = shift;

	my $carrier = $self->carrier;
	return unless $carrier;

	my $method = $EPL_TEMPLATES->{$DATA->{'servicecode'}};
	$method = 'get_' . uc($carrier) . '_EPL' unless $method;

	#$self->log("... $method, DATA: " . Dumper $DATA);

	my $EPL = '';
	#eval {
		$EPL = IntelliShip::Carrier::EPLTemplates->$method($DATA);
	#};

	#if ($@)
	#	{
	#	$self->log("EPLTemplates: $method Errors : " . $!);
	#	}

	return $EPL;
	}

sub get_BOL_EPL
	{
	my $self = shift;
	my $DATA = shift;

	my $BOL_string = '';
	if ($self->contact->get_contact_data_value('printthermalbol'))
		{
		my $bolcountthermal = $self->contact->get_contact_data_value('bolcountthermal') || 1;
		my $EPL = IntelliShip::Carrier::EPLTemplates->get_BOL_EPL($DATA);
		$BOL_string = $EPL x $bolcountthermal;
		}

	return $BOL_string;
	}

sub TagPrinterString
	{
	my $self = shift;
	my $string = shift;

	# Check for order stream, and add it to main stream, if it exists
	my $CO = $self->CO;

	my @string_lines = split("\n",$string);

	my $Stream = $CO->stream;
	if ($Stream)
		{
		push(@string_lines,split(/\~/,$Stream));
		}

	my $tagged_string = ".\n";
	foreach my $line (@string_lines)
		{
		# Need to reverse print direction of local labels
		if ( $line eq 'ZT' )
			{
			$line = 'ZB';
			}
		if ( $line =~ /Svcs/ || $line =~ /TRCK/ || $line =~ /CLS/ )
			{
			next;
			}
		if ($CO->extcarrier =~ /FedEx/i and $line eq 'ZB' )
			{
			$line .= "\nLO0,3,800,2\nLO0,3,2,1150\nLO800,3,2,1150\nLO0,1150,800,2\n" if $CO->extservice =~ /Ground/i;
			$line .= "\nLO0,3,810,2\nLO0,3,2,1200\nLO810,3,2,1200\nLO0,1200,810,2\n" if $CO->extservice =~ /(Express|Day|Overnight)/i;
			}

		$tagged_string .= "$line\n";
		}

	$tagged_string .= "R0,0\n";
	$tagged_string .= ".\n\n";

	return $tagged_string;
	}

sub insert_shipment
	{
	my $self = shift;
	my $shipmentData = shift;

	return unless $shipmentData;

	#$self->log("... shipmentData: " . Dumper $shipmentData);

	my $date_shipped = IntelliShip::DateUtils->get_db_format_date_time_with_timezone($shipmentData->{'datetoship'});
	my $date_packed = IntelliShip::DateUtils->get_db_format_date_time_with_timezone($shipmentData->{'datepacked'});

	my $shipmentObj = {
			'shipmentid' => $shipmentData->{'new_shipmentid'},

			'department' => $shipmentData->{'department'},
			'customerserviceid' => $shipmentData->{'customerserviceid'},
			'coid' => $shipmentData->{'coid'},
			'dateshipped' => $date_shipped,
			'quantityxweight' => $shipmentData->{'quantityxweight'},
			'freightinsurance' => $shipmentData->{'freightinsurance'},
			'hazardous' => $shipmentData->{'hazardous'},
			'deliverynotification' => $shipmentData->{'deliverynotification'},
			'custnum' => $shipmentData->{'custnum'},
			'oacontactphone' => $shipmentData->{'oacontactphone'},
			'securitytype' => $shipmentData->{'securitytype'},
			'description' => $shipmentData->{'description'},
			'shipasname' => $shipmentData->{'shipasname'},
			'density' => $shipmentData->{'density'},
			'destinationcountry' => $shipmentData->{'destinationcountry'},
			'partiestotransaction' => $shipmentData->{'partiestotransaction'},
			'defaultcsid' => $shipmentData->{'defaultcsid'},
			'ponumber' => $shipmentData->{'ponumber'},
			'dimweight' => $shipmentData->{'dimweight'},
			'dimlength' => $shipmentData->{'dimlength'},
			'dimheight' => $shipmentData->{'dimheight'},
			'naftaflag' => $shipmentData->{'naftaflag'},
			'carrier' => $shipmentData->{'carrier'},
			'dimwidth' => $shipmentData->{'dimwidth'},
			'commodityunits' => $shipmentData->{'commodityunits'},
			'manualthirdparty' => $shipmentData->{'manualthirdparty'},
			'contactphone' => $shipmentData->{'contactphone'},
			'customsvalue' => $shipmentData->{'customsvalue'},
			'contactname' => $shipmentData->{'contactname'},
			'customsdescription' => $shipmentData->{'customsdescription'},
			'billingaccount' => $shipmentData->{'billingaccount'},
			'commodityweight' => $shipmentData->{'commodityweight'},
			'dutyaccount' => $shipmentData->{'dutyaccount'},
			'manufacturecountry' => $shipmentData->{'manufacturecountry'},
			'contacttitle' => $shipmentData->{'contacttitle'},
			'shipmentnotification' => $shipmentData->{'shipmentnotification'},
			'originid' => $shipmentData->{'originid'},
			'bookingnumber' => $shipmentData->{'bookingnumber'},
			'custref3' => $shipmentData->{'custref3'},
			'dutypaytype' => $shipmentData->{'dutypaytype'},
			'extid' => $shipmentData->{'extid'},
			'datereceived' => $shipmentData->{'datereceived'},
			'weight' => $shipmentData->{'weight'},
			'billingpostalcode' => $shipmentData->{'billingpostalcode'},
			'insurance' => $shipmentData->{'insurance'},
			'currencytype' => $shipmentData->{'currencytype'},
			'service' => $shipmentData->{'service'},
			'isdropship' => $shipmentData->{'isdropship'},
			'ssnein' => $shipmentData->{'ssnein'},
			'harmonizedcode' => $shipmentData->{'harmonizedcode'},
			'tracking1' => $shipmentData->{'tracking1'},
			'isinbound' => $shipmentData->{'isinbound'},
			'oacontactname' => $shipmentData->{'oacontactname'},
			'daterouted' => $shipmentData->{'daterouted'},
			'quantity' => $shipmentData->{'quantity'},
			'commodityquantity' => $shipmentData->{'commodityquantity'},
			'dimunits' => $shipmentData->{'dimunits'},
			'freightcharges' => $shipmentData->{'freightcharges'},
			'termsofsale' => $shipmentData->{'termsofsale'},
			'commoditycustomsvalue' => $shipmentData->{'commoditycustomsvalue'},
			'datepacked' => $date_packed,
			'unitquantity' => $shipmentData->{'unitquantity'},
			'ipaddress' => $shipmentData->{'ipaddress'},
			'commodityunitvalue' => $shipmentData->{'commodityunitvalue'},
			'contactid' =>	$shipmentData->{'contactid'},
		};

	my $orignAddress = {
			addressname	=> $shipmentData->{'customername'},
			address1	=> $shipmentData->{'branchaddress1'},
			address2	=> $shipmentData->{'branchaddress2'},
			city		=> $shipmentData->{'branchaddresscity'},
			state		=> $shipmentData->{'branchaddressstate'},
			zip			=> $shipmentData->{'branchaddresszip'},
			country		=> $shipmentData->{'branchaddresscountry'},
			};

	my @arr1 = $self->model('MyDBI::Address')->search($orignAddress);
	$shipmentObj->{'addressidorigin'} = $arr1[0]->addressid if @arr1;

	my $destinAddress = {
			addressname	=> $shipmentData->{'addressname'},
			address1	=> $shipmentData->{'address1'},
			address2	=> $shipmentData->{'address2'},
			city		=> $shipmentData->{'addresscity'},
			state		=> $shipmentData->{'addressstate'},
			zip			=> $shipmentData->{'addresszip'},
			country		=> $shipmentData->{'addresscountry'},
			};

	my @arr2 = $self->model('MyDBI::Address')->search($destinAddress);
	$shipmentObj->{'addressiddestin'} = $arr2[0]->addressid if @arr2;

	#$self->log('*** shipmentData ***: ' . Dumper $shipmentObj);

	my $Shipment = $self->model('MyDBI::Shipment')->new($shipmentObj);
	$Shipment->insert;

	$self->log('New shipment inserted, ID: ' . $Shipment->shipmentid);

	$shipmentData->{'shipmentid'} = $Shipment->shipmentid;

	$self->response->shipment($Shipment);

	return $Shipment;
	}

sub SendPickUpNotification
	{
	my $self = shift;
	my $ResponseCode = shift;
	my $Message = shift;
	my $CustomerTransactionId = shift;
	my $ConfirmationNumber = shift;
	my $c = $self->context;

	my $Shipment = $self->SHIPMENT;

	my $subject;
	if($ResponseCode eq '0000')
		{
		$subject = "NOTICE: Driver Dispatched (" . $self->carrier .",". IntelliShip::DateUtils->american_date($Shipment->datepacked).")";
		}
	else
		{
		$subject = "ALERT: Error scheduling driver pickup on ". IntelliShip::DateUtils->american_date($Shipment->datepacked);
		}

	my $Email = IntelliShip::Email->new;

	$Email->content_type('text/html');
	$Email->from_address(IntelliShip::MyConfig->no_reply_email);
	$Email->from_name('IntelliShip2');
	$Email->subject($subject);
	$Email->add_to('noc@engagetechnology.com');
	$Email->add_to('imranm@alohatechnology.com') if IntelliShip::MyConfig->getDomain eq 'DEVELOPMENT';

	my $CO = $self->CO;
	my $Customer = $CO->customer;

	my $company_logo = $Customer->username . '-light-logo.png';
	my $fullpath = IntelliShip::MyConfig->branding_file_directory . '/' . IntelliShip::Utils->get_branding_id . '/images/header/' . $company_logo;
	$company_logo = 'engage-light-logo.png' unless -e $fullpath;
	$c->stash->{logo} = $company_logo;

	$c->stash->{Shipment_list} = $Shipment;

	$c->stash->{Message} = $Message;
	$c->stash->{ResponseCode} = $ResponseCode;
	$c->stash->{CustomerTransactionId} = $CustomerTransactionId if $CustomerTransactionId;
	$c->stash->{ConfirmationNumber} = $ConfirmationNumber if $ConfirmationNumber;

	$Email->body($Email->body . $c->forward($c->view('Email'), "render", [ 'templates/email/pickup-notification.tt' ]));

	if ($Email->send)
		{
		$self->context->log->debug("Shipment Pick-Up notification email successfully sent to " . join(',',@{$Email->to}));
		}
	}

sub SendDispatchNotification
	{
	my $self = shift;
	my $Type = shift;

	my $c = $self->context;
	my $CO = $self->CO;
	my $Shipment = $self->SHIPMENT;
	my $Customer = $CO->customer;

	my $CustomerService = IntelliShip::Arrs::API->get_hashref('CUSTOMERSERVICE',$Shipment->customerserviceid);
	my $Service = $self->service;
	my $shipmentData = $self->data;
	my ($notetypeid,$PickupRequest,$PickupRequestEmail,$subject);
	
	$PickupRequest = IntelliShip::Arrs::API->get_CS_value($Shipment->customerserviceid,'pickuprequest',$Customer->customerid);
	$PickupRequestEmail = ($CustomerService->{'carrieremail'}? $CustomerService->{'carrieremail'} : '');

	if(($PickupRequestEmail ) &&
		(
			( $PickupRequest == 1 || $PickupRequest == 2 || $PickupRequest == 7 ) ||
			( ( $PickupRequest == 5 || $PickupRequest == 6 || $PickupRequest == 9 ) && $Type eq 'Cancellation' )
		))
	{
	my $Note = $c->model('MyDBI::Note')->find({ ownerid => $Shipment->shipmentid, note => { like => 'Pick-Up Location%' } });

	if ( $Type eq 'Cancellation' )
		{
		$notetypeid ='1600';
		$subject = "ALERT:  Shipment Dispatched " .$Type ."(".$Customer->customername .",". $Shipment->service ."Pickup on ".IntelliShip::DateUtils->current_date .")";
		$c->stash->{type} = 'CANCEL';
		}
	else
		{
		$notetypeid = '1500';
		$subject = "ALERT:  Shipment Dispatched (". $Customer->customername .",". $Shipment->service ."Pickup on ".IntelliShip::DateUtils->current_date .")";
		}

	my $noteData = {
		'ownerid'      => $Shipment->shipmentid,
		'note'         => $Type,
		'contactid'    => $Shipment->contactid,
		'notestypeid'  => $notetypeid,
		'datecreated'  => IntelliShip::DateUtils->get_timestamp_with_time_zone,
		'datehappened' => $Shipment->datepacked,
		};

	my $Notes = $self->model('MyDBI::Note')->new($noteData);
	$Notes->notesid($self->get_token_id);
	$Notes->insert;

	my $Email = IntelliShip::Email->new;

	$Email->content_type('text/html');
	$Email->from_address(IntelliShip::MyConfig->no_reply_email);
	$Email->from_name('IntelliShip2');

	$Email->subject($subject);
	$Email->add_to('noc@engagetechnology.com');
	$Email->add_to('imranm@alohatechnology.com') if IntelliShip::MyConfig->getDomain eq 'DEVELOPMENT';

	$c->stash->{dispatchtitle} = "Dispatch " . $Type;
	if (my $OAAddress = $Shipment->origin_address)
		{
		my $shipper_address = $OAAddress->addressname;
		$shipper_address   .= "<br>" . $OAAddress->address1 if $OAAddress->address1;
		$shipper_address   .= " " . $OAAddress->address2    if $OAAddress->address2;
		$shipper_address   .= "<br>" . $OAAddress->city     if $OAAddress->city;
		$shipper_address   .= ", " . $OAAddress->state      if $OAAddress->state;
		$shipper_address   .= "  " . $OAAddress->zip        if $OAAddress->zip;
		$shipper_address   .= "<br>" . $OAAddress->country  if $OAAddress->country;

		$c->stash->{'fullfrom'} = $shipper_address;
		}

	$c->stash->{branchcontact} =$Shipment->oacontactname;
	$c->stash->{branchphone} = $Shipment->oacontactphone;
	$c->stash->{refnumber} = $CO->ordernumber;
	$c->stash->{shipdate} =$Shipment->dateshipped;
	$c->stash->{branchairportcode} ='';

	if (my $DAAddress = $Shipment->destination_address)
		{
		my $destination_address = $DAAddress->addressname;
		$destination_address   .= "<br>" . $DAAddress->address1 if $DAAddress->address1;
		$destination_address   .= " " . $DAAddress->address2    if $DAAddress->address2;
		$destination_address   .= "<br>" . $DAAddress->city     if $DAAddress->city;
		$destination_address   .= ", " . $DAAddress->state      if $DAAddress->state;
		$destination_address   .= "  " . $DAAddress->zip        if $DAAddress->zip;
		$destination_address   .= "<br>" . $DAAddress->country  if $DAAddress->country;
		$c->stash->{fullto} = $destination_address;
		}

	$c->stash->{contactname} =	$CO->contactname;
	$c->stash->{contactphone} =	$CO->contactphone;
	$c->stash->{ponumber} =	 $Shipment->ponumber;
	$c->stash->{etadate} =	$Shipment->datedelivered;
	$c->stash->{airportcode} = '';

	if ($shipmentData->{'billingaddress1'})
		{
		my $billingaddress = $shipmentData->{'billingname'};
		$billingaddress   .= "<br>" . $shipmentData->{'billingaddress1'} if $shipmentData->{'billingaddress1'};
		$billingaddress   .= " " . $shipmentData->{'billingaddress2'}    if $shipmentData->{'billingaddress2'};
		$billingaddress   .= "<br>" . $shipmentData->{'billingcity'}     if $shipmentData->{'billingcity'};
		$billingaddress   .= ", " . $shipmentData->{'billingstate'}      if $shipmentData->{'billingstate'};
		$billingaddress   .= "  " . $shipmentData->{'billingzip'}        if $shipmentData->{'billingzip'};
		$billingaddress   .= "<br>" . $shipmentData->{'billingcountry'}  if $shipmentData->{'billingcountry'};

		$c->stash->{fullbilling} = $billingaddress;

		$c->stash->{'addressname'}   .= " ($shipmentData->{'billingaccount'})" if $shipmentData->{'billingaccount'};
		}

	$c->stash->{pickupweight} 	 	= $Shipment->weight;
	$c->stash->{pickupdimweight} 	= $Shipment->dimweight;
	$c->stash->{dims}            	= $Shipment->dimlength . "x" . $Shipment->dimwidth . "x" . $Shipment->dimheight;;
	$c->stash->{density}         	= $Shipment->density;
	$c->stash->{totalquantity}   	= $Shipment->total_quantity;
	$c->stash->{zonenumber}      	= $Shipment->zonenumber;
	$c->stash->{tracking1}       	= $Shipment->tracking1;
	$c->stash->{customsdescription} = $Shipment->customsdescription;
	$c->stash->{description}     	= $CO->description;
	$c->stash->{carrier}	     	= $Shipment->carrier;
	$c->stash->{service} 			= $Shipment->service;

	my $barcode_image = IntelliShip::Utils->generate_UCC_128_barcode($Shipment->tracking1);
	$c->stash->{barcode} = 'http://dintelliship2.engagetechnology.com/print/barcode/'. $Shipment->tracking1 . '.png' if -e $barcode_image;

	$c->stash->{labelbanner} = 'Freight Charge';
	$c->stash->{commentstring} = 'Fuel Surcharge';

	$Email->body($Email->body . $c->forward($c->view('Email'), "render", [ 'templates/email/pickup-notification-1.tt' ]));

	if ($Email->send)
		{
		$self->context->log->debug("Shipment Pick-Up notification email successfully sent to " . join(',',@{$Email->to}));
		}
	}
}
sub SendCancelPickupNotification
	{
	my $self = shift;
	my $ResponseCode = shift;
	my $Message = shift;
	my $ConfirmationNumber = shift;

	my $c = $self->context;

	my $Shipment = $self->SHIPMENT;

	my $subject;
	if($ResponseCode eq '0000')
		{
		$subject = "NOTICE: Pickup Cancelled (" . $self->carrier .",". IntelliShip::DateUtils->american_date($Shipment->datepacked).")";
		}
	else
		{
		$subject = "ALERT: Error cancel driver pickup on ". IntelliShip::DateUtils->american_date($Shipment->datepacked);
		}

	my $Email = IntelliShip::Email->new;

	$Email->content_type('text/html');
	$Email->from_address(IntelliShip::MyConfig->no_reply_email);
	$Email->from_name('IntelliShip2');
	$Email->subject($subject);
	$Email->add_to('noc@engagetechnology.com');
	$Email->add_to('imranm@alohatechnology.com') if IntelliShip::MyConfig->getDomain eq 'DEVELOPMENT';

	my $CO = $self->CO;
	my $Customer = $CO->customer;

	my $company_logo = $Customer->username . '-light-logo.png';
	my $fullpath = IntelliShip::MyConfig->branding_file_directory . '/' . IntelliShip::Utils->get_branding_id . '/images/header/' . $company_logo;
	$company_logo = 'engage-light-logo.png' unless -e $fullpath;
	$c->stash->{logo} = $company_logo;

	$c->stash->{Shipment_list} = $Shipment;

	$c->stash->{Message} = $Message;
	$c->stash->{ResponseCode} = $ResponseCode;
	$c->stash->{ConfirmationNumber} = $ConfirmationNumber if $ConfirmationNumber;

	$Email->body($Email->body . $c->forward($c->view('Email'), "render", [ 'templates/email/cancel-pickup-notification.tt' ]));

	if ($Email->send)
		{
		$self->context->log->debug("Shipment Pick-Up-Cancel notification email successfully sent to " . join(',',@{$Email->to}));
		}
	}

sub note_confirmation_number
	{
	my $self = shift;
	my $Shipment = shift;
	my $ConfirmationNumber = shift;
	my $location = shift;

	my $noteData = {
		'ownerid'      => $Shipment->shipmentid,
		'note'         => 'Pick-Up Location: ' . $location . ' ConfirmationNumber: ' . $ConfirmationNumber,
		'contactid'    => $Shipment->contactid,
		'notestypeid'  => '1000',
		'datecreated'  => IntelliShip::DateUtils->get_timestamp_with_time_zone,
		'datehappened' => $Shipment->datepacked,
		};

	my $Notes = $self->model('MyDBI::Note')->new($noteData);
	$Notes->notesid($self->get_token_id);
	$Notes->insert;
	}

sub log
	{
	my $self = shift;
	my $msg = shift;
	if ($self->context)
		{
		$self->context->log->debug($msg);
		}
	else
		{
		print STDERR "\n" . $msg;
		}
	}

__PACKAGE__->meta()->make_immutable();

no Moose;

1;

__END__