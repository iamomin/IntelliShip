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
	'DONT-KNOW'              => &PRODUCTION,
	'atx00web01.localdomain' => &DEVELOPMENT,
	);

my %db_hosts = (
	'D-IntelliShip' => &PRODUCTION,
	'D-IntelliShip' => &DEVELOPMENT,
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

	## check to see if hostname exists in %hosts hash
	if ( defined $hosts{uc($hostname)} )
		{
		$domain = $hosts{uc($hostname)};
		}
	else
		{
		$domain = &DEVELOPMENT;
		}

	#print STDERR "\n Mode   : " . $domain;

	return $domain;
	}

=head2 getDatabaseDomain

depending on the server, will return DEVELOPMENT, PRODUCTION or PRODUCTION_NETSCALER.

	my $mode = IntelliShip::MyConfig->getDatabaseDomain;

=cut

sub getDatabaseDomain
	{
	my $db_domain;

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

	## check to see if hostname exists in %db_hosts hash
	if ( defined $db_hosts{uc($hostname)} )
		{
		$db_domain = $db_hosts{uc($hostname)};
		}
	else
		{
		$db_domain = &DEVELOPMENT;
		}

	#print STDERR "\n DataBase Domain: " . $db_domain;

	return $db_domain;
	}

=head2 getSendmailPath

get the path to sendmail

	my $sendmail_path = IntelliShip::MyConfig->getSendmailPath;

=cut

sub getSendmailPath
	{
	return $sendmail_path{getDomain()};
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

__PACKAGE__->meta()->make_immutable();

no Moose;

1;

__END__