#!/usr/bin/perl -w
use strict;

use lib '/opt/engage/intelliship2/IntelliShip/lib';

use Net::FTP;
use File::Copy;
use Data::Dumper;
use POSIX qw(strftime);
use IntelliShip::Email;
use IntelliShip::MyConfig;
use IntelliShip::Model::MyDBI;

my $ordernumber = @ARGV;

##############################
### Database Connections
##############################
my $myDBI = IntelliShip::Model::MyDBI->new();

##############################
## Get import file path
my $ImportFilePath = IntelliShip::MyConfig->import_directory;

##############################
## Get list of ftp sites
##############################

# Build SQL to get list of FTP sites
my $FTP_SQL = "SELECT * FROM ftpinfo WHERE ftpinfotypeid=1 AND active=1 ORDER BY ftpinfoid DESC";
my $FTP_STH = $myDBI->select($FTP_SQL);

print "\n... total " . $FTP_STH->numrows . " FTP servers found";
for (my $row=0; $row < $FTP_STH->numrows; $row++)
	{
	my $FTPRef = $FTP_STH->fetchrow($row);

	print "\n... FTP REF: " . Dumper($FTPRef);

	my $ftp = Net::FTP->new($FTPRef->{'address'},Timeout=>$FTPRef->{'timeout'});

	if ( defined($ftp) )
		{
		$ftp->login($FTPRef->{'username'},$FTPRef->{'password'});
		$ftp->ascii;

		$ftp->cwd($FTPRef->{'path'}) if $FTPRef->{'path'};

		my @remote_files = $ftp->ls;

		if ( defined($ordernumber) && $ordernumber ne '' )
			{
			@remote_files = grep { $_ =~ /$ordernumber/ } @remote_files;
			}

		foreach my $file ( @remote_files )
			{
			next if ($file eq '.' || $file eq '..');

			print "\n... remote file $file";

			my $token_id = $myDBI->get_token_id;

			my $file_unique = $token_id . "_" . $file;

			my $LocalFile;
			# Sort Sony Files
			if ($FTPRef->{'customer'} eq 'Sony')
				{
				if ( $file_unique =~ /ORDHDRIMP/ || $file_unique =~ /ORDIMP/ )
					{
					$LocalFile = "$ImportFilePath/co/$file_unique";
					}
				elsif ( $file_unique =~ /ORDDTLIMP/ || $file_unique =~ /ORDPRD/ )
					{
					$LocalFile = "$ImportFilePath/product/$file_unique";
					}
				elsif ( $file_unique =~ /SHPHDRIMP/ || $file_unique =~ /SHPIMP/ )
					{
					$LocalFile = "$ImportFilePath/shipment/$file_unique";
					}
				elsif ( $file_unique =~ /SHPDTLIMP/ || $file_unique =~ /SHPPRD/ )
					{
					$LocalFile = "$ImportFilePath/product/shipmentproduct/$file_unique";
					}
				else
					{
					print "... Unknown sony filetype: $file_unique";
					next;
					}

				print "\n... downloading file $file to $LocalFile";

				$ftp->get($file,$LocalFile);
				}
			else
				{
				if ( $file_unique =~ /_Shipment_/ )
					{
					$LocalFile = "$ImportFilePath/shipment/$file_unique";
					}
				# AMFQubica
				elsif ( $FTPRef->{'address'} eq '137.117.163.230' )
					{
					if ( $file_unique =~ /_QO/ )
						{
						$LocalFile = "$ImportFilePath/co/$file_unique";
						}
					elsif ( $file_unique =~ /_QP/ )
						{
						$LocalFile = "$ImportFilePath/product/$file_unique";
						}
					else
						{
						$LocalFile = "$ImportFilePath/co/$file_unique";
						}
					}
				# Ernie Ball
				elsif ( $FTPRef->{'address'} eq '66.209.109.195' )
					{
					if ( $file_unique =~ /_orders/ )
						{
						$LocalFile = "$ImportFilePath/co/$file_unique";
						}
					elsif ( $file_unique =~ /_lineitem/ )
						{
						$LocalFile = "$ImportFilePath/product/$file_unique";
						}
					else
						{
						$LocalFile = "$ImportFilePath/co/$file_unique";
						}
					}
				# parts authority
				elsif ( $FTPRef->{'address'} eq '71.190.220.26' )
					{
					$LocalFile = "$ImportFilePath/product/$file_unique";
					}
				elsif ( $FTPRef->{'path'} =~ /product/i )
					{
					$LocalFile = "$ImportFilePath/product/$file_unique";
					}
				elsif ( $FTPRef->{'username'} =~ /garvey/i )
					{
					$LocalFile = "$ImportFilePath/co/garvey/$file_unique";
					}
				else
					{
					$LocalFile = "$ImportFilePath/co/$file_unique";
					}

				print "\n... downloading file $file to $LocalFile";

				$ftp->get($file,$LocalFile);

				if ( $FTPRef->{'customer'} eq 'garveyOFF' && -r $LocalFile )
					{
					#my $from_email = "noc\@intelliship.$config->{BASE_DOMAIN}";
					my $from_email = "noc\@intelliship.engagetechnology.com";
					my $to_email = 'noc@engagetechnology.com';

					my $subject = 'Garvey FTP File';

					SendEmailNotification($from_email,$to_email,undef,undef,$subject,$subject,$LocalFile);
					}
				}

			if (IntelliShip::MyConfig->getDomain eq 'PRODUCTION')
				{
				print "\n... deleting file $file from remote ftp server";
				$ftp->delete($file);
				}
			}

		$ftp->quit();
		}
	else
		{
		print "\n... ftp site is inaccessible";

		## If the ftp site is inaccessible - email the listed admin
		if ( defined($FTPRef->{'email'}) && $FTPRef->{'email'} ne '' )
			{
			my $CurrentTime = strftime("%D %T", localtime);

			#my $from_email = "noc\@intelliship.$config->{BASE_DOMAIN}";
			my $from_email = "noc\@intelliship.engagetechnology.com";
			my $to_email = $FTPRef->{'email'};
			my $subject = "WARNING: Intelliship FTP site $FTPRef->{'customer'} ($FTPRef->{'address'}) is inaccessible ($CurrentTime).";
			my $body = "WARNING: Intelliship FTP site $FTPRef->{'customer'} ($FTPRef->{'address'}) is inaccessible ($CurrentTime).";

			SendEmailNotification($from_email,$to_email,undef,undef,$subject,$body);
			}
		}
	}

print "\n\n";

sub SendEmailNotification
	{
	my ($from_email,$to_email,$cc,$bcc,$subject,$body,$file) = @_;

	my $Email = IntelliShip::Email->new;
	$Email->content_type('text/html');

	$Email->from_address(IntelliShip::MyConfig->no_reply_email);
	$Email->from_name('IntelliShip2');
	$Email->from_address($from_email);

	$Email->add_to($to_email);
	$Email->cc($cc) if $cc;
	$Email->bcc($bcc) if $bcc;

	$Email->subject($subject);
	$Email->add_line($body);

	$Email->attach($file) if $file;
	if ($Email->send)
		{
		print "import failure order notification email successfully sent to " . join(',',@{$Email->to});
		}
	}

__END__
