package IntelliShip::Controller::Customer;
use Moose;
use IO::File;
use Data::Dumper;
use Math::BaseCalc;
use IntelliShip::DateUtils;
use IntelliShip::Arrs::API;
use namespace::autoclean;

BEGIN {

	extends 'IntelliShip::Errors';
	extends 'Catalyst::Controller';

	has 'context' => ( is => 'rw' );
	has 'token' => ( is => 'rw' );
	has 'contact' => ( is => 'rw' );
	has 'customer' => ( is => 'rw' );
	has 'arrs_api_context' => ( is => 'rw' );

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

	#$c->log->debug('In ' . __PACKAGE__ . ', index');
	#$c->response->body('Matched IntelliShip::Controller::Customer in Customer.');
	$c->response->redirect($c->uri_for('/customer/login'));
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
	#$c->log->debug("#### FLUSH EXPIRED TOKEN FROM DB");
	$c->model("MyDBI")->dbh->do("DELETE FROM token WHERE dateexpires <= timestamp with time zone 'now'");
	}

sub authorize_user :Private
	{
	my $self = shift;
	my ($NewTokenID, $CustomerID, $ContactID, $ActiveUser,$MyBrandingID) = $self->authenticate_token;
	return $NewTokenID;
	}

sub authenticate_token :Private
	{
	my $self = shift;
	my $c = $self->context;

	my $TokenID = $self->get_login_token;

	#$c->log->debug("**** Authorize Customer User, Token ID: " . $TokenID);

	my ($NewTokenID, $CustomerID, $ContactID, $ActiveUser, $BrandingID);

	my $Token = $c->model("MyDBI::Token")->find({ tokenid => $TokenID });

	if ($Token and $NewTokenID = $Token->tokenid)
		{
		$self->token($Token);

		my ($Customer,$Contact) = $self->get_customer_contact;

		$self->contact($Contact);
		$self->customer($Customer);

		## Update token expire time
		$c->model("MyDBI")->dbh->do("UPDATE token SET dateexpires = timestamp with time zone 'now' + '2 hours' WHERE tokenid = '$NewTokenID'");
		}
	else
		{
		$c->log->debug("NO TOKEN ($TokenID) FOUND IN DB");
		}


	return ($NewTokenID, $CustomerID, $ContactID, $ActiveUser, $BrandingID);
	}

sub get_customer_contact
	{
	my $self = shift;
	my $username = shift;
	my $password = shift;

	my $c = $self->context;

	$username = $self->token->active_username if $self->token;
	#$c->log->debug("Authenticate User: " . $username);

	my ($customerUser, $contactUser) = split(/\//,$username);

	$contactUser = $customerUser unless $contactUser;

	#$c->log->debug("Customer user: " . $customerUser);
	#$c->log->debug("Contact  user: " . $contactUser) if $contactUser;

	my $contact_search = { username => $contactUser };
	$contact_search->{password} = $password unless $self->token;
	$contact_search->{customerid} = $self->token->customerid if $self->token;

	my @contactArr = $c->model('MyDBI::Contact')->search($contact_search);
	return unless @contactArr;
	my $Contact = $contactArr[0] if @contactArr;

	#$c->log->debug($Contact ? "Contact customerid: " . $Contact->customerid : Dumper $contact_search);
	#$c->log->debug($Contact ? "Contact contactid: " . $Contact->contactid : "no contact found");

	my @customerArr = $c->model('MyDBI::Customer')->search({ customerid => $Contact->customerid, username => $customerUser });
	return unless @customerArr;
	my $Customer = $customerArr[0] if @customerArr;

	#$c->log->debug("Customer customerid: " . $Customer->customerid);

	return ($Customer, $Contact);
	}

sub get_token :Private
	{
	my $self = shift;
	my $c = $self->context;

	if (my $TokenID = $self->get_login_token)
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
	#$c->log->debug("get_token_id, Token ID: " . $SeqID);

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

sub get_address_dropdown_list
	{
	my $self = shift;
	my $list = [];

	my $c = $self->context;

	my $myDBI = $self->context->model('MyDBI');
	my $customerid = $self->customer->customerid;
	my $smartaddressbook = $self->customer->smartaddressbook; # 0 = keep only 1,2,3 etc is interval

	my $where = '';

	if ( defined($smartaddressbook) and $smartaddressbook > 0 )
		{
		$where = " AND ( keep = 1 OR date(datecreated) > date(timestamp 'now' + '- $smartaddressbook days'))";
		}
	else
		{
		$where = " AND ( keep = 1) ";
		}

	# TODO ::: join to addresses table on either addressid or dropaddressid to split into origin/destination

	my $orderby = "";
	if ( $customerid =~ /VOUGHT/ )
		{
		$orderby = "  ORDER BY extcustnum, addressname, address1, address2, city";
		}
	else
		{
		$orderby = "  ORDER BY addressname, address1, address2, city";
		}

	my $sql = "SELECT
					DISTINCT ON (addressname,address1,
						address2,city,state,zip,country) address.addressid as addressid,
					addressname as addressname
				FROM co
					INNER JOIN address on co.addressid = address.addressid AND co.customerid = '$customerid'
				WHERE
				co.cotypeid in (1,2,10)
					$where
					$orderby";

	$c->log->debug('list is' . $sql);

	my $sth = $myDBI->select($sql);
	for (my $row=0; $row < $sth->numrows; $row++)
		{
		my $data = $sth->fetchrow($row);
		push(@$list, { name => $data->{'addressname'}, value => $data->{'addressid'} });
		}

	$c->log->debug('list is' . Dumper($list));
	return $list;
	}

sub API
	{
	my $self = shift;

	unless ($self->arrs_api_context)
		{
		my $APIRequest = IntelliShip::Arrs::API->new;
		$APIRequest->context($self->context);
		$self->arrs_api_context($APIRequest);
		}

	return $self->arrs_api_context;
	}

sub get_select_list
	{
	my $self = shift;
	my $list_name = shift;

	my $c = $self->context;

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
		my @customers = $c->model('MyDBI::Customer')->search( {},
			{
			select => [ 'customername', 'addressid' ],
			}
			);
		foreach my $Customer (@customers)
			{
			push(@$list, { name => $Customer->customername, value => $Customer->addressid});
			}
		}
	elsif ($list_name eq 'ADDRESS_BOOK_CUSTOMERS')
		{
		my $CustomerID = $self->customer->customerid;
		my $smart_address_book = $self->customer->smartaddressbook || 0; # 0 = keep only 1,2,3 etc is interval

		my $smart_address_book_sql = '( keep = 1 )';
		if ($smart_address_book > 0)
			{
			$smart_address_book_sql = "( keep = 1 OR date(datecreated) > date(timestamp 'now' + '-$smart_address_book days') )";
			}

		my $extcustnum_field = '';
		$extcustnum_field = "extcustnum," if $CustomerID =~ /VOUGHT/;

		my $OrderBy = ($CustomerID =~ /VOUGHT/ ? "extcustnum, " : "") . "addressname, address1, address2, city";

		my $SQL = "
		SELECT
			DISTINCT ON (addressname)
			addressname,
			address.addressid
		FROM
			co
			INNER JOIN
			address
			ON co.addressid = address.addressid AND co.customerid = '$CustomerID'
		WHERE
			co.cotypeid in (1,2,10) AND
			address.addressname <> '' AND
			$smart_address_book_sql
		ORDER BY
			$OrderBy
		";
		#$c->log->debug("SEARCH_ADDRESS_DETAILS: " . $SQL);
		my $myDBI = $c->model('MyDBI');
		my $sth = $myDBI->select($SQL);

		for (my $row=0; $row < $sth->numrows; $row++)
			{
			my $data = $sth->fetchrow($row);
			push(@$list, { name => $data->{addressname}, value => $data->{addressid} });
			}
		}
	elsif ($list_name eq 'COUNTRY')
		{
		my @records = $c->model('MyDBI::Country')->all;
		#my @records = $c->model('MyDBI::Country')->search({ countryiso2 => 'US' });

		push(@$list, { name => '', value => ''});
		foreach my $Country (@records)
			{
			next unless $Country->countryiso2;
			push(@$list, { name => $Country->countryname, value => $Country->countryiso2});
			}
		}
	elsif ($list_name eq 'UNIT_TYPE')
		{
		my @records = $c->model('MyDBI::Unittype')->search({}, {order_by => 'unittypename'});
		foreach my $UnitType (@records)
			{
			push(@$list, { name => $UnitType->unittypename, value => $UnitType->unittypeid });
			}
		}
	elsif ($list_name eq 'WEIGHT_TYPE')
		{
		my @records = $c->model('MyDBI::Weighttype')->search({}, {order_by => 'weighttypename'});
		foreach my $WeightType (@records)
			{
			push(@$list, { name => $WeightType->weighttypename, value => $WeightType->weighttypeid });
			}
		}
	elsif ($list_name eq 'CUSTOMER_SHIPMENT_CARRIER')
		{
		my $myDBI = $c->model('MyDBI');
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
		my $product_desc_rs = $c->model('MyDBI::Co')->search(
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
		 while ( my $obj = $product_desc_rs->next)
			{
			push(@$list, { name => $obj->extcd(), value => $obj->extcd()});
			}
		}

	elsif ($list_name eq 'DEPARTMENT')
		{
		my $product_desc_rs = $c->model('MyDBI::Co')->search(
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
		 while ( my $obj = $product_desc_rs->next)
			{
			push(@$list, { name => $obj->department(), value => $obj->department()});
			}
		}
	elsif ($list_name eq 'CUSTOMER_NUMBER')
		{
		my $product_desc_rs = $c->model('MyDBI::Co')->search(
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
		my $myDBI = $c->model('MyDBI');
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
		my $myDBI = $c->model('MyDBI');
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
	elsif ($list_name eq 'CURRENCY')
		{
		my $myDBI = $c->model('MyDBI');
		my $sql = "SELECT DISTINCT currency FROM country";my $sth = $myDBI->select($sql);
		for (my $row=0; $row < $sth->numrows; $row++)
			{
			my $data = $sth->fetchrow($row);
			next unless $data->{'currency'};
			push(@$list, { name => $data->{'currency'}, value => $data->{'currency'} });
			}
		}
	elsif ($list_name eq 'SPECIAL_SERVICE')
		{
		my $AssRef = $self->API->get_sop_asslisting($self->customer->get_sop_id);

		my @ass_names = split(/\t/,$AssRef->{'assessorial_names'});
		my @ass_displays = split(/\t/,$AssRef->{'assessorial_display'});

		for (my $row = 0; $row < scalar @ass_names; $row++)
			{
			push(@$list, { name => $ass_displays[$row], value => $ass_names[$row] });
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
	elsif ($list_name eq 'BOL_DETAIL')
		{
		$list = [
			{ name => 'SKU Detail Only', value => '1'},
			{ name => 'SKU Detail w/Summary', value => '2'},
			{ name => 'Summary Only', value => '3'}
			];
		}
	elsif ($list_name eq 'BOL_TYPE')
		{
		$list = [
			{ name => 'Engage', value => 'bol'},
			{ name => 'VisionShip', value => 'bolvisionship'},
			];
		}
	elsif ($list_name eq 'CAPABILITY_LIST')
		{
		$list = [
			{ name => 'None', value => '0' },
			{ name => 'Available', value => '1' },
			{ name => 'Mandatory', value => '2' },
			{ name => 'Default', value => '3' }
			];
		}
	elsif ($list_name eq 'PO_AUTH_TYPE')
		{
		$list = [
			{ name => 'Select One' , value => '0' },
			{ name => 'Per Product', value => '1' },
			{ name => 'Whole PO', value => '2' },
			];
		}
	elsif ($list_name eq 'COMPANY_TYPE')
		{
		$list = [
			{ name => 'Direct' , value => '1' },
			{ name => 'Direct w/Indirect', value => '2' },
			{ name => 'Indirect', value => '3' },
			];
		}
	elsif ($list_name eq 'DEFAULT_PACKING_LIST')
		{
		$list = [
			{ name => 'Not Shown' , value => '0' },
			{ name => 'Show, unchecked', value => '1' },
			{ name => 'Show, checked', value => '2' },
			{ name => 'Show, checked FORCED', value => '3' },
			];
		}
	elsif ($list_name eq 'LIVE_PRODUCT_LIST')
		{
		$list = [
			{ name => 'None' , value => '0' },
			{ name => 'All', value => 'All' },
			{ name => 'Domestic Only', value => 'Domestic' },
			{ name => 'International Only', value => 'Intl' },
			];
		}
	elsif ($list_name eq 'PACKING_LIST')
		{
		$list = [
			{ name => 'Generic', value => 'packinglist' },
			];
		}
	elsif ($list_name eq 'MARKUP_TYPE')
		{
		$list = [
			{ name => 'None' , value => '0' },
			{ name => 'Dollar', value => 'amt' },
			{ name => 'Percentage', value => 'percent' },
			];
		}
	elsif ($list_name eq 'INDICATOR_TYPE')
		{
		$list = [
			{ name => 'Graphic' , value => '0' },
			{ name => 'Text', value => '1' },
			{ name => 'Graphic Text', value => '2' },
			];
		}
	elsif ($list_name eq 'QUICKSHIP_DROPLIST')
		{
		$list = [
			{ name => 'None' , value => '0' },
			{ name => 'Yes', value => '1' },
			{ name => 'Default', value => '2' },
			];
		}
	elsif ($list_name eq 'POINT_INSTRUCTION')
		{
		$list = [
			{ name => 'Select One' , value => '' },
			{ name => 'Generic', value => 'poinstructions' },
			];
		}
	elsif ($list_name eq 'LOGIN_LEVEL')
		{
		my @records = $c->model('MyDBI::Loginlevel')->all;
		foreach my $Loginlevel (@records)
			{
			push(@$list, { name => $Loginlevel->loginlevelname, value => $Loginlevel->loginlevelid});
			}
		}
	elsif ($list_name eq 'QUOTE_MARKUP')
		{
		$list = [
			{ name => '0%' , value =>    '0' },
			{ name => '5%' , value => '1.05' },
			{ name => '10%', value =>  '1.1' },
			{ name => '15%', value => '1.15' },
			{ name => '20%', value => '1.2'  },
			{ name => '25%', value => '1.25' },
			{ name => '30%', value => '1.3'  },
			{ name => '35%', value => '1.35' },
			{ name => '40%', value => '1.4'  },
			{ name => '45%', value => '1.45' },
			{ name => '50%', value => '1.5'  },
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

sub set_navigation_rules
	{
	my $self = shift;
	my $page = shift;

	my $c = $self->context;
	my $Contact = $self->contact;
	my $Customer = $self->customer;
	my $login_level = $Customer->login_level;

	my $navRules = {};
	if ($login_level != 25 and $login_level != 35 and $login_level != 40 and !$Contact->is_restricted)
		{
		$navRules->{DISPLAY_SHIPMENT_MAINTENANCE} = 1;
		$navRules->{DISPLAY_UPLOAD_FILE} = $Customer->uploadorders;
		$navRules->{DISPLAY_SHIP_PACKAGE} = !$Contact->get_contact_data_value('disallowshippackages') || 0;
		}

	unless ($Contact->is_restricted)
		{
		$navRules->{DISPLAY_QUICKSHIP} = ($Customer->quickship and !$Contact->get_contact_data_value('myorders'));
		$navRules->{DISPLAY_NEW_ORDER} = (!$Contact->get_contact_data_value('myorders') and !$Contact->get_contact_data_value('disallowneworder'));
		}

	$navRules->{DISPLAY_MYORDERS} = $Contact->get_contact_data_value('myorders');
	$navRules->{DISPLAY_BATCH_SHIPPING} = $Customer->batchprocess unless $login_level == 25;

	$c->stash->{$_} = $navRules->{$_} foreach keys %$navRules;
	#$c->stash->{$_} = 1 foreach keys %$navRules;
	#$c->log->debug("NAVIGATION RULES: " . Dumper $navRules);
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
