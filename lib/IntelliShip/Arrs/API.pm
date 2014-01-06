package IntelliShip::Arrs::API;

use Moose;
use Data::Dumper;
use LWP::UserAgent;
use HTTP::Request::Common;
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

sub APIRequest
	{
	my $self = shift;
	my $request = shift;

	my $arrs_path = '/opt/engage/arrs';
	if ( -r "/opt/engage/arrs/lib" )
		{
		eval "use lib '$arrs_path/lib'";
		eval "use ARRS";

		my $ARRS = new ARRS();
		return $ARRS->APICall($request);
		}
	else
		{
		$request->{'screen'} = 'api';
		$request->{'username'} = 'engage';
		$request->{'password'} = 'ohila4';
		$request->{'httpurl'} = "http://darrs.engagetechnology.com";

	#	my $mode = IntelliShip::MyConfig->getDomain;
	#
	#	if ( hostname() eq 'rml00web01' )
	#		{
	#		$request->{'httpurl'} = "http://drarrs.$config->{BASE_DOMAIN}";
	#		}
	#	elsif ( hostname() eq 'rml01web01' )
	#		{
	#		$request->{'httpurl'} = "http://rarrs.$config->{BASE_DOMAIN}";
	#		}
	#	elsif ( &GetServerType == 3 )
	#		{
	#		$request->{'httpurl'} = "http://darrs.$config->{BASE_DOMAIN}";
	#		}
	#	else
	#		{
	#		$request->{'httpurl'} = "http://arrs.$config->{BASE_DOMAIN}";
	#		}

		my $UserAgent = LWP::UserAgent->new();

		my $host_response = $UserAgent->request(
				POST $request->{'httpurl'},
				Content_Type	=>	'form-data',
				Content			=>	[%$request]
		);

		$host_response->remove_header($host_response->header_field_names);
		return $self->convert_response_to_ref($host_response->as_string);
		}
	}

sub convert_response_to_ref
	{
	my $self = shift;
	my $host_response = shift;
	my $response = {};

	my @Lines = split(/\n/,$host_response);

	while (@Lines)
		{
		my $Line = shift(@Lines);
		my ($Key,$Value) = $Line =~ /(\w+): (.*)/;

		if ( defined($Value) && $Value ne '' )
			{
			$response->{$Key} = $Value;
			}
		}

	return $response;
	}

sub populate_cs_name
	{
	my $self = shift;
	my $request = $self->request;

	my $http_request = {
		action => 'GetCarrierServiceName',
		csid => $request->{'csid'},
		};

	return $http_request;
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

		return $http_request;
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

sub get_carrrier_service_rate_list
	{
	my $self = shift;
	my $CO = shift;
	my $Contact = shift;
	my $Customer = shift;
	my $is_route = shift;
	my $freightcharges = shift;
	$self->context->log->debug("freightcharges :". $freightcharges);
	my $request = {};
	$request->{'action'} = 'GetCSList';
	$request->{'customerid'} = $Customer->customerid;

	## Add support for dropship & inbound
	if ($CO->isinbound == 1)
		{
		my $ToAddress = $CO->to_address;
		my $FromAddress = $Customer->address;
		$request->{'fromzip'} = $FromAddress->zip;
		$request->{'fromstate'} = $FromAddress->state;
		$request->{'fromcountry'} = $FromAddress->country;
		$request->{'tozip'} = $ToAddress->zip;
		$request->{'tostate'} = $ToAddress->state;
		$request->{'tocountry'} = $ToAddress->country;
		}
	else
		{
		my $ToAddress = $Customer->address;
		my $FromAddress = $CO->to_address;
		$request->{'fromzip'} = $ToAddress->zip;
		$request->{'fromstate'} = $ToAddress->state;
		$request->{'fromcountry'} = $ToAddress->country;
		$request->{'tozip'} = $FromAddress->zip;
		$request->{'tostate'} = $FromAddress->state;
		$request->{'tocountry'} = $FromAddress->country;
		}

	$request->{'datetoship'} = IntelliShip::DateUtils->american_date($CO->datetoship);
	$request->{'dateneeded'} = IntelliShip::DateUtils->american_date($CO->dateneeded);

	$request->{'hasrates'} = $Customer->hasrates;
	$request->{'autocsselect'} = 1 if $Customer->autocsselect; ## NOT SURE
	$request->{'allowraterecalc'} = 1;
	$request->{'manroutingctrl'} = $Customer->get_contact_data_value('manroutingctrl');
	$request->{'clientid'} = $Customer->get_contact_data_value('clientid');

	###########
	$request->{'required_assessorials'} = "";
	$request->{'autocsselect'} = 0;
	$request->{'productparadigm'} = undef;
	##########

	$self->populate_package_detail_section($CO,$request);

	$request->{'quantityxweight'} = $CO->quantityxweight ? 1 : 0;
	#$request->{'productparadigm'} = $CO->productparadigm ## NOT SURE

	# TODO: Implement route support
	$request->{'route'} = $is_route;

	# Inbound and dropship flags
	$request->{'isinbound'} = (defined($CO->isinbound) and $CO->isinbound == 1) ? 1 : 0;
	$request->{'isdropship'} = (defined($CO->isdropship) and $CO->isdropship == 1) ? 1 : 0;

	# Collect and thirdparty flags
	$request->{'collect'} = 0;
	$request->{'collect'} = 1 if ($freightcharges == 1);
	$request->{'thirdparty'} = 0;
	$request->{'thirdparty'} = 1 if ($freightcharges == 2);;

	# Flag for sorting CS list in cost order - currently used for 'route only' login level
	$request->{'sortcslist'} = $Contact->login_level == 20 ? 1 : 0;

	# Flag for attaching rates to CS listing - currently 'route only' login level doesn't get display
	$request->{'displaychargesincslist'} = $Contact->login_level == 20 ? 0 : 1;

	($request->{'sopid'}, my $UsingAltSOP, my $AltSOPID) = $Customer->get_sop_id($CO->usealtsop,$CO->custnum);

	if (my $agg_freight_class = $self->get_aggregate_freight_class($CO,$request))
		{
		$request->{'class'} = $agg_freight_class;
		}

	#Pass order csid in for rating on first pass - reclacs don't take this into account.
	unless ($CO->freightcharges)
		{
		my %CSRef = %$request;
		my $CSRef = \%CSRef;
		$CSRef->{'coid'} = $CO->coid;
		$request->{'csid'} = $self->get_co_customer_service($request,$Customer,$CO);
		}

	$request->{'required_assessorials'} = $self->get_required_assessorials($request,$Customer,$CO);
	$self->context->log->debug("request :". Dumper($request));
	my $response = $self->APIRequest($request);

	$self->context->log->debug("response :". Dumper($response));
	my @CSIDs = split(/\t/,$response->{'csids'}) if defined($response->{'csids'});
	my @CSNames = split(/\t/,$response->{'csnames'}) if defined($response->{'csnames'});

	my $carrier_list = {};
	for ( my $i = 0; $i < scalar(@CSIDs); $i ++ )
		{
		$carrier_list->{$i} = {'key' => $CSIDs[$i], 'value' => $CSNames[$i]};
		}

	unless ($request->{'csid'})
		{
		($carrier_list,$response) = $self->get_other_carrier_data($carrier_list,$Customer,$response,$request,scalar(@CSIDs));
		}

	$request->{'action'} = 'GetCSJSArrays';
	$request->{'csids'} = $response->{'csids'};

	# Slip the cost weight list into the cs data ref
	my $cs_data_ref =  $self->APIRequest($request);
	$cs_data_ref->{'costweightlist'} = $response->{'costweightlist'};

	return ($response, $cs_data_ref, $carrier_list);
	}

__PACKAGE__->meta()->make_immutable();

no Moose;

1;

__END__