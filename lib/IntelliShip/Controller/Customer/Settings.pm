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
	#push (@$settings, { name => 'Contact Information', url => '/customer/settings/contactinformation'}) if $Customer->customerid eq '8ETKCWZXZC0UY';
	push (@$settings, { name => 'Contact Information', url => '/customer/settings/contactinformation'});
	push (@$settings, { name => 'Company Management', url => '/customer/settings/company'}) if $Contact->is_superuser;
	push (@$settings, { name => 'Sku Management', url => '/customer/settings/skumanagement'}) if $Contact->login_level != 25 and $Contact->get_contact_data_value('skumanager');
	push (@$settings, { name => 'Extid Management', url => '/customer/settings/extidmanagement'}) if $Customer->has_extid_data($c->model('MyDBI'));

	if ($Contact->login_level != 25 and ($Contact->login_level == 35 or $Contact->login_level == 40))
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
		$c->stash->{MESSAGE} = "Incorrect current password, please retry.";
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

	my %measures = map { $_->{value} => $_->{name} } @{$self->get_select_list('UNIT_OF_MEASURE')};
	$_->unitofmeasure($measures{$_->unitofmeasure}) foreach @productskus;

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

	$c->stash($params);
	$c->stash(template => "templates/customer/settings.tt");
	}

sub findsku :Local
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	my $sql = "SELECT customerskuid FROM productsku WHERE customerid = '" . $self->customer->customerid . "' AND customerskuid LIKE '%" . $params->{'term'} . "%' ORDER BY 1";
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

		$c->log->debug(($ProductSku ? "EDIT (ID: " . $ProductSku->productskuid . ")" : "SETUP NEW") . " PRODUCT SKU");

		$c->stash->{hazardous} = '0' unless $c->stash->{hazardous}; ## No
		$c->stash->{unitofmeasure} = 'EA' unless $c->stash->{unitofmeasure}; ## Each
		$c->stash->{unittypeid} = '3' unless $c->stash->{unittypeid}; ## Each
		$c->stash->{dimention_list} = $self->get_select_list('DIMENTION');
		$c->stash->{unittype_list} = $self->get_select_list('UNIT_TYPE');
		$c->stash->{yesno_list} = $self->get_select_list('YES_NO_NUMERIC');
		$c->stash->{weighttype_list} = $self->get_select_list('WEIGHT_TYPE');
		$c->stash->{class_list} = $self->get_select_list('CLASS');
		$c->stash->{unitofmeasure_list} = $self->get_select_list('UNIT_OF_MEASURE');

		#my $unit_type_description = {};
		#$unit_type_description->{$_->unittypeid} = $_->unittypename foreach $self->context->model('MyDBI::Unittype')->all;
		#$c->stash->{unit_type_description} = $unit_type_description;

		$c->stash->{SETUP_PRODUCT_SKU} = 1;
		}
	elsif ($params->{'do'} eq 'configure')
		{
		$ProductSku = $c->model('MyDBI::Productsku')->new({}) unless $ProductSku;

		$ProductSku->customerskuid($params->{customerskuid}) if($params->{customerskuid});
		$ProductSku->description($params->{description}? $params->{description} :undef);
		$ProductSku->upccode($params->{upccode} ? $params->{upccode} :undef );
		$ProductSku->manufacturecountry($params->{manufacturecountry} ? $params->{manufacturecountry} :undef);
		$ProductSku->value($params->{value} ? $params->{value} : undef);
		$ProductSku->class($params->{class} ? $params->{class} : undef);
		$ProductSku->hazardous($params->{hazardous});
		$ProductSku->nmfc($params->{nmfc} ? $params->{nmfc} : undef);
		$ProductSku->unitofmeasure($params->{unitofmeasure});
		$ProductSku->balanceonhand($params->{balanceonhand} ? $params->{balanceonhand} : undef);
		$ProductSku->unittypeid($params->{unittypeid} ? $params->{unittypeid} : undef);
		## SKU
		$ProductSku->weight($params->{weight} ? $params->{weight} : undef);
		$ProductSku->weighttype($params->{weighttype});
		$ProductSku->length($params->{length} ? $params->{length} : undef);
		$ProductSku->width($params->{width} ? $params->{width} : undef);
		$ProductSku->height($params->{height} ? $params->{height} : undef);
		$ProductSku->dimtype($params->{dimtype});
		# CASE
		$ProductSku->caseweight($params->{caseweight} ? $params->{caseweight} : undef);
		$ProductSku->caseweighttype($params->{caseweighttype});
		$ProductSku->caselength($params->{caselength} ? $params->{caselength} : undef);
		$ProductSku->casewidth($params->{casewidth} ? $params->{casewidth} : undef);
		$ProductSku->caseheight($params->{caseheight} ? $params->{caseheight} : undef);
		$ProductSku->casedimtype($params->{casedimtype});
		$ProductSku->skupercase($params->{skupercase} ? $params->{skupercase} : undef);
		# PALLET
		$ProductSku->palletweight($params->{palletweight} ? $params->{palletweight} : undef);
		$ProductSku->palletweighttype($params->{palletweighttype} ? $params->{palletweighttype} : undef);
		$ProductSku->palletlength($params->{palletlength} ? $params->{palletlength} : undef);
		$ProductSku->palletwidth($params->{palletwidth} ? $params->{palletwidth} : undef);
		$ProductSku->palletheight($params->{palletheight} ? $params->{palletheight} : undef);
		$ProductSku->palletdimtype($params->{palletdimtype} ? $params->{palletdimtype} : undef);
		$ProductSku->casesperpallet($params->{casesperpallet} ? $params->{casesperpallet} : undef);

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
	elsif ($params->{'do'} eq 'delete')
		{
		$ProductSku->delete;
		$c->stash->{MESSAGE} = "Product sku deleted successfully!";
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
	elsif (length $params->{'customerskuid'})
		{
		$WHERE->{customerskuid} = $params->{'customerskuid'};
		}

	return undef unless scalar keys %$WHERE;

	$WHERE->{customerid} = $self->customer->customerid;

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
	elsif ($type eq 'contactmanagement')
		{
		$sql = "SELECT contactid FROM contact WHERE customerid = '" . $c->stash->{customerid} ."' ORDER BY username";
		}

	my $sth = $c->model('MyDBI')->select($sql);

	#$c->log->debug("SQL: " . $sql);

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

	$c->stash($params);

	IntelliShip::Utils->trim_hash_ref_values($params);

	if ($params->{'do'} eq 'delete')
		{
		my $Contact =  $c->model('MyDBI::Contact')->find({contactid => $params->{'contactid'}});
		$Contact->delete;
		$self->get_customer_contacts($Contact->customerid);
		}
	elsif ($params->{'do'} eq 'configure')
		{
		IntelliShip::Utils->hash_decode($params);

		my $Contact =  $c->model('MyDBI::Contact')->find({contactid => $params->{'contactid'}});

		unless ($Contact)
			{
			$c->log->debug("....... NO CONTACT INFO, CREATING NEW FOR CUSTOMER ID: " . $params->{'customerid'});
			$Contact = $c->model('MyDBI::Contact')->new({});
			$Contact->contactid($self->get_token_id);
			$Contact->customerid($params->{'customerid'});
			#$Contact->password($Contact->contactid);
			$Contact->insert;
			}

		my $addressData = {
			address1	=> $params->{'contact_address1'},
			address2	=> $params->{'contact_address2'},
			city		=> $params->{'contact_city'},
			state		=> $params->{'contact_state'},
			zip			=> $params->{'contact_zip'},
			country		=> $params->{'contact_country'},
			};

		my $Address;
		if ($Contact->addressid)
			{
			$Address = $Contact->address;
			}
		else
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

		$Contact->username($params->{'contact_username'}) if $params->{'contact_username'};
		$Contact->password($params->{'contact_password'}) if $params->{'contact_password'};

		$Contact->firstname($params->{'firstname'});
		$Contact->lastname($params->{'lastname'});
		$Contact->email($params->{'contact_email'});
		$Contact->fax($params->{'contact_fax'});
		$Contact->department($params->{'department'});
		$Contact->phonemobile($params->{'phonemobile'});
		$Contact->phonebusiness($params->{'phonebusiness'});
		$Contact->phonehome($params->{'phonehome'});

	# INITIALLY FLUSH CONTACT SETTINGS IF ANY.
	$Contact->customer_contact_data({ ownertypeid => '2' })->delete;
	$c->log->debug("___ Flush old custcondata for Contact: " . $Contact->contactid);

	my $CONTACT_RULES = IntelliShip::Utils->get_rules('CONTACT');

	$c->log->debug("___ CONTACT_RULES record count " . @$CONTACT_RULES);

	#INSERT NEW CONTACT SETTING RECORDS
	foreach my $ruleHash (@$CONTACT_RULES)
		{
		#$c->log->debug("FIELD : $ruleHash->{value} = " . $params->{$ruleHash->{value}});
		if (defined $params->{$ruleHash->{value}})
			{
			my $customerContactData = {
				ownertypeid  => 2,
				ownerid      => $Contact->contactid,
				datatypeid   => $ruleHash->{datatypeid},
				datatypename => $ruleHash->{value},
				value        => ($ruleHash->{type} eq 'CHECKBOX') ? 1 : $params->{$ruleHash->{value}},
				};

			my $NewCCData = $c->model("MyDBI::Custcondata")->new($customerContactData);
			$NewCCData->custcondataid($self->get_token_id);
			$NewCCData->insert;
			}
		}

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
		my $Contact;
		if (defined $params->{'contactid'})
			{
			$Contact = $c->model('MyDBI::Contact')->find({contactid => $params->{'contactid'}});
			}
		else
			{
			$c->log->debug(" GETTING SELF CONTACT = ");
			$Contact = $self->contact;
			$c->stash->{customerid} = $Contact->customerid
			}

		if ($Contact)
			{
			$c->stash->{contactInfo}		= $Contact;
			$c->stash->{contact_password}	= $Contact->password;
			$c->stash->{contactAddress}		= $Contact->address;
			$c->stash->{location}			= $Contact->get_contact_data_value('location');
			$c->stash->{ownerid}			= $Contact->get_contact_data_value('ownerid');
			$c->stash->{origdate}			= $Contact->get_contact_data_value('origdate');
			$c->stash->{sourcedate}			= $Contact->get_contact_data_value('sourcedate');
			$c->stash->{disabledate}		= $Contact->get_contact_data_value('disabledate');
			}

		$c->stash->{contact_password}        = $self->get_token_id unless $c->stash->{contact_password};
		$c->stash->{statelist_loop}          = $self->get_select_list('US_STATES');
		$c->stash->{countrylist_loop}        = $self->get_select_list('COUNTRY');

		$c->stash->{capability_loop}         = $self->get_select_list('CAPABILITY_LIST');
		$c->stash->{loginlevel_loop}         = $self->get_select_list('LOGIN_LEVEL');
		$c->stash->{quotemarkup_loop}        = $self->get_select_list('YES_NO_NUMERIC');
		$c->stash->{quotemarkupdefault_loop} = $self->get_select_list('QUOTE_MARKUP');
		$c->stash->{unittype_loop}           = $self->get_select_list('UNIT_TYPE');
		$c->stash->{poinstructions_loop}     = $self->get_select_list('POINT_INSTRUCTION');
		$c->stash->{poauthtype_loop}         = $self->get_select_list('PO_AUTH_TYPE');
		$c->stash->{defaultpackinglist_loop} = $self->get_select_list('DEFAULT_PACKING_LIST');
		$c->stash->{quickshipdroplist_loop}  = $self->get_select_list('QUICKSHIP_DROPLIST');
		$c->stash->{indicatortype_loop}      = $self->get_select_list('INDICATOR_TYPE');
		$c->stash->{packinglist_loop}        = $self->get_select_list('PACKING_LIST');
		$c->stash->{labeltype_loop}          = $self->get_select_list('LABEL_TYPE');
		$c->stash->{printreturnshipment_loop}= $self->get_select_list('PRINT_RETURN_SHIPMENT');
		$c->stash->{contactsetting_loop}     = $self->get_contact_setting_list($Contact);

		$c->stash->{SUPER_USER} = $self->contact->is_superuser;

		$self->set_required_fields;

		$c->stash->{CONTACT_INFO}  = 1;
		$c->stash(template => "templates/customer/settings.tt");
		}
	}

sub set_required_fields :Private
	{
	my $self = shift;
	my $c = $self->context;

	my $requiredList = [];

	if ($self->contact->is_superuser)
		{
		push(@$requiredList, { name => 'phonebusiness',	details => "{ phone: false }"});
		push(@$requiredList, { name => 'phonemobile',	details => "{ phone: false }"});
		}
	else
		{
		$requiredList = [
			{ name => 'phonebusiness',    details => "{ phone: true }"},
			{ name => 'phonemobile',      details => "{ phone: true }"},
			{ name => 'contact_address1', details => "{ minlength: 2 }"},
			{ name => 'contact_city',     details => " { minlength: 2 }"},
			{ name => 'contact_state',    details => "{ minlength: 2 }"},
			{ name => 'contact_zip',      details => "{ minlength: 5 }"},
			{ name => 'contact_country',  details => "{ minlength: 1 }"},
			];
		}

	push(@$requiredList, { name => 'contact_username', details => "{ minlength: 1 }"});
	push(@$requiredList, { name => 'contact_password', details => "{ minlength: 6 }"});
	push(@$requiredList, { name => 'phonehome',        details => "{ phone: false }"});
	push(@$requiredList, { name => 'contact_email',    details => "{ email: false }"});
	push(@$requiredList, { name => 'contact_fax',      details => "{ phone: false }"});

	$c->stash->{requiredfield_list} = $requiredList;
	}

sub get_customer_contacts :Private
	{
	my $self = shift;
	my $customerid = shift;

	my $c = $self->context;
	my $params = $c->req->params;

	$customerid = $params->{'customerid'} if !$customerid and $params->{'customerid'};
	$c->stash->{customerid} = $customerid;
	$c->log->debug("CUSTOMER CONTACT MANAGEMENT");

	my $contact_batches;
	my $WHERE = {};
	if ($params->{'contact_ids'})
		{
		$WHERE = { contactid => [split(',', $params->{'contact_ids'})] };
		}
	else
		{
		$contact_batches = $self->process_pagination('contactmanagement');
		$WHERE->{contactid} = $contact_batches->[0] if $contact_batches;
		}
	$c->stash->{SHOW_PAGINATION} = 1 unless $params->{'contact_ids'};

	#$c->log->debug("WHERE: " . Dumper $WHERE);

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

	$c->stash->{contact_batches} = $contact_batches;
	$c->stash->{recordsperpage_list} = $self->get_select_list('RECORDS_PER_PAGE');

	$c->stash->{CONTACT_LIST} = 1;
	$c->stash->{CONTACT_MANAGEMENT} = 1;

	$c->stash(template => "templates/customer/settings-company.tt");
	}

sub get_contact_setting_list :Private
	{
	my $self = shift;
	my $Contact = shift;
	my $c = $self->context;

	my $CONTACT_RULES = IntelliShip::Utils->get_rules('CONTACT');

	$c->log->debug("___ CONTACT_RULES record count " . @$CONTACT_RULES);

	#my $list = [];
	foreach my $ruleHash (@$CONTACT_RULES)
		{
		my $value = ($Contact and $Contact->get_only_contact_data_value($ruleHash->{value})) || '';

		$value = $ruleHash->{default} if (!$value and defined $ruleHash->{default});
		if ($ruleHash->{type} eq 'CHECKBOX')
			{
			$ruleHash->{checked} = $value ;
			}
		elsif ($ruleHash->{type} eq 'SELECT' or $ruleHash->{type} eq 'RADIO')
			{
			$ruleHash->{selected} = $value;
			if ($ruleHash->{value} eq 'defaultproductunittype' or $ruleHash->{value} eq 'defaultpackageunittype')
				{
				$ruleHash->{loop} = $c->stash->{'unittype_loop'};
				}
			elsif ($ruleHash->{value} eq 'returncapability' or $ruleHash->{value} eq 'dropshipcapability')
				{
				$ruleHash->{loop} = $c->stash->{'capability_loop'};
				}
			else
				{
				$ruleHash->{loop} = $c->stash->{$ruleHash->{value}.'_loop'};
				}
			}
		else
			{
			$ruleHash->{text} = $value;
			}
		}

	return $CONTACT_RULES;
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
