package IntelliShip::Controller::Customer::Order;
use Moose;
use Data::Dumper;
use IntelliShip::Utils;
use namespace::autoclean;

BEGIN { extends 'IntelliShip::Controller::Customer'; has 'CO' => ( is => 'rw' ); }

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

	#($params->{'ordernumber'},$params->{'hasautoordernumber'}) = $self->get_auto_order_number($params->{'ordernumber'});

	$c->stash->{neworder} = 1;
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
	$c->stash->{deliverymethod} = "prepaid";

	$c->stash(template => "templates/customer/order.tt");
	}

sub save_order :Private
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	$c->log->debug("check order in");

	my $CO = $self->get_order;

	my $coData = {};

	$coData->{'datetoship'} = IntelliShip::DateUtils->get_db_format_date_time($params->{'datetoship'});
	$coData->{'dateneeded'} = IntelliShip::DateUtils->get_db_format_date_time($params->{'dateneeded'});

	$coData->{'description'} = $params->{'description'};
	#$coData->{'extcd'} = $params->{'comments'};
	$coData->{'extloginid'} = $self->customer->username;
	$coData->{'contactname'} = $params->{'tocontact'};
	$coData->{'contactphone'} = $params->{'tophone'};
	$coData->{'department'} = $params->{'fromdepartment'};
	$coData->{'shipmentnotification'} = $params->{'toemail'};
	$coData->{'deliverynotification'} = $params->{'fromemail'};

	#$OrderRef->{'cotypeid'} = $HashRef->{'action'} eq 'clearquote' ? 10 : 1;
	#
	#if (
	#	$HashRef->{'loginlevel'} == 35 ||
	#	$HashRef->{'loginlevel'} == 40 ||
	#	( $HashRef->{'cotypeid'} && $HashRef->{'cotypeid'} == 2 )
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

	## SAVE ADDRESS DETAILS
	$self->save_address;

	## SAVE PACKAGE & PRODUCT DETAILS
	$self->save_package_product_details;

	## Display Order Review Page
	$self->setup_summary_page;
	}

sub save_address
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	$c->log->debug("... save address details");

	IntelliShip::Utils->trim_hash_ref_values($params);

	my $CO = $self->get_order;

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
		}

	$CO->update;
	}

sub get_row_id
	{
	my $self = shift;
	my $index = shift;

	my $params = $self->context->req->params;

	foreach (keys %$params)
		{
		return $1 if $_ =~ m/^rownum_id_(\d+)$/ and $params->{$_} == $index;
		}
	}

sub save_package_product_details
	{
	my $self = shift;

	my $c = $self->context;
	my $params = $c->req->params;

	$c->log->debug("... save package product details");

	my $CO = $self->get_order;
	my $total_row_count = int $params->{'pkg_detail_row_count'};

	my $last_package_id=0;
	for (my $index=1; $index <= $total_row_count; $index++)
		{
		# If we're a package...the last id we got back was the id of a package.
		# Save it out so following products will get owned by it.
		# If this is a product, and we have a packageid, the ownertype needs to be a package
		my $PackageIndex = int $self->get_row_id($index);

		$c->log->debug("PackageIndex: " . $PackageIndex);

		my $ownerid = $CO->coid;
		$ownerid = $last_package_id if ($params->{'type_' . $PackageIndex } eq 'product');

		my $PackProData = {
				ownerid     => $ownerid,
				boxnum      => $params->{'quantity_' . $PackageIndex },
				quantity    => $params->{'quantity_' . $PackageIndex },
				partnumber  => $params->{'sku_' . $PackageIndex },
				description => $params->{'description_' . $PackageIndex },
				unittypeid  => $params->{'unittype_' . $PackageIndex },
				weight      => int $params->{'weight_' . $PackageIndex },
				dimweight   => int $params->{'dimweight_' . $PackageIndex },
				dimlength   => int $params->{'dimlength_' . $PackageIndex },
				dimwidth    => int $params->{'dimwidth_' . $PackageIndex },
				dimheight   => int $params->{'dimheight_' . $PackageIndex },
				density     => int $params->{'density_' . $PackageIndex },
				class       => int $params->{'class_' . $PackageIndex },
				frtins      => int $params->{'frtins_' . $PackageIndex},
				nmfc        => int $params->{'nmfc_' . $PackageIndex },
				decval      => int $params->{'decval_' . $PackageIndex },
			};

		$c->log->debug("PackProData: " . Dumper $PackProData);

		my $PackProDataObj = $c->model("MyDBI::Packprodata")->new($PackProData);
		$PackProDataObj->packprodataid($self->get_token_id);
		$PackProDataObj->insert;

		$c->log->debug("New Packprodata Inserted, ID: " . $PackProDataObj->packprodataid);

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

	$c->log->debug("get_auto_order_number OUT ordernumber=$OrderNumber") if $OrderNumber;

	return ($OrderNumber,$HasAutoOrderNumber);
	}

sub get_order
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	return $self->CO if $self->CO;

	if ($params->{'coid'})
		{
		my $CO = $c->model('MyDBI::Co')->find({ coid => $params->{'coid'} });
		$c->log->debug("Existing CO Found, ID: " . $CO->coid);
		$self->CO($CO);
		}
	else
		{
		## Set default cotypeid (Default to vanilla 'Order')
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
			$c->log->debug("_______ NO CO FOUND _______");
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

sub setup_summary_page
	{
	my $self = shift;
	my $c = $self->context;

	$c->stash->{review_order} = 1;
	$self->populate_order;
	$c->stash(template => "templates/customer/order-review.tt");
	}

sub populate_order
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	my $CO = $self->get_order;

	my $ToAddress = $CO->to_address;

	$c->stash->{toAddress} = $ToAddress;

	## Initialize Screen
	$self->setup;
	$c->stash->{coid} = $CO->coid;
	$c->stash->{edit_order} = 1;

	## Ship From Section
	$c->stash->{fromemail} = $CO->deliverynotification;

	## Ship To Section
	$c->stash->{toname} = $ToAddress->addressname;
	$c->stash->{toaddress1} = $ToAddress->address1;
	$c->stash->{toaddress2} = $ToAddress->address2;
	$c->stash->{tocity} = $ToAddress->city;
	$c->stash->{tostate} = $ToAddress->state;
	$c->stash->{tozip} = $ToAddress->zip;
	$c->stash->{tocountry} = $ToAddress->country;
	$c->stash->{tocontact} = $CO->contactname;
	$c->stash->{tophone} = $CO->contactphone;
	$c->stash->{toemail} = $CO->shipmentnotification;
	$c->stash->{ordernumber} = $CO->ordernumber;
	$c->stash->{dateneeded} = $CO->dateneeded;

	# Ship Information
	$c->stash->{comments} = $CO->description;

	# Package Details
	$c->stash->{'totalweight'} = 0;
	$c->stash->{'totalpackages'} = 0;
	$self->populate_package_detail_section;

	# ASSESSORIALS SECTION 1000 for co and 2000 for shipment
	$c->stash->{specialservice_loop} = $self->populate_assessorials_section;
	}

sub populate_package_detail_section
	{
	my $self = shift;
	my $c = $self->context;

	my $CO = $self->get_order;

	my $rownum_id = 0;
	my $package_detail_section_html;

	# Step 1: Find Packages belog to Order
	my $find_package = {};
	$find_package->{'ownerid'} = $CO->coid;
	$find_package->{'ownertypeid'} = '1000';
	$find_package->{'datatypeid'} = '1000';

	my @packages = $c->model('MyDBI::Packprodata')->search($find_package);

	foreach my $PackageData (@packages)
		{
		$rownum_id++;
		$c->stash->{'totalpackages'}++;
		$package_detail_section_html .= $self->add_detail_row('package',$rownum_id, $PackageData);

		# Step 3: Find Product belog to Package
		my $WHERE = { ownerid => $PackageData->packprodataid };
		$WHERE->{'ownertypeid'}  = '3000';
		$WHERE->{'datatypeid'}   = '2000';

		my @arr = $c->model('MyDBI::Packprodata')->search($WHERE);
		foreach my $Packprodata (@arr)
			{
			$rownum_id++;
			$package_detail_section_html .= $self->add_detail_row('product',$rownum_id, $Packprodata);
			}
		}

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

	return $c->forward($c->view('Ajax'), "render", [ "templates/customer/ajax.tt" ]);
	}

sub populate_assessorials_section
	{
	my $self = shift;
	my $c = $self->context;

	my $special_service_loop = $self->get_select_list('SPECIAL_SERVICE');
	my $specialService = $self->get_special_services;

	foreach my $SpecialService (@$special_service_loop)
		{
		$SpecialService->{'checked'} = 'CHECKED' if $specialService->{$SpecialService->{'value'}};
		}

	return $special_service_loop;
	}

sub get_special_services
	{
	my $self = shift;
	my $COID = $self->CO->coid;

	return unless $COID;

	my $specialService = {};
	my $sql = "SELECT assname FROM assdata WHERE ownerid = '$COID'";
	my $STH = $self->context->model("MyDBI")->select("$sql");
	my $data = $STH->query_data;

	$specialService->{$_} = 1 foreach @$data;
	return $specialService;
	}

__PACKAGE__->meta->make_immutable;

1;
