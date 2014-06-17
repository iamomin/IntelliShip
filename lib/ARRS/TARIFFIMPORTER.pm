{
	package ARRS::TARIFFIMPORTER;

	use strict;
	use ARRS::CARRIER;
	use ARRS::COMMON;
	use ARRS::CSOVERRIDE;
	use ARRS::CUSTOMERSERVICE;
	use ARRS::ZIPMILEAGE;

	use Array::Compare;
	use Date::Calc qw(Delta_Days);
	use Date::Manip qw(ParseDate UnixDate);
	use IntelliShip::MyConfig;
    use Data::Dumper;

	my $Benchmark = 0;
	my $config = IntelliShip::MyConfig->get_ARRS_configuration;

	sub new
	{
		my $proto = shift;
		my $class = ref($proto) || $proto;

		my $self = {};

		( $self->{'tariffdbname'}, $self->{'arrsdbref'}) = @_;

		$self->{'dbref'} = ARRS::IDBI->connect(
			{
				dbname		=> $self->{'tariffdbname'},
				dbhost		=> $config->{DB_HOST},
				dbuser	 	=> $config->{DB_USER},
				dbpassword	=> $config->{DB_PASSWORD},
				autocommit	=> 0,
			}
		) or die "Could not connect to database: " .$self->{'tariffdbname'};
		
		bless($self, $class);
		return $self;
	}
	
	sub ImportTariff
	{
		my $self = shift;
		my ($content, $ratetypeid) = @_;
		#warn "########## ImportTariff " . $content;
		
		my @rows = split("\r\n", $content);
		my $row_count = 0;
		foreach my $row (@rows){
			my $result = $self->ProcessRow($row, $ratetypeid);
			if($result){
				$row_count++;
			}
		}
		
		return {status => 'success', message => "$row_count row(s) processed for $ratetypeid"};
	}
	
	sub ProcessRow
	{
		my $self = shift;
		my ($row, $ratetypeid) = @_;
		warn "########## processRow " . $row;
		my $carrierscac = substr($row, 1, 3);
		my $originbegin = substr($row, 5, 5);
		my $originstate = substr($row, 10, 2);
		my $destlowzip = substr($row, 12, 5);
		my $desthighzip = substr($row, 17, 3);
		my $deststate = substr($row, 20, 2);
		my $class = substr($row, 22, 3);
		my $mc1 = substr($row, 25, 6);
		$mc1 = $mc1 / 100 if $mc1;
		my $mc2 = substr($row, 31, 6);
		$mc2 = $mc2 / 100 if $mc2;
		my $mc3 = substr($row, 37, 6);
		$mc3 = $mc3 / 100 if $mc3;
		my $mc4 = substr($row, 43, 6);
		$mc4 = $mc4 / 100 if $mc4;
		my $l5c = substr($row, 49, 6);
		$l5c = $l5c / 100 if $l5c;
		my $m5c = substr($row, 55, 6);
		$m5c = $m5c / 100 if $m5c;
		my $m1m = substr($row, 61, 6);
		$m1m = $m1m / 100 if $m1m;
		my $m2m = substr($row, 67, 6);
		$m2m = $m2m / 100 if $m2m;
		my $m5m = substr($row, 73, 6);
		$m5m = $m5m / 100 if $m5m;
		my $m10m = substr($row, 79, 6);
		$m10m = $m10m / 100 if $m10m;
		my $m20m = substr($row, 85, 6);
		$m20m = $m20m / 100 if $m20m;
		my $m30m = substr($row, 91, 6);
		$m30m = $m30m / 100 if $m30m;
		my $m40m = substr($row, 97, 6);
		$m40m = $m40m / 100 if $m40m;
		
		my $rbno = substr($row, 103, 6);
		
		my $mc5 = substr($row, 109, 6);
		$mc5 = $mc5 / 100 if $mc5;
		my $mc6 = substr($row, 115, 6);
		$mc6 = $mc6 / 100 if $mc6;
		my $mc7 = substr($row, 121, 6);
		$mc7 = $mc7 / 100 if $mc7;
		my $mc8 = substr($row, 127, 6);
		$mc8 = $mc8 / 100 if $mc8;
		my $ssmc1 = substr($row, 133, 6);
		$ssmc1 = $ssmc1 / 100 if $ssmc1;
		my $ssmc2 = substr($row, 139, 6);
		$ssmc2 = $ssmc2 / 100 if $ssmc2;
		my $ssmc3 = substr($row, 145, 6);
		$ssmc3 = $ssmc3 / 100 if $ssmc3;
		my $ssmc4 = substr($row, 151, 6);
		$ssmc4 = $ssmc4 / 100 if $ssmc4;
		my $ssmc5 = substr($row, 157, 6);
		$ssmc5 = $ssmc5 / 100 if $ssmc5;
		my $ssmc6 = substr($row, 163, 6);
		$ssmc6 = $ssmc6 / 100 if $ssmc6;
		my $ssmc7 = substr($row, 169, 6);
		$ssmc7 = $ssmc7 / 100 if $ssmc7;
		my $ssmc8 = substr($row, 175, 6);
		$ssmc8 = $ssmc8 / 100 if $ssmc8;

		my $rateid = $self->{'arrsdbref'}->gettokenid();
		
		warn "########## inserting row by id: $rateid";
		
		
		$desthighzip =~ s/^\s+//;
		$desthighzip =~ s/\s+$//;
		my $dhlength = length($desthighzip);
		if($dhlength < 5 && length($destlowzip) == 5 && $destlowzip =~ /^[0-9]+$/)
		{
			warn "########## \$desthighzip = $desthighzip, \$dhlength=$dhlength";
			my $dhprefix = substr($destlowzip, 0, 5 - $dhlength);
			$desthighzip = $dhprefix . "" . $desthighzip;
			warn "########## \$destlowzip = $destlowzip, new \$desthighzip = $desthighzip";
		}
		
		my $sql = "INSERT INTO rate(
							rateid, ratetypeid, carrierscac, originbegin, originend, originstate, 
							destbegin, destend, deststate, class, mc1, mc2, mc3, mc4, l5c, 
							m5c, m1m, m2m, m5m, m10m, m20m, m30m, m40m, rbno, mc5, mc6, mc7, 
							mc8, ssmc1, ssmc2, ssmc3, ssmc4, ssmc5, ssmc6, ssmc7, ssmc8)
					VALUES (?, ?, ?, ?, ?, ?, 
							?, ?, ?, ?, ?, ?, ?, ?, ?, 
							?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 
							?, ?, ?, ?, ?, ?, ?, ?, ?)";
					
		my $sth = $self->{'dbref'}->prepare($sql)
											or die "Could not prepare SQL statement";
		#warn "########## prepared statement $sql";
		my $success = $sth->execute($rateid, $ratetypeid, $carrierscac, $originbegin, $originbegin, $originstate, $destlowzip, $desthighzip,  $deststate, $class, $mc1, $mc2, $mc3, $mc4, $l5c, $m5c, $m1m, $m2m, $m5m, $m10m, $m20m, $m30m, $m40m, $rbno, $mc5, $mc6, $mc7, $mc8, $ssmc1, $ssmc2, $ssmc3, $ssmc4, $ssmc5, $ssmc6, $ssmc7, $ssmc8)
								or die "####### Could not execute statement: ".$self->{'dbref'}->errstr;
		
		warn "########## executed statement $success";
		
		if($success){
			 $self->{'dbref'}->commit;
			 warn "######### Added row to rate table: " + $rateid;			 
		}else{
			 $self->{'dbref'}->rollback;			 
			 warn "######### Failed to add row to rate table: " + $rateid;			 
		}
		
		$sth->finish();
		return $success;
	}
}
1;