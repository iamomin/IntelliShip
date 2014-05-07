#!/usr/bin/perl -w

#==========================================================
#   Project:	ARRS
#
#   Filename:	USPS.pm
#
#   Date:		05/06/2014
#
#   Purpose:	Rate against our USPS Ship Manager Server
#
#   Company:	Aloha Technology Pvt Ltd
#
#   Author(s):	Imran Momin
#
#==========================================================


package Tariff::USPS;

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
	 dbname	  => 'arrs',
	 dbhost	  => 'localhost',
	 dbuser	  => 'webuser',
	 dbpassword  => 'Byt#Yu2e',
	 autocommit  => 1
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
	my ($Weight,$DiscountPercent,$Class,$OriginZip,$DestZip,$SCAC,$DateShipped,$Required_Asses,$FileID,$ClientID,$CSID,$ServiceID,$ToCountry,$CustomerID,$DimHeight,$DimWidth,$DimLength) = @_;

	my $Benchmark = 0;
	my $S_ = &Benchmark() if $Benchmark;
	warn "USPS->GetCost()->$Weight,$DiscountPercent,$Class,$OriginZip,$DestZip,$SCAC,$DateShipped,$Required_Asses,$ClientID,$CSID,$ServiceID,$ToCountry";

	my $Cost = -1;
	my $days = 0;
	my $errorcode = 0;

	#warn "... USPS GetTransit()";
	#warn "... CUSTOMERID: $CustomerID";

	my $AcctNum = undef;
	my $MeterNum = undef;

	eval {
	($days,$Cost,$errorcode) = $self->GetTransit($SCAC,$OriginZip,$DestZip,$Weight,$Class,$DateShipped,$Required_Asses,$FileID,$ClientID,$CSID,$ServiceID,$ToCountry,$AcctNum,$MeterNum,$DimHeight,$DimWidth,$DimLength);
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
		#warn "NO eFreight TRANSIT => SCAC-$SCAC";
		}

	warn "USPS, return cost $Cost transit=$days for $SCAC" if $Benchmark;
	&Benchmark($S_,"USPS: $SCAC - \$$Cost") if $Benchmark;

	return ($Cost,$days);
}

sub GetTransit
{
	my $self = shift;

	my ($scac,$oazip,$dazip,$weight,$class,$dateshipped,$required_asses,$fileid,$clientid,$csid,$serviceid,$tocountry,$acctnum,$meternum,$height,$width,$length) = @_;
	if ( !$fileid ) { $fileid = 'test' }
	#warn "USPS: GetTrasit($scac,$oazip,$dazip,$weight,$class,$dateshipped,$required_asses,$fileid,$clientid,$csid,$serviceid,$tocountry,$acctnum,$meternum)";

	my $STH = $self->{'dbref'}->prepare("SELECT servicename FROM service WHERE serviceid = ?") or die "Could not prepare asscode select sql statement";
	$STH->execute($serviceid) or die "Could not execute asscode select sql statement";
	my ($servicename) = $STH->fetchrow_array;
	$STH->finish();

	($servicename,my $container) = split(/\ \-\ /,$servicename) if $servicename =~ /\-/;
	$servicename = uc $servicename;
	$container = uc $container;
	$container =~ s/BOXES/BOX/;
	$container =~ s/SMALL/SM/;
	$container =~ s/MEDIUM/MD/;
	$container =~ s/LARGE/LG/;

	warn "\nService: " . $servicename . ", container: " . $container;

	my $path = "$config->{BASE_PATH}/bin/run";
	my $file = $fileid . ".info";
	my $File = $path . "/" . $file;
	my $Days = 0;
	my $cost = -1;
	my $ErrorCode;

	#warn "USPS: FILE=$File";

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

	my $machinableElement = '<Machinable>true</Machinable>' if $servicename =~ /STANDARD POST/;
	my $firstClassMailTypeElement = '<FirstClassMailType>PACKAGE SERVICE</FirstClassMailType>' if $servicename =~ /FIRST CLASS/;

	my $XML = <<XML;
<RateV4Request USERID="667ENGAG1719">
     <Revision/>
     <Package ID="1ST">
          <Service>$servicename</Service>
          <ZipOrigination>$oazip</ZipOrigination>
          <ZipDestination>$dazip</ZipDestination>
          <Pounds>$weight</Pounds>
          <Ounces>0</Ounces>
          <Container>$container</Container>
          <Size>REGULAR</Size>
          <Width>$width</Width>
          <Length>$length</Length>
          <Height>$height</Height>
          $machinableElement
          $firstClassMailTypeElement
     </Package>
</RateV4Request>
XML

	my $ShipmentReturn = $self->ProcessLocalRequest($XML);

	## Check return string for errors;
	if ( $ShipmentReturn->{'Postage'} )
		{
		warn "USPS ShipManager Error: " .  $ShipmentReturn->{'Postage'}->{'Error'} if $ShipmentReturn->{'Postage'}->{'Error'};
		$cost = $ShipmentReturn->{'Postage'}->{'Rate'};
		$oazip = $ShipmentReturn->{'Postage'}->{'Rate'};
		$Days = $1 if $ShipmentReturn->{'Postage'}->{'MailService'} =~ m/(\d+)\-Day/i;
		}

	warn "USPS RETURN DAYS|COST: |$Days|$cost|";
	return ($Days,$cost,$ErrorCode);
}

sub ProcessLocalRequest
	{
	my $self = shift;
	my $XML_request = shift;

	#warn "\n XML_request: " . $XML_request;

	my $shupment_request = {
			httpurl => 'http://production.shippingapis.com/ShippingAPI.dll',
			API => 'RateV4',
			XML => $XML_request
			};

	my $UserAgent = LWP::UserAgent->new();
	my $response = $UserAgent->request(
			POST $shupment_request->{'httpurl'},
			Content_Type  => 'text/html',
			Content       => [%$shupment_request]
			);

	unless ($response)
		{
		warn "USPS: Unable to access USPS site";
		return;
		}

	my $xml = new XML::Simple;

	my $XMLResponse = $xml->XMLin($response->content);

	#warn "Response DS: " . Dumper $XMLResponse;

	return $XMLResponse->{'RateV4Response'}->{'Package'};
	}

1

__END__