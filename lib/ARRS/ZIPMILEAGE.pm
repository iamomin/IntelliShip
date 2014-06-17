#!/usr/bin/perl -w

#==========================================================
#   Project:	ARRS
#
#   Filename:	ZIPMILEAGE.pm
#
#   Date:		06/24/2004
#
#   Purpose:	Calclulate zip->zip mileage, and maintain
#					db of cached calcs
#
#   Company:	Engage TMS
#
#   Author(s):	Kirk Aksdal
#					Leigh Bohannon
#
#==========================================================

{
	package ARRS::ZIPMILEAGE;

	use strict;
	use ARRS::DBOBJECT;
	@ARRS::ZIPMILEAGE::ISA = ("ARRS::DBOBJECT");

	use ARRS::COMMON;

	use HTTP::Request;
	use LWP::UserAgent::ProxyAny;
	use POSIX qw(ceil);

	sub new
	{
		my $proto = shift;
		my $class = ref($proto) || $proto;

		my $self = $class->SUPER::new(@_);

		$self->{'object_tablename'} = 'zipmileage';
		$self->{'object_primarykey'} = 'zipmileageid';
		$self->{'object_fieldlist'} = ['zipmileageid', 'origin', 'dest', 'mileage'];

		# Zip ranges should be a rarity (based on SOP chicanery, more than anything in real life).
		# This table/module was set to use origin->destination for a reason (speed).
		# Any entries that look like they could use ranges should be busted into individual entries.
		# Ranges would only come in manually (never automatically), so this shouldn't be a problem.  Kirk, 1/26/06.

		bless($self, $class);
		return $self;
	}

	sub GetMileage
	{
		my $self = shift;
		my ($FromZip,$ToZip) = @_;
		my $Mileage;

		if ( $FromZip =~ /\d{5}-\d{4}/ ) { $FromZip =~ s/(\d{5})-\d{4}/$1/ }
		if ( $ToZip =~ /\d{5}-\d{4}/ ) { $ToZip =~ s/(\d{5})-\d{4}/$1/ }

		if ( ! ($Mileage = $self->GetDBMileage($FromZip,$ToZip) ) )
		{
			$Mileage = $self->GetRoadMileage($FromZip,$ToZip);
		}

		return $Mileage;
	}

	sub GetDBMileage
	{
		my $self = shift;
		my ($FromZip,$ToZip) = @_;
		my $Mileage = 0;

		my $MileageSQL = "
			SELECT
				mileage
			FROM
				zipmileage
			WHERE
				origin = '$FromZip' AND
				dest = '$ToZip'
		";

		my $STH = $self->{'object_dbref'}->prepare($MileageSQL)
			or TraceBack("Could not prepare GetDBMileage select",1);

		$STH->execute()
			or TraceBack("Could not execute GetDBMileage select",1);

		($Mileage) = $STH->fetchrow_array();

		$STH->finish();

		return $Mileage;
	}

	sub GetRoadMileage
	{
		my $self = shift;
		my ($FromZip,$ToZip) = @_;

		my $ua = LWP::UserAgent::ProxyAny->new;
		$ua->agent("Mozilla/4.08");

		local $^W = 0;
		#my $ReqURL = "http://www.randmcnally.com/rmc/directions/dirGetMileage.jsp?cmty=0&txtStartZip=$FromZip&txtDestZip=$ToZip";
		#my $ReqURL = "http://www.melissadata.com/lookups/zipdistance.asp?zipcode1=$FromZip&zipcode2=$ToZip&submit1=Submit";
		#my $ReqURL = "https://maps.google.com/maps?f=d&hl=en&geocode=&saddr=$FromZip&daddr=$ToZip";
		my $ReqURL = "http://www.melissadata.com/lookups/zipdistance.asp?zip1=$FromZip&zip2=$ToZip";
		

		local $^W = 1;

#warn $ReqURL;
		my $req = new HTTP::Request("GET" => $ReqURL);
		my $Response = $ua->request($req);
		my $response_string = $Response->as_string;
		$response_string =~ s/<.*?>//g;
		$response_string =~ s/\&nbsp\;//g;
		$response_string =~ s/\r//g;
		$response_string =~ s/\n//g;
		$response_string =~ s/\s{2}//g;
		$response_string =~ s/\s{1}//g;
		$response_string =~ s/,//g;
#		print $response_string;
#		warn $response_string;

		#my ($GotResult) = $response_string =~ m/Suggestedroutes/i;
		my ($GotResult) = $response_string =~ m/Distancefrom\d+\(/i;

		if (defined($GotResult))
		{
			#my ($Mileage) = $response_string =~ m/Driving Distance: (\d+)? miles/;
			#my ($Mileage) = $response_string =~ m/is (\d+)? miles/;
			#my ($Mileage) = $response_string =~ m/is\s(\d+)?\smiles\./;
			#my ($Mileage) = $response_string =~ m/Suggestedroutes(.*?)mi/;
			my ($Mileage) = $response_string =~ m/\)is(.*?)miles\./;
#warn "MILEAGE: $Mileage";

			$Mileage = ceil($Mileage);
			$self->SetValuesArray(
				'origin',	$FromZip,
				'dest',		$ToZip,
				'mileage',	$Mileage,
			);

			$self->Create();
			$self->{'object_dbref'}->commit();

			return $Mileage;
   	}
		else
		{
			return 0;
		}
	}
}

1;
