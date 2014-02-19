#!/usr/bin/perl -w

#==========================================================
#   Project:	ARRS
#
#   Filename:	DBOBJECT
#
#   Date:		02/14/2002
#   Rewrite:	06/12/2002
#
#   Purpose:	DB Object Handling
#
#   Company:	Engage TMS
#
#   Author(s):	Kirk Aksdal
#					Leigh Bohannon
#
#==========================================================

{
	package ARRS::DBOBJECT;

	use strict;

	use ARRS::COMMON;

	sub new
	{
		my $proto = shift;
		my $class = ref($proto) || $proto;

		my ($DBRef, $Contact) = @_;

		my $self = {};

		$self->{'object_dbref'} = $DBRef;		# Handle to the database
		$self->{'object_contact'} = $Contact;	# The current user
		$self->{'object_errorstring'} = '';		# Errors are passed back this way
		$self->{'object_initialized'} = 0;		# Set true on create/load
		$self->{'object_issuper'} = 0;			# Used for special superuser cases

		# Child object will override these
		$self->{'object_tablename'} = '';		# The DB table name
		$self->{'object_primarykey'} = '';		# The DB table primary key
		$self->{'object_fieldlist'} = [];		# The list of DB fields

		bless($self, $class);

		return $self;
	}

	sub IsInitialized
	{
		my $self = shift;

		return $self->{'object_initialized'};
	}

	sub IsOwner
	{
		my $self = shift;

		return 0;
	}

	sub IsGuest
	{
		my $self = shift;

		return 0;
	}

	sub GetLastError
	{
		my $self = shift;

		return $self->{'object_errorstring'};
	}

	sub CanDo
	{
		my $self = shift;
		my ($Key) = @_;

my $DEBUG = 0;

if ($DEBUG) {warn $self->{'object_tablename'}."->CanDo($Key)";}

		if (defined($self->{'object_issuper'}) && $self->{'object_issuper'} == 1)
		{
			return 1;
		}
		elsif (!defined($self->{'object_contact'}))
		{
if ($DEBUG) {TraceBack('CONTACT NOT DEFINED');}
			return 0;
		}
		elsif (!$self->{'object_contact'}->IsAuthenticated())
		{
if ($DEBUG) {TraceBack('CONTACT NOT AUTHENTICATED');}
			return 0;
		}
		elsif ($self->{'object_contact'}->HasKey('superuser') || $self->{'object_contact'}->HasKey('master'))
		{
if ($DEBUG) {TraceBack('SUPERUSER OVERRIDE');}
			return 1;
		}
		elsif ($self->{'object_contact'}->HasKey('manager'))
		{
if ($DEBUG) {TraceBack('MANAGER OVERRIDE');}
			return 1;
		}
		elsif (!$self->{'object_contact'}->HasKey($Key))
		{
if ($DEBUG) {TraceBack('CONTACT DOES NOT HAVE KEY: '.$Key);}
			return 0;
		}
		elsif ($self->IsOwner())
		{
if ($DEBUG) {TraceBack('CONTACT IS OWNER');}
			return 1;
		}
		elsif ($self->IsGuest())
		{
if ($DEBUG) {TraceBack('CONTACT IS GUEST');}
			return 1;
		}

		return 0;
	}

	sub Delete
	{
		my $self = shift;

		if (!$self->{'object_initialized'})
		{
			$self->{'object_errorstring'} = 'Object Not Initialized';
			TraceBack($self->{'object_errorstring'}, 1);
		}

		# Permissions check table scope
		if (!$self->CanDo('DELETE'))
		{
			$self->{'object_errorstring'} = 'Permission Denied';
			TraceBack($self->{'object_errorstring'});
			return 0;
		}

		my $SQLString = "DELETE FROM ".$self->{'object_tablename'}." WHERE ".
			$self->{'object_primarykey'}." = ?";

		$self->{'object_dbref'}->do($SQLString, undef, $self->{'field_'.$self->{'object_primarykey'}})
			or TraceBack("could not delete", 1);

		$self->{'object_dbref'}->CommitOK();

		return 1;
	}

	# Create a new database object
	sub Create
	{
		my $self = shift;

		if (!defined($self->{'field_'.$self->{'object_primarykey'}}) || $self->{'field_'.$self->{'object_primarykey'}} eq "")
		{
			$self->{'field_'.$self->{'object_primarykey'}} = $self->{'object_dbref'}->gettokenid();
		}

		$self->{'field_updatetoken'} = $self->{'object_dbref'}->gettokenid();
		$self->{'field_datecreated'} = $self->{'object_dbref'}->gettimestamp();

		my $FieldString = '';
		my $BindString = '';
		my @BindArray = ();

		foreach my $Field ($self->GetFieldList())
		{
			if ($FieldString ne '')
			{
				$FieldString .= ', ';
				$BindString .= ', ';
			}

			$FieldString .= $Field;

			# Turn this on for debug, off for normal ops.
			if (1)
			{
				if ( !defined($self->{'field_'.$Field}) || $self->{'field_'.$Field} eq '' )
				{
					$self->{'field_'.$Field} = undef;
				}

				$BindString .= $self->{'object_dbref'}->quote($self->{'field_'.$Field});;
			}
			else
			{
				$BindString .= '?';
				@BindArray = (@BindArray, $self->{'field_'.$Field});
			}
		}

		my $Table = $self->{'object_tablename'};
		my $SQLString = "INSERT INTO $Table ($FieldString) VALUES ($BindString)";
#warn $SQLString;
foreach my $Bind (@BindArray) { if (defined($Bind)&& $Bind ne '') { warn $Bind; }}
		#$self->{'object_dbref'}->do("LOCK TABLE milestone IN SHARE ROW EXCLUSIVE MODE") or die;
		#$self->{'object_dbref'}->do("LOCK TABLE workorder IN SHARE ROW EXCLUSIVE MODE") or die;
		#$self->{'object_dbref'}->do("LOCK TABLE subworkorder IN SHARE ROW EXCLUSIVE MODE") or die;
		#$self->{'object_dbref'}->do("LOCK TABLE billing IN SHARE ROW EXCLUSIVE MODE") or die;
		#$self->{'object_dbref'}->do("LOCK TABLE tracking IN SHARE ROW EXCLUSIVE MODE") or die;
		#$self->{'object_dbref'}->do("LOCK TABLE product IN SHARE ROW EXCLUSIVE MODE") or die;

		$self->{'object_dbref'}->do($SQLString, undef, @BindArray)
			or TraceBack("could not insert ".$SQLString, 1);
		$self->{'object_dbref'}->CommitOK();

		$self->{'object_initialized'} = 1;

		# Permissions check table scope
		if (!$self->CanDo('INSERT'))
		{
			$self->{'object_errorstring'} = 'Permission Denied';
			TraceBack($self->{'object_errorstring'});
			$self->{'object_initialized'} = 0;
			$self->{'object_dbref'}->CommitNotOK();
			return 0;
		}

		return 1;
	}

	sub Commit
	{
		my $self = shift;

		if (!$self->{'object_initialized'})
		{
			$self->{'object_errorstring'} = 'Object Not Initialized';
			TraceBack($self->{'object_errorstring'});
			return 0;
		}

		# Permissions check table scope
		if (!$self->CanDo('UPDATE'))
		{
			$self->{'object_errorstring'} = 'Permission Denied';
			TraceBack($self->{'object_errorstring'});
			return 0;
		}

		my $FieldString = '';
		my @BindArray = ();

		$self->{'field_updatetoken'} = $self->{'object_dbref'}->gettokenid();

		my $Table = $self->{'object_tablename'};
		my $PrimaryKey = $self->{'object_primarykey'};
		my $PrimaryKeyValue = $self->{'object_dbref'}->quote($self->{'field_'.$PrimaryKey});

		foreach my $Field ($self->GetFieldList())
		{
			if ($FieldString ne '')
			{
				$FieldString .= ', ';
			}

			if ( !defined($self->{'field_'.$Field}) || $self->{'field_'.$Field} eq '' )
			{
				$self->{'field_'.$Field} = undef;
			}
#			$FieldString .= "$Field = ".$self->{'object_dbref'}->quote($self->{'field_'.$Field});
			$FieldString .= "$Field = ?";
			@BindArray = (@BindArray, $self->{'field_'.$Field});
		}

		my $SQLString = "UPDATE $Table SET $FieldString WHERE $PrimaryKey = $PrimaryKeyValue";
#if ($self->{'object_tablename'} eq 'milestone')
#{
#my $BindString = join(', ', @BindArray);
#warn $SQLString;
#warn $BindString;
#}

	#	$self->{'object_dbref'}->do("LOCK TABLE milestone IN SHARE ROW EXCLUSIVE MODE") or die;
	#	$self->{'object_dbref'}->do("LOCK TABLE workorder IN SHARE ROW EXCLUSIVE MODE") or die;
	#	$self->{'object_dbref'}->do("LOCK TABLE subworkorder IN SHARE ROW EXCLUSIVE MODE") or die;
	#	$self->{'object_dbref'}->do("LOCK TABLE billing IN SHARE ROW EXCLUSIVE MODE") or die;
	#	$self->{'object_dbref'}->do("LOCK TABLE tracking IN SHARE ROW EXCLUSIVE MODE") or die;
	#	$self->{'object_dbref'}->do("LOCK TABLE product IN SHARE ROW EXCLUSIVE MODE") or die;

		$self->{'object_dbref'}->do($SQLString, undef, @BindArray)
			or TraceBack("could not update: ".$SQLString, 1);
		$self->{'object_dbref'}->CommitOK();


		return 1;
	}

	# Reload the object from database.
	sub Reload
	{
		my $self = shift;

		return $self->Load($self->{$self->{'object_primarykey'}});
	}

	# Retrieve the objects properties from the database
	sub Load
	{
		my $self = shift;

		return $self->LowLevelLoad($self->{'object_primarykey'}, @_);
	}

	# Retrieve the objects properties from the database
	sub LowLevelLoadAdvanced
	{
		my $self = shift;
		warn "############# LowLevelLoadAdvanced ".$self->{'object_tablename'};
		my $tstart = time;
		
		my ($UpdateToken, $LookupHashRef) = @_;

		my $ReturnValue = 0;

		my @BindVars = ();

		my $SQLString = "SELECT * FROM ".$self->{'object_tablename'}." WHERE ";

		my $First = 1;
		foreach my $Key (keys(%$LookupHashRef))
		{
			if (!$First)
			{
				$SQLString .= ' AND ';
			}
			$SQLString .= $Key." = ? ";
			$First = 0;
			@BindVars = (@BindVars, $LookupHashRef->{$Key});
		}

		if (defined($UpdateToken))
		{
			$SQLString .= " AND updatetoken = ?";
			push(@BindVars, $UpdateToken);
		}

		warn "############# SQLString: ".$SQLString . "\n ". @BindVars;
		my $sth = $self->{'object_dbref'}->prepare($SQLString)
			or die "Could not prepare SQL statement";

		$sth->execute(@BindVars)
			or die "Cannot execute sql statement";

		if (my $DataRef = $sth->fetchrow_hashref())
		{
			foreach my $key (keys(%$DataRef))
			{
				$self->{'field_'.$key} = $DataRef->{$key};
			}

			$ReturnValue = 1;

			$self->{'object_initialized'} = 1;
		}

		$sth->finish();

		# Permissions check table scope
		if (!$self->CanDo('read'))
		{
			$self->{'errorstring'} = 'Permission Denied';
			$self->{'object_initialized'} = 0;
			$ReturnValue = 0;
		}

		warn "############# Time taken by LowLevelLoadAdvanced: ". (time - $tstart);
		return $ReturnValue;
	}

	# Retrieve the objects properties from the database
	sub LowLevelLoad
	{
		my $self = shift;
		my ($PKName, $PKValue, $UpdateToken) = @_;

		$self->{'object_initialized'} = 0;

		my @BindVars = ($PKValue);

		my $SQLString = "SELECT * FROM ".$self->{'object_tablename'}." WHERE ".$PKName." = ?";

		my $sth = $self->{'object_dbref'}->prepare($SQLString)
			or TraceBack("Could not prepare SQL statement", 1);

		$sth->execute(@BindVars)
			or TraceBack("Cannot execute sql statement", 1);

		if (my $DataRef = $sth->fetchrow_hashref())
		{
			foreach my $key (keys(%$DataRef))
			{
				$self->{'field_'.$key} = $DataRef->{$key};
			}

			$self->{'object_initialized'} = 1;
		}

		$sth->finish();

		# Permissions check table scope
		if ($self->{'object_initialized'} && !$self->CanDo('READ'))
		{
			$self->{'object_errorstring'} = 'Permission Denied';
			TraceBack($self->{'object_errorstring'});
			$self->{'object_initialized'} = 0;
			return 0;
		}

		return $self->{'object_initialized'};
	}

	sub CreateOrLoadCommit
	{
		my $self = shift;
		my ($DataRef) = @_;
		if (
			defined($DataRef->{$self->{'object_primarykey'}}) &&
			$DataRef->{$self->{'object_primarykey'}} ne '' &&
			$self->Load($DataRef->{$self->{'object_primarykey'}})
		)
		{
			$self->SetValuesArray(%$DataRef);
			return $self->Commit();
		}
		else
		{
			$self->SetValuesArray(%$DataRef);
			return $self->Create();
		}
	}

	sub CreateOrLoadCommitArray
	{
		my $self = shift;
		my @DataArray = @_;
		my %DataHash = @DataArray;
		my $DataRef = \%DataHash;

		if (
			defined($DataRef->{$self->{'object_primarykey'}}) &&
			$DataRef->{$self->{'object_primarykey'}} ne '' &&
			$self->Load($DataRef->{$self->{'object_primarykey'}})
		)
		{
			$self->SetValuesArray(@DataArray);
			return $self->Commit();
		}
		else
		{
			$self->SetValuesArray(@DataArray);
			return $self->Create();
		}
	}

	# This function WILL stomp.
	sub SetValuesArray
	{
		my $self = shift;
		my (@KeysValues) = @_;

		my $TempCounter = 250;

#my @tempFields = $self->GetFieldList();
#my $str_tempFields = join(',', @tempFields);
#TraceBack($str_tempFields, 0);

		foreach my $Field ($self->GetFieldList())
		{
			my @TempValues = @KeysValues;
			while (scalar(@TempValues))
			{
				my $Key = shift @TempValues;
				my $Value = shift @TempValues;

				if ($Key eq $Field)
				{
					$self->{'field_'.$Field} = $Value;
#if (defined($Value) && $Value ne '')
#{
#warn "$Field = $Value";
#}
					last;
				}
			}
if ($TempCounter-- <= 0)
{
	last;
}
		}

		return 1;
	}

	# This function will NOT stomp.
	sub SetValues
	{
		my $self = shift;
		my ($HashRef) = @_;

		foreach my $Field ($self->GetFieldList())
		{
			if (defined($HashRef->{$Field}) && $HashRef->{$Field} ne '')
			{
				$self->{'field_'.$Field} = $HashRef->{$Field};
#warn $Field."=".$HashRef->{$Field};
			}
		}

		return 1;
	}

	# Retrive a hashref loaded with all the db fields and their values.
	sub GetValueHashRef
	{
		my $self = shift;

		if (!$self->{'object_initialized'})
		{
			$self->{'object_errorstring'} = 'Object Not Initialized';
			TraceBack($self->{'object_errorstring'});
			return 0;
		}

		my $FieldHash = {};
		foreach my $FieldName ($self->GetFieldList())
		{
			$FieldHash->{$FieldName} = $self->{'field_'.$FieldName};
		}

		return $FieldHash;
	}

	sub GetFieldList
	{
		my $self = shift;

		return @{$self->{'object_fieldlist'}};
	}

	sub GetWorstCondition
	{
		my $self = shift;
		my ($WorstCondition, $SQLString, @BindArray) = @_;

		my $STH = $self->{'object_dbref'}->prepare($SQLString)
			or TraceBack("Could not prepare sql.", 1);

		$STH->execute(@BindArray)
			or TraceBack("Could not execute sql.", 1);

		if (my ($Condition) = $STH->fetchrow_array())
		{
			$WorstCondition = $Condition;
		}

		$STH->finish();

		return $WorstCondition
	}

	sub GetCreatedYear
	{
		my $self = shift;

		if ( defined($self->{'field_datecreated'}) && $self->{'field_datecreated'} ne '' )
		{
			my ($CreatedYear) = $self->{'field_datecreated'} =~ /^(\d{4})-\d{2}-\d{2}/;
			return $CreatedYear;
		}
		else
		{
			return undef;
		}
	}
}

1;
