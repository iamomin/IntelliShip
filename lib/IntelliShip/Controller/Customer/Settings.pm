package IntelliShip::Controller::Customer::Settings;
use Moose;
use Data::Dumper;
use IntelliShip::Email;
use IntelliShip::MyConfig;
use namespace::autoclean;

BEGIN { extends 'IntelliShip::Controller::Customer'; }

=head1 NAME

IntelliShip::Controller::Customer::Settings - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    #$c->response->body('Matched IntelliShip::Controller::Customer::Settings in Customer::Settings.');

	#$c->log->debug("DISPLAY SETTING LINKS");

	my $Customer = $self->customer;
	my $Contact = $self->contact;
	my $settings = [];

	## Display settings
	# Customer ID: 8ETKCWZXZC0UY (Motorola Solutions, Inc.)
	push (@$settings, { name => 'Change Password', url => '/customer/settings/changepassword' }) if $Customer->customerid ne '8ETKCWZXZC0UY';
	push (@$settings, { name => 'Contact Information', url => '/customer/settings/contactinformation'}) if $Customer->customerid eq '8ETKCWZXZC0UY';
	push (@$settings, { name => 'Company Management', url => '/customer/settings/customermanagement'}) if $Contact->is_superuser;
	push (@$settings, { name => 'Sku Management', url => '/customer/settings/skumanagement'}) if $Customer->login_level != 25 and $Contact->get_contact_data_value('skumanager');
	push (@$settings, { name => 'Extid Management', url => '/customer/settings/extidmanagement'}) if $Customer->has_extid_data($c->model('MyDBI'));

	if ($Customer->login_level != 25 and ($Customer->login_level == 35 or $Customer->login_level == 40))
		{
		push (@$settings, { name => 'My POs View', url => '#'});
		}
	elsif ($Contact->get_contact_data_value('myorders'))
		{
		push (@$settings, { name => 'My Order Numbers View', url => '#'});
		}

	$c->stash->{settings_loop} = $settings;
	$c->stash(template => "templates/customer/settings.tt");
}

sub changepassword :Local
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	if (length $params->{'oldpassword'} and
		length $params->{'newpassword1'} and
		$params->{'newpassword1'} eq $params->{'newpassword2'})
		{
		$self->update_password;
		}
	else
		{
		$c->stash->{CHANGE_PASSWORD_SETUP} = 1;
		}

	$c->stash(template => "templates/customer/settings.tt");
	}

sub update_password :Private
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	my $Contact = $self->contact;
	my $Customer = $self->customer;

	#$c->log->debug("Contact->password: " . $Contact->password);
	#$c->log->debug("Customer->password: " . $Customer->password);

	if ($params->{'oldpassword'} ne $Contact->password)
		{
		$c->stash->{ERR_MESSAGE} = "Old password isn't valid";
		$c->stash->{CHANGE_PASSWORD_SETUP} = 1;
		}
	else
		{
		$Contact->password($params->{'newpassword1'});
		$Customer->password($params->{'newpassword1'});

		$Contact->update;
		$Customer->update;

		my $customername = $Customer->customername;
		my $customerdomain = $Customer->username;
		my $username = $Contact->username;
		my $fullname = $Contact->full_name;

		# don't add a domain if it looks like they are an old style contact ie TX-VOYAGER
		my $who;
		if ( $customerdomain ne $username )
			{
			$who = $customerdomain . "/" . $username;
			}
		else
			{
			$who = $username;
			}

		my $Email = IntelliShip::Email->new;
		$Email->send_to($Contact->email ? $Contact->email : $Customer->email);
		$Email->allow_send_from_dev(1);

		my $body = "Login Password Changed, " . $customername . " " . $fullname . " (" . IntelliShip::DateUtils->american_date_time . " by " . $who . ")";
		$Email->add_line('');
		$Email->add_line('');

		$Email->set_company_template;
		#$Email->send_now;

		$c->stash->{MESSAGE} = "Your password has been successfully updated!";

		$c->detach("index",$params);
		}
	}

sub skumanagement :Local
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	#$c->log->debug("SKU MANAGEMENT");

	my $productskus_batches = $self->process_pagination('skumanagement');

	my $ORDER_BY = { order_by => 'description' };
	my $WHERE = { customerid => $self->customer->customerid };
	$WHERE->{productskuid} = $productskus_batches->[0] if $productskus_batches;
	#$c->log->debug("WHERE: " . Dumper $WHERE);

	my @productskus = $c->model('MyDBI::Productsku')->search($WHERE, $ORDER_BY);
	#$c->log->debug("TOTAL SKUS: " . @productskus);

	$c->stash->{productskulist} = \@productskus;
	$c->stash->{productsku_count} = scalar @productskus;
	$c->stash->{productskus_batches} = $productskus_batches;
	$c->stash->{recordsperpage_list} = $self->get_select_list('RECORDS_PER_PAGE');

	$c->stash->{PRODUCT_SKU_LIST} = 1;
	$c->stash->{SKU_MANAGEMENT} = 1;

	$c->stash(template => "templates/customer/settings.tt");
	}

sub extidmanagement :Local
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	my $extid_droplist_batches = $self->process_pagination('extidmanagement');

	my $ORDER_BY = { order_by => 'fieldorder desc,fieldtext' };
	my $WHERE = { customerid => $self->customer->customerid };
	$WHERE->{field} = "extid";
	$WHERE->{droplistdataid} = $extid_droplist_batches->[0] if (scalar @$extid_droplist_batches > 0);

	my @droplistdata = $c->model('MyDBI::Droplistdata')->search($WHERE, $ORDER_BY);

	$c->stash->{extiddroplist} = \@droplistdata;
	$c->stash->{extid_droplist_count} = scalar @droplistdata;
	$c->stash->{extid_droplist_batches} = $extid_droplist_batches;
	$c->stash->{recordsperpage_list} = $self->get_select_list('RECORDS_PER_PAGE');

	$c->stash->{EXTID_DROP_LIST} = 1;
	$c->stash->{EXTID_MANAGEMENT} = 1;

	$c->stash(template => "templates/customer/settings.tt");
	}

sub customermanagement :Local
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	$c->log->debug("CUSTOMER MANAGEMENT");
	my $customer_batches = $self->process_pagination('customermanagement');
	my $WHERE = {};
	$WHERE->{customerid} = $customer_batches->[0] if $customer_batches;

	my @customers = $self->context->model('MyDBI::Customer')->search($WHERE, {
	select => [
		'customerid',
		'username',
		'customername',
		'contact',
		'phone',
		'email'
		],
	order_by => { -asc => 'customername' },
	});

	$c->stash->{customerlist} = \@customers;
	$c->stash->{customer_count} = scalar @customers;
	$c->stash->{customer_batches} = $customer_batches;
	$c->stash->{recordsperpage_list} = $self->get_select_list('RECORDS_PER_PAGE');

	$c->stash->{CUSTOMER_LIST} = 1;
	$c->stash->{CUSTOMER_MANAGEMENT} = 1;

	$c->stash(template => "templates/customer/settings.tt");
	}

sub get_customer_contacts :Private
	{
	my $self = shift;
	my $customerid = shift;
	my $c = $self->context;

	$c->log->debug("CUSTOMER CONTACT MANAGEMENT");
	#my $contact_batches = $self->process_pagination('contactmanagement', $Customer);
	my $WHERE = {};
	#$WHERE->{contactid} = $contact_batches->[0] if $contact_batches;
	$c->log->debug("customerid " . $customerid);
	$WHERE->{customerid} = $customerid;

	my @contacts = $self->context->model('MyDBI::Contact')->search($WHERE, {
	select => [
		'contactid',
		'customerid',
		'username',
		'firstname',
		'lastname',
		'phonemobile',
		'email'
		],
	order_by => { -asc => 'username' },
	});

	$c->stash->{contactlist} = \@contacts;
	$c->stash->{contact_count} = scalar @contacts;
	$c->log->debug("contact_count " . $c->stash->{contact_count});
	#$c->stash->{contact_batches} = $contact_batches;
	#$c->stash->{recordsperpage_list} = $self->get_select_list('RECORDS_PER_PAGE');

	$c->stash->{CONTACT_LIST} = 1;
	$c->stash->{CONTACT_MANAGEMENT} = 1;

	$c->stash(template => "templates/customer/settings.tt");
	}

my $CUSTOMER_RULES = {
	 1 => { name => 'Super User', value => 'superuser' , type => 'CHECKBOX', datatypeid => 1 },
	 2 => { name => 'Administrator', value => 'administrator' , type => 'CHECKBOX', datatypeid => 1 },
	 3 => { name => 'Third Party Billing', value=> 'thirdpartybill' , type => 'CHECKBOX', datatypeid => 1 },
	 4 => { name => 'Auto Print', value => 'autoprint' , type => 'CHECKBOX', datatypeid => 1 },
	 5 => { name => 'Has Rates', value => 'hasrates' , type => 'CHECKBOX', datatypeid => 1 },
	 6 => { name => 'Allow Postdating', value => 'allowpostdating' , type => 'CHECKBOX', datatypeid => 1 },
	 7 => { name => 'Auto Process', value => 'autoprocess' , type => 'CHECKBOX', datatypeid => 1 },
	 8 => { name => 'Batch Shipping', value => 'batchprocess' , type => 'CHECKBOX', datatypeid => 1 },
	 9 => { name => 'Quick Ship', value => 'quickship' , type => 'CHECKBOX', datatypeid => 1 },
	10 => { name => 'Default Declared Value', value => 'defaultdeclaredvalue' , type => 'CHECKBOX', datatypeid => 1 },
	11 => { name => 'Default Freight Insurance', value => 'defaultfreightinsurance' , type => 'CHECKBOX', datatypeid => 1 },
	12 => { name => 'Print Thermal BOL', value => 'printthermalbol', type => 'CHECKBOX', datatypeid => 1 },
	13 => { name => 'Print 8.5x11 BOL', value => 'print8_5x11bol' , type => 'CHECKBOX', datatypeid => 1 },
	14 => { name => 'Has Product Data', value => 'hasproductdata' , type => 'CHECKBOX', datatypeid => 1 },
	15 => { name => 'Export Shipment Tab', value => 'exportshipmenttab' , type => 'CHECKBOX', datatypeid => 1 },
	16 => { name => 'Auto CS Select', value => 'autocsselect' , type => 'CHECKBOX', datatypeid => 1 },
	17 => { name => 'Auto Shipment Opimize', value => 'autoshipmentoptimize' , type => 'CHECKBOX', datatypeid => 1 },
	18 => { name => 'Error on Past Ship Date', value => 'errorshipdate' , type => 'CHECKBOX', datatypeid => 1 },
	19 => { name => 'Error on Past Due Date', value => 'errorduedate' , type => 'CHECKBOX', datatypeid => 1 },
	20 => { name => 'Upload Orders', value => 'uploadorders' , type => 'CHECKBOX', datatypeid => 1 },
	21 => { name => 'ZPL2', value => 'zpl2' , type => 'CHECKBOX', datatypeid => 1 },
	22 => { name => 'Security Types', value => 'hassecurity' , type => 'CHECKBOX', datatypeid => 1 },
	23 => { name => 'Show Hazardous', value => 'showhazardous' , type => 'CHECKBOX', datatypeid => 1 },
	24 => { name => 'AM Delivery', value => 'amdelivery' , type => 'CHECKBOX', datatypeid => 1 },
	25 => { name => 'Print UCC128 Label', value => 'checkucc128' , type => 'CHECKBOX', datatypeid => 1 },
	26 => { name => 'Require Order Number', value => 'reqordernumber' , type => 'CHECKBOX', datatypeid => 1 },
	27 => { name => 'Require Customer Number', value => 'reqcustnum' , type => 'CHECKBOX', datatypeid => 1 },
	28 => { name => 'Require PO Number', value => 'reqponum' , type => 'CHECKBOX', datatypeid => 1 },
	29 => { name => 'Require Product Description', value => 'reqproddescr' , type => 'CHECKBOX', datatypeid => 1 },
	30 => { name => 'Require Ship Date', value => 'reqdatetoship' , type => 'CHECKBOX', datatypeid => 1 },
	31 => { name => 'Require Due Date', value => 'reqdateneeded' , type => 'CHECKBOX', datatypeid => 1 },
	32 => { name => 'Require', value => 'reqcustref2' , type => 'CHECKBOX', datatypeid => 1 },
	33 => { name => 'Require', value => 'reqcustref3' , type => 'CHECKBOX', datatypeid => 1 },
	34 => { name => 'Require Department', value => 'reqdepartment' , type => 'CHECKBOX', datatypeid => 1 },
	35 => { name => 'Require', value => 'reqextid' , type => 'CHECKBOX', datatypeid => 1 },
	36 => { name => 'Manual Routing Control', value => 'manroutingctrl' , type => 'CHECKBOX', datatypeid => 1 },
	37 => { name => 'Has AltSOPs', value => 'hasaltsops' , type => 'CHECKBOX', datatypeid => 1 },
	38 => { name => 'Custnum Address Lookup', value => 'custnumaddresslookup' , type => 'CHECKBOX', datatypeid => 1 },
	39 => { name => 'Saturday Shipping', value => 'satshipping' , type => 'CHECKBOX', datatypeid => 1 },
	40 => { name => 'Sunday Shipping', value => 'sunshipping' , type => 'CHECKBOX', datatypeid => 1 },
	41 => { name => 'Auto DIM Classing', value => 'autodimclass' , type => 'CHECKBOX', datatypeid => 1 },
	42 => { name => 'Save Order Upon Shipping', value => 'saveorder' , type => 'CHECKBOX', datatypeid => 1 },
	43 => { name => 'Always Show Assessorials', value => 'alwaysshowassessorials' , type => 'CHECKBOX', datatypeid => 1 },
	44 => { name => 'TAB Pick-N-Pack', value => 'pickpack' , type => 'CHECKBOX', datatypeid => 1 },
	45 => { name => 'Date Specific Consolidation', value => 'dateconsolidation' , type => 'CHECKBOX', datatypeid => 1 },
	46 => { name => 'Alert Cutoff Date Change', value => 'alertcutoffdatechange' , type => 'CHECKBOX', datatypeid => 1 },
	47 => { name => 'Allow Consolidate/Combine', value => 'consolidatecombine' , type => 'CHECKBOX', datatypeid => 1 },
	48 => { name => 'Default Multi Order Nums', value => 'defaultmultiordernum' , type => 'CHECKBOX', datatypeid => 1 },
	49 => { name => 'Export PackProdata (requires shipment export)', value => 'exportpackprodata' , type => 'CHECKBOX', datatypeid => 1 },
	50 => { name => 'Default Commercial Invoice', value => 'defaultcomminv' , type => 'CHECKBOX', datatypeid => 1 },
	51 => { name => 'Intelliship Notification', value => 'aosnotifications' , type => 'CHECKBOX', datatypeid => 1 },
	52 => { name => 'DisAllow New Order', value => 'disallowneworder' , type => 'CHECKBOX', datatypeid => 1 },
	53 => { name => 'Single Order Shipment', value => 'singleordershipment' , type => 'CHECKBOX', datatypeid => 1 },
	54 => { name => 'DisAllow Ship Packages', value => 'disallowshippackages' , type => 'CHECKBOX', datatypeid => 1 },
	55 => { name => 'Independent Quantity/Weight', value => 'quantityxweight' , type => 'CHECKBOX', datatypeid => 1 },
	57 => { name => 'SOP' , value => 'sopid' , type => 'SELECT', datatypeid => 2 },
	58 => { name => 'Client ID' , value => 'clientid' , type => 'INPUT', datatypeid => 2 },
	59 => { name => 'Thermal Label Count' , value => 'defaultthermalcount' , type => 'INPUT', datatypeid => 2 },
	60 => { name => '8.5x11 BOL Label Count' , value => 'bolcount8_5x11' , type => 'INPUT', datatypeid => 2 },
	61 => { name => 'Thermal BOL Label Count' , value => 'bolcountthermal' , type => 'INPUT', datatypeid => 2 },
	62 => { name => 'Label Printer Port' , value => 'labelport' , type => 'INPUT', datatypeid => 2 },
	63 => { name => 'BOL Type' , value => 'boltype' , type => 'SELECT', datatypeid => 1 },
	64 => { name => 'BOL Detail' , value => 'boldetail' , type => 'SELECT', datatypeid => 1 },
	65 => { name => 'Auto Report Times' , value => 'autoreporttime' , type => 'INPUT', datatypeid => 2 },
	66 => { name => 'Auto Report Email' , value => 'autoreportemail' , type => 'INPUT', datatypeid => 2 },
	67 => { name => 'Auto Report Interval' , value => 'autoreportinterval' , type => 'INPUT', datatypeid => 2 },
	68 => { name => 'Proxy IP' , value => 'proxyip' , type => 'INPUT', datatypeid => 2 },
	69 => { name => 'Proxy Port' , value => 'proxyport' , type => 'INPUT', datatypeid => 2 },
	70 => { name => 'Loss Prevention Email' , value => 'losspreventemail' , type => 'INPUT', datatypeid => 2 },
	71 => { name => 'Loss Prevention Email (Manual Order Create)' , value => 'losspreventemailordercreate' , type => 'INPUT', datatypeid => 2 },
	72 => { name => 'Smart Address Book' , value => 'smartaddressbook' , type => 'INPUT', datatypeid => 2 },
	73 => { name => 'API Intelliship Address' , value => 'apiaosaddress' , type => 'INPUT', datatypeid => 2 },
	74 => { name => 'Charge Difference Threshold (flat)' , value => 'chargediffflat' , type => 'INPUT', datatypeid => 2 },
	75 => { name => 'Charge Difference Threshold (%/min)' , value => 'chargediffpct' , type => 'INPUT', datatypeid => 2 },
	76 => { name => '' , value => 'chargediffmin' , type => 'INPUT', datatypeid => 2 },
	77 => { name => 'Return Capability' , value => 'returncapability' , type => 'SELECT', datatypeid => 1 },
	78 => { name => 'Login Level' , value => 'loginlevel' , type => 'SELECT', datatypeid => 1 },
	79 => { name => 'Dropship Capability' , value => 'dropshipcapability' , type => 'SELECT', datatypeid => 1 },
	80 => { name => 'Display Quote Markup' , value => 'quotemarkup' , type => 'SELECT', datatypeid => 1 },
	81 => { name => 'Quote Markup Default' , value => 'quotemarkupdefault' , type => 'SELECT', datatypeid => 1 },
	82 => { name => 'Default Freight Class' , value => 'defaultfreightclass' , type => 'INPUT', datatypeid => 2 },
	83 => { name => 'Cycle Time Threshold' , value => 'cycletimethreshold' , type => 'INPUT', datatypeid => 2 },
	84 => { name => 'Due Date Offset (equal)' , value => 'duedateoffsetequal' , type => 'INPUT', datatypeid => 2 },
	85 => { name => 'Due Date Offset (less than)' , value => 'duedateoffsetlessthan' , type => 'INPUT', datatypeid => 2 },
	86 => { name => 'Default Package Unit Type' , value => 'defaultpackageunittype' , type => 'SELECT', datatypeid => 1 },
	87 => { name => 'Default Product Unit Type' , value => 'defaultproductunittype' , type => 'SELECT', datatypeid => 1 },
	88 => { name => 'PO Instructions' , value => 'poinstructions' , type => 'SELECT', datatypeid => 1 },
	89 => { name => 'PO Auth Type' , value => 'poauthtype' , type => 'SELECT', datatypeid => 1 },
	90 => { name => 'Company Type' , value => 'companytype' , type => 'SELECT', datatypeid => 1 },
	91 => { name => 'Print Packing List' , value => 'defaultpackinglist' , type => 'SELECT', datatypeid => 1 },
	92 => { name => 'Packing List' , value => 'packinglist' , type => 'SELECT', datatypeid => 1 },
	93 => { name => 'Live Product TAB' , value => 'liveproduct' , type => 'SELECT', datatypeid => 2 },
	94 => { name => 'Freight Charge Editablity' , value => 'fceditability' , type => 'SELECT', datatypeid => 1 },
	95 => { name => 'Label Stub' , value => 'labelstub' , type => 'SELECT', datatypeid => 2 },
	};

sub customersetup :Local
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	if ($params->{'do'} eq 'configure')
		{
		my $Customer = $self->get_customer;
		$Customer = $c->model('MyDBI::Customer')->new({}) unless $Customer;

		IntelliShip::Utils->trim_hash_ref_values($params);

		$Customer->halocustomerid($params->{'halocustomerid'}) if ($params->{'halocustomerid'});
		$Customer->customername($params->{'customername'}) if ($params->{'customername'});
		$Customer->contact($params->{'contact'}) if ($params->{'contact'});
		$Customer->phone($params->{'phone'}) if ($params->{'phone'});
		$Customer->email($params->{'email'}) if ($params->{'email'});
		$Customer->fax($params->{'fax'}) if ($params->{'fax'});
		$Customer->ssnein($params->{'ssnein'}) if ($params->{'ssnein'});
		$Customer->password($params->{'password'}) if ($params->{'password'});
		$Customer->labelbanner($params->{'labelbanner'}) if ($params->{'labelbanner'});
		$Customer->labelport($params->{'cust_labelport'}) if ($params->{'cust_labelport'});
		$Customer->defaultthermalcount($params->{'cust_defaultthermalcount'}) if ($params->{'cust_defaultthermalcount'});
		$Customer->bolcount8_5x11($params->{'cust_bolcount8_5x11'}) if ($params->{'cust_bolcount8_5x11'});
		$Customer->bolcountthermal($params->{'cust_bolcountthermal'}) if ($params->{'cust_bolcountthermal'});
		$Customer->autoreporttime($params->{'cust_autoreporttime'}) if ($params->{'cust_autoreporttime'});
		$Customer->autoreportemail($params->{'cust_autoreportemail'}) if ($params->{'cust_autoreportemail'});
		$Customer->autoreportinterval($params->{'cust_autoreportinterval'}) if ($params->{'cust_autoreportinterval'});
		$Customer->proxyip($params->{'cust_proxyip'}) if ($params->{'cust_proxyip'});
		$Customer->proxyport($params->{'cust_proxyport'}) if ($params->{'cust_proxyport'});
		$Customer->losspreventemail($params->{'cust_losspreventemail'}) if ($params->{'cust_losspreventemail'});
		$Customer->losspreventemailordercreate($params->{'cust_losspreventemailordercreate'}) if ($params->{'cust_losspreventemailordercreate'});
		$Customer->smartaddressbook($params->{'cust_smartaddressbook'}) if ($params->{'cust_smartaddressbook'});
		$Customer->apiaosaddress($params->{'cust_apiaosaddress'}) if ($params->{'cust_apiaosaddress'});


		if ($params->{'cust_quickship'} && !$params->{'cust_defaulttoquickship'} )
			{
			$Customer->{'quickship'} = $params->{'cust_quickship'} ? '1' : '0';
			}
		elsif ( $params->{'cust_quickship'} && $params->{'cust_defaulttoquickship'} )
			{
			$Customer->{'quickship'} ='2';
			}
		else
			{
			$Customer->{'quickship'} ='0';
			}

		my $msg;
		if ($Customer->customerid)
			{
			$Customer->update;
			$c->log->debug("Customer UPDATED, ID: ".$Customer->customerid);
			$msg = "Customer update successfully!";
			}
		else
			{
			#$ProductSku->customerid($self->customer->customerid);
			$Customer->customerid($self->get_token_id);
			$Customer->insert;
			$c->log->debug("NEW CUSTOMER INSERTED, ID: ".$Customer->customerid);
			$msg = "New Customer configured successfully!";
			}

		# Save Address Details
		my $addressData = {
				addressname => $params->{'customername'},
				address1    => $params->{'address1'},
				address2    => $params->{'address2'},
				city        => $params->{'city'},
				state       => $params->{'state'},
				zip         => $params->{'zip'},
				country     => $params->{'country'},
				};

		my $Address;
		if ($Customer->addressid)
			{
			$Address = $Customer->address;
			}
		else
			{
			my @address = $c->model('MyDBI::Address')->search($addressData);

			$Address = (@address ? $address[0] : $c->model('MyDBI::Address')->new({}));

			unless ($Address->addressid)
				{
				$Address->addressid($self->get_token_id);
				$Address->insert;
				$c->log->debug("New Address Inserted: " . $Address->addressid);
				}

			$Customer->addressid($Address->addressid);
			}

		$Address->update($addressData);

		# Save Auxilary Address Details
		my $auxAddressData = {
				addressname => $params->{'auxaddressname'},
				address1    => $params->{'auxaddress1'},
				address2    => $params->{'auxaddress2'},
				city        => $params->{'auxcity'},
				state       => $params->{'auxstate'},
				zip         => $params->{'auxzip'},
				country     => $params->{'auxcountry'},
				};

		my $AuxilaryAddress;
		if ($Customer->auxformaddressid)
			{
			$AuxilaryAddress = $Customer->auxilary_address;
			}
		else
			{
			my @auxaddress = $c->model('MyDBI::Address')->search($auxAddressData);

			$AuxilaryAddress = (@auxaddress ? $auxaddress[0] : $c->model('MyDBI::Address')->new({}));

			unless ($AuxilaryAddress->addressid)
				{
				$AuxilaryAddress->addressid($self->get_token_id);
				$AuxilaryAddress->insert;
				$c->log->debug("New Auxilary Address Inserted: " . $AuxilaryAddress->addressid);
				}

			$Customer->auxformaddressid($AuxilaryAddress->addressid);
			}

		$AuxilaryAddress->update($auxAddressData);

		if (my @CustConData = $c->model("MyDBI::CustConData")->search({ ownerid => $Customer->customerid ,ownertypeid => '1' }))
			{
			$c->log->debug("___ Flush old custcondata for company: " . $Customer->customerid);
			foreach my $custdata (@CustConData)
				{
				$custdata->delete;
				}
			}

		foreach my $key (sort keys %$CUSTOMER_RULES)
			{
			my $ruleHash = $CUSTOMER_RULES->{$key};
			#$c->log->debug("___FIELD : cust_$ruleHash->{value} = " . $params->{'cust_'.$ruleHash->{value}});
			if($params->{'cust_'.$ruleHash->{value}})
				{
				#$c->log->debug("___ Inserting New custcondata $ruleHash->{value} for company: " . $Customer->customerid);
				my $customerContactData = {
					ownertypeid	=> 1,
					ownerid		=> $Customer->customerid,
					datatypeid	=> $ruleHash->{datatypeid},
					datatypename=> $ruleHash->{value},
					value       => ($ruleHash->{type} eq 'CHECKBOX') ? 1 : $params->{'cust_'.$ruleHash->{value}},
					};

				my $NewCCData = $c->model("MyDBI::Custcondata")->new($customerContactData);
				$NewCCData->custcondataid($self->get_token_id);
				$NewCCData->insert;
				}
			}

		# FREIGHT MARKUP
		my $shipmentmarkupdata =$c->model('MyArrs::RateData')->search({
			-and => [
			  -or => [
				freightmarkupamt => { '!=', undef },
				freightmarkuppercent  => { '!=', undef },
			  ],
			  ownerid => $Customer->customerid,
			  ownertypeid => 1,
			],
		});

		foreach my $RateData ($shipmentmarkupdata)
			{
			#$c->log->debug("___ Flush old RateData for Ownerid : " . $Customer->customerid);
			$RateData->delete;
			}

		if($params->{'shipmentmarkup'} and $params->{'shipmentmarkuptype'})
			{
			my $column = "freightmarkup" . $params->{'shipmentmarkuptype'};
			my $amt = $params->{'shipmentmarkup'};

			$amt = $params->{'shipmentmarkup'} / 100 if $column eq 'freightmarkuppercent';
			my $RateData = {
				ownertypeid => 1,
				ownerid     => $Customer->customerid,
				customerid  => $Customer->customerid,
				$column  => $amt,
				};

			my $RateDataObj = $c->model("MyArrs::RateData")->new($RateData);
			$RateDataObj->ratedataid($self->get_token_id);
			$RateDataObj->insert;

			$c->log->debug("New RateDataObj Inserted, ID: " . $RateDataObj->ratedataid);
			}

		# ASSDATA MARKUP
		my $assdatamarkupdata =$c->model('MyArrs::AssData')->search({
			-and => [
			  -or => [
				assmarkupamt => { '!=', undef },
				assmarkuppercent  => { '!=', undef },
			  ],
			  ownerid => $Customer->customerid,
			  ownertypeid => 1,
			],
		});

		foreach my $AssData ($assdatamarkupdata)
			{
			#$c->log->debug("___ Flush old AssData for Ownerid : " . $Customer->customerid);
			$AssData->delete;
			}

		if ($params->{'assmarkup'} and $params->{'assmarkuptype'})
			{
			my $ass_column = "assmarkup" . $params->{'assmarkuptype'};
			my $ass_amt = $params->{'assmarkup'};

			$ass_amt = $params->{'assmarkup'} / 100 if $ass_column eq 'assmarkuppercent';
			my $AssData = {
				ownertypeid => 1,
				ownerid     => $Customer->customerid,
				$ass_column  => $ass_amt,
				};

			my $AssDataObj = $c->model("MyArrs::AssData")->new($AssData);
			$AssDataObj->assdataid($self->get_token_id);
			$AssDataObj->insert;

			$c->log->debug("New AssDataObj Inserted, ID: " . $AssDataObj->assdataid);
			}

		$Customer->update;

		$c->stash->{MESSAGE} = $msg;
		$c->detach("customermanagement",$params);
		}
	else
		{
		my $Customer = $self->get_customer;
		if ($Customer)
			{
			#$c->log->debug("CUSTOMER DUMP: " . Dumper $Customer->{'_column_data'});
			$c->stash($Customer->{'_column_data'});
			$c->stash->{customerAddress} = $Customer->address;
			$c->stash->{customerAuxFormAddress} = $Customer->auxilary_address;
			$c->stash->{cust_defaulttoquickship} = 1 if ( $Customer->{'quickship'} && ($Customer->{'quickship'} eq '2') );


			my @shipmentmarkupdata =$c->model('MyArrs::RateData')->search({
				-and => [
				  -or => [
					freightmarkupamt => { '!=', undef },
					freightmarkuppercent  => { '!=', undef },
				  ],
				  customerid => $Customer->customerid,
				  ownerid => $Customer->customerid,
				  ownertypeid => 1,
				],
			});

			foreach my $RateData (@shipmentmarkupdata)
				{
				if($RateData->freightmarkupamt)
					{
					$c->stash->{shipmentmarkup} = $RateData->freightmarkupamt;
					$c->stash->{shipmentmarkuptype} = 'amt' ;
					}
				elsif ($RateData->freightmarkuppercent)
					{
					$c->stash->{shipmentmarkup} = $RateData->freightmarkuppercent * 100;
					$c->stash->{shipmentmarkuptype} = 'percent';
					}
				}

			my @assdatamarkupdata =$c->model('MyArrs::AssData')->search({
				-and => [
				  -or => [
					assmarkupamt => { '!=', undef },
					assmarkuppercent  => { '!=', undef },
				  ],
				  ownerid => $Customer->customerid,
				  ownertypeid => 1,
				],
			});

			foreach my $AssData (@assdatamarkupdata)
				{
				if ($AssData->assmarkupamt)
					{
					$c->stash->{assmarkup} = $AssData->assmarkupamt;
					$c->stash->{assmarkuptype} = 'amt';
					}
				elsif ($AssData->assmarkuppercent)
					{
					$c->stash->{assmarkup} = $AssData->assmarkuppercent  * 100;
					$c->stash->{assmarkuptype} = 'percent';
					}
				}

			$self->get_customer_contacts($Customer->customerid)
			}

		$c->stash->{CONTACT_INFORMATION} = $c->forward($c->view('Ajax'), "render", [ "templates/customer/settings.tt" ]);
		$c->stash->{CONTACT_LIST}            = 0;
		$c->stash->{CONTACT_MANAGEMENT}      = 0;
		$c->stash->{companysetting_loop}     = $self->get_company_setting_list($Customer);
		$c->stash->{weighttype_loop}         = [{ name => 'LB', value => 'LBS'},{ name => 'KG', value => 'KGS'}];
		$c->stash->{countrylist_loop}        = $self->get_select_list('COUNTRY');
		$c->stash->{statelist_loop}          = $self->get_select_list('US_STATES');
		$c->stash->{customerlist_loop}       = $self->get_select_list('CUSTOMER');
		$c->stash->{boltype_loop}            = $self->get_select_list('BOL_TYPE');
		$c->stash->{boldetail_loop}          = $self->get_select_list('BOL_DETAIL');
		$c->stash->{capability_loop}         = $self->get_select_list('CAPABILITY_LIST');
		$c->stash->{loginlevel_loop}         = $self->get_select_list('LOGIN_LEVEL');
		$c->stash->{quotemarkup_loop}        = $self->get_select_list('YES_NO_NUMERIC');
		$c->stash->{quotemarkupdefault_loop} = $self->get_select_list('QUOTE_MARKUP');
		$c->stash->{unittype_loop}           = $self->get_select_list('UNIT_TYPE');
		$c->stash->{poinstructions_loop}     = $self->get_select_list('POINT_INSTRUCTION');
		$c->stash->{poauthtype_loop}         = $self->get_select_list('PO_AUTH_TYPE');
		$c->stash->{companytype_loop}        = $self->get_select_list('COMPANY_TYPE');
		$c->stash->{defaultpackinglist_loop} = $self->get_select_list('DEFAULT_PACKING_LIST');
		$c->stash->{packinglist_loop}        = $self->get_select_list('PACKING_LIST');
		$c->stash->{liveproduct_loop}        = $self->get_select_list('LIVE_PRODUCT_LIST');
		$c->stash->{quickshipdroplist_loop}  = $self->get_select_list('QUICKSHIP_DROPLIST');
		$c->stash->{indicatortype_loop}      = $self->get_select_list('INDICATOR_TYPE');
		$c->stash->{fceditability_loop}      = $self->get_select_list('FREIGHT_CHARGE_EDITABILITY_LIST');
		$c->stash->{labelstub_loop}          = $self->get_select_list('LABEL_STUB_LIST');
		$c->stash->{markuptype_loop}         = $self->get_select_list('MARKUP_TYPE');
		$c->stash->{SETUP_CUSTOMER}          = 1;
		}

	$c->stash->{CUSTOMER_MANAGEMENT} = 1;
	$c->stash->{template} = "templates/customer/settings.tt";
	}

sub get_customer
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	my $WHERE = {};
	if (length $params->{'customerid'})
		{
		$WHERE->{customerid} = $params->{'customerid'};
		}
	elsif (length $params->{'customername'})
		{
		$WHERE->{customername} = $params->{'customername'};
		}

	return undef unless scalar keys %$WHERE;
	return $c->model('MyDBI::Customer')->find($WHERE);
	}

sub ajax :Local
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	#$c->log->debug("SETTINGS AJAX");

	$c->stash->{ajax} = 1;

	if ($params->{'productsku'})
		{
		my $WHERE = { customerid => $self->customer->customerid };
		my $ORDER_BY = { order_by => 'description' };

		$WHERE->{productskuid} = [split(',', $params->{'page'})];
		#$c->log->debug("WHERE: " . Dumper $WHERE);
		my @productskus = $c->model('MyDBI::Productsku')->search($WHERE, $ORDER_BY);

		#$c->log->debug("TOTAL SKUS: " . @productskus);
		$c->stash->{productskulist} = \@productskus;
		$c->stash->{productsku_count} = scalar @productskus;

		$c->stash->{PRODUCT_SKU_LIST} = 1;
		$c->stash->{SKU_MANAGEMENT} = 1;
		}
	elsif ($params->{'droplistdata'})
		{
		my $WHERE = { customerid => $self->customer->customerid };
		my $ORDER_BY = { order_by => 'fieldorder desc,fieldtext' };

		$WHERE->{droplistdataid} = [split(',', $params->{'page'})];
		my @droplistdata = $c->model('MyDBI::Droplistdata')->search($WHERE, $ORDER_BY);

		$c->stash->{extiddroplist} = \@droplistdata;
		$c->stash->{extid_droplist_count} = scalar @droplistdata;

		$c->stash->{EXTID_DROP_LIST} = 1;
		$c->stash->{EXTID_MANAGEMENT} = 1;
		}
	elsif ($params->{'customername'})
		{
		my $WHERE = { customerid => [split(',', $params->{'page'})] };
		$c->log->debug("WHERE: " . Dumper $WHERE);
		my @customers = $c->model('MyDBI::Customer')->search($WHERE,{
		select => [
			'customerid',
			'username',
			'customername',
			'contact',
			'phone',
			'email'
			],
		order_by => { -asc => 'customername' },
		});

		$c->log->debug("TOTAL CUSTOMERS: " . @customers);
		$c->stash->{customerlist} = \@customers;
		$c->stash->{customer_count} = scalar @customers;

		$c->stash->{CUSTOMER_LIST} = 1;
		$c->stash->{CUSTOMER_MANAGEMENT} = 1;
		}

	$c->stash($params);
	$c->stash(template => "templates/customer/settings.tt");
	}

sub findsku :Local
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;
	#$c->log->debug("FIND SKU: " . Dumper $params);

	#my $WHERE = { customerid => $self->customer->customerid };
	#$WHERE->{description} = { like => $params->{'term'} };
	#my $rs = $c->model('MyDB')->search($WHERE, { select => ['productskuid'],  as => ['productskuid'], order_by => 'description' });
	#$c->log->debug("productskus: " . Dumper $rs);

	my $sql = "SELECT description FROM productsku WHERE customerid = '" . $self->customer->customerid . "' AND description LIKE '%" . $params->{'term'} . "%' ORDER BY 1";
	my $sth = $c->model('MyDBI')->select($sql);
	#$c->log->debug("query_data: " . Dumper $sth->query_data);
	my $arr = [];
	push(@$arr, $_->[0]) foreach @{$sth->query_data};
	#$c->log->debug("jsonify: " . IntelliShip::Utils->jsonify($arr));
	$c->response->body(IntelliShip::Utils->jsonify($arr));
	}

sub findcustomer :Local
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;
	$c->log->debug("FIND CUSTOMER: " . Dumper $params);

	my $sql = "SELECT customername FROM customer WHERE customername LIKE '%" . $params->{'term'} . "%' ORDER BY 1";
	my $sth = $c->model('MyDBI')->select($sql);
	my $arr = [];
	push(@$arr, $_->[0]) foreach @{$sth->query_data};
	$c->response->body(IntelliShip::Utils->jsonify($arr));
	}

sub productskusetup :Local
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	my $ProductSku = $self->get_product_sku;
	if ($params->{'do'} eq 'setup')
		{
		if ($ProductSku)
			{
			#$c->log->debug("PRODUCT SKU DUMP: " . Dumper $ProductSku->{'_column_data'});
			$c->stash($ProductSku->{'_column_data'});
			}

		$c->log->debug(($ProductSku ? "EDIT (ID: " . $ProductSku->productskuid . ")" : "SETUP NEW") . " PRODUCT SKU SETUP");

		$c->stash->{dimention_list} = $self->get_select_list('DIMENTION');
		$c->stash->{unittype_list} = $self->get_select_list('UNIT_TYPE');
		$c->stash->{yesno_list} = $self->get_select_list('YES_NO_NUMERIC');
		$c->stash->{weighttype_list} = $self->get_select_list('WEIGHT_TYPE');
		$c->stash->{unitofmeasure_list} = $self->get_select_list('UNIT_OF_MEASURE');

		#my $unit_type_description = {};
		#$unit_type_description->{$_->unittypeid} = $_->unittypename foreach $self->context->model('MyDBI::Unittype')->all;
		#$c->stash->{unit_type_description} = $unit_type_description;

		$c->stash->{SETUP_PRODUCT_SKU} = 1;
		}
	elsif ($params->{'do'} eq 'configure')
		{
		$ProductSku = $c->model('MyDBI::Productsku')->new({}) unless $ProductSku;

		$ProductSku->description($params->{description});
		$ProductSku->customerskuid($params->{customerskuid});
		$ProductSku->upccode($params->{upccode});
		$ProductSku->manufacturecountry($params->{manufacturecountry});
		$ProductSku->value($params->{value});
		$ProductSku->class($params->{class});
		$ProductSku->hazardous($params->{hazardous});
		$ProductSku->nmfc($params->{nmfc});
		$ProductSku->unitofmeasure($params->{unitofmeasure});
		$ProductSku->balanceonhand($params->{balanceonhand});
		$ProductSku->unittypeid($params->{unittypeid});
		## SKU
		$ProductSku->weight($params->{weight});
		$ProductSku->weighttype($params->{weighttype});
		$ProductSku->length($params->{length});
		$ProductSku->width($params->{width});
		$ProductSku->height($params->{height});
		$ProductSku->dimtype($params->{dimtype});
		## CASE
		$ProductSku->caseweight($params->{caseweight});
		$ProductSku->caseweighttype($params->{caseweighttype});
		$ProductSku->caselength($params->{caselength});
		$ProductSku->casewidth($params->{casewidth});
		$ProductSku->caseheight($params->{caseheight});
		$ProductSku->casedimtype($params->{casedimtype});
		$ProductSku->skupercase($params->{skupercase});
		## PALLET
		$ProductSku->palletweight($params->{palletweight});
		$ProductSku->palletweighttype($params->{palletweighttype});
		$ProductSku->palletlength($params->{palletlength});
		$ProductSku->palletwidth($params->{palletwidth});
		$ProductSku->palletheight($params->{palletheight});
		$ProductSku->palletdimtype($params->{palletdimtype});
		$ProductSku->casesperpallet($params->{casesperpallet});

		my $msg;
		if ($ProductSku->productskuid)
			{
			$ProductSku->update;
			$c->log->debug("PRODUCT SKU UPDATED, ID: ".$ProductSku->productskuid);
			$msg = "Product sku update successfully!";
			}
		else
			{
			$ProductSku->customerid($self->customer->customerid);
			$ProductSku->productskuid($self->get_token_id);
			$ProductSku->insert;
			$c->log->debug("NEW PRODUCT SKU INSERTED, ID: ".$ProductSku->productskuid);
			$msg = "New product sku configured successfully!";
			}

		$c->stash->{MESSAGE} = $msg;
		$c->detach("skumanagement",$params);
		}

	$c->stash->{SKU_MANAGEMENT} = 1;
	$c->stash->{template} = "templates/customer/settings.tt";
	}

sub get_product_sku
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	my $WHERE = {};
	if (length $params->{'productskuid'})
		{
		$WHERE->{productskuid} = $params->{'productskuid'};
		}
	elsif (length $params->{'productsku'})
		{
		$WHERE->{description} = $params->{'productsku'};
		}

	return undef unless scalar keys %$WHERE;
	return $c->model('MyDBI::Productsku')->find($WHERE);
	}

sub extidsetup :Local
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	my $DropListData = $self->get_drop_list_data;
	if ($params->{'do'} eq 'configure')
		{
		$DropListData = $c->model('MyDBI::Droplistdata')->new({}) unless $DropListData;

		$DropListData->fieldvalue($params->{fieldvalue});
		$DropListData->fieldtext($params->{fieldtext});
		$DropListData->fieldorder($params->{fieldorder});
		$DropListData->datemodified('now');

		if ($DropListData->droplistdataid)
			{
			$DropListData->update;
			$c->stash->{MESSAGE} = "Extid updated successfully!";
			}
		else
			{
			$DropListData->customerid($self->customer->customerid);
			$DropListData->droplistdataid($self->get_token_id);
			$DropListData->field('extid');
			$DropListData->insert;

			$c->stash->{MESSAGE} = "New Extid added successfully!";
			}

		$c->detach("extidmanagement",$params);
		}
	else
		{
		$c->stash($DropListData->{'_column_data'}) if ($DropListData);

		$c->stash->{yesno_list} = $self->get_select_list('YES_NO_NUMERIC');
		$c->stash->{SETUP_EXTID} = 1;
		}

	$c->stash->{EXTID_MANAGEMENT} = 1;
	$c->stash->{template} = "templates/customer/settings.tt";
	}

sub finddroplistdata :Local
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;
	#$c->log->debug("FIND DropListData: " . Dumper $params);

	my $term  = uc($params->{'term'});
	my $sql = "SELECT fieldvalue FROM droplistdata WHERE field = 'extid' and customerid = '" . $self->customer->customerid . "' AND fieldvalue LIKE '%" . $term . "%' ORDER BY 1";
	my $sth = $c->model('MyDBI')->select($sql);

	my $arr = [];
	push(@$arr, $_->[0]) foreach @{$sth->query_data};
	$c->response->body(IntelliShip::Utils->jsonify($arr));
	}

sub get_drop_list_data
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	my $WHERE = {};
	if (length $params->{'droplistdataid'})
		{
		$WHERE->{droplistdataid} = $params->{'droplistdataid'};
		}
	elsif (length $params->{'fieldvalue'})
		{
		$WHERE->{fieldvalue} = uc($params->{'fieldvalue'});
		}

	return undef unless scalar keys %$WHERE;
	return $c->model('MyDBI::Droplistdata')->find($WHERE);
	}

sub process_pagination
	{
	my $self = shift;
	my $type = shift;

	my $c = $self->context;
	my $params = $c->req->params;

	#$c->log->debug("PROCESS PAGINATION");

	my $batch_size = (defined $params->{records_per_page} ? int $params->{records_per_page} : 100);
	$c->stash->{records_per_page} = $batch_size;

	my $sql;
	if ($type eq 'skumanagement')
		{
		$sql = "SELECT productskuid FROM productsku WHERE customerid = '" . $self->customer->customerid . "' ORDER BY description";
		}
	elsif ($type eq 'extidmanagement')
		{
		$sql = "SELECT droplistdataid FROM droplistdata WHERE field = 'extid' AND customerid = '" . $self->customer->customerid . "' ORDER BY fieldorder desc,fieldtext";
		}
	elsif ($type eq 'customermanagement')
		{
		$sql = "SELECT customerid FROM customer ORDER BY customername";
		}

	my $sth = $c->model('MyDBI')->select($sql);

	$c->log->debug("SQL: " . $sql);

	my @matching_ids = map { @$_ } @{ $sth->query_data };
	my $batches = $self->spawn_batches(\@matching_ids,$batch_size);

	#$c->log->debug("TOTAL PAGES: " . @$batches);
	#$c->log->debug("TOTAL PAGES: " . Dumper $batches);
	return $batches;
	}

sub contactinformation :Local
	{
	my $self = shift;
	my $c = $self->context;

	my $params = $c->req->params;
	my $Contact = $params->{'ajax'} ? $c->model('MyDBI::Contact')->find({contactid => $params->{'contactid'}}) : $self->contact;

	my $Address = $Contact->address;
	$c->stash->{contactid} = $params->{'contactid'};

	IntelliShip::Utils->trim_hash_ref_values($params);

	if ($params->{'do'} eq 'cancel')
		{
		$self->get_customer_contacts($Contact->customerid);
		}
	elsif ($params->{'do'} eq 'configure')
		{
		IntelliShip::Utils->hash_decode($params);

		my $addressData = {
			address1	=> $params->{'contact_address1'},
			address2	=> $params->{'contact_address2'},
			city		=> $params->{'contact_city'},
			state		=> $params->{'contact_state'},
			zip			=> $params->{'contact_zip'},
			country		=> $params->{'contact_country'},
			};

		unless ($Address)
			{
			my @addresses = $c->model('MyDBI::Address')->search($addressData);

			$Address = (@addresses ? $addresses[0] : $c->model('MyDBI::Address')->new({}));

			unless ($Address->addressid)
				{
				$Address->addressid($self->get_token_id);
				$Address->insert;
				$c->log->debug("New Address Inserted: " . $Address->addressid);
				}

			$Contact->addressid($Address->addressid);
			}

		$Address->update($addressData);

		$Contact->email($params->{'email'});
		$Contact->fax($params->{'fax'});
		$Contact->department($params->{'department'});
		$Contact->phonemobile($params->{'phonemobile'});
		$Contact->phonebusiness($params->{'phonebusiness'});
		$Contact->phonehome($params->{'phonehome'});
		$Contact->update;

		$c->stash->{MESSAGE} = 'Contact information updated successfully';

		if ($params->{'ajax'})
			{
			$self->get_customer_contacts($Contact->customerid);
			}
		else
			{
			$c->detach("index",$params);
			}
		}
	else
		{
		$c->stash->{CONTACT_INFO} = 1;
		$c->stash->{contactInfo} = $Contact;
		$c->stash->{contactAddress} = $Address;

		$c->stash->{location}	= $Contact->get_contact_data_value('location');
		$c->stash->{ownerid}	= $Contact->get_contact_data_value('ownerid');
		$c->stash->{origdate}	= $Contact->get_contact_data_value('origdate');
		$c->stash->{sourcedate}	= $Contact->get_contact_data_value('sourcedate');
		$c->stash->{disabledate}= $Contact->get_contact_data_value('disabledate');

		$c->stash->{statelist_loop} = $self->get_select_list('US_STATES');
		$c->stash->{countrylist_loop} = $self->get_select_list('COUNTRY');

		$c->stash(template => "templates/customer/settings.tt");
		}
	}

sub get_company_setting_list
	{
	my $self = shift;
	my $Customer = shift;
	my $c = $self->context;

	my $list = [];
	foreach my $key (sort keys %$CUSTOMER_RULES)
		{
		my $ruleHash = $CUSTOMER_RULES->{$key};
		if($ruleHash->{type} eq 'CHECKBOX')
			{
			push(@$list, { name => $ruleHash->{name}, value => $ruleHash->{value}, checked => ($Customer and $Customer->get_contact_data_value($ruleHash->{value})) });
			}
		else
			{
			$c->stash->{'cust_'.$ruleHash->{value}} = ($Customer and $Customer->get_contact_data_value($ruleHash->{value}));
			}
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
