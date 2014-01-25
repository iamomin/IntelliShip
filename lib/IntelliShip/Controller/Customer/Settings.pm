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

sub customersetup :Local
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	my $Customer = $self->get_customer;
	if ($params->{'do'} eq 'setup')
		{
		if ($Customer)
			{
			$c->log->debug("CUSTOMER DUMP: " . Dumper $Customer->{'_column_data'});
			$c->stash($Customer->{'_column_data'});
			}

		$c->log->debug(($Customer ? "EDIT (ID: " . $Customer->customerid . ")" : "SETUP NEW") . " CUSTOMER SETUP");

		$c->stash->{customerAddress} = $Customer->address;
		$c->stash->{customerAuxFormAddress} = $Customer->auxilary_address;
		$c->stash->{countrylist_loop} = $self->get_select_list('COUNTRY');
		$c->stash->{statelist_loop} = $self->get_select_list('US_STATES');
		$c->stash->{customerlist_loop} = $self->get_select_list('CUSTOMER');
		$c->stash->{cust_sopid} = $Customer->get_contact_data_value('sopid');
		$c->stash->{cust_clientid} = $Customer->get_contact_data_value('clientid');
		$c->stash->{companysetting_loop} = $self->get_company_setting_list($Customer);

		$c->log->debug("COMPANY SETTINGS: " . Dumper $c->stash->{companysetting_loop});
		$c->stash->{weighttype_loop} = [{ name => 'LB', value => 'LBS'},{ name => 'KG', value => 'KGS'}];
		$c->stash->{cust_labelport} = $Customer->get_contact_data_value('labelport');
		$c->stash->{cust_defaultthermalcount} = $Customer->get_contact_data_value('defaultthermalcount');
		$c->stash->{cust_bolcount8_5x11} = $Customer->get_contact_data_value('bolcount8_5x11');
		$c->stash->{cust_bolcountthermal} = $Customer->get_contact_data_value('bolcountthermal');

		$c->stash->{boltype_loop} = $self->get_select_list('BOL_TYPE');
		$c->stash->{cust_boltype} = $Customer->get_contact_data_value('boltype');

		$c->stash->{boldetail_loop} = $self->get_select_list('BOL_DETAIL');
		$c->stash->{cust_boldetail} = $Customer->get_contact_data_value('boldetail');
		$c->stash->{cust_autoreporttime} = $Customer->get_contact_data_value('autoreporttime');
		$c->stash->{cust_autoreportemail} = $Customer->get_contact_data_value('autoreportemail');
		$c->stash->{cust_autoreportinterval} = $Customer->get_contact_data_value('autoreportinterval');
		$c->stash->{cust_proxyip} = $Customer->get_contact_data_value('proxyip');
		$c->stash->{cust_proxyport} = $Customer->get_contact_data_value('proxyport');


		$c->stash->{cust_losspreventemail} = $Customer->get_contact_data_value('losspreventemail');
		$c->stash->{cust_losspreventemailordercreate} = $Customer->get_contact_data_value('losspreventemailordercreate');
		$c->stash->{cust_smartaddressbook} = $Customer->get_contact_data_value('smartaddressbook');
		$c->stash->{cust_apiaosaddress} = $Customer->get_contact_data_value('apiaosaddress');

		$c->stash->{cust_chargediffflat} = $Customer->get_contact_data_value('chargediffflat');
		$c->stash->{cust_chargediffpct} = $Customer->get_contact_data_value('chargediffpct');
		$c->stash->{cust_chargediffmin} = $Customer->get_contact_data_value('chargediffmin');

		$c->stash->{capability_loop} = $self->get_select_list('CAPABILITY_LIST');
		$c->stash->{cust_returncapability} = $Customer->get_contact_data_value('returncapability');

		$c->stash->{cust_dropshipcapability} = $Customer->get_contact_data_value('dropshipcapability');

		$c->stash->{loginlevel_loop} = $self->get_select_list('LOGIN_LEVEL');
		$c->stash->{cust_loginlevel} = $Customer->get_contact_data_value('loginlevel');

		$c->stash->{quotemarkup_loop} = $self->get_select_list('YES_NO_NUMERIC');
		$c->stash->{cust_quotemarkup} = $Customer->get_contact_data_value('quotemarkup');

		$c->stash->{quotemarkupdefault_loop} = $self->get_select_list('QUOTE_MARKUP');
		$c->stash->{cust_quotemarkupdefault} = $Customer->get_contact_data_value('quotemarkupdefault');

		$c->stash->{cust_defaultfreightclass} = $Customer->get_contact_data_value('defaultfreightclass');
		$c->stash->{cust_cycletimethreshold} = $Customer->get_contact_data_value('cycletimethreshold');
		$c->stash->{cust_duedateoffsetequal} = $Customer->get_contact_data_value('duedateoffsetequal');
		$c->stash->{cust_duedateoffsetlessthan} = $Customer->get_contact_data_value('duedateoffsetlessthan');

		$c->stash->{unittype_loop} = $self->get_select_list('UNIT_TYPE');
		$c->stash->{cust_defaultpackageunittype} = $Customer->get_contact_data_value('defaultpackageunittype');
		$c->stash->{cust_defaultproductunittype} = $Customer->get_contact_data_value('defaultproductunittype');

		$c->stash->{poinstructions_loop} = $self->get_select_list('POINT_INSTRUCTION');
		$c->stash->{cust_poinstructions} = $Customer->get_contact_data_value('poinstructions');

		$c->stash->{poauthtype_loop} = $self->get_select_list('PO_AUTH_TYPE');
		$c->stash->{cust_poauthtype} = $Customer->get_contact_data_value('poauthtype');

		$c->stash->{companytype_loop} = $self->get_select_list('COMPANY_TYPE');
		$c->stash->{cust_companytype} = $Customer->get_contact_data_value('companytype');

		$c->stash->{defaultpackinglist_loop} = $self->get_select_list('DEFAULT_PACKING_LIST');
		$c->stash->{cust_defaultpackinglist} = $Customer->get_contact_data_value('defaultpackinglist');

		$c->stash->{packinglist_loop} = $self->get_select_list('PACKING_LIST');
		$c->stash->{cust_packinglist} = $Customer->get_contact_data_value('packinglist');


		$c->stash->{liveproduct_loop} = $self->get_select_list('LIVE_PRODUCT_LIST');
		$c->stash->{cust_liveproduct} = $Customer->get_contact_data_value('liveproduct');


		$c->stash->{quickshipdroplist_loop} = $self->get_select_list('QUICKSHIP_DROPLIST');

		$c->stash->{indicatortype_loop} = $self->get_select_list('INDICATOR_TYPE');
		#$c->stash->{cust_liveproduct} = $Customer->get_contact_data_value('liveproduct');

		$c->stash->{markuptype_loop} = $self->get_select_list('MARKUP_TYPE');
		my $shipmentmarkupsql = "
				SELECT *
				FROM ratedata
				WHERE
					customerid = '$Customer->customerid'
					AND ownerid = '$Customer->customerid'
					AND ownertypeid = 1
					AND ( freightmarkupamt is not null or freightmarkuppercent is not null )";

		my $ShipmentMarkup = $c->model('MyArrs')->select($shipmentmarkupsql);

		if ($ShipmentMarkup->numrows > 0)
			{
			my $data = $ShipmentMarkup->fetchrow(0);
			if($data->freightmarkupamt)
				{
				$c->stash->{shipmentmarkup} = $data->freightmarkupamt;
				$c->stash->{shipmentmarkuptype} = 'amt' ;
				}
			elsif ($data->freightmarkuppercent)
				{
				$c->stash->{shipmentmarkup} = $data->freightmarkuppercent * 100;
				$c->stash->{shipmentmarkuptype} = 'percent';
				}
			}

		my $assdatamarkupsql = "
				SELECT *
				FROM
					assdata
				WHERE
					ownerid = '$Customer->customerid'
					AND ownertypeid = 1
					AND ( assmarkupamt is not null or assmarkuppercent is not null )";

		my $AssDataMarkup = $c->model('MyArrs')->select($assdatamarkupsql);

		if ($AssDataMarkup->numrows > 0)
			{
			my $AssData = $AssDataMarkup->fetchrow(0);
			return $AssData->{'carriername'};
			if ($AssData->assmarkupamt)
				{
				$c->stash->{assmarkup} = $AssData->assmarkupamt;
				$c->stash->{assmarkuptype} = 'amt';
				}
			elsif ($AssData->assmarkuppercent)
				{
				$c->stash->{assmarkup} = $AssData->assmarkuppercent * 100;
				$c->stash->{assmarkuptype} = 'percent';
				}
			}



		$c->stash->{SETUP_CUSTOMER} = 1;
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
	elsif (length $params->{'customer'})
		{
		$WHERE->{username} = $params->{'customer'};
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
	elsif ($params->{'customer'})
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

	my $sql = "SELECT username FROM customer WHERE username LIKE '%" . $params->{'term'} . "%' ORDER BY 1";
	my $sth = $c->model('MyDBI')->select($sql);
	#$c->log->debug("query_data: " . Dumper $sth->query_data);
	my $arr = [];
	push(@$arr, $_->[0]) foreach @{$sth->query_data};
	#$c->log->debug("jsonify: " . IntelliShip::Utils->jsonify($arr));
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

	#$c->log->debug("TOTAL RECORDS: " . $sth->numrows);

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
	my $Contact = $self->contact;
	my $Address = $Contact->address;

	#$c->log->debug("Contact: " . Dumper $Contact->{_column_data});
	#$c->log->debug("Address: " . Dumper $Address->{_column_data});

	IntelliShip::Utils->trim_hash_ref_values($params);

	if ($params->{'do'} eq 'configure')
		{
		my $addressData = {
			address1	=> $params->{'address1'},
			address2	=> $params->{'address2'},
			city		=> $params->{'city'},
			state		=> $params->{'state'},
			zip			=> $params->{'zip'},
			country		=> $params->{'country'},
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

		$c->detach("index",$params);
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

my $CHKBOX_SETTINGS = {
	 1 => { name => 'Super User', value => 'superuser' },
	 2 => { name => 'Administrator', value => 'administrator' },
	 3 => { name => 'Third Party Billing', value=> 'thirdpartybill' },
	 4 => { name => 'Auto Print', value => 'autoprint' },
	 5 => { name => 'Has Rates', value => 'hasrates' },
	 6 => { name => 'Allow Postdating', value => 'allowpostdating' },
	 7 => { name => 'Auto Process', value => 'autoprocess' },
	 8 => { name => 'Batch Shipping', value => 'batchprocess' },
	 9 => { name => 'Quick Ship', value => 'quickship' },
	10 => { name => 'Default To Quick Ship', value => 'defaulttoquickship' },
	11 => { name => 'Default Declared Value', value => 'defaultdeclaredvalue' },
	12 => { name => 'Default Freight Insurance', value => 'defaultfreightinsurance' },
	13 => { name => 'Print Thermal BOL', value => 'printthermalbol' },
	14 => { name => 'Print 8.5x11 BOL', value => 'print8_5x11bol' },
	15 => { name => 'Has Product Data', value => 'hasproductdata' },
	16 => { name => 'Export Shipment Tab', value => 'exportshipmenttab' },
	17 => { name => 'Auto CS Select', value => 'autocsselect' },
	18 => { name => 'Auto Shipment Opimize', value => 'autoshipmentoptimize' },
	19 => { name => 'Error on Past Ship Date', value => 'errorshipdate' },
	20 => { name => 'Error on Past Due Date', value => 'errorduedate' },
	21 => { name => 'Upload Orders', value => 'uploadorders' },
	22 => { name => 'ZPL2', value => 'cust_zpl2' },
	23 => { name => 'Security Types', value => 'hassecurity' },
	24 => { name => 'Show Hazardous', value => 'showhazardous' },
	25 => { name => 'AM Delivery', value => 'amdelivery' },
	26 => { name => 'Print UCC128 Label', value => 'checkucc128' },
	27 => { name => 'Require Order Number', value => 'reqordernumber' },
	28 => { name => 'Require Customer Number', value => 'reqcustnum' },
	29 => { name => 'Require PO Number', value => 'reqponum' },
	30 => { name => 'Require Product Description', value => 'reqproddescr' },
	31 => { name => 'Require Ship Date', value => 'reqdatetoship' },
	32 => { name => 'Require Due Date', value => 'reqdateneeded' },
	33 => { name => 'Require', value => 'reqcustref2' },
	34 => { name => 'Require', value => 'reqcustref3' },
	35 => { name => 'Require Department', value => 'reqdepartment' },
	36 => { name => 'Require', value => 'reqextid' },
	37 => { name => 'Manual Routing Control', value => 'manroutingctrl' },
	38 => { name => 'Has AltSOPs', value => 'hasaltsops' },
	39 => { name => 'Custnum Address Lookup', value => 'custnumaddresslookup' },
	40 => { name => 'Saturday Shipping', value => 'satshipping' },
	41 => { name => 'Sunday Shipping', value => 'sunshipping' },
	42 => { name => 'Auto DIM Classing', value => 'autodimclass' },
	43 => { name => 'Save Order Upon Shipping', value => 'saveorder' },
	44 => { name => 'Always Show Assessorials', value => 'alwaysshowassessorials' },
	45 => { name => 'TAB Pick-N-Pack', value => 'pickpack' },
	46 => { name => 'Date Specific Consolidation', value => 'dateconsolidation' },
	47 => { name => 'Alert Cutoff Date Change', value => 'alertcutoffdatechange' },
	48 => { name => 'Allow Consolidate/Combine', value => 'consolidatecombine' },
	49 => { name => 'Default Multi Order Nums', value => 'defaultmultiordernum' },
	50 => { name => 'Export PackProdata (requires shipment export)', value => 'exportpackprodata' },
	51 => { name => 'Default Commercial Invoice', value => 'defaultcomminv' },
	52 => { name => 'Intelliship Notification', value => 'aosnotifications' },
	53 => { name => 'DisAllow New Order', value => 'disallowneworder' },
	54 => { name => 'Single Order Shipment', value => 'singleordershipment' },
	55 => { name => 'DisAllow Ship Packages', value => 'disallowshippackages' },
	56 => { name => 'Independent Quantity/Weight', value => 'quantityxweight' },
	};

sub get_company_setting_list
	{
	my $self = shift;
	my $Customer = shift;

	my $list = [];
	foreach my $key (sort keys %$CHKBOX_SETTINGS)
		{
		my $ruleHash = $CHKBOX_SETTINGS->{$key};
		push(@$list, { name => $ruleHash->{name}, value => $ruleHash->{value}, checked => $Customer->get_contact_data_value($ruleHash->{value}) });
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
