package IntelliShip::Controller::Customer;
use Moose;
use IO::File;
use Data::Dumper;
use IntelliShip::MyConfig;
use IntelliShip::DateUtils;
use IntelliShip::Arrs::API;
use namespace::autoclean;

BEGIN {

	extends 'Catalyst::Controller';

	has 'errors'           => ( is => 'rw', isa => 'ArrayRef' );
	has 'context'          => ( is => 'rw' );
	has 'token'            => ( is => 'rw' );
	has 'contact'          => ( is => 'rw' );
	has 'customer'         => ( is => 'rw' );
	has 'arrs_api_context' => ( is => 'rw' );
	has 'DB_ref'           => ( is => 'rw' );

	}

sub BUILD
	{
	my $self = shift;
	$self->errors([]);
	}

sub has_errors
	{
	my $self = shift;
	return scalar @{$self->errors};
	}

sub add_error
	{
	my $self = shift;
	my $error_msg = shift;
	return undef unless $error_msg;
	my $err_array = $self->errors;
	push (@$err_array, $error_msg);
	}

sub myDBI
	{
	my $self = shift;
	$self->DB_ref($self->context->model('MyDBI')) unless $self->DB_ref;
	return $self->DB_ref if $self->DB_ref;
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

sub help :Local
	{
	my ( $self, $c ) = @_;
	$c->stash(template => "templates/customer/help.tt");
	return 1;
	}

sub printdemo :Local
	{
	my ( $self, $c ) = @_;
	$c->stash(template => "templates/customer/applet-print-demo.html");
	return 1;
	}

sub uspsrateapi :Local
	{
	my ( $self, $c ) = @_;
	$c->stash(template => "templates/customer/usps-rate-api.html");
	return 1;
	}

sub clear_stash :Private
	{
	my $self = shift;
	my $stash = $self->context->stash;
	delete $stash->{$_} foreach keys %$stash;
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

	$BrandingID = $self->get_branding_id;

	return ($NewTokenID, $CustomerID, $ContactID, $ActiveUser, $BrandingID);
	}

sub get_customer_contact :Private
	{
	my $self = shift;
	my $username = shift;
	my $password = shift;

	my $c = $self->context;

	$username = $self->token->active_username if $self->token;
	#$c->log->debug("Authenticate User: " . $username);

	my $Customer  = $self->token->customer if $self->token;

	my $contact_search = { username => $username };
	$contact_search->{password} = $password unless $self->token;
	$contact_search->{customerid} = $Customer->customerid if $Customer;

	my @contactArr = $c->model('MyDBI::Contact')->search($contact_search);

	return unless @contactArr;

	foreach my $Contact (@contactArr)
		{
		$Customer = $Contact->customer unless $Customer;

		next unless $Customer;

		my $Contact = $contactArr[0];

		#$c->log->debug("Customer ID : " . $Customer->customerid);
		#$c->log->debug("Contact ID  : " . $Contact->contactid);

		if ($Customer->customerid eq $Contact->customerid)
			{
			return ($Customer, $Contact);
			}
		}

	$c->log->debug("No Matching Information Found");
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
	return $myDBI->get_token_id;
=head
	my $sth = $myDBI->select("SELECT to_char(timestamp 'now', 'YYYYMMDDHH24MISS')||lpad(CAST(nextval('master_seq') AS text),6,'0') AS rawtoken");

	my $RawToken = $sth->fetchrow(0)->{'rawtoken'} if $sth->numrows;
	#print STDERR "\n********** RawToken: " . $RawToken;

	## Convert our 20 digit token to a 13 digit token
	my $BaseCalc = new Math::BaseCalc(digits => [0..9,'A'..'H','J'..'N','P'..'Z']);
	my $SeqID = $BaseCalc->to_base($RawToken);

	#print STDERR "\n********** SeqID: " . $SeqID;
	#$c->log->debug("get_token_id, Token ID: " . $SeqID);

	return $SeqID;
=cut
	}

sub get_branding_id
	{
	my $self = shift;
	my $c = $self->context;

	return $c->stash->{branding_id} if $c->stash->{branding_id};

	#$c->log->debug("**** HTTP_HOST: " . $ENV{HTTP_HOST});

	my $branding_id = IntelliShip::Utils->get_branding_id;
	$c->stash->{branding_id} = $branding_id;

	#$c->log->debug("**** BRANDING: " . $branding_id);

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

sub get_select_list
	{
	my $self = shift;
	my $list_name = shift;
	my $optional_hash = shift;

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
		my @customers = $c->model('MyDBI::Customer')->search( { customername => { '!=' => '' } },
			{
			select => [ 'customerid', 'customername' ],
			order_by => 'customername',
			}
			);
		foreach my $Customer (@customers)
			{
			push(@$list, { name => $Customer->customername, value => $Customer->customerid});
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

		my $OrderBy = ($CustomerID =~ /VOUGHT/ ? "extcustnum, " : "") . "addressname";
=as
		my $SQL = "
		SELECT
			DISTINCT ON (addressname,city,state,address1)
			addressname,city,state,address1,
			co.coid as referenceid
		FROM
			co
			INNER JOIN
			address
			ON co.addressid = address.addressid AND co.customerid = '$CustomerID'
		WHERE
			co.cotypeid in (1,2,10) AND
			address.addressname <> '' AND
			$smart_address_book_sql
		Order BY
			$OrderBy
		";
=cut
		my $SQL = "
		SELECT
			MAX( co.coid ) coid
		FROM
			co INNER JOIN address ON co.addressid = address.addressid AND co.customerid = '$CustomerID'
		WHERE
			( keep = 1 OR date(datecreated) > date(timestamp 'now' + '-365 days') )
			AND co.cotypeid in (1,2,10)
			AND address.addressname <> ''
			AND address.address1 <> ''
			AND address.state <> ''
			AND address.city <> ''
			AND address.zip <> ''
		GROUP BY
			country, state, city, zip, address1";

		#$c->log->debug("SEARCH_ADDRESS_DETAILS: " . $SQL);

		my $sth = $self->myDBI->select($SQL);

		for (my $row=0; $row < $sth->numrows; $row++)
			{
			my $data = $sth->fetchrow($row);
			my $sth1 = $self->myDBI->select("SELECT addressid, contactname FROM co WHERE coid = '$data->{'coid'}'");
			my $address_data = $sth1->fetchrow(0);
			my $Address = $c->model('MyDBI::Address')->find({ addressid => $address_data->{'addressid'} });
			push(@$list, {
					company_name => $Address->addressname,
					reference_id => $data->{'coid'},
					address1     => $Address->address1,
					city         => $Address->city,
					state        => $Address->state,
					zip          => $Address->zip,
					contactname  => $address_data->{'contactname'},
				});
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
	elsif ($list_name eq 'STATE')
		{
		my $country = $optional_hash->{'country'} || '';
		my $myDBI = $self->context->model('MyDBI');
		my $sth = $myDBI->select("SELECT statename, stateiso2 FROM statelist WHERE counrtyiso2 = '$country' ORDER BY statename");

		push(@$list, { name => '', value => ''});
		for (my $row=0; $row < $sth->numrows; $row++)
			{
			my $data = $sth->fetchrow($row);
			next unless $data->{stateiso2};
			push(@$list, { name => $data->{statename}, value => $data->{stateiso2}});
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
		my @records = $c->model('MyDBI::Weighttype')->search({}, {order_by => 'weighttypeid'});
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
		push(@$list, { name => '', value => ''});

		my $product_desc_rs = $c->model('MyDBI::Co')->search(
			{
			customerid => $self->customer->customerid,
			statusid => { '<'  => 5 },
			extcd    => { '!=' => '' },
			cotypeid => 1,
			},
			{
			distinct => 1,
			select => 'extcd',
			order_by => 'extcd',
			});

		 while ( my $obj = $product_desc_rs->next)
			{
			push(@$list, { name => $obj->extcd, value => $obj->extcd});
			}
		}
	elsif ($list_name eq 'DEPARTMENT')
		{
		push(@$list, { name => '', value => ''});

		my $product_desc_rs = $c->model('MyDBI::Co')->search(
			{
			customerid => $self->customer->customerid,
			statusid   => { '<'  => 5 },
			department => { '!=' => '' },
			cotypeid   => 1,
			},
			{
			distinct => 1,
			select => 'department',
			order_by => 'department',
			});

		 while ( my $obj = $product_desc_rs->next)
			{
			push(@$list, { name => $obj->department, value => $obj->department});
			}
		}
	elsif ($list_name eq 'CUSTOMER_NUMBER')
		{
		my $product_desc_rs = $c->model('MyDBI::Co')->search(
								{
								customerid => $self->customer->customerid,
								custnum    => { '!=' => '' },
								statusid   => { '<' => 5 },
								cotypeid   => 1,
								},
								{
								distinct => 1,
								select   => 'custnum',
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
				coalesce(addressname,'') || ' : ' || coalesce(address1,'') || ' : ' || coalesce(address2,'') || ' : ' || coalesce(city,'') || ' : ' || coalesce(state,'') || ' : ' || coalesce (zip,'') as address,
				coalesce(addressname,'') || ' : ' || coalesce(address1,'') || ' : ' || coalesce(address2,'') || ' : ' || coalesce(city,'') || ' : ' || coalesce(state,'') || ' : ' || coalesce (zip,'')
			FROM
				co INNER JOIN address a ON a.addressid = co.addressid
				AND co.customerid = '" . $self->customer->customerid . "'
				AND co.statusid < 5
				AND co.cotypeid = 1
				AND address1 <> ''
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
			next if $ass_names[$row] =~ /dryice/i;
			push(@$list, { name => $ass_displays[$row], value => $ass_names[$row] });
			}
		}
	elsif ($list_name eq 'LOGIN_LEVEL')
		{
		my @records = $c->model('MyDBI::Loginlevel')->all;
		foreach my $Loginlevel (@records)
			{
			push(@$list, { name => $Loginlevel->loginlevelname, value => $Loginlevel->loginlevelid});
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
			{ value => 'AR',     name => 'Carat' },
			{ value => 'CFT',    name => 'Cubic Feet' },
			{ value => 'CG',     name => 'Centigrams' },
			{ value => 'CG',     name => 'Centigrams' },
			{ value => 'CM',     name => 'Centimeters' },
			{ value => 'CM3',    name => 'Cubic Centimeters' },
			{ value => 'DOZ',    name => 'Dozen' },
			{ value => 'DPR',    name => 'Dozen Pair' },
			{ value => 'EA',     name => 'Each' },
			{ value => 'G',      name => 'Grams' },
			{ value => 'GR',     name => 'Gross' },
			{ value => 'GAL',    name => 'Gallon' },
			{ value => 'KG',     name => 'Kilograms' },
			{ value => 'KGM',    name => 'Kilogram' },
			{ value => 'L',      name => 'Liter' },
			{ value => 'LB',     name => 'Pound' },
			{ value => 'LFT',    name => 'Linear Foot' },
			{ value => 'LNM',    name => 'Linear Meters' },
			{ value => 'LTR',    name => 'Liters' },
			{ value => 'LYD',    name => 'Linear Yard' },
			{ value => 'M',      name => 'Meters' },
			{ value => 'MG',     name => 'Milligram' },
			{ value => 'ML',     name => 'Millileter' },
			{ value => 'M2',     name => 'Square Meters' },
			{ value => 'M3',     name => 'Cubic Meters' },
			{ value => 'NO',     name => 'Number' },
			{ value => 'OZ',     name => 'Ounces' },
			{ value => 'PCS',    name => 'Pieces' },
			{ value => 'PR',     name => 'Pair'},
			{ value => 'PRS',    name => 'Pairs' },
			{ value => 'SFT',    name => 'Square Feet' },
			{ value => 'SQI',    name => 'Square Inches' },
			{ value => 'SYD',    name => 'Square Yard' },
			{ value => 'YD',     name => 'Yard' },
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
			{ value => 'OTHER_NEW'     , name => 'Other - New' },
			];
		}
	elsif ($list_name eq 'DELIVERY_METHOD')
		{
		$list = [
			{ value => '0' , name => 'Bill To Shipper (Prepaid)' }
			];

		if ($self->contact->get_contact_data_value('thirdpartybill'))
			{
			push @$list, { value => '1' , name => 'Bill To Recipient (Collect)' };
			push @$list, { value => '2' , name => 'Bill To 3rd Party (3rd Party)' };
			}
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
	elsif ($list_name eq 'PRINT_RETURN_SHIPMENT')
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
			{ name => 'Generic', value => 'generic' },
			{ name => 'Sprint',  value => 'sprint' },
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
	elsif ($list_name eq 'FREIGHT_CHARGE_EDITABILITY_LIST')
		{
		$list = [
			{ name => 'None' , value => '0' },
			{ name => 'Always', value => '1' },
			{ name => 'Only w/o Existing Rates', value => '2' },
			];
		}
	elsif ($list_name eq 'LABEL_STUB_LIST')
		{
		$list = [
			{ name => 'None' , value => '0' },
			{ name => 'Generic', value => 'stub_generic.stream' },
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
	elsif ($list_name eq 'CLASS')
		{
		push @$list, { name => 'NA', value => ''};
		my @classes = qw(50 55 60 65 70 77.5 85 92.5 100 110 125 150 175 200 250 300 400 500);
		push @$list, { name => $_, value => $_} foreach @classes;
		}
	elsif ($list_name eq 'LABEL_TYPE')
		{
		$list = [
			{ name => 'EPL', value => 'epl' },
			{ name => 'ZPL', value => 'zpl' },
			{ name => 'JPG', value => 'jpg' },
			];
		}
	elsif ($list_name eq 'TRACK_URL')
		{
		$list = [
			{ name => 'DHL'		, value => IntelliShip::Utils->get_tracking_URL('DHL', 'XXXX') },
			{ name => 'UPS'		, value => IntelliShip::Utils->get_tracking_URL('UPS', 'XXXX') },
			{ name => 'Fedex'	, value => IntelliShip::Utils->get_tracking_URL('Fedex', 'XXXX') },
			{ name => 'USPS'	, value => IntelliShip::Utils->get_tracking_URL('USPS', 'XXXX') },
			];
		}
	elsif ($list_name eq 'TERMS_OF_SALE_LIST')
		{
		$list = [
			{ name => 'FOB/FCA' , value => '1' },
			{ name => 'CIF/CIP',  value => '2' },
			{ name => 'C&F/CPT',  value => '3' },
			{ name => 'EXW',      value => '4' },
			{ name => 'DDU',      value => '5' },
			{ name => 'DDP',      value => '6' },
			];
		}
	elsif ($list_name eq 'DUTY_PAY_TYPE_LIST')
		{
		$list = [
			{ name => 'Bill' ,            value => '1' },
			{ name => 'Bill Recipient',   value => '2' },
			{ name => 'Bill Third Party', value => '3' },
			];
		}
	elsif ($list_name eq 'FONT_SIZE')
		{
		$list = [
			{ name =>  '',  value =>  '0' },
			{ name => '10', value => '10' },
			{ name => '11', value => '11' },
			{ name => '12', value => '12' },
			{ name => '13', value => '13' },
			{ name => '14', value => '14' },
			{ name => '15', value => '15' },
			{ name => '16', value => '16' },
			{ name => '18', value => '18' },
			{ name => '20', value => '20' },
			];
		}
	elsif ($list_name eq 'JPG_LABEL_ROTATION')
		{
		$list = [
			{ name => 'None - no rotation' , value => '0' },
			{ name =>  '90 Degree',  value => '90' },
			{ name => '180 Degree',  value => '180' },
			{ name => '270 Degree',  value => '270' },
			];
		}
	elsif ($list_name eq 'PACKAGE_PRODUCT_LEVEL')
		{
		$list = [
			{ name => '' ,         value => '0' },
			{ name => 'Normal',    value => '1' },
			{ name => 'Mini',      value => '2' },
			{ name => 'Micro',     value => '3' },
			{ name => 'Enchanced', value => '4' },
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

sub set_header_section
	{
	my $self = shift;
	my $page = shift;

	my $c = $self->context;
	my $Contact = $self->contact;
	my $Customer = $self->customer;
	my $company_logo = $Customer->username . '-light-logo.png';
	my $fullpath = IntelliShip::MyConfig->branding_file_directory . '/' . $self->get_branding_id . '/images/header/' . $company_logo;
	$company_logo = 'engage-light-logo.png' unless -e $fullpath;
	$c->stash->{logo} = $company_logo;

	my $user_profile = $Customer->username . '-' . $Contact->username . '.png';
	$fullpath = IntelliShip::MyConfig->branding_file_directory . '/engage/images/profile/' . $user_profile;
	$c->stash->{user_profile} = $user_profile if -e $fullpath;
	}

sub set_navigation_rules
	{
	my $self = shift;
	my $page = shift;

	my $c = $self->context;
	my $Contact = $self->contact;
	my $Customer = $self->customer;
	my $login_level = $Contact->login_level;

	return if $c->stash->{RULES_CACHED};

	my $navRules = {};
	if ($login_level != 25 and $login_level != 35 and $login_level != 40 and !$Contact->is_restricted)
		{
		$navRules->{DISPLAY_SHIPMENT_MAINTENANCE} = 1;
		$navRules->{DISPLAY_UPLOAD_FILE} = $Customer->get_contact_data_value('uploadorders') || 0;
		$navRules->{DISPLAY_SHIP_PACKAGE} = !$Contact->get_contact_data_value('disallowshippackages') || 0;
		}

	$navRules->{DISPLAY_SHIP_A_PACKAGE} = $Contact->get_contact_data_value('shipapackage') || 0;
	$navRules->{DISPLAY_DASHBOARD} = $Contact->get_contact_data_value('dashboard') || 0;

	unless ($Contact->is_restricted)
		{
		$navRules->{DISPLAY_QUICKSHIP} = $Customer->quickship;
		$navRules->{DISPLAY_NEW_ORDER} = !$Contact->get_contact_data_value('disallowneworder');
		}

	$navRules->{DISPLAY_MYORDERS} = $navRules->{DISPLAY_MYSHIPMENT} = $Contact->get_contact_data_value('myorders');
	$navRules->{DISPLAY_BATCH_SHIPPING} = $Customer->batchprocess unless $login_level == 25;

	$navRules->{ORDER_SUPPLIES} = $Contact->get_contact_data_value('ordersupplies');

	$c->stash->{$_} = $navRules->{$_} foreach keys %$navRules;

	my $landing_page;
	$landing_page = '/customer/order/multipage' if !$landing_page and $c->stash->{DISPLAY_SHIP_A_PACKAGE};
	$landing_page = '/customer/order/quickship' if !$landing_page and $c->stash->{DISPLAY_QUICKSHIP};
	$landing_page = '/customer/myorders' if !$landing_page and $c->stash->{DISPLAY_MYORDERS};
	$landing_page = '/customer/report' unless $landing_page;

	$c->stash->{landing_page} = $landing_page;

	$c->stash->{RULES_CACHED} = 1;
	}

sub process_pagination
	{
	my $self = shift;
	my $field = shift;
	my $records = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	$c->log->debug("PROCESS PAGINATION");

	my $batch_size = (defined $params->{records_per_page} ? int $params->{records_per_page} : 100);
	$c->stash->{records_per_page} = $batch_size;

	my @matching_ids = map { $_->{$field} } @$records;
	my $records_batch = $self->spawn_batches(\@matching_ids,$batch_size);

	$c->log->debug("TOTAL PAGES: " . @$records_batch);
	#$c->log->debug("TOTAL PAGES: " . Dumper $records_batch);

	$c->stash->{no_batches} = @$records_batch == 0;

	return $records_batch;
	}

sub SaveStringToFile
	{
	my $self = shift;
	my $FileName = shift;
	my $FileString = shift;

	return unless $FileName;
	return unless $FileString;

	my $c = $self->context;

	$c->log->debug("SaveStringToFile, file: " . $FileName);

	my $FILE = new IO::File;
	unless (open ($FILE,">$FileName"))
		{
		$c->log->debug("*** Label String Save Error: " . $!);
		return;
		}

	print $FILE $FileString;
	close $FILE;
	}

sub GetBillingAddressInfo
	{
	my $self = shift;
	my ($CSID, $webaccount, $customername, $customerid, $billingaccount, $chargetype, $addressiddestin, $custnum, $baaddressid) = @_;

	my $BillingAddressInfo;

	# if it's third party see if there is an address in the thirdpartyacct table
	if ( $chargetype eq '1' || $chargetype eq '2' )
		{
		$BillingAddressInfo = $self->GetCollectThirdPartyAddress($billingaccount, $customerid, $chargetype, $addressiddestin);

		if ( defined($BillingAddressInfo) && $BillingAddressInfo ne '' && $billingaccount ne 'Collect' && $billingaccount ne '')
			{
			$BillingAddressInfo->{'addressname'} .= " (" . $billingaccount . ")";
			}
		}

	unless ($BillingAddressInfo)
		{
		my @arr = $self->context->model('MyDBI::Altsop')->search({ key => 'extcustnum', value => $custnum, customerid => $customerid });
		my $AltSOP = $arr[0] if @arr;
		if ($AltSOP)
			{
			my $AltSOPID = $AltSOP->altsopid;
			my $SQL = "
				SELECT
					addressname, address1, address2, city, state, zip, country
				FROM
					altsop asp INNER JOIN address a ON asp.billingaddressid = a.addressid
				WHERE
					asp.altsopid = '$AltSOPID' AND
				";

			my $STH = $self->myDBI->select($SQL);
			if ($STH->numrows)
				{
				$BillingAddressInfo = $STH->fetchrow(0);
				if ($billingaccount)
					{
					$BillingAddressInfo->{'addressname'} .= " (" . $billingaccount . ")";
					}
				if ( $AltSOP->sibling )
					{
					$BillingAddressInfo = $self->BillToEngage($webaccount, $BillingAddressInfo->{'addressname'});
					}
				}
			else
				{
				if ($billingaccount)
					{
					$BillingAddressInfo->{'addressname'} = $billingaccount;
					}
				else
					{
					$BillingAddressInfo = $self->BillToEngage($webaccount, $customername);
					}
				}
			}
		else
			{
			if ($baaddressid)
				{
				my $Address = $self->context->model('MyDBI::Address')->find({ addressid => $baaddressid });
				$BillingAddressInfo = $Address->{_column_data};
				}
			else
				{
				$BillingAddressInfo = $self->BillToEngage($webaccount, $customername, $self->customer->addressid);
				}
			}
		}

	return $BillingAddressInfo;
	}

sub GetCollectThirdPartyAddress
	{
	my $self = shift;
	my ($accountnumber,$customerid,$chargetype,$addressiddestin) = @_;

	my $AddressInfo;
	if ( $chargetype eq '1' && ($accountnumber eq '' || $accountnumber eq 'Collect') && $addressiddestin )
		{
		my $Address = $self->context->model('MyDBI::Address')->find({ addressid => $addressiddestin });
		$AddressInfo = $Address->{_column_data} if $Address;
		}
	else
		{
		my $SQLString = "
			SELECT
				tpcompanyname as addressname,
				tpaddress1 as address1,
				tpaddress2 as address2,
				tpcity as city,
				tpstate as state,
				tpzip as zip,
				tpcountry as country
			FROM
				thirdpartyacct
			 WHERE
				customerid = '$customerid' AND
				upper(tpacctnumber) = upper('$accountnumber')
			LIMIT 1
			";

		my $sth = $self->myDBI->select($SQLString);

		$AddressInfo = $sth->fetchrow(0) if $sth->numrows;
		}

	if ( $chargetype eq '2' && $accountnumber eq '' && $AddressInfo )
		{
		# set something so that it doesn't fall into the
		#altsop address section in GetBillingAddressInfo()
		$AddressInfo->{'addressname'} = '' if $AddressInfo;
		}

	return $AddressInfo;
	}

sub BillToEngage
	{
	my $self = shift;
	my ($webaccount, $customername, $addressid) = @_;

	if ( $addressid )
		{
		if (my $Address = $self->context->model('MyDBI::Address')->find({ addressid => $addressid }))
			{
			return $Address->{_column_data};
			}
		}
	else
		{
		return {
			addressname	=> IntelliShip::Utils->get_bill_to_name($webaccount,$customername),
			address1	=> 'PO Box 4157',
			city		=> 'Costa Mesa',
			state		=> 'CA',
			zip			=> '92628',
			country		=> 'US',
			careof		=> 'c/o Engage TMS',
			};
		}
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
