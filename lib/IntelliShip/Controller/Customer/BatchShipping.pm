package IntelliShip::Controller::Customer::BatchShipping;
use Moose;
use Data::Dumper;
use namespace::autoclean;

BEGIN { extends 'IntelliShip::Controller::Customer::Order'; }

=head1 NAME

IntelliShip::Controller::Customer::BatchShipping - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;
	my $params = $c->req->params;

    #$c->response->body('Matched IntelliShip::Controller::Customer::BatchShipping in Customer::BatchShipping.');
	$c->log->debug("BATCH SHIPPINH");

	my $do_value = $params->{'do'} || '';
	if ($do_value eq 'batchship')
		{
		$self->batch_ship;
		}
	else
		{
		$self->setup;
		}
	}

sub ajax :Local
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	my $action = $params->{'action'} || '';
	if ($action eq 'get_service_list')
		{
		my @carrier_service_list = $c->model('MyArrs::service')->search({ carrierid => $params->{'carrier'} }, { select => ['serviceid','servicename'], order_by => 'servicename' });
		#$c->log->debug("carrier_service_list: " . Dumper @carrier_service_list);
		$c->stash->{carrier_service_list} = \@carrier_service_list;
		}
	elsif ($action eq 'search_orders')
		{
		$self->search_batch_orders;
		}

	$c->stash($params);
	$c->stash(template => "templates/customer/batch-shipping.tt");
	}

sub setup :Private
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	$c->stash->{carrier_list} = $self->get_select_list('CARRIER');
	#$c->stash->{carrierservice_list} = $self->get_select_list('CARRIER_SERVICE');
	$c->stash->{extcd_list} = $self->get_select_list('PRODUCT_DESCRIPTION');
	$c->stash->{customernumber_list} = $self->get_select_list('CUSTOMER_NUMBER');
	$c->stash->{department_list} = $self->get_select_list('DEPARTMENT');
	$c->stash->{destination_address_list} = $self->get_select_list('DESTINATION_ADDRESS');
	$c->stash->{destination_state_list} = $self->get_select_list('US_STATES');

	$c->stash(template => "templates/customer/batch-shipping.tt");
	}

sub search_batch_orders :Private
	{
	my $self = shift;

	my $c = $self->context;
	my $params = $c->req->params;
	my $Contact = $self->contact;

	IntelliShip::Utils->hash_decode($params);

	my $CustomerID = $self->customer->customerid;

	my $OrderSQL = "
		SELECT
			DISTINCT ordernumber
		FROM
			co
			INNER JOIN address a ON a.addressid = co.addressid AND co.customerid = '$CustomerID'
		WHERE
			co.cotypeid = 1
			AND co.estimatedweight IS NOT NULL
			AND
			(
				(
					co.extcarrier IS NOT NULL
					AND co.extservice IS NOT NULL
				)
				OR
				(
					co.dateneeded IS NOT NULL
				)
			)
		";

	# Exclude previously shipped orders
	if ($params->{'excludeshipped'})
		{
		$OrderSQL .= " AND co.statusid < 5 ";
		}

	# Select on carrier
	if ( defined($params->{'carrierid'}) and $params->{'carrierid'} ne '' and $params->{'carrierid'} ne '0' )
		{
		my $CarrierName = &APIRequest({action=>'GetValueHashRef',module=>'CARRIER',moduleid=>$params->{'carrierid'},field=>'carriername'})->{'carriername'};
		$OrderSQL .=
		"
			AND co.extcarrier = '^$CarrierName\$'
		";
		}

	# Select on carrier/service
	if ($params->{'csid'})
		{
		my ($carrier,$service) = $self->API->get_carrier_service_name($params->{'csid'});
		$c->log->debug("Carrier: $carrier, Service: $service");

		$OrderSQL .=
		"
			AND co.extcarrier ~* '^$carrier\$'
			AND co.extservice ~* '^$service\$'
		";
		}

	# Select on delivery address
	if ($params->{'address'})
		{
		my ($toname,$toaddress1,$toaddress2,$tocity,$tostate,$tozip) = split(/ : /,$params->{'address'} );

		$OrderSQL .= " AND a.addressname = '$toname'"  if $toname ne '';
		$OrderSQL .= " AND a.address1 = '$toaddress1'" if $toaddress1 ne '';
		$OrderSQL .= " AND a.address2 = '$toaddress2'" if $toaddress2 ne '';
		$OrderSQL .= " AND a.city = '$tocity'"         if $tocity ne '';
		$OrderSQL .= " AND a.state = '$tostate'"       if $tostate ne '';
		$OrderSQL .= " AND a.zip = '$tozip'"           if $tozip ne '';
		}

	# Select on ship date
	if ( defined($params->{'datetoship'}) and $params->{'datetoship'} ne '' )
		{
		$OrderSQL .=
		"
			AND co.datetoship = timestamp '$params->{'datetoship'}'
		";
		}

	# Select on deliver date
	if ( defined($params->{'dateneeded'}) and $params->{'dateneeded'} ne '' )
		{
		$OrderSQL .=
		"
			AND co.dateneeded = timestamp '$params->{'dateneeded'}'
		";
		}

	# Select on destination state
	if ( defined($params->{'batchstate'}) and $params->{'batchstate'} ne '' )
		{
		$OrderSQL .=
		"
			AND a.state = '$params->{'batchstate'}'
		";
		}

	# Select on destination zip range
	if ( defined($params->{'startzip'}) and $params->{'startzip'} ne '' )
		{
		$OrderSQL .=
		"
			AND a.zip >= '$params->{'startzip'}'
		";
		}

	if ( defined($params->{'stopzip'}) and $params->{'stopzip'} ne '' )
		{
		$OrderSQL .=
		"
			AND a.zip <= '$params->{'stopzip'}'
		";
		}

	# Select on product description
	if ( defined($params->{'extcd'}) and $params->{'extcd'} ne '' and $params->{'extcd'} ne '0' )
		{
		$OrderSQL .=
		"
			AND co.extcd = '$params->{'extcd'}'
		";
		}

	# Select on order numbers
	if ( defined($params->{'startordernumber'}) and $params->{'startordernumber'} ne '' )
		{
		$OrderSQL .=
		"
			AND upper(co.ordernumber) >= upper('$params->{'startordernumber'}')
		";
		}

	if ( defined($params->{'stopordernumber'}) and $params->{'stopordernumber'} ne '' )
		{
		$OrderSQL .=
		"
			AND upper(co.ordernumber) <= upper('$params->{'stopordernumber'}')
		";
		}

	# Select on customer number
	if ( defined($params->{'custnum'}) and $params->{'custnum'} ne '' and $params->{'custnum'} ne '0' )
		{
		$OrderSQL .=
		"
			AND co.custnum = '$params->{'custnum'}'
		";
		}

	# Select on product description
	if ( defined($params->{'department'}) and $params->{'department'} ne '' and $params->{'department'} ne '0' )
		{
		$OrderSQL .=
		"
			AND co.department = '$params->{'department'}'
		";
		}

	# check for restricted login
	if ($Contact->is_restricted)
		{
		my $values =  $Contact->get_restricted_values('extcustnum');
		$OrderSQL .= " AND upper(co.extcustnum) IN (" . join(',', @$values) . ") " if $values;
		}

	# Limit number of CO's pulled.  Note, if the CO quantity > 1, then the number of labels printed will not
	# equal the number of CO's pulled.
	$OrderSQL .= " LIMIT $params->{'orderlimit'} " if $params->{'orderlimit'} > 0;

	$OrderSQL =~ s/(\n|\t|\s)+/\ /g;

	$c->log->debug("OrderSQL: " . $OrderSQL);

	my $STH = $c->model('MyDBI')->select($OrderSQL);

	my $OrderNumbers = '';
	if ($STH->numrows)
		{
		my $arr = $STH->query_data;
		#$c->log->debug("OrderNumbers: " . Dumper $arr);
		my @COS = $c->model('MyDBI::CO')->search({ ordernumber => $arr });

		my $matching_order_list = [];
		foreach my $CO (@COS)
			{
			push(@$matching_order_list, {
				coid         => $CO->coid,
				ordernumber  => $CO->ordernumber,
				carrier      => $CO->extcarrier,
				service      => $CO->extservice,
				datetoship   => IntelliShip::DateUtils->american_date($CO->datetoship),
				dateneeded   => IntelliShip::DateUtils->american_date($CO->dateneeded),
				toAddress    => $CO->to_address
				});
			}

		$c->stash->{matching_order_list} = $matching_order_list;
		}
	else
		{
		$c->stash->{MESSAGE} = 'No matching orders found for batch ship';
		}


	return $OrderNumbers;
	}

sub batch_ship :Private
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	my $COIDList = (ref $params->{'coids'} eq 'ARRAY' ? $params->{'coids'} : [$params->{'coids'}]);
	$params->{'multiordershipment'} = 1;
	$params->{'coids'} = $COIDList;

	$c->stash->{CONSOLIDATE} = 1;

	$params->{do} = undef;
	$params->{coid} = $COIDList->[0];

	$self->quickship;
	}

=encoding utf8

=head1 AUTHOR

root

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
