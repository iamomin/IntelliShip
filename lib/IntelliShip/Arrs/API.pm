package IntelliShip::Arrs::API;

use Moose;
use Data::Dumper;
use IntelliShip::DateUtils;

extends 'IntelliShip::Arrs::Utils';

sub process_request
	{
	my $self = shift;
	my $action = shift;
	my $method_name = 'populate_' . $action;

	my $http_request = $self->$method_name;
	my $response = $self->APIRequest($http_request);

	return $response;
	}

sub get_mode
	{
	my $self = shift;
	my $carrier = shift;
	my $service = shift;

	my $http_request = {
		action      => 'GetMode',
		carriername => $carrier,
		servicename => $service
		};

	my $response = $self->APIRequest($http_request);

	return $response->{'modetype'};
	}

sub get_carrier_service_name
	{
	my $self = shift;
	my $CSID = shift;

	my $http_request = {
		action	=> 'GetCarrierServiceName',
		csid	=> $CSID,
		};

	my $response = $self->APIRequest($http_request);

	return ($response->{'carriername'},$response->{'servicename'});
	}

sub get_dim_weight
	{
	my $self = shift;
	my $cs_id     = shift;
	my $dimlength = shift;
	my $dimwidth  = shift;
	my $dimheight = shift;

	my $http_request = {
		action    => 'GetDimWeight',
		csid      => $cs_id,
		dimlength => $dimlength,
		dimwidth  => $dimwidth,
		dimheight => $dimheight,
		};

	my $dataHash = $self->APIRequest($http_request);
	return $dataHash->{'dimweight'};
	}

sub get_sop_asslisting
	{
	my $self = shift;
	my $sopid = shift;

	my $http_request = {
		action    => 'GetSOPAssListing',
		sopid      => $sopid
		};

	return $self->APIRequest($http_request);
	}

sub get_CS_value
	{
	my $self = shift;
	my ($CSID,$ValueType,$CustomerID,$AllowNull) = @_;

	my $http_request = {
		action => 'GetCSValue',
		customerserviceid => $CSID,
		datatypename => $ValueType,
		customerid => $CustomerID,
		allownull => $AllowNull,
		};

	my $dataHash = $self->APIRequest($http_request);
	return $dataHash->{'value'};
	}

sub get_CS_shipping_values
	{
	my $self = shift;
	my ($CSID,$CustomerID) = @_;

	my $http_request = {
		action => 'GetCSShippingValues',
		customerid => $CustomerID,
		csid => $CSID,
		};

	return $self->APIRequest($http_request);
	}

sub get_carrier_list
	{
	my $self = shift;
	my ($SOPID,$CustomerID) = @_;

	my $http_request = {
		action => 'GetCarrierList',
		sopid => $SOPID,
		customerid => $CustomerID,
		};

	return $self->APIRequest($http_request);
	}

sub get_carrrier_service_rate_list
	{
	my $self             = shift;
	my $CO               = shift;
	my $Contact          = shift;
	my $Customer         = shift;
	my $skip_csid_search = shift || 1;

	my $request = {};
	$request->{'action'} = 'GetCSList';
	$request->{'customerid'} = $Customer->customerid;

	my $contact_login_level = $Contact->login_level || 0;

	## Add support for dropship & inbound
	
	my $FromAddress = $CO->origin_address;
	$request->{'fromzip'} = $FromAddress->zip;
	$request->{'fromstate'} = $FromAddress->state;
	$request->{'fromcountry'} = $FromAddress->country;
	
	my $ToAddress = $CO->destination_address;
	$request->{'tozip'} = $ToAddress->zip;
	$request->{'tostate'} = $ToAddress->state;
	$request->{'tocountry'} = $ToAddress->country;
		
	$request->{'datetoship'} = IntelliShip::DateUtils->american_date($CO->datetoship);
	$request->{'dateneeded'} = IntelliShip::DateUtils->american_date($CO->dateneeded);

	 unless ($request->{'dateneeded'})
		{
		my $future_date = IntelliShip::DateUtils->get_timestamp_delta_days_from_now(7);
		$request->{'dateneeded'} = IntelliShip::DateUtils->american_date($future_date);
		$self->context->log->debug("NO DATE NEEDED, FUTURE DATE SELECTED: ". $request->{'dateneeded'});
		}

	$request->{'hasrates'} = $Customer->hasrates;
	$request->{'autocsselect'} = $Customer->autocsselect;
	$request->{'allowraterecalc'} = 1;
	$request->{'manroutingctrl'} = $Customer->get_contact_data_value('manroutingctrl');
	$request->{'clientid'} = $Customer->get_contact_data_value('clientid');

	###########
	$request->{'productparadigm'} = undef;
	##########

	$self->populate_package_detail_section($CO,$request);

	$request->{'quantityxweight'} = $CO->quantityxweight ? 1 : 0;

	# Inbound and dropship flags
	$request->{'isinbound'} = (defined($CO->isinbound) and $CO->isinbound == 1) ? 1 : 0;
	$request->{'isdropship'} = (defined($CO->isdropship) and $CO->isdropship == 1) ? 1 : 0;

	# Collect and thirdparty flags
	$request->{'route'} = ($CO->freightcharges == 0);
	$request->{'collect'} = ($CO->freightcharges == 1);
	$request->{'thirdparty'} = ($CO->freightcharges == 2);

	# Flag for sorting CS list in cost order - currently used for 'route only' login level
	$request->{'sortcslist'} = $contact_login_level == 20 ? 1 : 0;

	# Flag for attaching rates to CS listing - currently 'route only' login level doesn't get display
	$request->{'displaychargesincslist'} = $contact_login_level == 20 ? 0 : 1;

	($request->{'sopid'}, my $UsingAltSOP, my $AltSOPID) = $Customer->get_sop_id($CO->usealtsop,$CO->custnum);

	if (my $agg_freight_class = $self->get_aggregate_freight_class($CO,$request))
		{
		$request->{'class'} = $agg_freight_class;
		}

	## Pass order csid in for rating on first pass - reclacs don't take this into account.
	unless ($CO->freightcharges or $skip_csid_search)
		{
		$request->{'csid'} = $self->get_co_customer_service($request,$Customer,$CO);
		}

	$request->{'required_assessorials'} = $self->get_required_assessorials($CO);

	$self->context->log->debug("GetCSList API REQUEST: ". Dumper($request));
	############################################
	my $response = $self->APIRequest($request);
	############################################
	$self->context->log->debug("GetCSList API RESPONSE:". Dumper($response));

	my @CSIDs = split(/\t/,$response->{'csids'}) if defined($response->{'csids'});
	my @CSNames = split(/\t/,$response->{'csnames'}) if defined($response->{'csnames'});

	# my $DefaultCSID = $response->{'defaultcsid'};
	# my $DefaultCost = $contact_login_level == 20 ? undef : $response->{'defaultcost'};
	# my $DefaultTotalCost = $contact_login_level == 20 ? undef : $response->{'defaulttotalcost'};
	my $CostList = $contact_login_level == 20 ? undef : $response->{'costlist'};
	my @costlist_arr = split(/,/,$CostList) if ($CostList);

	my $carrier_Details = {};
	for ( my $i = 0; $i < scalar(@CSIDs); $i ++ )
		{
		$carrier_Details->{$CSIDs[$i]} = {'NAME' => $CSNames[$i], 'COST_DETAILS' => $costlist_arr[$i+1]};
		}

	unless ($request->{'csid'})
		{
		$carrier_Details = $self->get_other_carrier_data($carrier_Details, $Customer, $request);
		}

	return $carrier_Details;
	}

sub get_hashref
	{
	my $self = shift;
	my $module = shift;
	my $moduleid = shift;

	my $http_request = {
			action   => 'GetValueHashRef',
			module   => $module,
			moduleid => $moduleid,
			};

	return $self->APIRequest($http_request);
	}

sub valid_billing_account
	{
	my $self = shift;
	my ($CSID, $BillingAccount) = @_;

	return 0 unless $CSID;

	my $CSrequest = {
			action	=> 'GetValueHashRef',
			module	=> 'CUSTOMERSERVICE',
			moduleid	=> $CSID,
			field		=> 'thirdpartyacct'
			};

	my $CSResponse =  $self->APIRequest($CSrequest);

	my $ThirdPartyAcct = $CSResponse->{'thirdpartyacct'};

	if ( $ThirdPartyAcct =~ m/^engage::(.*?)$/ )
		{
		my ($junk,$ThirdPartyAcct) = split(/::/,$ThirdPartyAcct);
		}
	else
		{
		return 1;
		}

	if ( uc($ThirdPartyAcct) eq uc($BillingAccount) )
		{
		return 0;
		}
	else
		{
		return 1;
		}
	}

sub get_carrier_ID
	{
	my $self = shift;
	my $csid = shift;

	# Account number should be letters and numbers only and be 6 or 10 in length for ups
	my $CSRef = $self->APIRequest({
			action   => 'GetValueHashRef',
			module   => 'CUSTOMERSERVICE',
			moduleid => $csid,
			field    => 'serviceid'
		});

	my $SRef = $self->APIRequest({
			action   => 'GetValueHashRef',
			module   => 'SERVICE',
			moduleid => $CSRef->{'serviceid'},
			field    => 'carrierid'
		});

	return $SRef->{'carrierid'};
	}

# Bolt alt sop account number after the customer name
# The alt sop account number is assumed to be always attached to the CS
sub get_alt_SOP_consignee_name
	{
	my $self = shift;
	my ($CustomerID, $CSID, $ConsigneeName) = @_;

	if (my $AltSOPAcctNum = $self->get_CS_value($CSID, 'thirdpartyacct', $CustomerID))
		{
		$ConsigneeName .= " ($AltSOPAcctNum)";
		}

	return $ConsigneeName;
	}

__PACKAGE__->meta()->make_immutable();

no Moose;

1;

__END__