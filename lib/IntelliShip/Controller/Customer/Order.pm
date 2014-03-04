package IntelliShip::Controller::Customer::Order;
use Moose;
use IO::File;
use Data::Dumper;
use POSIX qw(ceil);
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
	elsif ($do_value eq 'ship')
		{
		$self->SHIP_ORDER;
		}
	elsif ($do_value eq 'cancel')
		{
		$self->void_shipment;
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
	if ($do_value eq 'ship')
		{
		$self->SHIP_ORDER;
		}
	elsif ($do_value eq 'cancel')
		{
		$self->void_shipment;
		$self->setup_one_page;
		}
	else
		{
		$self->setup_one_page;
		$c->stash->{quickship} = 1;
		}
	}

sub setup_one_page :Private
	{
	my $self = shift;
	my $c = $self->context;

	my $CO = $self->get_order;
	if ($CO->can_autoship and $self->customer->get_contact_data_value('autoprocess'))
		{
		$c->log->debug("Auto Shipping Order, ID: " . $CO->coid);
		return $self->SHIP_ORDER;
		}

	$c->stash->{one_page} = 1;

	#DYNAMIC FIELD VALIDATIONS
	$self->set_required_fields;

	$self->setup_address;
	$c->stash(ADDRESS_SECTION => $c->forward($c->view('Ajax'), "render", [ "templates/customer/order-address.tt" ]));

	$self->setup_shipment_information;
	$c->stash(SHIPMENT_SECTION => $c->forward($c->view('Ajax'), "render", [ "templates/customer/order-shipment.tt" ]));

	$self->setup_carrier_service;
	$c->stash(CARRIER_SERVICE_SECTION => $c->forward($c->view('Ajax'), "render", [ "templates/customer/order-carrier-service.tt" ]));

	$c->stash(template => "templates/customer/order-one-page.tt");
	}

sub setup_address :Private
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	my $Contact = $self->contact;
	my $Customer = $self->customer;

	my $CO = $self->get_order;

	my $do = $c->req->param('do') || '';
	if (!$do or $do eq 'address')
		{
		$c->stash->{populate} = 'address';
		$self->populate_order;
		}

	$c->stash->{fromCustomer} = $Customer;
	$c->stash->{fromCustomerAddress} = $Customer->address;
	$c->stash->{AMDELIVERY} = 1 if $Customer->amdelivery;
	$c->stash->{ordernumber} = ($params->{'ordernumber'} ? $params->{'ordernumber'} : $CO->coid) unless $c->stash->{ordernumber};
	$c->stash->{customerlist_loop} = $self->get_select_list('ADDRESS_BOOK_CUSTOMERS');
	$c->stash->{countrylist_loop} = $self->get_select_list('COUNTRY');
	$c->stash->{statelist_loop} = $self->get_select_list('US_STATES');

	if ($c->stash->{one_page})
		{
		$c->stash->{deliverymethod} = '0';
		$c->stash->{deliverymethod_loop} = $self->get_select_list('DELIVERY_METHOD') ;
		}

	$c->stash->{tooltips} = $self->get_tooltips;

	#DYNAMIC INPUT FIELDS VISIBILITY
	unless ($Customer->login_level == 25)
		{
		$c->stash->{SHOW_PONUMBER} = $Customer->get_contact_data_value('reqponum');
		$c->stash->{SHOW_EXTID}    = $Customer->get_contact_data_value('reqextid');
		$c->stash->{SHOW_CUSTREF2} = $Customer->get_contact_data_value('reqcustref2');
		$c->stash->{SHOW_CUSTREF3} = $Customer->get_contact_data_value('reqcustref3');
		}

	#DYNAMIC FIELD VALIDATIONS
	$self->set_required_fields('address');

	$c->stash->{tocountry}  = "US";
	$c->stash->{fromemail}  = $Contact->email unless $c->stash->{fromemail};
	$c->stash->{department} = $Contact->department unless $c->stash->{department};
	$c->stash->{fromcontact}= $Contact->full_name unless $c->stash->{fromcontact};
	$c->stash->{fromphone}  = $Contact->phonebusiness unless $c->stash->{fromphone};

	$c->stash(template => "templates/customer/order-address.tt");
	}

sub setup_shipment_information :Private
	{
	my $self = shift;
	my $c = $self->context;

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

	if ($Customer->address->country ne $CO->to_address->country)
		{
		$c->log->debug("... customer address and drop address not same, INTERNATIONAL shipment");
		my $CA = IntelliShip::Controller::Customer::Order::Ajax->new;
		$CA->context($c);
		$CA->set_international_details;
		$c->stash->{INTERNATIONAL_AND_COMMODITY} = $c->forward($c->view('Ajax'), "render", [ "templates/customer/order-ajax.tt" ]);
		}

	unless ($c->stash->{one_page})
		{
		$c->stash->{deliverymethod} = '0';
		$c->stash->{deliverymethod_loop} = $self->get_select_list('DELIVERY_METHOD');
		}

	$c->stash->{default_package_type} = $Contact->default_package_type;
	$c->stash->{default_product_type} = $Contact->default_product_type;

	#DYNAMIC FIELD VALIDATIONS
	$self->set_required_fields('shipment');

	$c->stash->{tooltips} = $self->get_tooltips;

	$c->stash(template => "templates/customer/order-shipment.tt");
	}

sub setup_carrier_service :Private
	{
	my $self = shift;
	my $c = $self->context;

	my $Customer = $self->customer;
	my $Contact = $self->contact;

	$c->stash->{review_order} = 1;
	$c->stash->{customer} = $Contact;

	my $do = $c->req->param('do') || '';
	if (!$do or $do =~ /(summary|review|step2)/)
		{
		$c->stash->{populate} = 'summary';
		$self->populate_order;
		}

	#$c->stash->{deliverymethod} = '0';
	#$c->stash->{deliverymethod_loop} = $self->get_select_list('DELIVERY_METHOD');

	if ($Contact->is_administrator and $Customer->login_level != 10 and $Customer->login_level != 20 and $Customer->login_level != 15)
		{
		$c->stash->{SHOW_NEW_OTHER_CARRIER} = 1;
		}

	unless ($c->stash->{one_page})
		{
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

	$c->stash->{tooltips} = $self->get_tooltips;

	$c->stash(template => "templates/customer/order-carrier-service.tt");
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

	#IntelliShip::Utils->hash_decode($params);

	my $CO = $self->get_order;

	my $coData = { keep => '0' };

	$coData->{'isdropship'} = $params->{'isdropship'} || 0;
	$coData->{'combine'} = $params->{'combine'} if $params->{'combine'};
	$coData->{'ordernumber'} = $params->{'ordernumber'} if $params->{'ordernumber'};
	$coData->{'department'} = $params->{'fromdepartment'} if $params->{'fromdepartment'};
	$coData->{'deliverynotification'} = $params->{'fromemail'} if $params->{'fromemail'};
	$coData->{'datetoship'} = IntelliShip::DateUtils->get_db_format_date_time($params->{'datetoship'}) if $params->{'datetoship'};
	$coData->{'dateneeded'} = IntelliShip::DateUtils->get_db_format_date_time($params->{'dateneeded'}) if $params->{'dateneeded'};

	$coData->{'description'} = $params->{'description'} if $params->{'description'};
	#$coData->{'extcd'} = $params->{'comments'};
	$coData->{'extloginid'} = $self->customer->username;
	$coData->{'contactname'} = $params->{'tocontact'} if $params->{'tocontact'};

	if ($params->{'tophone'})
		{
		$params->{'tophone'} =~ s/\D//g;
		$coData->{'contactphone'} = $params->{'tophone'};
		}

	$coData->{'freightcharges'} = $params->{'deliverymethod'} if $params->{'deliverymethod'};

	$coData->{'shipmentnotification'} = $params->{'toemail'} if $params->{'toemail'};
	$coData->{'custnum'} = $params->{'tocustomernumber'} if $params->{'tocustomernumber'};

	$coData->{'cotypeid'} = ($params->{'action'} and $params->{'action'} eq 'clearquote') ? 10 : 1;

	if ($self->customer->login_level =~ /(35|40)/ and $params->{'cotypeid'} and $params->{'cotypeid'} == 2)
		{
		$coData->{'cotypeid'} = 2;
		}

	$coData->{'estimatedweight'} = $params->{'totalweight'};
	$coData->{'density'} = $params->{'density'};
	$coData->{'volume'} = $params->{'volume'};
	$coData->{'class'} = $params->{'class'};

	# Sort out volume/density/class issues - if we have volume (and of course weight), and nothing
	# else, calculate density.  If we have density and no class, get class.
	# Volume assumed to be in cubic feet - density would of course be #/cubic foot
	if ($params->{'estimatedweight'} and $params->{'volume'} and !$params->{'density'} )
		{
		$coData->{'density'} = int($params->{'estimatedweight'} / $params->{'volume'});
		}

	if ($params->{'density'} and !$params->{'class'})
		{
		$coData->{'class'} = IntelliShip::Utils->get_freight_class_from_density($params->{'estimatedweight'}, undef, undef, undef, $params->{'density'});
		}

	$coData->{'consolidationtype'} = ($params->{'consolidationtype'} ? $params->{'consolidationtype'} : 0);

	## If this order has non-voided shipments, keep it's status as 'shipped' (statusid = 5)
	if ($CO->shipment_count > 0)
		{
		$coData->{'statusid'} = 5;
		}

	$coData->{'extcarrier'} = $params->{'carrier'} if $params->{'carrier'};

	## Sort out 'Other' carrier nonsense
	if ($params->{'customerserviceid'})
		{
		if ($params->{'customerserviceid'} =~ /^OTHER_(\w{13})/)
			{
			my $Other = $c->model('MyDBI::Other')->find({ customerid => $self->customer->customerid, otherid => $1 });
			$coData->{'extcarrier'} = 'Other - ' . $Other->othername if $Other;
			}
		else
			{
			my ($CarrierName,$ServiceName) = $self->API->get_carrier_service_name($params->{'customerserviceid'});
			$coData->{'extcarrier'} = $CarrierName if !$coData->{'extcarrier'} and $CarrierName;
			$coData->{'extservice'} = $ServiceName if $ServiceName;
			}
		}

	$coData->{'dimlength'} = $params->{'dimlength_1'} if $params->{'dimlength_1'};
	$coData->{'dimwidth'} = $params->{'dimwidth_1'} if $params->{'dimwidth_1'};
	$coData->{'dimheight'} = $params->{'dimheight_1'} if $params->{'dimheight_1'};

	$CO->update($coData);
	}

sub save_address :Private
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	$c->log->debug("... save address details");

	my $CO = $self->get_order;

	my $update_co=0;
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

	## Sort out return address/id
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
		$c->log->debug("... package/product details not found in request");
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

		my $ownerid = $CO->coid;
		$ownerid = $last_package_id if ($params->{'type_' . $PackageIndex } eq 'product');
		my $datatypeid = "1000";
		$datatypeid = "2000" if ($params->{'type_' . $PackageIndex } eq 'product');
		my $ownertypeid = 1000;
		$ownertypeid = 3000 if ($params->{'type_' . $PackageIndex } eq 'product');

		my $weight    = $params->{'weight_'.$PackageIndex} || 0;
		my $dimweight = $params->{'dimweight_'.$PackageIndex} || 0;
		my $dimlength = $params->{'dimlength_'.$PackageIndex} || 0;
		my $dimwidth  = $params->{'dimwidth_'.$PackageIndex} || 0;
		my $dimheight = $params->{'dimheight_'.$PackageIndex} || 0;
		my $density   = $params->{'density_' . $PackageIndex} || 0;
		my $class     = $params->{'class_' . $PackageIndex} || 0;
		my $decval    = $params->{'decval_' . $PackageIndex} || 0;
		my $frtins    = $params->{'frtins_'.$PackageIndex} || 0;
		my $dryicewt  = ($params->{'dryicewt'} ? ceil($params->{'dryicewt'}) : 0);

		my $PackProData = {
				ownertypeid => $ownertypeid,
				ownerid     => $ownerid,
				datatypeid  => $datatypeid,
				boxnum      => $params->{'quantity_' . $PackageIndex},
				quantity    => $params->{'quantity_' . $PackageIndex},
				unittypeid  => $params->{'unittype_' . $PackageIndex },
				weight      => sprintf("%.2f", $weight),
				dimweight   => sprintf("%.2f", $dimweight),
				dimlength   => sprintf("%.2f", $dimlength),
				dimwidth    => sprintf("%.2f", $dimwidth),
				dimheight   => sprintf("%.2f", $dimheight),
				density     => sprintf("%.2f", $density),
				class       => sprintf("%.2f", $class),
				decval      => sprintf("%.2f", $decval),
				frtins      => sprintf("%.2f", $frtins),
				dryicewt    => int $dryicewt,
			};

		$PackProData->{partnumber}  = $params->{'sku_' . $PackageIndex} if $params->{'sku_' . $PackageIndex};
		$PackProData->{description} = $params->{'description_' . $PackageIndex} if $params->{'description_' . $PackageIndex};
		$PackProData->{nmfc} = $params->{'nmfc_' . $PackageIndex} if $params->{'nmfc_' . $PackageIndex};
		$PackProData->{datecreated} = IntelliShip::DateUtils->get_timestamp_with_time_zone;

		#$c->log->debug("PackProData: " . Dumper $PackProData);

		my $PackProDataObj = $c->model("MyDBI::Packprodata")->new($PackProData);
		$PackProDataObj->packprodataid($self->get_token_id);
		$PackProDataObj->insert;

		$c->log->debug("New Packprodata Inserted, ID: " . $PackProDataObj->packprodataid);

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

sub void_shipment :Private
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	$c->log->debug("___ CANCEL ORDER ___");

	my $CO = $self->get_order;
	$CO->update({ statusid => '200' });

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
			my $coData = {
				ordernumber       => $self->get_auto_order_number($params->{'ordernumber'}),
				clientdatecreated => IntelliShip::DateUtils->get_timestamp_with_time_zone,
				datecreated       => IntelliShip::DateUtils->get_timestamp_with_time_zone,
				customerid        => $customerid,
				contactid         => $self->contact->contactid,
				addressid         => $self->customer->address->addressid,
				cotypeid          => $cotypeid,
				freightcharges    => 0,
				statusid          => 1
				};

			$CO = $c->model('MyDBI::Co')->new($coData);
			$CO->coid($self->get_token_id);
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

	## Address and Shipment Information
	if (!$populate or $populate eq 'address' or $populate eq 'summary')
		{
		$c->stash->{combine} = $CO->combine;
		$c->stash->{customer} = $self->customer;
		$c->stash->{customerAddress} = $self->customer->address;

		## Ship From Section
		$c->stash->{department} = $CO->department;
		$c->stash->{fromemail} = $CO->deliverynotification;

		## Ship To Section
		$c->stash->{tocontact} = $CO->contactname;
		$c->stash->{tophone} = $CO->contactphone;
		$c->stash->{toemail} = $CO->shipmentnotification;
		$c->stash->{ordernumber} = $CO->ordernumber;
		$c->stash->{toAddress} = $CO->to_address;
		$c->stash->{tocustomernumber} = $CO->custnum;
		$c->stash->{description} = $CO->description;
		}

	## Package Details
	if (!$populate or $populate eq 'shipment')
		{
		$c->stash->{'totalweight'} = 0;
		$c->stash->{'totalpackages'} = 0;

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
		$c->log->debug("Total No of packages  " . @$packages);

		my $rownum_id = 0;
		my $package_detail_section_html;
		foreach my $Package (@$packages)
			{
			$rownum_id++;
			$c->stash->{'totalpackages'}++;
			$package_detail_section_html .= $self->add_detail_row('package',$rownum_id, $Package);

			# Step 2: Find Product belog to Package
			my @products = $Package->products;
			foreach my $Packprodata (@products)
				{
				$rownum_id++;
				$package_detail_section_html .= $self->add_detail_row('product',$rownum_id, $Packprodata);
				}
			}

		## Don't move this above foreach block
		$c->stash->{description} = $CO->description;

		# Step 3: Find product belog to Order
		my @products = $CO->co_products;
		foreach my $ProductData (@products)
			{
			$rownum_id++;
			$package_detail_section_html .= $self->add_detail_row('product',$rownum_id, $ProductData);
			}

		#$c->log->debug("PACKAGE_DETAIL_SECTION: HTML: " . $package_detail_section_html);
		$c->stash->{package_detail_section} = $package_detail_section_html;
		$c->stash->{package_detail_row_count} = $rownum_id;
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

	# SELECTED SPECIAL SERVICES
	if (!$populate or $populate eq 'shipment' or $populate eq 'summary')
		{
		my @special_services = $CO->assessorials;
		my %serviceHash =  map { $_->assname => 1 } @special_services;
		my $special_service_loop = $self->get_select_list('SPECIAL_SERVICE');
		my @selected_special_service_loop = grep { $serviceHash{$_->{'value'}} } @$special_service_loop;
		$c->stash->{selected_special_service_loop} = \@selected_special_service_loop if @selected_special_service_loop;
		#$c->log->debug("selected_special_service_loop: " . Dumper @selected_special_service_loop);
		}

	$c->stash->{deliverymethod} = $CO->freightcharges || 0;
	}

sub add_detail_row :Private
	{
	my $self = shift;
	my $type = shift;
	my $row_num_id = shift;
	my $PackProData = shift;
	my $c = $self->context;

	$c->stash->{ROW_COUNT} = $row_num_id;
	$c->stash->{DETAIL_TYPE} = $type;

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

	$c->stash->{PKG_DETAIL_ROW} = 1;
	$c->stash->{packageunittype_loop} = $self->get_select_list('UNIT_TYPE');

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

	$c->log->debug("------- SHIP_ORDER -------");

	$self->save_order unless $params->{'do'} eq 'load';

	my $CO = $self->get_order;

	$params->{'carrier'} = $CO->extcarrier if $CO->extcarrier and !$params->{'carrier'};

	$c->log->debug("CO->extcarrier      : " . $CO->extcarrier);
	$c->log->debug("params->{'carrier'} : " . $params->{'carrier'}) if $params->{'carrier'};
	$c->log->debug("CO->extservice      : " . $CO->extservice);
	$c->log->debug("params->{'service'} : " . $params->{'service'}) if $params->{'service'};

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

	my $CustomerID = $Customer->customerid;
	my $ServiceTypeID = $self->API->get_CS_value($params->{'customerserviceid'}, 'servicetypeid', $CustomerID);
	#$c->log->debug("API ServiceTypeID: " . Dumper $ServiceTypeID);

	$params->{'new_shipmentid'} = $self->get_token_id;
	$c->log->debug("___ Generate New Shipment ID: " . $params->{'new_shipmentid'});

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

		# Process small/freight shipments (mainly FedEx freight, on the freight end)
		if ($ServiceTypeID < 3000)
			{
			# Get shipment charges and fsc's sorted out for overridden shipment.
			if ($params->{'fcchanged'} and $params->{'fcoverride'})
				{
				$self->ProcessFCOverride;
				}

			# Save out all shipment packages. Give them a dummy shipmentid, pass that around for continuity.
			my @packages = $CO->packages;
			foreach my $Package (@packages)
				{
				my $ShipmentPackage = $c->model('MyDBI::Packprodata')->new($Package->{'_column_data'});
				$ShipmentPackage->ownertypeid(2000); # Shipment
				$ShipmentPackage->ownerid($params->{'new_shipmentid'});
				$ShipmentPackage->packprodataid($self->get_token_id);
				$ShipmentPackage->insert;

				$c->log->debug("___ new shipment package insert: " . $ShipmentPackage->packprodataid);

				my @products = $Package->products;
				foreach my $Product (@products)
					{
					my $ShipmentProduct = $c->model('MyDBI::Packprodata')->new($Product->{'_column_data'});
					$ShipmentProduct->ownertypeid(3000); # Product (for Packages)
					$ShipmentProduct->ownerid($ShipmentPackage->packprodataid);
					$ShipmentProduct->packprodataid($self->get_token_id);
					$ShipmentProduct->insert;

					$c->log->debug("___ new shipment product insert: " . $ShipmentProduct->packprodataid);
					}
				}

			# Push all shipmentcharges onto a list for use by all shipments
			if ($params->{'packagecosts'} and $params->{'packagecosts'} > 0)
				{
				$params->{'shipmentchargepassthru'} = $self->BuildShipmentChargePassThru;
				$c->log->debug("___ shipmentchargepassthru: " . $params->{'shipmentchargepassthru'});
				}

			# Extract shipment specific data for use in the shipping process
			if ( $params->{'fakeitemids'} )
				{
				#$params = $self->GetCurrentPackage;
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

	# Build up shipment ref
	my $ShipmentData = $self->BuildShipmentInfo;

	# Kludge to get freightinsurance into the shipments
	my $SaveFreightInsurance = $ShipmentData->{'freightinsurance'};
	$ShipmentData->{'freightinsurance'} = $params->{'frtins'};

	$params->{'customerserviceid'} = $self->API->get_co_customer_service({}, $self->customer, $CO) unless $params->{'customerserviceid'};

	my $CustomerService = $self->API->get_hashref('CUSTOMERSERVICE',$params->{'customerserviceid'});
	#$c->log->debug("CUSTOMERSERVICE DETAILS FOR $params->{'customerserviceid'}:" . Dumper $CustomerService);

	my $ShippingData = $self->API->get_CS_shipping_values($params->{'customerserviceid'},$self->customer->customerid);
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

	foreach my $key (%$Service)
		{
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
	$Handler->customer($self->customer);
	$Handler->carrier($params->{'carrier'});
	$Handler->customerservice($CustomerService);
	$Handler->service($Service);
	$Handler->CO($CO);
	$Handler->request_data($ShipmentData);

	my $Response = $Handler->process_request({
			NO_TOKEN_OPTION => 1
			});

	# Process errors
	unless ($Response->is_success)
		{
		$c->log->debug("SHIPMENT TO CARRIER FAILED: " . $Response->message);
		$c->log->debug("RESPONSE CODE: " . $Response->response_code);
		return $self->display_error_details($Response->message);
		}

	$c->log->debug("SHIPMENT PROCESSED SUCCESSFULLY");

	my $Shipment = $Response->shipment;
	unless ($Shipment)
		{
		$c->log->debug("ERROR: No response received. " . $Response->message);
		return $self->display_error_details($Response->message);
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

	# Build up data for use in BOL assessorial display
	my $ass_names = $params->{'assessorial_names'};
	if ($ass_names)
		{
		$ass_names =~ s/'//g;

		foreach my $ass_name (split(/,/,$ass_names))
			{
			my $ass_value = $params->{$ass_name} || '';
			$params->{'assessorial_values'} .= "'$ass_value',";
			}

		chop($params->{'assessorial_values'}) if $params->{'assessorial_values'};
		}

	$c->log->debug("SHIPCONFIRM SAVE ASSESSORIALS....");

	$c->log->debug("SHIPMENT ID: " . $Shipment->shipmentid);
	# Save out shipment assessorials
	#$self->SaveAssessorials($params,$params->{'shipmentid'},2000);

	unless ($Shipment)# $Shipment and $Shipment->tracking1 and $Shipment->shipmentid)
		{
		if (!defined($Shipment))
			{
			}
		elsif (defined($Shipment->{'shipmentid'}))
			{
			#$Shipment->ChangeStatus(5); ######### TODO ########
			}

		 ######### TODO ########
		# undef the shipmentid or else shipconfirm will try to display as readonly shipment
		#$Shipment->{'shipmentid'} = undef;
		#$CO->ChangeStatus(1);

		# # Excise bad zip/zone combinations from the db.
		# elsif ($Shipment->{'errorcode'} eq 'badzone')
			# {
			# my $ZoneRef = {
				# action   => 'DeleteZone',
				# typeid   => $CS->{'zonetypeid'},
				# fromzip  => $Customer->{'zip'},
				# tozip    => $ShipmentRef->{'addresszip'},
				# };

			# &APIRequest($ZoneRef);
			# }

		# if (!defined($Shipment->{'errorstring'}))
			# {
			# $Shipment->{'errorstring'} = 'An Error Has Occurred.  Please try again later.';
			# }
		 ######### TODO ########
		}
	else
		{
		#Set shipment and order statuses (ship complete and shipped, respectively)
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

		#############################################
		# GENERATE LABEL TO PRINT
		#############################################
		$self->generate_label($Shipment, $Service, $PrinterString);
		$c->stash(template => "templates/customer/order-label.tt");
		}
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

	my $ShipmentData = $self->BuildShipmentInfo;

	# Alt SOP mangling
	# if ( $CgiRef->{'usingaltsop'} )
		# {
		# $CgiRef->{'addressname'} = $self->GetAltSOPConsigneeName($CgiRef->{'customerserviceid'},$CgiRef->{'addressname'});
		# }

	$c->stash($params);
	$c->stash($Shipment->{_column_data});
	$c->stash->{fromAddress} = $Shipment->origin_address;
	$c->stash->{toAddress} = $Shipment->destination_address;
	$c->stash->{shipdate} = IntelliShip::DateUtils->date_to_text_long(IntelliShip::DateUtils->american_date($Shipment->dateshipped));
	$c->stash->{tracking1} = $Shipment->tracking1;
	$c->stash->{custnum} = $Shipment->custnum;

	my $BillingAccount = $Shipment->billingaccount;
	if (defined($BillingAccount) and $BillingAccount ne '')
		{
		$c->stash->{billingtype} = "3RD PARTY";
		}
	else
		{
		$c->stash->{billingtype} = "P/P";
		}

	if (defined($Shipment->dimweight) and $Shipment->dimweight == 0)
		{
		$c->stash->{dimweight} = undef;
		}

	my $label_type = $self->contact->label_type;
	$label_type = $self->customer->label_type unless $label_type;
	$c->stash->{label_type} = $label_type || 'EPL';

	$c->stash->{enteredweight} = $CO->total_weight;
	$c->stash->{ponumber} = $Shipment->ponumber;
	$c->stash->{tracking1} = $Shipment->tracking1;
	$c->stash->{service} = uc($Service->{'servicename'});
	$c->stash->{totalquantity} = $CO->total_quantity;

	if ($Shipment->dimlength and $Shipment->dimwidth and $Shipment->dimheight)
		{
		$c->stash->{dims} = $Shipment->dimlength . "x" . $Shipment->dimwidth . "x" . $Shipment->dimheight;
		}

	######### TODO IMPLEMENT PARENT ORDER NUMBER AS REFNUMBER #########
	# if ( defined($CgiRef->{'originalcoid'}) and $CgiRef->{'originalcoid'} ne '' )
		# {
		# my $ParentCO = new CO($self->{'dbref'}->{'aos'},$self->{'customer'});
		# $ParentCO->Load($CgiRef->{'originalcoid'});
		# $CgiRef->{'refnumber'} = $ParentCO->GetValueHashRef()->{'ordernumber'};
		# }
	# else
		# {
		# $CgiRef->{'refnumber'} = $CgiRef->{'ordernumber'};
		# }

	# if ( defined($CgiRef->{'ponumber'}) and $CgiRef->{'ponumber'} ne '' )
		# {
		# $CgiRef->{'refnumber'} .= " - $CgiRef->{'ponumber'}";
		# }
	# elsif ( defined($CgiRef->{'custnum'}) and $CgiRef->{'custnum'} ne '' )
		# {
		# $CgiRef->{'refnumber'} .= " - $CgiRef->{'custnum'}";
		# }
	######################################################################

	my $refnumber = $CO->ordernumber;
	if ( defined($CO->{'ponumber'}) and $CO->ponumber ne '' )
		{
		$refnumber .= " - " . $CO->{'ponumber'};
		}

	$c->stash->{refnumber} = $refnumber;

	$self->ProcessPrinterStream($Shipment, $PrinterString);

	my $template = $params->{'carrier'} || 'default';
	$c->stash(LABEL => $c->forward($c->view('Label'), "render", [ "templates/label/" . lc($template) . ".tt" ]));
	$c->stash(MEDIA_PRINT => 1);
	$c->stash($params);
	}

sub ProcessPrinterStream
	{
	my $self = shift;
	my $Shipment = shift;
	my $PrinterString = shift;

	my $c = $self->context;
	my $Contact = $self->contact;

	# Label stub
	if ( my $StubTemplate = $Contact->get_contact_data_value('labelstub') )
		{
		#$CgiRef->{'truncd_custnum'} = TruncString($CgiRef->{'custnum'},16);
		#$CgiRef->{'truncd_addressname'} = TruncString($CgiRef->{'addressname'},16);
		#$PrinterString = $self->InsertLabelStubStream($PrinterString,$StubTemplate,$CgiRef);
		}

	#if ( $CgiRef->{'dhl_intl_labels'} )
	#	{
	#	$PrinterString .= $CgiRef->{'dhl_intl_labels'};
	#	}

	# UCC 128 label handling
	if ($Contact->get_contact_data_value('checkucc128'))
		{
		#my $UCC128 = new UCC128($self->{'dbref'}->{'aos'}, $self->{'customer'});
		#if ( my $UCC128ID = $UCC128->GetUCC128ID($CgiRef->{'addressname'},$CgiRef->{'department'},$CgiRef->{'custnum'},$CgiRef->{'externalpk'}) )
		#	{
		#	$UCC128->Load($UCC128ID);
		#	$PrinterString .= $self->BuildUCC128Label;
		#	}
		}

	$self->SaveStringToFile($Shipment->shipmentid, $PrinterString);

	# Label stub
	my $CustomerLabelType = $c->stash->{label_type};

	$c->log->debug(".... Customer Label Type: " . $CustomerLabelType);
	if ($CustomerLabelType =~ /^jpg$/i)
		{
		## Generate JPEG label image
		system("/opt/engage/EPL2JPG/generatelabel.pl ". $Shipment->shipmentid ." jpg s 270");
		##

		my $out_file = $Shipment->shipmentid . '.jpg';
		my $copyImgCommand = 'cp '.IntelliShip::MyConfig->label_file_directory.'/'.$out_file.' '.IntelliShip::MyConfig->label_image_directory.'/'.$out_file;
		$c->log->debug("copyImgCommand: " . $copyImgCommand);

		## Copy to Apache context path
		system($copyImgCommand);
		##

		$c->stash->{LABEL_IMG} = '/label/' . $Shipment->shipmentid . '.jpg';
		}
	else
		{
		if ($CustomerLabelType =~ /^zpl$/i)
			{
			require IntelliShip::EPL2TOZPL2;
			my $EPL2TOZPL2 = IntelliShip::EPL2TOZPL2->new();
			$PrinterString = $EPL2TOZPL2->ConvertStreamEPL2ToZPL2($PrinterString);
			}

		#$c->log->debug("PrinterString    : " . $PrinterString);

		## Set Printer String Loop
		my @PSLINES = split(/\n/,$PrinterString);

		my $printerstring_loop = [];
		foreach my $line (@PSLINES)
			{
			$line =~ s/"/\\"/sg;
			$line =~ s/'//g;
			push @$printerstring_loop, $line;
			}

		$c->log->debug("printerstring_loop: " . Dumper $printerstring_loop);
		$c->stash->{printerstring_loop} = $printerstring_loop;
		$c->stash->{label_port} = 'LPT1';
		}
	}

sub SaveStringToFile
	{
	my $self = shift;
	my $FileName = shift;
	my $FileString = shift;

	return unless $FileName;
	return unless $FileString;

	$FileName = IntelliShip::MyConfig->label_file_directory . '/' . $FileName;
	$self->context->log->debug("EPL File: " . $FileName);

	my $FILE = new IO::File;
	unless (open ($FILE,">$FileName"))
		{
		warn "\nLabel String Save Error: " . $!;
		return;
		}
	print $FILE $FileString;
	close $FILE;
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

sub BuildShipmentInfo
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;
	my $Customer = $self->customer;
	my $CO = $self->get_order;

	my $myDBI = $c->model('MyDBI');

	my $ShipmentData = { 'shipmentid' => $params->{'new_shipmentid'} };

	$ShipmentData->{$_} = $params->{$_} foreach keys %$params;

	my $FromAddress = $Customer->address;
	$ShipmentData->{'customername'}         = $FromAddress->addressname;
	$ShipmentData->{'branchaddress1'}       = $FromAddress->address1;
	$ShipmentData->{'branchaddress2'}       = $FromAddress->address2;
	$ShipmentData->{'branchaddresscity'}    = $FromAddress->city;
	$ShipmentData->{'branchaddressstate'}   = $FromAddress->state;
	$ShipmentData->{'branchaddresszip'}     = $FromAddress->zip;
	$ShipmentData->{'branchaddresscountry'} = $FromAddress->country;

	my $ToAddress = $CO->to_address;
	$ShipmentData->{'addressname'}    = $ToAddress->addressname;
	$ShipmentData->{'address1'}       = $ToAddress->address1;
	$ShipmentData->{'address2'}       = $ToAddress->address2;
	$ShipmentData->{'addresscity'}    = $ToAddress->city;
	$ShipmentData->{'addressstate'}   = $ToAddress->state;
	$ShipmentData->{'addresszip'}     = $ToAddress->zip;
	$ShipmentData->{'addresscountry'} = $ToAddress->country;
	$ShipmentData->{'addresscountryname'} = $ToAddress->country_description;

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
	$ShipmentData->{'freightinsurance'} = $params->{'freightinsurance'};
	$ShipmentData->{'weighttype'} = $params->{'weighttype'};
	$ShipmentData->{'dimunits'} = $params->{'dimunits'};
	$ShipmentData->{'density'} = $params->{'density'};
	$ShipmentData->{'ipaddress'} = $params->{'ipaddress'};
	$ShipmentData->{'custnum'} = $params->{'custnum'};
	$ShipmentData->{'shipasname'} = $params->{'customername'};
	$ShipmentData->{'manualthirdparty'} = $params->{'manualthirdparty'};
	$ShipmentData->{'originid'} = 3;
	$ShipmentData->{'insurance'} = $params->{'insurance'};
	$ShipmentData->{'oacontactname'} = $params->{'branchcontact'};
	$ShipmentData->{'oacontactphone'} = $params->{'branchphone'};
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
		my $Value = $params->{'custnum'};
		my $CarrierID = $self->API->get_carrier_ID($params->{'customerserviceid'});

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

		unless ($Customer->login_level == 25)
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
		unless ($Customer->login_level == 25 or $c->stash->{one_page})
			{
			push(@$requiredList, { name => 'datetoship', details => "{ date: true }"}) if $customerRules{'reqdatetoship'} and $Customer->allowpostdating;
			push(@$requiredList, { name => 'dateneeded', details => "{ date: true }"}) if $customerRules{'reqdateneeded'};
			}

		push(@$requiredList, { name => 'package-detail-list', details => "{ method: validate_package_details }"})
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

	$params->{'coid'} = undef;
	$c->stash->{CO} = undef;
	$c->stash->{coid} = undef;
	$c->stash({});
	}

sub display_error_details :Private
	{
	my $self = shift;
	my $msg = shift;

	my $c = $self->context;

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
	my $HasAutoOrderNumber = $STH->fetchrow(0)->{'count(*)'};

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

__PACKAGE__->meta->make_immutable;

1;
