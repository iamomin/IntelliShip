#!/usr/bin/perl -w

#==========================================================
#   Project:	ARRS
#
#   Filename:	CONTACT
#
#   Date:		02/14/2002
#
#   Purpose:	CONTACT Handling
#
#   Company:	Engagte TMS
#
#   Author(s):	Kirk Aksdal
#					Leigh Bohannon
#
#==========================================================

{
	package ARRS::CONTACT;

	use strict;
	use ARRS::DBOBJECT;
	@ARRS::CONTACT::ISA = ("ARRS::DBOBJECT");

	use ARRS::COMMON;
	use ARRS::CONTACTIP;
	use ARRS::TOKEN;
	use IntelliShip::MyConfig;

	my $UnderConstruction = 0;
	my $config = IntelliShip::MyConfig->get_ARRS_configuration;

	sub new
	{
		my $proto = shift;
		my $class = ref($proto) || $proto;

		my $self = $class->SUPER::new(@_);

		# Override these properties
		$self->{'object_tablename'} = 'contact';
		$self->{'object_primarykey'} = 'contactid';
		$self->{'object_fieldlist'} = ['contactid','customerid','keyringid','username','password','firstname','lastname','email','phonemobile','phonebusiness','datecreated','datedeactivated'];

		# Contact specific properties
		$self->{'object_authenticated'} = 0;
		$self->{'object_keysloaded'} = 0;
		$self->{'object_keys'} = {};
		$self->{'object_screensloaded'} = 0;
		$self->{'object_screens'} = {};

		bless($self, $class);
		return $self;
	}

	sub IsOwner
	{
		my $self = shift;

		return $self->{'object_contact'}->CanAccessCompany($self->GetValueHashRef()->{'companyid'});
	}

	sub IsAuthenticated
	{
		my $self = shift;

		return $self->{'object_initialized'} && $self->{'object_authenticated'};
	}

	sub TokenID
	{
		my $self = shift;

		if ($self->{'object_initialized'} && $self->{'object_authenticated'})
		{
			return $self->{'object_token'}->GetValueHashRef()->{'tokenid'};
		}

		return undef;
	}

	sub Logout
	{
		my $self = shift;
		my ($TokenID) = @_;

		if (!$self->IsAuthenticated())
		{
			return 0;
		}

		$TokenID = (defined($TokenID) && $TokenID ne '') ? $TokenID : $self->TokenID();

		$self->{'object_dbref'}->do("DELETE FROM token WHERE tokenid = ?", undef, $TokenID)
			or TraceBack( "Could not execute delete expired tokens SQL statement", 1);

		$self->{'object_dbref'}->commit();

		return 1;
	}

	sub CanAccessCompany
	{
		my $self = shift;
		my ($CompanyID) = @_;

		$CompanyID = DefaultTo($CompanyID,$self->GetValueHashRef()->{'companyid'});

		# Ops and managers can access all companies, all the time (for 'IsOwner' purposes)
		if ( $self->HasKey('manager') || $self->HasKey('operator') )
		{
			return 1;
		}
		else
		{
			# Work on this  - just kludged so we don't have to deal with it at the moment
			return 1;
		}
	}

	sub Authenticate
	{
		my $self = shift;
		my ($IPAddress, $Username, $Password, $TokenID) = @_;

		my $Commit = shift || 1;

		# This is how we shut down outside access while we're testing, etc.
		if ( $UnderConstruction && (!defined($TokenID) || $TokenID eq '') && $0 =~ m"$config->{HALO_PATH}/html/index.cgi" )
		{
			my ($Const, $NewPassword) = split('_', $Password);
			$Password = $NewPassword;

			if ($Const ne 'const')
			{
				$self->{'object_errorstring'} = 'HALO is being upgraded.  Please check back shortly.';
				return 0;
			}
		}

		my ($NewTokenID,$ContactID);
		my $Return = 0;

		my $Token = new ARRS::TOKEN($self->{'object_dbref'}, $self);

# Have each arrs session delete its own token (Logout())...this should help with delete issues when arrs is
# receiving lots of rapid calls.
# Addendum - still not sure how this will work with remote calls, which I still think we need to account for.
# Leave it as is, for now.  Kirk, 2008-05-28
		$self->{'object_dbref'}->do("DELETE FROM token WHERE (dateexpires <= current_date)")
			or TraceBack("Could not execute delete expired tokens SQL statement", 1);

		# Check existing token
		if (defined($TokenID) && $TokenID ne '')
		{
			($NewTokenID, $ContactID) = $self->AuthenticateToken($IPAddress, $TokenID);
		}
		# Login
		elsif (defined($Username) && defined($Password) && $Username ne '' && $Password ne '')
		{
			($NewTokenID, $ContactID) = $self->AuthenticateUser($Username, $Password, $IPAddress);
		}

		$self->{'object_issuper'} = 1;
		$Token->{'object_issuper'} = 1;

		if (!defined($NewTokenID) || !defined($ContactID))
		{
			$self->{'object_errorstring'} = 'Invalid Session';
		}
		elsif(!$self->Load($ContactID))
		{
			$self->{'object_errorstring'} = 'Invalid Login';
		}
		elsif( $NewTokenID eq '-2' )
		{
			$self->{'object_errorstring'} = 'Invalid Session';
		}
		elsif(!$Token->Load($NewTokenID))
		{
			$self->{'object_errorstring'} = 'Unknown Error';
		}
		elsif( $self->GetValueHashRef()->{'iprestricted'} && !$self->ValidContactIP($ContactID,$IPAddress) )
		{
			$self->{'object_errorstring'} = 'Invalid Contact IP Address';
		}
		else
		{
			$self->{'object_token'} = $Token;
			$self->{'object_errorstring'} = '';
			$self->{'object_authenticated'} = 1;
			$Return = 1;
		}

		$self->{'object_issuper'} = 0;
		$Token->{'object_issuper'} = 0;

		$self->{'object_dbref'}->commit();

		return $Return;
	}

	sub AuthenticateToken
	{
		my $self = shift;
		my ($IPAddress, $TokenID, $ScreenName) = @_;
		my $STH = $self->{'object_dbref'}->prepare("
			SELECT
				tokenid,
				contactid,
				datecreated
			FROM
				token
			WHERE
				tokenid = ?
				AND ipaddress = ?
		")
			or TraceBack("Could not prepare SQL statement", 1);

		$STH->execute($TokenID, $IPAddress)
			or TraceBack("Could not execute SQL statement", 1);

		my ($NewTokenID, $ContactID, $DateCreated) = $STH->fetchrow_array();
		$STH->finish();

		if (defined($NewTokenID) && $NewTokenID ne '')
		{
			# Update token expire time
			my $STH_update = $self->{'object_dbref'}->prepare("
				UPDATE
					token
				SET
					dateexpires = current_date + interval '1' hour,
					screenname = ?
				WHERE
					tokenid = ?
			")
				or TraceBack("Could not prepare sql token update statement", 1);

			$STH_update->execute($ScreenName, $NewTokenID)
				or TraceBack("Could not prepare sql token update statement", 1);

			$STH_update->finish();
		}

		return ($NewTokenID, $ContactID);
	}

	sub AuthenticateUser
	{
		my $self = shift;
		my ($Username, $Password, $IPAddress) = @_;

		my $SQL = "
			SELECT
				contactid
			FROM
				contact
			WHERE
				username = ?
				AND password = ?
				AND contact.datedeactivated is null
		";

		my $STH = $self->{'object_dbref'}->prepare($SQL)
			or TraceBack("Could not prepare SQL statement", 1);

		$STH->execute($Username, $Password)
			or TraceBack("Could not execute SQL statement", 1);

		my ($ContactID) = $STH->fetchrow_array();

		my $TokenID = undef;
		if (defined($ContactID))
		{
			$TokenID = $self->{'object_dbref'}->gettokenid();

			$self->{'object_dbref'}->do("
				INSERT INTO token
					(tokenid, contactid, datecreated, dateexpires, ipaddress)
				VALUES
					(?, ?, current_date, current_date + interval '1' hour, ?)",
				undef,
				$TokenID,
				$ContactID,
				$IPAddress
			)
				or TraceBack("Could not execute SQL statement", 1);
		}

		return ($TokenID, $ContactID);
	}

	sub HasKey
	{
		my $self = shift;
		my ($Key) = @_;

		if (!$self->{'object_keysloaded'})
		{
			my $STH = $self->{'object_dbref'}->prepare("
				SELECT
					krk.keyname
				FROM
					keyringkey krk
				WHERE
					krk.keyringid = ?
			")
				or TraceBack("Could not prepare SQL statement", 1);

			$STH->execute($self->GetValueHashRef()->{'keyringid'})
				or TraceBack("Could not execute SQL statement", 1);

			while (my ($KeyName) = $STH->fetchrow_array())
			{
				$self->{'object_keys'}->{$KeyName} = 1;
			}

			$STH->finish();

			$self->{'object_keysloaded'} = 1;
		}

		return defined($self->{'object_keys'}->{$Key}) ? 1 : 0;
	}

	sub IsEngage
	{
		my $self = shift;

		if
		(
			$self->HasKey('operator') ||
			$self->HasKey('sales') ||
			$self->HasKey('superuser') ||
			$self->HasKey('master') ||
			$self->HasKey('accountant') ||
			$self->HasKey('manager')
		)
		{
			return 1;
		}
		else
		{
			return 0;
		}
	}

	sub IsNotEngage
	{
		my $self = shift;

		if
		(
			$self->HasKey('customer') ||
			$self->HasKey('customer2') ||
			$self->HasKey('carrier') ||
			$self->HasKey('carrier2')
		)
		{
			return 1;
		}
		else
		{
			return 0;
		}
	}

	sub IsCustomer
	{
		my $self = shift;

		if
		(
			$self->HasKey('customer') ||
			$self->HasKey('customer2')
		)
		{
			return 1;
		}
		else
		{
			return 0;
		}
	}

	sub IsCarrier
	{
		my $self = shift;

		if
		(
			$self->HasKey('carrier') ||
			$self->HasKey('carrier2')
		)
		{
			return 1;
		}
		else
		{
			return 0;
		}
	}

	sub CanAccess
	{
		my $self = shift;
		my ($Screen) = @_;

		if ( $self->HasKey('superuser') || $self->HasKey('master') )
		{
			return 1;
		}
		if (!$self->{'object_screensloaded'})
		{
			my $STH = $self->{'object_dbref'}->prepare("
				SELECT
					krs.screenname
				FROM
					keyringscreen krs
				WHERE
					krs.keyringid = ?
			")
				or TraceBack("Could not prepare SQL statement", 1);

			$STH->execute($self->GetValueHashRef()->{'keyringid'})
				or TraceBack("Could not execute SQL statement", 1);

			while (my ($ScreenName) = $STH->fetchrow_array())
			{
				$self->{'object_screens'}->{$ScreenName} = 1;
			}

			$STH->finish();

			$self->{'object_screensloaded'} = 1;
		}

		return defined($self->{'object_screens'}->{$Screen}) ? 1 : 0;
	}

	sub Deactivate
	{
		my $self = shift;

		$self->SetValuesArray('datedeactivated', $self->{'object_dbref'}->gettimestamp());
		$self->Commit();
	}

	sub ValidContactIP
	{
		my $self = shift;
		my ($ContactID,$IPAddress) = @_;

		my $ContactIP = new ARRS::CONTACTIP($self->{'object_dbref'}, $self);

		$ContactIP->{'object_issuper'} = 1;

		if ( !$ContactIP->LowLevelLoadAdvanced(undef,{'contactid',$ContactID,'ipaddress',$IPAddress}) )
		{
			return 0;
		}
		else
		{
			return 1;
		}
	}
}

1;
