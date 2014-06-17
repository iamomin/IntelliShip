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

	my $customer_batches;
	my $WHERE = {};
	if ($params->{'customer_ids'})
		{
		$WHERE = { customerid => [split(',', $params->{'customer_ids'})] };
		}
	else
		{
		$customer_batches = $self->process_pagination('customermanagement');
		$WHERE->{customerid} = $customer_batches->[0] if $customer_batches;
		}
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
	$c->stash->{SUPER_USER} = $self->contact->is_superuser;

	if ($Customer)
		{
		$params->{'customerid'} = $Customer->customerid unless $params->{'customerid'};
		#$c->log->debug("CUSTOMER DUMP: " . Dumper $Customer->{'_column_data'});
		$c->stash($Customer->{'_column_data'});
		$c->stash->{customerAddress} = $Customer->address;
		$c->stash->{customerAuxFormAddress} = $Customer->auxilary_address;
		$c->stash->{cust_defaulttoquickship} = 1 if ($Customer->quickship eq '2');
		$c->stash->{SSO_CUSTOMER}            = 1 if $Customer->is_single_sign_on_customer;

		$self->get_branding_settings;
		$c->stash->{COMPANY_BRANDING_HTML} = $c->forward($c->view('Ajax'), "render", [ "templates/customer/settings-company-branding.tt" ]);

		my @shipmentmarkupdata =$c->model('MyArrs::RateData')->search({
			-and => [
			-or => [
				freightmarkupamt => { '!=' => undef },
				freightmarkuppercent  => { '!=' => undef },
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
		}
	else
		{
		if (length $params->{'customername'})
			{
			$c->stash->{MESSAGE} = 'Invalid customer name';
			$c->detach("index",$params);
			}
		}

	$c->stash->{password}                = $self->get_token_id unless $c->stash->{password};
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
	$c->stash->{printreturnshipment_loop}= $self->get_select_list('PRINT_RETURN_SHIPMENT');
	$c->stash->{labelstub_loop}          = $self->get_select_list('LABEL_STUB_LIST');
	$c->stash->{markuptype_loop}         = $self->get_select_list('MARKUP_TYPE');
	$c->stash->{labeltype_loop}          = $self->get_select_list('LABEL_TYPE');
	$c->stash->{jpgrotation_loop}        = $self->get_select_list('JPG_LABEL_ROTATION');
	$c->stash->{packageproductlevel_loop}= $self->get_select_list('PACKAGE_PRODUCT_LEVEL');

	$c->stash->{CURRENT_COMPANY} = ($params->{'customerid'} eq $self->customer->customerid);

	$c->stash->{SETUP_CUSTOMER} = 1;
	$c->stash->{CUSTOMER_MANAGEMENT} = 1;
	$c->stash->{template} = "templates/customer/settings-company.tt";
	}

sub configure :Local
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	my $Customer = $self->get_customer;
	unless ($Customer)
		{
		$Customer = $c->model('MyDBI::Customer')->new({});
		$Customer->createdby($self->customer->customerid);
		$Customer->datecreated(IntelliShip::DateUtils->get_timestamp_with_time_zone);
		}

	IntelliShip::Utils->trim_hash_ref_values($params);

	$Customer->halocustomerid($params->{'halocustomerid'}) if $params->{'halocustomerid'};
	$Customer->customername($params->{'customername'}) if $params->{'customername'};
	$Customer->username($params->{'username'}) if $params->{'username'};
	$Customer->contact($params->{'contact'}) if $params->{'contact'};
	$Customer->phone($params->{'phone'}) if $params->{'phone'};
	$Customer->email($params->{'email'}) if $params->{'email'};
	$Customer->fax($params->{'fax'}) if $params->{'fax'};
	$Customer->ssnein($params->{'ssnein'}) if $params->{'ssnein'};
	$Customer->password($params->{'password'}) if $params->{'password'};
	$Customer->labelbanner($params->{'labelbanner'}) if $params->{'labelbanner'} ;
	$Customer->labelport($params->{'cust_labelport'}) if $params->{'cust_labelport'};
	$Customer->defaultthermalcount($params->{'cust_defaultthermalcount'}) if $params->{'cust_defaultthermalcount'};
	$Customer->bolcount8_5x11($params->{'cust_bolcount8_5x11'}) if $params->{'cust_bolcount8_5x11'};
	$Customer->bolcountthermal($params->{'cust_bolcountthermal'}) if $params->{'cust_bolcountthermal'} ;
	$Customer->autoreporttime($params->{'cust_autoreporttime'}) if $params->{'cust_autoreporttime'} ;
	$Customer->autoreportemail($params->{'cust_autoreportemail'}) if $params->{'cust_autoreportemail'};
	$Customer->autoreportinterval($params->{'cust_autoreportinterval'}) if $params->{'cust_autoreportinterval'};
	$Customer->proxyip($params->{'cust_proxyip'}) if $params->{'cust_proxyip'} ;
	$Customer->proxyport($params->{'cust_proxyport'})  if $params->{'cust_proxyport'};
	$Customer->losspreventemail($params->{'cust_losspreventemail'})  if $params->{'cust_losspreventemail'};
	$Customer->losspreventemailordercreate($params->{'cust_losspreventemailordercreate'}) if $params->{'cust_losspreventemailordercreate'};
	$Customer->smartaddressbook($params->{'cust_smartaddressbook'}) if $params->{'cust_smartaddressbook'};
	$Customer->apiaosaddress($params->{'cust_apiaosaddress'}) if $params->{'cust_apiaosaddress'};
	$Customer->weighttype($params->{'weighttype'}) if $params->{'weighttype'};
	$Customer->createdby($params->{'createdby'}) if $params->{'createdby'};

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

	my $Address = $Customer->address if $Customer->addressid;
	unless ($Address)
		{
		my @address = $c->model('MyDBI::Address')->search($addressData);

		$Address = (@address ? $address[0] : $c->model('MyDBI::Address')->new($addressData));

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

	my $AuxilaryAddress = $Customer->auxilary_address if $Customer->auxformaddressid;
	unless ($AuxilaryAddress)
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

sub delete :Local
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;
	my $Customer = $self->get_customer;

	$Customer->delete;
	$c->stash->{MESSAGE} = "Customer deleted successfully";
	$c->detach("index",$params);
	}

sub ajax :Local
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	$c->stash->{ajax} = 1;

	if ($params->{'type'} eq 'HTML')
		{
		$self->get_HTML_DATA;
		}
	elsif ($params->{'type'} eq 'JSON')
		{
		$self->get_JSON_DATA;
		}

	$c->stash($params);
	}

sub get_HTML_DATA :Private
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	my $action = $params->{'action'} || '';

	if ($action eq 'get_customers')
		{
		$self->index($c);
		}
	elsif (length $params->{'contactid'})
		{
		$params->{'do'} = 'configure';
		$self->contactinformation;
		}
	elsif ($action eq 'get_customer_contacts')
		{
		$self->get_customer_contacts;
		}
	elsif ($action eq 'get_branding_settings')
		{
		$self->get_branding_settings;
		}

	$c->stash(template => "templates/customer/settings-company.tt") unless $c->stash->{template};
	}

sub get_JSON_DATA :Private
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	my $action = $params->{'action'} || '';
	my $dataHash;
	if ($action eq 'validate_contact_username')
		{
		$dataHash = $self->validate_contact_username;
		}
	elsif ($action eq 'validate_customer_username')
		{
		$dataHash = $self->validate_customer_username;
		}
	elsif ($action eq 'search_customer')
		{
		my $WHERE = "WHERE customername LIKE '%" . $params->{'term'} . "%' ";

		if ($self->contact->is_administrator && !$self->contact->is_superuser)
			{
			$WHERE .= "AND (createdby = '" . $self->customer->customerid ."' OR customerid = '".$self->customer->customerid."') ";
			}
		my $sql = "SELECT customername FROM customer $WHERE ORDER BY 1";
		my $sth = $c->model('MyDBI')->select($sql);
		my $arr = [];
		push(@$arr, $_->[0]) foreach @{$sth->query_data};
		return $c->response->body(IntelliShip::Utils->jsonify($arr));
		}
	elsif ($action eq 'update_branding_settings')
		{
		$dataHash = $self->update_branding_settings;
		}
	elsif ($action eq 'check_customer_contacts')
		{
		$dataHash = $self->check_customer_contacts;
		}

		#$c->log->debug("\n TO dataHash:  " . Dumper ($dataHash));
		my $json_DATA = IntelliShip::Utils->jsonify($dataHash);
		#$c->log->debug("\n TO json_DATA:  " . Dumper ($json_DATA));
		return $c->response->body($json_DATA);
	}

sub validate_contact_username :Private
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	my $WHERE = {
		contactid => { '!=' => $params->{'contactid'}},
		username => $params->{'username'}
		};

	return { COUNT => $c->model('MyDBI::Contact')->search($WHERE)->count };
	}

sub validate_customer_username :Private
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	my $WHERE = {
		customerid => { '!=' => $params->{'customerid'} },
		username => $params->{'username'}
		};

	return { COUNT => $c->model('MyDBI::Customer')->search($WHERE)->count };
   }

sub get_branding_settings :Private
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	$c->stash->{fontsize_loop} = $self->get_select_list('FONT_SIZE');

	my $customer_css = IntelliShip::MyConfig->branding_file_directory . '/' . $self->get_branding_id . '/css/' . $params->{'customerid'} . '.css';

	my $INPUT = new IO::File;

	my $BRANDING_CSS = '';
	if (open $INPUT, $customer_css)
		{
		$BRANDING_CSS .= $_ while <$INPUT>;
		close $INPUT;
		}
	else
		{
		$c->log->debug("Branding CSS not found '$customer_css'");
		}

	my $custom_styles;
	if ($BRANDING_CSS =~ /\/\*custom_css_start\*\/(.*?)\/\*custom_css_end\*\//s)
		{
		$custom_styles = $1;
		$c->log->debug("custom_styles: " . $custom_styles);
		}

	$c->stash->{stylesetting_loop} = $self->get_style_setting_list($custom_styles);

	# IDENTIFY AND CLEAR THE OLD CUSTOM CSS CLASSES.
	my $custom_css_start_line = "/*custom_css_start*/";
	my $custom_css_end_line = "/*custom_css_end*/";

	$custom_styles = $custom_css_start_line . $custom_styles . $custom_css_end_line;

	$BRANDING_CSS =~ s/\Q$custom_styles\E//g;

	$c->stash->{BRANDING_CSS} = $BRANDING_CSS;
	$c->stash->{BASE_URL} = $c->request->base;
	$c->stash(template => "templates/customer/settings-company-branding.tt");
	}

sub get_style_setting_list
	{
	my $self = shift;
	my $CUSTOM_STYLE_DATA = shift;
	my $c = $self->context;

	my $CUSTOM_CSS_RULES = IntelliShip::Utils->get_custome_css_style_hash;
	my $css_contents;

	foreach my $style (@$CUSTOM_CSS_RULES)
		{
		if ($CUSTOM_STYLE_DATA =~ /$style->{section}[0]\{(.*?)\}/s) {
			$css_contents = $1;
			$css_contents =~ s/\n\t\s*//g; # Remove new line character, tabs and spaces
			$c->log->debug("css_contents:" . $css_contents);
			my $values = {};
			foreach my $element (split(';', $css_contents))
				{
				my @attribute_arr = split(/:/, $element);
				if ($attribute_arr[0] eq 'background')
					{
					$values->{bgcolor} = $attribute_arr[1];
					$values->{bgcolor} =~ s/\ *#//;
					}
				elsif ($attribute_arr[0] eq 'color')
					{
					$values->{color} = $attribute_arr[1];
					$values->{color} =~ s/\ *#//;
					}
				elsif ($attribute_arr[0] eq 'font-size')
					{
					$values->{size} = $attribute_arr[1];
					$values->{size} =~ s/\s*px//;
					$values->{size} =~ s/^\s+//;
					}
				}
			$style->{values} = $values;
			}
		}

	#$c->log->debug("CUSTOM_CSS_STYLES: " . Dumper @$CUSTOM_CSS_RULES);

	return $CUSTOM_CSS_RULES;
	}

sub update_branding_settings :Private
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;
	my $Customer = $self->get_customer;

	my $CSS_CONTENT = $params->{'custom-style-sheet'};
	my $CustomerCss  = IntelliShip::MyConfig->branding_file_directory . '/' . $self->get_branding_id . '/css/' . $params->{'customerid'} . '.css';

	my $FILE = new IO::File;
	unless (open ($FILE,">$CustomerCss"))
		{
		return { SUCCESS => 0, error => "Unable to open branding css" };
		}

	print $FILE $CSS_CONTENT;

	print $FILE "\n/*custom_css_start*/\n";

	my $css_contents;
	my $CUSTOM_CSS_RULES = IntelliShip::Utils->get_custome_css_style_hash;
	foreach my $style_list (@$CUSTOM_CSS_RULES)
		{
		foreach my $style (@{ $style_list->{section }})
			{
			$css_contents = $style . "{";
			$css_contents .= "$_\n" . "\tbackground: " . $params->{"$style_list->{bgcolor}"} . ";" if $params->{"$style_list->{bgcolor}"};
			$css_contents .= "$_\n" . "\tcolor: " . $params->{"$style_list->{font}"} . ";" if $params->{"$style_list->{font}"};
			$css_contents .= "$_\n" . "\tfont-size: " . $params->{"$style_list->{size}"} . "px;" if $params->{"$style_list->{size}"};
			if($style eq 'input[type=button].active')
				{
				$css_contents .= "$_\n" . "\tborder-color: " . $params->{"$style_list->{bgcolor}"} . ";" if $params->{"$style_list->{bgcolor}"};
				}

			unless ($css_contents eq $style . "{")
				{
				$css_contents .= "$_\n" . "}$_\n\n";
				print $FILE $css_contents ;
				$css_contents = '';
				}
			}
		}

	print $FILE "\n/*custom_css_end*/\n";
	close $FILE;

	return { SUCCESS => 1, MESSAGE => "Updated successfully..." };
	}

sub check_customer_contacts
	{
	my $self = shift;
	my $c = $self->context;
	my $Customer = $self->get_customer;

	my $sql = "SELECT contactid FROM contact WHERE customerid = '" . $Customer->customerid ."' ORDER BY username";
	my $sth = $c->model('MyDBI')->select($sql);
	if($sth->numrows)
		{
		$c->log->debug("___ CONTACTS FOUND: ");
		return { CONTACTS => $sth->numrows, MESSAGE => "Please delete all contacts and try agian" };
		}
	else
		{
		#$c->log->debug("___ Flush old custcondata for company: " . $Customer->customerid);
		#$Customer->settings->delete;
		return { CONTACTS => 0};
		}
	}
	
sub brandingdemo :Local
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	$c->stash->{NO_CACHE} = 1;
	$c->stash->{BRANDING_DEMO_CSS} = $params->{'id'};

	my $CO = IntelliShip::Controller::Customer::Order->new;
	$CO->context($c);
	$CO->contact($self->contact);
	$CO->customer($self->contact->customer);
	$CO->quickship;

	$self->customer($c->model('MyDBI::Customer')->find({ customerid => $params->{'id'} }));

	$c->stash(template => "templates/customer/order-one-page-v1.tt");
	}

sub upload :Local
	{
	my $self = shift;

	my $c = $self->context;
	my $params = $c->req->params;

	my $Customer = $self->get_customer;
	unless ($Customer)
		{
		$c->log->debug("Customer not found");
		return;
		}

	my $Upload = $c->request->upload('Filedata');
	unless ($Upload)
		{
		$c->log->debug("File to be uploaded is not provided");
		return;
		}

	my $FILE_name = $Customer->username . '-' . $params->{'type'} . '-logo.png';
	my $FullPath  = IntelliShip::MyConfig->branding_file_directory . '/' . $self->get_branding_id . '/images/header/' . $FILE_name;
	$c->log->debug("FILE_name: " . $FILE_name . ", Full Path: " . $FullPath);

	if ($Upload->copy_to($FullPath))
		{
		$c->log->debug("File Upload Path, " . $FullPath);
		}
	}

sub get_customer
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	my $WHERE = {};
	if ($params->{'customerid'})
		{
		$WHERE->{customerid} = $params->{'customerid'};
		}
	elsif ($params->{'customername'})
		{
		$WHERE->{customername} = $params->{'customername'};
		if ($self->contact->is_administrator && !$self->contact->is_superuser)
			{
			$WHERE->{-and} = [{createdby => $self->customer->customerid}, {-or => {[customerid => $self->customer->customerid]}}];
			my @customer =  $c->model('MyDBI::Customer')->search(
				-and => [
				-or => [
					createdby => $self->customer->customerid,
					customerid => $self->customer->customerid,
					],
				customername => $params->{'customername'},
				]);

			return (@customer ? $customer[0] : undef);
			}
		}

	return undef unless scalar keys %$WHERE;
	return $c->model('MyDBI::Customer')->find($WHERE);
	}

sub get_company_setting_list :Private
	{
	my $self = shift;
	my $Customer = shift;
	my $c = $self->context;

	my $CUSTOMER_RULES = IntelliShip::Utils->get_rules('CUSTOMER');

	$CUSTOMER_RULES = [sort { uc($a->{'name'}) cmp uc($b->{'name'}) } @$CUSTOMER_RULES];

	$c->log->debug("___ CUSTOMER_RULES record count " . @$CUSTOMER_RULES);

	my @Settings;
	if ($Customer)
		{
		@Settings = $Customer->settings ;
		$c->stash->{SHOW_CREATEDBY} = ($self->contact->is_superuser && $Customer->customerid != $self->customer->customerid);
		}
	my %customerRules = map { $_->datatypename => $_->value } @Settings;

	my $list = [];
	foreach my $ruleHash (@$CUSTOMER_RULES)
		{
		my $value = $customerRules{$ruleHash->{value}} || '';

		$value = $ruleHash->{default} if (!$value and defined $ruleHash->{default});
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
