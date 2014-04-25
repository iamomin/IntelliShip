package IntelliShip::Controller::Customer::Settings::Tariff;

use Moose;
use Data::Dumper;
use IntelliShip::Utils;
use namespace::autoclean;
use IntelliShip::Arrs::API;
use IntelliShip::Controller::Customer::Settings::JSONUtil;

BEGIN { extends 'IntelliShip::Controller::Customer::Settings'; }

our $JSONUTIL = IntelliShip::Controller::Customer::Settings::JSONUtil->new();  

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
            warn "########## 1";
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

        #warn "########## servicelist in Tariff.pm". Dumper($servicelist);
        
        $c->stash->{'JSON'} = $JSONUTIL->services_to_json($servicelist);
        $c->stash(template => "templates/customer/json.tt"); 
    }

sub get_service_tariff :Local
    {
        warn "########## 2";
        my ( $self, $c, $csid ) = @_;
        my $tariff = $self->API->get_service_tariff($csid);

        #warn "########## servicelist in Tariff.pm". Dumper($tariff);
        
        $c->stash->{'JSON'} = $JSONUTIL->tariff_to_json($tariff);
        $c->stash(template => "templates/customer/json.tt"); 
    }

sub save :Local
    {
        warn "########## save";
        my ( $self, $c, $data ) = @_;
		my $params = $c->req->params;			
		my $tariff = $JSONUTIL->from_json($params->{'data'});
		my $info = $JSONUTIL->from_json($params->{'info'});
		#warn "######### tariff: ".Dumper($tariff);
		
		$c->stash->{'JSON'} = $JSONUTIL->to_json($self->API->save_tariff($tariff, $info));
        $c->stash(template => "templates/customer/json.tt");
    }
	
sub deleteAllTariffRows: Local
	{
		warn "########## deleteAllTariffRows";
        my ( $self, $c) = @_;
		my $params = $c->req->params;
		my $tariff = $JSONUTIL->from_json($params->{'data'});
		$c->stash->{'JSON'} = $JSONUTIL->to_json($self->API->delete_all_tariff_rows($tariff));
        $c->stash(template => "templates/customer/json.tt");
	}
	
sub delete: Local
	{
		warn "########## delete";
        my ( $self, $c) = @_;
		my $params = $c->req->params;
		my $row = $JSONUTIL->from_json($params->{'data'});
		$c->stash->{'JSON'} = $JSONUTIL->to_json($self->API->delete_tariff_row($row));
        $c->stash(template => "templates/customer/json.tt");
	}
	
sub get_carrier_services: Local
{
	my ( $self, $c ) = @_;
	my $params = $c->req->params;
	my $servicelist = $self->API->get_carrier_services($params->{'carrierid'}, $params->{'customerid'});

	warn "########## servicelist in get_carrier_services". Dumper($servicelist);
	
	$c->stash->{'JSON'} = $JSONUTIL->to_json($servicelist);
	$c->stash(template => "templates/customer/json.tt"); 
}

sub add_services: Local
{
	my ( $self, $c ) = @_;
	my $params = $c->req->params;
	my $serviceids = $JSONUTIL->from_json($params->{'serviceids'});
	my $result = $self->API->add_services($serviceids, $params->{'customerid'});

	warn "########## servicelist in get_carrier_services". Dumper($result);
	
	$c->stash->{'JSON'} = $JSONUTIL->to_json($result);
	$c->stash(template => "templates/customer/json.tt"); 
}
1;