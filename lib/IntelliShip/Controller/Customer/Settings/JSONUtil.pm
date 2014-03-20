package IntelliShip::Controller::Customer::Settings::JSONUtil;

use Data::Dumper;
use JSON;

use base qw(Exporter);
@JSONUtil::EXPORT = qw(services_to_json tariff_to_json);

sub new
{
        my $proto = shift;
        my $class = ref($proto) || $proto;

        my $self = {};
        bless($self, $class);
        return $self;
}

sub services_to_json
{
    warn "########## services_to_json";
    my ( $self, $services) = @_;
    my @json = ();
    while (my ($key, $carrier) = each %$services)
    {        
        my $carriernode = {};
        $carriernode->{'id'} = $key;
        $carriernode->{'text'} = $carrier->{'carriername'};
        my $csrecords = $carrier->{'csrecords'};
        warn "############ csrecords size: ". scalar(@csrecords);
        my @children = ();
        foreach $cs (@$csrecords)
        {
            warn "######### ref: ". ref $cs;
            my $child = {};
            $child->{'id'} = $cs->{'csid'};
            $child->{'text'} = $cs->{'servicename'};
            $child->{'sid'} = $cs->{'sid'};
            push(@children, $child);
        }

        $carriernode->{'children'} = \@children;
        push(@json, $carriernode);
    }

    return encode_json(\@json);
    
}

sub tariff_to_json
{
   # my ( $self, $tariff) = @_;
}

1;