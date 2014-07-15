#!/usr/bin/perl

use strict;
use lib '/opt/engage/intelliship2/IntelliShip/lib';
use IO::File;
use Data::Dumper;
use Getopt::Long;
use File::Basename;
use Spreadsheet::ParseExcel;
use IntelliShip::MyConfig;
use IntelliShip::Model::MyDBI;

use lib IntelliShip::MyConfig->application_root;

#require IntelliShip::Import::Users;

my $options = {
	'username' => 'Motorola',
	'pwd' => '8EY2KRRW87RWW',
	};

GetOptions($options, "username=s", "pwd=s", "file=s", "cron=i", "help");

if (defined $options->{'help'})
	{
	print <<FOO;
$0: Import Contacts (aka Users) into IntelliShip

NAME
       import_contacts - import tab seperated contact information into database

SYNOPSIS
       import_contact --username
       import_contacts --pwd
       import_contacts --file
       import_contacts --cron

COMMANDS
       username       = Customer domain/username
       pwd            = System user password
       file           = File to be imported
       cron           = Cron tab setup

EXAMPLE
       perl import_contacts.pl --cron 1
       perl import_contacts.pl --username tsharp\@engagetechnology.com --pwd xxxx --file /var/IMPORT_TEST

AUTHOR
       Imran Momin <imranm\@alohatechnology.com>
       Send bug reports or comments to the above address or to Tony Sharp <tsharp\@engagetechnology.com>.

  --help               - This help page

FOO
	exit;
	}

#print Dumper($options);

my $USER = $options->{'username'};
my $PWD = $options->{'pwd'};
my $file = $options->{'file'};
my $cron = $options->{'cron'};

my $import_path = IntelliShip::MyConfig->application_root . "/var/import/contact";
my $imported_path = IntelliShip::MyConfig->application_root . "/var/imported/contact";

my $Domain = $USER;

unless ($Domain)
	{
	die "\nInvalid Username/Domain\n";
	}

print "\nUser     : " . $USER;
print "\nPassword : " . 'x' x length($PWD);
print "\n";

## Connect to your database.
my $myDBI = IntelliShip::Model::MyDBI->new();

## Search for valid customer in database.
my @arr = $myDBI->resultset('Customer')->search({ username => lc($USER), password => $PWD });

unless (@arr)
	{
	die "\n... no matching customer found";
	}

print "\n... valid customer found";
my $Customer = $arr[0];

print "\n... Customer ID  : " . $Customer->customerid;
print "\n... Customer Name: " . $Customer->customername;
print "\n";

my $CustomerID = $Customer->customerid;

my @files;
if ($file)
	{
	die "\n" . $! . "\n" unless stat $file;
	push(@files,$file);
	}
else
	{
	push(@files,<$import_path/*>);
	}

#################################
### Check for Files to Import
#################################
unless (@files)
	{
	die "\n... no files to proceed import\n";
	}

my $CountrySQL = "SELECT upper(countryname) as countryname, countryiso2 FROM country";
my $sth = $myDBI->select($CountrySQL);
#print "query_data: " . Dumper($sth->query_data);

my %countryHash;
if ($sth->numrows)
	{
	%countryHash = map { $_->[0] => $_->[1] } @{$sth->query_data};
	}

foreach my $File (@files)
	{
	print "\nFile       : " . $File;

	eval {
		process_file($File);
		};

	if ($@)
		{
		print "Error: " . $@;
		last;
		}
	}

print "\n*** FILE IMPORTED SUCCESSFULLY ***\n" unless $@;
print "\n\n";

sub process_file
	{
	my $file = shift;
	print "\n... process file $file";

	my $parser   = Spreadsheet::ParseExcel->new();
	my $workbook = $parser->parse($file);

	return die $parser->error() unless $workbook;

	my $worksheet = $workbook->worksheet(0);
	my ( $row_min, $row_max ) = $worksheet->row_range();
	my ( $col_min, $col_max ) = $worksheet->col_range();

	for (my $i = 0; $i <= $row_max; $i++)
		{
		## skip header row
		next if $i == 0;

		my @array;
		for (my $j = 0; $j <= $col_max; $j++)
			{
			my $cell = $worksheet->get_cell($i,$j);
			next unless $cell;
			push(@array, $cell->value());
			}

		my $UserID = "$array[0]";
		my $Password = $myDBI->get_token_id;
		my $LoginLevel = '';
		my $FirstName = "$array[2]";
		my $LastName = "$array[3]";
		my $EmailAddress = "$array[15]";
		my $CellPhone = "$array[14]";
		my $TelephoneNumber = "$array[13]";
		my $FaxNumber = '';
		my $HomeNumber = '';
		my $SiteName = "$array[6]";
		my $MailingAddress1 = "$array[7]";
		my $MailingAddress2 = "$array[8]";
		my $City = "$array[9]";
		my $StateProvince = "$array[10]";
		my $ZipPostalCode = "$array[11]";
		my $Country = "$array[12]";
		my $Location = "$array[5]";
		my $OwnerID = "$array[1]";
		my $Department = "$array[4]";
		my $DateDeactivated = '';
		my $QuickShip = "Default";
		my $ZPL2 = "JPG";
		my $SaturdayShipping = "Yes";
		my $SundayShipping = "Yes";
		my $DisplayQuoteMarkup = '';
		my $QuoteMarkupDefault = '';
		my $LabelPort = '';
		my $SKUManager = '';
		my $MyOrders = '';
		my $CustNumAddressLookup = '';
		my $TextStatus = '';
		my $RestrictOrders = '';
		my $ReturnCapability = '';
		my $DropShipCapability = '';
		my $DefaultFreightClass = '';
		my $AutoDIMClassing = '';
		my $APIUsername = '';
		my $APIPassword = '';
		my $DefaultPackageUnitType = '';
		my $DefaultProductUnitType = '';
		my $POInstructions = '';
		my $POAuthType = '';
		my $DefaultCommercialInvoice = '';
		my $PrintPackingList = '';
		my $AccountStatusDetail = "$array[16]";
		my $OrigDate = "$array[17]";
		my $SourceDate = "$array[18]";
		my $DisableDate = "$array[19]";
		my $return = '';

		my $sth = $myDBI->select("SELECT 1 FROM contact WHERE customerid = '$CustomerID' AND upper(username) = '" . uc($UserID) . "'");
		if ($sth->numrows)
			{
			print "\n... matching customer user already exist, skip importing user '$UserID'";
			next;
			}

		## To make N/A to null
		if ($ZipPostalCode =~ m/N\/A/i)
			{
			$ZipPostalCode = "";
			}

		## Substitute Country Name with ISO 2 Code
		$Country =~ s/^\s*|\s*$//; #remove leading and trailing whitespace
		$Country =~ s/\\s+/\\s/;
		$Country = uc($Country);

		if ($countryHash{$Country})
			{
			$Country = $countryHash{$Country};
			}

		## Substitute State Name with ISO 2 Code
		$StateProvince =~ s/^\s*|\s*$//; #remove leading and trailing whitespace
		$StateProvince =~ s/\\s+/\\s/;
		$StateProvince = uc( $StateProvince);

		my $addressData = {
			addressname => $SiteName,
			address1 => $MailingAddress1,
			address2 => $MailingAddress2,
			city => $City,
			state => $StateProvince,
			zip => $ZipPostalCode,
			country => $Country,
			};

		#print "\n... addressData: " . Dumper($addressData);

		my @arr = $myDBI->resultset('Address')->search($addressData);
		my $Address;
		if (@arr)
			{
			$Address = $arr[0];
			print "\n... existing address found, addressid: " . $Address->addressid;
			}
		else
			{
			print "\n... inserting new address";
			$Address = $myDBI->resultset('Address')->new($addressData);
			$Address->addressid($myDBI->get_token_id);
			$Address->insert;
			}

		my $Contact = { customerid => $CustomerID, addressid => $Address->addressid };
		my $CRef = {};

		$Contact->{'domain'} = $Domain;
		$Contact->{'username'} = $UserID;
		$Contact->{'password'} = $Password;
		$Contact->{'firstname'} = $FirstName;
		$Contact->{'lastname'} = $LastName;
		$Contact->{'email'} = $EmailAddress;
		$Contact->{'phonemobile'} = $CellPhone;
		$Contact->{'phonebusiness'} = $TelephoneNumber;
		$Contact->{'fax'} = $FaxNumber;
		$Contact->{'phonehome'} = $HomeNumber;

		$Contact->{'department'} = $Department;


		my $Contact = $myDBI->resultset('Contact')->new($Contact);
		$Contact->contactid($myDBI->get_token_id);
		$Contact->insert;

		print "... NEW Contact INSERTED, contactid: " . $Contact->contactid;

		## Contact rules with datatypeid = 1;
		my @datatype_1_fields = ('loginlevel','quickship','satshipping','sunshipping','jpglabel','dropshipcapability','returncapability','autodimclass','reqproddescr','custnumaddresslookup','indicatortype','myorders','quotemarkup','quotemarkupdefault','skumanager','labeltype');

		## Contact rules with datatypeid = 2;
		my @datatype_2_fields = ('halousername','halopassword','halourl','labelport','origdate','sourcedate','disabledate','location','ownerid','defaultpackageunittype','defaultproductunittype','defaultpackinglist','poauthtype','poinstructions');

		## Data type int
		$CRef->{'loginlevel'} = $LoginLevel || 0;
		$CRef->{'quickship'} = $QuickShip || 2;
		$CRef->{'quickship'} = 2 if $CRef->{'quickship'} =~ /Default/i;
		$CRef->{'satshipping'} = $SaturdayShipping || 0;
		$CRef->{'satshipping'} = $CRef->{'satshipping'} =~ /Yes/i ? 1 : 0;
		$CRef->{'sunshipping'} = $SundayShipping || 0;
		$CRef->{'sunshipping'} = $CRef->{'sunshipping'} =~ /Yes/i ? 1 : 0;
		$CRef->{'labeltype'} = $CRef->{'labeltype'} || 'jpg';
		$CRef->{'labeltype'} = lc($CRef->{'labeltype'});
		$CRef->{'dropshipcapability'} = $DropShipCapability || 1;
		$CRef->{'returncapability'} = $ReturnCapability || 1 ;
		$CRef->{'autodimclass'} = $AutoDIMClassing || 0;
		$CRef->{'reqproddescr'} = $CRef->{'reqproddescr'} || 1;
		$CRef->{'custnumaddresslookup'} = $CustNumAddressLookup || 0;
		$CRef->{'indicatortype'} = $CRef->{'indicatortype'} || 0;
		$CRef->{'myorders'} = $MyOrders || 0;
		$CRef->{'quotemarkup'} = $DisplayQuoteMarkup || 0;
		$CRef->{'quotemarkupdefault'} = $QuoteMarkupDefault || 0;
		$CRef->{'skumanager'} = $SKUManager || 0;

		## Data type string
		$CRef->{'halousername'} = $Contact->{'username'};
		$CRef->{'halopassword'} = $Contact->{'password'};
		$CRef->{'halourl'} = 'shippingreport-test.motorolasolutions.com';
		$CRef->{'labelport'} = $LabelPort || 'LPT1';
		$CRef->{'defaultpackageunittype'} = $DefaultPackageUnitType || '18';
		$CRef->{'defaultproductunittype'} = $DefaultProductUnitType || '3';
		$CRef->{'defaultpackinglist'} = $CRef->{'defaultpackinglist'} || '2';
		$CRef->{'poauthtype'} = $POAuthType || '0';
		$CRef->{'poinstructions'} = $POInstructions || '0';

		my $customerContactSql = "INSERT INTO custcondata (custcondataid, ownertypeid, ownerid, datatypeid, datatypename, value) VALUES ";
		my $customerContactValues = [];

		foreach my $datatypename (@datatype_1_fields)
			{
			push (@$customerContactValues, "('".$myDBI->get_token_id."', '2', '".$Contact->contactid."', '1','".$datatypename."', '".$CRef->{$datatypename}."')" );
			}

		foreach my $datatypename (@datatype_2_fields)
			{
			push (@$customerContactValues, "('".$myDBI->get_token_id."', '2', '".$Contact->contactid."', '2','".$datatypename."', '".$CRef->{$datatypename}."')" );
			}

		my $SQL = $customerContactSql . join(' , ',@$customerContactValues) if $customerContactValues;
		print "\n... Customer Settings SQL: " . $SQL;
		$myDBI->dbh->do($SQL);
		}
	}

__END__
