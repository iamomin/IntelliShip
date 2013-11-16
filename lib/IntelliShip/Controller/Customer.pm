package IntelliShip::Controller::Customer;
use Moose;
use Data::Dumper;
use Math::BaseCalc;
use IntelliShip::DateUtils;
use namespace::autoclean;

BEGIN {

	extends 'IntelliShip::Errors';
	extends 'Catalyst::Controller';

	has 'context' => ( is => 'rw' );
	has 'token' => ( is => 'rw' );
	has 'token' => ( is => 'rw' );
	has 'contact' => ( is => 'rw' );
	has 'customer' => ( is => 'rw' );

	}

=head1 NAME

IntelliShip::Controller::Customer - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

	$c->log->debug('In ' . __PACKAGE__ . ', index');
    #$c->response->body('Matched IntelliShip::Controller::Customer in Customer.');
}

=head2 default

Standard 404 error page

=cut

sub default :Path
	{
	my ( $self, $c ) = @_;
	$c->response->redirect($c->uri_for('/customer/login'));
	}

sub access_denied :Private
	{
	my ( $self, $c ) = @_;
	my $params = $c->request->parameters;

	$c->response->body( "Access Denied" );
	}

sub logout :Local :Args(0)
	{
	my ( $self, $c ) = @_;

	$c->log->debug('@@@@@@@@ DELETING TOKEN ID: ' . $self->token->tokenid);
	$self->token->delete;
	$self->token(undef);

	$c->response->redirect($c->uri_for('/customer/login'));
	}

sub login :Local :Args(0)
	{
	my ( $self, $c ) = @_;

	$c->log->debug("========== LOG IN CUSTOMER USER");

	my $params = $c->request->parameters;
	my $Token = $self->get_token;

	if ($Token)
		{
		$self->token($Token);
		$c->detach("dashboard",$params);
		}
	elsif (defined $params->{'username'} and defined $params->{'password'})
		{
		my $TokenID = $self->authenticate_user($params->{'username'}, $params->{'password'});

		unless ($TokenID)
			{
			$c->log->debug('$$$$$$ CUSTOMER USER NOT FOUND $$$$$$');
			$c->stash(template => "templates/customer/login.tt");
			$c->stash(error => "Invalid username or password");
			return 0;
			}

		$c->res->cookies->{'TokenID'} = { value => $TokenID, expires => '+3600' };

		$c->stash(template => "templates/customer/dashboard.tt");
		}
	else
		{
		$c->stash(template => "templates/customer/login.tt"); ## SHOW LOGIN PAGE FIRST
		}

	return 1;
	}

sub dashboard :Local :Args(0)
	{
	my ( $self, $c ) = @_;
	$c->stash(template => "templates/customer/dashboard.tt");
	return 1;
	}

sub authenticate_user :Private
	{
	my $self = shift;
	my $c = $self->context;

	my ($Username, $Password, $BrandingID, $SSOUsername, $SSOAuth) = @_;

	my ($Customer, $Contact ) = $self->get_customer_contact($Username,$Password);

	my ($CustomerID, $ContactID, $ActiveUser);

	if ($Customer and $Contact)
		{
		$ContactID = $Contact->contactid;
		$CustomerID = $Customer->customerid;

		#$ActiveUser = ($Contact->firstname ? $Contact->firstname : $Contact->username);
		$ActiveUser = $Contact->username;
		$BrandingID = $self->get_branding_id;

		$c->log->debug("ActiveUser: " . $ActiveUser);
		$c->log->debug("BrandingID: " . $BrandingID);

		$self->contact($Contact);
		$self->customer($Customer);
		}

	my $TokenID = undef;
	my $myDBI = $c->model("MyDBI");

	if ($ContactID)
		{
		$TokenID = $self->get_token_id;

		$c->stash->{TokenID} = $TokenID;

		$c->log->debug("#### Creating new session for token: " . $TokenID);

		($BrandingID, $SSOUsername, $SSOAuth) = ('','',''); ##**

		my $sql = "INSERT INTO token
					(tokenid, customerid, datecreated, dateexpires,active_username,brandingid,ssoid)
				VALUES
					('$TokenID', '$ContactID', timestamp 'now', timestamp 'now' + '2 hours', '$Username', '$BrandingID', '$SSOAuth')";

		$myDBI->dbh->do($sql);

		$self->token($c->model("MyDBI::Token")->find($TokenID));
		}

	$c->log->debug("#### FLUSH EXPIRED TOKEN FROM DB");
	$myDBI->dbh->do("DELETE FROM token WHERE dateexpires <= timestamp 'now'");

	return $TokenID;
	}

sub authorize_user :Private
	{
	my $self = shift;
	my $c = $self->context;
	my ($NewTokenID, $CustomerID, $ContactID, $ActiveUser,$MyBrandingID) = $self->authenticate_token;
	return $NewTokenID;
	}

sub authenticate_token :Private
	{
	my $self = shift;
	my $c = $self->context;

	my $TokenID = $self->get_login_token;

	$c->log->debug("**** Authorize Customer User, Token ID: " . $TokenID);

	my ($NewTokenID, $CustomerID, $ContactID, $ActiveUser, $BrandingID);

	my $Token = $c->model("MyDBI::Token")->find({ tokenid => $TokenID });

	if ($Token)
		{
		$NewTokenID = $Token->tokenid;
		$self->token($Token);

		my ($Customer,$Contact) = $self->get_customer_contact;

		$self->contact($Contact);
		$self->customer($Customer);

		$c->stash->{customer} = $Customer;
		$c->stash->{contact} = $Contact;
		}

	## Update token expire time
	$c->model("MyDBI")->dbh->do("UPDATE token SET dateexpires = timestamp 'now' + '2 hours' WHERE tokenid = '$TokenID'");

	return ($NewTokenID, $CustomerID, $ContactID, $ActiveUser, $BrandingID);
	}

sub get_customer_contact
	{
	my $self = shift;
	my $username = shift;
	my $password = shift;

	my $c = $self->context;

	$username = $self->token->active_username if $self->token;
	$c->log->debug("Authenticated user: " . $username);

	my ($customerUser, $contactUser) = split(/\//,$username);

	$contactUser = $customerUser unless $contactUser;

	$c->log->debug("Customer user: " . $customerUser);
	$c->log->debug("Contact  user: " . $contactUser) if $contactUser;

	my $contact_search = { username => $contactUser };
	$contact_search->{password} = $password unless $self->token;

	my $Customer = $c->model('MyDBI::Customer')->find({ username => $customerUser });
	my $Contact = $c->model('MyDBI::Contact')->find($contact_search);

	return ($Customer, $Contact);
	}

sub get_token :Private
	{
	my $self = shift;
	my $c = $self->context;
	my $TokenID = $c->stash->{TokenID};
	$TokenID = $c->req->cookies->{'TokenID'}->value if !$TokenID and $c->req->cookies->{'TokenID'};
	return $c->model("MyDBI::Token")->find({ tokenid => $TokenID });
	}

sub get_login_token :Private
	{
	my $self = shift;
	my $c = $self->context;
	my $TokenID = $c->stash->{TokenID};
	$TokenID = $c->req->cookies->{'TokenID'}->value if !$TokenID and $c->req->cookies->{'TokenID'};
	return $TokenID;
	}

sub get_token_id :Private
	{
	my $self = shift;
	my $c = $self->context;
	my $myDBI = $c->model('MyDBI')->new;
	my $sth = $myDBI->select("SELECT to_char(timestamp 'now', 'YYYYMMDDHH24MISS')||lpad(CAST(nextval('master_seq') AS text),6,'0') AS rawtoken");

	my $RawToken = $sth->fetchrow(0)->{'rawtoken'} if $sth->numrows;
	#print STDERR "\n********** RawToken: " . $RawToken;

	## Convert our 20 digit token to a 13 digit token
	my $BaseCalc = new Math::BaseCalc(digits => [0..9,'A'..'H','J'..'N','P'..'Z']);
	my $SeqID = $BaseCalc->to_base($RawToken);

	#print STDERR "\n********** SeqID: " . $SeqID;
	$c->log->debug("get_token_id, Token ID: " . $SeqID);

	return $SeqID;
	}

sub get_branding_id
	{
	my $self = shift;
	my $c = $self->context;

	return $c->stash->{branding_id} if $c->stash->{branding_id};

	my $branding_id;

	return unless $ENV{HTTP_HOST};
	#$c->log->debug("**** ENV: " . Dumper %ENV);

	#override brandingid based on url
 	if ( $ENV{HTTP_HOST} =~ /d?visionship\.*\.*/ )
		{
		$branding_id = 'visionship';
		}
	elsif ( $ENV{HTTP_HOST} =~ /d?eraship\.engage*\.*/ )
		{
		$branding_id = 'eraship';
		}
	elsif ( $ENV{HTTP_HOST} =~ /d?accellent\.engage*\.*/ or  $ENV{HTTP_HOST} =~ /d?ais\.engage*\.*/)
		{
		$branding_id = 'accellent';
		}
	elsif ( $ENV{HTTP_HOST} =~ /d?gintelliship\.engage*\.*/ )
		{
		$branding_id = 'greating';
		}
	elsif ( $ENV{HTTP_HOST} =~ /d?mintelliship\.engage*\.*/ || $ENV{HTTP_HOST} =~ /motorolasolutions/ )
		{
		$branding_id = 'motorola';
		}
	elsif ( !-d 'branding/brandingid/' . $branding_id )
		{
		$branding_id = 'engage';
		}

	$c->stash->{branding_id} = $branding_id;

	return $branding_id;
	}

sub get_select_list
	{
	my $self = shift;
	my $list_name = shift;

	my $list = [];
	if ($list_name eq 'ACTIVE_INACTIVE')
		{
		$list = [
			{ name => 'Active', value => 'ACTIVE'},
			{ name => 'Inactive', value => 'INACTIVE'},
			];
		}
	elsif ($list_name eq 'YES_NO')
		{
		$list = [
			{ name => 'Yes', value => 'Y'},
			{ name => 'No', value => 'N'},
			];
		}
	elsif ($list_name eq 'YES_NO_BLANK')
		{
		$list = [
			{ name => '', value => ''},
			{ name => 'Yes', value => 'Y'},
			{ name => 'No', value => 'N'},
			];
		}
	elsif ($list_name eq 'CUSTOMER')
		{
		my @records = $self->context->model('MyDBI::Customer')->all;
		foreach my $Country (@records)
			{
			push(@$list, { name => $Country->customername, value => $Country->customerid});
			}
		}
	elsif ($list_name eq 'COUNTRY')
		{
		my @records = $self->context->model('MyDBI::Country')->all;
		#my @records = $self->context->model('MyDBI::Country')->search({ countryiso2 => 'US' });

		foreach my $Country (@records)
			{
			push(@$list, { name => $Country->countryname, value => $Country->countryiso2});
			}
		}
	elsif ($list_name eq 'UNIT_TYPE')
		{
		my @records = $self->context->model('MyDBI::Unittype')->search({}, {order_by => 'unittypename'});
		foreach my $UnitType (@records)
			{
			push(@$list, { name => $UnitType->unittypename, value => $UnitType->unittypeid });
			}
		}
	elsif ($list_name eq 'US_STATES')
		{
		$list = [
			{ value => ''  , name => ''},
			{ value => 'AL', name => 'Alabama' },
			{ value => 'AK', name => 'Alaska' },
			{ value => 'AZ', name => 'Arizona' },
			{ value => 'AR', name => 'Arkansas' },
			{ value => 'CA', name => 'California' },
			{ value => 'CO', name => 'Colorado' },
			{ value => 'CT', name => 'Connecticut' },
			{ value => 'DE', name => 'Delaware' },
			{ value => 'DC', name => 'District of Columbia' },
			{ value => 'FL', name => 'Florida' },
			{ value => 'GA', name => 'Georgia' },
			{ value => 'HI', name => 'Hawaii' },
			{ value => 'ID', name => 'Idaho' },
			{ value => 'IL', name => 'Illinois' },
			{ value => 'IN', name => 'Indiana' },
			{ value => 'IA', name => 'Iowa' },
			{ value => 'KS', name => 'Kansas' },
			{ value => 'KY', name => 'Kentucky' },
			{ value => 'LA', name => 'Louisiana' },
			{ value => 'ME', name => 'Maine' },
			{ value => 'MD', name => 'Maryland' },
			{ value => 'MA', name => 'Massachusetts' },
			{ value => 'MI', name => 'Michigan' },
			{ value => 'MN', name => 'Minnesota' },
			{ value => 'MS', name => 'Mississippi' },
			{ value => 'MO', name => 'Missouri' },
			{ value => 'MT', name => 'Montana' },
			{ value => 'NE', name => 'Nebraska' },
			{ value => 'NV', name => 'Nevada' },
			{ value => 'NH', name => 'New Hampshire' },
			{ value => 'NJ', name => 'New Jersey' },
			{ value => 'NM', name => 'New Mexico' },
			{ value => 'NY', name => 'New York' },
			{ value => 'NC', name => 'North Carolina' },
			{ value => 'ND', name => 'North Dakota' },
			{ value => 'OH', name => 'Ohio' },
			{ value => 'OK', name => 'Oklahoma' },
			{ value => 'OR', name => 'Oregon' },
			{ value => 'PA', name => 'Pennsylvania' },
			{ value => 'PR', name => 'Puerto Rico' },
			{ value => 'RI', name => 'Rhode Island' },
			{ value => 'SC', name => 'South Carolina' },
			{ value => 'SD', name => 'South Dakota' },
			{ value => 'TN', name => 'Tennessee' },
			{ value => 'TX', name => 'Texas' },
			{ value => 'UT', name => 'Utah' },
			{ value => 'VT', name => 'Vermont' },
			{ value => 'VI', name => 'Virgin Islands' },
			{ value => 'VA', name => 'Virginia' },
			{ value => 'WA', name => 'Washington' },
			{ value => 'WV', name => 'West Virginia' },
			{ value => 'WI', name => 'Wisconsin' },
			{ value => 'WY', name => 'Wyoming' }
			];
		}
	elsif ($list_name eq 'HOUR')
		{
		$list = [
			{ name => '', value => '0'},
			{ name => '01', value => '01'},{ name => '02', value => '02'},{ name => '03', value => '03'},
			{ name => '04', value => '04'},{ name => '05', value => '05'},{ name => '06', value => '06'},
			{ name => '07', value => '07'},{ name => '08', value => '08'},{ name => '09', value => '09'},
			{ name => '10', value => '10'},{ name => '11', value => '11'},{ name => '12', value => '12'},
			];
		}
	elsif ($list_name eq 'MONTH')
		{
		$list = [
			{ name => '', value => ''},
			{ name => 'January', value => '1'},{ name => 'February', value => '2'},
			{ name => 'March', value => '3'},{ name => 'April', value => '4'},
			{ name => 'May', value => '5'},{ name => 'June', value => '6'},
			{ name => 'July', value => '7'},{ name => 'August', value => '8'},
			{ name => 'September', value => '9'},{ name => 'October', value => '10'},
			{ name => 'November', value => '11'},{ name => 'December', value => '12'},
			];
		}
	elsif ($list_name eq 'SPECIAL_SERVICE')
		{
		$list = [
			{ value => 'adultsigreq' , name => 'Adult Signature Required' },
			{ value => 'callforappointment' , name => 'Call for Delivery Appointment' },
			{ value => 'cod' , name => 'COD Service' },
			{ value => 'constructionsite' , name => 'Construction Site Delivery' },
			{ value => 'dryice' , name => 'Dry Ice' },
			{ value => 'guaranteeddelivery' , name => 'Guaranteed Delivery' },
			{ value => 'insidepickupdelivery' , name => 'Inside Pickup or Delivery' },
			{ value => 'liftgateservice' , name => 'Lift Gate Service' },
			{ value => 'residential' , name => 'Residential' },
			{ value => 'saturdaydelivery' , name => 'Saturday Delivery' },
			{ value => 'saturdaypickup' , name => 'Saturday Pickup' },
			{ value => 'sigreq' , name => 'Signature Required' },
			{ value => 'sundaydelivery' , name => 'Sunday Delivery' },
			{ value => 'sundaypickup' , name => 'Sunday Pickup' },
			];
		}
	elsif ($list_name eq 'CARRIER')
		{
		$list = [
			{ value => '0000000000006' , name => 'ConWay' },
			{ value => '0000000000001' , name => 'FedEx' },
			{ value => '0000000000005' , name => 'FedEx Freight LTL' },
			{ value => 'WATKINS000001' , name => 'FedEx LTL' },
			{ value => 'AMTREX0000001' , name => 'IN-HOUSE' },
			{ value => 'LANDSTAREXPS1' , name => 'Landstar Express' },
			{ value => '0000000000031' , name => 'Mach 1' },
			{ value => 'OHF0000000001' , name => 'Oak Harbor Freight' },
			{ value => 'OLDDOMINION01' , name => 'Old Dominion' },
			{ value => 'SEKO000000001' , name => 'Seko Worldwide' },
			{ value => '0000000000003' , name => 'UPS' },
			{ value => 'USPS000000001' , name => 'USPS' },
			{ value => 'VISIONSHIP001' , name => 'Vision' },
			{ value => '0000000000011' , name => 'YRC' },
			{ value => 'OTHER_NEW' , name => 'Other - New' },
			];
		}
	elsif ($list_name eq 'DELIVERY_METHOD')
		{
		$list = [
			{ value => 'prepaid' , name => 'Prepaid' },
			{ value => 'collect' , name => 'Collect' },
			{ value => '3rdparty' , name => '3rd Party' },
			];
		}

	return $list;
	}


=encoding utf8

=head1 AUTHOR

root

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
