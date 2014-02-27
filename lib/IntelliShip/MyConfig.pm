package IntelliShip::MyConfig;

use Moose;
use Sys::Hostname;

=head1 CONFIGURATION SETTINGS

Configuration settings used by this Module are hardcoded into the Module. As new servers are added, an entry will be needed in this module.

Also, for each new server Cluster that is added, information about the cluster will need to be added to the appropriate hash.

=cut

# constants
use constant PRODUCTION   => "PRODUCTION";
use constant DEVELOPMENT  => "DEVELOPMENT";
use constant TEST         => "TEST";

######################################
##   CONFIGURATION SETTINGS START   ##
######################################

# hostname-to-mode hash, any server not listed here is assumed to be production
my %hosts = (
	'DONT-KNOW'  => &PRODUCTION,
	'ENCD00'     => &DEVELOPMENT,
	'RT-XML'     => &TEST,

	'ATX00WEB01.LOCALDOMAIN' => &DEVELOPMENT,
	);

# aos_intelliship DB hosts
my %db_hosts = (
	&PRODUCTION  => 'localhost',
	&DEVELOPMENT => 'dintelliship.engagetechnology.com',
	&TEST        => 'dintelliship.engagetechnology.com',
	);

# arrs DB hosts
my %arrs_db_hosts = (
	&PRODUCTION  => 'localhost',
	&DEVELOPMENT => 'darrs.engagetechnology.com',
	&TEST        => 'darrs.engagetechnology.com',
	);

# sendmail

my %sendmail_path = (
	DEVELOPMENT => "/usr/sbin/sendmail",
	PRODUCTION => "/usr/lib/sendmail",
	TEST => "/usr/lib/sendmail",
	);


## database list
my @db_list = (
	{database => "aos_intelliship", status => 'Active'},
	);

######################################
##    CONFIGURATION SETTINGS END    ##
######################################

=head1 METHODS

=head2 getHostname

returns the standard host name for the current machine.

	my $hostname = IntelliShip::MyConfig->getHostname;

=cut

sub getHostname
	{
	return hostname();
	}

=head2 getDomain

depending on the server, will return DEVELOPMENT, TEST or PRODUCTION.

	my $mode = IntelliShip::MyConfig->getDomain;

=cut

sub getDomain
	{
	my $domain;

	# Determine what machine we are running on...
	my $hostname = uc $ENV{'HOSTNAME'};

	unless ($hostname)
		{
		$hostname = uc hostname();

		if (index($hostname,'.') > -1)
			{
			($hostname) = split(/\./,$hostname);
			}

		$ENV{'HOSTNAME'} = $hostname;
		}

	## check to see if hostname exists in %hosts hash
	if ($hosts{$hostname})
		{
		$domain = $hosts{$hostname};
		}
	else
		{
		$domain = &DEVELOPMENT;
		}

	#print STDERR "\n Mode   : " . $domain;

	return $domain;
	}

=head2 getDatabaseDomain

depending on the server, will return DEVELOPMENT, PRODUCTION or TEST.

	my $mode = IntelliShip::MyConfig->getDatabaseDomain;

=cut

sub getDatabaseDomain
	{
	# Determine what machine we are running on...
	my $hostname = $ENV{'HOSTNAME'};

	unless ($hostname)
		{
		$hostname = hostname();

		if (index($hostname,'.') > -1)
			{
			($hostname) = split(/\./,$hostname);
			}

		$ENV{'HOSTNAME'} = $hostname;
		}

	#print STDERR "\nHOSTNAME: " . $hostname;

	my $db_domain;

	## check to see if hostname exists in %hosts hash
	unless ($db_domain = $hosts{$hostname})
		{
		$db_domain = &DEVELOPMENT;
		}

	#print STDERR "\nDataBase Domain: " . $db_domain;

	return $db_domain;
	}

=head2 getDatabaseHost

depending on the server, will return DEVELOPMENT, PRODUCTION or TEST.

	my $mode = IntelliShip::MyConfig->getDatabaseHost;

=cut

sub getDatabaseHost
	{
	## check to see if hostname exists in %db_hosts hash
	my $domain = getDatabaseDomain() || '';

	my $db_host;
	unless ($db_host = $db_hosts{$domain})
		{
		$db_host = 'localhost';
		}

	#print STDERR "\nDataBase Host: " . $db_host;

	return $db_host;
	}

=head2 getArrsDatabaseHost

depending on the server, will return DEVELOPMENT, PRODUCTION or TEST.

	my $mode = IntelliShip::MyConfig->getArrsDatabaseHost;

=cut

sub getArrsDatabaseHost
	{
	## check to see if hostname exists in %db_hosts hash
	my $domain = getDatabaseDomain() || '';

	my $db_host;
	unless ($db_host = $arrs_db_hosts{$domain})
		{
		$db_host = 'localhost';
		}

	#print STDERR "\nArrs DataBase Host: " . $db_host;

	return $db_host;
	}

=head2 getSendmailPath

get the path to sendmail

	my $sendmail_path = IntelliShip::MyConfig->getSendmailPath;

=cut

sub getSendmailPath
	{
	return $sendmail_path{getDomain()};
	}

sub application_root
	{
	my $self = shift;

	my $application_root = '';
	if (getDomain() eq &TEST)
		{
		$application_root = '/var/intelliship/git/IntelliShip/';
		}
	else
		{
		$application_root = '/opt/engage/intelliship2/IntelliShip';
		}

	return $application_root;
	}

my $ARRS_CONFIG = {
	BASE_PATH      => application_root(),
	DB_NAME        => 'arrs',
	DB_HOST        => getArrsDatabaseHost(),
	DB_USER        => 'webuser',
	DB_PASSWORD    => 'Byt#Yu2e',
	BASE_DOMAIN    => 'engagetechnology.com',
	HALO_PATH      => '/opt/engage/halo',
	ADMIN_USER     => 'engage',
	ADMIN_PASSWORD => 'ohila4'
	};

sub get_ARRS_configuration
	{
	my $self = shift;
	return $ARRS_CONFIG;
	}

sub getActiveDatabaseList
	{
	my @active_db_list;
	foreach my $db_hash (@db_list)
		{
		next unless ($db_hash->{status} eq 'Active');
		push(@active_db_list, $db_hash);
		}
	return @active_db_list;
	}

sub no_reply_email
	{
	my $self = shift;
	return 'NO_REPLY@engagetechnology.com';
	}

sub base_path
	{
	my $self = shift;
	return '/opt/engage/intelliship';
	}

sub import_directory
	{
	my $self = shift;
	return $self->base_path . '/var/import';
	}

sub file_directory
	{
	my $self = shift;
	return $self->base_path . '/var/log/intelliship/files';
	}

sub report_file_directory
	{
	my $self = shift;
	return $self->base_path . '/var/log/intelliship/reports';
	}

sub image_file_directory
	{
	my $self = shift;
	return $self->application_root . '/root/static/images';
	}

__PACKAGE__->meta()->make_immutable();

no Moose;

1;

__END__