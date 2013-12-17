package IntelliShip::Controller::Customer;
use Moose;
use IO::File;
use Data::Dumper;
use Math::BaseCalc;
use IntelliShip::DateUtils;
use namespace::autoclean;

BEGIN {

	extends 'IntelliShip::Errors';
	extends 'Catalyst::Controller';

	has 'context' => ( is => 'rw' );
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
	$c->response->redirect($c->uri_for('/customer/login'));
}


=head1

auto : Private

auto actions will be run after any begin, but before your URL-matching action is processed.
Unlike the other built-ins, multiple auto actions can be called; they will be called in turn,
starting with the application class and going through to the most specific class.

=cut

sub auto :Private
	{
	my($self, $c) = @_;

	$c->log->debug('Auto Divert to ' . $c->action);

	## Catalyst context is not accessible in every user defined function
	$self->context($c);
	####################

	return 1 if $c->request->action =~ /login$/;

	#$c->log->debug("c->request->cookies: " . Dumper $c->request->cookies);
	#$c->log->debug("c->response->cookies: " . Dumper $c->response->cookies);

	unless ($self->authorize_user)
		{
		#$c->log->debug('**** Root::auto Not a valid user, forwarding to customer/login ');
		$c->response->redirect($c->uri_for('/customer/login'));
		$c->stash->{template} = undef;
		return 0;
		}

	#$c->log->debug("**** User Authorized Successfully");
	$c->response->cookies->{'TokenID'} = { value => $self->token->tokenid, expires => '+20M' };

	return 1;
	}

=head2 default

Standard 404 error page

=cut

sub default :Path
	{
	my ( $self, $c ) = @_;
	$c->response->redirect($c->uri_for('/customer/login'));
	}

sub flush_expired_tokens :Private
	{
	my $self = shift;
	my $c = $self->context;
	$c->log->debug("#### FLUSH EXPIRED TOKEN FROM DB");
	$c->model("MyDBI")->dbh->do("DELETE FROM token WHERE dateexpires <= timestamp with time zone 'now'");
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
	$contact_search->{customerid} = $self->token->customerid if $self->token;

	my @contactArr = $c->model('MyDBI::Contact')->search($contact_search);
	my $Contact = $contactArr[0] if @contactArr;

	my @customerArr = $c->model('MyDBI::Customer')->search({ customerid => $Contact->customerid, username => $customerUser });
	my $Customer = $customerArr[0] if @customerArr;

	return ($Customer, $Contact);
	}

sub get_token :Private
	{
	my $self = shift;
	my $c = $self->context;
	my $TokenID = $c->stash->{TokenID};
	$TokenID = $c->req->cookies->{'TokenID'}->value if !$TokenID and $c->req->cookies->{'TokenID'};

	if ($TokenID)
		{
		return $c->model("MyDBI::Token")->find({ tokenid => $TokenID });
		}

	return undef;
	}

sub get_login_token :Private
	{
	my $self = shift;
	my $c = $self->context;

	my $TokenID = $c->stash->{TokenID};

	if (!$TokenID and $c->req->cookies->{'TokenID'})
		{
		$TokenID = $c->req->cookies->{'TokenID'}->value;
		$c->stash->{TokenID} = $TokenID;
		}

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
	if ($list_name eq 'COSTATUS')
		{
		my @records = $self->context->model('MyDBI::Costatus')->all;
		foreach my $CoStatus (@records)
			{
			push(@$list, { name => $CoStatus->costatusname, value => $CoStatus->statusid});
			}
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
	elsif ($list_name eq 'WEIGHT_TYPE')
		{
		my @records = $self->context->model('MyDBI::Weighttype')->search({}, {order_by => 'weighttypename'});
		foreach my $WeightType (@records)
			{
			push(@$list, { name => $WeightType->weighttypename, value => $WeightType->weighttypeid });
			}
		}
	elsif ($list_name eq 'CUSTOMER_SHIPMENT_CARRIER')
		{
		my $myDBI = $self->context->model('MyDBI');
		my $sql = "SELECT DISTINCT carrier FROM shipment INNER JOIN co ON shipment.coid = co.coid WHERE co.customerid = '" . $self->customer->customerid . "' AND shipment.carrier <> '' ORDER BY 1";
		my $sth = $myDBI->select($sql);
		for (my $row=0; $row < $sth->numrows; $row++)
			{
			my $data = $sth->fetchrow($row);
			push(@$list, { name => $data->{'carrier'}, value => $data->{'carrier'} });
			}
		}
	elsif ($list_name eq 'PRODUCT_DESCRIPTION')
		{
		my $product_desc_rs = $self->context->model('MyDBI::Co')->search(
			{
			customerid => $self->customer->customerid,
			statusid => { '<' => 5},
			cotypeid => 1,
			},
			{
			select => 'extcd',
			distinct => 1,
			order_by => 'extcd',
			});
		 while( my $obj = $product_desc_rs->next) 
			{
			push(@$list, { name => $obj->extcd(), value => $obj->extcd()});
			}
		}

	elsif ($list_name eq 'DEPARTMENT')
		{
		my $product_desc_rs = $self->context->model('MyDBI::Co')->search(
			{
			customerid => $self->customer->customerid,
			statusid => { '<' => 5},
			cotypeid => 1,
			},
			{
			select => 'department',
			distinct => 1,
			order_by => 'department',
			});
		 while( my $obj = $product_desc_rs->next) 
			{
			push(@$list, { name => $obj->department(), value => $obj->department()});
			}
		}
	elsif ($list_name eq 'CUSTOMER_NUMBER')
		{
		my $product_desc_rs = $self->context->model('MyDBI::Co')->search(
								{
								customerid => $self->customer->customerid,
								statusid => { '<' => 5},
								cotypeid => 1,
								},
								{
								select => 'custnum',
								distinct => 1,
								order_by => 'custnum',
								});
		 while (my $Co = $product_desc_rs->next) 
			{
			push(@$list, { name => $Co->custnum, value => $Co->custnum });
			}
		}
	elsif ($list_name eq 'CARRIER_SERVICE')
		{
		my $myDBI = $self->context->model('MyDBI');
		my $sql = "SELECT
						DISTINCT coalesce(extcarrier,'') || ' - ' || coalesce(extservice,'') as carrierservice 
					FROM 
						co
					WHERE
						co.customerid = '" . $self->customer->customerid . "'
					ORDER BY 
						carrierservice";
		my $sth = $myDBI->select($sql);
		for (my $row=0; $row < $sth->numrows; $row++)
			{
			my $data = $sth->fetchrow($row);
			push(@$list, { name => $data->{'carrierservice'}, value => $data->{'carrierservice'} });
			}
		}
	elsif ($list_name eq 'DESTINATION_ADDRESS')
		{
		my $myDBI = $self->context->model('MyDBI');
		my $sql = "
			SELECT
				DISTINCT
				coalesce(addressname,'') || ':' || coalesce(address1,'') || ':' || coalesce(address2,'') || ':' || coalesce(city,'') || ':' || coalesce(state,'') || ':' || coalesce (zip,'') as address,
				coalesce(addressname,'') || ':' || coalesce(address1,'') || ':' || coalesce(address2,'') || ':' || coalesce(city,'') || ':' || coalesce(state,'') || ':' || coalesce (zip,'')
			FROM
				co INNER JOIN address a ON a.addressid = co.addressid
			WHERE
				co.customerid = '" . $self->customer->customerid . "'
				AND co.statusid < 5
				AND co.cotypeid = 1
			ORDER BY
				address";
		my $sth = $myDBI->select($sql);
		for (my $row=0; $row < $sth->numrows; $row++)
			{
			my $data = $sth->fetchrow($row);
			push(@$list, { name => $data->{'address'}, value => $data->{'address'} });
			}
		}
	elsif ($list_name eq 'ACTIVE_INACTIVE')
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
	elsif ($list_name eq 'YES_NO_NUMERIC')
		{
		$list = [
			{ name => 'Yes', value => '1'},
			{ name => 'No', value => '0'},
			];
		}
	elsif ($list_name eq 'UNIT_OF_MEASURE')
		{
		$list = [
			{ value => 'Each',   name => 'Each'},
			{ value => 'Inch',   name => 'Inch'},
			{ value => 'Feet',   name => 'Feet'},
			{ value => 'Kit',    name => 'Kit'},
			{ value => 'Pounds', name => 'Pounds'},
			{ value => 'Lot',    name => 'Lot'},
			{ value => 'Roll',   name => 'Roll'},
			{ value => 'Sheet',  name => 'Sheet'},
			{ value => 'Sq. Ft', name => 'Sq. Ft'},
			];
		}
	elsif ($list_name eq 'DIMENTION')
		{
		$list = [
			{ value => '1',   name => 'Inch'},
			{ value => '3',   name => 'Centimeter'},
			];
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
	elsif ($list_name eq 'RECORDS_PER_PAGE')
		{
		$list = [
			{ value =>   0 , name => 'All' },
			{ value =>  10 , name => ' 10' },
			{ value =>  50 , name => ' 50' },
			{ value => 100 , name => '100' },
			{ value => 150 , name => '150' },
			{ value => 200 , name => '200' },
			{ value => 250 , name => '250' },
			{ value => 300 , name => '300' },
			{ value => 450 , name => '450' },
			{ value => 500 , name => '500' },
			];
		}

	return $list;
	}

sub download :Private
	{
	my $self = shift;

	my $c = $self->context;

	my $file_path = $c->stash->{FILE};

	$c->log->debug('DOWNLOAD FILE' . $file_path);

	my $file = (split(/\//, $file_path))[-1];

	my @file_parts = split(/\./,$file);
	my $File_extension = pop @file_parts;
	my $File_name = $file_parts[0] . '.' . $File_extension if @file_parts;
	$File_name =~ s/\s+//g;

	# output header
	$c->response->content_type('text/' . $File_extension);
	$c->response->header('Content-Disposition' => 'attachment;filename="' . $File_name . '"');

	# create an IO::File for Catalyst
	my $FH = new IO::File;
	open($FH, $file_path) or return $c->log->debug('ERROR OPENING FILE: ' . $!);

	# output file data
	$c->response->body($FH);
	}

sub set_company_template
	{
	my $self = shift;
	my $Email = shift;

	return unless $Email;

	my $c = $self->context;

	$c->stash->{email_content} = $Email->body;
	$Email->body($c->forward($c->view('Email'), "render", [ $c->stash->{template} ]));
	$c->stash->{email_content} = undef;

	$Email->content_type('text/html');
	$Email->from_name('IntelliShip Admin') unless $Email->from_name;
	$Email->from_address('No_REPLY@engagetechnology.com') unless $Email->from_address;
	}

sub spawn_batches
	{
	my $self = shift;
	my $matching_ids = shift;
	my $batch_size = shift || @$matching_ids;

	#$Template::Directive::WHILE_MAX = scalar @$matching_ids if $matching_ids and @$matching_ids > 1000 and !$batch_size;

	my $batches = [];
	push @$batches, [ splice @$matching_ids, 0, $batch_size ] while @$matching_ids;

	return $batches;
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
