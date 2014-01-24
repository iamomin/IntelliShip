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
		$sql = "SELECT droplistdataid FROM droplistdata WHERE field = 'extid' and customerid = '" . $self->customer->customerid . "' ORDER BY fieldorder desc,fieldtext";
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
			address1    => $params->{'address1'},
			address2    => $params->{'address2'},
			city        => $params->{'city'},
			state       => $params->{'state'},
			zip         => $params->{'zip'},
			country     => $params->{'country'},
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

		$c->stash->{location}    = $Contact->get_contact_data_value('location');
		$c->stash->{ownerid}     = $Contact->get_contact_data_value('ownerid');
		$c->stash->{origdate}    = $Contact->get_contact_data_value('origdate');
		$c->stash->{sourcedate}  = $Contact->get_contact_data_value('sourcedate');
		$c->stash->{disabledate} = $Contact->get_contact_data_value('disabledate');

		$c->stash->{statelist_loop} = $self->get_select_list('US_STATES');
		$c->stash->{countrylist_loop} = $self->get_select_list('COUNTRY');

		$c->stash(template => "templates/customer/settings.tt");
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
