package IntelliShip::Controller::Customer::Order;
use Moose;
use IO::File;
use Data::Dumper;
use POSIX qw(ceil);
use IntelliShip::Email;
use IntelliShip::Utils;
use IntelliShip::MyConfig;
use IntelliShip::Carrier::Handler;
use IntelliShip::Carrier::Constants;
use namespace::autoclean;

BEGIN { extends 'IntelliShip::Controller::Customer'; }

sub onepage :Local
	{
	my $self = shift;
	my $c = $self->context;

	my $do_value = $c->req->param('do') || '';
	if ($do_value eq 'save')
		{
		$self->save_new_order;
		}
	elsif ($do_value eq 'cancel')
		{
		$self->cancel_order;
		}
	else
		{
		$self->setup_one_page;
		}
	}

sub quickship :Local
	{
	my $self = shift;
	my $c = $self->context;

	my $do_value = $c->req->param('do') || '';
	if ($do_value eq 'save')
		{
		$self->save_new_order;
		}
	elsif ($do_value eq 'print')
		{
		$self->setup_label_to_print;
		}
	elsif ($do_value eq 'cancel')
		{
		$self->cancel_order;
		$self->setup_one_page;
		}
	else
		{
		$c->stash->{quickship} = 1;
		$self->setup_one_page;
		}
	}

sub _setup_one_page :Private
	{
	my $self = shift;
	my $c = $self->context;

	my $CO = $self->get_order;

	if ($self->order_can_auto_process)
		{
		$c->log->debug("Auto Shipping Order, ID: " . $CO->coid);
		$self->SHIP_ORDER;
		return $self->display_error_details($self->errors->[0]) if $self->has_errors;
		return $self->setup_label_to_print;
		}

	$c->stash->{one_page} = 1;

	#DYNAMIC FIELD VALIDATIONS
	$self->set_required_fields;

	$self->setup_address;
	$self->setup_shipment_information;
	$self->setup_carrier_service;

	$c->stash(template => "templates/customer/order-one-page.tt");
	}

sub setup_one_page :Private
	{
	my $self = shift;
	my $c = $self->context;

	my $CO = $self->get_order;

	if ($self->order_can_auto_process)
		{
		$c->log->debug("Auto Shipping Order, ID: " . $CO->coid);
		$self->SHIP_ORDER;
		return $self->display_error_details($self->errors->[0]) if $self->has_errors;
		return $self->setup_label_to_print;
		}

	$c->stash->{one_page} = 1;

	#DYNAMIC FIELD VALIDATIONS
	$self->set_required_fields;

	$self->setup_address;;
	$self->setup_shipment_information;
	$self->setup_carrier_service;
	$c->stash->{ROUTE_CAPTION} = ($self->customer->is_single_sign_on_customer and $self->customer->get_contact_data_value('routebuttonname')) ? uc($self->customer->get_contact_data_value('routebuttonname')) : 'ROUTE NOW';
	$c->stash(template => "templates/customer/order-one-page-v1.tt");
	}

sub order_can_auto_process
	{
	my $self = shift;

	my $c      = $self->context;
	my $params = $c->req->params;
	my $CO     = $self->get_order;

	return if $CO->statusid == 200; ## Not Void Status
	return ($CO->can_autoship and !$params->{'force_edit'} and ($c->stash->{AUTO_PROCESS} == 1 or $self->customer->get_contact_data_value('autoprocess')));
	}

sub setup_address :Private
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	my $Contact = $self->contact;
	my $Customer = $self->customer;

	my $CO = $self->get_order;

	my $do = $params->{'do'} || '';
	if (!$do or $do eq 'address')
		{
		$c->stash->{populate} = 'address';
		$self->populate_order;
		}

	$c->stash->{fromAddress} = $Contact->address unless $c->stash->{fromAddress};
	$c->stash->{fromAddress} = $Customer->address unless $c->stash->{fromAddress};

	$self->set_company_address;

	$c->stash->{AMDELIVERY} = 1 if $Customer->amdelivery;
	$c->stash->{ordernumber} = ($params->{'ordernumber'} ? $params->{'ordernumber'} : $CO->ordernumber) unless $c->stash->{ordernumber};
	$c->stash->{customerlist_loop} = $self->get_select_list('ADDRESS_BOOK_CUSTOMERS');
	$c->stash->{countrylist_loop} = $self->get_select_list('COUNTRY');

	my $country = ($CO->to_address ? $CO->to_address->country : 'US');
	$c->stash->{statelist_loop} = $self->get_select_list('STATE', { country => $country }) if $country eq 'US';

	if ($c->stash->{one_page})
		{
		$c->stash->{deliverymethod} = '0';
		$c->stash->{deliverymethod_loop} = $self->get_select_list('DELIVERY_METHOD') ;
		$c->stash->{shipmenttype_loop} = $self->get_shipment_types;
		$c->stash->{CONSOLIDATE_COMBINE} = $Customer->get_contact_data_value('consolidatecombine');
		}

	#$c->stash->{tooltips} = $self->get_tooltips;

	#DYNAMIC INPUT FIELDS VISIBILITY
	unless ($Contact->login_level == 25)
		{
		$c->stash->{SHOW_PONUMBER} = $Customer->get_contact_data_value('reqponum');
		$c->stash->{SHOW_EXTID}    = $Customer->get_contact_data_value('reqextid');
		$c->stash->{SHOW_CUSTREF2} = $Customer->get_contact_data_value('reqcustref2');
		$c->stash->{SHOW_CUSTREF3} = $Customer->get_contact_data_value('reqcustref3');
		}

	#DYNAMIC FIELD VALIDATIONS
	$self->set_required_fields('address');

	$c->stash->{tocountry}  = "US" unless $c->stash->{toAddress};
	$c->stash->{fromemail}  = $Contact->email unless $c->stash->{fromemail};
	$c->stash->{fromdepartment} = $Contact->department unless $c->stash->{fromdepartment};
	$c->stash->{fromcontact}= $Contact->full_name unless $c->stash->{fromcontact};
	$c->stash->{fromphone}  = $Contact->phonebusiness unless $c->stash->{fromphone};

	if ($c->action =~ /multipage/)
		{
		$c->stash(template => "templates/customer/order-address.tt");
		}
	else
		{
		$c->stash(ADDRESS_SECTION => $c->forward($c->view('Ajax'), "render", [ "templates/customer/order-address.tt" ]));
		}
	}

sub setup_shipment_information :Private
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	$c->stash->{packageunittype_loop} = $self->get_select_list('UNIT_TYPE');

	my $CO = $self->get_order;
	my $Contact = $self->contact;
	my $Customer = $self->customer;

	my $do = $c->req->param('do') || '';
	if (!$do or $do eq 'shipment' or $do eq 'step1')
		{
		$c->stash->{populate} = 'shipment';
		$self->populate_order;
		}

	$c->stash->{SPECIAL_SERVICE} = $self->get_special_services if $Contact->get_contact_data_value('specialserviceexpanded') and !$c->stash->{SPECIAL_SERVICE};

	unless ($c->stash->{one_page})
		{
		$c->stash->{deliverymethod} = '0';
		$c->stash->{deliverymethod_loop} = $self->get_select_list('DELIVERY_METHOD');

		if ($Customer->address->country ne $CO->to_address->country)
			{
			$c->log->debug("... customer address and drop address not same, INTERNATIONAL shipment");
			my $CA = IntelliShip::Controller::Customer::Order::Ajax->new;
			$CA->context($c);
			$CA->contact($self->contact);
			$CA->set_international_details;
			$c->stash->{INTERNATIONAL_AND_COMMODITY} = $c->forward($c->view('Ajax'), "render", [ "templates/customer/order-ajax.tt" ]);
			$c->stash->{INTERNATIONAL} = 0;
			}
		}

	$c->stash->{default_packing_list} = $Contact->default_packing_list;
	$c->stash->{print_return_shipment} = $Contact->print_return_shipment unless $CO->ordernumber =~ /\-RTN$/;

	if (my $unit_type_id = $Contact->default_package_type)
		{
		$c->stash->{default_package_type} = $unit_type_id;
		$c->stash->{unittypeid} = $unit_type_id unless $c->stash->{unittypeid}; ## Only for multipage order
		my $UnitType = $c->model('MyDBI::UnitType')->find({ unittypeid => $unit_type_id });
		$c->stash->{default_package_type_text} = uc $UnitType->unittypename if $UnitType;
		}

	#DYNAMIC FIELD VALIDATIONS
	$self->set_required_fields('shipment');

	#$c->stash->{tooltips} = $self->get_tooltips;

	if ($c->action =~ /multipage/)
		{
		$c->stash(template => "templates/customer/order-shipment.tt");
		}
	else
		{
		unless ($c->stash->{PACKAGE_DETAIL_SECTION})
			{
			$c->stash->{HIDE_PRODUCT} = 1 if $Contact->get_contact_data_value('packageproductlevel') == 2;
			$c->log->debug("... setup new package shipment details");
			$params->{'unittypeid'} = $c->stash->{default_package_type};
			$params->{'detail_type'} = 'package';
			my $CA = IntelliShip::Controller::Customer::Order::Ajax->new;
			$CA->context($c);
			$CA->contact($self->contact);
			my $data = $CA->add_package_product_row;
			$c->stash->{PACKAGE_DETAIL_SECTION} = $data->{rowHTML};
			}
		}

	$c->stash->{WEIGHT_TYPE} = $Customer->weighttype || 'LBS';
	$c->stash->{quantityxweight} = $Contact->get_contact_data_value('auto_select_quantity_x_weight');
	}

sub setup_carrier_service :Private
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	my $Customer = $self->customer;
	my $Contact  = $self->contact;
	my $CO       = $self->get_order;

	$c->stash->{review_order} = 1;
	$c->stash->{customer} = $Contact;

	my $do = $params->{'do'} || '';
	if (!$do or $do =~ /(summary|review|step2)/)
		{
		$c->stash->{populate} = 'summary';
		$self->populate_order;
		}

	if ($Contact->is_administrator and $Contact->login_level != 10 and $Contact->login_level != 20 and $Contact->login_level != 15)
		{
		$c->stash->{SHOW_NEW_OTHER_CARRIER} = 1;
		}

	my $populate_carrier_service = 0;
	if ($do =~ /(step2|review)/)
		{
		$populate_carrier_service = 1 unless $params->{'skiproute'};
		}
	elsif ($CO->has_carrier_service_details)
		{
		$populate_carrier_service = 1;
		}

	if ($populate_carrier_service)
		{
		$c->log->debug("CO has carrier service details, populate details...");

		my $CA = IntelliShip::Controller::Customer::Order::Ajax->new;
		$CA->customer($Customer);
		$CA->contact($Contact);
		$CA->context($c);
		$CA->{SKIP_SAVE_ORDER} = 1;
		$CA->get_carrier_service_list;
		$CA->{SKIP_SAVE_ORDER} = 0;

		$c->stash->{SERVICE_LEVEL_SUMMARY} = $c->forward($c->view('Ajax'), "render", [ "templates/customer/order-ajax.tt" ]);
		#$c->log->debug("SERVICE_LEVEL_SUMMARY, HTML: " . $c->stash->{SERVICE_LEVEL_SUMMARY});
		}

	#$c->stash->{tooltips} = $self->get_tooltips;

	if ($c->action =~ /multipage/)
		{
		$c->stash(template => "templates/customer/order-carrier-service.tt");
		}
	else
		{
		$c->stash(CARRIER_SERVICE_SECTION => $c->forward($c->view('Ajax'), "render", [ "templates/customer/order-carrier-service.tt" ]));
		}
	}

sub get_shipment_types
	{
	my $self = shift;
	my $Contact = $self->contact;

	return unless $self->context->stash->{quickship};

	my $returncapability = $Contact->get_contact_data_value('returncapability');
	my $dropshipcapability = $Contact->get_contact_data_value('dropshipcapability');

	my $CO = $self->get_order;
	my $is_outbound = (!$CO->isinbound and !$CO->isdropship);

	my $shipmenttype_loop = [];
	if ($returncapability == 1 || $returncapability == 3 || $CO->ordernumber =~ /\-RTN$/)
		{
		push(@$shipmenttype_loop, { name => 'Inbound',  value => 'inbound', checked => $CO->isinbound });
		}
	if ($dropshipcapability == 1 || $dropshipcapability == 3)
		{
		push(@$shipmenttype_loop, { name => 'Dropship', value => 'dropship', checked => $CO->isdropship });
		}

	push @$shipmenttype_loop, { name => 'Outbound', value => 'outbound', checked =>  $is_outbound } if @$shipmenttype_loop;

	return $shipmenttype_loop;
	}

sub save_order :Private
	{
	my $self = shift;

	return if $self->{SKIP_SAVE_ORDER};

	## SAVE CO DETAILS
	$self->save_CO_details;

	## SAVE ADDRESS DETAILS
	$self->save_address;

	## SAVE PACKAGE & PRODUCT DETAILS
	$self->save_package_product_details;

	## SAVE SPECIAL SERVICES
	$self->save_special_services;
	}

sub save_CO_details :Private
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	$c->log->debug("... SAVE CO DETAILS");

	IntelliShip::Utils->hash_decode($params);

	my $CO = $self->get_order;

	my $coData = { keep => '0' };

	##########################################################
	##  FLUSH OLD DETAILS IF ANY FOR MATCHING ORDERNUMBER   ##
	##########################################################
	if ($params->{'ordernumber'})
		{
		if (my @DuplicateCOs = $c->model('MyDBI::CO')->search({ ordernumber => $params->{'ordernumber'}, coid => { '!=' => $CO->coid} }))
			{
			$c->log->debug("*** ".@DuplicateCOs." DUPLICATE order found for order number '$params->{'ordernumber'}', delete old details...");
			foreach my $DuplicateCO (@DuplicateCOs)
				{
				$DuplicateCO->delete_all_package_details;
				$DuplicateCO->delete;
				}
			}
		}

	$coData->{'return'}  = $params->{'printreturnshipment'} || '';
	$coData->{'isinbound'}  = ($params->{'shipmenttype'} && $params->{'shipmenttype'} eq 'inbound') || 0;
	$coData->{'isdropship'} = ($params->{'shipmenttype'} && $params->{'shipmenttype'} eq 'dropship') || 0;
	$coData->{'combine'} = $params->{'combine'} if $params->{'combine'};
	$coData->{'ordernumber'} = $params->{'ordernumber'} if $params->{'ordernumber'};
	$coData->{'department'} = $coData->{'isinbound'} ? $params->{'todepartment'} : $params->{'fromdepartment'};
	$coData->{'deliverynotification'} = $params->{'fromemail'} if $params->{'fromemail'};
	$coData->{'oacontactname'}  = $params->{'fromcontact'} if $params->{'fromcontact'};
	$coData->{'oacontactphone'} = $params->{'fromphone'} if $params->{'fromphone'};
	$coData->{'datetoship'} = IntelliShip::DateUtils->get_db_format_date_time($params->{'datetoship'}) if $params->{'datetoship'};
	$coData->{'dateneeded'} = IntelliShip::DateUtils->get_db_format_date_time($params->{'dateneeded'}) if $params->{'dateneeded'};

	$coData->{'ponumber'} = $params->{'ponumber'} if $params->{'ponumber'};
	$coData->{'extid'} = $params->{'extid'} if $params->{'extid'};
	$coData->{'custref2'} = $params->{'custref2'} if $params->{'custref2'};
	$coData->{'custref3'} = $params->{'custref3'} if $params->{'custref3'};
	$coData->{'description'} = $params->{'description'} if $params->{'description'};
	$coData->{'extcd'} = $params->{'description_1'} if $params->{'description_1'};
	$coData->{'extloginid'} = $self->customer->username;
	$coData->{'contactname'} = $params->{'tocontact'} if $params->{'tocontact'};

	if ($params->{'tophone'})
		{
		$params->{'tophone'} =~ s/\D//g;
		$coData->{'contactphone'} = $params->{'tophone'};
		}

	$coData->{'freightcharges'} = $params->{'deliverymethod'} if $params->{'deliverymethod'};

	$coData->{'shipmentnotification'} = $params->{'toemail'} if $params->{'toemail'};

	$coData->{'custnum'} = $coData->{'isinbound'} ? $params->{'fromcustomernumber'} : $params->{'tocustomernumber'};

	$coData->{'cotypeid'} = ($params->{'action'} and $params->{'action'} eq 'clearquote') ? 10 : 1;

	if ($self->contact->login_level =~ /(35|40)/ and $params->{'cotypeid'} and $params->{'cotypeid'} == 2)
		{
		$coData->{'cotypeid'} = 2;
		}

	$coData->{'estimatedweight'} = $params->{'totalweight'};
	$coData->{'density'} = $params->{'density_1'} || 0.00;
	$coData->{'volume'} = $params->{'volume'};
	$coData->{'class'} = $params->{'class_1'};

	# Sort out volume/density/class issues - if we have volume (and of course weight), and nothing
	# else, calculate density.  If we have density and no class, get class.
	# Volume assumed to be in cubic feet - density would of course be #/cubic foot
	if ($coData->{'estimatedweight'} and $coData->{'volume'} and !$coData->{'density'} )
		{
		$coData->{'density'} = int($coData->{'estimatedweight'} / $coData->{'volume'});
		}

	if ($coData->{'density'} and !$coData->{'class'})
		{
		$coData->{'class'} = IntelliShip::Utils->get_freight_class_from_density($coData->{'estimatedweight'}, undef, undef, undef, $coData->{'density'});
		}

	$coData->{'consolidationtype'} = ($params->{'consolidationtype'} ? $params->{'consolidationtype'} : 0);

	## If this order has non-voided shipments, keep it's status as 'shipped' (statusid = 5)
	if ($CO->shipment_count > 0)
		{
		$coData->{'statusid'} = 5;
		}

	$coData->{'extcarrier'} = $params->{'carrier'} if $params->{'carrier'};

	if ($params->{'customerserviceid'})
		{
		if ($params->{'customerserviceid'} =~ /^OTHER_(\w{13})/)
			{
			## Sort out 'Other' carrier nonsense
			my $Other = $c->model('MyDBI::Other')->find({ customerid => $self->customer->customerid, otherid => $1 });
			$coData->{'extcarrier'} = 'Other - ' . $Other->othername if $Other;
			}
		else
			{
			my ($CarrierName,$ServiceName) = $self->API->get_carrier_service_name($params->{'customerserviceid'});
			$coData->{'extcarrier'} = $CarrierName if !$coData->{'extcarrier'} and $CarrierName;
			$coData->{'extservice'} = $ServiceName if $ServiceName;
			$c->log->debug("... CarrierName: $CarrierName,  ServiceName: $ServiceName");
			}
		}

	$coData->{'dimlength'} = $params->{'dimlength_1'} if $params->{'dimlength_1'};
	$coData->{'dimwidth'} = $params->{'dimwidth_1'} if $params->{'dimwidth_1'};
	$coData->{'dimheight'} = $params->{'dimheight_1'} if $params->{'dimheight_1'};
	$coData->{'estimatedinsurance'} = $params->{'insurance'};

	## International
	$coData->{'termsofsale'} = $params->{'termsofsale'} if $params->{'termsofsale'};
	$coData->{'dutyaccount'} = $params->{'dutyaccount'} if $params->{'dutyaccount'};
	$coData->{'manufacturecountry'} = $params->{'manufacturecountry'} if$params->{'manufacturecountry'} ;
	$coData->{'dutypaytype'} = $params->{'dutypaytype'} if $params->{'dutypaytype'} ;
	$coData->{'destinationcountry'} = $params->{'destinationcountry'} if $params->{'destinationcountry'} ;

	$coData->{'partiestotransaction'} = $params->{'partiestotransaction'} if $params->{'partiestotransaction'};

	## Commidity
	$coData->{'commodityquantity'} = $params->{'commodityquantity'} if $params->{'commodityquantity'};
	$coData->{'commodityunits'} = $params->{'commodityunits'} if $params->{'commodityunits'} ;
	$coData->{'commoditycustomsvalue'} = $params->{'commoditycustomsvalue'} if $params->{'commoditycustomsvalue'};
	$coData->{'commodityunitvalue'} = $params->{'commodityunitvalue'} if $params->{'commodityunitvalue'};
	$coData->{'currencytype'} = $params->{'currencytype'} if $params->{'currencytype'};

	$CO->update($coData);
	}

sub save_address :Private
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	IntelliShip::Utils->hash_decode($params);

	$c->log->debug("... save address details");

	my $CO = $self->get_order;

	my $update_co=0;

	## Configure Origin Address
	if (defined $params->{'fromaddress1'})
		{
		my $originAddressData = {
			addressname => $params->{'fromname'},
			address1    => $params->{'fromaddress1'},
			address2    => $params->{'fromaddress2'},
			city        => $params->{'fromcity'},
			state       => $params->{'fromstate'},
			zip         => $params->{'fromzip'},
			country     => $params->{'fromcountry'},
			};

		IntelliShip::Utils->trim_hash_ref_values($originAddressData);

		## Fetch origin address
		my @addresses = $c->model('MyDBI::Address')->search($originAddressData);

		my $OriginAddress;
		if (@addresses)
			{
			$OriginAddress = $addresses[0];
			$c->log->debug("Existing Address Found, ID: " . $OriginAddress->addressid);
			}
		else
			{
			$OriginAddress = $c->model("MyDBI::Address")->new($originAddressData);
			$OriginAddress->addressid($self->get_token_id);
			$OriginAddress->insert;
			$c->log->debug("New Address Inserted, ID: " . $OriginAddress->addressid);
			}

		$CO->oaaddressid($OriginAddress->id);
		$update_co=1;

		if (defined($params->{'shipmenttype'}) && $params->{'shipmenttype'} eq 'dropship')
			{
			$CO->dropaddressid($OriginAddress->id);
			}
		}

	## Configure Destination Address
	if (defined $params->{'toaddress1'})
		{
		my $toAddressData = {
				addressname => $params->{'toname'},
				address1    => $params->{'toaddress1'},
				address2    => $params->{'toaddress2'},
				city        => $params->{'tocity'},
				state       => $params->{'tostate'},
				zip         => $params->{'tozip'},
				country     => $params->{'tocountry'},
				};

		IntelliShip::Utils->trim_hash_ref_values($toAddressData);

		$c->log->debug("checking for dropship address availability");

		## Fetch ship from address
		my @addresses = $c->model('MyDBI::Address')->search($toAddressData);

		my $ToAddress;
		if (@addresses)
			{
			$ToAddress = $addresses[0];
			$c->log->debug("Existing Address Found, ID: " . $ToAddress->addressid);
			}
		else
			{
			$ToAddress = $c->model("MyDBI::Address")->new($toAddressData);
			$ToAddress->addressid($self->get_token_id);
			$ToAddress->insert;
			$c->log->debug("New Address Inserted, ID: " . $ToAddress->addressid);
			}

		$CO->addressid($ToAddress->id);
		$update_co=1;
		}

	## Configure Route To Address
	if (defined $params->{'rtaddress1'})
		{
		$c->log->debug("checking for return address availability");

		my $returnAddressData = {
			addressname => $params->{'rtname'},
			address1    => $params->{'rtaddress1'},
			address2    => $params->{'rtaddress2'},
			city        => $params->{'rtcity'},
			state       => $params->{'rtstate'},
			zip         => $params->{'rtzip'},
			country     => $params->{'rtcountry'},
			};

		IntelliShip::Utils->trim_hash_ref_values($returnAddressData);

		## Fetch return address
		my @addresses = $c->model('MyDBI::Address')->search($returnAddressData);

		my $ReturnAddress;
		if (@addresses)
			{
			$ReturnAddress = $addresses[0];
			$c->log->debug("Existing Address Found, ID: " . $ReturnAddress->addressid);
			}
		else
			{
			$ReturnAddress = $c->model("MyDBI::Address")->new($returnAddressData);
			$ReturnAddress->addressid($self->get_token_id);
			$ReturnAddress->insert;
			$c->log->debug("New Address Inserted, ID: " . $ReturnAddress->addressid);
			}

		$CO->rtaddressid($ReturnAddress->id);
		$update_co=1;
		}

	$CO->update if $update_co;
	}

sub save_third_party_details
	{
	my $self = shift;
	my $c = $self->context;

	my $CO = $self->get_order;
	my $Customer = $CO->customer;
	my $params = $c->req->params;

	unless ($params->{'tpacctnumber'} or $params->{'tpaddress1'})
		{
		$c->log->debug("UNABLE TO STORE THIRD PARTY INFO, no tpacctnumber/tpaddress1 found");
		return;
		}

	$c->log->debug("SAVE_THIRD_PARTY_INFO, account number: " . $params->{'tpacctnumber'});

	my $thirdPartyAcctData = {};
	$thirdPartyAcctData->{'tpacctnumber'}  = $params->{'tpacctnumber'} if $params->{'tpacctnumber'};
	$thirdPartyAcctData->{'tpcompanyname'} = $params->{'tpcompanyname'} if $params->{'tpcompanyname'};
	$thirdPartyAcctData->{'tpaddress1'}    = $params->{'tpaddress1'} if $params->{'tpaddress1'};
	$thirdPartyAcctData->{'tpaddress2'}    = $params->{'tpaddress2'} if $params->{'tpaddress2'};
	$thirdPartyAcctData->{'tpcity'}        = $params->{'tpcity'} if $params->{'tpcity'};
	$thirdPartyAcctData->{'tpstate'}       = $params->{'tpstate'} if $params->{'tpstate'};
	$thirdPartyAcctData->{'tpzip'}         = $params->{'tpzip'} if $params->{'tpzip'};
	$thirdPartyAcctData->{'tpcountry'}     = $params->{'tpcountry'} if $params->{'tpcountry'};

	IntelliShip::Utils->trim_hash_ref_values($thirdPartyAcctData);

	my $Thirdpartyacct = $c->model('MyDBI::Thirdpartyacct')->find({ thirdpartyacctid => $params->{tpaccid} }) if $params->{tpaccid};
	$Thirdpartyacct = $c->model('MyDBI::Thirdpartyacct')->find({ thirdpartyacctid => $params->{thirdpartyacctid} }) if !$Thirdpartyacct and $params->{thirdpartyacctid};
	$Thirdpartyacct = $Customer->third_party_account($params->{'tpacctnumber'}) unless $Thirdpartyacct;
	unless ($Thirdpartyacct)
		{
		$thirdPartyAcctData->{'customerid'} = $Customer->customerid;
		$Thirdpartyacct = $c->model("MyDBI::Thirdpartyacct")->new($thirdPartyAcctData);
		}

	if ($Thirdpartyacct->thirdpartyacctid)
		{
		$Thirdpartyacct->update($thirdPartyAcctData);
		$c->log->debug("Existing third party info found, thirdpartyacctid: " . $Thirdpartyacct->thirdpartyacctid);
		}
	else
		{
		$Thirdpartyacct->thirdpartyacctid($self->get_token_id);
		$Thirdpartyacct->insert;
		$c->log->debug("New Thirdpartyacct Inserted, ID: " . $Thirdpartyacct->thirdpartyacctid);
		}

	$CO->tpacctnumber($Thirdpartyacct->tpacctnumber);
	$CO->freightcharges(2); # Third party
	$CO->update;
	}

sub get_row_id :Private
	{
	my $self = shift;
	my $index = shift;

	my $params = $self->context->req->params;

	foreach (keys %$params)
		{
		return $1 if $_ =~ m/^rownum_id_(\d+)$/ and $params->{$_} == $index;
		}
	}

sub save_package_product_details :Private
	{
	my $self = shift;

	my $c = $self->context;
	my $params = $c->req->params;

	$c->log->debug("... save package product details");

	my $total_row_count = int $params->{'pkg_detail_row_count'};

	$c->log->debug("... Total Row Count: " . $total_row_count);

	unless ($total_row_count)
		{
		$c->log->debug("... package/product row count not found in request");
		return;
		}

	my $CO = $self->get_order;

	# Deal with packages/products.
	# Delete packages & products for combined coids
	if ($params->{'consolidatedorder'})
		{
		for (my $i = 1; $i <= $params->{'productcount'}; $i++)
			{
			# Only packages are relevent for normal consolidates, skip products
			if (!$params->{'cotypeid'} or $params->{'cotypeid'} != 2)
				{
				next if $params->{"datatypeid_" . $i} == 2000;
				}

			my $ComboCO = $c->model('MyDBI::CO')->find({ coid => $params->{"consolidatedcoid_" . $i} });
			next unless $ComboCO;

			$c->log->debug("___ consolidatedorder: Flush old PackProData for ComboCO: " . $ComboCO->coid);
			$ComboCO->delete_all_package_details;

			my $ConsolidationType = $ComboCO->consolidationtype || 0;
			my $Status = $ComboCO->statusid || 0;

			if ($Status == 200)
				{
				$ComboCO->consolidationtype($ConsolidationType);
				}
			elsif ($ConsolidationType and !$params->{'consolidationtype'})
				{
				$ComboCO->consolidationtype($ConsolidationType);
				}
			else
				{
				$ComboCO->consolidationtype($params->{'consolidationtype'});
				}

			$ComboCO->update;
			}
		}
	else
		{
		$c->log->debug("___ Flush old PackProData");
		$CO->delete_all_package_details;
		}

	my $last_package_id=0;
	for (my $index=1; $index <= $total_row_count; $index++)
		{
		# If we're a package...the last id we got back was the id of a package.
		# Save it out so following products will get owned by it.
		# If this is a product, and we have a packageid, the ownertype needs to be a package
		my $PackageIndex = int $self->get_row_id($index);

		next unless defined $params->{'type_' . $PackageIndex};

		$c->log->debug("PackageIndex: " . $PackageIndex);

		my $ownerid         = ($params->{'type_' . $PackageIndex } eq 'product' ? $last_package_id : $CO->coid);
		my $datatypeid      = ($params->{'type_' . $PackageIndex } eq 'product' ? '2000' : '1000');
		my $ownertypeid     = ($params->{'type_' . $PackageIndex } eq 'product' ? '3000' : '1000');

		my $quantity        = $params->{'quantity_' . $PackageIndex} || 0;
		my $weight          = ( $params->{'weight_'.$PackageIndex}    ? sprintf("%.2f",$params->{'weight_'.$PackageIndex}):     undef);
		my $dimweight       = ( $params->{'dimweight_'.$PackageIndex} ? sprintf("%.2f",$params->{'dimweight_'.$PackageIndex}) : undef);
		my $dimlength       = ( $params->{'dimlength_'.$PackageIndex} ? sprintf("%.2f",$params->{'dimlength_'.$PackageIndex}):  undef);
		my $dimwidth        = ( $params->{'dimwidth_'.$PackageIndex}  ? sprintf("%.2f",$params->{'dimwidth_'.$PackageIndex}) :  undef);
		my $dimheight       = ( $params->{'dimheight_'.$PackageIndex} ? sprintf("%.2f",$params->{'dimheight_'.$PackageIndex}) : undef);
		my $density         = ( $params->{'density_' . $PackageIndex} ? sprintf("%.2f",$params->{'density_' . $PackageIndex}) : undef);
		my $class           = $params->{'class_' . $PackageIndex} || 0;
		my $decval          = ( $params->{'decval_' . $PackageIndex}  ? sprintf("%.2f",$params->{'decval_' . $PackageIndex}) :  undef);
		my $frtins          = $params->{'frtins_'.$PackageIndex} || 0;
		my $dryicewt        = ($params->{'dryicewt'} ? ceil($params->{'dryicewt'}) : 0);
		my $unittypeid      = ($params->{'unittype_' . $PackageIndex } ? $params->{'unittype_' . $PackageIndex } : undef);
		my $unitofmeasure   = $params->{'unitofmeasure_' . $PackageIndex} || 0;
		my $quantityxweight = $params->{'quantityxweight_' . $PackageIndex} || 0;

		my $PackProData = {
				ownertypeid     => $ownertypeid,
				ownerid         => $ownerid,
				datatypeid      => $datatypeid,
				boxnum          => $quantity,
				quantity        => $quantity,
				unitofmeasure   => $unitofmeasure,
				unittypeid      => $unittypeid,
				weight          => $weight,
				dimweight       => $dimweight,
				dimlength       => $dimlength,
				dimwidth        => $dimwidth,
				dimheight       => $dimheight,
				density         => $density,
				class           => $class,
				decval          => $decval,
				frtins          => $frtins,
				dryicewt        => int $dryicewt,
				quantityxweight => $quantityxweight
			};

		$PackProData->{partnumber}  = $params->{'sku_' . $PackageIndex} if $params->{'sku_' . $PackageIndex};
		$PackProData->{description} = $params->{'description_' . $PackageIndex} if $params->{'description_' . $PackageIndex};
		$PackProData->{nmfc}        = $params->{'nmfc_' . $PackageIndex} if $params->{'nmfc_' . $PackageIndex};
		$PackProData->{datecreated} = IntelliShip::DateUtils->get_timestamp_with_time_zone;

		#$c->log->debug("PackProData: " . Dumper $PackProData);

		my $PackProDataObj = $c->model("MyDBI::Packprodata")->new($PackProData);
		$PackProDataObj->packprodataid($self->get_token_id);
		$PackProDataObj->insert;

		$c->log->debug("New " . uc($params->{'type_'.$PackageIndex}) . " Inserted, ID: " . $PackProDataObj->packprodataid);

		$last_package_id = $PackProDataObj->packprodataid if ($params->{'type_' . $PackageIndex } eq 'package');
		}
=as
		my $OriginalCOID      = $ItemRef->{'consolidatedcoid' . $PackageIndex };
		my $UnitofMeasure     = $ItemRef->{'unitofmeasure' . $PackageIndex };
		my $DryIceWt          = ceil($ItemRef->{'dryicewt' . $PackageIndex });
		my $ConsolidationType = $ItemRef->{'consolidationtype' . $PackageIndex };
		my $POPPDID           = $ItemRef->{'poppdid' . $PackageIndex };
		my $StatusID          = $ItemRef->{'statusid' . $PackageIndex };
		my $ReqQty            = $ItemRef->{'reqqty' . $PackageIndex };
		my $DGUNNum           = $ItemRef->{'dgunnum' . $PackageIndex };
		my $DGPkgType         = $ItemRef->{'dgpkgtype' . $PackageIndex };
		my $DGPackingGroup    = $ItemRef->{'dgpackinggroup' . $PackageIndex };
		my $DGPkgInstructions = $ItemRef->{'dgpkginstructions' . $PackageIndex };
=cut
	}

sub save_special_services :Private
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	return if $params->{'interview'} == 1 && $params->{'do'} eq 'ship';

	$c->log->debug("... save special services");

	my $CO = $self->get_order;

	if (my @assessorials = $CO->assessorials)
		{
		$c->log->debug("___ Flush old Assdata for ownerid: " . $CO->coid);
		foreach my $AssData (@assessorials)
			{
			$c->log->debug("___ Flush old Assdata for assdataid: " . $AssData->assdataid);
			$AssData->delete;
			}
		}

	my $AssRef = $self->API->get_sop_asslisting($self->customer->get_sop_id);

	my @ass_names = split(/\t/,$AssRef->{'assessorial_names'});
	my @ass_displays = split(/\t/,$AssRef->{'assessorial_display'});

	for (my $row = 0; $row < scalar @ass_names; $row++)
		{
		my $ass_name = $ass_names[$row];
		if (defined $params->{$ass_name})
			{
			my $AssData = {
					ownertypeid => 1000,
					ownerid     => $CO->coid,
					assname     => $ass_names[$row],
					assdisplay  => $ass_displays[$row],
				};

			my $AssDataObj = $c->model("MyDBI::Assdata")->new($AssData);
			$AssDataObj->assdataid($self->get_token_id);
			$AssDataObj->insert;

			$c->log->debug("New AssDataObj Inserted, ID: " . $AssDataObj->assdataid);
			}
		}
	}

sub save_new_order :Private
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	$self->save_order;

	my $parent = $params->{'parent'} || '';
	if (length $parent)
		{
		$c->response->redirect($c->uri_for('/customer/' . $parent));
		}
	else
		{
		$self->clear_CO_details;
		$params->{do} = undef;
		$c->detach($c->action);
		}
	}

sub cancel_order :Private
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	$c->log->debug("___ CANCEL ORDER ___");

	my $CO = $self->get_order;
	$CO->update({ statusid => '200' });

	return if $params->{'consolidate'};

	my $parent = $params->{'parent'} || '';
	if (length $parent)
		{
		$c->response->redirect($c->uri_for('/customer/' . $parent));
		}
	else
		{
		$self->clear_CO_details;
		$params->{do} = undef;
		$c->detach($c->action);
		}
	}

sub get_order :Private
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	if ($c->stash->{CO})
		{
		#$c->log->debug("Hmm, cached CO found");
		$c->stash->{coid} = $c->stash->{CO}->coid;
		return $c->stash->{CO};
		}

	#$c->log->debug("params->{'coid'}: " . $params->{'coid'}) if $params->{'coid'};
	my $CO;
	if ($params->{'coid'})
		{
		$CO = $c->model('MyDBI::Co')->find({ coid => $params->{'coid'} });
		$c->log->debug("Existing CO Found, ID: " . $CO->coid);
		}
	else
		{
		## Set default cotypeid (Default to vanilla 'Order')
		my $cotypeid = $params->{'cotypeid'} || '1';
		my $ordernumber = $params->{'ordernumber'} || '';
		my $customerid = $self->customer->customerid;

		#$c->log->debug("get_order, cotypeid: $cotypeid, ordernumber=$ordernumber, customerid: $customerid");
		my @cos;
=as
		my @r_c = $c->model('MyDBI::Restrictcontact')->search({contactid => $self->contact->contactid, fieldname => 'extcustnum'});

		my $allowed_ext_cust_nums = [];
		push(@$allowed_ext_cust_nums, $_->{'fieldvalue'}) foreach @r_c;


		@cos = $c->model('MyDBI::Co')->search({
							customerid => $customerid,
							ordernumber => uc($ordernumber),
							cotypeid => $cotypeid,
							extcustnum => $allowed_ext_cust_nums
							});

		unless (@cos)
			{
			@cos = $c->model('MyDBI::Co')->search({
							customerid => $customerid,
							ordernumber => uc($ordernumber),
							cotypeid => $cotypeid
							});
			}

		$c->log->debug("total customer order found: " . @cos);

=cut

		my ($coid,$statusid) = (0,0);
		if (@cos)
			{
			$CO = $cos[0];
			($coid, $statusid, $ordernumber) = ($CO->coid,$CO->statusid,$CO->ordernumber);
			$c->log->debug("coid: $coid , statusid: $statusid, ordernumber: $ordernumber");
			}
		else
			{
			$c->log->debug("######## NO CO FOUND ########");
			my $COID = $self->get_token_id;
			my $OrderNumber = $self->get_auto_order_number($params->{'ordernumber'});
			#$OrderNumber = $COID unless $OrderNumber;
			$params->{'ordernumber'} = $OrderNumber;
			$c->stash->{ordernumber} = $OrderNumber;

			my $addressid = $self->contact->address->addressid if $self->contact->address;
			   $addressid = $self->customer->address->addressid if !$addressid and $self->customer->address;

			my $coData = {
				ordernumber       => $OrderNumber,
				clientdatecreated => IntelliShip::DateUtils->get_timestamp_with_time_zone,
				datecreated       => IntelliShip::DateUtils->get_timestamp_with_time_zone,
				customerid        => $customerid,
				contactid         => $self->contact->contactid,
				addressid         => $addressid,
				cotypeid          => $cotypeid,
				freightcharges    => 0,
				statusid          => 1
				};

			$CO = $c->model('MyDBI::Co')->new($coData);
			$CO->coid($COID);
			$CO->insert;

			$c->log->debug("New CO Inserted, ID: " . $CO->coid);
			}
		}

	$c->stash->{coid} = $CO->coid;
	$c->stash->{CO} = $CO;

	return $CO;
	}

sub setup_quickship_page :Private
	{
	my $self = shift;
	my $c = $self->context;

	$c->stash->{title} = 'Quick Ship Order';
	$c->req->params->{do} = undef;
	$c->stash->{quickship} = 1;

	$self->setup_one_page;
	}

sub populate_order :Private
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	return unless $params->{coid};

	$c->log->debug("_______ POPULATE_ORDER _______");

	my $CO = $self->get_order;

	my $populate = $c->stash->{populate};

	$c->stash->{edit_order} = 1 unless $populate;
	$c->stash->{thirdpartyacctid} = $params->{thirdpartyacctid} if $params->{thirdpartyacctid};

	## Shipment Information
	$c->stash->{datetoship} = IntelliShip::DateUtils->american_date($CO->datetoship);
	$c->stash->{dateneeded} = IntelliShip::DateUtils->american_date($CO->dateneeded);
	$c->stash->{ponumber} = $CO->ponumber;
	$c->stash->{extid} = $CO->extid;
	$c->stash->{custref2} = $CO->custref2;
	$c->stash->{custref3} = $CO->custref3;

	## Address and Shipment Information
	if (!$populate or $populate eq 'address' or $populate eq 'summary')
		{
		$c->stash->{combine} = $CO->combine;
		$c->stash->{customer} = $self->customer;
		$c->stash->{customerAddress} = $self->customer->address;

		## Ship From Section
		$c->stash->{fromcontact}= $CO->oacontactname;
		$c->stash->{fromemail}  = $CO->deliverynotification;
		$c->stash->{fromphone}  = $CO->oacontactphone;

		if($CO->isinbound)
			{
			$c->stash->{fromcustomernumber} = $CO->custnum;
			$c->stash->{todepartment} = $CO->department;
			}
		else
			{
			$c->stash->{tocustomernumber} = $CO->custnum;
			$c->stash->{fromdepartment} = $CO->department;
			}

		## Ship To Section
		$c->stash->{tocontact} = $CO->contactname;
		$c->stash->{tophone} = $CO->contactphone;
		$c->stash->{toemail} = $CO->shipmentnotification;
		$c->stash->{ordernumber} = $CO->ordernumber;

		$c->stash->{tocustomernumber} = $CO->custnum;
		$c->stash->{description} = $CO->description;

		$c->stash->{fromAddress} = $CO->origin_address;
		$c->stash->{toAddress} = $CO->destination_address;
		}

	## Package Details
	if (!$populate or $populate eq 'shipment')
		{
		$c->stash->{ROW_COUNT} = 0;

		my $packages = [];
		if ($params->{'coids'})
			{
			foreach my $coid (@{$params->{coids}})
				{
				my $CoObj = $c->model('MyDBI::Co')->find({ coid => $coid});
				my @co_packages = $CoObj->packages;
				push @$packages, $_ foreach @co_packages;

				$c->log->debug("Total No of Packages in COID ($coid): " . @co_packages);
				}

			$c->log->debug("Grand Total Packages: " . @$packages);
			}

		# Step 1: Find Packages belog to Order
		my @CoPackages = $CO->packages;

		$c->stash->{dryicewt} = $CoPackages[0]->dryicewt if @CoPackages;

		push @$packages, $_ foreach @CoPackages;
		$c->log->debug("Total number of packages " . @$packages);

		if ($c->stash->{one_page})
			{
			my ($totalweight,$insurance,$freightinsurance) = (0,0,0);
			my $package_detail_section_html = '';
			foreach my $Package (@$packages)
				{
				$package_detail_section_html .= $self->add_package_detail_row($Package);

				$insurance += $Package->decval;
				$totalweight += $Package->weight;
				$freightinsurance += $Package->frtins;
				}

			$c->stash->{insurance} = $insurance;
			$c->stash->{totalweight} = $totalweight;
			$c->stash->{freightinsurance} = $freightinsurance;

			## Don't move this above foreach block
			$c->stash->{description} = $CO->description;

			#$c->log->debug("PACKAGE_DETAIL_SECTION: HTML: " . $package_detail_section_html);
			$c->stash->{PACKAGE_DETAIL_SECTION} = $package_detail_section_html;
			}
		else
			{
			$c->stash($packages->[0]->{_column_data}) if @$packages;
			$c->stash->{comments} = $CO->description; ##**
			}

		## SELECTED SPECIAL SERVICES
		if ($CO->assessorials->count)
			{
			$c->stash->{SPECIAL_SERVICE} = $self->get_special_services;
			}
		}

	if ($populate eq 'summary')
		{
		my @packages = $CO->packages;

		my $total_weight = $CO->estimatedweight || 0.00;
		unless ($total_weight)
			{
			$total_weight += $_->weight foreach @packages;
			}

		my $insurance = $CO->estimatedinsurance || 0.00;
		unless ($insurance)
			{
			$insurance += $_->decval foreach @packages;
			}

		$c->stash->{fromphone}  = $self->contact->phonebusiness;
		$c->stash->{dateneeded} = IntelliShip::DateUtils->american_date($CO->dateneeded);
		$c->stash->{total_packages} = @packages;
		$c->stash->{total_weight} = sprintf("%.2f",$total_weight);
		$c->stash->{insurance} = sprintf("%.2f",$insurance);

		#$c->stash->{international} = '';
		}

	$c->stash->{deliverymethod} = $CO->freightcharges || 0;
	}

sub set_company_address
	{
	my $self = shift;
	my $c = $self->context;
	my $Contact = $self->contact;
	my $fromAddress = $c->stash->{fromAddress};

	$c->stash->{customername}		= $fromAddress->addressname;
	$c->stash->{customername}		= $Contact->customer->address->addressname unless $c->stash->{customername};
	$c->stash->{customeraddress1}	= $fromAddress->address1;
	$c->stash->{customeraddress2}	= $fromAddress->address2;
	$c->stash->{customercity}		= $fromAddress->city;
	$c->stash->{customercountry}	= $fromAddress->country;
	$c->stash->{customerzip}		= $fromAddress->zip;
	$c->stash->{customerstate}		= $fromAddress->state;
	$c->stash->{customeremail}		= $Contact->email;
	$c->stash->{customerdepartment} = $Contact->department ;
	$c->stash->{customercontact}	= $Contact->full_name;
	$c->stash->{customerphone}		= $Contact->phonebusiness;

	unless ($fromAddress->addressname)
		{
		$fromAddress->addressname($c->stash->{customername});
		$fromAddress->update;
		}
	}

sub add_detail_row :Private
	{
	my $self = shift;
	my $type = shift;
	my $row_num_id = shift;
	my $PackProData = shift;

	my $c = $self->context;
	my $params = $c->req->params;

	$c->stash->{ROW_COUNT} = $row_num_id;
	$c->stash->{DETAIL_TYPE} = $type;

	## Shipment Automation Has Entered Weight, Set Package Weight
	if ($params->{'enteredweight'} and $params->{'enteredweight'} > 0 and $PackProData->datatypeid == 1000)
		{
		$PackProData->weight($params->{'enteredweight'});
		}
	## Shipment Automation Has Entered Package Quantity, Set Package Quantity
	if ($params->{'quantity'} and $params->{'quantity'} > 0 and $PackProData->datatypeid == 1000)
		{
		$PackProData->quantity($params->{'quantity'});
		}

	$c->stash->{'coid'}        = $PackProData->ownerid;
	$c->stash->{'weight'}      = $PackProData->weight;
	$c->stash->{'class'}       = $PackProData->class;
	$c->stash->{'dimweight'}   = $PackProData->dimweight;
	$c->stash->{'unittype'}    = $PackProData->unittypeid;
	$c->stash->{'sku'}         = $PackProData->partnumber;
	$c->stash->{'description'} = $PackProData->description;
	$c->stash->{'quantity'}    = $PackProData->quantity;
	$c->stash->{'frtins'}      = $PackProData->frtins;
	$c->stash->{'nmfc'}        = $PackProData->nmfc;
	$c->stash->{'decval'}      = $PackProData->decval;
	$c->stash->{'dimlength'}   = $PackProData->dimlength;
	$c->stash->{'dimwidth'}    = $PackProData->dimwidth;
	$c->stash->{'dimheight'}   = $PackProData->dimheight;
	$c->stash->{'density'}     = $PackProData->density;

	my $flag = uc($type) . '_DETAIL_ROW';
	$c->stash->{$flag} = 1;
	my $HTML = $c->forward($c->view('Ajax'), "render", [ "templates/customer/order-ajax.tt" ]);
	$c->stash->{$flag} = 0;

	return $HTML;
	}

sub add_package_detail_row :Private
	{
	my $self = shift;
	my $Package = shift;

	my $c = $self->context;
	my $params = $c->req->params;

	$c->stash->{measureunit_loop} = $self->get_select_list('DIMENTION') unless $c->stash->{measureunit_loop};
	$c->stash->{classlist_loop} = $self->get_select_list('CLASS') unless $c->stash->{classlist_loop};
	$c->stash->{'PACKAGE_INDEX'}++;

	## Find Product belog to Package
	my @products = $Package->products;
	my $product_HTML = '';
	foreach my $Product (@products)
		{
		$c->stash->{ROW_COUNT}++;
		$c->stash($Product->{_column_data});

		$c->stash->{PRODUCT_DETAIL_ROW} = 1;
		$product_HTML .= $c->forward($c->view('Ajax'), "render", [ "templates/customer/order-shipment-package.tt" ]);
		$c->stash->{PRODUCT_DETAIL_ROW} = 0;
		}

	## Shipment Automation Has Entered Weight, Set Package Weight
	if ($params->{'enteredweight'} and $params->{'enteredweight'} > 0 and $Package->datatypeid == 1000)
		{
		$Package->weight($params->{'enteredweight'});
		}
	## Shipment Automation Has Entered Package Quantity, Set Package Quantity
	if ($params->{'quantity'} and $params->{'quantity'} > 0 and $Package->datatypeid == 1000)
		{
		$Package->quantity($params->{'quantity'});
		}

	$c->stash($Package->{_column_data});
	$c->stash->{'coid'} = $Package->ownerid;

	if (my $UnitType = $Package->unittype)
		{
		$c->stash->{PACKAGE_TYPE} = uc $UnitType->unittypename;
		}

	$c->stash->{SHIPPER_NUMBER} = $Package->ownerid if $params->{'action'} eq 'consolidate';

	$c->stash->{ROW_COUNT}++;
	$c->stash->{PACKAGE_PRODUCTS_ROW} = $product_HTML;

	$c->stash->{PACKAGE_DETAIL_ROW} = 1;
	my $HTML = $c->forward($c->view('Ajax'), "render", [ "templates/customer/order-shipment-package.tt" ]);
	$c->stash->{PACKAGE_DETAIL_ROW} = 0;

	return $HTML;
	}

sub get_special_services :Private
	{
	my $self = shift;
	my $c = $self->context;

	my $CA = IntelliShip::Controller::Customer::Order::Ajax->new;
	$CA->context($c);
	$CA->contact($self->contact);
	$CA->customer($self->customer);
	$CA->get_special_service_list;
	return $c->forward($c->view('Ajax'), "render", [ "templates/customer/order-ajax.tt" ]);
	}

sub get_tooltips :Private
	{
	my $self = shift;
	my $type = [
		{ id => 'ordernumber'		, value => 'Order number please!' },
		{ id => 'fromdepartment'	, value => 'From where to ship?' },
		{ id => 'fromemail'			, value => 'Your email address will be used for shipment notification!' },
		{ id => 'toname'			, value => 'Recipient company name' },
		{ id => 'toaddress1'		, value => 'Steet Address' },
		{ id => 'toaddress2'		, value => 'Apt, Floor, Suite, etc. (Optional)' },
		{ id => 'tocity'			, value => 'Recipient city' },
		{ id => 'tozip'				, value => 'Recipient zip code' },
		{ id => 'tocontact'			, value => 'Recipient contact' },
		{ id => 'tophone'			, value => 'Recipient phone number' },
		{ id => 'tocustomernumber'	, value => '(Optional)' },
		{ id => 'toemail'			, value => 'Recipient email address will be used for shipment notification!' },
		{ id => 'datetoship'		, value => 'When to ship?' },
		{ id => 'dateneeded'		, value => 'Delivery date' },
		{ id => 'comments'			, value => '(Optional)' },
		{ id => 'dryicewt'			, value => '(Optional)' },
		{ id => 'insurance'			, value => '(Optional)' },
		{ id => 'freightinsurance'	, value => '(Optional)' },
		{ id => 'quantity'			, value => 'Product quantity' },
		{ id => 'sku'				, value => 'Enter sku ID' },
		{ id => 'weight'			, value => 'Provide weight' },
		{ id => 'dimweight'			, value => '(Optional)' },
		{ id => 'dimlength'			, value => 'Package length' },
		{ id => 'dimwidth'			, value => 'Package width' },
		{ id => 'dimheight'			, value => 'Package height' },
		{ id => 'density'			, value => '(Optional)' },
		{ id => 'nmfc'				, value => '(Optional)' },
		{ id => 'class'				, value => '(Optional)' },
		{ id => 'decval'			, value => '(Optional)' },
		{ id => 'frtins'			, value => '(Optional)' },
		{ id => 'type'				, value => 'Provide type' },
		{ id => 'othercarrier'		, value => '(Optional)' },
		];
	return $type;
	}

sub SendChargeThresholdEmail :Private
	{
	my $self = shift;
	#my ($ToEmail,$ShipmentRef) = @_;
    #
	#my $CustomerName = $self->{'customer'}->GetValueHashRef()->{'customername'};
    #
	#my $Addressid = $self->{'customer'}->GetValueHashRef()->{'addressid'};
	#my $Address = new ADDRESS($self->{'dbref'}->{'aos'}, $self->{'customer'});
	#$Address->Load($Addressid);
	#my $AddressCity = $Address->GetValueHashRef()->{'city'};
	#$CustomerName = $CustomerName . " - " . $AddressCity;
    #
	#my $OrderNumAlias = $ShipmentRef->{'ordernumberaka'};
    #
	#if ( !defined($OrderNumAlias) or $OrderNumAlias eq '' )
	#	{
	#	$OrderNumAlias = 'Order #';
	#	}
    #
	#my $DateCreated = $self->{'dbref'}->{'aos'}->gettimestamp();
	#$DateCreated =~ s/^(\d{4})-(\d{2})-(\d{2}).*/$2\/$3\/$1/;
    #
	#my ($OrigCarrier,$OrigService) = &GetCarrierServiceName($ShipmentRef->{'defaultcsid'});
	#my ($Carrier,$Service) = &GetCarrierServiceName($ShipmentRef->{'customerserviceid'});
    #
	#my $DISPLAY = new DISPLAY($TEMPLATE_DIR);
    #
	#my $EmailInfo = {};
	#$EmailInfo->{'fromemail'} = "intelliship\@intelliship.$config->{BASE_DOMAIN}";
	#$EmailInfo->{'fromname'} = 'NOC';
	#$EmailInfo->{'toemail'} = $ToEmail;
	#$EmailInfo->{'toname'} = '';
	#$EmailInfo->{'subject'} =  "ALERT: " . $CustomerName . ", Carrier Change Exceeds Threshold (" . $OrderNumAlias . " " . $ShipmentRef->{'ordernumber'} . ")";
	##$EmailInfo->{'cc'} = 'noc@engagetechnology.com';
    #
	#my $BodyHash = {};
	#$BodyHash->{'ordernumberaka'} = $OrderNumAlias;
	#$BodyHash->{'ordernumber'} = $ShipmentRef->{'ordernumber'};
	#$BodyHash->{'datecreated'} = $DateCreated;
	#$BodyHash->{'username'} = $ShipmentRef->{'active_username'};
	#$BodyHash->{'origcarrier'} = $OrigCarrier;
	#$BodyHash->{'origservice'} = $OrigService;
	#$BodyHash->{'carrier'} = $Carrier;
	#$BodyHash->{'service'} = $Service;
	#$BodyHash->{'totalshipmentcharges'} = sprintf("%.2f", $ShipmentRef->{'totalshipmentcharges'});
	#$BodyHash->{'defaultcsidtotalcost'} = sprintf("%.2f", $ShipmentRef->{'defaultcsidtotalcost'});
    #
	#$DISPLAY->sendemail($EmailInfo,$BodyHash,"changed_shipment.email");
	}

sub CheckChargeThreshold :Private
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	my $Customer = $self->customer;

	my $OverThreshold = 0;

	# Check for flat threshold amount
	#if ( my $Threshold = $Customer->chargediffflat') )
	#	{
	#	my $difference = ($params->{'totalshipmentcharges'} - $params->{'defaultcsidtotalcost'});

	#	if ( $difference > $Threshold )
	#		{
	#		$OverThreshold = 1;
	#		}
	#	}

	# Check for percentage threshold amount (but there's no point if we're already over from the flat)
	#if (!$OverThreshold and (my $Threshold = $Customer->chargediffpct))
	#	{
	#	my $DollarAmt = $params->{'defaultcsidtotalcost'} * ($Threshold / 100);
	#	my $difference = ($params->{'totalshipmentcharges'} - $params->{'defaultcsidtotalcost'});

	#	if ( $difference > $DollarAmt and $difference > $self->{'customer'}->GetCustomerValue('chargediffmin') )
	#		{
	#		$OverThreshold = 1;
	#		}
	#	}

	if ($OverThreshold and $Customer->losspreventemail)
		{
		$self->SendChargeThresholdEmail($Customer->losspreventemail,$params);
		}
	}

sub ProcessFCOverride :Private
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	undef $params->{'packagecosts'};

	my $Weights = $params->{'weightlist'};
	$Weights =~ s/'//g;
	my @Weights = split(/,/,$Weights);

	my $Quantities = $params->{'quantitylist'};
	$Quantities =~ s/'//g;
	my @Quantities = split(/,/,$Quantities);

	if ($params->{'aggregateweight'} > 0)
		{
		for (my $i = 0; $i < scalar @Weights; $i++)
			{
			for ( my $j = 1; $j <= $Quantities[$i]; $j++ )
				{
				my $PackageRatio;

				if ($params->{'quantityxweight'})
					{
					$PackageRatio = $Weights[$i]/$params->{'aggregateweight'};
					}
				else
					{
					$PackageRatio = ($Weights[$i]/$Quantities[$i])/$params->{'aggregateweight'};
					}

				my $PackageCost = sprintf("%02.2f",($params->{'freightcharge'} * $PackageRatio));
				my $PackageFSCCost = sprintf("%02.2f",($params->{'fuelsurcharge'} * $PackageRatio));

				$params->{'packagecosts'} .= $PackageCost . "-" . $PackageFSCCost . "::";
				}
			}
		}
	elsif ($params->{'aggregateweight'} == 0)
		{
		my $TotalQuantity = 0;
		foreach my $Quantity (@Quantities) { $TotalQuantity += $Quantity };
		my $PackageRatio = 1/$TotalQuantity;

		my $PackageCost = sprintf("%02.2f",($params->{'freightcharge'} * $PackageRatio));
		my $PackageFSCCost = sprintf("%02.2f",($params->{'fuelsurcharge'} * $PackageRatio));

		$params->{'packagecosts'} = ( $PackageCost . "-" . $PackageFSCCost . "::" ) x $TotalQuantity;
		}
	}

sub BuildDryIceWt :Private
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	my $DryIceWtList = '';
	my $DryIceWt = '';

	if ($params->{'dryicewtlist'})
		{
		$DryIceWtList = $params->{'dryicewtlist'};
		}
	else
		{
		my $CO = $self->get_order;
		my @packages = $CO->packages;
		foreach my $Package (@packages)
			{
			if ($params->{'quantityxweight'})
				{
				$DryIceWtList .= ceil($params->{'dryicewt'}/$Package->quantity) . ",";
				}
			else
				{
				$DryIceWtList .= ceil($params->{'dryicewt'}) . ",";
				}
			}
		}

	chop ($DryIceWtList);

	if ($DryIceWtList)
		{
		my @DryIceWts = split(/,/,$DryIceWtList);
		$DryIceWt = shift(@DryIceWts);
		$DryIceWtList = join(',',@DryIceWts);
		}

	return ($DryIceWt,$DryIceWtList);
	}

sub SHIP_ORDER :Private
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	IntelliShip::Utils->hash_decode($params);

	$c->log->debug("------- SHIP_ORDER -------");

	$self->save_order unless $params->{'do'} eq 'load';

	my $CO = $self->get_order;

	$params->{'carrier'} = $CO->extcarrier if $CO->extcarrier and !$params->{'carrier'};
	$params->{'service'} = $CO->extservice if $CO->extservice and !$params->{'service'};

	$c->log->debug("Carrier: " . $params->{'carrier'}) if $params->{'carrier'};
	$c->log->debug("Service: " . $params->{'service'}) if $params->{'service'};

	if (length $CO->extcarrier == 0 or length $params->{'carrier'} == 0)
		{
		$c->log->warn("CAN'T SHIP WITHOUT CARRIER");
		return $self->display_error_details("CAN'T SHIP WITHOUT CARRIER");
		}

	my $Customer = $self->customer;

	if ($params->{'defaultcsid'} and $params->{'defaultcsidtotalcost'} > 0 and $params->{'defaultcsid'} ne $params->{'customerserviceid'})
		{
		$self->CheckChargeThreshold;
		}

	## Create or Update the thirdpartyacct table with address info if this is 3rd party
	if ($CO->freightcharges == 2) # Third Party
		{
		$self->save_third_party_details;
		}

	# Prepend 'AM Delivery' to comments if 'AM Delivery' was checked on the interface.
	if ($params->{'amdeliverycheck'})
		{
		if ($params->{'description'} ne '')
			{
			$params->{'description'} = 'AM Delivery: ' . $params->{'description'};
			}
		else
			{
			$params->{'description'} = 'AM Delivery';
			}
		}

	$params->{'customerserviceid'} = $self->API->get_co_customer_service({}, $Customer, $CO) unless $params->{'customerserviceid'};

	my $CustomerID = $Customer->customerid;

	my $laundryArr = [];
	$params->{'new_shipmentid'} = $self->get_token_id;

	## Save out all shipment packages. Give them a dummy shipmentid, pass that around for continuity.
	my @packages = $CO->packages;
	foreach my $Package (@packages)
		{
		my $ShipmentPackage = $c->model('MyDBI::Packprodata')->new($Package->{'_column_data'});
		$ShipmentPackage->ownertypeid(2000); # 2000 = shipment
		$ShipmentPackage->ownerid($params->{'new_shipmentid'});
		$ShipmentPackage->packprodataid($self->get_token_id);
		$ShipmentPackage->shippedqty($ShipmentPackage->quantity);
		$ShipmentPackage->insert;

		push(@$laundryArr, $ShipmentPackage);

		$c->log->debug("___ new shipment package insert: " . $ShipmentPackage->packprodataid);

		my @products = $Package->products;
		foreach my $Product (@products)
			{
			my $ShipmentProduct = $c->model('MyDBI::Packprodata')->new($Product->{'_column_data'});
			$ShipmentProduct->ownertypeid(3000); # 3000 = Product (for Packages)
			$ShipmentProduct->ownerid($ShipmentPackage->packprodataid);
			$ShipmentProduct->packprodataid($self->get_token_id);
			$ShipmentProduct->shippedqty($ShipmentProduct->quantity);
			$ShipmentProduct->insert;

			push(@$laundryArr, $ShipmentProduct);

			$c->log->debug("___ new shipment product insert: " . $ShipmentProduct->packprodataid);
			}
		}

	## 'OTHER' carriers
	if ($params->{'customerserviceid'} =~ m/OTHER_/)
		{
		my ($CustomerServiceID) = $params->{'customerserviceid'} =~ m/OTHER_(.*)/;
		if ($CustomerServiceID eq 'NEW')
			{
			my $Other = $c->model("MyDBI::Other")->new({});
			$Other->insert({
				'othername' => $params->{'other'},
				'customerid' => $CustomerID,
				});
			$params->{'customerserviceid'} = 'OTHER_' . $Other->otherid;
			}

		$params->{'enteredweight'} = $CO->total_weight;
		$params->{'dimweight'} = $CO->total_dimweight;
		$params->{'quantity'} = $CO->total_quantity;
		}
	## 'Normal' carriers
	else
		{
		$params->{'quantity'}      = 0;
		$params->{'dimweight'}     = 0;
		$params->{'enteredweight'} = 0;
		$params->{'dimlength'}     = 0;
		$params->{'dimwidth'}      = 0;
		$params->{'dimheight'}     = 0;
		$params->{'extcd'}         = 0;

		my $ServiceTypeID = $self->API->get_CS_value($params->{'customerserviceid'}, 'servicetypeid', $CustomerID);
		#$c->log->debug("API ServiceTypeID: " . Dumper $ServiceTypeID);

		# Process small/freight shipments (mainly FedEx freight, on the freight end)
		if ($ServiceTypeID < 3000)
			{
			# Get shipment charges and fsc's sorted out for overridden shipment.
			if ($params->{'fcchanged'} and $params->{'fcoverride'})
				{
				$self->ProcessFCOverride;
				}

			my @special_services = $CO->assessorials;
			foreach my $AssData (@special_services)
				{
				my $AssData = $c->model('MyDBI::AssData')->new($AssData->{'_column_data'});
				$AssData->ownertypeid(2000); # 2000 = shipment
				$AssData->ownerid($params->{'new_shipmentid'});
				$AssData->assdataid($self->get_token_id);
				$AssData->insert;

				push(@$laundryArr, $AssData);
				}

			# Push all shipmentcharges onto a list for use by all shipments
			if ($params->{'packagecosts'})
				{
				#$params->{'shipmentchargepassthru'} = $self->BuildShipmentChargePassThru;
				#$c->log->debug("___ shipmentchargepassthru: " . $params->{'shipmentchargepassthru'});
				my @shipmentCharges = split(/\|/,$params->{'packagecosts'});
				foreach my $sc (@shipmentCharges)
					{
					my ($chargename,$chargeamount) = split(/:/,$sc);
					my $ShipmentCharge = $c->model('MyDBI::Shipmentcharge')->new({
						shipmentchargeid => $self->get_token_id,
						shipmentid       => $params->{'new_shipmentid'},
						chargename       => $chargename,
						chargeamount     => sprintf("%.2f",$chargeamount)
						});

					$ShipmentCharge->insert;
					push(@$laundryArr, $ShipmentCharge);
					}
				}

			################################################
			$params->{'enteredweight'} = $CO->total_weight;
			$params->{'dimweight'} = $CO->total_dimweight;
			$params->{'quantity'} = $CO->total_quantity;
			################################################
			}
		elsif ($ServiceTypeID == 3000) ## Process LTL shipments
			{
			$params->{'enteredweight'} = $CO->total_weight;
			$params->{'dimweight'} = $CO->total_dimweight;
			$params->{'quantity'} = $CO->total_quantity;
			}
		}

	# Kludge to get dry ice weight list built up for propagation
	if ($params->{'dryicewt'} or $params->{'dryicewtlist'})
		{
		($params->{'dryicewt'},$params->{'dryicewtlist'}) = $self->BuildDryIceWt;
		}

	# International field
	$self->LoadInternationalDefaults;

	# Build up shipment ref
	my $ShipmentData = $self->BuildShipmentInfo;

	# Kludge to get freightinsurance into the shipments
	my $SaveFreightInsurance = $ShipmentData->{'freightinsurance'};
	$ShipmentData->{'freightinsurance'} = $params->{'frtins'};

	my $CustomerService = $self->API->get_hashref('CUSTOMERSERVICE',$params->{'customerserviceid'});
	#$c->log->debug("CUSTOMERSERVICE DETAILS FOR $params->{'customerserviceid'}:" . Dumper $CustomerService);

	my $ShippingData = $self->API->get_CS_shipping_values($params->{'customerserviceid'},$Customer->customerid);
	#$c->log->debug("get_CS_shipping_values\n RESPONSE: " . Dumper $ShippingData);

	if ($ShippingData->{'decvalinsrate'})
		{
		$CustomerService->{'webaccount'} = $ShippingData->{'webaccount'};
		}

	# If billingaccount (3rd party) exists, and eq webaccount, undef it...this causes problems
	# with FedEx, at the least, and is superfluous/unnecessary elsewhere
	if ($ShipmentData->{'billingaccount'} and $ShipmentData->{'billingaccount'} eq $CustomerService->{'webaccount'})
		{
		undef $ShipmentData->{'billingaccount'};
		}

	if ($ShippingData->{'meternumber'})
		{
		$CustomerService->{'meternumber'} = $ShippingData->{'meternumber'};
		}

	#$c->log->debug("WEBACCOUNT: " . $CustomerService->{'webaccount'} . ", BILLINGACCOUNT: " . $CustomerService->{'webaccount'} . ", TPACCTNUMBER: " . $ShipmentData->{'tpacctnumber'});

	my $Service = $self->API->get_hashref('SERVICE',$CustomerService->{'serviceid'});
	#$c->log->debug("SERVICE: " . Dumper $Service);

	unless ($Service)
		{
		$c->log->debug("SERVICE INFORMATION NOT FOUND ***********");
		return undef;
		}

	if ($ShippingData->{'webhandlername'})
		{
		$Service->{'webhandlername'} = $ShippingData->{'webhandlername'};
		}

	if ($Service->{'webhandlername'} =~ /handler_web_efreight/)
		{
		$params->{'carrier'} = &CARRIER_EFREIGHT;
		}
	elsif ($Service->{'webhandlername'} =~ /handler_local_generic/ && $params->{'carrier'} ne &CARRIER_USPS)
		{
		$params->{'carrier'} = &CARRIER_GENERIC;
		}

	if ($params->{'carrier'} eq &CARRIER_GENERIC || $params->{'carrier'} eq &CARRIER_EFREIGHT)
		{
		my $BillingAddressInfo = $self->GetBillingAddressInfo(
				$params->{'customerserviceid'},
				$CustomerService->{'webaccount'},
				$Customer->customername,
				$Customer->customerid,
				$ShipmentData->{'billingaccount'},
				$ShipmentData->{'freightcharges'},
				$CO->addressid,
				$ShipmentData->{'custnum'},
				$ShippingData->{'baaddressid'}
				);

		$ShipmentData->{'billingaddressname'} = $BillingAddressInfo->{'addressname'};
		$ShipmentData->{'billingaddress1'}    = $BillingAddressInfo->{'address1'};
		$ShipmentData->{'billingaddress2'}    = $BillingAddressInfo->{'address2'};
		$ShipmentData->{'billingcity'}        = $BillingAddressInfo->{'city'};
		$ShipmentData->{'billingstate'}       = $BillingAddressInfo->{'state'};
		$ShipmentData->{'billingcountry'}     = $BillingAddressInfo->{'country'};
		$ShipmentData->{'billingzip'}         = $BillingAddressInfo->{'zip'};

		$c->log->debug("Billing Address" . Dumper $BillingAddressInfo);
		}

	foreach my $key (%$Service)
		{
		next if !$key or !$Service->{$key};
		$ShipmentData->{$key} = $Service->{$key};
		}

	###################################################################
	## Process shipment down through the carrrier handler
	## (online, customerservice, service, carrier handler).
	###################################################################
	my $Handler = IntelliShip::Carrier::Handler->new;
	$Handler->request_type(&REQUEST_TYPE_SHIP_ORDER);
	$Handler->token($self->get_login_token);
	$Handler->context($self->context);
	$Handler->contact($self->contact);
	$Handler->carrier($params->{'carrier'});
	$Handler->customerservice($CustomerService);
	$Handler->service($Service);
	$Handler->CO($CO);
	$Handler->API($self->API);
	$Handler->request_data($ShipmentData);

	my $Response = $Handler->process_request({
			NO_TOKEN_OPTION => 1
			});

	# Process errors
	unless ($Response->is_success)
		{
		$c->log->debug("SHIPMENT TO CARRIER FAILED: " . $Response->message);
		$c->log->debug("RESPONSE CODE: " . $Response->response_code);
		$_->delete foreach @$laundryArr; ## Flush all inserted shipment information
		$self->add_error($Response->message);
		return 0;
		}

	$c->log->debug("SHIPMENT PROCESSED SUCCESSFULLY");

	my $Shipment = $Response->shipment;
	unless ($Shipment)
		{
		$c->log->debug("ERROR: No response received. " . $Response->message);
		$_->delete foreach @$laundryArr; ## Flush all inserted shipment information
		$self->add_error($Response->message);
		return 0;
		}

	my $PrinterString = $Response->printer_string;
	#$c->log->debug("PrinterString: " . $PrinterString);

	$ShipmentData->{'freightinsurance'} = $SaveFreightInsurance;

	# Kludge to maintain 'pickuprequest' $params->{'storepickuprequest'} = $params->{'pickuprequest'};
	#$params = {%$params, %{$Shipment->{'_column_data'}}};
	#$c->log->debug("Shipment->{'_column_data'}: " . Dumper $Shipment->{'_column_data'});

	$params->{'pickuprequest'} = $params->{'storepickuprequest'};

	# Process good shipment

	# If the customer has an email address, check to see if the shipment address is different
	# from the co address (and send an email, if it is)
	if ($Customer->losspreventemail)
		{
		$self->CheckIfShipmentModified($ShipmentData);
		}

	# If the csid was changed from the defaultcsid log the activity in the notes table
	if ($params->{'defaultcsid'} > 0 and $params->{'customerserviceid'} > 0 and $params->{'defaultcsid'} != $params->{'customerserviceid'})
		{
		$self->NoteCSIDOverride($params);
		}

	#Now that we have everything pushed into our params...
	#Check for Products and override screen if we have any
	my $has_pick_and_pack = $CO->has_pick_and_pack;
	if ($has_pick_and_pack)
		{
		#$PNPPPD->SavePickAndPack($params);
		}

	# Change fullfillment status - PO or Pick & Pack Only
	if ($params->{'cotypeid'} == 2 or $has_pick_and_pack)
		{
		if($CO->is_fullfilled($params->{'ordernumber'},$params->{'cotypeid'}))
			{
			$CO->statusid(350); ## Set PO to 'Fullfilled'
			}
		else
			{
			$CO->statusid(300); ## Set PO to 'Unfullfilled'
			}
		}

	$c->log->debug("SHIPMENT ID: " . $Shipment->shipmentid);
	# If we don't have a csid and service, and *do* have a freight charge (s/b through overrride),
	# stuff a shipment charge entry in - this is an 'Other' shipment with an overriden freight charge
	if (!$params->{'customerserviceid'} and !$params->{'service'} and $params->{'freightcharge'})
		{
		my $scData = {
			shipmentchargeid => $self->get_token_id,
			chargename => IntelliShip::Utils->get_shipment_charge_display_name('freightcharge'),
			chargeamount => $params->{'freightcharge'},
			shipmentid => $Shipment->shipmentid,
			};

		$c->model('MyDBI::Shipmentcharge')->new($scData)->insert;
		$c->log->debug("___ NEW SHIPMENTCHARGE INSERTED< ID: " . $scData->{shipmentchargeid});
		}

	#$c->log->debug("SHIPCONFIRM SAVE ASSESSORIALS....");

	## Save out shipment assessorials
	#$self->SaveAssessorials($params,$params->{'shipmentid'},2000);

	## Set shipment and order statuses (ship complete and shipped, respectively)
	$Shipment->statusid(4);
	$CO->statusid(5);

	# Extra, carrier specific bits
	#if ($Shipment->{'screen'} eq 'displayawb_airborne_preprint')
	#	{
	#	my $trackinglast3 = $Shipment->tracking1 =~ /\d+(\d{3})$/;
	#	if ($Shipment->partiestotransaction eq 'Y')
	#		{
	#		$Shipment->{'relateddisplay'} = '&nbsp;&nbsp;&nbsp;&nbsp;X';
	#		}
	#	elsif ( $Shipment->partiestotransaction eq 'N' )
	#		{
	#		$Shipment->{'relateddisplay'} = '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;X';
	#		}
	#	}

	$CO->update;
	$Shipment->update;

	$params->{'shipmentid'} = $Shipment->shipmentid;

	#############################################
	# GENERATE LABEL TO PRINT
	#############################################
	$self->generate_label($Shipment, $Service, $PrinterString);

	return $Shipment->shipmentid;
	}

sub generate_label :Private
	{
	my $self = shift;
	my $Shipment = shift;
	my $Service = shift;
	my $PrinterString = shift;

	my $c = $self->context;
	my $params = $c->req->params;
	my $CO = $self->get_order;

	#$c->log->debug("PrinterString    : " . $PrinterString);

	## Alt SOP mangling
	if ($params->{'usingaltsop'})
		{
		$params->{'addressname'} = $self->API->get_alt_SOP_consignee_name($params->{'customerserviceid'},$params->{'addressname'});
		}
	if ($params->{'originalcoid'})
		{
		my $ParentCO = $c->model('MyDBI::CO')->find({ coid => $params->{'originalcoid'} });
		$params->{'refnumber'} = $ParentCO->ordernumber if $ParentCO;
		}
	else
		{
		$params->{'refnumber'} = $params->{'ordernumber'} || $CO->ordernumber;
		}

	if ($params->{'ponumber'})
		{
		$params->{'refnumber'} .= " - $params->{'ponumber'}";
		}
	elsif ($params->{'custnum'})
		{
		$params->{'refnumber'} .= " - $params->{'custnum'}";
		}

	my $LabelType = $self->contact->get_label_type;

	$c->log->debug(".... Label Type: " . $LabelType);

	## Save EPL Print String On Server
	my $FileName = IntelliShip::MyConfig->label_file_directory . '/' . $Shipment->shipmentid;
	$self->SaveStringToFile($FileName, $PrinterString);

	if ($LabelType =~ /JPG/i)
		{
		my $rotation = $self->contact->jpg_label_rotation;
		my $cmdGenerageLabel = IntelliShip::MyConfig->script_directory . "/intelliship_generate_label.pl " . $Shipment->shipmentid ." jpg s " . $rotation;
		$c->log->debug("cmdGenerageLabel: " . $cmdGenerageLabel);
		system($cmdGenerageLabel);
		}
	else
		{
		if ($LabelType =~ /^zpl$/i)
			{
			require IntelliShip::EPL2TOZPL2;
			my $EPL2TOZPL2 = IntelliShip::EPL2TOZPL2->new();
			$PrinterString = $EPL2TOZPL2->ConvertStreamEPL2ToZPL2($PrinterString);
			}
		}
	}

sub setup_label_to_print
	{
	my $self = shift;

	my $c = $self->context;
	my $params = $c->req->params;

	my $Shipment = $c->model('MyDBI::Shipment')->find({ shipmentid => $params->{'shipmentid'} });

	my $label_file = IntelliShip::MyConfig->label_file_directory . '/' . $Shipment->shipmentid . '.jpg';
	   $label_file = IntelliShip::MyConfig->label_file_directory  . '/' . $Shipment->shipmentid unless -e $label_file;

	$c->stash($params);
	$c->stash->{label_print_count} = $self->contact->default_thermal_count;

	## print commercial invoice only for international shipment
	$c->stash->{printcominv} = $self->contact->get_contact_data_value('defaultcomminv') if $Shipment->is_international;

	unless (-e $label_file)
		{
		$c->log->debug("... label details not found for shipment ID: " . $Shipment->shipmentid);
		$c->stash->{MESSAGE} = 'We are sorry, label information not found.';
		return;
		}

	my $CustomerService = $self->API->get_hashref('CUSTOMERSERVICE',$Shipment->customerserviceid);
	my $Service = $self->API->get_hashref('SERVICE',$CustomerService->{'serviceid'});

	if ($Service->{'webhandlername'} =~ /handler_web_efreight/)
		{
		$params->{'carrier'} = &CARRIER_EFREIGHT;
		}
	elsif ($Service->{'webhandlername'} =~ /handler_local_generic/ && $Shipment->carrier ne &CARRIER_USPS)
		{
		$params->{'carrier'} = &CARRIER_GENERIC;
		}

	## print BOL only for Generic and eFreight
	if ($params->{'carrier'} eq &CARRIER_GENERIC || $params->{'carrier'} eq &CARRIER_EFREIGHT)
		{
		$c->stash->{billoflading} = $self->contact->get_contact_data_value('print8_5x11bol');
		}

	if ($label_file =~ /JPG/i)
		{
		$c->stash->{LABEL_IMG} = '/print/label/' . $Shipment->shipmentid . '.jpg';
		}
	else
		{
		$c->stash($Shipment->{_column_data});
		$c->stash($Shipment->CO->{_column_data});

		$c->stash->{fromAddress}   = $Shipment->origin_address;
		$c->stash->{toAddress}     = $Shipment->destination_address;
		$c->stash->{shipdate}      = IntelliShip::DateUtils->date_to_text_long($Shipment->{_column_data}->{dateshipped}); ##**
		$c->stash->{billingtype}   = ($Shipment->billingaccount ? "3RD PARTY" : "P/P");
		$c->stash->{dimweight}     = $Shipment->dimweight;
		$c->stash->{enteredweight} = $Shipment->total_weight;
		$c->stash->{totalquantity} = $Shipment->total_quantity;
		$c->stash->{refnumber}     = $params->{'refnumber'};

		if ($Shipment->dimlength and $Shipment->dimwidth and $Shipment->dimheight)
			{
			$c->stash->{dims} = $Shipment->dimlength . "x" . $Shipment->dimwidth . "x" . $Shipment->dimheight;
			}

		if ($params->{'carrier'} eq &CARRIER_GENERIC || $params->{'carrier'} eq &CARRIER_EFREIGHT)
			{
			$self->SetGenericLabelData($Shipment)
			}

		$self->SetupPrinterStream($Shipment);

		my $template = $params->{'carrier'} || $Shipment->carrier ;
		   $template = 'default' unless $template;
		$c->stash(LABEL => $c->forward($c->view('Label'), "render", [ "templates/label/" . lc($template) . ".tt" ]));
		}

	$c->stash->{SEND_EMAIL} = IntelliShip::Utils->is_valid_email($Shipment->deliverynotification);
	$c->stash->{AUTO_PRINT} = $self->contact->get_contact_data_value('autoprint');

	$c->stash(template => "templates/customer/order-label.tt");
	}

sub GetNotificationShipments :Private
	{
	my $self = shift;
	my $Shipment = shift;

	my $c = $self->context;
	my $shipment_id = $Shipment->shipmentid;

	my $sql = "
		SELECT
			s.shipmentid,
			to_char(s.dateshipped,'MM/DD/YYYY') as dateshipped,
			to_char(s.datecreated,'MM/DD/YYYY') as datecreated,
			s.tracking1,
			s.carrier,
			s.service,
			to_char(s.datedue,'MM/DD/YYYY') as datedue,
			s.shipmentnotification,
			a.addressname as toname,
			a.city as tocity,
			a.state as tostate,
			p.description as description
		FROM
			shipment s
			INNER JOIN co ON co.coid = s.coid
			INNER JOIN address a ON s.addressiddestin = a.addressid
			INNER JOIN packprodata p ON s.shipmentid = p.ownerid
		WHERE
			s.shipmentid = '$shipment_id'
			AND date(s.dateshipped) = date(timestamp 'now')
			AND s.statusid IN (4,100)
			AND p.datatypeid = 1000
			AND p.ownertypeid = 2000
			AND s.shipmentnotification IS NOT NULL";

	my $sth = $self->myDBI->select($sql);

	my $shipments = [];
	for (my $row=0; $row < $sth->numrows; $row++)
		{
		my $data = $sth->fetchrow($row);
		push(@$shipments,$data);
		}

	return $shipments;
	}

sub SendShipNotification :Private
	{
	my $self = shift;
	my $Shipment = shift;

	return unless $self->contact->get_contact_data_value('aosnotifications');

	return unless $Shipment->shipmentnotification or $Shipment->deliverynotification;

	my $c = $self->context;
	my $Customer = $self->customer;

	my $Email = IntelliShip::Email->new;

	$Email->content_type('text/html');
	$Email->from_address(IntelliShip::MyConfig->no_reply_email);
	$Email->from_name('IntelliShip2');
	$Email->subject("NOTICE: Shipment Prepared (" .$Shipment->carrier . $Shipment->service . "#" . $Shipment->tracking1 . ")");

	$Email->add_to($Shipment->shipmentnotification) if $Shipment->shipmentnotification;
	$Email->add_to($Shipment->deliverynotification) if $Shipment->deliverynotification;

	#if ($Shipment->deliverynotification and $self->contact->get_contact_data_value('combineemail'))
	#	{
	#	$Email->add_to($Shipment->deliverynotification);
	#	}

	#$Email->add_line('<br>');
	#$Email->add_line('<p>Shipment notification</p>');
	#$Email->add_line('<br>');
	
	$self->set_header_section;
	
	$c->stash->{notification_list} = $self->GetNotificationShipments($Shipment);
	$Email->body($Email->body . $c->forward($c->view('Email'), "render", [ 'templates/customer/shipment-notification.tt' ]));

	my $LabelImageFile = IntelliShip::MyConfig->label_file_directory . '/' . $Shipment->shipmentid . '.jpg';
	if (-e $LabelImageFile)
		{
		$Email->attach($LabelImageFile);
		}

	if ($Email->send)
		{
		$c->log->debug("Email successfully sent to " . join(',',@{$Email->to}));
		}
	}

sub VOID_SHIPMENT :Private
	{
	my $self = shift;
	my $shipment_id = shift;

	my $c = $self->context;
	my $params = $c->req->params;
	my $Customer = $self->customer;
	my $Contact = $self->contact;

	$c->log->debug("VOID_SHIPMENT, ID: " . $shipment_id);

	## Set shipment to void status, for later processing
	my $Shipment = $c->model('MyDBI::Shipment')->find({ shipmentid => $shipment_id});
	$Shipment->statusid(5); ## Void Shipment
	$Shipment->update;

	my $CO = $Shipment->CO;

	my $CustomerService = $self->API->get_hashref('CUSTOMERSERVICE',$Shipment->customerserviceid);
	my $Service         = $self->API->get_hashref('SERVICE',$CustomerService->{'serviceid'});

	my $carrier = $Shipment->carrier;
	if ($Service->{'webhandlername'} =~ /handler_web_efreight/)
		{
		$carrier = &CARRIER_EFREIGHT;
		}
	elsif ($Service->{'webhandlername'} =~ /handler_local_generic/ && $Shipment->carrier ne &CARRIER_USPS)
		{
		$carrier = &CARRIER_GENERIC;
		}

	###################################################################
	## Process void shipment down through the carrrier handler
	###################################################################
	my $Handler = IntelliShip::Carrier::Handler->new;
	$Handler->request_type(&REQUEST_TYPE_VOID_SHIPMENT);
	$Handler->token($self->get_login_token);
	$Handler->context($self->context);
	$Handler->contact($self->contact);
	$Handler->carrier($carrier);
	$Handler->CO($CO);
	$Handler->SHIPMENT($Shipment);

	my $Response = $Handler->process_request({
					NO_TOKEN_OPTION => 1
					});

	# Process errors
	unless ($Response->is_success)
		{
		$c->log->debug("VOID SHIPMENT TO CARRIER FAILED: " . $Response->message);
		#return $self->display_error_details($Response->message);
		return undef;
		}

	## Remove product counts from pick & pack CO shipped product counts
	if ($CO->has_pick_and_pack)
		{
		my @packages = $Shipment->packages;
		foreach my $Package (@packages)
			{
			my @products = $Package->products;
			foreach my $Product (@products)
				{
				if ($CO->cotypeid == 2)
					{
					my $shipped_qty = $Product->shippedqty - $Package->quantity;
					$shipped_qty = $shipped_qty > 0 ? $shipped_qty : 0;
					$Product->shippedqty($shipped_qty);
					$Product->reqqty($shipped_qty);
					}
				else
					{
					my $qty = $Product->quantity + $Package->quantity;
					my $shipped_qty = $Product->shippedqty - $Package->quantity;
					my $status_id = $qty > 0 ? 1 : 2;

					$Product->shippedqty($shipped_qty);
					$Product->statusid($status_id);
					$Product->quantity($qty);
					}

				$Product->update;
				}
			}
		}

	## Send an Email Alert to LossPrevention Email
	## If the customer has an email address, check to see if the shipment address is different
	## from the co address (and send an email, if it is)
	my $ToEmail = $Customer->losspreventemail;
	my $CustomerName = $Customer->customername;
	if ($ToEmail)
		{
		$self->SendShipmentVoidEmail($Shipment);
		}

	## Add note to notes table
	my $noteData = { ownerid => $Shipment->shipmentid };
	$noteData->{'notesid'}      = $self->get_token_id;
	$noteData->{'note'}         = 'Shipment Voided By ' . $Contact->username;
	$noteData->{'contactid'}    = $Contact->contactid;
	$noteData->{'notestypeid'}  = 900;
	$noteData->{'datehappened'} = IntelliShip::DateUtils->get_timestamp_with_time_zone();

	$c->model('MyDBI::Note')->new($noteData)->insert;

	return 1;
	}

sub SendShipmentVoidEmail
	{
	my $self = shift;
	my $Shipment = shift;

	my $Contact        = $self->contact;
	my $Customer       = $self->customer;
	my $OrderNumber    = $Shipment->CO->ordernumber;
	my $TrackingNumber = $Shipment->tracking1;
	my $ipaddress      = $self->context->req->address;

	my ($Carrier,$Service) = $self->API->get_carrier_service_name($Shipment->customerserviceid);

	my $subject = "WARNING: " . $Customer->customername . ", $Carrier $Service $TrackingNumber (Voided By " . $Contact->full_name  . "/$ipaddress )";
	my $Email = IntelliShip::Email->new;

	$Email->content_type('text/html');
	$Email->from_address(IntelliShip::MyConfig->no_reply_email);
	$Email->from_name('IntelliShip2');
	$Email->subject($subject);
	$Email->add_to($Customer->losspreventemail);

	$Email->add_line('');
	$Email->add_line('=' x 60);
	$Email->add_line('ShipmentID  : ' . $Shipment->shipmentid);
	$Email->add_line('Carrier     : ' . $Carrier);
	$Email->add_line('Service     : ' . $Service);
	$Email->add_line('Tracking1   : ' . $TrackingNumber);
	$Email->add_line('OrderNumber : ' . $OrderNumber);
	$Email->add_line('=' x 60);
	$Email->add_line('');

	if ($Email->send)
		{
		$self->context->log->debug("Shipment voide notification email successfully sent");
		}
	}

sub SetGenericLabelData
	{
	my $self = shift;
	my $Shipment = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	$c->log->debug("___ SetGenericLabelData ___");

	my $CO       = $Shipment->CO;
	my $Customer = $CO->customer;

	#####################################################################################################
	## Build comment string (concat all charges for the shipment) and assessorials that aren't charged
	#####################################################################################################

	# build string to exclude asses that were charged/included above
	my ($CommentString,$ExcludeNames) = ('',{});

	my @shipmentcharge = $Shipment->shipment_charges;
	foreach my $ShipmentCharge (@shipmentcharge)
		{
		if ( $ShipmentCharge->chargename !~ /Freight/i && $ShipmentCharge->chargename !~ /Fuel Surcharge/i )
			{
			$ExcludeNames->{$ShipmentCharge->chargename} = 1;
			}
		$CommentString .= $ShipmentCharge->chargename . ", ";
		}

	my @assessorials = $Shipment->assessorials;

	foreach my $AccessorialName (@assessorials)
		{
		next if $ExcludeNames->{$AccessorialName->assdisplay};
		$CommentString .= $AccessorialName->assdisplay. ", ";
		}

	$CommentString =~ s/(.*), $/\( $1 \)/;
	$c->stash->{commentstring}      = $CommentString;
	$c->stash->{customsdescription} = $Shipment->customsdescription;
	$c->stash->{branchcontact}      = $Shipment->oacontactname;
	$c->stash->{branchphone}        = $Shipment->oacontactphone;

	my $CSValueRef = $self->API->get_CS_shipping_values($Shipment->customerserviceid, $CO->customerid);

	my $webaccount;
	if ( $CSValueRef->{'webaccount'} )
		{
		$webaccount = $CSValueRef->{'webaccount'};
		}

	my $BillingAddressInfo = $self->GetBillingAddressInfo(
			$Shipment->customerserviceid,
			$webaccount,
			$Customer->customername,
			$Customer->customerid,
			$Shipment->billingaccount,
			$Shipment->freightcharges,
			$Shipment->addressiddestin,
			$Shipment->custnum,
			$CSValueRef->{'baaddressid'}
			);

	#$c->log->debug("Billing Address" . Dumper $BillingAddressInfo);

	## if it's third party billing add the account number to the name
	if ($Shipment->billingaccount && $Shipment->billingaccount ne 'Collect')
		{
		$BillingAddressInfo->{'addressname'} .= " (" . $Shipment->billingaccount . ")";
		}

	$BillingAddressInfo->{'addressname'}  = '' unless $BillingAddressInfo->{'addressname'};
	$BillingAddressInfo->{'addressname2'} = '' unless $BillingAddressInfo->{'addressname2'};

	if ($BillingAddressInfo->{'addressname'} =~ /Engage TMS Global Logistics/i || $BillingAddressInfo->{'addressname2'} =~ /c\/o Engage TMS Global Logistics/i)
		{
		$BillingAddressInfo->{'engage'} ='714-517-5540';
		}

	## generate tracking number barcode image
	IntelliShip::Utils->generate_UCC_128_barcode($Shipment->tracking1);

	$c->stash->{BillingAddressInfo} = $BillingAddressInfo;
	}

sub SetupPrinterStream
	{
	my $self = shift;
	my $Shipment = shift;

	my $c = $self->context;
	my $Contact = $self->contact;

	# Label stub
	#if ( my $StubTemplate = $Contact->get_contact_data_value('labelstub') )
		#{
		#$CgiRef->{'truncd_custnum'} = TruncString($CgiRef->{'custnum'},16);
		#$CgiRef->{'truncd_addressname'} = TruncString($CgiRef->{'addressname'},16);
		#$PrinterString = $self->InsertLabelStubStream($PrinterString,$StubTemplate,$CgiRef);
		#}

	#if ( $CgiRef->{'dhl_intl_labels'} )
	#	{
	#	$PrinterString .= $CgiRef->{'dhl_intl_labels'};
	#	}

	# UCC 128 label handling
	#if ($Contact->get_contact_data_value('checkucc128'))
		#{
		#my $UCC128 = new UCC128($self->{'dbref'}->{'aos'}, $self->{'customer'});
		#if ( my $UCC128ID = $UCC128->GetUCC128ID($CgiRef->{'addressname'},$CgiRef->{'department'},$CgiRef->{'custnum'},$CgiRef->{'externalpk'}) )
		#	{
		#	$UCC128->Load($UCC128ID);
		#	$PrinterString .= $self->BuildUCC128Label;
		#	}
		#}

	## Set Printer String Loop
	my $label_file = IntelliShip::MyConfig->label_file_directory  . '/' . $Shipment->shipmentid;

	my $FILE = new IO::File;
	unless (open ($FILE,$label_file))
		{
		$c->log->debug("*** Label File Error: " . $!);
		return;
		}

	my @PSLINES = <$FILE>;

	close $FILE;

	my $printerstring_loop = [];
	foreach my $line (@PSLINES)
		{
		chomp $line;
		next unless $line;
		$line =~ s/"/\\"/sg;
		$line =~ s/'//g;
		push @$printerstring_loop, $line;
		}

	#$c->log->debug("printerstring_loop: " . Dumper $printerstring_loop);

	$c->stash->{printerstring_loop} = $printerstring_loop;
	$c->stash->{label_port}         = $Contact->label_port || 'LPT1';
	}

# Push all shipment charges onto a simple delimited string, for passing back so that all
# shipments in a given run will receive proper individual charges.  This is mainly for use
# with carriers that we connect directly to (FedEx, DHL, etc).
sub BuildShipmentChargePassThru
	{
	my $self = shift;
	my $ChargeRef = $self->context->params;

	my $ShipmentChargePassThru = '';
	my @PackageRatios = $self->GetPackageRatios;

	# Get freight and fuel surcharges set up
	my @FreightANDFSCCharges = split(/::/,$ChargeRef->{'packagecosts'});

	my @FreightCharges = ();
	my @FSCCharges = ();

	foreach my $FreightAndFSCCharge ( @FreightANDFSCCharges )
		{
		my($FreightCharge,$FSCCharge) = split(/-/,$FreightAndFSCCharge);

		push(@FreightCharges,$FreightCharge);
		push(@FSCCharges,$FSCCharge);
		}

	my $FreightChargeList = join(',',@FreightCharges);
	$ShipmentChargePassThru .= 'freightcharge:' . $FreightChargeList . '::';

	my $FSCChargeList = join(',',@FSCCharges);
	$ShipmentChargePassThru .= 'fuelsurcharge:' . $FSCChargeList . '::';

	# Get accessorial charges (charge a portion to each package, based on the ratio of package
	# weight vs. total shipment weight).
	my $ChargeCount = scalar(@FreightCharges);

	foreach my $ChargeType (@{$self->{'chargetypes'}})
		{
		if ( $ChargeType eq 'freightcharge' or $ChargeType eq 'fuelsurcharge' ) { next; }

		$ShipmentChargePassThru .= "$ChargeType:";

		for ( my $i = 0; $i < $ChargeCount; $i ++ )
			{
			if ($ChargeRef->{$ChargeType} >= 0)
				{
				my $Charge = sprintf("%02.2f",$ChargeRef->{$ChargeType} * $PackageRatios[$i]);
				$ShipmentChargePassThru .= "$Charge,";
				}
			}

		chop($ShipmentChargePassThru);

		$ShipmentChargePassThru .= "::";
		}

	$ShipmentChargePassThru =~ s/[a-z]+:://g;

	return $ShipmentChargePassThru;
	}

sub BuildUCC128Label
	{
	my $self = shift;

	my $Shipment;
	# Build carrier routing stuff
	my $Zip = $Shipment->{'addresszip'};
	if ( $Zip =~ /(\d{5})-\d{4}/ ) { $Zip = $1 }
	$Shipment->{'carrierroutingbc'} = '420' . $Zip;
	$Shipment->{'carrierroutinghr'} = '(420) ' . $Zip;

	# Build sscc stuff
	my $SSCAIN = '00';

	my $Sequence = $self->{'dbref'}->seqnumber($self->{'sequencename'});

	my $Contact = new CONTACT($self->{'dbref'}, $self->{'customer'});
	$Contact->Load($Shipment->{'contactid'});
	my $EANUCCPrefix = $Contact->GetContactValue('eanuccprefix');

	while ( length($Sequence . $EANUCCPrefix) < 17 ) { $Sequence = '0' . $Sequence }

	my ($SeqFirst,$SeqLast16) = $Sequence =~ /(\d)(\d+)/;

	my $BaseNumber = $SeqFirst . $EANUCCPrefix . $SeqLast16;
	my @BaseNumbers = split(//,$BaseNumber);
	pop(@BaseNumbers);
	my $BaseOdd;
	my $BaseEven;

	while (@BaseNumbers)
		{
		$BaseOdd += shift(@BaseNumbers);
		$BaseEven += shift(@BaseNumbers);
		}

	my $CheckDigit = 10 - ((($BaseOdd * 3) + $BaseEven) % 10);

	$Shipment->{'ssccbc'} = $SSCAIN . $SeqFirst . $EANUCCPrefix . $SeqLast16 . $CheckDigit;
	$Shipment->{'sscchr'} = "($SSCAIN) $SeqFirst $EANUCCPrefix $SeqLast16 $CheckDigit";

	# Save sscc back to shipment
	$Shipment->ssccnumber('',$Shipment->{'ssccbc'});
	$Shipment->update;

	my $UCC128Label;
=as
	# Build up UCC128 label stream
	chop(my $CONF_DIRECTORY = "$config->{BASE_PATH}/conf/");
	my $TEMPLATE_DIR = $CONF_DIRECTORY;
	use DISPLAY;
	my $DISPLAY = new DISPLAY($TEMPLATE_DIR);

	my $RawString = $DISPLAY->TranslateTemplate($self->{'ucc128template'}, $Shipment);

	$RawString =~ s/"/\\"/sg;
	$RawString =~ s/'//g;

	# Generate proper number of copies
	for ( my $i = 1; $i <= $self->{'ucc128copies'}; $i ++ )
		{
		my @StringLines = split("\n",$RawString);

		# Tag lines for web use
		foreach my $Line (@StringLines)
			{
			$UCC128Label .= "$Line\n";
			}
		}
=cut
	return $UCC128Label;
	}

sub GetPackageRatios
	{
	my $self = shift;
	my $ShipmentRef = $self->context->params;

	my @PackageRatios = ();

	# Get weights (higher of entered or dim), for determining accessorial ratios
	my $EnteredWeights = $ShipmentRef->{'weightlist'};
	$EnteredWeights =~ s/'//g;
	my @EnteredWeights = split(/,/,$EnteredWeights);

	my $DimWeights = '';
	my @DimWeights = ();
	if ($ShipmentRef->{'dimweightlist'})
		{
		$DimWeights = $ShipmentRef->{'dimweightlist'};
		$DimWeights =~ s/'//g;
		@DimWeights = split(/,/,$DimWeights);
		}

	for ( my $i = 0; $i < scalar @EnteredWeights; $i ++ )
		{
		my $Ratio = 0;
		if ( defined($ShipmentRef->{'aggregateweight'}) and $ShipmentRef->{'aggregateweight'} == 0 )
			{
			$Ratio = 1/$ShipmentRef->{'totalquantity'};
			}
		elsif ( defined($DimWeights[$i]) and $DimWeights[$i] > $EnteredWeights[$i] )
			{
			$Ratio = $DimWeights[$i]/$ShipmentRef->{'aggregateweight'};
			}
		else
			{
			$Ratio = $EnteredWeights[$i]/$ShipmentRef->{'aggregateweight'};
			}

		push(@PackageRatios,$Ratio);
		}

	return @PackageRatios;
	}

sub LoadInternationalDefaults
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	my $CO = $self->get_order;
	my $myDBI = $c->model('MyDBI');

	# Defaults for Int'l values

	my $ToAddress = $CO->destination_address;
	$params->{'destinationcountry'} = $params->{'destinationcountry'} ? $params->{'destinationcountry'} : $ToAddress->country;
	my $FromAddress = $CO->origin_address;
	$params->{'manufacturecountry'} = $params->{'manufacturecountry'} ? $params->{'manufacturecountry'} :$FromAddress->country;
	$params->{'harmonizedcode'} = $params->{'harmonizedcode'} ? $params->{'harmonizedcode'} : $params->{'exthsc'};

	$params->{'customsdescription'} = $CO->extcd if !$params->{'customsdescription'} and $CO->extcd;
	$params->{'commoditycustomsvalue'} = $params->{'commoditycustomsvalue'} ? $params->{'commoditycustomsvalue'} : $CO->estimatedinsurance;
	$params->{'commodityweight'} = $params->{'enteredweight'};
	$params->{'slac'} = $params->{'slac'} ? $params->{'slac'} : $params->{'commodityquantity'};
	$params->{'dimunits'} = ( $params->{'destinationcountry'} eq 'US' ) ? 'IN' : 'CM';

	my $commoditycustomsvalue = $params->{'commoditycustomsvalue'} || 0;
	my $commodityquantity     = $params->{'commodityquantity'} || 0;
	if ($commoditycustomsvalue && $commodityquantity && !$params->{'commodityunitvalue'})
		{
		$params->{'commodityunitvalue'} = $commoditycustomsvalue / $commodityquantity;
		}

	my $manufacturecountry = $params->{'manufacturecountry'} || '';
	my $destinationcountry = $params->{'destinationcountry'} || '';
	if ($manufacturecountry =~ /(US|CA|MX)/ && $destinationcountry =~ /(US|CA|MX)/)
		{
		$params->{'naftaflag'} = 'Y';
		}
	else
		{
		$params->{'naftaflag'} = 'N';
		}

	# Set defaults across the board (Basically, whatever the interface defaults to)
	#$params->{'termsofsale'} = $params->{'termsofsale'}  ? $params->{'termsofsale'} : 1;
	#$params->{'dutypaytype'} = $params->{'dutypaytype'} ? $params->{'dutypaytype'} : 1;
	#$params->{'commodityunits'} = $params->{'commodityunits'} ? $params->{'commodityunits'} : 'PCS';
	#$params->{'partiestotransaction'} = $params->{'partiestotransaction'} ? $params->{'partiestotransaction'} : 'N';
	#$params->{'commoditycustomsvalue'} = $params->{'commoditycustomsvalue'}  ? $params->{'commoditycustomsvalue'} : 0;
	#$params->{'commodityunitvalue'} = $params->{'commodityunitvalue'}  ? $params->{'commodityunitvalue'} : 0;
	#$params->{'currencytype'} = $params->{'currencytype'}  ? $params->{'currencytype'} : 'USD';
	}

sub BuildShipmentInfo
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	my $CO = $self->get_order;
	my $Contact = $CO->contact;
	my $Customer = $CO->customer;

	my $myDBI = $c->model('MyDBI');

	my $ShipmentData = { 'new_shipmentid' => $params->{'new_shipmentid'} };

	$ShipmentData->{$_} = $params->{$_} foreach keys %$params;

	my $FromAddress = $CO->origin_address;
	$ShipmentData->{'shipasname'}           = $FromAddress->addressname;
	$ShipmentData->{'customername'}         = $FromAddress->addressname;
	$ShipmentData->{'branchaddress1'}       = $FromAddress->address1;
	$ShipmentData->{'branchaddress2'}       = $FromAddress->address2;
	$ShipmentData->{'branchaddresscity'}    = $FromAddress->city;
	$ShipmentData->{'branchaddressstate'}   = $FromAddress->state;
	$ShipmentData->{'branchaddresszip'}     = $FromAddress->zip;
	$ShipmentData->{'branchaddresscountry'} = $FromAddress->country;

	my $ToAddress = $CO->destination_address;
	$ShipmentData->{'addressname'}          = $ToAddress->addressname;
	$ShipmentData->{'address1'}             = $ToAddress->address1;
	$ShipmentData->{'address2'}             = $ToAddress->address2;
	$ShipmentData->{'addresscity'}          = $ToAddress->city;
	$ShipmentData->{'addressstate'}         = $ToAddress->state;
	$ShipmentData->{'addresszip'}           = $ToAddress->zip;
	$ShipmentData->{'addresscountry'}       = $ToAddress->country;
	$ShipmentData->{'addresscountryname'}   = $ToAddress->country_description;

	$ShipmentData->{'coid'} = $CO->coid;
	$ShipmentData->{'datetoship'} = IntelliShip::DateUtils->american_date($CO->datetoship);
	$ShipmentData->{'dateneeded'} = IntelliShip::DateUtils->american_date($CO->dateneeded);

	$ShipmentData->{'contactname'} = $CO->contactname;
	$ShipmentData->{'contactphone'} = $CO->contactphone;
	$ShipmentData->{'contacttitle'} = $CO->contacttitle;
	$ShipmentData->{'dimlength'} = $CO->dimlength;
	$ShipmentData->{'dimwidth'} = $CO->dimwidth;
	$ShipmentData->{'dimheight'} = $CO->dimheight;
	$ShipmentData->{'currencytype'} = $CO->currencytype;
	$ShipmentData->{'destinationcountry'} = $CO->destinationcountry;
	$ShipmentData->{'manufacturecountry'} = $CO->manufacturecountry;
	$ShipmentData->{'dutypaytype'} = $CO->dutypaytype;
	$ShipmentData->{'termsofsale'} = $CO->termsofsale;
	$ShipmentData->{'commodityquantity'} = $CO->commodityquantity;
	$ShipmentData->{'commodityunitvalue'} = $CO->commodityunitvalue;
	$ShipmentData->{'commoditycustomsvalue'} = $CO->commoditycustomsvalue;
	$ShipmentData->{'unitquantity'} = $CO->unitquantity;
	$ShipmentData->{'partiestotransaction'} = $CO->partiestotransaction;
	$ShipmentData->{'dutyaccount'} = $CO->dutyaccount;
	$ShipmentData->{'commodityunits'} = $CO->commodityunits;
	$ShipmentData->{'bookingnumber'} = $CO->bookingnumber;
	$ShipmentData->{'ordernumber'} = $CO->ordernumber;
	$ShipmentData->{'description'} = $CO->description;
	$ShipmentData->{'extcd'} = $CO->extcd;
	$ShipmentData->{'shipmentnotification'} = $CO->shipmentnotification;
	$ShipmentData->{'deliverynotification'} = $CO->deliverynotification;
	$ShipmentData->{'hazardous'} = $CO->hazardous;
	$ShipmentData->{'ponumber'} = $CO->ponumber;
	$ShipmentData->{'securitytype'} = $CO->securitytype;
	$ShipmentData->{'contactid'} = $CO->contactid;
	$ShipmentData->{'extid'} = $CO->extid;
	$ShipmentData->{'custref2'} = $CO->custref2;
	$ShipmentData->{'custref3'} = $CO->custref3;
	$ShipmentData->{'department'} = $CO->department;
	$ShipmentData->{'freightcharges'} = $CO->freightcharges;
	$ShipmentData->{'isinbound'} = $CO->isinbound;
	$ShipmentData->{'isdropship'} = $CO->isdropship;
	$ShipmentData->{'datereceived'} = IntelliShip::DateUtils->american_date_time($CO->datereceived);
	$ShipmentData->{'datepacked'} = IntelliShip::DateUtils->american_date_time($CO->datepacked);
	$ShipmentData->{'daterouted'} = IntelliShip::DateUtils->american_date_time($CO->daterouted);
	$ShipmentData->{'usealtsop'} = $CO->usealtsop;
	$ShipmentData->{'quantityxweight'} = $CO->quantityxweight;

	$ShipmentData->{'dimweight'} = $params->{'dimweight'};
	$ShipmentData->{'customsdescription'} = $params->{'customsdescription'};
	$ShipmentData->{'dimunits'} = $params->{'dimunits'};
	$ShipmentData->{'commodityweight'} = $params->{'commodityweight'};
	$ShipmentData->{'customsvalue'} = $params->{'customsvalue'};
	$ShipmentData->{'customsdesription'} = $params->{'customsdesription'};
	$ShipmentData->{'harmonizedcode'} = $params->{'harmonizedcode'};
	$ShipmentData->{'ssnein'} = $params->{'ssnein'};
	$ShipmentData->{'naftaflag'} = $params->{'naftaflag'};
	$ShipmentData->{'slac'} = $params->{'slac'};
	$ShipmentData->{'billingaccount'} = $params->{'billingaccount'};
	$ShipmentData->{'billingpostalcode'} = $params->{'billingpostalcode'};
	$ShipmentData->{'tracking1'} = $params->{'tracking1'};
	$ShipmentData->{'defaultcsid'} = $params->{'defaultcsid'};

	$ShipmentData->{'carrier'} = ($params->{'carrier'} ? $params->{'carrier'} : $CO->extcarrier);
	$ShipmentData->{'service'} = ($params->{'service'} ? $params->{'service'} : $CO->extservice);

	$ShipmentData->{'quantity'} = ($params->{'quantity'} ? $params->{'quantity'} : $CO->total_weight);
	$ShipmentData->{'totalquantity'} = $CO->total_quantity;
	$ShipmentData->{'freightinsurance'} = $params->{'freightinsurance'};
	$ShipmentData->{'weighttype'} = $params->{'weighttype'};
	$ShipmentData->{'dimunits'} = $params->{'dimunits'};
	$ShipmentData->{'density'} = $CO->density;
	$ShipmentData->{'ipaddress'} = $params->{'ipaddress'};
	$ShipmentData->{'custnum'} = $params->{'custnum'};

	$ShipmentData->{'manualthirdparty'} = $params->{'manualthirdparty'};
	$ShipmentData->{'originid'} = 3;
	$ShipmentData->{'insurance'} = $params->{'insurance'};

	$ShipmentData->{'branchcontact'}  = $CO->oacontactname;
	$ShipmentData->{'branchphone'}    = $CO->oacontactphone;

	$ShipmentData->{'oacontactname'}  = $CO->oacontactname;
	$ShipmentData->{'oacontactphone'} = $CO->oacontactphone;

	$ShipmentData->{'cfcharge'} = $params->{'cfcharge'};
	$ShipmentData->{'usingaltsop'} = $params->{'usingaltsop'};
	$ShipmentData->{'dryicewt'} = $params->{'dryicewt'};
	$ShipmentData->{'dryicewtlist'} = $params->{'dryicewtlist'};
	$ShipmentData->{'dgunnum'} = $params->{'dgunnum'};
	$ShipmentData->{'dgpkgtype'} = $params->{'dgpkgtype'};
	$ShipmentData->{'dgpkginstructions'} = $params->{'dgpkginstructions'};
	$ShipmentData->{'dgpackinggroup'} = $params->{'dgpackinggroup'};
	$ShipmentData->{'assessorial_names'} = $params->{'assessorial_names'};

	if ($params->{'aostype'} and $params->{'aostype'} == 1)
		{
		$ShipmentData->{'shipqty'} = $params->{'shipqty'};
		$ShipmentData->{'shiptypeid'} = $params->{'shiptypeid'};
		}

	# undef billingaccount if it came through the interface as tp but it is in the db already as fedex hack thirdpartyacct which really isn't tp
	if ($params->{'customerserviceid'} and $params->{'billingaccount'} and
		!$self->API->valid_billing_account($params->{'customerserviceid'},$params->{'billingaccount'}))
		{
		$params->{'billingaccount'} = undef;
		}

	if ($CO->tpacctnumber)
		{
		$ShipmentData->{'thirdpartybilling'} = 1;

		# Get third party address bits into params (in case we picked up a 3p account from 'BuildShipmentData'
		if (my $ThirdPartyAccountObj = $Customer->third_party_account($CO->tpacctnumber))
			{
			$ShipmentData->{'tpcompanyname'} = $ThirdPartyAccountObj->tpcompanyname;
			$ShipmentData->{'tpaddress1'}    = $ThirdPartyAccountObj->tpaddress1;
			$ShipmentData->{'tpaddress2'}    = $ThirdPartyAccountObj->tpaddress2;
			$ShipmentData->{'tpcity'}        = $ThirdPartyAccountObj->tpcity;
			$ShipmentData->{'tpstate'}       = $ThirdPartyAccountObj->tpstate;
			$ShipmentData->{'tpzip'}         = $ThirdPartyAccountObj->tpzip;
			$ShipmentData->{'tpcountry'}     = $ThirdPartyAccountObj->tpcountry;
			}
		}

	# If carrier/service is FedEx/Freight, set 3rd party billing to the Engage heavy account
	my $host_name = IntelliShip::MyConfig->getHostname;
	if ($params->{'carrier'}  =~ /FedEx/ and $params->{'service'} =~ /Freight/ and !$params->{'billingaccount'} and $host_name !~ /rml/)
		{
		$c->log->debug("*** In FedEx billingaccount/thirdpartybillinghack");
		$ShipmentData->{'billingaccount'} = '232191376';
		$ShipmentData->{'thirdpartybilling'} = 0;
		}

	# Check new alt billing table first before the actual CS value.
	# Check for 3rd party billing defaults for customer/service
	# All of this needs a csid (won't work for autoselect otherwise)
	if ($params->{'customerserviceid'} and !$params->{'billingaccount'})
		{
		my $Key = 'extcustnum';
		my $Value = $params->{'custnum'} || '';
		my $CarrierID = $self->API->get_carrier_ID($params->{'customerserviceid'}) || '';

		# Get alternate billing account
		my $sth = $myDBI->select("SELECT billingaccount FROM altbilling WHERE key = '$Key' AND upper(value) = upper('$Value') AND carrierid = '$CarrierID' LIMIT 1");
		my $ThirdPartyAcct = $sth->fetchrow(0)->{'billingaccount'} if $sth->numrows;

		unless ($ThirdPartyAcct)
			{
			$ThirdPartyAcct = $self->API->get_CS_value($params->{'customerserviceid'}, 'thirdpartyacct', $self->customer->customerid, 0);
			#$c->log->debug("API ThirdPartyAcct: " . Dumper $ThirdPartyAcct);
			}

		if ($ThirdPartyAcct and $ThirdPartyAcct =~ m/^engage::(.*?)$/)
			{
			$ShipmentData->{'thirdpartybilling'} = 0;
			(my $junk,$ThirdPartyAcct) = split(/::/,$ThirdPartyAcct);
			}

		$ShipmentData->{'billingaccount'} = $ThirdPartyAcct;
		}

	# put collect in 'billingaccount' if 'Collect' Freight Charges is selected on the BOL
	if (!$params->{'billingaccount'} and $params->{'cfcharge'})
		{
		$ShipmentData->{'billingaccount'} = 'Collect';
		$ShipmentData->{'thirdpartybilling'} = 1;
		}

	# Build up 'dims' ref for label display
	if ($params->{'dimlength'} or $params->{'dimwidth'} or $params->{'dimheight'} or $params->{'dimunits'})
		{
		$ShipmentData->{'dims'} = $params->{'dimlength'} . 'x' . $params->{'dimwidth'} . 'x' . $params->{'dimheight'} . " " . $params->{'dimunits'};
		}

	# Put assessorials onto shipment ref
	if ($params->{'assessorial_names'})
		{
		my $ass_names = $params->{'assessorial_names'};
		$ass_names =~ s/'//g;
		my @ass_names = split(/,/,$ass_names);

		foreach my $ass_name (@ass_names)
			{
			my $ass_charge_name = grep { $ass_name eq $_ and ($params->{$_} eq 'on' or $params->{$_} > 0 ) } keys %$params;
			$ShipmentData->{$ass_charge_name} = $params->{$ass_charge_name} if $ass_charge_name;
			}
		}

	return $ShipmentData;
	}

sub CheckIfShipmentModified
	{
	my $self = shift;
	my $ShipmentData = shift;

	# Load CO so we we can check against what was actually shipped.
	my $CO = $self->get_order;

	my $OriginalAddress = $CO->to_address;

	if (   $OriginalAddress->addressname ne $ShipmentData->{'addressname'}
		or $OriginalAddress->address1 ne $ShipmentData->{'address1'}
		or $OriginalAddress->address2 ne $ShipmentData->{'address2'}
		or $OriginalAddress->city ne $ShipmentData->{'addresscity'}
		or $OriginalAddress->state ne $ShipmentData->{'addressstate'}
		or $OriginalAddress->zip ne $ShipmentData->{'addresszip'}
		or $OriginalAddress->country ne $ShipmentData->{'addresscountry'})
		{
		$self->SendShipmentModifiedEmail($OriginalAddress,$ShipmentData);
		}
	}

sub SendShipmentModifiedEmail
	{
	my $self = shift;
	my $OriginalAddress = shift;
	my $ShipmentRef = shift;

	return;

	my $CO = $self->get_order;

	#send email if ship address is different than co address

	my $EmailInfo = {};
	$EmailInfo->{'fromemail'} = "intelliship\@intelliship.engagetechnology.com";
	$EmailInfo->{'fromname'} = 'NOC';
	$EmailInfo->{'toemail'} = $self->customerlosspreventemail;;
	$EmailInfo->{'toname'} = '';
	$EmailInfo->{'subject'} =  "NOTICE: " . $self->customer->customername . " Order Modified (" . $CO->ordernumber . " by " . $self->contact->contact->full_name . ")";
	#$EmailInfo->{'cc'} = 'noc@engagetechnology.com';

	my $ServerType; # 1 = production, 2 = beta, 3 = dev

	if ( $ServerType == 1 )
		{
		$EmailInfo->{'subject'} =  "TEST " . $EmailInfo->{'subject'};
		}

	my $BodyHash = {};
	$BodyHash->{'ordernumber'} = $CO->ordernumber;
	$BodyHash->{'orig_addressname'} = $OriginalAddress->addressname;
	$BodyHash->{'orig_address1'} = $OriginalAddress->address1;

	if ($OriginalAddress->address2 ne '')
		{
		$BodyHash->{'orig_address2'} = $OriginalAddress->address2;
		}

	$BodyHash->{'orig_addresscity'} = $OriginalAddress->city;
	$BodyHash->{'orig_addressstate'} = $OriginalAddress->state;
	$BodyHash->{'orig_addresszip'} = $OriginalAddress->zip;
	$BodyHash->{'orig_addresscountry'} = $OriginalAddress->country;

	$BodyHash->{'addressname'} = $ShipmentRef->{'addressname'};
	$BodyHash->{'address1'} = $ShipmentRef->{'address1'};

	if (defined($ShipmentRef->{'address2'}) && $ShipmentRef->{'address2'} ne '')
		{
		$BodyHash->{'address2'} = $ShipmentRef->{'address2'};
		}

	$BodyHash->{'addresscity'} = $ShipmentRef->{'addresscity'};
	$BodyHash->{'addressstate'} = $ShipmentRef->{'addressstate'};
	$BodyHash->{'addresszip'} = $ShipmentRef->{'addresszip'};
	$BodyHash->{'addresscountry'} = $ShipmentRef->{'addresscountry'};
	}

sub set_required_fields :Private
	{
	my $self = shift;
	my $page = shift;
	my $c = $self->context;
	my $Contact = $self->contact;
	my $Customer = $self->customer;

	return if $c->stash->{requiredfield_list};

	my $requiredList = [];

	my @custcondata_arr = $Customer->custcondata({ownertypeid => '1'});
	my %customerRules = map { $_->datatypename => $_->value } @custcondata_arr;
	#$c->log->debug("Customer->ID: " . $Customer->customerid . ", customerRules: " . Dumper %customerRules);
	if (!$page or $page eq 'address')
		{
		$requiredList = [
			{ name => 'fromemail',  details => "{ email: false }"},
			{ name => 'toname',     details => "{ minlength: 2 }"},
			{ name => 'toaddress1', details => "{ minlength: 2 }"},
			{ name => 'tocity',     details => " { minlength: 2 }"},
			{ name => 'tostate',    details => "{ minlength: 2 }"},
			{ name => 'tozip',      details => "{ minlength: 5 }"},
			{ name => 'tocountry',  details => "{ minlength: 2 }"},
			{ name => 'tophone',    details => "{ phone: false }"},
			{ name => 'toemail',    details => "{ email: false }"},
		];

		unless ($Contact->login_level == 25)
			{
			if ($c->stash->{one_page})
				{
				push(@$requiredList, { name => 'datetoship', details => "{ date: true }"})    if $customerRules{'reqdatetoship'} and $Customer->allowpostdating;
				push(@$requiredList, { name => 'dateneeded', details => "{ date: true }"})    if $customerRules{'reqdateneeded'};

				push(@$requiredList, { name => 'ponumber',    details => "{ minlength: 2 }"}) if $customerRules{'reqponum'};
				push(@$requiredList, { name => 'ordernumber', details => "{ minlength: 2 }"}) if $customerRules{'reqordernumber'};
				push(@$requiredList, { name => 'extid',    details => "{ minlength: 2 }"})    if $customerRules{'reqextid'};
				push(@$requiredList, { name => 'custref2', details => "{ minlength: 2 }"})    if $customerRules{'reqcustref2'};
				push(@$requiredList, { name => 'custref3', details => "{ minlength: 2 }"})    if $customerRules{'reqcustref3'};
				}

			push(@$requiredList, { name => 'tocustomernumber', details => "{ minlength: 2 }"}) if $customerRules{'reqcustnum'};
			push(@$requiredList, { name => 'fromdepartment',   details => "{ minlength: 2 }"}) if $customerRules{'reqdepartment'};
			}
		}

	if (!$page or $page eq 'shipment')
		{
		unless ($Contact->login_level == 25 or $c->stash->{one_page})
			{
			push(@$requiredList, { name => 'datetoship', details => "{ date: true }"}) if $customerRules{'reqdatetoship'} and $Customer->allowpostdating;
			push(@$requiredList, { name => 'dateneeded', details => "{ date: true }"}) if $customerRules{'reqdateneeded'};
			}

		push(@$requiredList, { name => 'package-detail-list', details => "{ method: validatePackageDetails }"})
		}

	#$c->log->debug("requiredfield_list: " . Dumper $requiredList);
	$c->stash->{requiredfield_list} = $requiredList;
	}

sub clear_CO_details :Private
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	$c->log->debug("___ clear_CO_details ___");

	my $stashRef = $c->stash;
	delete $params->{$_} foreach keys %$params;
	delete $stashRef->{$_} foreach keys %$stashRef;
	}

sub display_error_details :Private
	{
	my $self = shift;
	my $msg = shift;

	my $c = $self->context;

	$c->stash($c->req->params);
	$c->stash(MESSAGE => $msg);
	$c->stash(template => "templates/customer/order-error.tt");
	}

sub get_auto_order_number :Private
	{
	my $self = shift;
	my $OrderNumber = shift || '';

	my $c = $self->context;
	my $MyDBI = $c->model('MyDBI');
	my $CustomerID = $self->customer->customerid;

	# see if a customer sequence exists for the order number
	my $SQL = "SELECT count(*) from pg_class where relname = lower('ordernumber_" . $CustomerID . "_seq')";

	#$c->log->debug("SQL: " . $SQL);

	my $STH = $MyDBI->select($SQL);
	my $HasAutoOrderNumber = $STH->fetchrow(0)->{'count'};

	# get order number if one is needed
	if ($HasAutoOrderNumber and !$OrderNumber)
		{
		my $sql = "SELECT nextval('ordernumber_" . $CustomerID . "_seq')";
		my $sth = $MyDBI->select($sql);
		$OrderNumber = "QS" . $sth->fetchrow(0)->{'nextval'};
		}

	#$c->log->debug("HasAutoOrderNumber=$HasAutoOrderNumber, OUT ordernumber=$OrderNumber");

	return $OrderNumber;
	}

sub generate_packing_list
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	$c->log->debug("___ generate_packing_list ___");

	my $Shipment = $c->model('MyDBI::Shipment')->find({ shipmentid => $params->{'shipmentid'} });
	my $CO       = $Shipment->CO;
	my $Customer = $CO->customer;

	# Set global packing list values
	$c->stash($Shipment->{_column_data});
	$c->stash->{'contactname'}    = $CO->contactname;
	$c->stash->{'ordernumber'}    = $CO->ordernumber;
	$c->stash->{'dateshipped'}    = IntelliShip::DateUtils->american_date($Shipment->dateshipped);
	$c->stash->{'carrierservice'} = $Shipment->carrier . ' - ' . $Shipment->service;
	$c->stash->{'totalpages'}     = 1;
	$c->stash->{'currentpage'}    = 1;

	# Origin Address
	if (my $OAAddress = $Shipment->origin_address)
		{
		my $shipper_address = $OAAddress->addressname;
		$shipper_address   .= "<br>" . $OAAddress->address1 if $OAAddress->address1;
		$shipper_address   .= " " . $OAAddress->address2    if $OAAddress->address2;
		$shipper_address   .= "<br>" . $OAAddress->city     if $OAAddress->city;
		$shipper_address   .= ", " . $OAAddress->state      if $OAAddress->state;
		$shipper_address   .= "  " . $OAAddress->zip        if $OAAddress->zip;
		$shipper_address   .= "<br>" . $OAAddress->country  if $OAAddress->country;

		$shipper_address   .= "<br>" . $Shipment->oacontactphone       if $Shipment->oacontactphone;
		$shipper_address   .= "<br>" . $Shipment->deliverynotification if $Shipment->deliverynotification;

		$c->stash->{'shipperaddress'} = $shipper_address;
		}

	# Destination Address
	if (my $DAAddress = $Shipment->destination_address)
		{
		my $consignee_address = $DAAddress->addressname;
		$consignee_address   .= "<br>" . $DAAddress->address1 if $DAAddress->address1;
		$consignee_address   .= " " . $DAAddress->address2    if $DAAddress->address2;
		$consignee_address   .= "<br>" . $DAAddress->city     if $DAAddress->city;
		$consignee_address   .= ", " . $DAAddress->state      if $DAAddress->state;
		$consignee_address   .= "  " . $DAAddress->zip        if $DAAddress->zip;
		$consignee_address   .= "<br>" . $DAAddress->country  if $DAAddress->country;

		$consignee_address   .= "<br>" . $Shipment->contactphone         if $Shipment->contactphone;
		$consignee_address   .= "<br>" . $Shipment->shipmentnotification if $Shipment->shipmentnotification;

		$c->stash->{'consigneeaddress'} = $consignee_address;
		}

	# # Billing Address
	my $CSValueRef = $self->API->get_CS_shipping_values($Shipment->customerserviceid, $CO->customerid);

	my $webaccount;
	if ( $CSValueRef->{'webaccount'} )
		{
		$webaccount = $CSValueRef->{'webaccount'};
		}

	my $BillingAddressInfo = $self->GetBillingAddressInfo(
			$Shipment->customerserviceid,
			$webaccount,
			$Customer->customername,
			$Customer->customerid,
			$Shipment->billingaccount,
			$Shipment->freightcharges,
			$Shipment->addressiddestin,
			undef,
			$CSValueRef->{'baaddressid'}
			);

	if ( $BillingAddressInfo )
		{
		my $billingaddress = $BillingAddressInfo->{'addressname'};
		$billingaddress   .= "<br>" . $BillingAddressInfo->{'address1'} if $BillingAddressInfo->{'address1'};
		$billingaddress   .= " " . $BillingAddressInfo->{'address2'} if $BillingAddressInfo->{'address2'};
		$billingaddress   .= "<br>" . $BillingAddressInfo->{'city'} if $BillingAddressInfo->{'city'};
		$billingaddress   .= ", " . $BillingAddressInfo->{'state'} if $BillingAddressInfo->{'state'};
		$billingaddress   .= "  " . $BillingAddressInfo->{'zip'} if $BillingAddressInfo->{'zip'};
		$billingaddress   .= "<br>" . $BillingAddressInfo->{'country'} if $BillingAddressInfo->{'country'};

		$c->stash->{'billingaddress'} = $billingaddress;
		$c->stash->{'addressname'}   .= " ($BillingAddressInfo->{'billingaccount'})" if $BillingAddressInfo->{'billingaccount'};
		}

	##########################
	## Set line item values ##
	##########################
	my @packages = $Shipment->packages;

	my ($gross_weight,$quantity,$product_statusid) = (0,0,0);

	my $packinglist_loop = [];
	foreach my $Package (@packages)
		{
		# Use shipment package data for # of packages, weights, and the like
		my $weight = ($Package->dimweight > $Package->weight ? $Package->dimweight : $Package->weight);

		$gross_weight += $weight;
		$quantity     += $Package->quantity;

		(my $shipment_section_ref,$product_statusid) = $self->GetLineItems($Package);

		foreach my $key (sort { $a <=> $b } keys %$shipment_section_ref)
			{
			push(@$packinglist_loop, $shipment_section_ref->{$key});
			}
		}

	my $items = (14 - @$packinglist_loop);
	if ($items > 0)
		{
		push(@$packinglist_loop, {}) while $items--;
		}

	$c->stash->{packinglist_loop} = $packinglist_loop;
	$c->stash->{grossweight}      = $gross_weight;
	$c->stash->{quantity}         = $quantity;

	if ( $product_statusid == 2 )
		{
		$c->stash->{datefullfilled} = IntelliShip::DateUtils->american_date($Shipment->dateshipped);
		}

	## print commercial invoice only for international shipment
	$c->stash->{printcominv} = $self->contact->get_contact_data_value('defaultcomminv') if $Shipment->is_international;

	my $CustomerService = $self->API->get_hashref('CUSTOMERSERVICE',$Shipment->customerserviceid);
	my $Service = $self->API->get_hashref('SERVICE',$CustomerService->{'serviceid'});

	if ($Service->{'webhandlername'} =~ /handler_web_efreight/)
		{
		$params->{'carrier'} = &CARRIER_EFREIGHT;
		}
	elsif ($Service->{'webhandlername'} =~ /handler_local_generic/ && $Shipment->carrier ne &CARRIER_USPS)
		{
		$params->{'carrier'} = &CARRIER_GENERIC;
		}

	## print BOL only for Generic and eFreight
	if ($params->{'carrier'} eq &CARRIER_GENERIC || $params->{'carrier'} eq &CARRIER_EFREIGHT)
		{
		$c->stash->{billoflading} = $self->contact->get_contact_data_value('print8_5x11bol');
		}

	my $list_type = $self->contact->get_contact_data_value('packinglist');
	$list_type = 'generic' unless $list_type =~ /sprint/i;

	if ($list_type =~ /sprint/i)
		{
		my $barcode_image = IntelliShip::Utils->generate_UCC_128_barcode($Shipment->tracking1);
		$c->stash->{'barcode_image'} = '/print/barcode/' . $Shipment->tracking1 . '.png' if -e $barcode_image;
		$self->setup_label_to_print ;
		}

	my $template = 'order-packing-list-' . $list_type . '.tt';

	## Render Packing List HTML
	my $PackListHTML = $c->forward($c->view('Ajax'), "render", [ "templates/customer/" . $template ]);

	## Save packinglist invoice to File
	my $PackListFileName = IntelliShip::MyConfig->packing_list_directory . '/' . $Shipment->shipmentid;

	$self->SaveStringToFile($PackListFileName, $PackListHTML);

	$c->stash(template => "templates/customer/" . $template);

	return $PackListHTML;
	}

sub GetLineItems
	{
	my $self = shift;
	my $PackProData = shift;

	my $package_id  = $PackProData->packprodataid;
	my $shipment_id = $PackProData->ownerid;

	# First check order-centric/pick & pack data
	my ($product_ref,$product_statusid) = $self->GetOrderProductData($package_id,$shipment_id);

	$self->context->log->debug("GetOrderProductData: " . Dumper $product_ref);

	# Then check shipment products
	if ( !exists($product_ref->{0}) )
		{
		($product_ref,$product_statusid) = $self->GetShipmentProductData($package_id,$shipment_id);
		$self->context->log->debug("GetShipmentProductData: " . Dumper $product_ref);
		}

	# Finish off with shipment package
	if ( !exists($product_ref->{0}) )
		{
		$product_ref->{0} = {
			partnumber			=> $PackProData->partnumber,
			orderedqty			=> $PackProData->quantity,
			shippedqty			=> $PackProData->shippedqty,
			remainingqty		=> 0,
			productdescription	=> $PackProData->description,
			nmfc				=> $PackProData->nmfc,
			unittypeid			=> $PackProData->unittypeid,
			decval				=> $PackProData->decval,
			};

		$product_ref->{0} = $self->GetComInvPackData($product_ref->{0},$shipment_id);

		$product_statusid = 2;

		#$self->context->log->debug("final details: " . Dumper $product_ref);
		}

	return ($product_ref,$product_statusid);
	}

sub GetOrderProductData
	{
	my $self = shift;
	my $shippack_id = shift;
	my $shipment_id = shift;

	my $sql = "
		SELECT
			(p2.quantity + p1.shippedqty) as orderedqty,
			p1.shippedqty as shippedqty,
			p2.quantity as remainingqty,
			p1.description as productdescription,
			p1.partnumber,
			p2.statusid,
			p1.unittypeid,
			p1.partnumber,
			p1.nmfc,
			p1.decval
		FROM
			packprodata p1
			INNER JOIN packprodata p2 ON p2.packprodataid = p1.poppdid
		WHERE
			p1.ownerid = '$shippack_id'
			AND p2.statusid IN (1,2)
		ORDER BY
			p2.datecreated
	";

	my $STH = $self->myDBI->select($sql);

	my $product_ref = {};
	my $product_statusid = 2;
	for (my $row=0; $row < $STH->numrows; $row++)
		{
		my $product_data = $STH->fetchrow($row);
		$product_data = $self->GetComInvPackData($product_data,$shipment_id);

		$product_statusid    = 1 if $product_data->{'statusid'} < 2;
		$product_ref->{$row} = $product_data;
		}

	return ($product_ref,$product_statusid);
	}

sub GetShipmentProductData
	{
	my $self = shift;
	my $shippack_id = shift;
	my $shipment_id = shift;

	my $sql = "
		SELECT
			shippedqty as orderedqty,
			shippedqty as shippedqty,
			0 as remainingqty,
			description as productdescription,
			partnumber,
			2 as statusid,
			unittypeid,
			partnumber,
			nmfc,
			decval
		FROM
			packprodata
		WHERE
			ownerid = '$shippack_id'
		ORDER BY
			datecreated
	";

	my $STH = $self->myDBI->select($sql);

	my $product_ref = {};
	my $product_statusid = 2;
	for (my $row=0; $row < $STH->numrows; $row++)
		{
		my $product_data = $STH->fetchrow($row);
		$product_data = $self->GetComInvPackData($product_data,$shipment_id);

		$product_statusid    = 1 if $product_data->{'statusid'} < 2;
		$product_ref->{$row} = $product_data;
		}

	return ($product_ref,$product_statusid);
	}

sub GetComInvPackData
	{
	my $self = shift;
	my $product_data = shift;
	my $shipment_id = shift;

	# Additions to handle commercial invoice side of things
	my $STH = $self->myDBI->select("SELECT manufacturecountry FROM shipment WHERE shipmentid = '$shipment_id'");
	my $ManufactureCountry = ($STH->numrows ? $STH->fetchrow(0)->{'manufacturecountry'} : '');

	$product_data->{'packagedescription'}  = $product_data->{'productdescription'};
	$product_data->{'packagedescription'} .= ", $product_data->{'partnumber'}" if $product_data->{'partnumber'};
	$product_data->{'packagedescription'} .= ", $product_data->{'nmfc'}" if $product_data->{'nmfc'};
	$product_data->{'packagedescription'} .= ", " . $ManufactureCountry if $ManufactureCountry;

	my $UnitTypeName = '';
	if ($product_data->{'unittypeid'})
		{
		$STH = $self->myDBI->select("SELECT unittypename FROM unittype WHERE unittypeid = '$product_data->{'unittypeid'}'");
		$UnitTypeName = ($STH->numrows ? $STH->fetchrow(0)->{'unittypename'} : '');
		}

	$product_data->{'packagequantity'}  = $product_data->{'shippedqty'};
	$product_data->{'packagequantity'} .= " " . $UnitTypeName;
	$product_data->{'packagequantity'} .= "e" if $product_data->{'unittypeid'} == 3; # Eaches needs the 'e' for plural
	$product_data->{'packagequantity'} .= "s" if $product_data->{'shippedqty'} > 1;

	$product_data->{'goodscost'} = $product_data->{'decval'};

	return $product_data;
	}

sub generate_bill_of_lading
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	$c->log->debug("___ generate_bill_of_lading ___");

	my $Shipment = $c->model('MyDBI::Shipment')->find({ shipmentid => $params->{'shipmentid'} });
	my $CO       = $Shipment->CO;
	my $Customer = $CO->customer;

	## Set global packing list values
	my $dataHash = $Shipment->{_column_data};
	$dataHash->{'contactname'}    = $CO->contactname;
	$dataHash->{'ordernumber'}    = $CO->ordernumber;
	$dataHash->{'dateshipped'}    = IntelliShip::DateUtils->american_date($Shipment->dateshipped);
	$dataHash->{'carrierservice'} = $Shipment->carrier . ' - ' . $Shipment->service;
	$dataHash->{'totalpages'}     = 1;
	$dataHash->{'currentpage'}    = 1;

	## Destination Address
	if (my $DestinationAddress = $Shipment->destination_address)
		{
		$dataHash->{'addressname'}    = $DestinationAddress->addressname;
		$dataHash->{'address1'}       = $DestinationAddress->address1;
		$dataHash->{'address2'}       = $DestinationAddress->address2;
		$dataHash->{'addresscity'}    = $DestinationAddress->city;
		$dataHash->{'addressstate'}   = $DestinationAddress->state;
		$dataHash->{'addresszip'}     = $DestinationAddress->zip;
		$dataHash->{'addresscountry'} = $DestinationAddress->country;
		}

	## Origin Address
	if (my $OriginatingAddress = $Shipment->origin_address)
		{
		$dataHash->{'branchaddress1'}       = $OriginatingAddress->address1;
		$dataHash->{'branchaddress2'}       = $OriginatingAddress->address2;
		$dataHash->{'branchaddresscity'}    = $OriginatingAddress->city;
		$dataHash->{'branchaddressstate'}   = $OriginatingAddress->state;
		$dataHash->{'branchaddresszip'}     = $OriginatingAddress->zip;
		$dataHash->{'branchaddresscountry'} = $OriginatingAddress->country;
		}

	my $bol_type = $self->contact->get_contact_data_value('boltype');

	## Billing Address
	if ($bol_type =~ /bolvisionship/)
		{
		my $CSValueRef = $self->API->get_CS_shipping_values($Shipment->customerserviceid,$Customer->customerid);
		my $BillingAddressInfo = $self->GetBillingAddressInfo(
				$Shipment->customerserviceid,
				undef,
				undef,
				$Customer->customerid,
				$Shipment->billingaccount,
				$Shipment->freightcharges,
				$Shipment->addressiddestin,
				undef,
				$CSValueRef->{'baaddressid'}
				);

		if ($BillingAddressInfo)
			{
			$dataHash->{'billingname'}     = uc $BillingAddressInfo->{'addressname'};
			$dataHash->{'billingaddress1'} = uc $BillingAddressInfo->{'address1'};
			$dataHash->{'billingaddress2'} = uc $BillingAddressInfo->{'address2'};
			$dataHash->{'billingcity'}     = uc $BillingAddressInfo->{'city'};
			$dataHash->{'billingstate'}    = uc $BillingAddressInfo->{'state'};
			$dataHash->{'billingzip'}      = uc $BillingAddressInfo->{'zip'};
			}

		my $CSRef = $self->API->get_hashref('CUSTOMERSERVICE',$Shipment->customerserviceid);
		my $SRef  = $self->API->get_hashref('SERVICE',$CSRef->{'serviceid'});
		my $CARef = $self->API->get_hashref('CARRIER',$SRef->{'carrierid'});

		$dataHash->{'scac'} = $CARef->{'scac'};
		}
	elsif ($Shipment->freightcharges == 1 or $Shipment->freightcharges == 2)
		{
		my $BillingAddressInfo = $self->GetBillingAddressInfo(
				$Shipment->customerserviceid,
				undef,
				undef,
				$Customer->customerid,
				$Shipment->billingaccount,
				$Shipment->freightcharges,
				$Shipment->addressiddestin
				);

		if ($BillingAddressInfo)
			{
			$dataHash->{'billingname'}     = $BillingAddressInfo->{'addressname'};
			$dataHash->{'billingaddress1'} = $BillingAddressInfo->{'address1'};
			$dataHash->{'billingaddress2'} = $BillingAddressInfo->{'address2'};
			$dataHash->{'billingcity'}     = $BillingAddressInfo->{'city'};
			$dataHash->{'billingstate'}    = $BillingAddressInfo->{'state'};
			$dataHash->{'billingzip'}      = $BillingAddressInfo->{'zip'};
			}

		if ($Shipment->billingaccount)
			{
			$dataHash->{'addressname'} .= " (" . $Shipment->billingaccount . ")";
			}
		}
	elsif ($CO->usealtsop and $CO->usealtsop == 1)
		{
		my $BillingAddressInfo = $self->GetBillingAddressInfo(
				$Shipment->customerserviceid,
				undef,
				undef,
				undef,
				undef,
				undef,
				undef,
				$Shipment->custnum
				);

		if ( $BillingAddressInfo )
			{
			$dataHash->{'billingname'} = $BillingAddressInfo->{'addressname'};

			if ($params->{'sibling'})
				{
				$dataHash->{'billingaddress1'} = 'c/o Engage Technology';
				$dataHash->{'billingaddress2'} = '3400 Players Club Parkway, Suite 150';
				$dataHash->{'billingcity'}     = 'Memphis';
				$dataHash->{'billingstate'}    = 'TN';
				$dataHash->{'billingzip'}      = '38125';
				}
			else
				{
				$dataHash->{'billingaddress1'} = $BillingAddressInfo->{'address1'};
				$dataHash->{'billingaddress2'} = $BillingAddressInfo->{'address2'};
				$dataHash->{'billingcity'}     = $BillingAddressInfo->{'city'};
				$dataHash->{'billingstate'}    = $BillingAddressInfo->{'state'};
				$dataHash->{'billingzip'}      = $BillingAddressInfo->{'zip'};
				}
			}
		}
 	else
		{
		my $CSValueRef = $self->API->get_CS_shipping_values($Shipment->customerserviceid, $CO->customerid);

		my $webaccount = $CSValueRef->{'webaccount'};

		$dataHash->{'billingname'}     = IntelliShip::Utils->get_bill_to_name($webaccount, $self->customer->customername);
		$dataHash->{'billingaddress1'} = 'c/o Engage Technology';
		$dataHash->{'billingaddress2'} = '3400 Players Club Parkway, Suite 150';
		$dataHash->{'billingcity'}     = 'Memphis';
		$dataHash->{'billingstate'}    = 'TN';
		$dataHash->{'billingzip'}      = '38125';
		}

	################################################
	## Sort out kooky cs specific 'Bill To' names ##
	################################################
	if (my $hack_bill_to_name = IntelliShip::Utils->get_BOL_bill_to_name($Shipment->customerserviceid))
		{
		$dataHash->{'billtoname'} = $hack_bill_to_name;
		}

	## Global Order Info
	$dataHash->{'branchphone'}   = $CO->dropphone ? $CO->dropphone : $Shipment->oacontactphone;
	$dataHash->{'branchcontact'} = $CO->dropcontact ? $CO->dropcontact : $Shipment->oacontactname;
	$dataHash->{'extcustnum'}    = $CO->extcustnum if $CO->extcustnum;

	#$dataHash->{'dateshipped'} =~ s/(\d{4})-(\d{2})-(\d{2}) \d{2}:\d{2}:\d{2}.*/$2\/$3\/$1/;
	$dataHash->{'dateshipped'}   = IntelliShip::DateUtils->american_date($dataHash->{'dateshipped'});

	####################################################
	## Build up data for use in BOL assessorial display
	####################################################
	my ($selectedSpecialServices, $SpecialServiceList) = ({},[]);

	my @assessorials = $Shipment->assessorials;
	$selectedSpecialServices->{$_->assname} = 1 foreach @assessorials;

	my $AssRef = $self->API->get_sop_asslisting($Customer->get_sop_id);
	my @ass_names = split(/\t/,$AssRef->{'assessorial_names'});
	my @ass_displays = split(/\t/,$AssRef->{'assessorial_display'});

	for (my $row = 0; $row < scalar @ass_names; $row++)
		{
		my $ass_name = $ass_names[$row];
		my $ass_data = { name => $ass_name, displayname => $ass_displays[$row] };
		$ass_data->{checked} = 1 if $selectedSpecialServices->{$ass_name};

		push @$SpecialServiceList, $ass_data;
		}

	$dataHash->{assessorial_loop} = $SpecialServiceList;

	$dataHash->{bol_packagelist_loop} = $self->GetBOLorPOPPD($Shipment, $dataHash);

	unless ($Shipment->tracking1)
		{
		$dataHash->{'tracking1'} = 'PLACE PRO LABEL HERE';
		}
	else
		{
		my $barcode_image = IntelliShip::Utils->generate_UCC_128_barcode($Shipment->tracking1);
		$dataHash->{'barcode_image'} = '/print/barcode/' . $Shipment->tracking1 . '.png' if -e $barcode_image;
		}

	my @LTLAccessorials = qw( codfee collectfreightcharge podservice singleshipment );

	foreach my $LTLAccessorial (@LTLAccessorials)
		{
		if ($dataHash->{$LTLAccessorial} && $dataHash->{$LTLAccessorial} =~ /,/)
			{
			undef $dataHash->{$LTLAccessorial};
			}
		}

	## Customer specific bol settings
	my $BASE_DOMAIN = IntelliShip::MyConfig->getBaseDomain;
	my $customer_bol_logo   = '';#$self->customer->bol_logo;
	my $customer_bol_width  = '';#$self->customer->bol_logo_width;
	my $customer_bol_height = '';#$self->customer->bol_logo_height;

	$dataHash->{'bol_image'}       = '/static/images/bol.jpg';
	$dataHash->{'bol_logo'}        = $customer_bol_logo   ? $customer_bol_logo : 'intelliship_logo.png';
	$dataHash->{'bol_logo_width'}  = $customer_bol_width  ? $customer_bol_width : '190';
	$dataHash->{'bol_logo_height'} = $customer_bol_height ? $customer_bol_height : '31';
	$dataHash->{'bol_url_phone'}   = $customer_bol_logo   ? '' : '<br><font color="#000000" size="1" face="Arial, Helvetica, sans-serif"><b>&nbsp;&nbsp;&nbsp;&nbsp;WWW.' . uc($BASE_DOMAIN) . '.COM&nbsp;&nbsp;901.620.6788</b></font></td>';

	$c->stash($dataHash);
	$self->get_branding_id;

	## Render BOL HTML
	my $BOL_HTML = $c->forward($c->view('Ajax'), "render", [ "templates/customer/order-bol.tt" ]);

	## Save BOL to File
	my $BOLFileName = IntelliShip::MyConfig->BOL_file_directory . '/' . $Shipment->shipmentid;

	$self->SaveStringToFile($BOLFileName, $BOL_HTML);

	if ($params->{'fromscreen'} && $params->{'fromscreen'} eq 'web_api')
		{
		$dataHash->{'bolstring'} = $BOL_HTML;
		}

	## print commercial invoice only for international shipment
	$c->stash->{printcominv} = $self->contact->get_contact_data_value('defaultcomminv') if $Shipment->is_international;

	$c->stash(template => "templates/customer/order-" . $bol_type . ".tt");

	return $BOL_HTML;
	}

sub GetBOLorPOPPD
	{
	my $self = shift;
	my $Shipment = shift;
	my $dataHash = shift;

	my $PackageProductList = [];

	# Does the shipment have packges?
	$dataHash->{'packagetotaldescription'} = '';
	$dataHash->{'boldetail'} = $self->contact->get_contact_data_value('boldetail');

	my $CO = $Shipment->CO;
	my @packages = $Shipment->packages;

	$self->context->log->debug("Total Packages: " . @packages);

	foreach my $Package (@packages)
		{
		## Dimension display
		my $packageData = $Package->{_column_data};
		if ($Package->dimlength && $Package->dimwidth  && $Package->dimheight)
			{
			$packageData->{'dims'} = $Package->dimlength . 'x' . $Package->dimwidth . 'x' . $Package->dimheight;
			}

		# Unit display
		if ($Package->unittypeid)
			{
			my $unit_type = $Package->unittype->unittypename;
			$packageData->{'unittype'} = $unit_type;
			unless ($dataHash->{'packagetotalunittype'})
				{
				$dataHash->{'packagetotalunittype'} = $unit_type;
				}
			elsif ($dataHash->{'packagetotalunittype'} ne $unit_type)
				{
				$dataHash->{'packagetotalunittype'} = 'Multiple';
				}
			}

		## Hazard check
		if ($CO->hazardous)
			{
			$dataHash->{'hazardcheck'} = 'Checked';
			$dataHash->{'packagetotalhazardcheck'} = 'Checked';
			}

		if ($Package->class)
			{
			$dataHash->{'freightclass'} = $Package->class;
			}
		else
			{
			$dataHash->{'freightclass'} = $dataHash->{'service'};
			}

		## Figure package total weight
		if ($dataHash->{'quantityxweight'})
			{
			$dataHash->{'packagetotalweight'} += $Package->weight * $Package->quantity;
			}
		else
			{
			$dataHash->{'packagetotalweight'} += $Package->weight;
			}

		$dataHash->{'packagetotalquantity'} += $Package->quantity;
		$dataHash->{'packagetotaldims'}      = '';

		## Add packages to display list if 'summary' bol detail needed
		if ($dataHash->{'boldetail'} == 2 || $dataHash->{'boldetail'} == 3)
			{
			push(@$PackageProductList, $packageData);
			}

		# Get products - only if sku level detail needed
		if ($dataHash->{'boldetail'} == 1 || $dataHash->{'boldetail'} == 2)
			{
			my @products = $Package->products;

			foreach my $Product (@products)
				{
				# Unit display
				my $productData = $Product->{_column_data};
				my $UnitType = $Product->unittype;
				$productData->{'unittype'} = $UnitType->unittypename if $UnitType;
				if ($Product->dimlength and $Product->dimwidth and $Product->dimheight)
					{
					$productData->{'dims'} = $Product->dimlength . 'x' . $Product->dimwidth . 'x' . $Product->dimheight;
					}

				push(@$PackageProductList, $productData);
				}
			}
		}

	$self->context->log->debug("PackageProductList Count: " . @$PackageProductList);

	return $PackageProductList;
	}

sub generate_commercial_invoice
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	$c->log->debug("___ generate_bill_of_lading ___");

	my $Shipment = $c->model('MyDBI::Shipment')->find({ shipmentid => $params->{'shipmentid'} });
	my $CO       = $Shipment->CO;
	my $Customer = $CO->customer;

	## Set global packing list values
	my $dataHash = $Shipment->{_column_data};

	$dataHash->{'dateshipped'} = IntelliShip::DateUtils->american_date($Shipment->dateshipped);

	$dataHash->{'mode'} = $self->API->get_mode($Shipment->carrier, $Shipment->service);

	$dataHash->{'today'} = IntelliShip::DateUtils->american_date(IntelliShip::DateUtils->current_date);

	$dataHash->{'prepaid'} = $Shipment->freightcharges ? '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;' : '&nbsp;&nbsp;X&nbsp;&nbsp;';
	$dataHash->{'collect'} = $Shipment->freightcharges ? '&nbsp;&nbsp;X&nbsp;&nbsp;'      : '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;';

	$dataHash->{'ordernumber'} = $CO->ordernumber;

	###########################################################
	## Shipment Address
	###########################################################
	my $OAAddress;
	if ($OAAddress = $CO->route_to_address)
		{
		my $shipper_address = $OAAddress->addressname;
		$shipper_address   .= "<br>" . $OAAddress->address1 if $OAAddress->address1;
		$shipper_address   .= " " . $OAAddress->address2    if $OAAddress->address2;
		$shipper_address   .= "<br>" . $OAAddress->city     if $OAAddress->city;
		$shipper_address   .= ", " . $OAAddress->state      if $OAAddress->state;
		$shipper_address   .= "  " . $OAAddress->zip        if $OAAddress->zip;
		$shipper_address   .= "<br>" . $OAAddress->country  if $OAAddress->country;

		$dataHash->{'shipperaddress'}  = $shipper_address;

		$dataHash->{'rtcontact'} = $CO->rtcontact;
		$dataHash->{'rtphone'}   = $CO->rtphone;

		if ($OAAddress->rtphone)
			{
			$dataHash->{'shipperphone'} .= $OAAddress->rtcontact . ' ' . $OAAddress->rtphone;
			}
		else
			{
			$dataHash->{'shipperphone'} .= "&nbsp;" . $Customer->contact . ' ' . $Customer->phone;
			}
		}
	elsif ($OAAddress = $Shipment->origin_address)
		{
		my $shipper_address = $OAAddress->addressname;
		$shipper_address   .= "<br>" . $OAAddress->address1 if $OAAddress->address1;
		$shipper_address   .= " " . $OAAddress->address2    if $OAAddress->address2;
		$shipper_address   .= "<br>" . $OAAddress->city     if $OAAddress->city;
		$shipper_address   .= ", " . $OAAddress->state      if $OAAddress->state;
		$shipper_address   .= "  " . $OAAddress->zip        if $OAAddress->zip;
		$shipper_address   .= "<br>" . $OAAddress->country  if $OAAddress->country;

		$dataHash->{'shipperaddress'} = $shipper_address;
		$dataHash->{'shipperphone'}   = $Shipment->oacontactphone       if $Shipment->oacontactphone;
		$dataHash->{'shipperemail'}   = $Shipment->deliverynotification if $Shipment->deliverynotification;
		}

	if (my $DAAddress = $Shipment->destination_address)
		{
		my $consignee_address = $DAAddress->addressname;
		$consignee_address   .= "<br>" . $DAAddress->address1 if $DAAddress->address1;
		$consignee_address   .= " " . $DAAddress->address2    if $DAAddress->address2;
		$consignee_address   .= "<br>" . $DAAddress->city     if $DAAddress->city;
		$consignee_address   .= ", " . $DAAddress->state      if $DAAddress->state;
		$consignee_address   .= "  " . $DAAddress->zip        if $DAAddress->zip;
		$consignee_address   .= "<br>" . $DAAddress->country  if $DAAddress->country;

		$dataHash->{'consigneeaddress'} = $consignee_address;

		$dataHash->{'consigneephone'} = $Shipment->contactphone;
		$dataHash->{'consigneeemail'} = $Shipment->shipmentnotification;
		}

	## Set line item values
	my @SC = $Shipment->shipment_charges;
	my ($freightcharge,$insurancecharge,$othercharge,$grandtotal) = (0,0,0,0);
	foreach my $ShipmentCharge (@SC)
		{
		next unless $ShipmentCharge->chargeamount;

		if ($ShipmentCharge->chargename =~ /Freight Charge/i)
			{
			$freightcharge += $ShipmentCharge->chargeamount;
			}
		elsif ($ShipmentCharge->chargename =~ /Insurance/i)
			{
			$insurancecharge += $ShipmentCharge->chargeamount;
			}
		else
			{
			$othercharge += $ShipmentCharge->chargeamount;
			}

		$grandtotal += $ShipmentCharge->chargeamount;
		}

	$dataHash->{'freightcharge'}   = sprintf("%.2f", $freightcharge);
	$dataHash->{'insurancecharge'} = sprintf("%.2f", $insurancecharge);
	$dataHash->{'othercharge'}     = sprintf("%.2f", $othercharge);

	my @packages = $Shipment->packages;

	my ($gross_weight,$quantity,$packinglist_loop)=(0,0,[]);
	foreach my $Package (@packages)
		{
		## Use shipment package data for # of packages, weights, and the like
		my $weight = ($Package->dimweight > $Package->weight ? $Package->dimweight : $Package->weight);
		$gross_weight += $weight;
		$quantity     += $Package->quantity;

		my($shipment_section_ref,$product_statusid) = $self->GetLineItems($Package);

		foreach my $key (sort { $a <=> $b } keys %$shipment_section_ref)
			{
			push(@$packinglist_loop, $shipment_section_ref->{$key});
			}
		}

	my $PackPro = $packages[0] if @packages;
	$dataHash->{'packinglist_loop'} = $packinglist_loop;
	$dataHash->{'dimensions'}       = $PackPro->dimheight . 'x' . $PackPro->dimwidth . 'x' . $PackPro->dimlength if $PackPro;
	$dataHash->{'grossweight'}      = $gross_weight;
	$dataHash->{'netweight'}        = $gross_weight;
	$dataHash->{'quantity'}         = $quantity;

	## Set Grand Total
	$dataHash->{'grandtotal'} = sprintf("%.2f", $grandtotal);

	$c->stash($dataHash);
	$self->get_branding_id;

	## Render Commercial Invoice HTML
	my $ComInvHTML = $c->forward($c->view('Ajax'), "render", [ "templates/customer/order-commercial-invoice.tt" ]);

	my $ComInvFileName = IntelliShip::MyConfig->commercial_invoice_directory . '/' . $Shipment->shipmentid;

	## Save commercial invoice to File
	$self->SaveStringToFile($ComInvFileName, $ComInvHTML);

	$c->stash(template => "templates/customer/order-commercial-invoice.tt");

	return $ComInvHTML;
	}

sub send_pickup_request
	{
	my $self = shift;
	my $Shipment = shift;

	my $c = $self->context;
	my $CO = $Shipment->CO;

	my $CustomerService = $self->API->get_hashref('CUSTOMERSERVICE',$Shipment->customerserviceid);
	my $Service         = $self->API->get_hashref('SERVICE',$CustomerService->{'serviceid'});

	my $carrier = $Shipment->carrier;
	if ($Service->{'webhandlername'} =~ /handler_web_efreight/)
		{
		$carrier = &CARRIER_EFREIGHT;
		}
	elsif ($Service->{'webhandlername'} =~ /handler_local_generic/ && $Shipment->carrier ne &CARRIER_USPS)
		{
		$carrier = &CARRIER_GENERIC;
		}

	my $Handler = IntelliShip::Carrier::Handler->new;
	$Handler->request_type(&REQUEST_TYPE_PICKUP_REQUEST);
	$Handler->token($self->get_login_token);
	$Handler->context($self->context);
	$Handler->contact($self->contact);
	$Handler->carrier($carrier);
	$Handler->customerservice($CustomerService);
	$Handler->service($Service);
	$Handler->CO($CO);
	$Handler->API($self->API);
	$Handler->SHIPMENT($Shipment);

	my $Response = $Handler->process_request({
			NO_TOKEN_OPTION => 1
			});

	$c->log->debug("....Response: " . $Response);
	}

sub create_return_shipment
	{
	my $self = shift;
	my $CO = shift;

	my $c = $self->context;
	my $Contact = $self->contact;

	my $RetCO = $c->model('MyDBI::CO')->new($CO->{_column_data});
	$RetCO->coid($self->get_token_id);
	$RetCO->ordernumber($RetCO->ordernumber . '-RTN');

	$RetCO->reset;

	$RetCO->dateneeded(undef);
	$RetCO->isinbound(1);
	$RetCO->insert;

	$c->log->debug(".... return shipment created, coid: " . $RetCO->coid);

	my @packages = $CO->packages;
	foreach my $Package (@packages)
		{
		my $RetPackage = $c->model('MyDBI::Packprodata')->new($Package->{_column_data});
		$RetPackage->packprodataid($self->get_token_id);
		$RetPackage->ownerid($RetCO->coid);
		$RetPackage->insert;

		my @products = $Package->products;
		foreach my $Product (@products)
			{
			my $RetProduct = $c->model('MyDBI::Packprodata')->new($Product->{_column_data});
			$RetProduct->packprodataid($self->get_token_id);
			$RetProduct->ownerid($RetPackage->packprodataid);
			$RetProduct->insert;
			}
		}

	return $RetCO;
	}

__PACKAGE__->meta->make_immutable;

1;
