package IntelliShip::Import::Orders;

use Moose;
use Text::CSV;
use File::Copy;
use Time::Piece;
use Data::Dumper;
use File::Basename;
use POSIX qw (ceil strftime);
use Date::Calc qw(Delta_Days);
use Scalar::Util qw(looks_like_number);

use IntelliShip::Utils;
use IntelliShip::MyConfig;
use IntelliShip::DateUtils;

extends 'IntelliShip::Errors';

has 'import_file'  => ( is => 'rw' );
has 'customer'     => ( is => 'rw' );
has 'contact'      => ( is => 'rw' );
has 'myDBI_obj'    => ( is => 'rw' );
has 'context'      => ( is => 'rw' );
has 'API'          => ( is => 'rw' );
has 'AuthContacts' => ( is => 'rw' );

my $config;
$Data::Dumper::Sortkeys = 1;

sub BUILD
	{
	my $self = shift;
	$self->AuthContacts({});
	$config = IntelliShip::MyConfig->get_ARRS_configuration;
	}

sub myDBI
	{
	my $self = shift;
	return $self->myDBI_obj if $self->myDBI_obj;
	$self->myDBI_obj($self->context->model('MyDBI'));
	return $self->myDBI_obj;
	}

=as
sub parse_csv_row
	{
	my $self = shift;
	my $row_data = shift;

	my $CSV = Text::CSV->new();

	unless ($CSV->parse($row_data))
		{
		print "\n$row_data\n";
		print $CSV->error_input . "\n";
		return;
		}

	return $CSV->fields();

	}
=cut

sub import
	{
	my $self = shift;

	my $c = $self->context;

	my @files;
	my $import_file = $self->import_file;

	my $imported_path = IntelliShip::MyConfig->base_path . "/var/imported/co";

	if ($import_file)
		{
		push(@files, $import_file);
		}
	else
		{
		my $import_path = $self->get_directory;
		$c->log->debug("... import_path: " . $import_path);
		push(@files, <$import_path/*>);
		}

	$c->log->debug("... Total Files: " . @files);

	#################################
	### Check for Files to Import
	#################################
	foreach my $file (@files)
		{
		next if (! -f $file or ! -r $file );

		$c->log->debug("... Start Import Process For " . $file);

		my ($order_file, $product_file) = $self->format_file($import_file);

		if (!$order_file and !$product_file)
			{
			$self->add_error("File formatting error");
			next;
			}

		my ($ImportFailures,$OrderTypeRef) = $self->ImportOrders($order_file);
		my ($ImportFailures1,$ProductTypeRef) = $self->ImportProducts($product_file);

		#my $import_base_file = fileparse($file);

		#unless (move($file,"$imported_path/$import_base_file"))
		#	{
		#	print STDERR "Could not move $file to $imported_path/$import_base_file: $!";
		#	}

		#$self->EmailImportFailures($ImportFailures,$imported_path,$import_base_file,$OrderTypeRef);
		#system("$config->{BASE_PATH}/html/unknowncust_order_email.pl");
		}
	}

sub get_directory
	{
	my $self = shift;
	my $TARGET_dir = IntelliShip::MyConfig->import_directory;
	$TARGET_dir .= '/' . 'co';
	$TARGET_dir .= '/' . $self->customer->username;

	unless (IntelliShip::Utils->check_for_directory($TARGET_dir))
		{
		$self->context->log->debug("Unable to create target directory, " . $!);
		return;
		}

	return $TARGET_dir;
	}

sub ImportOrders
	{
	my $self = shift;
	my $import_file = shift;

	return unless $import_file;

	my $c = $self->context;

	my $UnknownCustCount = 0;
	my $Error_File = '';
	my $OrderTypeRef = {};

	my $FILE = new IO::File;

	$c->log->debug("\n");
	$c->log->debug("##### ImportOrders Read File: " . $import_file);

	unless (open($FILE, $import_file))
		{
		$c->log->debug("*** Error: " . $!);
		return;
		}

	my @FileLines;
	while (<$FILE>)
		{
		chomp;
		push(@FileLines,$_);
		}

	close ($FILE);

	$c->log->debug("... Total file lines: " . @FileLines);

	my $LineCount = 0;
	my $ImportFailureRef = {};

	foreach my $Line (@FileLines)
		{
		$LineCount++;

		## Trim spaces from front and back
		$Line =~ s/^\s+//;
		$Line =~ s/\s+$//;

		## skip blank lines
		next unless $Line;

		$c->log->debug("");
		#$c->log->debug("... Import Line: " . $Line);

		my $CustRef = {};
		## split the tab delimited line into field names
		(
			$CustRef->{'ordernumber'},
			$CustRef->{'ponumber'},
			$CustRef->{'addressname'},
			$CustRef->{'address1'},
			$CustRef->{'address2'},
			$CustRef->{'addresscity'},
			$CustRef->{'addressstate'},
			$CustRef->{'addresszip'},
			$CustRef->{'addresscountry'},
			$CustRef->{'datetoship'},
			$CustRef->{'estimatedweight'},
			$CustRef->{'estimatedinsurance'},
			$CustRef->{'description'},
			$CustRef->{'exthsc'},
			$CustRef->{'extcd'},
			$CustRef->{'extcarrier'},
			$CustRef->{'extservice'},
			$CustRef->{'hazardous'},
			$CustRef->{'dateneeded'},
			$CustRef->{'extloginid'},
			$CustRef->{'extcustnum'},
			$CustRef->{'department'},
			$CustRef->{'commodityquantity'},
			$CustRef->{'contactname'},
			$CustRef->{'contactphone'},
			$CustRef->{'extid'},
			$CustRef->{'generic1'},
			$CustRef->{'generic2'},
			$CustRef->{'generic3'},
			$CustRef->{'unitquantity'},
			$CustRef->{'stream'},
			$CustRef->{'keep'},
			$CustRef->{'dateneededon'},
			$CustRef->{'tpacctnumber'},
			$CustRef->{'shipmentnotification'},
			$CustRef->{'deliverynotification'},
			$CustRef->{'securitytype'},
			$CustRef->{'routeflag'},
			$CustRef->{'termsofsale'},
			$CustRef->{'dutypaytype'},
			$CustRef->{'dutyaccount'},
			$CustRef->{'commodityunits'},
			$CustRef->{'partiestotransaction'},
			$CustRef->{'commodityunitvalue'},
			$CustRef->{'destinationcountry'},
			$CustRef->{'commoditycustomsvalue'},
			$CustRef->{'manufacturecountry'},
			$CustRef->{'currencytype'},
			$CustRef->{'dropname'},
			$CustRef->{'dropaddress1'},
			$CustRef->{'dropaddress2'},
			$CustRef->{'dropcity'},
			$CustRef->{'dropstate'},
			$CustRef->{'dropzip'},
			$CustRef->{'dropcountry'},
			$CustRef->{'dropcontact'},
			$CustRef->{'dropphone'},
			$CustRef->{'custref2'},
			$CustRef->{'custref3'},
			$CustRef->{'freightcharges'},
			$CustRef->{'transitdays'},
			$CustRef->{'residentialflag'},
			$CustRef->{'saturdayflag'},
			$CustRef->{'AMflag'},
			$CustRef->{'cotype'}
		) = split(/\t/, $Line);

		#$c->log->debug("... SPLIT DATA: " . Dumper $CustRef);

		my $export_flag = 0;

		#$c->log->debug("... CO information gathered");

		IntelliShip::Utils->trim_hash_ref_values($CustRef);

		##########################################################
		##  FLUSH OLD DETAILS IF ANY FOR MATCHING ORDERNUMBER   ##
		##########################################################
		if (my @DuplicateCOs = $c->model('MyDBI::CO')->search({ ordernumber => $CustRef->{'ordernumber'} }))
			{
			$c->log->debug("*** ".@DuplicateCOs." DUPLICATE order found for order number '$CustRef->{'ordernumber'}', delete old details...");
			foreach my $DuplicateCO (@DuplicateCOs)
				{
				$DuplicateCO->delete_all_package_details;
				$DuplicateCO->delete;
				}
			}

		## Sort out generic values - in the MAERSK era, we were saddled with a very bad design where the
		## dim fields were co-opted for other uses (volume,density,class, at this point)
		## So.  If all three generic fields are filled, they correspond to the previous dims.
		## If only generic1 is filled, that's volume.  Only generic2=density.  Only generic3=classo
		if ( $CustRef->{'generic1'} and $CustRef->{'generic2'} and $CustRef->{'generic3'} )
			{
			$CustRef->{'dimlength'} = $CustRef->{'generic1'};
			$CustRef->{'dimwidth'} = $CustRef->{'generic2'};
			$CustRef->{'dimheight'} = $CustRef->{'generic3'};
			}
		elsif ( $CustRef->{'generic1'} and !$CustRef->{'generic2'} and !$CustRef->{'generic3'} )
			{
			$CustRef->{'volume'} = $CustRef->{'generic1'};
			}
		elsif ( !$CustRef->{'generic1'} and $CustRef->{'generic2'} and !$CustRef->{'generic3'} )
			{
			$CustRef->{'density'} = $CustRef->{'generic2'};
			}
		elsif ( !$CustRef->{'generic1'} and !$CustRef->{'generic2'} and $CustRef->{'generic3'} )
			{
			$CustRef->{'class'} = $CustRef->{'generic3'};
			}

		## undef freightcharges if not valid value, (0,1,2)(prepaid,collect,tp)
		if ( defined $CustRef->{'freightcharges'}
			and $CustRef->{'freightcharges'} ne '0'
			and $CustRef->{'freightcharges'} ne '1'
			and $CustRef->{'freightcharges'} ne '2' )
			{
			$CustRef->{'freightcharges'} = undef;
			}

		if ( defined($CustRef->{'transitdays'}) and $CustRef->{'transitdays'} ne '' )
			{
			$CustRef->{'transitdays'} =~ s/[^0-9]//g; ## Remove non-numbers;
			## undef transitdays if not nothing left after removing everything expect integers
			if ( defined($CustRef->{'transitdays'}) and $CustRef->{'transitdays'} eq '' )
				{
				$CustRef->{'transitdays'} = undef;
				}
			}

		## set cotypeid
		if ( defined($CustRef->{'cotype'}) and $CustRef->{'cotype'} =~ /PO/i )
			{
			$CustRef->{'cotypeid'} = 2;
			$OrderTypeRef->{'ordertype'} = 'PO';
			$OrderTypeRef->{'ordertype_lc'} = 'PO';
			}
		elsif ( defined($CustRef->{'cotype'}) and $CustRef->{'cotype'} =~ /Quote/i )
			{
			$CustRef->{'cotypeid'} = 10;
			$OrderTypeRef->{'ordertype'} = 'Quote';
			$OrderTypeRef->{'ordertype_lc'} = 'quote';
			}
		else
			{
			$CustRef->{'cotypeid'} = 1;
			$OrderTypeRef->{'ordertype'} = 'Order';
			$OrderTypeRef->{'ordertype_lc'} = 'order';
			}

		#Straigten out address
		if ((!defined($CustRef->{'address1'}) or $CustRef->{'address1'} eq '') and
			(defined($CustRef->{'address2'}) and $CustRef->{'address2'} ne '')
			)
			{
			$CustRef->{'address1'} = $CustRef->{'address2'};
			$CustRef->{'address2'} = '';
			}

		## Default country to US if it is null
		$CustRef->{'addresscountry'} = uc($CustRef->{'addresscountry'});
		if ( !defined($CustRef->{'addresscountry'}) or $CustRef->{'addresscountry'} eq '' )
			{
			$CustRef->{'addresscountry'} = 'US';
			}
		## Trim contact name to 50
		if ( defined($CustRef->{'contactname'}) and $CustRef->{'contactname'} ne '' )
			{
			$CustRef->{'contactname'} = substr($CustRef->{'contactname'},0,50);
			}

		#################################################
		### Check for required fields and verify dates
		################################################

		unless ($CustRef->{'extloginid'})
			{
			$c->log->debug("--- no extloginid found");
			$export_flag = -9;
			}

		## Figure out who this is
		my ($ContactID,$CustomerID) = $self->AuthenticateContact($CustRef->{'extloginid'});
		$c->log->debug("... Authenticated Customer: " . $CustomerID . ", Contact: " . $ContactID);

		my $Contact = $c->model('MyDBI::Contact')->find({ contactid => $ContactID }) if $ContactID;
		my $Customer = $c->model('MyDBI::Customer')->find({ customerid => $CustomerID }) if $CustomerID;

		## If we don't have an incoming class, check if we have a default class...and stuff it in if we do
		unless ($Contact and $Customer)
			{
			$Contact = $self->contact;
			$Customer = $self->customer;
			}

		unless ($CustRef->{'class'})
			{
			$CustRef->{'class'} = $Contact->get_contact_data_value('defaultfreightclass');
			}

		unless ($CustomerID)
			{
			$c->log->debug("--- no CustomerID found");
			$export_flag = -9;
			}

		#if ($Customer)
		#	{
		#	($CustRef->{'errorshipdate'},$CustRef->{'errorduedate'}) = ($Customer->errorshipdate, $Customer->errorduedate);
		#	}

		## Convert Customer Security Type to Intelliship Security Type
		if ( defined($CustRef->{'securitytype'}) and $CustRef->{'securitytype'} ne '' )
			{
			my $STHS = $self->myDBI->select("
				SELECT
					securitytypeid
				FROM
					securitytypeext
				WHERE
					customerid = '$CustomerID'
					AND securitytypeext = '$CustRef->{'securitytype'}'
				LIMIT 1
			");

			my $securitytype = $STHS->fetchrow(0)->{'securitytypeid'} if $STHS->numrows;
			$CustRef->{'securitytype'} = $securitytype;
			}

		#Check for valid extcarrier/extservice
		if ($CustRef->{'extcarrier'} and $CustRef->{'extservice'}
			and ($CustRef->{'extcarrier'} !~ /^void$/i or $CustRef->{'extservice'} !~ /^void$/i))
			{
			my $SOPID = $Customer->get_contact_data_value('sopid') || $CustomerID;

			my $CSRef = {
				carrier => $CustRef->{'extcarrier'},
				service => $CustRef->{'extservice'},
				sopid   => $SOPID,
				};

			my $customerserviceid = $self->API->get_csid($CSRef);

			unless ($customerserviceid)
				{
				$c->log->debug("--- customerserviceid not found");
				$export_flag = -10;
				}
			}

		## Must have an order number
		unless ($CustRef->{'ordernumber'})
			{
			$c->log->debug("--- ordernumber not found");
			$export_flag = -1;
			}

		## Order needs an addr1 and an addr2
		if (!$CustRef->{'address1'} and !$CustRef->{'address2'})
			{
			$c->log->debug("--- address 1 and 2 not found");
			$export_flag = -2;
			}

		## Validate Country
		if ($CustRef->{'addresscountry'})
			{
			my $ValidCountry = $self->ValidateCountry($CustRef->{'addresscountry'});

			if ($ValidCountry)
				{
				$CustRef->{'addresscountry'} = $ValidCountry;
				}
			else
				{
				$c->log->debug("--- address country not found");
				$export_flag = -13;
				}
			}

		if ($CustRef->{'dropcountry'})
			{
			my $ValidOriginCountry = $self->ValidateCountry($CustRef->{'dropcountry'});

			if ($ValidOriginCountry)
				{
				$CustRef->{'dropcountry'} = $ValidOriginCountry;
				}
			else
				{
				$c->log->debug("--- drop country not found");
				$export_flag = -20;
				}
			}

		## US Specific Requirements and quirks
		if ( $CustRef->{'addresscountry'} eq 'US' )
			{
			## Order needs a city, state, and zip
			if (!$CustRef->{'addresscity'} or !$CustRef->{'addressstate'} or !$CustRef->{'addresszip'})
				{
				$c->log->debug("--- address city/state/zip not found");
				$export_flag = -3;
				}

			## if we've got a 4 digit US zip then pad with zero
			if ( $CustRef->{'addresszip'} and $CustRef->{'addresszip'} =~ /^\d{4}$/ )
				{
				$CustRef->{'addresszip'} = "0" . $CustRef->{'addresszip'};
				}

			## Zip needs to be 5 or 5+4
			if ( $CustRef->{'addresszip'} and $CustRef->{'addresszip'} !~ /\d{5}(\-\d{4})?/ )
				{
				$c->log->debug("--- address city/state/zip not found");
				$export_flag = -4;
				}
			}

		if (!defined($CustRef->{'addressname'}) or $CustRef->{'addressname'} eq '')
			{
			$c->log->debug("--- address name not found");
			$export_flag = -6;
			}

		## if anything is given for dropship address then validate that it is a good address
		if (
				(defined($CustRef->{'dropname'}) and $CustRef->{'dropname'} ne '')
			or (defined($CustRef->{'dropaddress1'}) and $CustRef->{'dropaddress1'} ne '')
			or (defined($CustRef->{'dropaddress2'}) and $CustRef->{'dropaddress2'} ne '')
			or (defined($CustRef->{'dropcity'}) and $CustRef->{'dropcity'} ne '')
			or (defined($CustRef->{'dropstate'}) and $CustRef->{'dropstate'} ne '')
			or (defined($CustRef->{'dropzip'}) and $CustRef->{'dropzip'} ne '')
			or (defined($CustRef->{'dropcountry'}) and $CustRef->{'dropcountry'} ne '')

			)
			{
			$CustRef->{'dropcountry'} = uc($CustRef->{'dropcountry'});
			if ( !defined($CustRef->{'dropcountry'}) or $CustRef->{'dropcountry'} eq '' )
				{
				$CustRef->{'dropcountry'} = 'US';
				}

			if ( defined($CustRef->{'dropcountry'}) )
				{
				my $ValidDropCountry = $self->ValidateCountry($CustRef->{'dropcountry'});

				if ($ValidDropCountry)
					{
					$CustRef->{'dropcountry'} = $ValidDropCountry;
					}
				else
					{
					$c->log->debug("--- drop country not found");
					$export_flag = -20;
					}
				}
			## Needs an addr1 and an addr2
			if (!$CustRef->{'dropaddress1'} eq '' and !$CustRef->{'dropaddress2'})
				{
				$c->log->debug("--- drop address 1 and 2 not found");
				$export_flag = -16;
				}

			if ( $CustRef->{'dropcountry'} eq 'US' )
				{
				## Needs a city, state, and zip
				if (!$CustRef->{'dropcity'} or !$CustRef->{'dropstate'} or !$CustRef->{'dropzip'})
					{
					$c->log->debug("--- drop city/state/zip not found");
					$export_flag = -17;
					}

				## if we've got a 4 digit US zip then pad with zero
				if ( $CustRef->{'dropzip'} and $CustRef->{'dropzip'} =~ /^\d{4}$/ )
					{
					$CustRef->{'dropzip'} = "0" . $CustRef->{'dropzip'};
					}
				## Zip needs to be 5 or 5+4
				if ( defined($CustRef->{'dropzip'}) and $CustRef->{'dropzip'} !~ /\d{5}(\-\d{4})?/ )
					{
					$c->log->debug("--- drop zip not found");
					$export_flag = -18;
					}
				}

			if (!$CustRef->{'dropname'})
				{
				$c->log->debug("--- drop name not found");
				$export_flag = -19;
				}

			$CustRef->{'isdropship'} = 1;
			}

		if (defined($CustRef->{'datetoship'}) and $CustRef->{'datetoship'} ne '')
			{
			$CustRef->{'datetoship'} = $self->VerifyDate($CustRef->{'datetoship'});
			if ( $CustRef->{'datetoship'} eq '0')
				{
				$c->log->debug("--- datetoship not found");
				$export_flag = -7;
				}
			elsif ( $CustRef->{'datetoship'} ne '0' and defined($CustRef->{'errorshipdate'}) and $CustRef->{'errorshipdate'} == 1 )
				{
				my ($current_day, $current_month, $current_year) = (localtime)[3,4,5];
				$current_year = $current_year + 1900;
				$current_month = $current_month + 1;

				if ( $current_month !~ /\d\d/ ) { $current_month = "0" . $current_month; }
				if ( $current_day !~ /\d\d/ ) { $current_day = "0" . $current_day; }

				my @TodayDate = ($current_year,$current_month,$current_day);

				my ($ShipMonth,$ShipDay,$ShipYear) = $CustRef->{'datetoship'} =~ /(\d{1,2})\/(\d{1,2})\/(\d{4})/;
				my @ShipDate = ($ShipYear,$ShipMonth,$ShipDay);

				if ( Delta_Days(@TodayDate, @ShipDate) < 0 )
					{
					$c->log->debug("--- ship date less than today's date");
					$export_flag = -12;
					}
				}
			}

		if (defined($CustRef->{'dateneeded'}) and $CustRef->{'dateneeded'} ne '')
			{
			$CustRef->{'dateneeded'} = $self->VerifyDate($CustRef->{'dateneeded'});
			if ( $CustRef->{'dateneeded'} eq '0')
				{
				$c->log->debug("--- dateneeded not found");
				$export_flag = -8;
				}
			elsif ( $CustRef->{'dateneeded'} ne '0' and defined($CustRef->{'errorduedate'}) and $CustRef->{'errorduedate'} == 1 )
				{
				my ($current_day, $current_month, $current_year) = (localtime)[3,4,5];
				$current_year = $current_year + 1900;
				$current_month = $current_month + 1;

				if ( $current_month !~ /\d\d/ ) { $current_month = "0" . $current_month; }
				if ( $current_day !~ /\d\d/ ) { $current_day = "0" . $current_day; }

				my @TodayDate = ($current_year,$current_month,$current_day);

				my ($DueMonth,$DueDay,$DueYear) = $CustRef->{'dateneeded'} =~ /(\d{1,2})\/(\d{1,2})\/(\d{4})/;
				my @DueDate = ($DueYear,$DueMonth,$DueDay);
				my $delta = Delta_Days(@TodayDate,@DueDate);

				#if ( Delta_Days(@TodayDate, @DueDate) <= 0 ) #Same day or in the past
				if ( Delta_Days(@TodayDate, @DueDate) < 0 )
					{
					$c->log->debug("--- due date less than today's date");
					$export_flag = -11;
					}
				}
			}

		## If shipment and delivery notification addresses are provided, they must be valid
		if ( defined($CustRef->{'shipmentnotification'}) and $CustRef->{'shipmentnotification'} ne '' )
			{
			unless (IntelliShip::Utils->is_valid_email($CustRef->{'shipmentnotification'}))
				{
				$c->log->debug("--- shipmentnotification email not valid");
				$export_flag = -14;
				}
			}

		if ( defined($CustRef->{'deliverynotification'}) and $CustRef->{'deliverynotification'} ne '' )
			{
			unless (IntelliShip::Utils->is_valid_email($CustRef->{'deliverynotification'}))
				{
				$c->log->debug("--- deliverynotification email not valid");
				$export_flag = -15;
				}
			}

		if ( $export_flag == 0 )
			{
			my $StatusID = 1;

			if ($CustRef->{'extcarrier'} =~ /^void$/i and $CustRef->{'extservice'} =~ /^void$/i)
				{
				$StatusID = 5;
				undef($CustRef->{'extcarrier'});
				undef($CustRef->{'extservice'});
				}

			if ($CustRef->{'commodityquantity'})
				{
				$CustRef->{'commodityquantity'} = ceil($CustRef->{'commodityquantity'}) || 0;
				}

			if ( defined($CustRef->{'description'}) and length($CustRef->{'description'}) > 100 )
				{
				$CustRef->{'description'} = substr($CustRef->{'description'},0,99);
				}

			my $CO = {
				customerid => $CustomerID,
				contactid  => $ContactID,
				statusid   => $StatusID,
				};

			#########################################################
			## Store To Address
			#########################################################
			my $toAddressData = {
					addressname => $CustRef->{'addressname'},
					address1    => $CustRef->{'address1'},
					address2    => $CustRef->{'address2'},
					city        => $CustRef->{'addresscity'},
					state       => $CustRef->{'addressstate'},
					zip         => $CustRef->{'addresszip'},
					country     => $CustRef->{'addresscountry'},
					};

			IntelliShip::Utils->trim_hash_ref_values($toAddressData);

			$c->log->debug("... checking for dropship address availability");

			## Fetch ship from address
			my @addresses = $c->model('MyDBI::Address')->search($toAddressData);

			my $ToAddress;
			if (@addresses)
				{
				$ToAddress = $addresses[0];
				$c->log->debug("... Existing Address Found, ID: " . $ToAddress->addressid);
				}
			else
				{
				$ToAddress = $c->model("MyDBI::Address")->new($toAddressData);
				$ToAddress->addressid($self->myDBI->get_token_id);
				$ToAddress->insert;
				$c->log->debug("... New Address Inserted, ID: " . $ToAddress->addressid);
				}

			$CO->{'addressid'} = $ToAddress->id;

			#########################################################
			## Store Drop Address
			#########################################################
			$c->log->debug("... checking for Drop address availability");

			my $returnAddressData = {
				addressname => $CustRef->{'dropname'},
				address1    => $CustRef->{'dropaddress1'},
				address2    => $CustRef->{'dropaddress2'},
				city        => $CustRef->{'dropcity'},
				state       => $CustRef->{'dropstate'},
				zip         => $CustRef->{'dropzip'},
				country     => $CustRef->{'dropcountry'},
				};

			IntelliShip::Utils->trim_hash_ref_values($returnAddressData);

			## Fetch return address
			@addresses = $c->model('MyDBI::Address')->search($returnAddressData);

			my $ReturnAddress;
			if (@addresses)
				{
				$ReturnAddress = $addresses[0];
				$c->log->debug("... Existing Address Found, ID: " . $ReturnAddress->addressid);
				}
			else
				{
				$ReturnAddress = $c->model("MyDBI::Address")->new($returnAddressData);
				$ReturnAddress->addressid($self->myDBI->get_token_id);
				$ReturnAddress->insert;
				$c->log->debug("... New Address Inserted, ID: " . $ReturnAddress->addressid);
				}

			$CO->{'rtaddressid'} = $ReturnAddress->id;
			###########################

			$CO->{'ordernumber'}           = $CustRef->{'ordernumber'};
			$CO->{'ponumber'}              = $CustRef->{'ponumber'};
			$CO->{'datetoship'}            = $CustRef->{'datetoship'} if $CustRef->{'datetoship'};
			$CO->{'estimatedweight'}       = $CustRef->{'estimatedweight'} || 0;
			$CO->{'estimatedinsurance'}    = $CustRef->{'estimatedinsurance'} || 0;
			$CO->{'description'}           = $CustRef->{'description'};
			$CO->{'exthsc'}                = $CustRef->{'exthsc'} if $CustRef->{'exthsc'};
			$CO->{'extcd'}                 = $CustRef->{'extcd'} if $CustRef->{'extcd'};
			$CO->{'extcarrier'}            = $CustRef->{'extcarrier'} if $CustRef->{'extcarrier'};
			$CO->{'extservice'}            = $CustRef->{'extservice'} if $CustRef->{'extservice'};
			$CO->{'dateneeded'}            = $CustRef->{'dateneeded'} if $CustRef->{'dateneeded'};
			$CO->{'extloginid'}            = $CustRef->{'extloginid'} if $CustRef->{'extloginid'};
			$CO->{'extcustnum'}            = $CustRef->{'extcustnum'} if $CustRef->{'extcustnum'};
			$CO->{'department'}            = $CustRef->{'department'} if $CustRef->{'department'};
			$CO->{'contactname'}           = $CustRef->{'contactname'} if $CustRef->{'contactname'};
			$CO->{'contactphone'}          = $CustRef->{'contactphone'} if $CustRef->{'contactphone'};
			$CO->{'extid'}                 = $CustRef->{'extid'} if $CustRef->{'extid'};
			$CO->{'dimlength'}             = $CustRef->{'dimlength'} || 0;
			$CO->{'dimwidth'}              = $CustRef->{'dimwidth'} || 0;
			$CO->{'dimheight'}             = $CustRef->{'dimheight'} || 0;
			$CO->{'unitquantity'}          = $CustRef->{'unitquantity'} || 1;
			$CO->{'commodityquantity'}     = $CustRef->{'commodityquantity'} || 0;
			$CO->{'chargeamount'}          = $CustRef->{'chargeamount'} || 0;
			$CO->{'stream'}                = $CustRef->{'stream'} if $CustRef->{'stream'};
			$CO->{'dateneededon'}          = $CustRef->{'dateneededon'} if $CustRef->{'dateneededon'};
			$CO->{'tpacctnumber'}          = $CustRef->{'tpacctnumber'} if $CustRef->{'tpacctnumber'};
			$CO->{'shipmentnotification'}  = $CustRef->{'shipmentnotification'} if $CustRef->{'shipmentnotification'};
			$CO->{'deliverynotification'}  = $CustRef->{'deliverynotification'} if $CustRef->{'deliverynotification'};
			$CO->{'importfile'}            = fileparse($import_file) if $import_file;
			$CO->{'securitytype'}          = $CustRef->{'securitytype'} if $CustRef->{'securitytype'};
			$CO->{'termsofsale'}           = $CustRef->{'termsofsale'} if $CustRef->{'termsofsale'};
			$CO->{'dutypaytype'}           = $CustRef->{'dutypaytype'} if $CustRef->{'dutypaytype'};
			$CO->{'dutyaccount'}           = $CustRef->{'dutyaccount'} if $CustRef->{'dutyaccount'};
			$CO->{'commodityunits'}        = $CustRef->{'commodityunits'} if $CustRef->{'commodityunits'};
			$CO->{'partiestotransaction'}  = $CustRef->{'partiestotransaction'} if $CustRef->{'partiestotransaction'};
			$CO->{'commodityunitvalue'}    = $CustRef->{'commodityunitvalue'} || 0;
			$CO->{'destinationcountry'}    = $CustRef->{'destinationcountry'} if $CustRef->{'destinationcountry'};
			$CO->{'commoditycustomsvalue'} = $CustRef->{'commoditycustomsvalue'} || 0;
			$CO->{'manufacturecountry'}    = $CustRef->{'manufacturecountry'} if $CustRef->{'manufacturecountry'};
			$CO->{'currencytype'}          = $CustRef->{'currencytype'} if $CustRef->{'currencytype'};
			$CO->{'dropcontact'}           = $CustRef->{'dropcontact'} if $CustRef->{'dropcontact'};
			$CO->{'dropphone'}             = $CustRef->{'dropphone'} if $CustRef->{'dropphone'};
			$CO->{'isdropship'}            = $CustRef->{'isdropship'} || 0;
			$CO->{'volume'}                = $CustRef->{'volume'} || 0;
			$CO->{'density'}               = $CustRef->{'density'} || 0;
			$CO->{'class'}                 = $CustRef->{'class'} || 0;
			$CO->{'custref2'}              = $CustRef->{'custref2'} if $CustRef->{'custref2'};
			$CO->{'custref3'}              = $CustRef->{'custref3'} if $CustRef->{'custref3'};
			$CO->{'freightcharges'}        = $CustRef->{'freightcharges'} || 0;
			$CO->{'transitdays'}           = $CustRef->{'transitdays'} || 0;
			$CO->{'cotypeid'}              = $CustRef->{'cotypeid'} || 1;

			if (defined($CustRef->{'hazardous'}))
				{
				if ( $CustRef->{'hazardous'} eq 'Y' or  $CustRef->{'hazardous'} eq 'y')
					{
					$CO->{'hazardous'} = 1;
					}
				else
					{
					$CO->{'hazardous'} = 0;
					}
				}
			if (defined($CustRef->{'keep'}))
				{
				if ( $CustRef->{'keep'} eq 'Y' or  $CustRef->{'keep'} eq 'y' or $CustRef->{'keep'} eq '1' )
					{
					$CO->{'keep'} = 1;
					}
				else
					{
					$CO->{'keep'} = 0;
					}
				}
				if (defined($CustRef->{'routeflag'}))
					{
					if ( $CustRef->{'routeflag'} eq 'Y' or  $CustRef->{'routeflag'} eq 'y')
						{
						$CO->{'routeflag'} = 1;
						$CO->{'extcarrier'} = undef;
						$CO->{'extservice'} = undef;
						}
					else
						{
						$CO->{'routeflag'} = 0;
						}
					}

			#$c->log->debug("... CO DATA DETAILS:  " . Dumper $CO);

			my $CO_Obj = $c->model('MyDBI::CO')->new($CO);
			$CO_Obj->coid($self->myDBI->get_token_id);
			$CO_Obj->insert;

			my $COID = $CO_Obj->coid;

			$c->log->debug("... NEW CO INSERTED, COID:  " . $COID);

			## Create package data
			my $packageData = {
				datatypeid  => '1000',
				ownertypeid => '1000',
				ownerid     => $COID,
				datecreated => IntelliShip::DateUtils->get_timestamp_with_time_zone,
				};

			## Default package quantity to one if none was given
			$packageData->{'quantity'}    = defined($CO->{'unitquantity'}) ? $CO->{'unitquantity'} : 1;
			$packageData->{'description'} = $CO->{'description'};
			$packageData->{'weight'}      = $CO->{'estimatedweight'};
			$packageData->{'decval'}      = $CO->{'estimatedinsurance'};

			my $PackProData = $c->model('MyDBI::Packprodata')->new($packageData);
			$PackProData->packprodataid($self->myDBI->get_token_id);
			$PackProData->insert;

			$c->log->debug("... NEW Package INSERTED, packprodataid:  " . $PackProData->packprodataid);

			## set assessorials
			if ( $CustRef->{'saturdayflag'} and $CustRef->{'saturdayflag'} == 1 )
				{
				$self->SaveAssessorial($COID,'saturdaysunday','Saturday Delivery','0')
				}
			if ( $CustRef->{'residentialflag'} and $CustRef->{'residentialflag'} == 1 )
				{
				$self->SaveAssessorial($COID,'residential','Residential Delivery','0')
				}
			if ( $CustRef->{'AMflag'} and $CustRef->{'AMflag'} == 1 )
				{
				$self->SaveAssessorial($COID,'amdelivery','AM Delivery','0')
				}
			}
		elsif ( $export_flag < 0 )
			{
			## We need a valid customerid for the failure to do any good...it's likely a header line
			if ($CustomerID)
				{
				$ImportFailureRef->{$CustomerID} .= "$CustRef->{'ordernumber'}";
				if ($CustRef->{'extcustnum'})
					{
					$ImportFailureRef->{$CustomerID} .= " ($CustRef->{'extcustnum'})";
					}
				$ImportFailureRef->{$CustomerID} .= ": $export_flag\n";
				}
			## Otherwise, just put out a warning for cron to pick up...Once we see enough headers, we can probably
			## code for them explicitly
			else
				{
				$UnknownCustCount++;

				if ( $UnknownCustCount == 1 )
					{
					$Error_File = fileparse($import_file);
					$Error_File = "unknowncustomer_".$Error_File;
					#open(OUT, ">" . $config->{BASE_PATH} . "/var/processing/$Error_File") or warn "unable to open error file";
					}
				$c->log->debug("___ Unknown line: $Line");
				#print OUT "$Line\n\n";
				#close (OUT);
				}
			}
		}

	if ( $UnknownCustCount > 0 )
		{
		$c->log->debug("*** UnknownCustCount ".$UnknownCustCount);
		#move("$config->{BASE_PATH}/var/processing/$Error_File","$config->{BASE_PATH}/var/export/unknowncust/$Error_File")
		#or &TraceBack("Could not move $Error_File: $!");
		}

	return ($ImportFailureRef,$OrderTypeRef);
	}

sub ImportProducts
	{
	my $self = shift;
	my $import_file = shift;

	return unless $import_file;

	my $c = $self->context;

	my $UnknownCustCount = 0;
	my $Error_File = '';
	my $OrderTypeRef = {};
	my $ordertype;

	my $FILE = new IO::File;

	$c->log->debug("\n");
	$c->log->debug("##### ImportProducts Read File: " . $import_file);

	unless (open($FILE, $import_file))
		{
		print STDERR "\n... Error: " . $!;
		return;
		}

	my @FileLines;
	while (<$FILE>)
		{
		chomp;
		push(@FileLines,$_);
		}

	close ($FILE);

	$c->log->debug("... Total file lines: " . @FileLines);

	my $LineCount = 0;
	my $ImportFailureRef = {};

	my $LastCOID = '';
	foreach my $Line (@FileLines)
		{
		$LineCount++;

		my $CustRef = {};

		## Trim spaces from front and back
		$Line =~ s/^\s+//;
		$Line =~ s/\s+$//;

		next unless $Line;

		($CustRef->{'extloginid'},
		$CustRef->{'ordernumber'},
		$CustRef->{'productquantity'},
		$CustRef->{'unittype'},
		$CustRef->{'weighttype'},
		$CustRef->{'productprice'},
		$CustRef->{'productdescr'},
		$CustRef->{'productweight'},
		$CustRef->{'partnumber'},
		$CustRef->{'linenum'},
		$CustRef->{'dimlength'},
		$CustRef->{'dimwidth'},
		$CustRef->{'dimheight'},
		$CustRef->{'hazardous'},
		$CustRef->{'serialnumber'},
		$CustRef->{'producttype'},
		$CustRef->{'cotype'}) = split(/\t/, $Line);

		my $export_flag = 0;

		IntelliShip::Utils->trim_hash_ref_values($CustRef);

		#$c->log->debug("...CustRef:  " . Dumper $CustRef);

		## set cotypeid
		if ( defined($CustRef->{'cotype'}) && $CustRef->{'cotype'} =~ /PO/i )
			{
			$CustRef->{'cotypeid'} = 2;
			$ordertype = 'PO';
			}
		elsif ( defined($CustRef->{'cotype'}) && $CustRef->{'cotype'} =~ /Quote/i )
			{
			$CustRef->{'cotypeid'} = 10;
			$ordertype = 'quote';
			}
		else
			{
			$CustRef->{'cotypeid'} = 1;
			$ordertype = 'order';
			}

		## set descr equal to part number if descr is not given and part number is
		if ( $CustRef->{'productdescr'} eq '' && $CustRef->{'partnumber'} ne '' )
			{
			$CustRef->{'productdescr'} = $CustRef->{'partnumber'};
			}

		if ( !defined($CustRef->{'productprice'}) || $CustRef->{'productprice'} eq '' )
			{
			$CustRef->{'productprice'} = 0;
			}

		if ( !defined($CustRef->{'productweight'}) || $CustRef->{'productweight'} eq '' )
			{
			$CustRef->{'productweight'} = undef;
			}

		################################################
		### Check for required fields & errors
		################################################
		## Check for valid extloginid

		my ($ContactID,$CustomerID) = $self->AuthenticateContact($CustRef->{'extloginid'});
		#$c->log->debug("... Authenticated Customer: " . $CustomerID . ", Contact: " . $ContactID);

		my $Contact = $c->model('MyDBI::Contact')->find({ contactid => $ContactID }) if $ContactID;
		my $Customer = $c->model('MyDBI::Customer')->find({ customerid => $CustomerID }) if $CustomerID;

		#$c->log->debug("... Contact DATA DETAILS:  " . Dumper $Contact);
		#$c->log->debug("... Customer DATA DETAILS:  " . Dumper $Customer);

		my $ProductStatus = 200;

		if (!defined($CustomerID) || $CustomerID eq '')
			{
			$export_flag = -1;
			}
		#else
		#	{
		#	my $Company = new CUSTOMER($DBRef->{'aos'}, $Customer);
		#	$Company->Load($CustomerID);

		#	my $PickPack = $Company->GetCustomerValue('pickpack');
		#	if ( defined($PickPack) && $PickPack == 1 )
		#		{
		#		$ProductStatus = 0;
		#		}
		#	}

		## Must have an order number
		if (!defined($CustRef->{'ordernumber'}) || $CustRef->{'ordernumber'} eq '')
			{
			$export_flag = -2;
			}

		if (defined($CustRef->{'ordernumber'}) && $CustRef->{'ordernumber'} ne '' && $export_flag ne '-1')
			{
			$c->log->debug("... search for CO by ordernumber:  " . $CustRef->{'ordernumber'});
			 my $sth = $self->myDBI->select("
				SELECT
					coid
				FROM
					co
				WHERE
					customerid = '$CustomerID'
					AND ordernumber = '$CustRef->{'ordernumber'}'
					AND cotypeid = '$CustRef->{'cotypeid'}'
				ORDER BY
					datecreated DESC
				LIMIT 1
			 ");

			my $coid = $sth->fetchrow(0)->{'coid'} if $sth->numrows;
			$CustRef->{'coid'} = $coid;

			$c->log->debug("... CO found, ID:  " . $coid);

			if (!defined($CustRef->{'coid'}) || $CustRef->{'coid'} eq '')
				{
				$export_flag = -2;
				}
			}

		## use this to issue delete of products for an order only once.
		$LastCOID = $CustRef->{'coid'};

		if ($CustRef->{'productquantity'})
			{
			$CustRef->{'productquantity'} =~ s/[^\d\.]//g;
			$CustRef->{'productquantity'} = int $CustRef->{'productquantity'};
			}
		else
			{
			$CustRef->{'productquantity'} = 0;
			}

		unless ($CustRef->{'productquantity'} =~ /^\d+$/)
			{
			$export_flag = -3;
			}

		if (!defined($CustRef->{'partnumber'}) || $CustRef->{'partnumber'} eq '')
			{
			$export_flag = -4;
			}

		if (!defined($CustRef->{'productdescr'}) || $CustRef->{'productdescr'} eq '')
			{
			$export_flag = -5;
			}

		if ($CustRef->{'unittype'})
			{
			my $STH = $self->myDBI->select("
				SELECT
					unittypeid
				FROM
					unittype
				WHERE
					upper(unittypename) = upper('$CustRef->{'unittype'}')
				LIMIT 1
				");

			my $unittypeid = $STH->fetchrow(0)->{'unittypeid'} if $STH->numrows;
			$CustRef->{'unittypeid'} = $unittypeid;

			$c->log->debug("... unittypeid:  " . $unittypeid);
			}
		else
			{
			$CustRef->{'unitttypeid'} = 3;
			}

		if ($CustRef->{'weighttype'} && $CustRef->{'weighttype'} =~ /(KG|KGS)/i)
			{
			$CustRef->{'weighttypeid'} = 2;
			}
		else
			{
			$CustRef->{'weighttypeid'} = 1;
			}

		my $CO;
		if ( $export_flag == 0 )
			{
			## if missing info, see if the customer has sku data in our db
			if ($CustRef->{'unittypeid'} &&
				(!$CustRef->{'productweight'} || !$CustRef->{'dimlength'} || !$CustRef->{'dimwidth'} || !$CustRef->{'dimheight'})
				)
				{
				my $sth = $c->myDBI->select("SELECT 1 FROM productsku WHERE customerid = '$CustomerID' AND unittypeid = '" . $CustRef->{'unitttypeid'} . "'");
				if ($sth->numrows)
					{
					$c->log->debug("... LOOKUP SKU DATA based on $CustRef->{'unittypeid'} and $CustRef->{'partnumber'} and $CustomerID");

					my $sql;
					my $FILTER  = "upper(customerskuid) = upper('$CustRef->{partnumber}') AND unittypeid = '$CustRef->{unittypeid}' AND customerid = '$CustomerID'";
					if ( $CustRef->{'unittypeid'} == 3 )
						{
						$sql = "SELECT weight wt, length ln, width wd, height ht FROM productsku WHERE $FILTER LIMIT 1";
						}
					elsif ( $CustRef->{'unittypeid'} == 2 )
						{
						$sql = "SELECT weight wt, caselength ln, casewidth wd, caseheight ht FROM productsku WHERE $FILTER LIMIT 1";
						}
					elsif ( $CustRef->{'unittypeid'} == 1 )
						{
						$sql = "SELECT palletweight wt, palletlength ln, palletwidth wd, palletheight ht FROM productsku WHERE FILTER LIMIT 1";
						}

					my $STH = $self->myDBI->select($sql);

					my ($weight, $length, $width, $height) = (0, 0, 0, 0);
					if ($STH->numrows)
						{
						my $d = $STH->fetchrow(0);
						($weight, $length, $width, $height) = ($d->{wt},$d->{ln},$d->{wd},$d->{ht});
						}
					$CustRef->{'productweight'} = $weight * $CustRef->{'productquantity'} if $weight;
					$CustRef->{'dimlength'} = $length if $length;
					$CustRef->{'dimwidth'} = $width if $width;
					$CustRef->{'dimheight'} = $height if $height;
					}
				}

			## if it's the 1st hit on a particular order then delete any existing product records
			if ( $LineCount== 1 || ($LastCOID ne $CustRef->{'coid'}) )
				{
				$CO=$c->model('MyDBI::Co')->find({coid => $CustRef->{'coid'}}) if $CustRef->{'coid'};

				#$c->log->debug("... CO DATA DETAILS:  " . Dumper $CO);
				}

			my $productData = { datatypeid => '2000' };

			## coid and packageid are passed in.  ideally products will associate to a package.
			## if none exist, the coid is passed so that the products will tie to the order instead.

			## OwnerTypeID:
			## 1000 = order (CO)
			## 2000 = shipment
			## 3000 = product (for packages)

			## DataTypeId
			## 1000 = Package
			## 2000 = Product
			my @packages = $CO->packages if $CO;
			if (@packages)
				{
				$c->log->debug("... package found, packprodataid: " . $packages[0]->packprodataid);
				$productData->{'ownerid'}     = $packages[0]->packprodataid;
				$productData->{'ownertypeid'} = '3000';
				}
			else
				{
				$c->log->debug("... package not found");
				$productData->{'ownerid'}     = $CustRef->{'coid'};
				$productData->{'ownertypeid'} = '1000';
				}

			$productData->{'quantity'}         = $CustRef->{'productquantity'};
			$productData->{'reqqty'}           = $CustRef->{'productquantity'};
			$productData->{'unittypeid'}       = $CustRef->{'unittypeid'};
			$productData->{'weighttypeid'}     = $CustRef->{'weighttypeid'} || 0;
			$productData->{'decval'}           = $CustRef->{'productprice'};
			$productData->{'description'}      = $CustRef->{'productdescr'};
			$productData->{'weight'}           = $CustRef->{'productweight'};
			$productData->{'partnumber'}       = $CustRef->{'partnumber'};
			$productData->{'statusid'}         = $ProductStatus;
			#$productData->{'shippedquantity1'} = 0;
			$productData->{'linenum'}          = $CustRef->{'linenum'};
			$productData->{'dimlength'}        = $CustRef->{'dimlength'} || 0;
			$productData->{'dimwidth'}         = $CustRef->{'dimwidth'} || 0;
			$productData->{'dimheight'}        = $CustRef->{'dimheight'} || 0;
			$productData->{'serialnumber'}     = $CustRef->{'serialnumber'};
			$productData->{'producttype'}      = $CustRef->{'producttype'};
			$productData->{'datecreated'}      = IntelliShip::DateUtils->get_timestamp_with_time_zone;

			$productData->{'description'} =~ s/'//g if $productData->{'description'};

			if ($CustRef->{'hazardous'})
				{
				$productData->{'hazardous'} = ($CustRef->{'hazardous'} =~ /Y/i ? 1 : 0);
				}

			#$c->log->debug("....productdata  : ".Dumper $productData );

			my $Product = $c->model('MyDBI::Packprodata')->new($productData);
			$Product->packprodataid($self->myDBI->get_token_id);
			$Product->insert;

			$c->log->debug("... NEW Product INSERTED, packprodataid:  " . $Product->packprodataid . " for COID: " . $CustRef->{'coid'});
			}
		elsif ( $export_flag < 0 )
			{
			## We need a valid customerid for the failure to do any good...it's likely a header line
			 if ( defined($CustomerID) && $CustomerID ne '' )
				{
				$ImportFailureRef->{$CustomerID} .= "$CustRef->{'ordernumber'}: $export_flag\n";
				}
			 ## Otherwise, just put out a warning for cron to pick up...Once we see enough headers, we can probably
			 ## code for them explicitly
			 else
				{
				$UnknownCustCount++;

				if ( $UnknownCustCount == 1 )
					{
					$Error_File = fileparse($import_file);
					$Error_File = "product_unknowncustomer_".$Error_File;

					#open(OUT,">$config->{BASE_PATH}/var/processing/$Error_File") or warn "unable to open error file";
					}
				print STDERR "\n___ Unknown line: $Line\n\n";
				#print OUT "$Line\n\n";
				}
			}
		}

	if ( $UnknownCustCount > 0 )
		{
		print STDERR"\n  ###UnknownCustCount ".$UnknownCustCount;
		#close (OUT);
		#move("$config->{BASE_PATH}/var/processing/$Error_File","$config->{BASE_PATH}/var/export/unknowncust/$Error_File")
		##   or &TraceBack("Could not move $Error_File: $!");
		}

	return ($ImportFailureRef,$ordertype);
	}

## Send email with list of failed imports
sub EmailImportFailures
	{
	my $self = shift;
	my ($ImportFailures,$filepath,$filename,$OrderTypeRef) = @_;

	return;## print STDERR "\n..... Skip EmailImportFailures: $ImportFailures, $filepath, $filename, $OrderTypeRef";

	#foreach my $customerid (keys(%$ImportFailures))
	#	{
	#	my $Display = new DISPLAY($TEMPLATE_DIR);
	#
	#	my ($Day,$Month,$Year,$Hour,$Minute) = (localtime)[3,4,5,2,1];
	#	$Month = $Month + 1;
	#	$Year = $Year + 1900;
	#	if ( length($Minute) == 1 ) { $Minute = "0".$Minute; }
	#	my $Timestamp = $Month."/".$Day."/".$Year." ".$Hour.":".$Minute;
	#
	#	my $Customer = new CUSTOMER($DBRef->{'aos'}, $Customer);
	#	$Customer->Load($customerid);
	#	my $CustomerName = $Customer->GetValueHashRef()->{'customername'};
	#
	#	my $toemail;
	#	if ( $Customer->GetValueHashRef()->{'email'} )
	#		{
	#		$toemail = $Customer->GetValueHashRef()->{'email'};
	#		}
	#
	#	my $fromemail = "intelliship\@intelliship.$config->{BASE_DOMAIN}";
	#	my $fromname = 'NOC';
	#	my $subject = "ALERT: " . $CustomerName . " " . $OrderTypeRef->{'ordertype'} ." Import Failures "  . "(".$Timestamp.", ".$filename.")";
	#	my $cc = 'noc@engagetechnology.com';
	#
	#	my $BodyHash = {};
	#	$BodyHash->{'failures'} = $ImportFailures->{$customerid};
	#	$BodyHash->{'ordertype'} = $OrderTypeRef->{'ordertype'};
	#	$BodyHash->{'ordertype_lc'} = $OrderTypeRef->{'ordertype_lc'};
	#	#warn $BodyHash->{'failures'};
	#	my $body = $Display->TranslateTemplate('import_failures.email', $BodyHash);
	#
	#	#SendFileAsEmailAttachment($fromemail,$toemail,$cc,undef,$subject,$body,$filepath."/".$filename,$filename,$fromname);
	#	}
	}

sub SaveAssessorial
	{
	my $self = shift;
	my ($OwnerID,$AssName,$AssDisplay,$AssValue) = @_;

	my $AssData = $self->context->model('MyDBI::ASSDATA')->new({
						ownertypeid => '1000',
						ownerid     => $OwnerID,
						assname     => $AssName,
						assdisplay  => $AssDisplay,
						assvalue    => $AssValue,
						});

	## Delete old assessorial for order
	#if
	#(
	#$AssData->LowLevelLoadAdvanced(undef,{
	#	ownertypeid => '1000',
	#	 ownerid	  => $OwnerID,
	#	 assname	  => $AssName,
	#  })
	#)
	#{
	#	$AssData->Delete();
	#}
	$AssData->assdataid($self->myDBI->get_token_id);
	$AssData->insert;
	$self->context->log->debug("... NEW AssData INSERTED, assdataid:  " . $AssData->assdataid);
	}

sub AuthenticateContact
	{
	my $self = shift;
	my $Username = shift;

	my $c = $self->context;

	my ($ContactID, $CustomerID);

	$c->log->debug("... Authenticate Contact, USERNAME: " . $Username);

	if ($self->AuthContacts and $self->AuthContacts->{$Username})
		{
		($ContactID, $CustomerID) = @{$self->AuthContacts->{$Username}};
		return ($ContactID,$CustomerID);
		}

	my $myDBI = $self->myDBI;
	my $SQL;
	## New contact user
	if ($Username =~ /\//)
		{
		my ($Domain, $Contact) = $Username =~ m/^(.*)\/(.*)$/;

		$SQL = "
			SELECT
				c.contactid,
				cu.customerid
			FROM
				customer cu
				INNER JOIN contact c ON cu.customerid = c.customerid
			WHERE
				cu.username = '$Domain'
				AND c.username = '$Contact'
				AND c.datedeactivated is null
		";
		}
	else
		{
		## Standard/Backwards compatible user
		$SQL = "
			SELECT
				c.contactid,
				cu.customerid
			FROM
				customer cu
				INNER JOIN contact c ON cu.customerid = c.customerid
			WHERE
				c.username = '$Username'
				AND cu.username = '$Username'
				AND c.datedeactivated is null
		";
		}
	#print STDERR "\n... SQL: " . $SQL;
	my $STHC = $myDBI->select($SQL);

	return ($ContactID,$CustomerID) unless $STHC->numrows;

	my $DATA = $STHC->fetchrow(0);
	($ContactID,$CustomerID) = ($DATA->{contactid},$DATA->{customerid});

	$self->AuthContacts->{$Username} = [$ContactID,$CustomerID];

	return ($ContactID,$CustomerID);
	}

sub ValidateCountry
	{
	my $self = shift;
	my $Country = shift;

	$Country =~ s/^\s+//;
	$Country =~ s/\s+$//;

	return undef unless $Country;

	$Country = uc($Country);

	my $SQL = "
		SELECT
			countryiso2
		FROM
			country
		WHERE
			upper(countryiso2) = '$Country'
			OR upper(countryname) = '$Country'
			OR upper(countryiso3) = '$Country'
		";

	my $STH = $self->myDBI->select($SQL);
	my $ISO2 = $STH->fetchrow(0)->{countryiso2} if $STH->numrows;

	return $ISO2;
	}

sub VerifyDate
	{
	my $self = shift;
	my $date = shift;
	return $date if IntelliShip::DateUtils->is_valid_date($date);
	}

sub format_file
	{
	my $self = shift;
	my $file = shift;

	my $c = $self->context;

	$c->log->debug("... format file, Name: " . $file);

	my $inputfilename = basename( $file );
	$inputfilename =~ s/.csv//;

	my $outdir = '/tmp';

	my $FH       = new IO::File;
	my $PRODFILE = new IO::File;
	my $ORDRFILE = new IO::File;

	my $order_out_file = $outdir . '/OrderImport-' . $inputfilename . '.txt';
	my $product_out_file = $outdir . '/ProductImport-' . $inputfilename . '.txt';

	unless (open $FH, '<:encoding(utf8)', $file)
		{
		$c->log->debug("*** Could not open '$file' $!");
		$self->add_error($!);
		return;
		}
	unless (open $PRODFILE, "+>$product_out_file")
		{
		$c->log->debug("*** Error: " . $!);
		$self->add_error($!);
		return;
		}
	unless (open $ORDRFILE, "+>$order_out_file")
		{
		$c->log->debug("*** Error: " . $!);
		$self->add_error($!);
		return;
		}

	my $i = 0;
	my $CSV = Text::CSV->new( { binary    => 1, auto_diag => 1 } );

	while (my $fields = $CSV->getline( $FH ))
		{
		#chomp;
		next if $i++ == 0;
		#$_ =~ s/^\s+//;
		#$_ =~ s/\s+$//;
		#$c->log->debug("File Line: " . $_) if $_;

		#unless ($CSV->parse($_))
		#	{
		#	$c->log->debug("CSV Parse Error: " . $CSV->error_input);
		#	next;
		#	}

		#my $fields = $CSV->fields();
		#$my $fields = [split ',', $_];

		#next unless @$fields;

		#$c->log->debug(".... Fields: " . Dumper $fields);

		if ($fields->[10] eq '')
			{
			if ($fields->[19] ne '')
				{
				$self->printImports($fields, $PRODFILE, $ORDRFILE);
				}
			}
		elsif ($fields->[10] ne '')
			{
			$self->printImports($fields, $PRODFILE, $ORDRFILE);
			}
		}

	close $FH;
	close $PRODFILE;
	close $ORDRFILE;

	$c->log->debug("... Generated OrderImport file $order_out_file for $file");
	$c->log->debug("... Generated ProductImport file $product_out_file for $file");

	return ($order_out_file,$product_out_file);
	}

sub printImports
	{
	my $self = shift;
	my $fields = shift;
	my $PRODFILE = shift;
	my $ORDRFILE = shift;

	my $c = $self->context;

	my $return1 = '';
	my $return2 = '';
	#Product Information Printing
	my $EquipName = '';
	my @EquipmentArray;
	my $EquipString = '';
	my @EquipArray2;
	my $EquipQtyName = '';
	my @EquipQtyArray;
	my $EquipQtyString = '';
	my @EquipQtyArray2;
	my $Return = '';
	my $Comment = '';
	my $ShipToCharge = '';
	my $CusRef2 = '';
	my $CusRef3 = '';

	if ($fields->[10] eq '')
		{
		$Return = $fields->[17];
		$Comment = $fields->[18];
		$EquipName = $fields->[19];
		$EquipQtyName = $fields->[20];
		}
	else
		{
		$Return = $fields->[16];
		$Comment = $fields->[17];
		$EquipName = $fields->[18];
		$EquipQtyName = $fields->[19];
		}

	if ($EquipName eq '' || $EquipQtyName eq '')
		{
		$EquipName = '';
		$EquipQtyName = '';
		#$return1 = "sprint/user\t$fields->[0]\t\t\t\t\t\t\t\n";
		#print PRODFILE "$return1";
		}
	elsif ($EquipName ne '' && $EquipQtyName ne '')
		{
		$EquipName =~ s/\n\n/\n/g;
		$EquipName =~ s/[\r\n]+/,/g;
		@EquipmentArray = split(',', $EquipName);

		foreach  (@EquipmentArray)
			{
			$EquipString = $_;
			$EquipString =~ s/^\s+//;
			$EquipString =~ s/\s+$//;
			$EquipString =~ s/\r\n/,/g;
			chomp($EquipString);
			$EquipString =~ s/\s+$//;
			push(@EquipArray2, $EquipString);
			}

		$EquipQtyName =~ s/\n\n/\n/g;
		$EquipQtyName =~ s/[\r\n]+/,/g;
		@EquipQtyArray = split(',', $EquipQtyName);

		foreach (@EquipQtyArray)
			{
			$EquipQtyString = $_;
			$EquipQtyString =~ s/^\s+//;
			$EquipQtyString =~ s/\s+$//;
			$EquipQtyString =~ s/\r\n/,/g;
			chomp($EquipQtyString);

			$EquipQtyString =~ s/\s+$//;
			push(@EquipQtyArray2, $EquipQtyString);
			}

		for (my $k = 0; $k < @EquipArray2; $k++)
			{
			$EquipArray2[$k] =~  s/\s+$//;
			$return1 = "sprint/user\t$fields->[0]\t$EquipQtyArray2[$k]\t\t\t\t$EquipArray2[$k]\t\t$EquipArray2[$k]\n";
			print $PRODFILE "$return1";
			}
		}

	#Order information printing

	my $ProjectNumber = '';
	my $ProjectName = '';
	my $endUserName = '';
	my $Address1 = '';
	my $Address2 = '';
	my $City = '';
	my $State = '';
	my $Zip = '';
	my $EquipmentConf = '';
	my $constant = 'sprint/user';
	my $MailStop = '';
	my $endUserPhone = '';
	my $CustomerWantDate = '';
	my $CustomerWantNumber = '';
	my $duedate = '';
	#my $ShipFromName = '';

	$ProjectNumber = $fields->[0];
	$ProjectName = $fields->[1];
	$endUserName = $fields->[2];
	$endUserName =~ s/\s+$//g;
	$Address1 = $fields->[8];
	$Address2 = $fields->[9];

	if ( $fields->[10] eq '' )
		{
		$City = $fields->[11];
		$State = $fields->[12];
		$Zip = $fields->[13];
		$Zip = sprintf("%05d", $Zip);
		$EquipmentConf = $fields->[21];
		#$EquipmentConf = substr($EquipmentConf, 0, 100);
		$MailStop = $fields->[6];
		$endUserPhone = $fields->[3];
		$CustomerWantDate = $fields->[15];
		}
	else{
		$City = $fields->[10];
		$State = $fields->[11];
		$Zip = $fields->[12];
		#$Zip = sprintf("%05d", $Zip);
		my ($ZipNew,$txt) = split(/\-/,$Zip);
		$Zip = $ZipNew;
		$EquipmentConf = $fields->[20];
		#$EquipmentConf = substr($EquipmentConf, 0, 100);
		$MailStop = $fields->[6];
		$endUserPhone = $fields->[3];
		$CustomerWantDate = $fields->[14];
		}

	if ( $endUserName eq '')
		{
		#print "$endUserName";
		#my $temp = "$ProjectName";
		#$temp =~ s/Shipment to //g;
		#$endUserName = "$temp";
		$endUserName = "OCCUPANT";
		#$ShipFromName = "OCCUPANT";
		}

	if ( $Return eq 'Y' || $Return eq 'Yes' || $Return eq '1')
		{
		$Return = $Return;
		}
	elsif ( $Return eq 'N' || $Return eq 'No' || $Return eq '0')
		{
		$Return = $Return;
		}
	elsif ($Return eq '')
		{
		$Return = "";
		}

	if ( $Comment ne '')
		{
		$Comment = "$Comment";
		}
	else
		{
		$Comment = '';
		}

	if ( $CustomerWantDate eq "OVERNIGHT" || $CustomerWantDate eq "Overnight" || $CustomerWantDate eq "OverNight")
		{
		$CustomerWantNumber = 1;
		}
	elsif ( $CustomerWantDate eq "TWO" || $CustomerWantDate eq "SECOND" )
		{
		$CustomerWantNumber = 2;
		}
	elsif ( $CustomerWantDate eq "THREE" || $CustomerWantDate eq "THIRD" )
		{
		$CustomerWantNumber = 3;
		}
	elsif ( $CustomerWantDate eq "GROUND" || $CustomerWantDate eq "Ground" )
		{
		$CustomerWantNumber = 5;
		}
	elsif ( looks_like_number($CustomerWantDate) )
		{
		$CustomerWantNumber = $CustomerWantDate;
		}
	elsif ( $CustomerWantDate =~/^((((0[13578])|([13578])|(1[02]))[\/](([1-9])|([0-2][0-9])|(3[01])))|(((0[469])|([469])|(11))[\/](([1-9])|([0-2][0-9])|(30)))|((2|02)[\/](([1-9])|([0-2][0-9]))))[\/]\d{4}$|^\d{4}$/)
		{
		$CustomerWantNumber = '';
		#$duedate = $CustomerWantDate;
		my @ddate =split('/' , $CustomerWantDate);
		$ddate[0]=~ s/^[0\s]+//;
		$ddate[1]=~ s/^[0\s]+//;
		$ddate[2]=~ s/^[0\s]+//;
		my $ddate = "$ddate[2]/$ddate[0]/$ddate[1]";
		#print "$ddate\n";

		my $todaydate = strftime "%m/%d/%Y", localtime;
		my @datenow =split('/' , $todaydate);
		 $datenow[0]=~ s/^[0\s]+//;
		 $datenow[1]=~ s/^[0\s]+//;
		 $datenow[2]=~ s/^[0\s]+//;
		my $presentdate = "$datenow[2]/$datenow[0]/$datenow[1]";
		#print "$presentdate\n";

		my $otherdate = Time::Piece->strptime($ddate, "%Y/%m/%d");
		my $now = Time::Piece->strptime($presentdate, "%Y/%m/%d");

		my $diff = $now - $otherdate;
		if ( $diff gt 0)
			{
			#print "$diff\n";
			$duedate = '';
			}
		elsif ( $diff lt 0 || $diff eq 0)
			{
			#print "$diff\n";
			$duedate = $CustomerWantDate;
			}
		}
	else
		{
		$CustomerWantNumber = '';
		}

	if ($EquipmentConf ne '')
		{
		$EquipmentConf  =~ s/[\r\n]+/,/g;
		$EquipmentConf  =~ s/,//g;
		}

	if ($EquipmentConf eq '')
		{
		$return2 = "$ProjectNumber\t\t$endUserName\t$Address1\t$Address2\t$City\t$State\t$Zip\t\t\t\t\t\t\t\t\t\t\t$duedate\t$constant\t$MailStop\t$ProjectName\t\t$endUserName\t$endUserPhone\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t$CustomerWantNumber\t\t\t\t\t$Comment\t$ShipToCharge\t$Return\t$CusRef2\t$CusRef3\n";
		print $ORDRFILE "$return2";
		}
	else
		{
		my @EquipmentConfArray = split(',',$EquipmentConf);

		for (my $m = 0; $m<@EquipmentConfArray; $m++)
			{
			my $temporary_var = $EquipmentConfArray[$m];
			$return2 = "$ProjectNumber\t\t$endUserName\t$Address1\t$Address2\t$City\t$State\t$Zip\t\t\t\t\t$temporary_var\t\t\t\t\t\t$duedate\t$constant\t$MailStop\t$ProjectName\t\t$endUserName\t$endUserPhone\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t$CustomerWantNumber\t\t\t\t\t$Comment\t$ShipToCharge\t$Return\t$CusRef2\t$CusRef3\n";
			#print "$return2";
			print $ORDRFILE "$return2";
			}
		}
	}

__PACKAGE__->meta()->make_immutable();

no Moose;

1;

__END__