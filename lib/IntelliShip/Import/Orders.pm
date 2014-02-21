package IntelliShip::Import::Orders;

use Moose;
use Text::CSV;
use File::Copy;
use File::Basename;
use POSIX qw (ceil);
use Date::Calc qw(Delta_Days);

use IntelliShip::Utils;
use IntelliShip::MyConfig;
use IntelliShip::DateUtils;

extends 'IntelliShip::Errors';

has 'import_file' => ( is => 'rw' );
has 'customer'    => ( is => 'rw' );
has 'contact'     => ( is => 'rw' );
has 'myDBI_obj'   => ( is => 'rw' );
has 'context'     => ( is => 'rw' );
has 'API'         => ( is => 'rw' );

my $config;

sub BUILD
	{
	my $self = shift;
	$config = IntelliShip::MyConfig->get_ARRS_configuration;
	}

sub myDBI
	{
	my $self = shift;
	return $self->myDBI_obj if $self->myDBI_obj;
	$self->myDBI_obj($self->context->model('MyDBI'));
	return $self->myDBI_obj;
	}

sub parse_row
	{
	my $self = shift;
	my $row_data = shift;
	return split /\t/, $row_data;
=as
	my $CSV = Text::CSV->new();

	unless ($CSV->parse($row_data))
		{
		print "\n$row_data\n";
		print $CSV->error_input . "\n";
		return;
		}

	return $CSV->fields();
=cut
	}

sub import
	{
	my $self = shift;
	my @files;
	my $import_file = $self->import_file;

	my $import_path = $self->get_directory;
	my $imported_path = IntelliShip::MyConfig->base_path . "/var/imported/co";
	print STDERR "\n... import_path: " . $import_path;

	if ($import_file)
		{
		push(@files, $import_file);
		}
	else
		{
		push(@files, <$import_path/*>);
		}

	print STDERR "\n... Total Files: " . @files;

	#################################
	### Check for Files to Import
	#################################
	foreach my $file (@files)
		{
		print STDERR "\n... Fetch file: " . $file;
		next if (! -f $file or ! -r $file );

		print STDERR "\n... ImportOrders for : " . $file;

		my ($ImportFailures,$OrderTypeRef) = $self->ImportOrders($file);

		my $import_base_file = fileparse($file);

		#unless (move($file,"$imported_path/$import_base_file"))
		#	{
		#	print STDERR "Could not move $file to $imported_path/$import_base_file: $!";
		#	}

		$self->EmailImportFailures($ImportFailures,$imported_path,$import_base_file,$OrderTypeRef);
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
		print STDERR "Unable to create target directory, " . $!;
		return;
		}

	return $TARGET_dir;
	}

sub ImportOrders
	{
	my $self = shift;
	my $import_file = shift;

	my $UnknownCustCount = 0;
	my $Error_File = '';
	my $OrderTypeRef = {};

	print STDERR "\n... Read File: " . $import_file;

	my $new_import_file = $self->format_file($import_file);

	my $FILE = new IO::File;

	unless (open($FILE, $new_import_file))
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

	print STDERR "\n... Total file lines: " . @FileLines;

	my $LineCount = 0;
	my $ImportFailureRef = {};

	foreach my $Line (@FileLines)
		{
		$LineCount++;

		my $CustRef = {};
		my $PackageRef = {};

		# Trim spaces from front and back
		$Line =~ s/^\s+//;
		$Line =~ s/\s+$//;

		# skip blank lines
		next unless $Line;

		# split the tab delimited line into fieldnames
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
		) = $self->parse_row($Line);

		my $export_flag = 0;

		print STDERR "\n... CO information gathered";

		IntelliShip::Utils->trim_hash_ref_values($CustRef);

		# Sort out generic values - in the MAERSK era, we were saddled with a very bad design where the
		# dim fields were co-opted for other uses (volume,density,class, at this point)
		# So.  If all three generic fields are filled, they correspond to the previous dims.
		# If only generic1 is filled, that's volume.  Only generic2=density.  Only generic3=classo
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

		# undef freightcharges if not valid value, (0,1,2)(prepaid,collect,tp)
		if ( defined $CustRef->{'freightcharges'}
			and $CustRef->{'freightcharges'} ne '0'
			and $CustRef->{'freightcharges'} ne '1'
			and $CustRef->{'freightcharges'} ne '2' )
			{
			$CustRef->{'freightcharges'} = undef;
			}

		if ( defined($CustRef->{'transitdays'}) and $CustRef->{'transitdays'} ne '' )
			{
			$CustRef->{'transitdays'} =~ s/[^0-9]//g; # Remove non-numbers;
			# undef transitdays if not nothing left after removing everything expect integers
			if ( defined($CustRef->{'transitdays'}) and $CustRef->{'transitdays'} eq '' )
				{
				$CustRef->{'transitdays'} = undef;
				}
			}

		# set cotypeid
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

		# Default country to US if it is null
		$CustRef->{'addresscountry'} = uc($CustRef->{'addresscountry'});
		if ( !defined($CustRef->{'addresscountry'}) or $CustRef->{'addresscountry'} eq '' )
			{
			$CustRef->{'addresscountry'} = 'US';
			}
		# Trim contact name to 50
		if ( defined($CustRef->{'contactname'}) and $CustRef->{'contactname'} ne '' )
			{
			$CustRef->{'contactname'} = substr($CustRef->{'contactname'},0,50);
			}

		#################################################
		### Check for required fields and verify dates
		################################################

		if (!defined($CustRef->{'extloginid'}) or $CustRef->{'extloginid'} eq '')
			{
			$export_flag = -9;
			}

		# Figure out who this is
		my ($ContactID,$CustomerID) = $self->AuthenticateContact($CustRef->{'extloginid'});

		my $Contact = $self->context->('MyDBI::Contact')->find({ contactid => $ContactID }) if $ContactID;
		my $Customer = $self->context->('MyDBI::Contact')->find({ customerid => $CustomerID }) if $CustomerID;

		# If we don't have an incoming class, check if we have a default class...and stuff it in if we do
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
			$export_flag = -9;
			}

		if ($Customer)
			{
			($CustRef->{'errorshipdate'},$CustRef->{'errorduedate'}) = ($Customer->errorshipdate, $Customer->errorduedate);
			}

		# Convert Customer Security Type to Intelliship Security Type
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
				$export_flag = -10;
				}
			}

		# Must have an order number
		unless ($CustRef->{'ordernumber'})
			{
			$export_flag = -1;
			}

		# Order needs an addr1 or an addr2
		if (!$CustRef->{'address1'} or !$CustRef->{'address2'})
			{
			$export_flag = -2;
			}

		# Validate Country
		if ($CustRef->{'addresscountry'})
			{
			my $ValidCountry = $self->ValidateCountry($CustRef->{'addresscountry'});

			if ($ValidCountry)
				{
				$CustRef->{'addresscountry'} = $ValidCountry;
				}
			else
				{
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
				$export_flag = -20;
				}
			}

		# US Specific Requirements and quirks
		if ( $CustRef->{'addresscountry'} eq 'US' )
			{
			# Order needs a city, state, and zip
			if (!$CustRef->{'addresscity'} or !$CustRef->{'addressstate'} or !$CustRef->{'addresszip'})
				{
				$export_flag = -3;
				}

			# if we've got a 4 digit US zip then pad with zero
			if ( defined($CustRef->{'addresszip'}) and $CustRef->{'addresszip'} =~ /^\d{4}$/ )
				{
				$CustRef->{'addresszip'} = "0" . $CustRef->{'addresszip'};
				}

			# Zip needs to be 5 or 5+4
			if ( defined($CustRef->{'addresszip'}) and $CustRef->{'addresszip'} !~ /\d{5}(\-\d{4})?/ )
				{
				$export_flag = -4;
				}
			}

		if (!defined($CustRef->{'addressname'}) or $CustRef->{'addressname'} eq '')
			{
			$export_flag = -6;
			}

		# if anything is given for dropship address then validate that it is a good address
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
					$export_flag = -20;
					}
				}
			# Needs an addr1 or an addr2
			if ( (!defined($CustRef->{'dropaddress1'}) or $CustRef->{'dropaddress1'} eq '') and
			(!defined($CustRef->{'dropaddress2'}) or $CustRef->{'dropaddress2'} eq '') )
				{
				$export_flag = -16;
				}

			if ( $CustRef->{'dropcountry'} eq 'US' )
				{
				# Needs a city, state, and zip
				if
				(
					(!defined($CustRef->{'dropcity'}) or $CustRef->{'dropcity'} eq '') or
				(!defined($CustRef->{'dropstate'}) or $CustRef->{'dropstate'} eq '') or
				(!defined($CustRef->{'dropzip'}) or $CustRef->{'dropzip'} eq '')
				)
					{
					$export_flag = -17;
					}

				# if we've got a 4 digit US zip then pad with zero
				if ( defined($CustRef->{'dropzip'}) and $CustRef->{'dropzip'} =~ /^\d{4}$/ )
					{
					$CustRef->{'dropzip'} = "0" . $CustRef->{'dropzip'};
					}
				# Zip needs to be 5 or 5+4
				if ( defined($CustRef->{'dropzip'}) and $CustRef->{'dropzip'} !~ /\d{5}(\-\d{4})?/ )
					{
					$export_flag = -18;
					}
				}

			if (!defined($CustRef->{'addressname'}) or $CustRef->{'addressname'} eq '')
				{
				$export_flag = -19;
				}

			$CustRef->{'isdropship'} = 1;
			}

		if (defined($CustRef->{'datetoship'}) and $CustRef->{'datetoship'} ne '')
			{
			$CustRef->{'datetoship'} = $self->VerifyDate($CustRef->{'datetoship'});
			if ( $CustRef->{'datetoship'} eq '0')
				{
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
					$export_flag = -12;
					}
				}
			}

		if (defined($CustRef->{'dateneeded'}) and $CustRef->{'dateneeded'} ne '')
			{
			$CustRef->{'dateneeded'} = $self->VerifyDate($CustRef->{'dateneeded'});
			if ( $CustRef->{'dateneeded'} eq '0')
				{
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
					$export_flag = -11;
					}
				}
			}

		# If shipment and delivery notification addresses are provided, they must be valid
		if ( defined($CustRef->{'shipmentnotification'}) and $CustRef->{'shipmentnotification'} ne '' )
			{
			if ( !VerifyEmail($CustRef->{'shipmentnotification'}) )
				{
				$export_flag = -14;
				}
			}

		if ( defined($CustRef->{'deliverynotification'}) and $CustRef->{'deliverynotification'} ne '' )
			{
			if ( !VerifyEmail($CustRef->{'deliverynotification'}) )
				{
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
				$CustRef->{'commodityquantity'} = ceil($CustRef->{'commodityquantity'});
				}

			if ( defined($CustRef->{'description'}) and length($CustRef->{'description'}) > 100 )
				{
				$CustRef->{'description'} = substr($CustRef->{'description'},0,99);
				}

			my $C = {};
			$C->{'customerid'} = $CustomerID;
			$C->{'contactid'} = $ContactID;
			$C->{'statusid'} = $StatusID;
			$C->{'ordernumber'} = $CustRef->{'ordernumber'};
			$C->{'ponumber'} = $CustRef->{'ponumber'};
			$C->{'addressname'} = $CustRef->{'addressname'};
			$C->{'address1'} = $CustRef->{'address1'};
			$C->{'address2'} = $CustRef->{'address2'};
			$C->{'addresscity'} = $CustRef->{'addresscity'};
			$C->{'addressstate'} = $CustRef->{'addressstate'};
			$C->{'addresszip'} = $CustRef->{'addresszip'};
			$C->{'addresscountry'} = $CustRef->{'addresscountry'};
			$C->{'datetoship'} = $CustRef->{'datetoship'};
			$C->{'estimatedweight'} = $CustRef->{'estimatedweight'};
			$C->{'estimatedinsurance'} = $CustRef->{'estimatedinsurance'};
			$C->{'description'} = $CustRef->{'description'};
			$C->{'exthsc'} = $CustRef->{'exthsc'};
			$C->{'extcd'} = $CustRef->{'extcd'};
			$C->{'extcarrier'} = $CustRef->{'extcarrier'};
			$C->{'extservice'} = $CustRef->{'extservice'};
			$C->{'dateneeded'} = $CustRef->{'dateneeded'};
			$C->{'extloginid'} = $CustRef->{'extloginid'};
			$C->{'extcustnum'} = $CustRef->{'extcustnum'};
			$C->{'department'} = $CustRef->{'department'};
			$C->{'commodityquantity'} = $CustRef->{'commodityquantity'};
			$C->{'contactname'} = $CustRef->{'contactname'};
			$C->{'contactphone'} = $CustRef->{'contactphone'};
			$C->{'extid'} = $CustRef->{'extid'};
			$C->{'dimlength'} = $CustRef->{'dimlength'};
			$C->{'dimwidth'} = $CustRef->{'dimwidth'};
			$C->{'dimheight'} = $CustRef->{'dimheight'};
			$C->{'unitquantity'} = $CustRef->{'unitquantity'};
			$C->{'stream'} = $CustRef->{'stream'};
			$C->{'dateneededon'} = $CustRef->{'dateneededon'};
			$C->{'tpacctnumber'} = $CustRef->{'tpacctnumber'};
			$C->{'shipmentnotification'} = $CustRef->{'shipmentnotification'};
			$C->{'deliverynotification'} = $CustRef->{'deliverynotification'};
			$C->{'importfile'} = fileparse($import_file);
			$C->{'securitytype'} = $CustRef->{'securitytype'};
			$C->{'termsofsale'} = $CustRef->{'termsofsale'};
			$C->{'dutypaytype'} = $CustRef->{'dutypaytype'};
			$C->{'dutyaccount'} = $CustRef->{'dutyaccount'};
			$C->{'commodityunits'} = $CustRef->{'commodityunits'};
			$C->{'partiestotransaction'} = $CustRef->{'partiestotransaction'};
			$C->{'commodityunitvalue'} = $CustRef->{'commodityunitvalue'};
			$C->{'destinationcountry'} = $CustRef->{'destinationcountry'};
			$C->{'commoditycustomsvalue'} = $CustRef->{'commoditycustomsvalue'};
			$C->{'manufacturecountry'} = $CustRef->{'manufacturecountry'};
			$C->{'currencytype'} = $CustRef->{'currencytype'};
			$C->{'dropname'} = $CustRef->{'dropname'};
			$C->{'dropaddress1'} = $CustRef->{'dropaddress1'};
			$C->{'dropaddress2'} = $CustRef->{'dropaddress2'};
			$C->{'dropcity'} = $CustRef->{'dropcity'};
			$C->{'dropstate'} = $CustRef->{'dropstate'};
			$C->{'dropzip'} = $CustRef->{'dropzip'};
			$C->{'dropcountry'} = $CustRef->{'dropcountry'};
			$C->{'dropcontact'} = $CustRef->{'dropcontact'};
			$C->{'dropphone'} = $CustRef->{'dropphone'};
			$C->{'isdropship'} = $CustRef->{'isdropship'};
			$C->{'volume'} = $CustRef->{'volume'};
			$C->{'density'} = $CustRef->{'density'};
			$C->{'class'} = $CustRef->{'class'};
			$C->{'custref2'} = $CustRef->{'custref2'};
			$C->{'custref3'} = $CustRef->{'custref3'};
			$C->{'freightcharges'} = $CustRef->{'freightcharges'};
			$C->{'transitdays'} = $CustRef->{'transitdays'};
			$C->{'cotypeid'} = $CustRef->{'cotypeid'};

			if (defined($CustRef->{'hazardous'}))
				{
				if ( $CustRef->{'hazardous'} eq 'Y' or  $CustRef->{'hazardous'} eq 'y')
					{
					$C->{'hazardous'} = 1;
					}
				else
					{
					$C->{'hazardous'} = 0;
					}
				}
			if (defined($CustRef->{'keep'}))
				{
				if ( $CustRef->{'keep'} eq 'Y' or  $CustRef->{'keep'} eq 'y' or $CustRef->{'keep'} eq '1' )
					{
					$C->{'keep'} = 1;
					}
				else
					{
					$C->{'keep'} = 0;
					}
				}
				if (defined($CustRef->{'routeflag'}))
					{
					if ( $CustRef->{'routeflag'} eq 'Y' or  $CustRef->{'routeflag'} eq 'y')
						{
						$C->{'routeflag'} = 1;
						$C->{'extcarrier'} = undef;
						$C->{'extservice'} = undef;
						}
					else
						{
						$C->{'routeflag'} = 0;
						}
					}

			print STDERR "\n... CO CreateOrLoadCommit-> ordernumber:  " . $C->{'ordernumber'};

			my $CO = $self->context->model('MyDBI::CO')->new($C);
			$CO->coid($self->myDBI->get_token_id);
			$CO->insert;
			print STDERR "\n... NEW CO INSERTED:  " . $CO->coid;

			my $COID = $CO->coid;

			print STDERR "\n... COID:" . $COID;
			# delete any packages or products that are tied to the order, pass pseudoscreen so authorized will also get deleted
			$CO->delete_all_package_details;

			# create package data
			$PackageRef->{'coid'} = $COID;
			$PackageRef->{'datatypeid'} = '1000';
			# default package quantity to one if none was given
			$PackageRef->{'quantity'} = defined($C->{'unitquantity'}) ? $C->{'unitquantity'} : 1;
			$PackageRef->{'description'} = $C->{'description'};
			$PackageRef->{'weight'} = $C->{'estimatedweight'};
			$PackageRef->{'decval'} = $C->{'estimatedinsurance'};
			$PackageRef->{'ownertypeid'} = 1000;
			$PackageRef->{'ownerid'} = $COID;

			my $PPD = $self->context->model('MyDBI::Packprodata')->new($PackageRef);
			$PPD->coid($self->myDBI->get_token_id);
			$PPD->insert;
			print STDERR "\n... NEW PPD INSERTED, packprodataid:  " . $PPD->packprodataid;

			# set assessorials
			if ( defined($CustRef->{'saturdayflag'}) and $CustRef->{'saturdayflag'} == 1 )
				{
				$self->SaveAssessorial($COID,'saturdaysunday','Saturday Delivery','0')
				}
			if ( defined($CustRef->{'residentialflag'}) and $CustRef->{'residentialflag'} == 1 )
				{
				$self->SaveAssessorial($COID,'residential','Residential Delivery','0')
				}
			if ( defined($CustRef->{'AMflag'}) and $CustRef->{'AMflag'} == 1 )
				{
				$self->SaveAssessorial($COID,'amdelivery','AM Delivery','0')
				}
			}
		elsif ( $export_flag < 0 )
			{
			# We need a valid customerid for the failure to do any good...it's likely a header line
			if ( defined($CustomerID) and $CustomerID ne '' )
				{
				$ImportFailureRef->{$CustomerID} .= "$CustRef->{'ordernumber'}";
				if ( defined($CustRef->{'extcustnum'}) and $CustRef->{'extcustnum'} ne '' )
					{
					$ImportFailureRef->{$CustomerID} .= " ($CustRef->{'extcustnum'})";
					}
				$ImportFailureRef->{$CustomerID} .= ": $export_flag\n";
				}
			# Otherwise, just put out a warning for cron to pick up...Once we see enough headers, we can probably
			# code for them explicitly
			else
				{
				$UnknownCustCount++;

				if ( $UnknownCustCount == 1 )
					{
					$Error_File = fileparse($import_file);
					$Error_File = "unknowncustomer_".$Error_File;
					open(OUT, ">" . $config->{BASE_PATH} . "/var/processing/$Error_File") or warn "unable to open error file";
					}
				print OUT "$Line\n\n";
				close (OUT);
				}
			}

		}

	if ( $UnknownCustCount > 0 )
		{
		print STDERR"\n  ###UnknownCustCount ".$UnknownCustCount;
		#move("$config->{BASE_PATH}/var/processing/$Error_File","$config->{BASE_PATH}/var/export/unknowncust/$Error_File")
		#or &TraceBack("Could not move $Error_File: $!");
		}

	return ($ImportFailureRef,$OrderTypeRef);
	}

# Send email with list of failed imports
sub EmailImportFailures
	{
	my $self = shift;
	my ($ImportFailures,$filepath,$filename,$OrderTypeRef) = @_;

	return print STDERR "\n..... Skip EmailImportFailures: $ImportFailures, $filepath, $filename, $OrderTypeRef";

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

	# Delete old assessorial for order
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
	print STDERR "\n... NEW AssData INSERTED, assdataid:  " . $AssData->assdataid;
	}

sub AuthenticateContact
	{
	my $self = shift;
	my $Username = shift;

	print STDERR "\n... AuthenticateContact, USERNAME: " . $Username;
	my ($ContactID, $CustomerID);

	my $myDBI = $self->myDBI;
	my $SQL;
	# New contact user
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
		# Standard/Backwards compatible user
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

	return ($ContactID,$CustomerID) unless  $STHC->numrows;

	my $DATA = $STHC->fetchrow(0);
	($ContactID,$CustomerID) = ($DATA->{contactid},$DATA->{customerid});

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

	use Scalar::Util qw(looks_like_number);
	use POSIX qw(strftime);
	use Time::Piece;

	my $inpdir = '/opt/engage/CSV2TXT/inputdir';
	my $outdir = '/tmp';
	opendir(D, "$inpdir") || die "Can't opendir $inpdir: $!\n";
	my @list = readdir(D);
	closedir(D);

	my $inputfilename;

		$inputfilename = basename( $file );
		$inputfilename =~ s/.csv//;

		my $csv = Text::CSV->new ({
			binary    => 1,
			auto_diag => 1,
			sep_char  => ','    # not really needed as this is the default
		});
 
	open(my $data, '<:encoding(utf8)', "$inpdir/$file") or die "Could not open '$file' $!\n";
	open PRODFILE, "+>$outdir/ProductImport-$inputfilename.txt" or die $!;
	open ORDRFILE, "+>$outdir/OrderImport-$inputfilename.txt" or die $!;
	my $i = 0;
	while (my $fields = $csv->getline( $data )) {
			if($i gt 0)
			{
			if ($fields->[10] eq ''){
				if($fields->[19] ne ''){
					#call sub
					$self->printImports($fields);
					#my ($retValue1, $retValue2) = printImports($fields);
					#print PRODFILE $retValue1;
					#print ORDRFILE $retValue2;
				}
			}elsif($fields->[10] ne ''){
				#if($fields->[18] ne ''){
					#call sub
					$self->printImports($fields);
					#my ($retValue1, $retValue2) = printImports($fields);
                                        #print PRODFILE $retValue1;
                                        #print ORDRFILE $retValue2;
				#}
			}

			
			}
			$i++;
		}
		if (not $csv->eof) {
			$csv->error_diag();
		}
		close $data;
		close PRODFILE;
		close ORDRFILE;
		print "\nGenerated ProductImport file $outdir/ProductImport-$inputfilename.txt  for  $inpdir/$file\n";
		print "Generated OrderImport file $outdir/OrderImport-$inputfilename.txt  for  $inpdir/$file\n";
	}

sub printImports
	{
	my $self = shift;
	my $fields = shift;

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

			if ($fields->[10] eq ''){
				$Return = $fields->[17];
				$Comment = $fields->[18];
				$EquipName = $fields->[19];
				$EquipQtyName = $fields->[20];
			}else{
                                $Return = $fields->[16];
                                $Comment = $fields->[17];
				$EquipName = $fields->[18];
				$EquipQtyName = $fields->[19];
			}


			if($EquipName eq '' || $EquipQtyName eq ''){
				$EquipName = '';
				$EquipQtyName = '';
				#$return1 = "sprint/user\t$fields->[0]\t\t\t\t\t\t\t\n";
				#print PRODFILE "$return1";
			}
			elsif($EquipName ne '' && $EquipQtyName ne '')
			{
			$EquipName =~ s/\n\n/\n/g;
			$EquipName =~ s/[\r\n]+/,/g;
			@EquipmentArray = split(',', $EquipName);

			foreach  (@EquipmentArray){
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

			foreach (@EquipQtyArray){
			        $EquipQtyString = $_;
        			$EquipQtyString =~ s/^\s+//;
		        	$EquipQtyString =~ s/\s+$//;
	        		$EquipQtyString =~ s/\r\n/,/g;
			        chomp($EquipQtyString);

        			$EquipQtyString =~ s/\s+$//;
			        push(@EquipQtyArray2, $EquipQtyString);
			}

			for (my $k = 0; $k < @EquipArray2; $k++) {
				$EquipArray2[$k] =~  s/\s+$//;
	        		$return1 = "sprint/user\t$fields->[0]\t$EquipQtyArray2[$k]\t\t\t\t$EquipArray2[$k]\t\t$EquipArray2[$k]\n";
				print PRODFILE "$return1";
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
			
			if ( $fields->[10] eq '' ){
				$City = $fields->[11];
                                $State = $fields->[12];
                                $Zip = $fields->[13];
				$Zip = sprintf("%05d", $Zip);
                                $EquipmentConf = $fields->[21];
				#$EquipmentConf = substr($EquipmentConf, 0, 100);
                                $MailStop = $fields->[6];
                                $endUserPhone = $fields->[3];
                                $CustomerWantDate = $fields->[15];
			} else{
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
			
			if ( $endUserName eq ''){
				#print "$endUserName";
				#my $temp = "$ProjectName";
				#$temp =~ s/Shipment to //g;
				#$endUserName = "$temp";
				$endUserName = "OCCUPANT";
				#$ShipFromName = "OCCUPANT";
			}else{
			}
			
			if ( $Return eq 'Y' || $Return eq 'Yes' || $Return eq '1'){
				$Return = $Return;
			}elsif( $Return eq 'N' || $Return eq 'No' || $Return eq '0'){
				$Return = $Return;
			}elsif($Return eq ''){
				$Return = "";
			}else{
			}

			if ( $Comment ne ''){
                                $Comment = "$Comment";
                        }else{
				$Comment = '';
                        }


			if ( $CustomerWantDate eq "OVERNIGHT" || $CustomerWantDate eq "Overnight" || $CustomerWantDate eq "OverNight"){
				$CustomerWantNumber = 1;		
			}elsif( $CustomerWantDate eq "TWO" || $CustomerWantDate eq "SECOND" ){
				$CustomerWantNumber = 2;
			}elsif( $CustomerWantDate eq "THREE" || $CustomerWantDate eq "THIRD" ){
                                $CustomerWantNumber = 3;
                        }elsif( $CustomerWantDate eq "GROUND" || $CustomerWantDate eq "Ground" ){
                                $CustomerWantNumber = 5;
			}elsif( looks_like_number($CustomerWantDate) ){
                                $CustomerWantNumber = $CustomerWantDate;
                        }elsif( $CustomerWantDate =~/^((((0[13578])|([13578])|(1[02]))[\/](([1-9])|([0-2][0-9])|(3[01])))|(((0[469])|([469])|(11))[\/](([1-9])|([0-2][0-9])|(30)))|((2|02)[\/](([1-9])|([0-2][0-9]))))[\/]\d{4}$|^\d{4}$/){
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
					if( $diff gt 0){
						#print "$diff\n";
						$duedate = '';
					}elsif( $diff lt 0 || $diff eq 0){
						#print "$diff\n";
						$duedate = $CustomerWantDate;
					}else{
					}
                        }else{
				$CustomerWantNumber = '';
			}
			
			if($EquipmentConf ne ''){
			$EquipmentConf  =~ s/[\r\n]+/,/g;
			$EquipmentConf  =~ s/,//g;
			}else{
			}

			if($EquipmentConf eq ''){
				$return2 = "$ProjectNumber\t\t$endUserName\t$Address1\t$Address2\t$City\t$State\t$Zip\t\t\t\t\t\t\t\t\t\t\t$duedate\t$constant\t$MailStop\t$ProjectName\t\t$endUserName\t$endUserPhone\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t$CustomerWantNumber\t\t\t\t\t$Comment\t$ShipToCharge\t$Return\t$CusRef2\t$CusRef3\n";
    	                        print ORDRFILE "$return2";
			}
			else{
			my @EquipmentConfArray = split(',',$EquipmentConf);
			
			for (my $m = 0; $m<@EquipmentConfArray; $m++) {
				my $temporary_var = $EquipmentConfArray[$m];
				$return2 = "$ProjectNumber\t\t$endUserName\t$Address1\t$Address2\t$City\t$State\t$Zip\t\t\t\t\t$temporary_var\t\t\t\t\t\t$duedate\t$constant\t$MailStop\t$ProjectName\t\t$endUserName\t$endUserPhone\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t$CustomerWantNumber\t\t\t\t\t$Comment\t$ShipToCharge\t$Return\t$CusRef2\t$CusRef3\n";
				#print "$return2";
				print ORDRFILE "$return2";
			}
			}
	}

__PACKAGE__->meta()->make_immutable();

no Moose;

1;

__END__