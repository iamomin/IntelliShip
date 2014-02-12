package IntelliShip::Arrs::Utils;

use Moose;
use Data::Dumper;
use LWP::UserAgent;
use HTTP::Request::Common;
use IntelliShip::Utils;

BEGIN { has 'context' => ( is => 'rw'); }

sub model
	{
	my $self = shift;
	my $model = shift;

	if ($self->context)
		{
		return $self->context->model($model);
		}
	}

sub myDBI
	{
	my $self = shift;
	return $self->model->('MyDBI');
	}

sub APIRequest
	{
	my $self = shift;
	my $request = shift;

	my $arrs_path = '/opt/engage/arrs';
	if (0 and -r "/opt/engage/arrs/lib" )
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
		#$request->{'httpurl'} = "http://localhost";
=as
		my $hostname = IntelliShip::MyConfig->getHostname;

		my $config; BEGIN { $0=~/(.*)\/.*\.(cgi|pl|pm)/; $config = do "$1/../intelliship.conf" }
		if ($hostname eq 'rml00web01')
			{
			$request->{'httpurl'} = "http://drarrs.$config->{BASE_DOMAIN}";
			}
		elsif ($hostname eq 'rml01web01')
			{
			$request->{'httpurl'} = "http://rarrs.$config->{BASE_DOMAIN}";
			}
		elsif (&GetServerType == 3)
			{
			$request->{'httpurl'} = "http://darrs.$config->{BASE_DOMAIN}";
			}
		else
			{
			$request->{'httpurl'} = "http://arrs.$config->{BASE_DOMAIN}";
			}
=cut
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

sub populate_package_detail_section
	{
	my $self = shift;
	my $CO = shift;
	my $request = shift;

	my @packages = $CO->package_details;

	$request->{'productcount'} = @packages;

	foreach my $PackProData (@packages)
		{
		$request->{'weightlist'}     .= $PackProData->weight . ",";
		$request->{'quantitylist'}   .= $PackProData->quantity . ",";
		$request->{'unittypelist'}   .= 12 . ",";
		$request->{'dimlengthlist'}  .= $PackProData->dimlength . ",";
		$request->{'dimwidthlist'}   .= $PackProData->dimwidth . ",";
		$request->{'dimheightlist'}  .= $PackProData->dimheight . ",";
		$request->{'datatypeidlist'} .= $PackProData->datatypeid . ",";

		$request->{'totalquantity'} += $PackProData->quantity;
		$request->{'aggregateweight'} += $PackProData->weight;
		}
	}

sub get_aggregate_freight_class
	{
	my $self = shift;
	my $CO = shift;
	my $request = shift;

	my @package_row = $CO->package_details;
	$request->{'productcount'} = @package_row;

	my $ClassWeights = {};
	foreach my $PackProData (@package_row)
		{
		my $Class = $PackProData->class;
		next unless ($Class);

		# Check which weight is highest (weight or dimweight)
		my $Weight = $PackProData->weight;
		my $DimWeight = $PackProData->dimweight;
		$Weight = (defined($Weight) and defined($DimWeight) and $Weight < $DimWeight ) ? $DimWeight : $Weight;
		$ClassWeights->{$Class} += (defined $Weight) ? $Weight : 0;
		}

	# Go through list and see which 'weight' has the highest class - this is the aggregate class for the shipment
	my $ClassWeight = 0;
	my $AggFreightClass = 0;
	foreach my $Class (sort {$a <=> $b} (keys(%$ClassWeights)))
		{
		if ($ClassWeights->{$Class} >= $ClassWeight and $Class > $AggFreightClass)
			{
			$AggFreightClass = $Class;
			$ClassWeight = $ClassWeights->{$Class};
			}
		}

	return $AggFreightClass;
	}

sub get_co_customer_service
	{
	my $self = shift;
	my $request = shift;
	my $Customer = shift;
	my $CustomerOrder = shift;

	$request->{'carrier'} = $CustomerOrder->extcarrier;
	$request->{'service'} = $CustomerOrder->extservice;

	# If we don't have a carrier or a service, return undef
	return undef if (!defined($request->{'carrier'}) or $request->{'carrier'} eq '');
	return undef if (!defined($request->{'service'}) or $request->{'service'} eq '');

	$request->{'sopid'} = $Customer->get_sopid($CustomerOrder->usealtsop, $CustomerOrder->extcustnum);

	return $self->get_csid($request);
	}

sub get_csid
	{
	my $self = shift;
	my $request = shift;

	$request->{'action'} = 'GetCSID';
	my $CSReturnRef = IntelliShip::Arrs::API->APIRequest($request);
	return $CSReturnRef->{'csid'};
	}

sub get_other_carrier_data
	{
	my $self = shift;
	my $carrier_list = shift;
	my $Customer = shift;
	my $request = shift;

	my $weight = 0;
	if ($request)
		{
		my $quantities = $request->{'quantitylist'};
		my $weights = $request->{'weightlist'};

		$quantities =~ s/\'//g if $quantities;
		$weights =~ s/\'//g if $weights;

		my @quantities = split(/,/, $quantities) if $quantities;
		my @weights = split(/,/, $weights) if $weights;

		if ($request->{'quantityxweight'})
			{
			while (@weights and @quantities)
				{
				$weight += (shift(@weights) * shift(@quantities));
				}
			}
		else
			{
			while (@weights)
				{
				$weight += shift(@weights);
				}
			}
		}

	# OTHER Carriers
	my $sql = "SELECT
					otherid, othername
				FROM other
				WHERE customerid = '" . $Customer->customerid . "'
				ORDER BY othername";

	my $STH = $self->model("MyDBI")->select("$sql");

	for (my $row=0; $row < $STH->numrows; $row++)
		{
		my $data = $STH->fetchrow($row);
		$carrier_list->{'OTHER_' . $data->{'otherid'}} = { 'NAME' => 'Other - ' . $data->{'othername'} };
		}

	if ($Customer->administrator)
		{
		$carrier_list->{'OTHER_NEW'} = { 'NAME' => 'Other - New' };
		}

	return $carrier_list;
	}

sub get_required_assessorials
	{
	my $self = shift;
	my $CO = shift;

	my @assessorials = $CO->assessorials;
	my $required_assessorials = join(',', map {$_->assname} @assessorials);

	return $required_assessorials;
	}

__PACKAGE__->meta()->make_immutable();

no Moose;

1;

__END__