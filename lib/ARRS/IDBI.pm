package ARRS::IDBI;

use strict;
use DBI;
use Math::BigInt;
use ARRS::COMMON;
use ARRS::BaseCalc;
use IntelliShip::MyConfig;

#####################################################################
##
##	module IDBI
##
##	Engage TMS dbi interface for postgres databases
##
#####################################################################

# Take control from the constructor to insert ourselves into the loop.
sub connect
	{
	my $proto = shift;
	my $class = ref($proto) || $proto;

	my ($HashScale) = @_;
	my %Hash = %$HashScale;

	my ($dbtype, $dbname, $dbhost, $dbuser, $dbpassword, $autocommit, $printerror) = (
		$Hash{'dbtype'},
		$Hash{'dbname'},
		$Hash{'dbhost'},
		$Hash{'dbuser'},
		$Hash{'dbpassword'},
		$Hash{'autocommit'},
		$Hash{'printerror'},
	);

	$dbhost = IntelliShip::MyConfig->getArrsDatabaseHost;

	$autocommit = defined($autocommit) ? $autocommit : 1;
	$printerror = defined($printerror) ? $printerror : 1;
	$dbtype = defined($dbtype) ? $dbtype : "Pg";

	my $self = {};

	if ( $dbtype eq "Oracle" )
		{
		# Set environment variables needed for oracle
		$ENV{'LD_LIBRARY_PATH'} = ':/opt/oracle/u01/app/oracle/product/9.2.0.1.0/lib:/opt/oracle/u01/app/oracle/product/9.2.0.1.0/network/lib';
		$ENV{'ORACLE_BASE'} = '/opt/oracle/u01/app/oracle';
		$ENV{'ORACLE_HOME'} = '/opt/oracle/u01/app/oracle/product/9.2.0.1.0';
		$ENV{'PATH'} = '/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/usr/bin/X11:/usr/X11R6/bin:/opt/oracle/u01/app/oracle/product/9.2.0.1.0/bin:/usr/java/j2sdk1.4.1_01/bin:/root/bin';

		$self->{DBH} = DBI->connect("dbi:Oracle:host=$dbhost;sid=$dbname", "$dbuser", "$dbpassword", {AutoCommit => $autocommit,FetchHashKeyName => 'NAME_lc',PrintError => $printerror});
		}
	elsif ( $dbtype eq "Pg" )
		{
		$self->{DBH} = DBI->connect("dbi:Pg:dbname=$dbname;host=$dbhost", "$dbuser", "$dbpassword", {AutoCommit => $autocommit,PrintError => $printerror});
		# Purolator hack
		}

	$self->{'commit_ok'} = 0;

	if (defined($self->{DBH}))
		{
		bless($self, $class);
		return $self;
		}
	else
		{
		return undef;
		}
	}

sub CommitOK
	{
	my $self = shift;

	if ( $self->{'commit_ok'} == 0 )
		{
		$self->{'commit_ok'} = 1;
		}
	}

sub CommitNotOK
	{
	my $self = shift;

	TraceBack("CommitNotOK Called!");

	$self->{'commit_ok'} = -1;
	}

sub IsCommitOK
	{
	my $self = shift;
	return $self->{'commit_ok'} == 1;
	}

# this functions as the pass through so we don't have to do each dbi function separately.
sub AUTOLOAD
	{
	my $self = shift;
	my $func = $ARRS::IDBI::AUTOLOAD;

	$func =~ s/.*:://;

	return $self->{DBH}->$func(@_);
	}

sub DESTROY
	{
	}

sub seqnumber
	{
	my $self = shift;

	my ($SeqName) = @_;

	my $sth = $self->{DBH}->prepare("SELECT nextval('$SeqName');")
		or TraceBack("Cannot prepare SQL statement: $DBI::errstr", 1);

	$sth->execute()
		or TraceBack("Cannot execute SQL statement: $DBI::errstr", 1);

	my ($SeqID) = $sth->fetchrow_array();

	$sth->finish();
	undef $sth;

	return $SeqID;
	}

sub gettimestamp
	{
	my $self = shift;

	my ($Interval) = @_;

	my $SQLString = "SELECT timestamp 'now' ";

	if (defined($Interval))
		{
		$SQLString .= $Interval;
		}

	my $sth = $self->{DBH}->prepare($SQLString)
		or TraceBack("Cannot prepare SQL statement: $DBI::errstr", 1);

	$sth->execute()
		or TraceBack("Cannot execute SQL statement: $DBI::errstr", 1);

	my ($Timestamp) = $sth->fetchrow_array();

	$sth->finish();
	undef $sth;

	return $Timestamp;
	}

sub convert20to13
	{
	my $self = shift;

	my ($SeqID) = @_;

	#Convert our 20 digit token to a 13 digit token
	my $calc = new ARRS::Math::BaseCalc(digits => [0..9,'A'..'H','J'..'N','P'..'Z']);
	$SeqID = $calc->to_base($SeqID);

	return $SeqID;
	}

sub gettokenid
	{
	my $self = shift;

	my $sth = $self->{DBH}->prepare("
		SELECT
			to_char(current_timestamp, 'YYYYMMDDHH24MISS')||lpad(CAST(nextval('master_seq') AS text), 6, '0')
	")
		or TraceBack("Cannot prepare SQL statement: $DBI::errstr", 1);

	$sth->execute()
		or TraceBack("Cannot execute SQL statement: $DBI::errstr", 1);

	my ($SeqID) = $sth->fetchrow_array();

	$sth->finish();
	undef $sth;

	$SeqID = $self->convert20to13($SeqID);

	return $SeqID;
	}

sub getsectionref
	{
	my $self = shift;

	my ($SQLString) = @_;

	my $DB = $self->{DBH};

	my $ListRef = {};
	my $Counter = 0;

	my $sth = $DB->prepare($SQLString)
		or TraceBack('could not prepare sql statement', 1);

	$sth->execute()
		or TraceBack('could not execute sql statement', 1);

	while (my $HashRef = $sth->fetchrow_hashref())
		{
		$ListRef->{$Counter++} = $HashRef;
		}

	$sth->finish();

	return $ListRef;
	}

sub getdropdownref_escape
	{
	my $self = shift;

	my ($SQLString, @BindVars) = @_;

	my $DB = $self->{DBH};

	my $ListRef = {};
	my $Counter = 0;

	my $sth = $DB->prepare($SQLString) or TraceBack('could not prepare sql statement', 1);

	$sth->execute(@BindVars) or TraceBack('could not execute sql statement', 1);

	while (my ($Key, $Value) = $sth->fetchrow_array())
		{
		$Value =~ s/'/\\'/g;
		$ListRef->{$Counter++} = {
			'key' => $Key,
			'value' => $Value,
			}
		}

	$sth->finish();

	return $ListRef;
	}

sub getdropdownref
	{
	my $self = shift;

	my ($SQLString, @BindVars) = @_;

	my $DB = $self->{DBH};

	my $ListRef = {};
	my $Counter = 0;

	my $sth = $DB->prepare($SQLString) or TraceBack('could not prepare sql statement', 1);

	$sth->execute(@BindVars) or TraceBack('could not execute sql statement', 1);

	while (my ($Key, $Value) = $sth->fetchrow_array())
		{
#		$Value =~ s/'/\\'/g;
		$ListRef->{$Counter++} = {
			'key' => $Key,
			'value' => $Value,
			}
		}

	$sth->finish();
	return $ListRef;
	}

sub insertrecord
	{
	my $self = shift;

	my ($Table, $PrimaryKey, $HashScale) = @_;

	my %Hash = %$HashScale;

#	my $RowCount = $self->countrows($Table);

#	if ($RowCount == 0)
#		{
#warn 'javi';
#warn "insert into $Table ($PrimaryKey) values ('0');";
#			$self->{DBH}->do("insert into $Table ($PrimaryKey) values ('0');");
#warn 'javi';
#		}

	my $sth;

#	my $sth = $self->{DBH}->prepare("SELECT * FROM $Table WHERE rownum = 1;")
#		or die "Cannot prepare SQL statement: $DBI::errstr";
#
#	$sth->execute()
#		or die "Cannot execute SQL statement: $DBI::errstr";
#
#	my $KeyScale = $sth->fetchrow_hashref();
#	my @Keys = keys %$KeyScale;
	my @Keys = keys %$HashScale;
#	$sth->finish();

#	if ($RowCount == 0)
#		{
#warn 'javi';
#warn "delete from $Table where $PrimaryKey = '0';";
#			$self->{DBH}->do("delete from $Table where $PrimaryKey = '0';");
#warn 'javi';
#		}


	# Look up the sequence number if necessary
	if (!defined($Hash{$PrimaryKey}))
		{
		$Hash{$PrimaryKey} = $self->seqnumber($Table . '_seq');
		}

	my $ColString = "";
	my $BindString = "";
	my @bindvars = ();

	foreach my $thekey (@Keys)
		{
		my $Value = $self->{DBH}->quote($Hash{$thekey});

		if ($ColString ne '')
			{
			$ColString .= ', ';
			$BindString .= ', ';
			}

		$ColString .= $thekey;
		$BindString .= $Value;
		}

	my $SQLString = "INSERT INTO $Table ($ColString) VALUES ($BindString);";

#warn $SQLString;
	$sth = $self->{DBH}->prepare($SQLString) or die "Cannot prepare SQL statement: $DBI::errstr";

	$sth->execute() or die "Cannot execute SQL statement: $DBI::errstr";

	$sth->finish();

	return $Hash{$PrimaryKey};
	}

sub countrows
	{
	my $self = shift;

	my ($Table) = @_;

	my $sth = $self->{DBH}->prepare("SELECT count(*) FROM $Table;") or die "Cannot prepare SQL statement: $DBI::errstr";

	$sth->execute() or die "Cannot execute SQL statement: $DBI::errstr";

	my ($RowCount) = $sth->fetchrow_array();
	$sth->finish();
	$sth = undef;

	return $RowCount;
	}

1;
