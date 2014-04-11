package IntelliShip::Carrier::Driver::FedEx::VoidShipment;

use Moose;
use Data::Dumper;
use Net::Telnet;
use IntelliShip::Utils;
use IntelliShip::DateUtils;

BEGIN { extends 'IntelliShip::Carrier::Driver'; }

sub process_request
	{
	my $self = shift;
	my $c = $self->context;
	my $Shipment = $self->SHIPMENT;

	$self->log("Process FedEx Void Shipment");

	$Shipment->statusid('6'); ## Voiding
	$Shipment->update;

	if ($Shipment->pickuprequest or $Shipment->customerserviceid)
		{
		}

	my $tracking_number = $Shipment->tracking1;
	$tracking_number =~ s/\s//g;

	# Hash with data to build up void string that we'll transmit to FedEx
	my %VoidData = (
		29 => "$tracking_number", #Required - tracking number
		);

	# Build the void setring
	# Note - double quotes (") get escaped *within* their string.  This is needed since we're 'echo'ing
	my $VoidString = '0,"023"';

	foreach my $key (keys(%VoidData))
		{
		# Push the key/value onto the string, if value exists (null value except in suffix tag
		# is a no-no).
		if( defined($VoidData{$key}) && $VoidData{$key} ne '' )
			{
			$VoidString .= "$key,\"$VoidData{$key}\"";
			}
		}

	# Void string suffix
	$VoidString .= '99,""';

	# Pass shipment string to fedex, and get the return value
	my $VoidReturn;

	if ( $Shipment->service and $Shipment->service !~ /International/ )
		{
		$self->log("Process Local request");
		$VoidReturn = $self->ProcessLocalRequest($VoidString);
		}
	else
		{
		$VoidReturn = $self->ProcessRemoteRequest($Shipment->service,'voidorder')
		}

	$self->log("VOID RETURN: " . $VoidReturn);

	unless ($VoidReturn)
		{
		$Shipment->statusid('5'); ## Void
		$Shipment->update;

		$self->add_error("No response received from FedEx");
		return;
		}

	# Check return string for errors;
	# (except 4028/not found errors - FedEx doesn't have it, we can void it)
	if ( $VoidReturn =~ /"2,"(\w+?)"/ && $1 ne '4028' )
		{
		$self->log("Error block");
		my ($ErrorCode) = $VoidReturn =~ /"2,"(\w+?)"/;
		my ($ErrorMessage) = $VoidReturn =~ /"3,"(.*?)"/;

		$Shipment->statusid('5');
		$Shipment->update;

		$self->log("Error - $ErrorCode: $ErrorMessage");
		$self->add_error("Error - $ErrorCode: $ErrorMessage");
		}
	else
		{
		$self->void_shipment;
		}

	return $Shipment;
	}

sub ProcessLocalRequest
	{
	my $self = shift;
	my $Request = shift;

	$self->log('... ProcessLocalRequest, REQUEST: ' . $Request);

	#$Request = '0,"020"1,"GlobalIntl#1"4,"Shipper Name"5,"Shipper Address #1"6,"Shipper Address #2"7,"Paris"8,"PA"9,"19406"11,"Recipient Company Name"12,"Recipient Contact Name"13,"660 American Ave"14,"3rd Floor"15,"North York"17,"20122"18,"6107680246"21,"15"23,"1"25,"Reference Notes"50,"IT"72,"FOB"74,"IT"77,"8"78,"19.950000"79,"commodity description"80,"US"81,"harmonized code"82,"1"113,"Y"117,"US"183,"6107680246"187,"299"414,"ea"498,"203618"1090,"USD"1273,"01"1274,"01"1282,"T"1349,"S"1958,"Box"1030,"19.950000"99,""';

	#my $Host = "160.209.84.51";
	#my $Host = "192.168.1.84";
	#my $Host = '192.168.1.76';
	my $Host = '216.198.214.5';
	my $Port = "2000";

	my ($NetTelnet, $Pre, $Match);

	eval {
	$NetTelnet = Net::Telnet->new(
					Host => $Host,
					Port => $Port,
					Timeout => 10
					);

	$NetTelnet->print($Request);

	($Pre,$Match) = $NetTelnet->waitfor(Match => '/99,""/');
	#my $Match = $telnet->getline;
	#my $Label = $telnet->getline;
	#$telnet->print('ls');
	#my ($output) = $telnet->waitfor('/\$ $/i');
	#warn "OUTPUT: " . $output;
	};

	$self->log($@) if $@;

	return $Pre.$Match."\n";
	}

sub ProcessRemoteRequest
	{
	my $self = shift;
	my ($ShipmentRef,$Action) = @_;
	}

__PACKAGE__->meta()->make_immutable();

no Moose;

1;

__END__
