#!/usr/bin/perl -w

use strict;
use lib '/opt/engage/intelliship2/IntelliShip/lib';
use IntelliShip::Utils;

if (IntelliShip::Utils->i_am_running)
	{
	exit;
	}

my @ToRun = (
	"/opt/engage/intelliship2/IntelliShip/cron/ftp_import.pl",
	"/opt/engage/intelliship2/IntelliShip/cron/import_order.pl --cron 1",
	);

foreach my $Job (@ToRun)
	{
	warn "Running $Job";
	system($Job);
	}

__END__