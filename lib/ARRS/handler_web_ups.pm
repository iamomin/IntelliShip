	package ARRS::handler_web_ups;

	use strict;
	use ARRS::CARRIERHANDLER;
	@ARRS::handler_web_ups::ISA = ("ARRS::CARRIERHANDLER");

	use ARRS::COMMON;

	use POSIX qw(ceil);
	use HTTP::Request;
	use LWP::UserAgent;

	my $Debug = 0;

	sub new
	{
		my $proto = shift;
		my $class = ref($proto) || $proto;

		my ($DBRef, $Customer) = @_;
		my $self = $class->SUPER::new($DBRef,$Customer);

		bless($self, $class);
		return $self;
	}

	sub GetFSCData
	{
		my $self = shift;

		my $ua = LWP::UserAgent->new;
		my $req_url = "http://www.ups.com/content/us/en/shipping/cost/zones/fuel_surcharge.html";
		my $req = new HTTP::Request("GET" => $req_url);
		my $response = $ua->request($req);
		my $response_string = $response->as_string;

		my ($fsc_history) = $response_string =~ /The following table illustrates the fuel surcharge history(.*?)<\/table>/s;
		my @fsc_data = ();

		while ( $fsc_history =~ /modulepad">([^<].*?)<\/div>/gs )
		{
			push(@fsc_data,$1);
		}

		my $fsc_data = {};
		my $fsc_counter = 0;

		for ( my $i = 0; $i < scalar(@fsc_data); )
		{
			my ($start_date,$stop_date) = $fsc_data[$i++] =~ /(.*) - (.*)/;
			$start_date = &VerifyDate($start_date);
			$stop_date = &VerifyDate($stop_date);

		   $fsc_data[$i] =~ s/(\d+\.?\d{0,2})%/$1\/100/e;

			foreach my $id (&GroundServiceIDs)
			{
				$fsc_data->{$fsc_counter}->{$id} = {
					start_date	=>	$start_date,
					stop_date	=>	$stop_date,
					fsc_rate		=>	$fsc_data[$i], # Ground FSC rate
				};
			}

			$i++;

		   $fsc_data[$i] =~ s/(\d+\.?\d{0,2})%/$1\/100/e;

			foreach my $id (&AirServiceIDs)
			{
				$fsc_data->{$fsc_counter}->{$id} = {
					start_date	=>	$start_date,
					stop_date	=>	$stop_date,
					fsc_rate		=>	$fsc_data[$i], # Air FSC rate
				};
			}

			$i++;
			$fsc_counter++;
		}

		return $fsc_data;
	}

	sub GroundServiceIDs
	{
		return qw(
			upsground0000
			1100000000005
			1100000000012
			upsstandard00
		);
	}

	sub AirServiceIDs
	{
		return qw(
			ups2dayair000
			ups2dayairam0
			ups3dayselect
			upsndair00000
			upsndairsaver
			upsndearlyam0
			upsexpress000
			upssaver00000
			upsexpedited0
		);
	}

1
