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
    
    
    my $servicelist = $self->API->get_carrier_service_list($params->{'customerid'});

    #warn "########## servicelist in Tariff.pm". Dumper($servicelist);

    $c->stash->{'SERVICE_LIST'} = $servicelist;
    $c->stash(template => "templates/customer/settings-tariff.tt");
    }

1;