package IntelliShip::Controller::Customer::Settings::Tariff;

use Moose;
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
        if($params->{'action'} eq 'get_carrier_service_list' )
        {
            $self->get_carrier_service_list($c, $params->{'customerid'});
        }

        if($params->{'action'} eq 'get_service_tariff' )
        {
            warn "########## 1";
            $self->get_service_tariff($c, $params->{'csid'});
        }
    }

sub get_carrier_service_list :Local
    {
        my ( $self, $c, $customerid ) = @_;
        my $servicelist = $self->API->get_carrier_service_list($customerid);

        #warn "########## servicelist in Tariff.pm". Dumper($servicelist);
        
        $c->stash->{'SERVICE_LIST'} = $servicelist;
        $c->stash(template => "templates/customer/settings-tariff.tt"); 
    }

sub get_service_tariff :Local
    {
        warn "########## 2";
        my ( $self, $c, $csid ) = @_;
        my $tariff = $self->API->get_service_tariff($csid);
        $c->stash->{'TARIFF'} = $tariff;
        $c->stash(template => "templates/customer/tariff.tt"); 
    }

1;