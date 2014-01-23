package IntelliShip::Controller::Customer::Order;
use Moose;
use Data::Dumper;
use IntelliShip::Utils;
use IntelliShip::MyConfig;
use IntelliShip::Carrier::Handler;
use IntelliShip::Carrier::Constants;
use namespace::autoclean;

BEGIN { extends 'IntelliShip::Controller::Customer'; has 'CO' => ( is => 'rw' ); }

sub onepage :Local
	{
	my $self = shift;
	my $c = $self->context;

	my $do_value = $c->req->param('do') || '';
	if ($do_value eq 'save')
		{
		$self->save_order;
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

	my $CO = $self->get_order;
	my $Customer = $self->customer;
	#($params->{'ordernumber'},$params->{'hasautoordernumber'}) = $self->get_auto_order_number($params->{'ordernumber'});

	$c->stash->{customer} = $Customer;
	$c->stash->{customerAddress} = $Customer->address;
	$c->stash->{AMDELIVERY} = 1 if $Customer->amdelivery;
	$c->stash->{ordernumber} = ($params->{'ordernumber'} ? $params->{'ordernumber'} : $CO->coid);
	$c->stash->{customerlist_loop} = $self->get_select_list('CUSTOMER');
	$c->stash->{countrylist_loop} = $self->get_select_list('COUNTRY');
	$c->stash->{statelist_loop} = $self->get_select_list('US_STATES');

	if ($c->stash->{one_page})
		{
		$c->stash->{deliverymethod} = "prepaid";
		$c->stash->{deliverymethod_loop} = $self->get_select_list('DELIVERY_METHOD') ;
		}

	$c->stash->{tooltips} = $self->get_tooltips;

	#DYNAMIC INPUT FIELDS VISIBILITY
	unless ($Customer->login_level == 25)
		{
		$c->stash->{SHOW_PONUMBER} = $Customer->reqponum;
		$c->stash->{SHOW_EXTID} = $Customer->get_contact_data_value('reqextid');
		$c->stash->{SHOW_CUSTREF2} = $Customer->get_contact_data_value('reqcustref2');
		$c->stash->{SHOW_CUSTREF3} = $Customer->get_contact_data_value('reqcustref3');
		}

	#DYNAMIC FIELD VALIDATIONS
	$self->set_required_fields('address');

	my $do = $c->req->param('do') || '';
	if ($do eq 'address')
		{
		$c->stash->{populate} = 'address';
		$self->populate_order;
		}

	$c->stash->{tocountry} = "US";
	$c->stash(template => "templates/customer/order-address.tt");
	}

sub setup_shipment_information :Private
	{
	my $self = shift;
	my $c = $self->context;

	$c->stash->{packageunittype_loop} = $self->get_select_list('UNIT_TYPE');

	my $CO = $self->get_order;
	my $Customer = $self->customer;

	if ($Customer->address->country ne $CO->to_address->country)
		{
		$c->log->debug("... customer address and drop address not same, INTERNATIONAL shipment");
		my $CA = IntelliShip::Controller::Customer::Ajax->new;
		$CA->context($c);
		$CA->set_international_details;
		$c->stash->{INTERNATIONAL_AND_COMMODITY} = $c->forward($c->view('Ajax'), "render", [ "templates/customer/ajax.tt" ]);
		}

	unless ($c->stash->{one_page})
		{
		$c->stash->{deliverymethod} = "prepaid";
		$c->stash->{deliverymethod_loop} = $self->get_select_list('DELIVERY_METHOD');
		}

	#DYNAMIC FIELD VALIDATIONS
	$self->set_required_fields('shipment');

	$c->stash->{tooltips} = $self->get_tooltips;

	$c->stash->{populate} = 'shipment';
	$self->populate_order;

	$c->stash(template => "templates/customer/order-shipment.tt");
	}

sub setup_carrier_service :Private
	{
	my $self = shift;
	my $c = $self->context;

	my $Customer = $self->customer;
	my $Contact = $self->contact;

	$c->stash->{review_order} = 1;
	$c->stash->{populate} = 'summary';
	$c->stash->{customer} = $Contact;

	$self->populate_order;

	$c->stash->{deliverymethod} = "prepaid";
	$c->stash->{deliverymethod_loop} = $self->get_select_list('DELIVERY_METHOD');

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

		$CA->get_carrier_service_list;

		$c->stash->{SERVICE_LEVEL_SUMMARY} = $c->forward($c->view('Ajax'), "render", [ "templates/customer/order-ajax.tt" ]);
		#$c->log->debug("SERVICE_LEVEL_SUMMARY, HTML: " . $c->stash->{SERVICE_LEVEL_SUMMARY});
		}

	$c->stash->{tooltips} = $self->get_tooltips;

	$c->stash(template => "templates/customer/order-carrier-service.tt");
	}

sub save_order :Private
	{
	my $self = shift;

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

	my $CO = $self->get_order;

	my $coData = { keep => '0' };

	$coData->{'isdropship'} = $params->{'isdropship'} || 0;
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

	if ($params->{'deliverymethod'})
		{
		my $deliverymethodHash = {
			'prepaid' => '0',
			'collect' => '1',
			'3rdparty' => '2',
			};

		$coData->{'freightcharges'} = $deliverymethodHash->{$params->{'deliverymethod'}};
		}

	$coData->{'shipmentnotification'} = $params->{'toemail'} if $params->{'toemail'};
	#$coData->{'tocustomernumber'} = $params->{'tocustomernumber'} if $params->{'tocustomernumber'};

	#$OrderRef->{'cotypeid'} = $HashRef->{'action'} eq 'clearquote' ? 10 : 1;
	#
	#if (
	#	$HashRef->{'loginlevel'} == 35 or
	#	$HashRef->{'loginlevel'} == 40 or
	#	( $HashRef->{'cotypeid'} and $HashRef->{'cotypeid'} == 2 )
	#)
	#{
	#	$OrderRef->{'cotypeid'} = 2;
	#}

	# $coData->{'estimatedweight'} = $params->{'estimatedweight'};
	# $coData->{'density'} = $params->{'density'};
	# $coData->{'volume'} = $params->{'volume'};
	# $coData->{'class'} = $params->{'class'};

	# # Sort out volume/density/class issues - if we have volume (and of course weight), and nothing
	# # else, calculate density.  If we have density and no class, get class.
	# # Volume assumed to be in cubic feet - density would of course be #/cubic foot
	# if ($params->{'estimatedweight'} and $params->{'volume'} and !$params->{'density'} )
		# {
		# $coData->{'density'} = int($params->{'estimatedweight'} / $params->{'volume'});
		# }

	# if ($params->{'density'} and !$params->{'class'})
		# {
		# $coData->{'class'} = IntelliShip::Utils->get_freight_class_from_density($params->{'estimatedweight'}, undef, undef, undef, $params->{'density'});
		# }

	# $coData->{'consolidationtype'} = ($params->{'consolidationtype'} ? $params->{'consolidationtype'} : 0);

	# ## If this order has non-voided shipments, keep it's status as 'shipped' (statusid = 5)
	# if ($params->{'coid'} and $self->get_shipment_count > 0)
		# {
		# $coData->{'statusid'} = 5;
		# }

	## Sort out 'Other' carrier nonsense
	if ($params->{'customerserviceid'} and $params->{'customerserviceid'} =~ /^OTHER_(\w{13})/)
		{
		my $Other = $c->model('MyDBI::Other')->find({ customerid => $self->customer->customerid, otherid => $1 });
		$coData->{'extcarrier'} = 'Other - ' . $Other->othername if $Other;
		}

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

	my $Thirdpartyacct;
	unless ($Thirdpartyacct = $Customer->third_party_account($params->{'tpacctnumber'}))
		{
		$Thirdpartyacct = $c->model("MyDBI::Thirdpartyacct")->new({ customerid => $Customer->customerid });
		}

	if ($Thirdpartyacct->thirdpartyacctid)
		{
		$Thirdpartyacct->update($thirdPartyAcctData);
		$c->log->debug("Existing third party info found, thirdpartyacctid: " . $Thirdpartyacct->thirdpartyacctid);
		}
	else
		{
		$Thirdpartyacct->thirdpartyacctid($self->get_token_id);
		$Thirdpartyacct->insert($thirdPartyAcctData);
		$c->log->debug("New Thirdpartyacct Inserted, ID: " . $Thirdpartyacct->thirdpartyacctid);
		}
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

	$c->log->debug("___ Flush old PackProData for ownerid: " . $CO->coid);
	my @packages = $c->model("MyDBI::Packprodata")->search({ ownerid => $CO->coid });
	foreach my $Pkg (@packages)
		{
		$c->model("MyDBI::Packprodata")->search({ ownerid => $Pkg->packprodataid })->delete;
		$Pkg->delete;
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

		my $PackProData = {
				ownertypeid => $ownertypeid,
				ownerid     => $ownerid,
				datatypeid  => $datatypeid,
				boxnum      => $params->{'quantity_' . $PackageIndex},
				quantity    => $params->{'quantity_' . $PackageIndex},
				unittypeid  => $params->{'unittype_' . $PackageIndex },
				weight      => sprintf("%.2f", $params->{'weight_' . $PackageIndex}),
				dimweight   => sprintf("%.2f", $params->{'dimweight_' . $PackageIndex}),
				dimlength   => sprintf("%.2f", $params->{'dimlength_' . $PackageIndex}),
				dimwidth    => sprintf("%.2f", $params->{'dimwidth_' . $PackageIndex}),
				dimheight   => sprintf("%.2f", $params->{'dimheight_' . $PackageIndex}),
				density     => sprintf("%.2f", $params->{'density_' . $PackageIndex}),
				class       => sprintf("%.2f", $params->{'class_' . $PackageIndex}),
				decval      => sprintf("%.2f", $params->{'decval_' . $PackageIndex}),
				frtins      => sprintf("%.2f", $params->{'frtins_' . $PackageIndex}),
			};

		$PackProData->{partnumber}  = $params->{'sku_' . $PackageIndex} if $params->{'sku_' . $PackageIndex};
		$PackProData->{description} = $params->{'description_' . $PackageIndex} if $params->{'description_' . $PackageIndex};
		$PackProData->{nmfc} = $params->{'nmfc_' . $PackageIndex} if $params->{'nmfc_' . $PackageIndex};

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

	my $CO = $self->get_order;

	$c->log->debug("___ Flush old Assdata for ownerid: " . $CO->coid);
	my @assessorial_datas = $c->model("MyDBI::Assdata")->search({ ownerid => $CO->coid });

	foreach my $AssData (@assessorial_datas)
		{
		$c->log->debug("___ Flush old Assdata for assdataid: " . $AssData->assdataid);
		$AssData->delete;
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

sub get_shipment_count :Private
	{
	my $self = shift;
	my $c = $self->context;
	my $COID = $self->params->{'coid'};
	return unless $COID;
	my $STH = $c->model("MyDBI")->select("SELECT count(*) FROM shipment WHERE coid = '$COID' AND statusid NOT IN ('5','6','7')");
	my $Count = $STH->fetchrow(0)->{'count'};
	return $Count;
	}

sub get_auto_order_number :Private
	{
	my $self = shift;
	my $OrderNumber = shift || '';

	my $c = $self->context;
	my $myDBI = $c->model("MyDBI");
	my $Customer = $self->customer;

	$c->log->debug("get_auto_order_number IN ordernumber=$OrderNumber");

	# see if a customer sequence exists for the order number
	my $SQL = "SELECT count(*) from pg_class where relname = lower('ordernumber_" . $Customer->customerid . "_seq')";
	$c->log->debug("get_auto_order_number SQL=$SQL");

	my $HasAutoOrderNumber = $myDBI->select($SQL)->fetchrow(0)->{'count'};

	if ( $HasAutoOrderNumber == 0 )
		{
		$OrderNumber = undef;
		}
	elsif ( length $OrderNumber == 0 and $HasAutoOrderNumber == 1 )
		{
		my $sql = "SELECT nextval('ordernumber_" . $Customer->customerid . "_seq')";
		$OrderNumber = "QS" . $myDBI->select($SQL)->fetchrow_array;
		}

	$c->log->debug("get_auto_order_number OUT ordernumber=$OrderNumber") if $OrderNumber;

	return ($OrderNumber,$HasAutoOrderNumber);
	}

sub void_shipment :Private
	{
	my $self = shift;
	my $c = $self->context;

	$c->log->debug("___ CANCEL ORDER ___");

	my $CO = $self->get_order;
	$CO->update({ statusid => '200' });
	}

sub get_order :Private
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	if ($self->CO)
		{
		#$c->log->debug("Hmm, cached CO found");
		$c->stash->{coid} = $self->CO->coid;
		return $self->CO;
		}

	#$c->log->debug("params->{'coid'}: " . $params->{'coid'}) if $params->{'coid'};
	if ($params->{'coid'})
		{
		my $CO = $c->model('MyDBI::Co')->find({ coid => $params->{'coid'} });
		$c->log->debug("Existing CO Found, ID: " . $CO->coid);
		$self->CO($CO);
		}
	else
		{
		## Set default cotypeid (Default to vanilla 'Order')
		my $cotypeid = $params->{'cotypeid'} || '1';
		my $ordernumber = $params->{'ordernumber'} || '';
		my $customerid = $self->customer->customerid;

		$c->log->debug("get_order, cotypeid: $cotypeid, ordernumber=$ordernumber, customerid: $customerid");

		my @r_c = $c->model('MyDBI::Restrictcontact')->search({contactid => $self->contact->contactid, fieldname => 'extcustnum'});

		my $allowed_ext_cust_nums = [];
		push(@$allowed_ext_cust_nums, $_->{'fieldvalue'}) foreach @r_c;
=as
		$allowed_ext_cust_nums = 'AND upper(extcustnum) in (' . $allowed_ext_cust_nums . ')' if length $allowed_ext_cust_nums;
		my $myDBI = $c->model('MyDBI');
		my $SQLString = "
			SELECT coid, statusid
			FROM
				co
			WHERE
				customerid = '$customerid' AND
				upper(ordernumber) = upper('$ordernumber') AND
				cotypeid IN ($cotypeid)
				$allowed_ext_cust_nums
			ORDER BY
				cotypeid,
				datecreated DESC
			LIMIT 1";
		my $sth = $myDBI->select($SQLString);
		if ($sth->numrows)
			{
			my $data = $sth->fetchrow(0);
			my ($coid, $statusid, $ordernumber) = ($data->{'coid'},$data->{'statusid'},$data->{''});
			}
=cut

		my @cos = $c->model('MyDBI::Co')->search({
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

		my ($coid, $statusid) = (0,0);
		if (@cos)
			{
			my $CO = $cos[0];
			$self->CO($CO);
			($coid, $statusid, $ordernumber) = ($CO->coid,$CO->statusid,$CO->ordernumber);
			$c->log->debug("coid: $coid , statusid: $statusid, ordernumber: $ordernumber");
			}
		else
			{
			$c->log->debug("######## NO CO FOUND ########");
			my $coData = {
				clientdatecreated => IntelliShip::DateUtils->get_timestamp_with_time_zone,
				datecreated => IntelliShip::DateUtils->get_timestamp_with_time_zone,
				customerid => $customerid,
				contactid  => $self->contact->contactid,
				addressid  => $self->customer->address->addressid,
				cotypeid => $cotypeid,
				statusid   => 1
				};

			my $CO = $c->model('MyDBI::Co')->new($coData);
			$CO->coid($self->get_token_id);
			$CO->insert;

			$c->log->debug("New CO Inserted, ID: " . $CO->coid);
			$self->CO($CO);
			}
		}

	$c->stash->{coid} = $self->CO->coid;

	return $self->CO;
	}

sub setup_quickship_page :Private
	{
	my $self = shift;
	my $c = $self->context;

	$c->stash->{quickship} = 1;
	$c->stash->{title} = 'Quick Ship Order';
	$self->populate_order;
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

	## Address and Shipment Information
	if (!$populate or $populate eq 'address' or $populate eq 'summary')
		{
		$c->stash->{customer} = $self->customer;
		$c->stash->{customerAddress} = $self->customer->address;

		## Ship From Section
		$c->stash->{department} = $CO->department;
		$c->stash->{fromemail} = $CO->deliverynotification;

		## Ship To Section
		$c->stash->{tocontact} = $CO->contactname;
		$c->stash->{tophone} = $CO->contactphone;
		#$c->stash->{tocustomernumber} = $CO->ordernumber;
		$c->stash->{toemail} = $CO->shipmentnotification;
		$c->stash->{ordernumber} = $CO->ordernumber;
		$c->stash->{toAddress} = $CO->to_address;
		}

	## Package Details
	if (!$populate or $populate eq 'shipment')
		{
		## Shipment Information
		$c->stash->{datetoship} = IntelliShip::DateUtils->american_date($CO->datetoship);
		$c->stash->{dateneeded} = IntelliShip::DateUtils->american_date($CO->dateneeded);

		$c->stash->{'totalweight'} = 0;
		$c->stash->{'totalpackages'} = 0;my $rownum_id = 0;
		my $package_detail_section_html;

		# Step 1: Find Packages belog to Order
		my $find_package = {};
		$find_package->{'ownerid'} = $CO->coid;
		$find_package->{'ownertypeid'} = '1000';
		$find_package->{'datatypeid'} = '1000';

		my @packages = $c->model('MyDBI::Packprodata')->search($find_package);

		foreach my $Package (@packages)
			{
			$rownum_id++;
			$c->stash->{'totalpackages'}++;
			$package_detail_section_html .= $self->add_detail_row('package',$rownum_id, $Package);

			# Step 3: Find Product belog to Package
			my $WHERE = { ownerid => $Package->packprodataid };
			$WHERE->{'ownertypeid'}  = '3000';
			$WHERE->{'datatypeid'}   = '2000';

			my @arr = $Package->products;

			foreach my $Packprodata (@arr)
				{
				$rownum_id++;
				$package_detail_section_html .= $self->add_detail_row('product',$rownum_id, $Packprodata);
				}
			}

		## Don't move this above foreach block
		$c->stash->{description} = $CO->description;

		# Step 3: Find product belog to Order
		my $find_product = {};
		$find_product->{'ownerid'}      = $CO->coid;
		$find_product->{'ownertypeid'}  = '1000';
		$find_product->{'datatypeid'}   = '2000';

		my @products = $c->model('MyDBI::Packprodata')->search($find_product);

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
		unless ($total_weight)
			{
			$insurance += $_->decval foreach @packages;
			}

		$c->stash->{dateneeded} = IntelliShip::DateUtils->american_date($CO->dateneeded);
		$c->stash->{total_packages} = @packages;
		$c->stash->{total_weight} = sprintf("%.2f",$total_weight);
		$c->stash->{insurance} = sprintf("%.2f",$insurance);
		#$c->stash->{international} = '';

		my @special_services = $CO->assessorials;
		my %serviceHash =  map { $_->assname => 1 } @special_services;
		my $special_service_loop = $self->get_select_list('SPECIAL_SERVICE');
		my $selected_special_service_loop = [grep { $serviceHash{$_->{'value'}} } @$special_service_loop];
		$c->stash->{selected_special_service_loop} = $selected_special_service_loop;
		#$c->log->debug("selected_special_service_loop: " . Dumper $selected_special_service_loop);
		}
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

	my $Unittype;
	if ($c->stash->{review_order})
		{
		$c->stash->{REVIEW_PKG_DETAIL_ROW} = 1;
		$c->stash->{'totalweight'} += $PackProData->weight;
		$Unittype = $self->context->model('MyDBI::Unittype')->find({unittypeid => $PackProData->unittypeid});
		}
	else
		{
		$c->stash->{PKG_DETAIL_ROW} = 1;

		$c->stash->{packageunittype_loop} = $self->get_select_list('UNIT_TYPE');
		}

	$c->stash->{'weight'}      = $PackProData->weight;
	$c->stash->{'class'}       = $PackProData->class;
	$c->stash->{'dimweight'}   = $PackProData->dimweight;
	$c->stash->{'unittype'}    = $PackProData->unittypeid;
	$c->stash->{'unittype'}    = $Unittype->unittypename if ($c->stash->{review_order});
	$c->stash->{'sku'}         = $PackProData->partnumber;
	$c->stash->{'description'} = $PackProData->description;
	$c->stash->{'quantity'}    = $PackProData->quantity;
	$c->stash->{'quantity'}    = $PackProData->boxnum;
	$c->stash->{'frtins'}      = $PackProData->frtins;
	$c->stash->{'nmfc'}        = $PackProData->nmfc;
	$c->stash->{'decval'}      = $PackProData->decval;
	$c->stash->{'dimlength'}   = $PackProData->dimlength;
	$c->stash->{'dimwidth'}    = $PackProData->dimwidth;
	$c->stash->{'dimheight'}   = $PackProData->dimheight;
	$c->stash->{'density'}     = $PackProData->density;

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

	my $CO = $self->get_order;
	my $Customer = $self->customer;

	if (length $params->{'defaultcsid'} and $params->{'defaultcsidtotalcost'} > 0 and $params->{'defaultcsid'} ne $params->{'customerserviceid'})
		{
		$self->CheckChargeThreshold;
		}

	## Create or Update the thirdpartyacct table with address info if this is 3rd party
	if ($params->{'deliverymethod'} eq '3rdparty')
		{
		$self->save_third_party_details;
		}

	# Instantiate shipmentcharge object for further use
	my $ShipmentCharge = $c->model("MyDBI::Shipmentcharge")->new();

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

	## 'OTHER' carriers
	if ($params->{'customerserviceid'} =~ m/OTHER_/)
		{
		my ($CustomerServiceID) = $params->{'customerserviceid'} =~ m/OTHER_(.*)/;
		if ($CustomerServiceID eq 'NEW')
			{
			my $Other = $c->model("MyDBI::Other")->new();
			$Other->insert({
				'othername' => $params->{'other'},
				'customerid' => $CustomerID,
				});
			$params->{'customerserviceid'} = 'OTHER_' . $Other->otherid;
			}

		$params->{'quantity'}=0;
		$params->{'dimweight'}=0;
		$params->{'enteredweight'}=0;

		my @packages = $CO->packages;
		foreach my $Package (@packages)
			{
			$params->{'enteredweight'} += $Package->weight;
			$params->{'dimweight'} += $Package->dimweight;
			$params->{'quantity'} += $Package->quantity;
			}
		}
	else ## 'Normal' carriers
		{
		# Process small/freight shipments (mainly FedEx freight, on the freight end)
		if ($ServiceTypeID < 3000)
			{
			$params->{'enteredweight'} = 0;
			$params->{'dimweight'}     = 0;
			$params->{'dimlength'}     = 0;
			$params->{'dimwidth'}      = 0;
			$params->{'dimheight'}     = 0;
			$params->{'extcd'}         = 0;

			# Get shipment charges and fsc's sorted out for overridden shipment.
			if ($params->{'fcchanged'} and $params->{'fcoverride'})
				{
				$self->ProcessFCOverride;
				}

			# Save out all shipment packages. Give them a dummy shipmentid, pass that around for continuity.
			my $DummyShipmentID = $self->get_token_id;
			$c->log->debug("___ Dummy Shipment ID: " . $DummyShipmentID);

			my @packages = $CO->packages;
			foreach my $Package (@packages)
				{
				my $ShipmentPackage = $self->model('MyDBI::Packprodata')->new($Package->{'_column_data'});
				$ShipmentPackage->ownertypeid(2000); # Shipment
				$ShipmentPackage->ownerid($DummyShipmentID);
				$ShipmentPackage->packprodataid($self->get_token_id);

				$ShipmentPackage->insert;

				$c->log->debug("___ new shipment package insert: " . $ShipmentPackage->packprodataid);

				my @products = $Package->products;

				foreach my $Product (@products)
					{
					my $ShipmentProduct = $self->model('MyDBI::Packprodata')->new($Product->{'_column_data'});
					$ShipmentProduct->ownertypeid(3000); # Product (for Packages)
					$ShipmentProduct->ownerid($ShipmentPackage->packprodataid);
					$ShipmentProduct->packprodataid($self->get_token_id);

					$ShipmentProduct->insert;

					$c->log->debug("___ new shipment product insert: " . $ShipmentProduct->packprodataid);
					}
				}

			# Push all shipmentcharges onto a list for use by all shipments
			if ($params->{'packagecosts'} > 0)
				{
				$params->{'shipmentchargepassthru'} = $ShipmentCharge->BuildShipmentChargePassThru($params);
				$c->log->debug("___ shipmentchargepassthru: " . $params->{'shipmentchargepassthru'});
				}

			# Extract shipment specific data for use in the shipping process
			if ( $params->{'fakeitemids'} )
				{
				#$params = $self->GetCurrentPackage;
				}
			}
		elsif ($ServiceTypeID == 3000) ## Process LTL shipments
			{
			$params->{'quantity'}      = 0;
			$params->{'dimweight'}     = 0;
			$params->{'enteredweight'} = 0;

			my @packages = $CO->packages;
			foreach my $Package (@packages)
				{
				$params->{'enteredweight'} += $Package->weight;
				$params->{'dimweight'} += $Package->dimweight;
				$params->{'quantity'} += $Package->quantity;
				}
			}
		}

	# Kludge to get dry ice weight list built up for propagation
	if ($params->{'dryicewt'} or $params->{'dryicewtlist'})
		{
		($params->{'dryicewt'},$params->{'dryicewtlist'}) = $self->BuildDryIceWt;
		}

	# Build up shipment ref
	my $ShipmentData = $self->BuildShipmentInfo;

	# Get third party address bits into params (in case we picked up a 3p account from 'BuildShipmentData'
	my $ThirdPartyAccountObj;
	if ($ShipmentData->{'billingaccount'} and $ThirdPartyAccountObj = $Customer->third_party_account($ShipmentData->{'billingaccount'}))
		{
		$params->{'tpcompanyname'} = $ThirdPartyAccountObj->tpcompanyname;
		$params->{'tpaddress1'}    = $ThirdPartyAccountObj->tpaddress1;
		$params->{'tpaddress2'}    = $ThirdPartyAccountObj->tpaddress2;
		$params->{'tpcity'}        = $ThirdPartyAccountObj->tpcity;
		$params->{'tpstate'}       = $ThirdPartyAccountObj->tpstate;
		$params->{'tpzip'}         = $ThirdPartyAccountObj->tpzip;
		$params->{'tpcountry'}     = $ThirdPartyAccountObj->tpcountry;
		}

	# Kludge to get freightinsurance into the shipments
	my $SaveFreightInsurance = $ShipmentData->{'freightinsurance'};
	$ShipmentData->{'freightinsurance'} = $params->{'frtins'};

	###################################################################
	## Process shipment down through the carrrier handler
	## (online, customerservice, service, carrier handler).
	###################################################################
	my $Handler = IntelliShip::Carrier::Handler->new;
	$Handler->request_type(&REQUEST_TYPE_SHIP_ORDER);
	$Handler->token($self->get_login_token);
	$Handler->context($self->context);
	$Handler->customer($self->customer);
	$Handler->carrier(&CARRIER_FEDEX);
	$Handler->CO($CO);
	$Handler->request_data($ShipmentData);

	my $Response = $Handler->process_request({
			NO_TOKEN_OPTION => 0
			});

	# Process errors
	unless ($Response->is_success)
		{
		print STDERR "\n Error: " . Dumper $Response->errors;
		return;
		}

	my $Shipment = $Response->shipment;
	$ShipmentData->{'freightinsurance'} = $SaveFreightInsurance;

	# Kludge to maintain 'pickuprequest' $params->{'storepickuprequest'} = $params->{'pickuprequest'};
	$params = {%$params, %$Shipment};
	$params->{'pickuprequest'} = $params->{'storepickuprequest'};

	# Process good shipment

	# If the customer has an email address, check to see if the shipment address is different # from the co address (and send an email, if it is)
	my $ToEmail = $Customer->losspreventemail;
	my $CustomerName = $Customer->customername;

	if ($ToEmail)
		{
		$self->IsShipmentModified(
				$ToEmail,
				$CustomerName,
				$params->{'ordernumber'},
				$params->{'active_username'},
				$params->{'cotypeid'},
				$ShipmentData
			);
		}

	# If the csid was changed from the defaultcsid log the activity in the notes table
	if ($params->{'defaultcsid'} > 0 and $params->{'customerserviceid'} > 0 and $params->{'defaultcsid'} != $params->{'customerserviceid'})
		{
		$self->NoteCSIDOverride($params);
		}

	# Save out shipment packages
	my $PPD = new PACKPRODATA($self->{'dbref'}->{'aos'}, $self->{'customer'});

	if ($ServiceTypeID)
		{
		# Process small/freight shipments (mainly FedEx freight, on the freight end)
		if ( $ServiceTypeID < 3000 )
			{
			# Save out shipment charges
			$params->{'shipmentchargepassthru'} =
				$ShipmentCharge->SaveSmallShipmentCharges($params->{'shipmentchargepassthru'},$params->{'shipmentid'});

			(my $FakeItemID, $params->{'fakeitemids'}) = $params->{'fakeitemids'} =~ /^(\w{13}):(.*)/;

			$PPD->ReassignItemID($FakeItemID,$params->{'shipmentid'},2000);
			}
		# Process LTL shipments
		elsif ( $ServiceTypeID == 3000 )
			{
			# Save out shipment charges
			$ShipmentCharge->SaveShipmentCharges($params);

			# Save out shipment packages
			$PPD->SaveItems($params,2000);
			}
		}
	else # This will theoretically do 'Other' carriers
		{
		# Save out shipment packages
		$PPD->SaveItems($params,2000);
		}

	#Now that we have everything pushed into our params...
	#Check for Products and override screen if we have any
	my $PNPPPD = new PACKPRODATA($self->{'dbref'}->{'aos'}, $self->{'customer'});
	my $has_pnp = $PNPPPD->HasPickAndPack($params->{'coid'});
	if ( $has_pnp > 0 )
		{
		$PNPPPD->SavePickAndPack($params);
		}

	# Change fullfillment status - PO or Pick & Pack Only
	if ( $params->{'cotypeid'} == 2 or $has_pnp )
		{
		if( $CO->IsFullfilled($params->{'ordernumber'},$params->{'cotypeid'}) )
			{
			# Set PO to 'Fullfilled'
			$CO->ChangeStatus(350);
			}
		else
			{
			# Set PO to 'Unfullfilled'
			$CO->ChangeStatus(300);
			}
		}

	# If we don't have a csid and service, and *do* have a freight charge (s/b through overrride),
	# stuff a shipment charge entry in - this is an 'Other' shipment with an overriden freight charge
	if (!$params->{'customerserviceid'} and !$params->{'service'} and $params->{'freightcharge'})
		{
		$ShipmentCharge->SaveShipmentCharge($params->{'shipmentid'},'Freight Charge',$params->{'freightcharge'});
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

	# Save out shipment assessorials
	$self->SaveAssessorials($params,$params->{'shipmentid'},2000);
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
	my $params = $c->params;

	my $ShipmentData = {};

	$ShipmentData->{'addressname'} = $params->{'addressname'};
	$ShipmentData->{'address1'} = $params->{'address1'};
	$ShipmentData->{'address2'} = $params->{'address2'};
	$ShipmentData->{'addresscity'} = $params->{'addresscity'};
	$ShipmentData->{'addressstate'} = $params->{'addressstate'};
	$ShipmentData->{'addresszip'} = $params->{'addresszip'};
	$ShipmentData->{'addresscountry'} = $params->{'addresscountry'};
	$ShipmentData->{'customername'} = $params->{'customername'};
	$ShipmentData->{'branchaddress1'} = $params->{'branchaddress1'};
	$ShipmentData->{'branchaddress2'} = $params->{'branchaddress2'};
	$ShipmentData->{'branchaddresscity'} = $params->{'branchaddresscity'};
	$ShipmentData->{'branchaddressstate'} = $params->{'branchaddressstate'};
	$ShipmentData->{'branchaddresszip'} = $params->{'branchaddresszip'};
	$ShipmentData->{'branchaddresscountry'} = $params->{'branchaddresscountry'};
	$ShipmentData->{'contactname'} = $params->{'contactname'};
	$ShipmentData->{'contactphone'} = $params->{'contactphone'};
	$ShipmentData->{'contacttitle'} = $params->{'contacttitle'};
	$ShipmentData->{'dimlength'} = $params->{'dimlength'};
	$ShipmentData->{'dimwidth'} = $params->{'dimwidth'};
	$ShipmentData->{'dimheight'} = $params->{'dimheight'};
	$ShipmentData->{'dimunits'} = $params->{'dimunits'};
	$ShipmentData->{'currencytype'} = $params->{'currencytype'};
	$ShipmentData->{'destinationcountry'} = $params->{'destinationcountry'};
	$ShipmentData->{'manufacturecountry'} = $params->{'manufacturecountry'};
	$ShipmentData->{'dutypaytype'} = $params->{'dutypaytype'};
	$ShipmentData->{'termsofsale'} = $params->{'termsofsale'};
	$ShipmentData->{'commodityquantity'} = $params->{'commodityquantity'};
	$ShipmentData->{'commodityweight'} = $params->{'commodityweight'};
	$ShipmentData->{'commodityunitvalue'} = $params->{'commodityunitvalue'};
	$ShipmentData->{'commoditycustomsvalue'} = $params->{'commoditycustomsvalue'};
	$ShipmentData->{'unitquantity'} = $params->{'unitquantity'};
	$ShipmentData->{'customsvalue'} = $params->{'customsvalue'};
	$ShipmentData->{'partiestotransaction'} = $params->{'partiestotransaction'};
	$ShipmentData->{'customsdesription'} = $params->{'customsdesription'};
	$ShipmentData->{'harmonizedcode'} = $params->{'harmonizedcode'};
	$ShipmentData->{'ssnein'} = $params->{'ssnein'};
	$ShipmentData->{'naftaflag'} = $params->{'naftaflag'};
	$ShipmentData->{'dutyaccount'} = $params->{'dutyaccount'};
	$ShipmentData->{'commodityunits'} = $params->{'commodityunits'};
	$ShipmentData->{'customsdescription'} = $params->{'customsdescription'};
	$ShipmentData->{'bookingnumber'} = $params->{'bookingnumber'};
	$ShipmentData->{'slac'} = $params->{'slac'};
	$ShipmentData->{'weighttype'} = $params->{'weighttype'};
	$ShipmentData->{'dimunits'} = $params->{'dimunits'};
	$ShipmentData->{'billingaccount'} = $params->{'billingaccount'};
	$ShipmentData->{'billingpostalcode'} = $params->{'billingpostalcode'};
	$ShipmentData->{'tracking1'} = $params->{'tracking1'};
	$ShipmentData->{'defaultcsid'} = $params->{'defaultcsid'};
	$ShipmentData->{'carrier'} = $params->{'carrier'};
	$ShipmentData->{'service'} = $params->{'service'};
	$ShipmentData->{'quantity'} = $params->{'quantity'};
	$ShipmentData->{'coid'} = $params->{'coid'};
	$ShipmentData->{'datetoship'} = IntelliShip::DateUtils->american_date($params->{'datetoship'});
	$ShipmentData->{'dateneeded'} = IntelliShip::DateUtils->american_date($params->{'dateneeded'});
	$ShipmentData->{'freightinsurance'} = $params->{'freightinsurance'};
	$ShipmentData->{'ordernumber'} = $params->{'ordernumber'};
	$ShipmentData->{'dimweight'} = $params->{'dimweight'};
	$ShipmentData->{'density'} = $params->{'density'};
	$ShipmentData->{'description'} = $params->{'description'};
	$ShipmentData->{'ipaddress'} = $params->{'ipaddress'};
	$ShipmentData->{'custnum'} = $params->{'custnum'};
	$ShipmentData->{'shipasname'} = $params->{'customername'};
	$ShipmentData->{'extcd'} = $params->{'extcd'};
	$ShipmentData->{'shipmentnotification'} = $params->{'shipmentnotification'};
	$ShipmentData->{'deliverynotification'} = $params->{'deliverynotification'};
	$ShipmentData->{'hazardous'} = $params->{'hazardous'};
	$ShipmentData->{'tpcompanyname'} = $params->{'tpcompanyname'};
	$ShipmentData->{'tpaddress1'} = $params->{'tpaddress1'};
	$ShipmentData->{'tpaddress2'} = $params->{'tpaddress2'};
	$ShipmentData->{'tpcity'} = $params->{'tpcity'};
	$ShipmentData->{'tpstate'} = $params->{'tpstate'};
	$ShipmentData->{'tpzip'} = $params->{'tpzip'};
	$ShipmentData->{'tpcountry'} = $params->{'tpcountry'};
	$ShipmentData->{'manualthirdparty'} = $params->{'manualthirdparty'};
	$ShipmentData->{'ponumber'} = $params->{'ponumber'};
	$ShipmentData->{'securitytype'} = $params->{'securitytype'};
	$ShipmentData->{'contactid'} = $params->{'contactid'};
	$ShipmentData->{'originid'} = 3;
	$ShipmentData->{'insurance'} = $params->{'insurance'};
	$ShipmentData->{'extid'} = $params->{'extid'};
	$ShipmentData->{'custref2'} = $params->{'custref2'};
	$ShipmentData->{'custref3'} = $params->{'custref3'};
	$ShipmentData->{'department'} = $params->{'department'};
	$ShipmentData->{'freightcharges'} = $params->{'freightcharges'};
	$ShipmentData->{'oacontactname'} = $params->{'branchcontact'};
	$ShipmentData->{'oacontactphone'} = $params->{'branchphone'};
	$ShipmentData->{'isinbound'} = $params->{'isinbound'};
	$ShipmentData->{'isdropship'} = $params->{'isdropship'};
	$ShipmentData->{'datereceived'} = IntelliShip::DateUtils->american_date_time($params->{'datereceived'});
	$ShipmentData->{'datepacked'} = IntelliShip::DateUtils->american_date_time($params->{'datepacked'});
	$ShipmentData->{'daterouted'} = IntelliShip::DateUtils->american_date_time($params->{'daterouted'});
	$ShipmentData->{'cfcharge'} = $params->{'cfcharge'};
	$ShipmentData->{'usealtsop'} = $params->{'usealtsop'};
	$ShipmentData->{'usingaltsop'} = $params->{'usingaltsop'};
	$ShipmentData->{'quantityxweight'} = $params->{'quantityxweight'};
	$ShipmentData->{'dryicewt'} = $params->{'dryicewt'};
	$ShipmentData->{'dryicewtlist'} = $params->{'dryicewtlist'};
	$ShipmentData->{'dgunnum'} = $params->{'dgunnum'};
	$ShipmentData->{'dgpkgtype'} = $params->{'dgpkgtype'};
	$ShipmentData->{'dgpkginstructions'} = $params->{'dgpkginstructions'};
	$ShipmentData->{'dgpackinggroup'} = $params->{'dgpackinggroup'};
	$ShipmentData->{'assessorial_names'} = $params->{'assessorial_names'};

	if ($params->{'aostype'} == 1)
		{
		$ShipmentData->{'shipqty'} = $params->{'shipqty'};
		$ShipmentData->{'shiptypeid'} = $params->{'shiptypeid'};
		}

	# undef billingaccount if it came through the interface as tp but it is in the db already as fedex hack thirdpartyacct which really isn't tp
	if ($params->{'customerserviceid'} and $params->{'billingaccount'} and !$self->API->valid_billing_account($params->{'customerserviceid'},$params->{'billingaccount'}))
		{
		$params->{'billingaccount'} = undef;
		}

	if ( defined($params->{'billingaccount'}) and $params->{'billingaccount'} ne '' )
		{
		$ShipmentData->{'thirdpartybilling'} = 1;
		}

	my $myDBI = $c->model->('MyDBI');
	# Get Country Name - for DHL mainly at this point, but likely others will come up.
	if ($ShipmentData->{'addresscountry'})
		{
		my $sth = $myDBI->select->("SELECT countryname FROM country WHERE countryiso2 = '" . $ShipmentData->{'addresscountry'} . "'");
		$ShipmentData->{'addresscountryname'} = $sth->fetchrow(0)->{'countryname'} if $sth->numrows;
		}

	# If carrier/service is FedEx/Freight, set 3rd party billing to the Engage heavy account
	my $host_name = IntelliShip::MyConfig->getHostname;
	if ($params->{'carrier'} eq 'FedEx' and $params->{'service'} =~ /Freight/ and !$params->{'billingaccount'} and $host_name !~ /rml/)
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
			}

		if ( $ThirdPartyAcct =~ m/^engage::(.*?)$/ )
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

sub IsShipmentModified
	{
	my $self = shift;
	my ($COTypeID,$ShipmentData) = @_;

	# Load CO so we we can check against what was actually shipped.
	my $CO = $self->get_order;
	my $coid = '';

	my $OriginalAddress = $CO->to_address;

	if ($OriginalAddress->addressname ne $ShipmentData->{'addressname'} or
		$OriginalAddress->address1 ne $ShipmentData->{'address1'} or
		$OriginalAddress->address2 ne $ShipmentData->{'address2'} or
		$OriginalAddress->city ne $ShipmentData->{'addresscity'} or
		$OriginalAddress->state ne $ShipmentData->{'addressstate'} or
		$OriginalAddress->zip ne $ShipmentData->{'addresszip'} or
		$OriginalAddress->country ne $ShipmentData->{'addresscountry'})
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

	if (!$page or $page eq 'address')
		{
		$requiredList = [
			{ name => 'fromemail', details => "{ email: false }"},
			{ name => 'toname', details => "{ minlength: 2 }"},
			{ name => 'toaddress1', details => "{ minlength: 2 }"},
			{ name => 'tocity', details => " { minlength: 2 }"},
			{ name => 'tostate', details => "{ minlength: 2 }"},
			{ name => 'tozip', details => "{ minlength: 5 }"},
			{ name => 'tocountry', details => "{ minlength: 2 }"},
			{ name => 'tophone', details => "{ phone: false }"},
			{ name => 'toemail', details => "{ email: false }"},
		];

		unless ($Customer->login_level == 25)
			{
			if ($c->stash->{one_page})
				{
				push(@$requiredList, { name => 'datetoship', details => "{ date: true }"}) if $Customer->reqdatetoship and $Customer->allowpostdating;
				push(@$requiredList, { name => 'dateneeded', details => "{ date: true }"}) if $Customer->reqdateneeded;
				}

			push(@$requiredList, { name => 'tocustomernumber', details => "{ minlength: 2 }"}) if $Customer->reqcustnum;
			push(@$requiredList, { name => 'ponumber', details => "{ minlength: 2 }"}) if $Customer->reqponum;
			push(@$requiredList, { name => 'ordernumber', details => "{ minlength: 2 }"}) if $Customer->get_contact_data_value('reqordernumber');
			push(@$requiredList, { name => 'extid', details => "{ minlength: 2 }"}) if $Customer->get_contact_data_value('reqextid');
			push(@$requiredList, { name => 'custref2', details => "{ minlength: 2 }"}) if $Customer->get_contact_data_value('reqcustref2');
			push(@$requiredList, { name => 'custref3', details => "{ minlength: 2 }"}) if $Customer->get_contact_data_value('reqcustref3');
			push(@$requiredList, { name => 'fromdepartment', details => "{ minlength: 2 }"}) if $Customer->get_contact_data_value('reqdepartment');
			}
		}
	if (!$page or $page eq 'shipment')
		{
		unless ($Customer->login_level == 25 or $c->stash->{one_page})
			{
			push(@$requiredList, { name => 'datetoship', details => "{ date: true }"}) if $Customer->reqdatetoship and $Customer->allowpostdating;
			push(@$requiredList, { name => 'dateneeded', details => "{ date: true }"}) if $Customer->reqdateneeded;
			}
		push(@$requiredList, { name => 'package-detail-list', details => "{ method: validate_package_details }"})
		}

	#$c->log->debug("requiredfield_list: " . Dumper $requiredList);
	$c->stash->{requiredfield_list} = $requiredList;
	}

__PACKAGE__->meta->make_immutable;

1;
