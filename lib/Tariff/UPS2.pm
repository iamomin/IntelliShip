#!/usr/bin/perl -w

#==========================================================
#   Project:	ARRS
#
#   Filename:	UPS.pm
#
#   Date:		05/15/2014
#
#   Purpose:	Rate against our UPS Ship Manager Server
#
#   Company:	Aloha Technology Pvt Ltd
#
#   Author(s):	Imran Momin
#
#==========================================================


package Tariff::UPS2;

use strict;
use Data::Dumper;
use POSIX qw(ceil);
use ARRS::IDBI;
use ARRS::COMMON;
use ARRS::SERVICE;
use LWP::UserAgent;
use HTTP::Request::Common;
use ARRS::CUSTOMERSERVICE;
use IntelliShip::MyConfig;

my $Debug = 0;
my $config = IntelliShip::MyConfig->get_ARRS_configuration;

sub new
{
	my $proto = shift;
	my $class = ref($proto) || $proto;

	my $self = {};

	$self->{'dbref'} = ARRS::IDBI->connect({
		dbname     => 'arrs',
		dbhost     => 'localhost',
		dbuser     => 'webuser',
		dbpassword => 'Byt#Yu2e',
		autocommit => 1
		});

	bless($self, $class);

	return $self;
}

sub GetAssCode
{
	my $self = shift;
	my ($csid,$serviceid,$name) = @_;
	warn "USPS GetAssCode($csid,$serviceid,$name)";

	my $SQL = "
	 SELECT DISTINCT
		asscode,ownertypeid
	 FROM
		assdata
	 WHERE
		( (ownerid = ? AND ownertypeid = 4) OR (ownerid = ? AND ownertypeid = 3) )
		AND assname = ?
	 ORDER BY ownertypeid desc
	";

	my $STH = $self->{'dbref'}->prepare($SQL) or die "Could not prepare asscode select sql statement";

	$STH->execute($csid,$serviceid,$name) or die "Could not execute asscode select sql statement";

	my ($code,$ownertypeid) = $STH->fetchrow_array();

	$STH->finish();
	warn "USPS GetAssCode returns asscode=$code";
	return $code;
}

sub GetCost
{
	my $self = shift;
	my ($Weight,$DiscountPercent,$Class,$OriginZip,$DestZip,$SCAC,$DateShipped,$Required_Asses,$FileID,$ClientID,$CSID,$ServiceID,$ToCountry,$CustomerID,$DimHeight,$DimWidth,$DimLength,$FromCountry,$FromCity,$FromState,$ToCity,$ToState) = @_;

	my $Benchmark = 0;
	my $S_ = &Benchmark() if $Benchmark;
	warn "UPS2->GetCost()->$Weight,$DiscountPercent,$Class,$OriginZip,$DestZip,$SCAC,$DateShipped,$Required_Asses,$ClientID,$CSID,$ServiceID,$ToCountry";

	my $Cost = -1;
	my $days = 0;
	my $errorcode = 0;

	warn "... UPS2 GetTransit()";
	warn "... CUSTOMERID: $CustomerID";

	my $AcctNum = undef;
	my $MeterNum = undef;

	eval {
	($days,$Cost,$errorcode) = $self->GetTransit($SCAC,$OriginZip,$DestZip,$Weight,$Class,$DateShipped,$Required_Asses,$FileID,$ClientID,$CSID,$ServiceID,$ToCountry,$AcctNum,$MeterNum,$DimHeight,$DimWidth,$DimLength,$FromCountry,$FromCity,$FromState,$ToCity,$ToState);
	};
	warn "Error: " . $@ if $@;
	if ( $days )
		{
		if ( $errorcode )
			{
			warn "ERRORCODE=>$errorcode";
			}
		}
	else
		{
		warn "NO eFreight TRANSIT => SCAC-$SCAC";
		}

	warn "UPS, return cost $Cost transit=$days for $SCAC" if $Benchmark;
	&Benchmark($S_,"USPS: $SCAC - \$$Cost") if $Benchmark;

	return ($Cost,$days);
}

sub GetTransit
{
	my $self = shift;

	my ($scac,$oazip,$dazip,$weight,$class,$dateshipped,$required_asses,$fileid,$clientid,$csid,$serviceid,$tocountry,$acctnum,$meternum,$height,$width,$length,$fromcountry,$fromcity,$fromstate,$tocity,$tostate) = @_;

	if ( !$fileid ) { $fileid = 'test' }

	#warn "UPS2: GetTrasit($scac,$oazip,$dazip,$weight,$class,$dateshipped,$required_asses,$fileid,$clientid,$csid,$serviceid,$tocountry,$acctnum,$meternum)";

	my $STH = $self->{'dbref'}->prepare("SELECT servicename, servicecode FROM service WHERE serviceid = ?") or die "Could not prepare asscode select sql statement";
	$STH->execute($serviceid) or die "Could not execute asscode select sql statement";
	my ($servicename, $servicecode) = $STH->fetchrow_array;
	$STH->finish();
	
	warn "\nService: " . $servicename . "\nServiceCode:" . $servicecode;
	
	my $path = "$config->{BASE_PATH}/bin/run";
	my $file = $fileid . ".info";
	my $File = $path . "/" . $file;
	my $Days = 0;
	my $cost = -1;
	my $ErrorCode;

	warn "UPS: FILE=$File";

	## only use 5 digits.  won't rate with zip plus 4
	if ( defined($oazip) && $oazip !~ /^\d{5}$/ )
		{
		$oazip = substr($oazip,0,5);
		}

	if ( defined($dazip) && $dazip !~ /^\d{5}$/ )
		{
		$dazip = substr($dazip,0,5);
		}

	$height = ceil($height);
	$width  = ceil($width);
	$length = ceil($length);
	$weight = ceil($weight);

	my $XML = "<?xml version=\"1.0\"?>
<AccessRequest xml:lang=\"en-US\">
	<AccessLicenseNumber>7CD03B13C7D39706</AccessLicenseNumber>
	<UserId>tsharp212</UserId>
	<Password>Tony212!@</Password>
</AccessRequest>
<?xml version=\"1.0\"?>
<RatingServiceSelectionRequest xml:lang=\"en-US\">
	<Request>
	<TransactionReference>
		<CustomerContext>Rating and Service</CustomerContext>
		<XpciVersion>1.0</XpciVersion>
	</TransactionReference>
	<RequestAction>Rate</RequestAction>
	<RequestOption>Rate</RequestOption>
	</Request>
	<PickupType>
		<Code>07</Code>
		<Description>Rate</Description>
	</PickupType>
	<Shipment>
		<Description>Rate Description</Description>
		<Shipper>
			<Name>Tony Sharps</Name>
			<PhoneNumber>1234567890</PhoneNumber>
			<ShipperNumber>F5618Y</ShipperNumber>
			<Address>
				<AddressLine1>Ste 102-302</AddressLine1>
				<City>Memphis</City>
				<StateProvinceCode>TN</StateProvinceCode>
				<PostalCode>38125</PostalCode>
				<CountryCode>US</CountryCode>
			</Address>
		</Shipper>
		<ShipTo>
			<CompanyName>XYZ</CompanyName>
			<PhoneNumber>1234567890</PhoneNumber>
			<Address>
				<AddressLine1>Ste 100</AddressLine1>
				<City>$tocity</City>
				<PostalCode>$dazip</PostalCode>
				<CountryCode>$tocountry</CountryCode>
			</Address>
		</ShipTo>
		<ShipFrom>
			<CompanyName>Engage Technology, LLC</CompanyName>
			<AttentionName></AttentionName>
			<PhoneNumber>1234567890</PhoneNumber>
			<FaxNumber>1234567890</FaxNumber>
			<Address>
				<AddressLine1>Ste 102-302</AddressLine1>
				<City>$fromcity</City>
				<StateProvinceCode>$fromstate</StateProvinceCode>
				<PostalCode>$oazip</PostalCode> 
				<CountryCode>$fromcountry</CountryCode>
			</Address>
		</ShipFrom>
		<Service>
			<Code>$servicecode</Code>
		</Service>
		<PaymentInformation>
			<Prepaid>
				<BillShipper>
					<AccountNumber>F5618Y</AccountNumber>
				</BillShipper>
			</Prepaid>
		</PaymentInformation>
		<Package>
			<PackagingType>
				<Code>02</Code>
				<Description>Customer Supplied</Description>
			</PackagingType>
			<Description>Rate</Description>
			<PackageWeight>
				<UnitOfMeasurement>
					<Code>LBS</Code>
				</UnitOfMeasurement>
				<Weight>$weight</Weight>
			</PackageWeight>
		</Package>
		<ShipmentServiceOptions>
			<OnCallAir>
				<Schedule> 
					<PickupDay>02</PickupDay>
					<Method>02</Method>
				</Schedule>
			</OnCallAir>
		</ShipmentServiceOptions>
	</Shipment>
</RatingServiceSelectionRequest>";

	my $ShipmentReturn = $self->ProcessLocalRequest($XML);

	## Check return string for errors;

	if ( $ShipmentReturn->{Response}->{ResponseStatusDescription} =~ /Success/i )
		{
		$cost = $ShipmentReturn->{RatedShipment}->{TotalCharges}->{MonetaryValue};
		$Days = $1 if $ShipmentReturn->{'RatedShipment'}->{'GuaranteedDaysToDelivery'} =~ m/(\d+)\-Day/i;
		}
	else
		{
		$ErrorCode = $ShipmentReturn->{Response}->{Error}->{ErrorCode} . " - " . $ShipmentReturn->{Response}->{Error}->{ErrorDescription};
		warn "UPS2 ShipManager Error: " . $ErrorCode;
		}

	warn "UPS2 RETURN DAYS|COST: |$Days|$cost|";
	return ($Days,$cost,$ErrorCode);
}

sub ProcessLocalRequest
	{
	my $self = shift;
	my $XML_request = shift;

	#warn "\n XML_request: " . $XML_request;

	my $url = IntelliShip::MyConfig->getDomain eq 'PRODUCTION' ? 'https://onlinetools.ups.com/ups.app/xml/Rate' : 'https://wwwcie.ups.com/ups.app/xml/Rate';

	#Send HTTP Request
	my $browser = LWP::UserAgent->new();   
	my $req = HTTP::Request->new(POST => $url);
	$req->content("$XML_request");

	#Get HTTP Response Status
	my $response = $browser->request($req);
	unless ($response)
		{
		warn "USPS: Unable to access UPS site";
		return;
		}

	my $parser = new XML::Simple;
	my $responseDS= $parser->XMLin($response->content());

	#warn "Response DS: " . Dumper $responseDS;
	return $responseDS;
	}

1

__END__
