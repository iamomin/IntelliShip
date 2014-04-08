package IntelliShip::Carrier::Driver::FedEx::ShipOrder;

use Moose;
use Net::Telnet;
use Data::Dumper;
use POSIX qw(ceil);
use IntelliShip::Utils;
use IntelliShip::DateUtils;

BEGIN { extends 'IntelliShip::Carrier::Driver'; }

sub process_request
	{
	my $self = shift;

	my $CO = $self->CO;
	my $Customer = $CO->customer;
	my $shipmentData = $self->data;

	$self->log("Process FedEx Ship Order");

	###############################
	# The incoming variables
	###############################
	$shipmentData->{'carrier'} = 'Fedex';

	if ($shipmentData->{'addresscountry'} eq 'USA')
		{
		$shipmentData->{'addresscountry'} = 'US';
		}

	$shipmentData->{'commodityweight'} = $shipmentData->{'enteredweight'};
	$shipmentData->{'dateshipped'} = $shipmentData->{'datetoship'};

	if ( $shipmentData->{'enteredweight'} !~ /\.\d+/ ) { $shipmentData->{'enteredweight'} .= ".0"; }

	my $insurance;
	if ($shipmentData->{'insurance'} and $shipmentData->{'insurance'} =~ /\./ )
		{
		# search/replace simultaneously.
		($insurance = $shipmentData->{'insurance'}) =~ s/\.//;
		}

	$shipmentData->{'oacontactphone'} =~ s/-//g if $shipmentData->{'oacontactphone'};

	# Attempt to distill Remel's various phone formats into something fedex will take
	my $ContactPhone = $shipmentData->{'contactphone'} || '';
	$ContactPhone =~ s/-//g;
	$ContactPhone =~ s/\s+//g;
	$ContactPhone =~ s/\(//g;
	$ContactPhone =~ s/\)//g;

	if ($shipmentData->{'addresscountry'} eq 'US' or $shipmentData->{'addresscountry'} eq 'CA')
		{
		$ContactPhone = $1 if $ContactPhone =~ /^(\d{10})/;
		}

	# Allow for LTR type packages (0 weight)
	my $PackageType = "01";
	if (!$shipmentData->{'enteredweight'} or $shipmentData->{'enteredweight'} == 0)
		{
		$PackageType = "06";
		$shipmentData->{'enteredweight'} = "1.0";
		$shipmentData->{'commodityweight'} = "1.0";
		}

	# Hardwire 'Total Customs Value' to be the same as 'Commodity Customs Value'
	my $commoditycustomsvalue;
	if ($shipmentData->{'commoditycustomsvalue'})
		{
		if ( $shipmentData->{'commoditycustomsvalue'} =~ /\./ )
			{
			# search/replace simultaneously.
			($commoditycustomsvalue = $shipmentData->{'commoditycustomsvalue'}) =~ s/\.//;
			}
		elsif ( $shipmentData->{'commoditycustomsvalue'} !~ /\./ )
			{
			$commoditycustomsvalue = $shipmentData->{'commoditycustomsvalue'} . '00';
			}
		}

	# Hardwire 'Unit Quantity' to 'Commodity Number of Pieces'
	$shipmentData->{'unitquantity'} = $shipmentData->{'commodityquantity'};

	# 3rd Party Billing
	my $AccountNumber = "";
	my $BillingType = "";

	if ($shipmentData->{'billingaccount'})
		{
		$AccountNumber = $shipmentData->{'billingaccount'};
		$BillingType = 3;
		}
	else
		{
		$AccountNumber = $shipmentData->{'webaccount'};
		$BillingType = 1;
		}

	$AccountNumber =~ s/[-| ]//g;

	# Pop reference field with 'Order# - Customer#'
	$shipmentData->{'refnumber'} = $shipmentData->{'ordernumber'};
	if ($shipmentData->{'ponumber'})
		{
		$shipmentData->{'refnumber'} .= " - " . $shipmentData->{'ponumber'};
		}
	elsif ($shipmentData->{'custnum'})
		{
		$shipmentData->{'refnumber'} .= " - " . $shipmentData->{'custnum'};
		}

	# Strip non-numeric from ssnein field
	$shipmentData->{'ssnein'} =~ s/\D//g if $shipmentData->{'ssnein'};

	# Strip non alpha-numeric from harmonized code field
	$shipmentData->{'harmonizedcode'} =~ s/[^a-zA-Z0-9]//g if $shipmentData->{'harmonizedcode'};

	# Hash with data to build up shipping string that we'll transmit to FedEx

	my $ShipDate = IntelliShip::DateUtils->format_to_yyyymmdd($shipmentData->{'datetoship'});

	my %ShipData = (
		# Generic
		4		=>	$shipmentData->{'customername'}, 		#Sender company
		5		=>	$shipmentData->{'branchaddress1'},		#Sender Addr1
		6		=>	$shipmentData->{'branchaddress2'},		#Sender Addr2 -> but only if pop'd.  Probly pull from ref.
		7		=>	$shipmentData->{'branchaddresscity'},	#Sender City
		8		=>	$shipmentData->{'branchaddressstate'},	#Sender State
		9		=>	$shipmentData->{'branchaddresszip'},	#Sender Postal Code
		11		=>	$shipmentData->{'addressname'},			#Recipient Company
		12		=>	$shipmentData->{'contactname'},			#Recipient contactname
		13		=>	$shipmentData->{'address1'},			#Recipient Addr1
		14		=>	$shipmentData->{'address2'},			#Recipient Addr2
		15		=>	$shipmentData->{'addresscity'},			#Recipient City
		16		=>	$shipmentData->{'addressstate'},		#Recipient State
		17		=>	$shipmentData->{'addresszip'},			#Recipient Postal Code
		18		=>	$ContactPhone,							#Recipient Phone Number
		20		=>	$AccountNumber, 						#Payer Account Number
		23		=>	$BillingType,							#Pay Type
		25		=>	$shipmentData->{'refnumber'},			#Reference Number
		117		=>	$shipmentData->{'branchaddresscountry'},#Sender Country Code
		183		=>	$shipmentData->{'oacontactphone'},		#Sender Phone Number
		498		=>	$shipmentData->{'meternumber'},			#Required - Meter #
		1119	=>	"Y",
		24		=>	$ShipDate,								# Ship date
		1273	=>	$PackageType,							#FedEx Packaging Type
		1274	=>	$shipmentData->{'webname'},				#FedEx Service Type
		32		=>	$shipmentData->{'oacontactname'},		#Shipping contactname
		187		=>	"299",									# New printer stuff
		);

	# fedex says this has to do with hazardous - 20121112
	#if ( $shipmentData->{'international'} )
	#	{
	#	$ShipData{'1391'} = "2";	#Client Revision Indicator
	#	}

	## Total Package Weight this field has 2 implied decimals.
	## Multiplying by 100 just puts things to rights.
	$ShipData{'1670'} = ceil($shipmentData->{'enteredweight'} * 100);

	$ShipData{'75'} = $shipmentData->{'weighttype'};	#Weight Units
	$ShipData{'69'} = $insurance; 						#Declared Value/Carriage Value

	# Heavy
	$ShipData{'57'} = $shipmentData->{'dimheight'}; 	#Required for heavyweight
	$ShipData{'58'} = $shipmentData->{'dimwidth'}; 		#Required for heavyweight
	$ShipData{'59'} = $shipmentData->{'dimlength'}; 	#Required for heavyweight

	# International
	$ShipData{'1090'} = $shipmentData->{'currencytype'};
	$ShipData{'74'} = $shipmentData->{'destinationcountry'};

	if ( $shipmentData->{'international'} )
		{
		$ShipData{'80'} = $shipmentData->{'manufacturecountry'};
		$ShipData{'70'} = $shipmentData->{'dutypaytype'};
		$ShipData{'1958'} = "Box";
		}

	$ShipData{'71'} = $shipmentData->{'dutyaccount'};

	if ( $shipmentData->{'international'} )
		{
		$ShipData{'72'} = $shipmentData->{'termsofsale'};
		$ShipData{'414'} = $shipmentData->{'commodityunits'};
		$ShipData{'119'} = $commoditycustomsvalue;
		}

	$ShipData{'76'} = $shipmentData->{'commodityquantity'};
	$ShipData{'82'} = $shipmentData->{'unitquantity'};

	if ( $shipmentData->{'international'} )
		{
		$ShipData{'73'} = $shipmentData->{'partiestotransaction'};
		$ShipData{'79'} = $shipmentData->{'extcd'};
		}

	$ShipData{'81'} = $shipmentData->{'harmonizedcode'};

	if ( $shipmentData->{'international'} )
		{
		$ShipData{'413'} = $shipmentData->{'naftaflag'};
		}

	$ShipData{'1139'} = $shipmentData->{'ssnein'};
	$ShipData{'50'} = $shipmentData->{'addresscountry'}; #Recipient Country Code

	# FedEx says is obsolete (201211112)
	if ($shipmentData->{'international'})
		{
		$ShipData{'1349'} = "S";
		}

	# International Heavy
	$ShipData{'1271'} = $shipmentData->{'slac'}; # SLAC
	$ShipData{'1272'} = $shipmentData->{'bookingnumber'}; # Booking number

	# Hazardous - fedex says these are for hazardous not international.
	if ($shipmentData->{'hazardous'})
		{
		$ShipData{'456'} = 1;
		$ShipData{'466'} = 1;
		$ShipData{'471'} = 'L';
		# Hazardous - fedex says that this is DG commodity count.
		$ShipData{'1932'} = 1;
		}

	# Saturday Delivery
	if ($shipmentData->{'dateneeded'})
		{
		my $DateToText = IntelliShip::DateUtils->date_to_text_long($shipmentData->{'dateneeded'});
		if ($DateToText =~ /Saturday/i)
			{
			$ShipData{'1266'} = 'Y'
			}
		}

	# Hazardous
	if ($shipmentData->{'hazardous'} == 1)
		{
		$ShipData{'1331'} = "A", #Hazardous Flag
		$ShipData{'451'} = $shipmentData->{'dgunnum'},
		$ShipData{'461'} = $shipmentData->{'dgpkgtype'},
		$ShipData{'476'} = $shipmentData->{'dgpkginstructions'},
		$ShipData{'484'} = $ContactPhone,
		$ShipData{'489'} = $shipmentData->{'dgpackinggroup'},
		$ShipData{'1903'} = $shipmentData->{'description'}, # Dangerous Goods Proper Ship Name
		$ShipData{'1918'} = $shipmentData->{'contactname'}, # Dangerous Goods Signatory
		$ShipData{'1922'} = $shipmentData->{'addresscity'}, # Dangerous Goods Signatory Location
		$ShipData{'485'} = $shipmentData->{'contacttitle'}, # Dangerous Goods Signatory Title
		}

	$shipmentData->{'rtaddressid'} = $CO->rtaddressid;
	$shipmentData->{'rtcontact'} = $CO->rtcontact;
	$shipmentData->{'rtphone'} = $CO->rtphone;

	if ($shipmentData->{'rtaddressid'})
		{
		if ( !$shipmentData->{'rtphone'} )
			{
			$shipmentData->{'rtphone'} = $Customer->phone;
			$shipmentData->{'rtcontact'} = $Customer->contact;
			}

		$shipmentData->{'rtphone'} =~ s/\.//g;
		$shipmentData->{'rtphone'} =~ s/\///g;
		$shipmentData->{'rtphone'} =~ s/\)//g;
		$shipmentData->{'rtphone'} =~ s/\(//g;
		$shipmentData->{'rtphone'} =~ s/ //g;

		if (my $rtAddress = $CO->route_to_address)
			{
			$ShipData{'1586'} = "Y",
			$ShipData{'1485'} = $shipmentData->{'rtcontact'},
			$ShipData{'1492'} = $shipmentData->{'rtphone'},
			$ShipData{'1486'} = $rtAddress->addressname,
			$ShipData{'1487'} = $rtAddress->address1,
			$ShipData{'1488'} = $rtAddress->address2,
			$ShipData{'1489'} = $rtAddress->city,
			$ShipData{'1490'} = $rtAddress->state,
			$ShipData{'1491'} = $rtAddress->zip,
			$ShipData{'1585'} = $rtAddress->country,
			}
		}

	# Build the shipment string
	# Note - double quotes (") get escaped *within* their string.  This is needed since we're 'echo'ing
	# where we pipe it to the fedex program.

	# Shipment string prefix.
	my $ShipmentString = '0,"020"';
	foreach my $key (sort {$a <=> $b} (keys(%ShipData)))
		{
		# Push the key/value onto the string, if value exists (null value except in suffix tag
		# is a no-no).
		if($ShipData{$key})
			{
			$ShipData{$key} =~ s/`/\\`/g;
			$ShipData{$key} =~ s/"/%22/g;

			$ShipmentString .= $key . ',"' . $ShipData{$key} . '"';
			}
		}
	# Shipment string suffix
	$ShipmentString .= '99,""';

	# Pass shipment string to fedex, and get the return value

	#$self->log('... ShipmentString: ' . $ShipmentString);
	my $ShipmentReturn;

	eval {
	$ShipmentReturn = $self->ProcessLocalRequest($ShipmentString); ##**
	};
	#$self->log('... ShipmentReturnResponse: ' . $ShipmentReturn);

	# Check return string for errors;
	if ($ShipmentReturn =~ /"2,"\w+?"/)
		{
		my $ErrorCode = $1 if $ShipmentReturn =~ /"2,"(\w+?)"/;
		my $ErrorMessage = $1 if $ShipmentReturn =~ /"3,"(.*?)"/;

		$shipmentData->{'errorstring'} = "Carrier Response Error: " . $ErrorCode . " : " . $ErrorMessage;

		if (   $ErrorCode eq 'F010' 
			or $ErrorCode eq '1237'
			or $ErrorCode eq '4057'
			or $ErrorCode eq '5031'
			or $ErrorCode eq '5043'
			or $ErrorCode eq '6011'
			or $ErrorCode eq '6015'
			or $ErrorCode eq '8020'
			or $ErrorCode eq '6026' )
			{
			$shipmentData->{'errorcode'} = 'badzone';
			}

		$self->add_error($shipmentData->{'errorstring'});
		return $shipmentData;
		}
	elsif ($ShipmentReturn =~ /ERROR:(.*)\n/)
		{
		$self->add_error($1);
		return $shipmentData;
		}

	unless ($ShipmentReturn)
		{
		$self->add_error("No response received from FedEx");
		return $shipmentData;
		}

	# Build the shipment object to pass back to service
	my $TrackingNumber = $1 if $ShipmentReturn =~ /"29,"(\w+?)"/;
	my $PrinterString = $1 if $ShipmentReturn =~ /188,"(.*\nP1\nN\n)"/s;

	#$self->log("PrinterString: " . $PrinterString);

	if ( !$PrinterString )
		{
		$self->log("SEND HTTP REQUEST, " . __PACKAGE__);
		my $ua = LWP::UserAgent->new;
		$ua->agent("Mozilla/4.08");

		my $req_url = "http://216.198.214.5/" . $TrackingNumber;
		my $req = new HTTP::Request("GET" => $req_url);

		my $Response = $ua->request($req);

		my $String = $Response->as_string;
		$String =~ s/\x0c//;
		$String =~ s/\r//g;

		$PrinterString = $String;
		$self->log("RESPONSE STRING: " . $PrinterString);
		}

	$PrinterString = $self->TagPrinterString($PrinterString,$shipmentData->{'ordernumber'});

	$shipmentData->{'tracking1'} = $TrackingNumber;
	$shipmentData->{'printerstring'} = $PrinterString;
	$shipmentData->{'weight'} = $shipmentData->{'enteredweight'};

	#$self->log('### shipmentData ###: ' . Dumper $shipmentData);

	$self->insert_shipment($shipmentData);

	$self->response->printer_string($PrinterString);
	}

sub ProcessLocalRequest
	{
	my $self = shift;
	my $Request = shift;

	#$self->log('... ProcessLocalRequest, REQUEST: ' . $Request);

	#$Request = '0,"020"1,"GlobalIntl#1"4,"Shipper Name"5,"Shipper Address #1"6,"Shipper Address #2"7,"Paris"8,"PA"9,"19406"11,"Recipient Company Name"12,"Recipient Contact Name"13,"660 American Ave"14,"3rd Floor"15,"North York"17,"20122"18,"6107680246"21,"15"23,"1"25,"Reference Notes"50,"IT"72,"FOB"74,"IT"77,"8"78,"19.950000"79,"commodity description"80,"US"81,"harmonized code"82,"1"113,"Y"117,"US"183,"6107680246"187,"299"414,"ea"498,"203618"1090,"USD"1273,"01"1274,"01"1282,"T"1349,"S"1958,"Box"1030,"19.950000"99,""';

	#my $Host = "160.209.84.51";
	#my $Host = "192.168.1.84";
	#my $Host = '192.168.1.76';
	my $Host = '216.198.214.5';
	my $Port = "2000";

	my $telnet = Net::Telnet->new(
					Host => $Host,
					Port => $Port,
					#Dump_Log => "$config->{BASE_PATH}/var/log/fedex_local_dump.log",
					#Input_Log => "$config->{BASE_PATH}/var/log/fedex_local_input.log",
					Timeout => 10
					);

	#$telnet->print($Request);
	#my ($Pre,$Match) = $telnet->waitfor(Match => '/99,""/');
	$telnet->print($Request);
	my ($Pre,$Match) = $telnet->waitfor(Match => '/99,""/');
	#my $Match = $telnet->getline;
	#my $Label = $telnet->getline;
	#$telnet->print('ls');
	#my ($output) = $telnet->waitfor('/\$ $/i');
	#warn "OUTPUT: " . $output;

	#my @remotelabels = $telnet->cmd('type C:\FedEx\Fedex_LabelBuffer');

	#warn @remotelabels[0];
	#$telnet->dump_log();
	#$telnet->input_log();
	#warn "ProcessLoaclRequest: $Pre";
	#warn "MATCH=$Match";
	#warn "LABEL-$Label";
	return $Pre.$Match."\n";
	}

__PACKAGE__->meta()->make_immutable();

no Moose;

1;

__END__