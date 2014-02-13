package IntelliShip::Controller::Customer::Settings::Company;
use Moose;
use Data::Dumper;
use IntelliShip::Utils;
use namespace::autoclean;

BEGIN { extends 'IntelliShip::Controller::Customer::Settings'; }

=head1 NAME

IntelliShip::Controller::Customer::Settings::Company - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    #$c->response->body('Matched IntelliShip::Controller::Customer::Settings::Company in Customer::Settings::Company.');

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

	$c->stash(template => "templates/customer/settings-company.tt");
}

sub setup :Local
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	my $Customer = $self->get_customer;
	if ($Customer)
		{
		#$c->log->debug("CUSTOMER DUMP: " . Dumper $Customer->{'_column_data'});
		$c->stash($Customer->{'_column_data'});
		$c->stash->{customerAddress} = $Customer->address;
		$c->stash->{customerAuxFormAddress} = $Customer->auxilary_address;
		$c->stash->{cust_defaulttoquickship} = 1 if ($Customer->quickship eq '2');


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

	$c->stash->{CONTACT_INFORMATION} = $c->forward($c->view('Ajax'), "render", [ "templates/customer/settings-company.tt" ]);
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
	$c->stash->{labeltype_loop}          = $self->get_select_list('LABEL_TYPE');
	$c->stash->{SETUP_CUSTOMER}          = 1;

	$c->stash->{CUSTOMER_MANAGEMENT} = 1;
	$c->stash->{template} = "templates/customer/settings-company.tt";
	}

sub configure :Local
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

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
		$Customer->quickship($params->{'cust_quickship'} ? '1' : '0');
		}
	elsif ( $params->{'cust_quickship'} && $params->{'cust_defaulttoquickship'} )
		{
		$Customer->quickship('2');
		}
	else
		{
		$Customer->quickship('0');
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

	$c->log->debug("___ Flush old custcondata for company: " . $Customer->customerid);
	$Customer->settings->delete;

	my $CUSTOMER_RULES = IntelliShip::Utils->get_rules('CUSTOMER');

	$c->log->debug("___ CUSTOMER_RULES record count " . @$CUSTOMER_RULES);

	my $customerContactSql = "INSERT INTO custcondata (custcondataid, ownertypeid, ownerid, datatypeid, datatypename, value) VALUES ";
	my $customerContactValues = [];
	foreach my $ruleHash (@$CUSTOMER_RULES)
		{
		next unless $params->{'cust_'.$ruleHash->{value}};
=as
		#$c->log->debug("___ Inserting New custcondata $ruleHash->{value} for company: " . $Customer->customerid);
		my $customerContactData = {
			ownertypeid	 => 1,
			ownerid		 => $Customer->customerid,
			datatypeid	 => $ruleHash->{datatypeid},
			datatypename => $ruleHash->{value},
			value		 => ($ruleHash->{type} eq 'CHECKBOX') ? 1 : $params->{'cust_'.$ruleHash->{value}},
			};

		my $NewCCData = $c->model("MyDBI::Custcondata")->new($customerContactData);
		$NewCCData->custcondataid($self->get_token_id);
		$NewCCData->insert;
=cut
		push (@$customerContactValues, "('".$self->get_token_id."', '1', '".$Customer->customerid."', '".$ruleHash->{datatypeid}."', '".$ruleHash->{value}."', '".($ruleHash->{type} eq 'CHECKBOX' ? 1 : $params->{'cust_'.$ruleHash->{value}})."')" );
		}

	if (@$customerContactValues)
		{
		$c->log->debug("..... Inserting New Customer Settings");
		my $SQL = $customerContactSql . join(' , ',@$customerContactValues);
		$c->log->debug("Customer Settings SQL: " . $SQL);
		$c->model("MyDBI")->dbh->do($SQL);
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

	if ($params->{'shipmentmarkup'} and $params->{'shipmentmarkuptype'})
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

	if ($Customer->customerid eq $self->customer->customerid)
		{
		$self->customer($Customer);
		}

	$c->stash->{MESSAGE} = $msg;
	$c->detach("index",$params);
	}

sub ajax :Local
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	$c->stash->{ajax} = 1;

	if ($params->{'customername'})
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
	elsif (length $params->{'term'})
		{
		my $sql = "SELECT customername FROM customer WHERE customername LIKE '%" . $params->{'term'} . "%' ORDER BY 1";
		my $sth = $c->model('MyDBI')->select($sql);

		my $arr = [];
		push(@$arr, $_->[0]) foreach @{$sth->query_data};

		return $c->response->body(IntelliShip::Utils->jsonify($arr));
		}
	elsif (length $params->{'contactid'})
		{
		$params->{'do'} = 'configure';
		$self->contactinformation;
		}
	elsif ($params->{'do'} eq 'cancel')
		{
		$self->get_customer_contacts;
		}

	$c->stash($params);
	$c->stash(template => "templates/customer/settings-company.tt");
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

sub get_company_setting_list :Private
	{
	my $self = shift;
	my $Customer = shift;
	my $c = $self->context;

	return unless $Customer;

	my $CUSTOMER_RULES = IntelliShip::Utils->get_rules('CUSTOMER');
	$c->log->debug("___ CUSTOMER_RULES record count " . @$CUSTOMER_RULES);

	my @Settings = $Customer->settings;
	my %customerRules = map { $_->datatypename => $_->value } @Settings;

	my $list = [];
	foreach my $ruleHash (@$CUSTOMER_RULES)
		{
		my $value = $customerRules{$ruleHash->{value}} || '';

		if($ruleHash->{type} eq 'CHECKBOX')
			{
			push(@$list, { name => $ruleHash->{name}, value => $ruleHash->{value}, checked => $value });
			}
		else
			{
			$c->stash->{'cust_'.$ruleHash->{value}} = $value;
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
