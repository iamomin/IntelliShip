package IntelliShip::Carrier::Driver::FedEx::ShipOrder;

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
	my $requestData = $self->data;

	###############################
	# The incoming variables
	###############################
	$requestData->{'carrier'} = 'Fedex';

	if ($requestData->{'addresscountry'} eq 'USA')
		{
		$requestData->{'addresscountry'} = 'US';
		}

	$requestData->{'commodityweight'} = $requestData->{'enteredweight'};
	$requestData->{'dateshipped'} = $requestData->{'datetoship'};

	if ( $requestData->{'enteredweight'} !~ /\.\d+/ ) { $requestData->{'enteredweight'} .= ".0"; }

	my $insurance;
	if ($requestData->{'insurance'} and $requestData->{'insurance'} =~ /\./ )
		{
		# search/replace simultaneously.
		($insurance = $requestData->{'insurance'}) =~ s/\.//;
		}

	$requestData->{'oacontactphone'} =~ s/-//g;

	# Attempt to distill Remel's various phone formats into something fedex will take
	my $ContactPhone = $requestData->{'contactphone'};
	$ContactPhone =~ s/-//g;
	$ContactPhone =~ s/\s+//g;
	$ContactPhone =~ s/\(//g;
	$ContactPhone =~ s/\)//g;

	if ( $requestData->{'addresscountry'} eq 'US' or $requestData->{'addresscountry'} eq 'CA' )
		{
		$ContactPhone = $ContactPhone =~ /^(\d{10})/;
		}

	# Allow for LTR type packages (0 weight)
	my $PackageType = "01";
	if ($requestData->{'enteredweight'} == 0)
		{
		$PackageType = "06";
		$requestData->{'enteredweight'} = "1.0";
		$requestData->{'commodityweight'} = "1.0";
		}

	# Hardwire 'Total Customs Value' to be the same as 'Commodity Customs Value'
	my $commoditycustomsvalue;
	if ( $requestData->{'commoditycustomsvalue'} )
		{
		if ( $requestData->{'commoditycustomsvalue'} =~ /\./ )
			{
			# search/replace simultaneously.
			($commoditycustomsvalue = $requestData->{'commoditycustomsvalue'}) =~ s/\.//;
			}
		elsif ( $requestData->{'commoditycustomsvalue'} !~ /\./ )
			{
			$commoditycustomsvalue = $requestData->{'commoditycustomsvalue'} . '00';
			}
		}

	# Hardwire 'Unit Quantity' to 'Commodity Number of Pieces'
	$requestData->{'unitquantity'} = $requestData->{'commodityquantity'};

	# 3rd Party Billing
	my $AccountNumber = "";
	my $BillingType = "";

	if ($requestData->{'billingaccount'})
		{
		$AccountNumber = $requestData->{'billingaccount'};
		$BillingType = 3;
		}
	else
		{
		$AccountNumber = $requestData->{'webaccount'};
		$BillingType = 1;
		}

	$AccountNumber =~ s/[-| ]//g;

	# Pop reference field with 'Order# - Customer#'
	$requestData->{'refnumber'} = $requestData->{'ordernumber'};
	if ($requestData->{'ponumber'})
		{
		$requestData->{'refnumber'} .= " - " . $requestData->{'ponumber'};
		}
	elsif ($requestData->{'custnum'})
		{
		$requestData->{'refnumber'} .= " - " . $requestData->{'custnum'};
		}

	# Strip non-numeric from ssnein field
	if ($requestData->{'ssnein'})
		{
		$requestData->{'ssnein'} =~ s/\D//g;
		}

	# Strip non alpha-numeric from harmonized code field
	if ($requestData->{'harmonizedcode'})
		{
		$requestData->{'harmonizedcode'} =~ s/[^a-zA-Z0-9]//g;
		}

	# Hash with data to build up shipping string that we'll transmit to FedEx

	my $ShipDate = IntelliShip->DateUtils->format_to_yyyymmdd($requestData->{'datetoship'});

	my %ShipData = (
		# Generic
		4		=>	$requestData->{'customername'}, 		#Sender company
		5		=>	$requestData->{'branchaddress1'},		#Sender Addr1
		6		=>	$requestData->{'branchaddress2'},		#Sender Addr2 -> but only if pop'd.  Probly pull from ref.
		7		=>	$requestData->{'branchaddresscity'},	#Sender City
		8		=>	$requestData->{'branchaddressstate'},	#Sender State
		9		=>	$requestData->{'branchaddresszip'},		#Sender Postal Code
		11		=>	$requestData->{'addressname'},			#Recipient Company
		12		=>	$requestData->{'contactname'},			#Recipient contactname
		13		=>	$requestData->{'address1'},				#Recipient Addr1
		14		=>	$requestData->{'address2'},				#Recipient Addr2
		15		=>	$requestData->{'addresscity'},			#Recipient City
		16		=>	$requestData->{'addressstate'},			#Recipient State
		17		=>	$requestData->{'addresszip'},			#Recipient Postal Code
		18		=>	$ContactPhone,							#Recipient Phone Number
		20		=>	$AccountNumber, 						#Payer Account Number
		23		=>	$BillingType,							#Pay Type
		25		=>	$requestData->{'refnumber'},			#Reference Number
		117		=>	"US",									#Sender Country Code
		183		=>	$requestData->{'oacontactphone'},		#Sender Phone Number
		498		=>	$requestData->{'meternumber'},			#Required - Meter #
		1119	=>	"Y",
		24		=>	$ShipDate,								# Ship date
		1273	=>	$PackageType,							#FedEx Packaging Type
		1274	=>	$requestData->{'webname'},				#FedEx Service Type
		187		=>	"299",									# New printer stuff
		);

	# fedex says this has to do with hazardous - 20121112
	#if ( $requestData->{'international'} )
	#	{
	#	$ShipData{'1391'} = "2";	#Client Revision Indicator
	#	}

	## Total Package Weight this field has 2 implied decimals.
	## Multiplying by 100 just puts things to rights.
	$ShipData{'1670'} = ceil($requestData->{'enteredweight'} * 100);

	$ShipData{'75'} = $requestData->{'weighttype'};		#Weight Units
	$ShipData{'69'} = $insurance; 						#Declared Value/Carriage Value

	# Heavy
	$ShipData{'57'} = $requestData->{'dimheight'}; 		#Required for heavyweight
	$ShipData{'58'} = $requestData->{'dimwidth'}; 		#Required for heavyweight
	$ShipData{'59'} = $requestData->{'dimlength'}; 		#Required for heavyweight

	# International
	$ShipData{'1090'} = $requestData->{'currencytype'};
	$ShipData{'74'} = $requestData->{'destinationcountry'};

	if ( $requestData->{'international'} )
		{
		$ShipData{'80'} = $requestData->{'manufacturecountry'};
		$ShipData{'70'} = $requestData->{'dutypaytype'};
		$ShipData{'1958'} = "Box";
		}

	$ShipData{'71'} = $requestData->{'dutyaccount'};

	if ( $requestData->{'international'} )
		{
		$ShipData{'72'} = $requestData->{'termsofsale'};
		$ShipData{'414'} = $requestData->{'commodityunits'};
		$ShipData{'119'} = $commoditycustomsvalue;
		}

	$ShipData{'76'} = $requestData->{'commodityquantity'};
	$ShipData{'82'} = $requestData->{'unitquantity'};

	if ( $requestData->{'international'} )
		{
		$ShipData{'73'} = $requestData->{'partiestotransaction'};
		$ShipData{'79'} = $requestData->{'extcd'};
		}

	$ShipData{'81'} = $requestData->{'harmonizedcode'};

	if ( $requestData->{'international'} )
		{
		$ShipData{'413'} = $requestData->{'naftaflag'};
		}

	$ShipData{'1139'} = $requestData->{'ssnein'};
	$ShipData{'50'} = $requestData->{'addresscountry'}; #Recipient Country Code

	# fedex says is obsolete (201211112)
	##if ( $requestData->{'international'} )
	##	{
	##	$ShipData{'1349'} = "S";
	##	}

	# International Heavy
	$ShipData{'1271'} = $requestData->{'slac'}; # SLAC
	$ShipData{'1272'} = $requestData->{'bookingnumber'}; # Booking number

	# Hazardous - fedex says these are for hazardous not international.
	if ( $requestData->{'hazardous'} )
		{
		$ShipData{'456'} = 1;
		$ShipData{'466'} = 1;
		$ShipData{'471'} = 'L';
		# Hazardous - fedex says that this is DG commodity count.
		$ShipData{'1932'} = 1;
		}

	# Saturday Delivery
	if ( $requestData->{'dateneeded'} )
		{
		my $DateToText = IntelliShip::DateUtils->date_to_text_long($requestData->{'dateneeded'});
		if ( $DateToText =~ /Saturday/i )
			{
			$ShipData{'1266'} = 'Y'
			}
		}

	# Hazardous
	if ( $requestData->{'hazardous'} == 1 )
		{
		$ShipData{'1331'} = "A", #Hazardous Flag
		$ShipData{'451'} = $requestData->{'dgunnum'},
		$ShipData{'461'} = $requestData->{'dgpkgtype'},
		$ShipData{'476'} = $requestData->{'dgpkginstructions'},
		$ShipData{'484'} = $ContactPhone,
		$ShipData{'489'} = $requestData->{'dgpackinggroup'},
		$ShipData{'1903'} = $requestData->{'description'}, # Dangerous Goods Proper Ship Name
		$ShipData{'1918'} = $requestData->{'contactname'}, # Dangerous Goods Signatory
		$ShipData{'1922'} = $requestData->{'addresscity'}, # Dangerous Goods Signatory Location
		$ShipData{'485'} = $requestData->{'contacttitle'}, # Dangerous Goods Signatory Title
		}

	$requestData->{'rtaddressid'} = $CO->rtaddressid;
	$requestData->{'rtcontact'} = $CO->rtcontact;
	$requestData->{'rtphone'} = $CO->rtphone;

	if ($requestData->{'rtaddressid'})
		{
		if ( !$requestData->{'rtphone'} )
			{
			$requestData->{'rtphone'} = $Customer->phone;
			$requestData->{'rtcontact'} = $Customer->contact;
			}

		$requestData->{'rtphone'} =~ s/\.//g;
		$requestData->{'rtphone'} =~ s/\///g;
		$requestData->{'rtphone'} =~ s/\)//g;
		$requestData->{'rtphone'} =~ s/\(//g;
		$requestData->{'rtphone'} =~ s/ //g;

		if (my $rtAddress = $CO->rt_address)
			{
			$ShipData{'1586'} = "Y",
			$ShipData{'1485'} = $requestData->{'rtcontact'},
			$ShipData{'1492'} = $requestData->{'rtphone'},
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

	my $ShipmentReturn = $self->ProcessLocalRequest($ShipmentString);

	# Check return string for errors;
	if ( $ShipmentReturn =~ /"2,"\w+?"/ )
		{
		my ($ErrorCode) = $ShipmentReturn =~ /"2,"(\w+?)"/;
		my ($ErrorMessage) = $ShipmentReturn =~ /"3,"(.*?)"/;

		$requestData->{'errorstring'} = "Error - " . $ErrorCode . ": " . $ErrorMessage;

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
			$requestData->{'errorcode'} = 'badzone';
			}

		return $requestData;
		}
	elsif ( $ShipmentReturn =~ /ERROR:(.*)\n/ )
		{
		$requestData->{'errorstring'} = $1;
		$requestData->{'screen'} = 'shipconfirm';

		return $requestData;
		}

	# Build the shipment object to pass back to service
	my $TrackingNumber = $ShipmentReturn =~ /"29,"(\w+?)"/;
	my $PrinterString = $ShipmentReturn =~ /188,"(.*\nP1\nN\n)"/s;

	if ( !$PrinterString )
		{
		my $ua = LWP::UserAgent->new;
		$ua->agent("Mozilla/4.08");

		my $req_url = "http://216.198.214.5/" . $TrackingNumber;
		my $req = new HTTP::Request("GET" => $req_url);

		my $Response = $ua->request($req);

		my $String = $Response->as_string;
		$String =~ s/\x0c//;
		$String =~ s/\r//g;

		$PrinterString = $String;
		}

	$PrinterString = $self->TagPrinterString($PrinterString,$requestData->{'ordernumber'});

	$requestData->{'tracking1'} = $TrackingNumber;
	$requestData->{'printerstring'} = $PrinterString;
	$requestData->{'weight'} = $requestData->{'enteredweight'};

	$c->log->debug('requestData: ' . Dumper $requestData);
	my $Shipment = $c->model('MyDBI::Shipment')->new($requestData);
	$Shipment->shipmentid($self->get_token_id);
	$Shipment->insert;

	$c->log->debug('New shipment inserted, ID: ' . $Shipment->shipmentid);

	$Shipment->{'printerstring'} = $PrinterString;

	return $Shipment;
	}

sub ProcessLocalRequest
	{
	my $self = shift;
	my $Request = @_;

	#$Request = '0,"020"1,"GlobalIntl#1"4,"Shipper Name"5,"Shipper Address #1"6,"Shipper Address #2"7,"Paris"8,"PA"9,"19406"11,"Recipient Company Name"12,"Recipient Contact Name"13,"660 American Ave"14,"3rd Floor"15,"North York"17,"20122"18,"6107680246"21,"15"23,"1"25,"Reference Notes"50,"IT"72,"FOB"74,"IT"77,"8"78,"19.950000"79,"commodity description"80,"US"81,"harmonized code"82,"1"113,"Y"117,"US"183,"6107680246"187,"299"414,"ea"498,"203618"1090,"USD"1273,"01"1274,"01"1282,"T"1349,"S"1958,"Box"1030,"19.950000"99,""';

	#my $Host = "160.209.84.51";
	#my $Host = "192.168.1.84";
	#my $Host = '192.168.1.76';
	my $Host = '216.198.214.5';
	my $Port = "2000";

	use Net::Telnet;
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