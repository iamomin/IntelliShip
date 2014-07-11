#!/usr/bin/perl -w
use strict;

use lib '/opt/engage/intelliship2/IntelliShip/lib';

use DBI;
use Net::FTP;
use File::Copy;
use Sys::Hostname;

#use IntelliShip::Model::MyDBI;

my ($ordernumber) = @ARGV;

my $DBRef = {};

##############################
### Database Connections
##############################
#$DBRef->{'aos'} = IntelliShip::Model::MyDBI->new();

$DBRef->{'aos'} = DBI->connect("dbi:Pg:dbname=aos_intelliship;host=localhost", "webuser", "Byt#Yu2e", {AutoCommit => 1});

my $config->{'BASE_PATH'} = '/opt/engage/intelliship2/IntelliShip';

##############################
## Get list of ftp sites
##############################

# Build SQL to get list of FTP sites
my $FTP_SQL = "
   SELECT
      f.username,
      f.password,
      f.path,
      f.address,
		f.customer,
		f.timeout,
		f.email
   FROM
      ftpinfo f
   WHERE
      f.ftpinfotypeid = 1
		AND f.active = 1
AND ftpinfoid = '3001'
	ORDER BY ftpinfoid desc
";

my $FTP_STH = $DBRef->{'aos'}->prepare($FTP_SQL)
   or TraceBack ("Cannot prepare ftp select sql statement",1);

$FTP_STH->execute()
   or TraceBack ("Cannot execute ftp select sql statement",1);

while ( my $FTPRef = $FTP_STH->fetchrow_hashref() )
{
#warn "FTP: $FTPRef->{'username'}|$FTPRef->{'password'}|$FTPRef->{'path'}|$FTPRef->{'address'}|";
	my $ftp = Net::FTP->new($FTPRef->{'address'},Timeout=>$FTPRef->{'timeout'});

	if ( defined($ftp) )
	{
		$ftp->login($FTPRef->{'username'},$FTPRef->{'password'});
		$ftp->ascii();
		if ( $FTPRef->{'path'} ne '' )
   	{
      	$ftp->cwd($FTPRef->{'path'});
   	}


   	my @remote_files = $ftp->ls();

		if ( defined($ordernumber) && $ordernumber ne '' )
		{
			 @remote_files = grep { $_ =~ /$ordernumber/ } @remote_files;
		}

   	foreach my $file ( @remote_files )
   	{
			next if ($file eq '.' || $file eq '..');
#warn "$file";
			my $sql = "SELECT lpad(CAST(nextval('master_seq') AS text),6,'0') as token";
#warn $sql;
			my $sth = $DBRef->{'aos'}->prepare($sql) or warn "couldn't prepare seq num query";
			$sth->execute() or warn "couldn't execute token query";
   		my ($token_id) = $sth->fetchrow_array();
			$sth->finish();
			#my $file_unique = $DBRef->{'aos'}->gettokenid() . "_" . $file;
			my $file_unique = $token_id . "_" . $file;

			my $LocalFile;
			# Sort Sony Files
			if ($FTPRef->{'customer'} eq 'Sony')
			{
				if ( $file_unique =~ /ORDHDRIMP/ || $file_unique =~ /ORDIMP/ )
				{
					$LocalFile = "$config->{BASE_PATH}/var/import/co/$file_unique";
				}
				elsif ( $file_unique =~ /ORDDTLIMP/ || $file_unique =~ /ORDPRD/ )
				{
					$LocalFile = "$config->{BASE_PATH}/var/import/product/$file_unique";
				}
				elsif ( $file_unique =~ /SHPHDRIMP/ || $file_unique =~ /SHPIMP/ )
				{
					$LocalFile = "$config->{BASE_PATH}/var/import/shipment/$file_unique";
				}
				elsif ( $file_unique =~ /SHPDTLIMP/ || $file_unique =~ /SHPPRD/ )
				{
					$LocalFile = "$config->{BASE_PATH}/var/import/product/shipmentproduct/$file_unique";
				}
				else
				{
					warn "Unknown sony filetype: $file_unique";
					next;
				}

				$ftp->get($file,$LocalFile);
			}
			else
			{
				if ( $file_unique =~ /_Shipment_/ )
				{
					$LocalFile = "$config->{BASE_PATH}/var/import/shipment/$file_unique";
				}
				# AMFQubica
				elsif ( $FTPRef->{'address'} eq '137.117.163.230' )
				{
					if ( $file_unique =~ /_QO/ )
					{
						$LocalFile = "$config->{BASE_PATH}/var/import/co/$file_unique";
					}
					elsif ( $file_unique =~ /_QP/ )
					{
						$LocalFile = "$config->{BASE_PATH}/var/import/product/$file_unique";
					}
					else
					{
						$LocalFile = "$config->{BASE_PATH}/var/import/co/$file_unique";
					}
				}
				# parts authority
				elsif ( $FTPRef->{'address'} eq '71.190.220.26' )
				{
					$LocalFile = "$config->{BASE_PATH}/var/import/product/$file_unique";
				}
				elsif ( $FTPRef->{'path'} =~ /product/i )
				{
					$LocalFile = "$config->{BASE_PATH}/var/import/product/$file_unique";
				}
				elsif ( $FTPRef->{'username'} =~ /garvey/i )
				{
					$LocalFile = "$config->{BASE_PATH}/var/import/co/garvey/$file_unique";
				}
				else
				{
					$LocalFile = "$config->{BASE_PATH}/var/import/co/$file_unique";
				}

				$ftp->get($file,$LocalFile);


				if ( $FTPRef->{'customer'} eq 'garveyOFF' && -r $LocalFile )
				{
					my $from_email = "noc\@intelliship.$config->{BASE_DOMAIN}";
					my $to_email = 'noc@engagetechnology.com';

					my $subject = 'Garvey FTP File';

					SendFileAsEmailAttachment($from_email,$to_email,undef,undef,$subject,$subject,$LocalFile,$LocalFile);
				}
			}

			#if ( &GetServerType == 1 || hostname() eq 'rml00web01' )
			#{
				#$ftp->delete($file);
			#}
   	}
		$ftp->quit();
	}
	else
	{
		# If the ftp site is inaccessible - email the listed admin
		if ( defined($FTPRef->{'email'}) && $FTPRef->{'email'} ne '' )
		{
			use POSIX qw(strftime);
			my $CurrentTime = strftime("%D %T", localtime);

			my $from_email = "noc\@intelliship.$config->{BASE_DOMAIN}";
			my $to_email = $FTPRef->{'email'};
			my $subject = "WARNING: Intelliship FTP site $FTPRef->{'customer'} ($FTPRef->{'address'}) is inaccessible ($CurrentTime).";
			my $body = "WARNING: Intelliship FTP site $FTPRef->{'customer'} ($FTPRef->{'address'}) is inaccessible ($CurrentTime).";

			SendStringAsEmailAttachment($from_email,$to_email,'','',$subject,$body);
		}
	}
}
$FTP_STH->finish();

##############################
## Cleanup DB Connections
##############################
foreach my $DBName (keys(%$DBRef))
{
	$DBRef->{$DBName}->disconnect();
}

__END__