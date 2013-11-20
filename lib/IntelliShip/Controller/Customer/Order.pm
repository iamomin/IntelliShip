package IntelliShip::Controller::Customer::Order;
use Moose;
use Data::Dumper;
use IntelliShip::Utils;
use namespace::autoclean;

BEGIN { extends 'IntelliShip::Controller::Customer'; }

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
	$self->save_package_product_details;

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

	$coData->{dropaddressid} = $ToAddress->id;

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

sub save_package_product_details
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	$c->log->debug("save address details");

	my $Order = $self->get_order;

	my $coData = $c->stash->{CO_DATA};
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

__PACKAGE__->meta->make_immutable;

1;
