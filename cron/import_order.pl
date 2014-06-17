#!/usr/bin/perl

use strict;
use lib '/opt/engage/intelliship2/IntelliShip/lib';
use IO::File;
use Data::Dumper;
use Getopt::Long;
use IntelliShip::Model::MyDBI;

require IntelliShip::Import::Orders;

my $options = {
	'username' => '',
	'pwd' => '',
	'filetype' => 'order',
	};

GetOptions($options, "username=s", "pwd=s", "file=s", "filetype=s", "help");

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

COMMANDS
       username       = Contact username
       pwd            = Contact user password
       file           = File to be imported
       filetype       = Type of file (order/product)

EXAMPLE
       perl create_database.pl --username tsharp\@engagetechnology.com --pwd xxxx --file /var/IMPORT_TEST

AUTHOR
       Imran Momin <imranm\@alohatechnology.com>
       Send bug reports or comments to the above address or to David Dragon <tsharp\@engagetechnology.com>.

  --help               - This help page

FOO
	exit;
	}

#print Dumper($options);

my $USER = $options->{'username'};
my $PWD = $options->{'pwd'};
my $file = $options->{'file'};
my $filetype = $options->{'filetype'};

unless ($USER && $PWD)
	{
	die "\nInvalid Username/Password\n";
	}

unless ($file)
	{
	die "\nInvalid file\n";
	}

if ($file)
	{
	die "\n" . $! . "\n" unless stat $file;
	}

print "\nUser       : " . $USER;
print "\nFile       : " . $file if $file;
print "\nImport Type: " . uc $filetype;
print "\n";

eval {

	# Connect to your database.

	my $myDBI = IntelliShip::Model::MyDBI->new();

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
};

print $@ if $@;

print "\n\n";

__END__