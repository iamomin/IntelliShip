package IntelliShip::Carrier::Driver::UPS::AddressValidate;

use Moose;
use XML::LibXML::Simple;
use HTTP::Request;
use Data::Dumper;
use LWP::UserAgent;
use IntelliShip::Utils;

BEGIN { extends 'IntelliShip::Carrier::Driver'; }

my $URL = 'https://wwwcie.ups.com/ups.app/xml/XAV';
my $AccessLicenseNumber = '7CD03B13C7D39706';
my $UserId = 'tsharp212';
my $Password = 'Tony212!@';

sub process_request
	{
	my $self = shift;
	my $c = $self->context;
	
	if ($self->destination_address->lastvalidatedon)
		{
		my $sql = "select date_part('day', age(now()::timestamp, '" . $self->destination_address->lastvalidatedon . "'::timestamp) ) date_diff";
		$self->log("sql = " . $sql . "\n");
		my $STH = $c->model('MyDBI')->select($sql);
		my $days_old = $STH->fetchrow(0)->{'date_diff'} if $STH->numrows;
		$self->log("days_old = " + $days_old . "\n");
		return 1 if ($days_old <= 180);
		}
	
	#my ($ResponseCode,$Message);

	my $XML = "<?xml version=\"1.0\"?>
<AccessRequest xml:lang=\"en-US\">
<AccessLicenseNumber>$AccessLicenseNumber</AccessLicenseNumber>
<UserId>$UserId</UserId>
<Password>$Password</Password>
</AccessRequest>
<?xml version=\"1.0\"?>
<AddressValidationRequest xml:lang=\"en-US\">
<Request>
<TransactionReference>
<CustomerContext /><XpciVersion>1.0001</XpciVersion>
</TransactionReference>
<RequestAction>XAV</RequestAction>
<RequestOption>1</RequestOption>
</Request>
<MaximumListSize>1</MaximumListSize>
<AddressKeyFormat>
<ConsigneeName>" . $self->destination_address->addressname . "</ConsigneeName>
<AddressLine>" . $self->destination_address->address1 . "</AddressLine>
<AddressLine>" . $self->destination_address->address2 . "</AddressLine>
<PoliticalDivision2>" . $self->destination_address->city . "</PoliticalDivision2>
<PoliticalDivision1>" . $self->destination_address->state . "</PoliticalDivision1>
<PostcodePrimaryLow>" . $self->destination_address->zip . "</PostcodePrimaryLow>
<CountryCode>" . $self->destination_address->country . "</CountryCode>
</AddressKeyFormat>
</AddressValidationRequest>";

	my $browser = LWP::UserAgent->new();   
	my $req = HTTP::Request->new(POST => $URL);
	$self->log("\n\nXML = $XML \n\n");
	$req->content("$XML");
	my $resp = $browser->request($req);
	$self->log($resp->content() . "\n");
	my $parser = XML::LibXML::Simple->new();
	my $xmlResp= $parser->XMLin($resp->content());

	if($xmlResp->{Response}->{ResponseStatusDescription} =~ /Success/i)
		{
		$self->destination_address->lastvalidatedon(IntelliShip::DateUtils->get_timestamp_with_time_zone);
		$self->destination_address->update;
		#$ResponseCode = $xmlResp->{Response}->{ResponseStatusCode};
		#$Message = $xmlResp->{Response}->{ResponseStatusDescription};
		return 1;
		}
	else
		{
		#$ResponseCode = $xmlResp->{Response}->{Error}->{ErrorDescription};
		#$Message = "Invalid Address: " . $xmlResp->{Response}->{Error}->{ErrorDescription};
		$self->add_error("Invalid Address: " . $xmlResp->{Response}->{Error}->{ErrorDescription});
		#$self->log($Message);
		return undef;
		}
	}

__PACKAGE__->meta()->make_immutable();

no Moose;

1;

__END__
