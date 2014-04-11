#!/usr/bin/perl -w

#####################################################################
##
##	module COMMON
##
##	Engage TMS, Inc common functions
##
#####################################################################

{
	package ARRS::COMMON;

	use strict;

	use vars qw (@ISA @EXPORT);

	use Benchmark ':hireswallclock';
	use Date::Calendar;
	use Date::Business;
	use Date::Manip qw(ParseDate UnixDate);
	use Date::Calc qw(Delta_Days Add_Delta_Days);
	use DBI;
	use File::Basename;
	use HTTP::Request::Common;
	use LWP::UserAgent;
	use MIME::Lite;
	use POSIX qw(strftime);
	use Sys::Hostname;
	use IntelliShip::MyConfig;

	use Exporter;
	@ISA = ('Exporter');

	# Add function names to this array to get them exported for public use.
	@EXPORT = qw(&DefaultTo &IAmRunning &TraceBack &TrimHashRefValues &WarnHashRefValues &ZipToCity &TrimString &ArrayToTraceString &GetShortDates &GetAddressTag &SendStringAsEmailAttachment &SendFileAsEmailAttachment &GetFutureBusinessDate &Holiday &GetFutureDate &StripNaked &GetServerType &GetFreightClassFromDensity &DateIsPassed &VerifyDate &VerifyDateTime &SaveStringToFile &DateIsToday &FlushBrowser &VerifyEmail &GetIntellishipURL &DedupeArray &ChopHashRef &GetBoxCount &GetBillToName &commafy &CleanCgiRef &APIRequest &TurnAPIReturnToRef &Benchmark &GetDeltaDays);

	my $config = IntelliShip::MyConfig->get_ARRS_configuration;

	sub DefaultTo
	{
		my ($InString, $DefaultTo) = @_;
		my $Output = (defined($InString) && $InString ne '') ? $InString : $DefaultTo;
		return $Output;
	}

	sub IAmRunning
	{
		my ($filename,$filepath) = fileparse($0);

		if ( !(my @pid_files = <${filepath}/run/$filename.*>) )
		{
			system("/bin/touch $filepath/run/$filename.$$");
			return 0;
		}
		else
		{
			foreach my $pid_file (@pid_files)
			{
				my ($check_pid) = $pid_file =~ /.*\.pl\.(\d+)$/;
				my ($trunc_filename) = $filename =~ /^(\w{1,15})/;

				if ( my $found_pid = `ps -eo pid,comm | grep -s '$check_pid $trunc_filename'` )
				{
					return 1;
				}
				else
				{
					unlink($pid_file) || warn "Cannot unlink $pid_file: $!";
				}
			}
		}

		system("/bin/touch $filepath/run/$filename.$$");
		return 0;
	}

	sub TraceBack
	{
		my ($Error, $Die) = @_;

		$Die = DefaultTo($Die, 0);

		my $string = '';

		$string .= "TRACEBACK-----------------\n";
		$string .= "$Error\n";
		my $i = 1;
		while ( my($pkg, $file, $line, $callingsub) = caller($i++) )
		{
			$string .= "\t$callingsub at $file line $line\n";
		}
		$string .= "TRACEBACK-----------------";

		warn $string;

		die if $Die;
	}

# Trims all multiple internal whitespace down to a single space
	sub TrimHashRefValues
	{
		my ($HashRef) = @_;

		foreach my $Key (keys(%$HashRef))
		{
			if (defined($HashRef->{$Key}))
			{
				$HashRef->{$Key} =~ s/(.*?)\s*$/$1/;
				$HashRef->{$Key} =~ s/^\s*(.*)/$1/;
				$HashRef->{$Key} =~ s/\\//;
				$HashRef->{$Key} =~ s/ +/ /g;
			}
		}

		return $HashRef;
	}

	sub WarnHashRefValues
	{
		my ($ValueRef,$ShowEmptyKeys) = @_;

		print STDERR "-----------------------------------\n";

		# Warn out where we are.
		my($pkg, $file, $line, $callingsub) = caller(0);
		print STDERR "$file: $line\n";

		foreach my $Key (sort(keys(%$ValueRef)))
		{
		 	if ( defined($ValueRef->{$Key}) && $ValueRef->{$Key} ne '' )
			{
				print STDERR "$Key = |".$ValueRef->{$Key}."|\n";
#				if ($ValueRef->{$Key} eq ',')
#				{
#					die;
#				}
			}
			else
			{
				if ( $ShowEmptyKeys )
				{
					warn "$Key = ||";
				}
			}
		}
		print STDERR "-----------------------------------\n";
	}

	sub ArrayToTraceString
	{
		my (@Array) = @_;

		my $Output = '|';

		foreach my $Element (@Array)
		{
			$Output .= "$Element|";
		}

		$Output .= "\n";

		return $Output;
	}

# Preserves all internal whitespace (but truncate multiple internal spaces to one)
	sub TrimString
	{
		my ($String) = @_;

		if ( defined($String) && $String ne '' )
		{
			$String =~ s/(.*?)\s*$/$1/;
			$String =~ s/^\s*(.*)/$1/;
			$String =~ s/ +/ /;
		}

		return $String;
	}

	sub ZipToCity
	{
		my ($DBRef, $Zip) = @_;

		$Zip = TrimString($Zip);

		if (!defined($Zip) || $Zip eq '')
		{
			return 'UNKNOWN';
		}

		my $SQLString = "
			SELECT
				city
			FROM
				postalcode
			WHERE
				postalcode = ?
		";

		my $STH = $DBRef->prepare_cached($SQLString)
			or TraceBack("Could not prepare sql.", 1);

		$STH->execute($Zip)
			or TraceBack("Could not execute sql.", 1);

		my ($City) = $STH->fetchrow_array();

		$STH->finish();

		if (!defined($City))
		{
			$City = 'UNKNOWN';
		}

		return $City;
	}

   # Used to get truncated dates for display on mywo, wo, and myapbilling
   sub GetShortDates
   {
      my ($full_date) = @_;

      my ($short_date) = $full_date =~ /\d{4}-(\d{2}-\d{2} \d{2}):\d{2}:\d{2}(\.\d+)?-\d{2}/;
      $short_date =~ s/-/\//g;

      return ($short_date);
   }

	sub GetAddressTag
	{
			my ($Name,$Address1,$Address2,$City,$Province,$PostalCode,$Country,$Name2) = @_;

			my $Address = '';

			if ( defined($Name) and $Name ne '' )
			{
				$Address .= "&nbsp;" . $Name . "<br>";
			}

			if ( defined($Name2) and $Name2 ne '' )
			{
				$Address .= "&nbsp;" . $Name2 . "<br>";
			}

			if ( defined($Address1) and $Address1 ne '' )
			{
				$Address .= "&nbsp;" . $Address1 . "<br>";
			}

			if ( defined($Address2) and $Address2 ne '' )
			{
				$Address .= "&nbsp;" . $Address2 . "<br>";
			}

			if ( defined($City) and $City ne '' )
			{
				$Address .= "&nbsp;" . $City . ",&nbsp;";
			}

			if ( defined($Province) and $Province ne '' )
			{
				$Address .= "&nbsp;" . $Province . "&nbsp;";
			}

			if ( defined($PostalCode) and $PostalCode ne '' )
			{
				$Address .= "&nbsp;" . $PostalCode;
			}

			if ( (defined($City) and $City ne '') ||
					(defined($Province) and $Province ne '' ) ||
					(defined($PostalCode) and $PostalCode ne '' ) )
			{
				$Address .= "<br>";
			}

			if ( defined($Country) and $Country ne '' )
			{
				$Address .= "&nbsp;" . $Country;
			}

			return $Address;

	}

	sub SendStringAsEmailAttachment
	{
		my ($from_email,$to_email,$cc,$bcc,$subject,$body,$string,$file_name,$from_name,$mime_type) = @_;

		if ( &GetServerType == 3 )
		{
			$subject = 'TEST ' . $subject;

			if
			(
				$to_email !~ /noc\@.*$config->{BASE_DOMAIN}/ &&
				$cc !~ /noc\@.*$config->{BASE_DOMAIN}/ &&
				$bcc !~ /noc\@.*$config->{BASE_DOMAIN}/
			)
			{
				$cc = 'noc@engagetms.com,' . $cc;
			}
		}

		$mime_type = DefaultTo($mime_type,'text/html');

		if ( defined($from_name) && $from_name ne '' )
		{
			$from_email = $from_name . "<" . $from_email . ">";
		}

		local $^W = 0;
		my $msg = MIME::Lite->new(
			From            =>      "$from_email",
			To              =>      "$to_email",
			CC              =>      "$cc",
			BCC             =>      "$bcc",
			Subject         =>      "$subject",
			Data            =>      "$body",
		);
		local $^W = 1;

		if ( defined($string) && $string ne '' )
		{
			$msg->attach(
				Type            =>      "$mime_type",
				Data            =>      "$string",
				Filename        =>      "$file_name",
			);
		}

		$msg->send();
	}

	sub SendFileAsEmailAttachment
	{
		my ($from_email,$to_email,$cc,$bcc,$subject,$body,$file,$file_name,$from_name,$mime_type) = @_;

		if ( &GetServerType == 3 )
		{
			$subject = 'TEST ' . $subject;

			if ( $to_email !~ /noc\@engagetms\.com/ && $cc !~ /noc\@engagetms\.com/ && $bcc !~ /noc\@engagetms\.com/ )
			{
				$cc = 'noc@engagetms.com,' . $cc;
			}
		}

		$mime_type = DefaultTo($mime_type,'text/html');

		if ( defined($from_name) && $from_name ne '' )
		{
			$from_email = $from_name . "<" . $from_email . ">";
		}

		local $^W = 0;
		my $msg = MIME::Lite->new(
			From            =>      "$from_email",
			To              =>      "$to_email",
			CC              =>      "$cc",
			BCC             =>      "$bcc",
			Subject         =>      "$subject",
			Data            =>      "$body",
		);
		local $^W = 1;

		if ( -r $file )
		{
			$msg->attach(
				Type            =>      "$mime_type",
				Path            =>      "$file",
				Filename        =>      "$file_name",
			);
		}

		$msg->send();
	}

	sub GetFutureBusinessDate
	{
		my ($start_date,$offset_days,$include_saturday,$include_sunday,$start_dow,$norm_start_date) = @_;

		# If we didn't pass in a normalized start or a start DOW, calc it from 'start_date'
		# ( this is a fairly spendy calc - pass it in if you can )
		if ( !$norm_start_date || !$start_dow )
		{
			my $parsed_start_date = ParseDate($start_date);
			$norm_start_date = UnixDate($parsed_start_date, "%Q");
			$start_dow = UnixDate($parsed_start_date, "%a");
		}

		my $stop_date;

		# If no offset is given, return 'today' if it's a weekday, or the following business
		# day if it's a weekend or holiday
		if
		(
			( !defined($offset_days) || $offset_days eq '' ) &&
			( $start_dow eq 'Sat' || $start_dow eq 'Sun' )
		)
		{
			$offset_days = 1;
		}

		# Normal
	 	if ( !$include_saturday && !$include_sunday )
		{
			$stop_date = new Date::Business(
				DATE     => $norm_start_date,
				OFFSET   => $offset_days,
				HOLIDAY  => \&Holiday
			);
		}
		# One or both weekend days included
		else
		{
			$stop_date = new Date::Business(
				DATE     => $norm_start_date,
				HOLIDAY  => \&Holiday
			);

			for ( my $i = 1; $i < ($offset_days + 1); $i ++ )
			{
				$stop_date->next();

				if ( $stop_date->day_of_week() == 6 && !$include_saturday )
				{
					$stop_date->next();
				}

				if ( $stop_date->day_of_week() == 0 && !$include_sunday )
				{
					$stop_date->next();
				}
			}
		}

		$stop_date = $stop_date->image();
		$stop_date =~ s/(\d{4})(\d{2})(\d{2})/$2\/$3\/$1/;

#warn "|$start_date|$offset_days|$stop_date|";
		return $stop_date;
	}

	sub GetFutureDate
	{
		my ($start_date,$offset_days) = @_;

		my $parsed_start_date = ParseDate($start_date);
		my @norm_start_date = UnixDate($parsed_start_date, "%Y", "%m", "%d");

		my ($stop_year,$stop_month,$stop_day) = Add_Delta_Days(@norm_start_date, $offset_days);

		if ( $stop_month =~ /^\d$/ ) { $stop_month = 0 . $stop_month }
		if ( $stop_day =~ /^\d$/ ) { $stop_day = 0 . $stop_day }

		my $stop_date = $stop_month . '/' . $stop_day . '/' . $stop_year;

#warn "|$start_date|$offset_days|$stop_year|$stop_month|$stop_day|$stop_date|";
		return $stop_date;
	}

	sub StripNaked
   {
   	my ($string) = @_;

      if ( !defined($string) || $string eq '' ) { return undef }

      $string = uc($string);
      $string =~ s/ //g;
      $string =~ s/[^a-zA-Z0-9]+//gs;
      $string =~ s/A//g;
      $string =~ s/E//g;
      $string =~ s/I//g;
      $string =~ s/O//g;
      $string =~ s/U//g;
      $string =~ s/(\D)\1+/$1/g;

      $string = substr($string,0,50);

      return $string;
   }


	sub Holiday
	{
		my ($start, $end) = @_;
		my $year = (localtime)[5] + 1900;

		my ($numHolidays) = 0;
		my ($holiday, @holidays);

		my $Profiles = {};
		$Profiles->{'US-Shipping'} = # United States of America - Shipping holidays
		{
			"New Year's Day"		=>	"1/1",
			"Memorial Day"			=>	"5/Mon/May",
			"Independence Day"	=>	"7/4",
			"Labor Day"				=>	"1/Mon/Sep",
			"Thanksgiving Day"	=>	"4/Thu/Nov",
			"Christmas Day"		=>	"12/25",
		};

		# Iterate through this year and next, to make sure we don't get caught by next year's holidays
		my @years = ( $year, ($year + 1) );
		foreach my $year (@years)
		{
			my $calendar = Date::Calendar->new($Profiles->{'US-Shipping'});
			my $year = $calendar->year($year);

			my @dates = $calendar->search('');

			foreach my $date (@dates)
			{
				# Take date array ref and turn it into a string for use as we move forward
				if ( @$date[2] !~ /\d{2}/ ) { @$date[2] = '0' . @$date[2] }
				if ( @$date[3] !~ /\d{2}/ ) { @$date[3] = '0' . @$date[3] }
				my $date = @$date[1] . @$date[2] . @$date[3];

				my $check_date = new Date::Business(DATE	=>	$date);
				if ( $check_date != 0 && $check_date != 6 )
				{
					push(@holidays,$date);
				}
			}
		}

		foreach $holiday (@holidays)
		{
			$numHolidays++ if ($start le $holiday && $end ge $holiday);
		}

		return $numHolidays;
	}

	sub GetServerType
	{
		# 1 = prod, 2 = beta, 3 = dev
		# Default it to prod
		my $ServerType = 1;

		my $Server = hostname();

		my ($ServerTypeID) = $Server =~ /\w{3}(\d{2})\w{3}\d{2}/;

		if ( $ServerTypeID eq '02' )
		{
		   $ServerType = 2;
		}
		elsif ( $ServerTypeID eq '00' )
		{
		   $ServerType = 3;
		}

		return $ServerType;
	}

	sub GetFreightClassFromDensity
	{
		my ($Weight,$DimLength,$DimWidth,$DimHeight,$Density) = @_;
		my ($FreightClass);

		if ( !defined($Density) || $Density eq '' )
		{
			if
			(
				( defined($DimLength) && $DimLength > 0 )
				&&
				( defined($DimWidth) && $DimWidth > 0 )
				&&
				( defined($DimHeight) && $DimHeight > 0 )
			)
			{
				$Density = int(($Weight/($DimLength * $DimWidth * $DimHeight)) * 1728 );
			}
			else
			{
				return 0;
			}
		}

		if ( $Density < 1 )
		{
			$FreightClass = 400;
		}
		elsif ( $Density >= 1 && $Density < 2 )
		{
			$FreightClass = 300;
		}
		elsif ( $Density >= 2 && $Density < 4 )
		{
			$FreightClass = 250;
		}
		elsif ( $Density >= 4 && $Density < 6 )
		{
			$FreightClass = 150;
		}
		elsif ( $Density >= 6 && $Density < 8 )
		{
			$FreightClass = 125;
		}
		elsif ( $Density >= 8 && $Density < 10 )
		{
			$FreightClass = 100;
		}
		elsif ( $Density >= 10 && $Density < 12 )
		{
			$FreightClass = 92.5;
		}
		elsif ( $Density >= 12 && $Density < 15 )
		{
			$FreightClass = 85;
		}
		elsif ( $Density >= 15 && $Density < 18 )
		{
			$FreightClass = 70;
		}
		elsif ( $Density >= 18 && $Density < 21 )
		{
			$FreightClass = 65;
		}
		elsif ( $Density >= 21 && $Density < 24 )
		{
			$FreightClass = 60;
		}
		elsif ( $Density >= 24 && $Density < 27 )
		{
			$FreightClass = 55;
		}
		elsif ( $Density >= 27 && $Density < 30 )
		{
			$FreightClass = 50;
		}

		return $FreightClass;
	}

	sub DateIsPassed
	{
		my ($Date) = @_;

		my $DatePassed = 0;

		if ( my $NormalizedDate = VerifyDate($Date) )
		{
			my ($month,$day,$year) = $NormalizedDate =~ /(\d{2})\/(\d{2})\/(\d{4})/;
			my @Date = ($year,$month,$day);
			my @CurrentDate = split(/:/,strftime("%Y:%m:%d", localtime(time)));

			if ( Delta_Days(@CurrentDate, @Date) < 0 )
			{
				$DatePassed = 1;
			}
		}

		return $DatePassed;
	}

	sub VerifyDate
	{
		my ($date) = @_;

		if ( defined($date) && $date ne '' )
		{
			my $formatdate = 0;
			#$date =~ s/-\d{2}$//g; Not sure why this is heare - it messes with hyphenated dates
			#$date =~ s/-/\//g; ParseDate Can handle hyphens now

			if ( my $parsed_date = ParseDate($date) )
			{
				my ($year,$month,$day) = UnixDate($parsed_date, "%Y", "%m", "%d");
				$formatdate = $month . "/" . $day . "/" . $year;
			}

			return $formatdate;
		}
		else
		{
			return undef;
		}
	}

	sub VerifyDateTime
	{
		my ($date) = @_;

		if ( defined($date) && $date ne '' )
		{
			my $formatdate = 0;
			$date =~ s/-\d{2}$//g;
			$date =~ s/-/\//g;

			if ( my $parsed_date = ParseDate($date) )
			{
				my ($year,$month,$day,$hour,$minute) = UnixDate($parsed_date, "%Y", "%m", "%d", "%H", "%M");
				$formatdate = $month . "/" . $day . "/" . $year . " " . $hour . ":" . $minute;
			}
			return $formatdate;
		}
		else
		{
			return undef;
		}
	}

	sub SaveStringToFile
	{
		my ($FileName,$FileString) = @_;

		if ( defined($FileString) && $FileString ne '' && defined($FileName) && $FileName ne '' )
		{
			open (FILE,">$FileName")
				or die "Could not open $FileName: $!";

			print FILE "$FileString";

			close (FILE)
				or die "Could not close $FileName: $!";

			return (1);
		}
	}

	sub DateIsToday
	{
		my ($Date) = @_;

		my $DateIsToday = 0;

		if ( my $NormalizedDate = VerifyDate($Date) )
		{
			my ($month,$day,$year) = $NormalizedDate =~ /(\d{2})\/(\d{2})\/(\d{4})/;
			my @Date = ($year,$month,$day);
			my @CurrentDate = split(/:/,strftime("%Y:%m:%d", localtime(time)));

			if ( Delta_Days(@CurrentDate, @Date) == 0 )
			{
				$DateIsToday = 1;
			}
		}

		return $DateIsToday;
	}

   sub FlushBrowser
   {
      if ( $0 =~ /index\.cgi/ )
      {
         # Keep the browser from timing out.
         print "\n";
         STDOUT->autoflush(1);
      }
   }

	sub VerifyEmail
	{
		my ($EmailAddressString) = @_;

		# Allow for comma delimited emails
		my @EmailAddress = split(/,/,$EmailAddressString);

		foreach my $EmailAddress (@EmailAddress)
		{
			$EmailAddress =~ s/^\s+//;
			$EmailAddress =~ s/\s+$//g;

			if ( $EmailAddress !~ /^[-_a-zA-Z0-9]+(\.[-_a-zA-Z0-9]+)*@[-a-zA-Z0-9]+(\.[-a-zA-Z0-9]+)*\.[a-zA-Z]{2,6}$/ )
			{
				return 0;
			}
		}

		return 1;
	}

	sub GetIntellishipURL
	{
		if ( hostname() eq 'atx01web01' )
		{
			return "intelliship.$config->{BASE_DOMAIN}";
		}
		elsif ( hostname() eq 'atx00web01' )
		{
			return "dintelliship.$config->{BASE_DOMAIN}";
		}
		elsif ( hostname() eq 'rml01web01' )
		{
			return 'remel.logistikasinc.com';
		}
		elsif ( hostname() eq 'rml00web01' )
		{
			return 'dremel.logistikasinc.com';
		}
	}

	sub DedupeArray
   {
      my @Array = @_;
      my @DedupedArray = ();
      my %Seen = ();

      foreach my $Item (@Array)
      {
         push(@DedupedArray,$Item) unless $Seen{$Item}++;
      }

      return @DedupedArray;
   }

	sub ChopHashRef
	{
		my ($Ref) = @_;

		foreach my $Key (keys(%$Ref))
		{
			chop($Ref->{$Key});
		}

		return $Ref;
	}

	sub GetBoxCount
	{
		my ($ShipmentRef) = @_;
		my $BoxCount = 1;

		foreach my $Key (sort(keys(%$ShipmentRef)))
		{
			if ( $Key !~ /^boxnum(\d+)$/ )
			{
				next
			}
			else
			{
				if ( $ShipmentRef->{$Key} > $BoxCount )
				{
					$BoxCount = $ShipmentRef->{$Key};
				}
			}
		}

		return $BoxCount;
	}

	sub GetBillToName
   {
      my ($webaccount, $customername) = @_;

		my $billtoname = '';

      if ( defined($webaccount) || $webaccount )
      {
			my @holder = split(" ",$customername);
      	$customername = shift(@holder);
         $billtoname = $webaccount . " (" . $customername . ")";
      }
      else
      {
         $billtoname = $customername;
      }

		return $billtoname;
   }

	sub commafy
   {
      local $_  = shift;
      if ($_ ne 0)
		{
         1 while s/^(-?\d+)(\d{3})/$1,$2/;
      }

		return $_;
   }

	sub CleanCgiRef
	{
		my ($HashRef) = @_;

		foreach my $Key (keys(%$HashRef))
		{
			$HashRef->{$Key} =~ s/\0/\|/;
		}

		return $HashRef;
	}

	sub APIRequest
	{
		my ($CgiRef) = @_;

		my $ua = LWP::UserAgent->new;

		$CgiRef->{'screen'} = 'api';
		$CgiRef->{'username'} = $config->{ADMIN_USER},
		$CgiRef->{'password'} = $config->{ADMIN_PASSWORD},
		$CgiRef->{'httpurl'} = "http://darrs.$config->{BASE_DOMAIN}";

		my $Response = $ua->request(
			POST $CgiRef->{'httpurl'},
				Content_Type	=>	'multipart/form-data',
				Content			=>	[%$CgiRef]
		);

		$Response->remove_header($Response->header_field_names);

		return $Response->as_string;
	}

	sub TurnAPIReturnToRef
	{
		my ($String) = @_;
		my $Ref = {};

		my @Lines = split(/\n/,$String);

		while (@Lines)
		{
			my $Line = shift(@Lines);

			my ($Key,$Value) = $Line =~ /(\w+): (.*)/;

			if ( $Key && $Value )
			{
				$Ref->{$Key} = $Value;
			}
		}

		return $Ref;
	}

   sub Benchmark
   {
		my ($Start,$Tag) = @_;

		# Figure out where we are.
		my($pkg, $file, $line, $callingsub) = caller(0);

		if ( $Start )
		{
			my $td = timestr(timediff(new Benchmark,$Start));
			$td =~ s/(.*) wallclock (secs).*/$1 $2/;
			print STDERR "$Tag: $td at $file: $line\n";

			return $1;
		}
		else
		{
			return new Benchmark;
		}
	}

	sub GetDeltaDays
	{
		my ($Date1,$Date2) = @_;

		my @Date2;
		if ( !defined($Date2) || $Date2 eq '' )
		{
			@Date2 = split(/:/,strftime("%Y:%m:%d", localtime(time)));
		}
		else
		{
			$Date2 = VerifyDate($Date2);

			my ($Month2,$Day2,$Year2) = $Date2 =~ /(\d{2})\/(\d{2})\/(\d{4})/;
			@Date2 = ($Year2,$Month2,$Day2);
		}

		$Date1 = VerifyDate($Date1);

		my ($Month1,$Day1,$Year1) = $Date1 =~ /(\d{2})\/(\d{2})\/(\d{4})/;
		my @Date1 = ($Year1,$Month1,$Day1);

		# Return is positive if dates are chronological (i.e. Date1 comes before Date2)
		return Delta_Days(@Date1,@Date2);
	}
}
1;
