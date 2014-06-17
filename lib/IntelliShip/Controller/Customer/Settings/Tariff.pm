package IntelliShip::Controller::Customer::Settings::Tariff;

use Moose;
use JSON;
use Data::Dumper;
use IntelliShip::Utils;
use namespace::autoclean;
use IntelliShip::Arrs::API;

BEGIN { extends 'IntelliShip::Controller::Customer::Settings'; }

sub ajax :Local
	{

	my ( $self, $c ) = @_;
	my $params = $c->req->params;

		$c->log->debug("######### Tariff Pricing: ". Dumper($params));
	if($params->{'action'} eq 'get_customer_service_list' )
		{
		$self->get_customer_service_list($c, $params->{'customerid'});
		}

	if($params->{'action'} eq 'get_service_tariff' )
		{
		$self->get_service_tariff($c, $params->{'csid'});
		}

	if($params->{'action'} eq 'get_template' )
		{
		$self->get_template($c);
		}

	if($params->{'action'} eq 'save' )
		{
		shift @_;
		$self->save(@_);
		}
	}

sub get_template :Local
	{
	my ( $self, $c) = @_;
	$c->stash(template => "templates/customer/settings-tariff.tt");
	}

sub get_customer_service_list :Local
	{
	my ( $self, $c, $customerid ) = @_;
	my $servicelist = $self->API->get_customer_service_list($customerid);
	$c->stash->{'JSON'} = $self->services_to_json($servicelist);
	$c->stash(template => "templates/customer/json.tt");
	}

sub get_service_tariff :Local
	{
	my ( $self, $c, $csid ) = @_;
	my $tariff = $self->API->get_service_tariff($csid);

	#warn "########## servicelist in Tariff.pm ". Dumper($tariff);

	$c->stash->{'JSON'} = $self->tariff_to_json($tariff);
	$c->stash(template => "templates/customer/json.tt");
	}

sub save :Local
	{
	my ( $self, $c, $data ) = @_;
	my $params = $c->req->params;
	my $tariff = $self->my_from_JSON($params->{'data'});
	my $info = $self->my_from_JSON($params->{'info'});
	#warn "######### tariff: ".Dumper($tariff);

	$c->stash->{'JSON'} = $self->to_my_JSON($self->API->save_tariff($tariff, $info));
	$c->stash(template => "templates/customer/json.tt");
	}

sub deleteTariffRows: Local
	{
	my ( $self, $c) = @_;
	my $params = $c->req->params;
	my $rateids = $self->my_from_JSON($params->{'rateids'});
	$c->stash->{'JSON'} = $self->to_my_JSON($self->API->delete_tariff_rows($rateids));
	$c->stash(template => "templates/customer/json.tt");
	}

sub delete: Local
	{
	my ( $self, $c) = @_;
	my $params = $c->req->params;
	my $row = $self->my_from_JSON($params->{'data'});
	$c->stash->{'JSON'} = $self->to_my_JSON($self->API->delete_tariff_row($row));
	$c->stash(template => "templates/customer/json.tt");
	}

sub delete_customer_service: Local
	{
	my ( $self, $c) = @_;
	my $params = $c->req->params;
	$c->stash->{'JSON'} = $self->to_my_JSON($self->API->delete_customer_service($params->{'csid'}));
	$c->stash(template => "templates/customer/json.tt");
	}

sub get_carrier_services: Local
	{
	my ( $self, $c ) = @_;
	my $params = $c->req->params;
	my $servicelist = $self->API->get_carrier_services($params->{'carrierid'}, $params->{'customerid'});

	#warn "########## servicelist in get_carrier_services". Dumper($servicelist);

	$c->stash->{'JSON'} = $self->to_my_JSON($servicelist);
	$c->stash(template => "templates/customer/json.tt");
	}

sub add_services: Local
	{
	my ( $self, $c ) = @_;
	my $params = $c->req->params;
	my $serviceids = $self->my_from_JSON($params->{'serviceids'});
	warn "########## serviceids in add_services ". Dumper($serviceids);
	my $result = $self->API->add_services($serviceids, $params->{'customerid'});

	#warn "########## servicelist in add_services ". Dumper($result);

	$c->stash->{'JSON'} = $self->to_my_JSON($result);
	$c->stash(template => "templates/customer/json.tt");
	}

sub import_tariff_files: Local
	{
	my ( $self, $c ) = @_;
	my $params = $c->req->params;
	my $ratetypeid = $params->{'ratetypeid'};
	my $tariffdbname = $params->{'tariffdbname'};
	my $uploads = $c->request->uploads;

	my $res = {};

	for my $field ( $c->req->upload)
		{
		my $upload = $c->req->upload($field);
		my $content = $upload->slurp();
		my $result = $self->API->import_tariff($content, $ratetypeid, $tariffdbname);
		$res->{$upload->filename} = $result;
		$upload=undef;
		}
	$c->stash->{'JSON'} = $self->to_my_JSON($res);
	$c->stash(template => "templates/customer/json.tt");
	}

sub import: Local
	{
	my ( $self, $c) = @_;
	$c->stash(template => "templates/customer/import_tariff.tt");
	}

sub save_tariff_rows: Local
	{
		my ( $self, $c ) = @_;
		my $params = $c->req->params;
		my $rates = $self->my_from_JSON($params->{'rates'});
		#warn "######### save_tariff_rows: " . Dumper($rates);
		my $result = $self->API->save_tariff_rows($rates);
		warn "########## \$result: $result";
		$c->stash->{'JSON'} = $self->to_my_JSON($result);
		$c->stash(template => "templates/customer/json.tt");
	}

sub services_to_json
	{
	my ( $self, $services) = @_;

	my @json = ();
	while (my ($key, $carrier) = each %$services)
		{
		my $carriernode = {};
		$carriernode->{'id'} = $key;
		$carriernode->{'text'} = $carrier->{'carriername'};
		my $csrecords = $carrier->{'csrecords'};

		my @children = ();
		foreach my $cs (@$csrecords)
			{
			my $child = {};
			$child->{'id'} = $cs->{'csid'};
			$child->{'text'} = $cs->{'servicename'};
			$child->{'sid'} = $cs->{'sid'};
			push(@children, $child);
			}

		$carriernode->{'children'} = \@children;
		push(@json, $carriernode);
		}

	return $self->to_my_JSON(\@json);

	}

sub tariff_to_json
	{
	my ( $self, $tariff) = @_;

	my $json = {};
	$json->{'headers'} = $tariff->{'zonenumbers'};
	$json->{'accountnumber'} = $tariff->{'accountnumber'};
	$json->{'meternumber'} = $tariff->{'meternumber'};
	$json->{'csid'} = $tariff->{'csid'};

	my $prevunitsstart = 0;
	my @data = ();	
	my $d = {};
	my $i = 0;
	my $rownum = 0;

	my $ratearray = $tariff->{'ratearray'};

	foreach my $record (@$ratearray)
		{
		my $unitsstart = $record->{'unitsstart'};
		if ($prevunitsstart != $unitsstart || $i == 0)
			{
			push(@data, $d);

			$d = {};
			$d->{'wtmin'} = $unitsstart;
			$d->{'wtmax'} = $record->{'unitsstop'};
			$d->{'mincost'} = $record->{'arcostmin'};
			#$d->{'rateid'} = $record->{'rateid'};
			$d->{'ratetypeid'} = $record->{'ratetypeid'};
			$d->{'rownum'} = $rownum++; #ONLY for UI purpose
			}

		$d->{$record->{'zonenumber'}} = {
										'actualcost'=>$record->{'actualcost'},
										'rateid'=>$record->{'rateid'},
										'costfield'=>$record->{'costfield'}
										};
		
		$prevunitsstart = $unitsstart;
		$i++;
		}

	shift @data; # remove the first empty row
	$json->{'rows'} = \@data;
	return $self->to_my_JSON($json);
	}

sub my_from_JSON
	{
	my ( $self, $json) = @_;
	return decode_json($json);
	}

sub to_my_JSON
	{
	my ( $self, $obj) = @_;
	return encode_json($obj);
	}

1;

__END__