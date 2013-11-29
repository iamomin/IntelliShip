package IntelliShip::Controller::Customer::Order;
use Moose;
use Data::Dumper;
use IntelliShip::Utils;
use namespace::autoclean;

BEGIN { extends 'IntelliShip::Controller::Customer'; }

sub quickship :Local
	{
	my $self = shift;
	my $c = $self->context;
	$self->setup;
	$c->stash->{quickship} = 1;
	$c->stash->{title} = 'Quick Ship Order';
	}

sub setup :Private
	{
    my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	($params->{'ordernumber'},$params->{'hasautoordernumber'}) = $self->get_auto_order_number($params->{'ordernumber'});

	$c->stash->{ordernumber} = $params->{'ordernumber'};
	$c->stash->{customer} = $self->customer;
	$c->stash->{customerAddress} = $self->customer->address;
	$c->stash->{customerlist_loop} = $self->get_select_list('CUSTOMER');
	$c->stash->{countrylist_loop} = $self->get_select_list('COUNTRY');
	$c->stash->{statelist_loop} = $self->get_select_list('US_STATES');
	$c->stash->{specialservice_loop} = $self->get_select_list('SPECIAL_SERVICE');
	$c->stash->{packageunittype_loop} = $self->get_select_list('UNIT_TYPE');
	$c->stash->{deliverymethod_loop} = $self->get_select_list('DELIVERY_METHOD');

	$c->stash->{tocountry} = "US";
	$c->stash->{package_detail_row_count} = "1";

	$c->stash(template => "templates/customer/order.tt");
	}

sub save_order :Private
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	$c->log->debug("check order in");

	my $Order = $self->get_order;
	my $fromAddress = $self->customer->address;

	my $coData = {
		customerid => $self->customer->customerid,
		contactid => $self->contact->contactid,
		addressid => $fromAddress->addressid
		};

	$c->stash->{CO_DATA} = $coData;

	## Set default cotypeid (Default to vanilla 'Order')
	$coData->{'cotypeid'} = (length $params->{'cotypeid'} ? $params->{'cotypeid'} : 1);

	## SAVE ADDRESS DETAILS
	$self->save_address;

	## SAVE PACKAGE & PRODUCT DETAILS
	# $self->save_package_product_details;

	$coData->{'estimatedweight'} = $params->{'estimatedweight'};
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
	if ($params->{'coid'} and $self->get_shipment_count > 0)
		{
		$coData->{'statusid'} = 5;
		}

	## Sort out 'Other' carrier nonsense
	if ($params->{'customerserviceid'} and $params->{'customerserviceid'} =~ /^OTHER_(\w{13})/)
		{
		my $Other = $c->model('MyDBI::Other')->find({ customerid => $self->customer->customerid, otherid => $1 });
		$coData->{'extcarrier'} = 'Other - ' . $Other->othername if $Other;
		}

	my $CO;
	if ($params->{'coid'})
		{
		$CO = $c->model('MyDBI::Co')->find({ coid => $params->{'coid'} });
		$CO->update($coData);
		}
	else
		{
		$CO = $c->model('MyDBI::Co')->new($coData);
		$CO->coid($self->get_token_id);
		$CO->insert;
		}
	}

sub save_address
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	$c->log->debug("save address details");

	my $Order = $self->get_order;
	my $fromAddress = $self->customer->address;

	my $coData = $c->stash->{CO_DATA};

	my $toAddressData = {
			addressname => $params->{'toname'},
			address1    => $params->{'toaddress1'},
			address2    => $params->{'toaddress2'},
			city        => $params->{'tocity'},
			state       => $params->{'tostate'},
			zip         => $params->{'tozip'},
			country     => $params->{'tocountry'},
			};

	$c->log->debug("checking for dropship address availability");

	## Fetch ship from address
	my @addresses = $c->model('MyDBI::Address')->search($toAddressData);

	my $ToAddress;
	if (@addresses)
		{
		$ToAddress = $addresses[0];
		$c->log->debug("existing address found, ID" . $ToAddress->addressid);
		}
	else
		{
		$ToAddress = $c->model("MyDBI::Address")->new($toAddressData);
		$ToAddress->addressid($self->get_token_id);
		$ToAddress->set_address_code_details;
		$ToAddress->insert;
		$c->log->debug("no address found, inserted new address, ID" . $ToAddress->addressid);
		}

	$coData->{addressid} = $ToAddress->id;

	## Sort out return address/id
	if (length $params->{'rtaddress1'})
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

		my $ReturnAddress;
		if (@addresses)
			{
			$ReturnAddress = $addresses[0];
			$c->log->debug("existing address found, ID" . $ToAddress->addressid);
			}
		else
			{
			$ReturnAddress = $c->model("MyDBI::Address")->new($toAddressData);
			$ReturnAddress->addressid($self->get_token_id);
			$ReturnAddress->set_address_code_details;
			$ReturnAddress->insert;
			$c->log->debug("no address found, inserted new address, ID" . $ToAddress->addressid);
			}

		$coData->{rtaddressid} = $ReturnAddress->id;
		}

	}

sub get_row_id
	{
	my $self = shift;
	my $index = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	my $rownum_id;

	my @keys = grep { $params->{$_} == $index } keys %$params;
	foreach my $key (@keys)
		{
		if ($key =~ m/^rownum_id_/ and $params->{$key} == $index)
			{
			$rownum_id = $key;
			last;
			}
		}

	return $rownum_id;
	}

sub save_package_product_details
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	$c->log->debug("save package details");
	my $coData = $c->stash->{CO_DATA};

	my $Order = $self->get_order;
	my $total_row_count = $params->{'pkg_detail_row_count'};
	$total_row_count =~ s/^Package_Row_//;

	my $last_package_id=0;
	for (my $index=1; $index <= $total_row_count; $index++)
		{
		# If we're a package...the last id we got back was the id of a package.
		# Save it out so following products will get owned by it.
		# If this is a product, and we have a packageid, the ownertype needs to be a package
		my $PackageIndex = $self->get_row_id($index);
		$PackageIndex =~ s/^rownum_id_//;

		my $ownerid = $coData->{coid};
		$ownerid = $last_package_id if ($params->{'type_' . $PackageIndex } eq 'product');

		my $PackProData = {
				weight            => $params->{'weight_' . $PackageIndex },
				class             => $params->{'class_' . $PackageIndex },
				dimweight         => $params->{'dimweight_' . $PackageIndex },
				unittypeid        => $params->{'unittype_' . $PackageIndex },
				partnumber        => $params->{'sku_' . $PackageIndex },
				description       => $params->{'description_' . $PackageIndex },
				quantity          => $params->{'quantity_' . $PackageIndex },
				boxnum            => $params->{'quantity_' . $PackageIndex },
				frtins            => $params->{'frtins_' . $PackageIndex},
				nmfc              => $params->{'nmfc_' . $PackageIndex },
				decval            => $params->{'decval_' . $PackageIndex },
				dimlength         => $params->{'dimlength_' . $PackageIndex },
				dimwidth          => $params->{'dimwidth_' . $PackageIndex },
				dimheight         => $params->{'dimheight_' . $PackageIndex },
				density           => $params->{'density_' . $PackageIndex },
				ownerid           => $ownerid,
			};

		my $PackProDataObj = $c->model("MyDBI::Packprodata")->new($PackProData);
		$PackProDataObj->packprodataid($self->get_token_id);
		$PackProDataObj->insert;
		$c->log->debug("inserted new Packprodata, ID" . $PackProDataObj->packprodataid);
		$last_package_id = $PackProDataObj->packprodataid if ($params->{'type_' . $PackageIndex } eq 'package');
		}
=a
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

sub get_shipment_count
	{
	my $self = shift;
	my $c = $self->context;
	my $COID = $self->params->{'coid'};
	return unless $COID;
	my $STH = $c->model("MyDBI")->select("SELECT count(*) FROM shipment WHERE coid = '$COID' AND statusid NOT IN ('5','6','7')");
	my $Count = $STH->fetchrow(0)->{'count'};
	return $Count;
	}

sub get_auto_order_number
	{
	my $self = shift;
	my $OrderNumber = shift || "";

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

	$c->log->debug("get_auto_order_number OUT ordernumber=$OrderNumber");

	return ($OrderNumber,$HasAutoOrderNumber);
	}

sub get_order
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	my $cotypeid = $params->{'cotypeid'} || 1;
	my $ordernumber = $params->{'ordernumber'};
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
						customerid => $self->customer->customerid,
						ordernumber => uc($ordernumber),
						cotypeid => $cotypeid,
						extcustnum => $allowed_ext_cust_nums
						});

	unless (@cos)
		{
		@cos = $c->model('MyDBI::Co')->search({
						customerid => $self->customer->customerid,
						ordernumber => uc($ordernumber),
						cotypeid => $cotypeid
						});
		}

	$c->log->debug("total customer order found: " . @cos);

	my ($coid, $statusid) = (0,0);
	if (@cos)
		{
		my $data = $cos[0];
		($coid, $statusid, $ordernumber) = ($data->{'coid'},$data->{'statusid'},$data->{'ordernumber'});
		}

	$c->log->debug("coid: $coid , statusid: $statusid, ordernumber: $ordernumber");

	return($coid,$statusid,$ordernumber);
	}

sub populate_order
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	my $coid = $params->{'coid'};
	my $ordernumber = $params->{'ordernumber'};

	my $c = $self->context;
	$c->log->debug("populate_order, coid: $coid, ordernumber: $ordernumber");

	my $where = {};
	$where->{'customerid'}  = $self->customer->customerid;
	$where->{'coid'}        = $coid if ($coid);
	$where->{'ordernumber'} = $ordernumber if ($ordernumber);

	my @cos = $c->model('MyDBI::Co')->search($where);
	$c->log->debug("total customer order found: " . @cos);

	my $COData = $cos[0];
	$c->log->debug("populate_order, co:" . $COData->coid);
	$c->log->debug("populate_order, co:" . $COData->addressid);

	my $ToAddress = $COData->to_address;

	## Initialize Screen
	$self->setup;
	$c->stash->{title} = 'Edit Order';

	## Ship From Section
	$c->stash->{fromemail} = $COData->deliverynotification;

	## Ship To Section
	$c->stash->{toname} = $ToAddress->addressname;
	$c->stash->{toaddress1} = $ToAddress->address1;
	$c->stash->{toaddress2} = $ToAddress->address2;
	$c->stash->{tocity} = $ToAddress->city;
	$c->stash->{tostate} = $ToAddress->state;
	$c->stash->{tozip} = $ToAddress->zip;
	$c->stash->{tocountry} = $ToAddress->country;
	$c->stash->{tocontact} = $COData->contactname;
	$c->stash->{tophone} = $COData->contactphone;
	$c->stash->{toemail} = $COData->shipmentnotification;
	$c->stash->{ordernumber} = $COData->ordernumber;

	# Ship Information
	$c->stash->{comments} = $COData->description;

	# Package Details
	$self->populate_package_detail_section($COData);
	}

sub populate_package_detail_section
	{
	my $self = shift;
	my $COData = shift;
	my $c = $self->context;

	my $rownum_id = 0;
	my $package_detail_section_html;

	# Step 1: Find Packages belog to Order 
	my $find_package = {};
	$find_package->{'ownerid'} = $COData->coid;
	$find_package->{'ownertypeid'} = '1000';
	$find_package->{'datatypeid'} = '1000';

	my @packages = $c->model('MyDBI::Packprodata')->search($find_package);

	foreach my $PackageData (@packages)
		{
		$rownum_id++;
		$package_detail_section_html .= $self->add_detail_row('package',$rownum_id, $PackageData);

		# Step 3: Find Product belog to Package 
		my $find_product = {};
		$find_product->{'ownerid'}      = $PackageData->packprodataid;
		$find_product->{'ownertypeid'}  = '3000';
		$find_product->{'datatypeid'}   = '2000';

		my @products = $c->model('MyDBI::Packprodata')->search($find_product);
		$c->log->debug("total package products found: " . @products);

		foreach my $ProductData (@products)
			{
			$rownum_id++;
			$package_detail_section_html .= $self->add_detail_row('product',$rownum_id, $ProductData);
			}
		}

	# Step 3: Find product belog to Order 
	my $find_product = {};
	$find_product->{'ownerid'}      = $COData->coid;
	$find_product->{'ownertypeid'}  = '1000';
	$find_product->{'datatypeid'}   = '2000';

	my @products = $c->model('MyDBI::Packprodata')->search($find_product);
	$c->log->debug("total order prdt found: " . @products);

	foreach my $ProductData (@products)
		{
		$rownum_id++;
		$package_detail_section_html .= $self->add_detail_row('product',$rownum_id, $ProductData);
		}

	$c->stash->{package_detail_section} = $package_detail_section_html;
	$c->stash->{package_detail_row_count} = $rownum_id;
	}

sub add_detail_row
	{
	my $self = shift;
	my $type = shift;
	my $row_num_id = shift;
	my $PackProData = shift;
	my $c = $self->context;

	$c->stash->{PKG_DETAIL_ROW} = 1;
	$c->stash->{ROW_COUNT} = $row_num_id;
	$c->stash->{DETAIL_TYPE} = $type;
	$c->stash->{packageunittype_loop} = $self->get_select_list('UNIT_TYPE');

	$c->stash->{'weight'}      = $PackProData->weight;
	$c->stash->{'class'}       = $PackProData->class;
	$c->stash->{'dimweight'}   = $PackProData->dimweight;
	$c->stash->{'unittype'}    = $PackProData->unittypeid;
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

	my $row_HTML = $c->forward($c->view('Ajax'), "render", [ "templates/customer/ajax.tt" ]);
	$c->stash->{PKG_DETAIL_ROW} = 0;

	return $row_HTML;
	}

__PACKAGE__->meta->make_immutable;

1;
