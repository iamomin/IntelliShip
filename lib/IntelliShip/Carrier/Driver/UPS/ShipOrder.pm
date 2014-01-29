package IntelliShip::Carrier::Driver::UPS::ShipOrder;

use Moose;
use Data::Dumper;
use IntelliShip::Utils;
use IntelliShip::DateUtils;

BEGIN { extends 'IntelliShip::Carrier::Driver'; }

sub process_request
	{
	my $self = shift;

	my $CO = $self->CO;
	my $c = $self->context;
	my $Customer = $CO->customer;
	my $shipmentData = $self->data;

	if ($shipmentData->{'addresscountry'} eq 'USA')
		{
		$shipmentData->{'addresscountry'} = 'US';
		}

	if ($shipmentData->{'datetoship'})
		{
		$shipmentData->{'dateshipped'} = $shipmentData->{'datetoship'};
		}
    #
	#if (!defined($shipmentData->{'webaccount'}) or $shipmentData->{'webaccount'} eq '')
	#	{
	#	return (undef,'Missing Account Number');
	#	}
	#if (!defined($shipmentData->{'addresscity'}) or $shipmentData->{'addresscity'} eq '')
	#	{
	#	return (undef,'UPS Local: Unable To Ship Without A Destination City');
	#	}
	#if (!defined($shipmentData->{'addresszip'}) or $shipmentData->{'addresszip'} eq '')
	#	{
	#	return (undef,'UPS Local: Unable To Ship Without A Destination Zip Code');
	#	}
	#if (defined($shipmentData->{'insurance'}) and $shipmentData->{'insurance'} > 1000)
	#	{
	#	return (undef,'UPS Local: Unable To Ship With Declared Value Greater Than $1,000');
	#	}
	#if ($shipmentData->{'addresscountry'} eq 'US')
	#	{
	#	if ((!defined($shipmentData->{'address1'}) or $shipmentData->{'address1'} eq '') and (!defined($shipmentData->{'address2'}) or $shipmentData->{'address2'} eq ''))
	#		{
	#		return (undef,'UPS Local: Unable To Ship Without A Destination Address');
	#		}
	#	elsif (!defined($shipmentData->{'address1'}) or $shipmentData->{'address1'} eq '')
	#		{
	#		$shipmentData->{'address1'} = $shipmentData->{'address2'};
	#		}
	#	elsif ($shipmentData->{'address1'} eq '')
	#		{
	#		return (undef,'UPS Local: Unable To Ship Without A Destination Address');
	#		}
	#	elsif (defined($shipmentData->{'addresszip'}) and $shipmentData->{'addresszip'} !~ /\d{5}(\-\d{4})?/)
	#		{
	#		return (undef,'UPS Local: Invalid Destination Zip Code');
	#		}
	#	}

	my $ServiceCode = $self->service->{'servicecode'};
	if ($ServiceCode == '15')
		{
		if (   !$shipmentData->{'contactname'}
			or !$shipmentData->{'contactphone'}
			or !$shipmentData->{'oacontactname'}
			or !$shipmentData->{'oacontactphone'})
			{
			#return (undef,'UPS Local: Early A.M. Delivery Requires Contact Name & Number for Consignor and Consignee');
			}
		}

	# if (defined($shipmentData->{'dryice'}) and $shipmentData->{'dryice'} eq 'on' and (!defined($shipmentData->{'dryicewt'}) or $shipmentData->{'dryicewt'} eq ''))
		# {
		# return (undef,'UPS Local: Weight of Dry Ice Required for Shipments containing Dry Ice.');
		# }

	# # Push everything through DefaultTo...if undefined, set to ''
	# foreach my $key (keys(%$CgiRef))
		# {
		# $CgiRef->{$key} = DefaultTo($CgiRef->{$key}, '');
		# }

	my $numericaccount;
	if (defined($shipmentData->{'billingaccount'}) and $shipmentData->{'billingaccount'} ne '')
		{
		$shipmentData->{'billingaccount'} = uc($shipmentData->{'billingaccount'});
		$numericaccount = $self->convert_string($shipmentData->{'billingaccount'});
		}
	elsif (defined($shipmentData->{'webaccount'}) and $shipmentData->{'webaccount'} ne '')
		{
		$shipmentData->{'webaccount'} = uc($shipmentData->{'webaccount'});
		$numericaccount = $self->convert_string($shipmentData->{'webaccount'});
		}

	my $numericservice = $self->convert_string($ServiceCode);
	my $referencenumber = '99999';# $self->{'dbref'}->seqnumber('ups_refnum_seq');
	while (length($referencenumber) < 7)
		{
		$referencenumber = "0".$referencenumber;
		}

	my $checkvar = $numericaccount.$numericservice.$referencenumber;
	my ($o1,$e1,$o2,$e2,$o3,$e3,$o4,$e4,$o5,$e5,$o6,$e6,$o7,$e7,$o8) = split("",$checkvar);

	#Create check digit
	my $oddtotal = ($o1 + $o2 + $o3 + $o4 + $o5 + $o6 + $o7 + $o8);
	my $evens = ($e1 + $e2 + $e3 + $e4 + $e5 + $e6 + $e7);
	my $eventotal = $evens * 2;

	my $total = $oddtotal + $eventotal;
	my $a = $total + 9;
	my $b = $a/10;
	$b = int($b);
	my $next = $b * 10;

	my $check_digit = ($next - $total);
	if ($check_digit == 10){ $check_digit = 0; }

	unless ($shipmentData->{'tracking1'})
		{
		if (defined($shipmentData->{'billingaccount'}) and $shipmentData->{'billingaccount'} ne '')
			{
			$shipmentData->{'tracking1'} = "1Z".$shipmentData->{'billingaccount'}.$ServiceCode.$referencenumber.$check_digit;
			}
		elsif (defined($shipmentData->{'webaccount'}) and $shipmentData->{'webaccount'} ne '')
			{
			$shipmentData->{'tracking1'} = "1Z".$shipmentData->{'webaccount'}.$ServiceCode.$referencenumber.$check_digit;
			}
		}
	else
		{
		# this is a manually entered trackingnumber
		$shipmentData->{'manualtrackingflag'} = 1;

		# validate it's length
		if (length($shipmentData->{'tracking1'}) != 11 and length($shipmentData->{'tracking1'}) != 18)
			{
			return (undef,"Invalid UPS Tracking Number (" . $shipmentData->{'tracking1'} . ")");
			}

		# validate the checksum on the manually entered trakcing number
		if (length($shipmentData->{'tracking1'}) == 18 and !$self->validate_check_digit($shipmentData->{'tracking1'}))
			{
			return (undef,"Tracking Number Failed Check Digit Validation (" . $shipmentData->{'tracking1'} . ")");
			}
		}

	$shipmentData->{'weight'} = $shipmentData->{'enteredweight'};

	my $shipmentObj = {
			'department' => $shipmentData->{'department'},
			'coid' => $shipmentData->{'coid'},
			'dateshipped' => $shipmentData->{'dateshipped'},
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
			'shipmentid' => $shipmentData->{'shipmentid'},
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
			'datepacked' => $shipmentData->{'datepacked'},
			'unitquantity' => $shipmentData->{'unitquantity'},
			'ipaddress' => $shipmentData->{'ipaddress'},
			'commodityunitvalue' => $shipmentData->{'commodityunitvalue'}
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

	my @arr1 = $c->model('MyDBI::Address')->search($orignAddress);
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

	my @arr2 = $c->model('MyDBI::Address')->search($destinAddress);
	$shipmentObj->{'addressiddestin'} = $arr2[0]->addressid if @arr2;

	#$c->log->debug('*** shipmentData ***: ' . Dumper $shipmentObj);

	my $Shipment = $c->model('MyDBI::Shipment')->new($shipmentObj);
	$Shipment->insert;

	$c->log->debug('New shipment inserted, ID: ' . $Shipment->shipmentid);

	#$Shipment->{'printerstring'} = $PrinterString;

	return $Shipment;
	}

sub convert_string
	{
	my $self = shift;
	my $string = shift;
	my $converted;

	my %Convert = (
			'A', '2',
			'B', '3',
			'C', '4',
			'D', '5',
			'E', '6',
			'F', '7',
			'G', '8',
			'H', '9',
			'I', '0',
			'J', '1',
			'K', '2',
			'L', '3',
			'M', '4',
			'N', '5',
			'O', '6',
			'P', '7',
			'Q', '8',
			'R', '9',
			'S', '0',
			'T', '1',
			'U', '2',
			'V', '3',
			'W', '4',
			'X', '5',
			'Y', '6',
			'Z', '7',
			'0', '0',
			'1', '1',
			'2', '2',
			'3', '3',
			'4', '4',
			'5', '5',
			'6', '6',
			'7', '7',
			'8', '8',
			'9', '9',
		);

	my @chars = split (//,$string);
	foreach my $char (@chars)
		{
		$converted .= $Convert{$char};
		}
	return $converted;
	}

sub validate_check_digit
	{
	my $self = shift;
	my $trackingnumber = shift;

	my $Account = substr($trackingnumber,2,6);
	my $ServiceCode = substr($trackingnumber,8,2);
	my $Sequence = substr($trackingnumber,10,7);
	my $CheckDigit = substr($trackingnumber,17,1);

	my $numericaccount = $self->convert_string($Account);
	my $numericservice = $self->convert_string($ServiceCode);

	my $checkvar = $numericaccount.$numericservice.$Sequence;
	my ($o1,$e1,$o2,$e2,$o3,$e3,$o4,$e4,$o5,$e5,$o6,$e6,$o7,$e7,$o8) = split("",$checkvar);

	#Create check digit
	my $oddtotal = ($o1 + $o2 + $o3 + $o4 + $o5 + $o6 + $o7 + $o8);
	my $evens = ($e1 + $e2 + $e3 + $e4 + $e5 + $e6 + $e7);
	my $eventotal = $evens * 2;

	my $total = $oddtotal + $eventotal;
	my $a = $total + 9;
	my $b = $a/10;
	$b = int($b);
	my $next = $b * 10;

	my $check_digit = ($next - $total);
	if ($check_digit == 10){ $check_digit = 0; }

	return 1 if ($check_digit == $CheckDigit);
	return 0;
	}

__PACKAGE__->meta()->make_immutable();

no Moose;

1;

__END__