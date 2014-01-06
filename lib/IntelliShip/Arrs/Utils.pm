package IntelliShip::Arrs::Utils;

use Moose;
use Data::Dumper;
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
	my $response = shift;
	my $counter = shift;

	my $weight = 0;
	if ($request)
		{
		my $quantities = $request->{'quantitylist'};
		my $weights = $request->{'weightlist'};

		$quantities =~ s/\'//g;
		$weights =~ s/\'//g;

		my @quantities = split(/,/,$quantities);
		my @weights = split(/,/,$weights);

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

		$carrier_list->{$counter++} = { 'key' => 'OTHER_' . $data->{'otherid'}, 'value' => 'Other - ' . $data->{'othername'}};

		if ($response)
			{
			$response->{'costlist'} .= ",'0'";
			$response->{'costweightlist'} .= ",'$weight'" if $response->{'costweightlist'} and $weight;
			}
		}

	if ($Customer->administrator)
		{
		$carrier_list->{$counter++} = {'key' => 'OTHER_NEW', 'value' => 'Other - New'};

		if ($response)
			{
			$response->{'costlist'} .= ",'0'";
			$response->{'costweightlist'} .= ",'$weight'" if $response->{'costweightlist'} and $weight;
			}
		}

	return ($carrier_list,$response);
	}

sub get_required_assessorials
	{
	my $self = shift;
	my $request = shift;
	my $Customer = shift;
	my $CO = shift;

	my @assessorial_datas = $self->model("MyDBI::Assdata")->search({ ownerid => $CO->coid });

	my @assessorial_names;
	foreach my $AssData (@assessorial_datas)
		{
		push (@assessorial_names, $AssData->assname);
		}

	my $required_assessorials = join(',',@assessorial_names);
	return $required_assessorials;
	}

__PACKAGE__->meta()->make_immutable();

no Moose;

1;

__END__