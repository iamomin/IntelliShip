#!/usr/bin/perl

use strict;
use lib '/opt/engage/intelliship2/IntelliShip/lib';
use IO::File;
use Data::Dumper;
use Getopt::Long;
use IntelliShip::Utils;
use IntelliShip::MyConfig;
use IntelliShip::Model::MyDBI;
use IntelliShip::Arrs::API;

require IntelliShip::Import::Orders;

if (IntelliShip::Utils->i_am_running)
	{
	exit;
	}

my $options = {
	'username' => 'tsharp@engagetechnology.com',
	'pwd' => '33mark',
	'filetype' => 'order',
	'cron' => 0
	};

$SIG{__DIE__} = sub { print "See 'import_order --help'." };

GetOptions($options, "username=s", "pwd=s", "file=s", "filetype=s", "cron=i", "help");

if (defined $options->{'help'})
	{
	print <<FOO;
$0: Import Orders into IntelliShip

NAME
       import_order - import tab seprated order information into database

SYNOPSIS
       import_order --username
       import_order --pwd
       import_order --file
       import_order --filetype
       import_order --cron

COMMANDS
       username       = Contact username
       pwd            = Contact user password
       file           = File to be imported
       filetype       = Type of file (order/product)
       cron           = Cron tab setup

EXAMPLE
       perl import_order.pl --cron 1
       perl import_order.pl --username tsharp\@engagetechnology.com --pwd xxxx --file /var/IMPORT_TEST
       perl import_order.pl --username tsharp\@engagetechnology.com --pwd xxxx --file /tmp/OrderImport-8EYAEBM8QTFPZ.txt --filetype order
       perl import_order.pl --username tsharp\@engagetechnology.com --pwd xxxx --file /tmp/ProductImport-8EYAEBM8QTFPZ.txt --filetype product

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
my $filetype = $options->{'filetype'};
my $cron = $options->{'cron'};

unless ($cron)
	{
	unless ($USER && $PWD)
		{
		die "\nPlease Specify Valid Username/Password\n";
		}

	unless ($file)
		{
		die "\nInvalid file specified\n";
		}

	if ($file)
		{
		die "\n" . $! . "\n" unless stat $file;
		}
	}

## Connect to your database.
my $myDBI = IntelliShip::Model::MyDBI->new();

print "\nUser       : " . $USER;
print "\nFile       : " . $file if $file;
print "\nImport Type: " . uc $filetype;
print "\n";

print "\n... authenticate user " . $USER;
my @arr = $myDBI->resultset('Contact')->search({ username => $USER, password => $PWD });

unless (@arr)
	{
	die "\n... Invalid Username/Password\n";
	}

print "\n... user authenticated successfully";
my $Contact = $arr[0];
my $Customer = $Contact->customer;

print "\n... contact id " . $Contact->contactid;
print "\n... customer id " . $Customer->customerid;

eval {

	if ($cron)
		{
		process_bulk_import();
		}
	else
		{
		process_file($file,$filetype);
		}
	};

if ($@)
	{
	print "Error: " . $@;
	}

print "\n\n";

sub process_bulk_import
	{
	print "\n... process bulk import";

	my $file_path = IntelliShip::MyConfig->import_directory;
	my $order_path = $file_path . '/co';
	my $product_path = $file_path . '/product';

	print "\n... search order files in " . $order_path;
	my @orderfiles;
	push(@orderfiles, <$order_path/*>);
	print "\n... total order files found " . @orderfiles;

	foreach my $file (@orderfiles)
		{
		#print "\n... import order file " . $file;

		unless (-f $file)
			{
			print "\n... not a valid file, skip";
			next;
			}

		my $ImportHandler = IntelliShip::Import::Orders->new;
		$ImportHandler->myDBI($myDBI);
		$ImportHandler->contact($Contact);
		$ImportHandler->customer($Customer);
		$ImportHandler->import_type('order');
		$ImportHandler->import_file($file);
		$ImportHandler->API(IntelliShip::Arrs::API->new);
		$ImportHandler->import;

		print "\n\n";

		if ($ImportHandler->has_errors)
			{
			print "\n... Errors: " . Dumper $ImportHandler->errors;
			}
		else
			{
			}
		}

	print "\n*** ORDER FILES IMPORTED SUCCESSFULLY ***\n";

	print "\n... search product files in " . $product_path;
	my @productfiles;
	push(@productfiles, <$product_path/*>);
	print "\n... total product files found " . @productfiles;

	foreach my $file (@productfiles)
		{
		#print "\n... import product file " . $file;

		unless (-f $file)
			{
			print "\n... not a valid file, skip";
			next;
			}

		my $ImportHandler = IntelliShip::Import::Orders->new;
		$ImportHandler->myDBI($myDBI);
		$ImportHandler->contact($Contact);
		$ImportHandler->customer($Customer);
		$ImportHandler->import_type('product');
		$ImportHandler->import_file($file);
		$ImportHandler->API(IntelliShip::Arrs::API->new);
		$ImportHandler->import;

		print "\n\n";

		if ($ImportHandler->has_errors)
			{
			print "\n... Errors: " . Dumper $ImportHandler->errors;
			}
		else
			{
			}
		}

	print "\n*** PRODUCT FILES IMPORTED SUCCESSFULLY ***\n";
	}

sub process_file
	{
	my $file = shift;
	my $filetype = shift;

	my $ImportHandler = IntelliShip::Import::Orders->new;
	$ImportHandler->myDBI($myDBI);
	$ImportHandler->contact($Contact);
	$ImportHandler->customer($Customer);
	$ImportHandler->import_file($file);
	$ImportHandler->import_type($filetype);
	$ImportHandler->import;

	print "\n\n";

	if ($ImportHandler->has_errors)
		{
		print "\n... Errors: " . Dumper $ImportHandler->errors;
		}
	else
		{
		print "\n*** FILE IMPORTED SUCCESSFULLY ***\n";
		}
	}

__END__