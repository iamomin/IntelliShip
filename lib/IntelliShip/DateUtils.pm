package IntelliShip::DateUtils;

use Moose;
use DateTime;
use Date::Business;
use Date::Calendar;
use Time::HiRes qw/gettimeofday/;
use Date::Manip qw(ParseDate UnixDate);
use Date::Calc qw(Date_to_Text_Long check_date Delta_Days Add_Delta_Days Delta_DHMS Add_Delta_DHMS Day_of_Week Add_Delta_YMDHMS Timezone);

=head1 NAME

IntelliShip::DateUtils

=head1 SYNOPSIS

Collection of subroutines to manipulate date/time information.

=head1 METHODS

List below are the subroutines available.

=cut

sub date_to_text_long
	{
	my $self = shift;
	my $fulldate = shift;

	($fulldate, my $time) = split($&, $fulldate) if $fulldate =~ /(\ |T)/;

	my ($yy, $mm, $dd);
	($yy, $mm, $dd) = split(/\-/, $fulldate) if $fulldate =~ /-/;
	($mm, $dd, $yy) = split(/\//, $fulldate) if $fulldate =~ /\//;

	my $date = Date_to_Text_Long($yy, $mm, $dd);

	return $date . ' ' . $time;
	}

=head2 american_date

	my $american_date = IntelliShip::DateUtils->american_date('2007-05-01');
	print $american_date; # 05/01/2007

	my $american_date = IntelliShip::DateUtils->american_date('2007/05/01');
	print $american_date; # 05/01/2007

=cut

sub american_date
	{
	my $self = shift;
	my $date = shift;

	return '' unless $date;

	my ($yy, $mm, $dd);
	if ($date =~ /\:/)
		{
		$date =~ s/\D//g;
		$yy = substr($date, 0, 4);
		$mm = substr($date, 4, 2);
		$dd = substr($date, 6, 2);
		}
	else
		{
		($yy, $mm, $dd) = split(/\-/, $date) if $date =~ /-/;
		($mm, $dd, $yy) = split(/\//, $date) if $date =~ /\//;
		}

	return "$mm/$dd/$yy";
	}

sub american_date_time
	{
	my $self = shift;
	my $date_time = shift;

	$date_time = $self->timestamp unless $date_time;
	$date_time =~ s/\D//g;

	my $yy   = substr($date_time, 0, 4);
	my $mm   = substr($date_time, 4, 2);
	my $dd   = substr($date_time, 6, 2);
	my $time = substr($date_time, 8, 2) . ':' . substr($date_time, 10, 2) . ':' . substr($date_time, 12, 2);

	return "$mm/$dd/$yy $time";
	}

=head2 current_date

	my $date = IntelliShip::DateUtils->current_date('/');
	print $date; $ 2008/12/31

	my $date = IntelliShip::DateUtils->current_date;
	print $date; $ 2008-12-31

=cut

sub current_date
	{
	my $self = shift;
	my $separator = shift;

	$separator = '-' unless $separator;

	my @tm = localtime;
	my ($tm, $date);

	$tm[4] += 1;

	$tm[3] = "0" . $tm[3] if ($tm[3] < 10);
	$tm[4] = "0" . $tm[4] if ($tm[4] < 10);

	$tm[5] = $tm[5] + 1900;
	if ($separator =~ /\//)
		{
		$date = $tm[4] . $separator . $tm[3] . $separator . $tm[5];
		}
	else
		{
		$date = $tm[5] . $separator . $tm[4] . $separator . $tm[3];
		}

	return ($date);
	}

sub current_time
	{
	my $self = shift;
	my $timestamp = $self->timestamp;
	my $hours = substr($timestamp, 8, 2);
	my $min   = substr($timestamp, 10, 2);
	my $sec   = substr($timestamp, 12, 2);
	return "$hours:$min:$sec";
	}

sub get_db_format_date
	{
	my $self = shift;
	my $date = shift;

	return unless $date;

	my ($mm, $dd, $yy) = split(/\//, $date);
	$mm = '0' . $mm if length $mm == 1;
	$dd = '0' . $dd if length $dd == 1;

	return "$yy-$mm-$dd";
	}

sub get_db_format_date_time
	{
	my $self = shift;
	my $datetime = shift;

	return unless $datetime;

	$datetime =~ s/%2F/\//g if $datetime =~ /%2F/;

	my ($date, $time) = split(/\ |T/, $datetime) if $datetime =~ /(\ |T)/;
	$date = $datetime unless $date;

	my ($mm, $dd, $yy) = split(/\//, $date);
	$mm = '0' . $mm if length $mm == 1;
	$dd = '0' . $dd if length $dd == 1;

	$time = $self->current_time unless $time;
        my $returnVal = "$yy-$mm-$dd $time";
        $date = undef;
        $time = undef;
	return $returnVal;
	}

sub get_db_format_date_time_with_timezone
	{
	my $self = shift;
	my $datetime = shift;

	return unless $datetime;

	$datetime =~ s/%2F/\//g if $datetime =~ /%2F/;

	my ($date, $time) = split(/\ |T/, $datetime) if $datetime =~ /(\ |T)/;
	$date = $datetime unless $date;

	my ($mm, $dd, $yy) = split(/\//, $date);
	$mm = '0' . $mm if length $mm == 1;
	$dd = '0' . $dd if length $dd == 1;

	my ($seconds, $microseconds) = gettimeofday;
	my $timezone = Timezone();

	$time = $self->current_time unless $time;
	my $returnVal = "$yy-$mm-$dd $time.$microseconds-$timezone";

	$date = undef;
	$time = undef;

	return $returnVal;
	}

=head2 timestamp

	my $timestamp = IntelliShip::DateUtils->timestamp;
	print $timestamp; # 20081231125959

=cut

sub timestamp
	{
	my $self	= shift;
	my $epoch	= shift;
	my @time;

	if (!$epoch)
		{
		@time = localtime;
		}
	else
		{
		@time = localtime($epoch);
		}

	$time[4] += 1;

	$time[0] = "0" . $time[0] if ($time[0] < 10);
	$time[1] = "0" . $time[1] if ($time[1] < 10);
	$time[2] = "0" . $time[2] if ($time[2] < 10);
	$time[3] = "0" . $time[3] if ($time[3] < 10);
	$time[4] = "0" . $time[4] if ($time[4] < 10);
	$time[5] = $time[5] + 1900;

	my $date = $time[5] . $time[4] . $time[3] . $time[2] . $time[1] . $time[0];

	return $date;
	}

sub get_timestamp_with_time_zone
	{
	my $self = shift;
	my $timestamp = IntelliShip::DateUtils->timestamp;

	my ($year, $month, $day, $hours, $min, $sec);

	$year	= substr($timestamp, 0, 4);
	$month	= substr($timestamp, 4, 2);
	$day	= substr($timestamp, 6, 2);
	$hours	= substr($timestamp, 8, 2);
	$min	= substr($timestamp, 10, 2);
	$sec	= substr($timestamp, 12, 2);

	my ($seconds, $microseconds) = gettimeofday;
	my $timezone = Timezone();

	$timestamp = $year.'-'.$month.'-'.$day.' '.$hours.':'.$min.':'.$sec.'.'.$microseconds.'-'.$timezone;

	return $timestamp;
	}

=head2 get_formatted_timestamp

	my $formatted_timestamp = IntelliShip::DateUtils->get_formatted_timestamp;
	print $formatted_timestamp; # 2008/12/31 24:59:59

	my $formatted_timestamp = IntelliShip::DateUtils->get_formatted_timestamp('-');
	print $formatted_timestamp; # 2008-12-31 24:59:59

=cut

sub get_formatted_timestamp
	{
	my $self = shift;
	my $separator = shift;

	$separator = "-" unless ($separator eq '/');

	my $timestamp = IntelliShip::DateUtils->timestamp;

	my ($year, $month, $day, $hours, $min, $sec);

	$year	= substr($timestamp, 0, 4);
	$month	= substr($timestamp, 4, 2);
	$day	= substr($timestamp, 6, 2);
	$hours	= substr($timestamp, 8, 2);
	$min	= substr($timestamp, 10, 2);
	$sec	= substr($timestamp, 12, 2);

	$timestamp = "$year$separator$month$separator$day $hours:$min:$sec" if $separator;

	return $timestamp;
	}

sub display_timestamp
	{
	my $self      = shift;
	my $timestamp = shift;

	return undef unless $timestamp;

	my ($year, $month, $day, $hours, $min, $sec);

	$year  = substr($timestamp, 0,  4);
	$month = substr($timestamp, 4,  2);
	$day   = substr($timestamp, 6,  2);
	$hours = substr($timestamp, 8,  2);
	$min   = substr($timestamp, 10, 2);
	$sec   = substr($timestamp, 12, 2);

	return "$month/$day/$year $hours:$min:$sec";
	}

sub format_to_yyyymmdd
	{
	my $self = shift;
	my $date = shift;

	($date,my $time) = split(/$&/, $date) if $date =~ /(\ |T)/;

	my ($yy,$mm,$dd) = split(/\-/, $date) if $date =~ /\-/;
	   ($mm,$dd,$yy) = split(/\//, $date) if $date =~ /\//;

	return $yy . $mm . $dd;
	}

sub format_to_mmddyy
	{
	my $self = shift;
	my $date = shift;

	($date,my $time) = split(/$&/, $date) if $date =~ /(\ |T)/;

	my ($yy,$mm,$dd) = split(/\-/, $date) if $date =~ /\-/;
	   ($mm,$dd,$yy) = split(/\//, $date) if $date =~ /\//;

	return $mm . '/' . $dd . '/' . substr($yy,-2);
	}

sub get_delta_days
	{
	my $self = shift;
	my $date1 = shift;
	my $date2 = shift || $self->current_date;

	if ($date1 =~ /(\ |T)/g) ## 0000-00-00T00:00:00
		{
		my ($date, $time) = split($&, $date1);
		$date1 = $date;
		}

	my ($d1yy, $d1mm, $d1dd) = $self->parse_date($date1);
	my ($d2yy, $d2mm, $d2dd) = $self->parse_date($date2);

	return 0 unless check_date($d1yy, $d1mm, $d1dd);
	return 0 unless check_date($d2yy, $d2mm, $d2dd);

	return Delta_Days($d1yy, $d1mm, $d1dd, $d2yy, $d2mm, $d2dd);
	}
=as
sub get_delta_YMD_from_this_date
	{
	my $self = shift;
	my $dateIs = shift; ## 0000-00-00

	if ($dateIs =~ /\:/g) ## 0000-00-00 00:00:00
		{
		my ($date,$time) = split(/\ /,$dateIs);
		$dateIs = $date ;
		}

	my ($dyy, $dmm, $ddd) = split(/-/, $dateIs);

	return 0 unless ( check_date($dyy, $dmm, $ddd) );

	my $cdate = IntelliShip::DateUtils->current_date;
	my ($cyy, $cmm, $cdd) = split(/\//, $cdate);

	return N_Delta_YMD($cyy, $cmm, $cdd, $dyy, $dmm, $ddd);
	}
=cut
sub get_date_delta_days_from_given_date
	{
	my $self = shift;
	my $cdate = shift;
	my $delta = shift;
	my $separator = shift;

	$separator = "/" if (!$separator);

	$cdate = $self->current_date($separator) unless $cdate;

	my ($cyy, $cmm,$cdd);
	($cmm, $cdd,$cyy) = split(/\//, $cdate) if $separator eq '/';
	($cyy, $cmm,$cdd) = split(/\-/, $cdate) if $separator eq '-';

	my ($nyy, $nmm, $ndd) = Add_Delta_Days($cyy, $cmm, $cdd, $delta);
	$nmm = "0" . $nmm if (length($nmm) == 1);
	$ndd = "0" . $ndd if (length($ndd) == 1);
	my $new_date = $nyy . $separator . $nmm . $separator . $ndd;

	return $new_date;
	}

=head2 get_delta_from_timestamps

	my ($Dd,$Dh,$Dm,$Ds) = IntelliShip::DateUtils->get_delta_from_timestamps;

=cut

sub get_delta_from_timestamps
	{
	my $self = shift;
	my $stamp1 = shift;
	my $stamp2 = shift;

	$stamp1 =~ s/[\-\s\:]+//g;
	$stamp2 =~ s/[\-\s\:]+//g;

	my ($year1,$year2,$month1,$month2,$day1,$day2,$hour1,$hour2,$min1,$min2,$sec1,$sec2);

	$year1	= substr($stamp1,  0, 4);
	$month1	= substr($stamp1,  4, 2);
	$day1	= substr($stamp1,  6, 2);
	$hour1	= substr($stamp1,  8, 2);
	$min1	= substr($stamp1, 10, 2);
	$sec1	= substr($stamp1, 12, 2);

	$year2	= substr($stamp2,  0, 4);
	$month2	= substr($stamp2,  4, 2);
	$day2	= substr($stamp2,  6, 2);
	$hour2	= substr($stamp2,  8, 2);
	$min2	= substr($stamp2, 10, 2);
	$sec2	= substr($stamp2, 12, 2);

	return 0 unless check_date($year1, $month1, $day1);
	return 0 unless check_date($year2, $month2, $day2);

	return Delta_DHMS($year1,$month1,$day1, $hour1,$min1,$sec1,$year2,$month2,$day2, $hour2,$min2,$sec2); #($Dd,$Dh,$Dm,$Ds)
	}

sub get_timestamp_delta_HMS_from_now
	{
	my $self		= shift;
	my $add_hour	= shift;
	my $add_minutes	= shift;
	my $add_seconds	= shift;
	my $option		= shift;
	my @time		= localtime;

	$time[4] += 1;

	$time[0] = "0" . $time[0] if ($time[0] < 10);
	$time[1] = "0" . $time[1] if ($time[1] < 10);
	$time[2] = "0" . $time[2] if ($time[2] < 10);
	$time[3] = "0" . $time[3] if ($time[3] < 10);
	$time[4] = "0" . $time[4] if ($time[4] < 10);
	$time[5] = $time[5] + 1900;

	my ($yy, $mm, $dd, $hh, $mi, $ss);

	($yy, $mm, $dd, $hh, $mi, $ss) = Add_Delta_DHMS($time[5], $time[4], $time[3], $time[2], $time[1], $time[0], 0, $add_hour, $add_minutes, $add_seconds);

	$mm = "0" . $mm if (length($mm) == 1);
	$dd = "0" . $dd if (length($dd) == 1);
	$hh = "0" . $hh if (length($hh) == 1);
	$mi = "0" . $mi if (length($mi) == 1);
	$ss = "0" . $ss if (length($ss) == 1);

	if ($option eq 'AS_TIMESTAMP')
		{
		return "$yy$mm$dd$hh$mi$ss";
		}

	return "$yy-$mm-$dd $hh:$mi:$ss";
	}

sub get_timestamp_delta_HMS_from_given_datetime
	{
	my $self		= shift;
	my $date_time	= shift;
	my $add_hour	= shift;
	my $add_minute	= shift;
	my $add_seconds	= shift;
	my $option		= shift;

	$date_time =~ s/\D//g;

	my $date = substr($date_time,0,8);
	my $time = substr($date_time,0,6);

	my ($yy, $mm, $dd, $hh, $mi, $ss);
	$yy = substr($date_time,0,4);
	$mm = substr($date_time,4,2);
	$dd = substr($date_time,6,2);
	$hh = substr($date_time,8,2);
	$mi = substr($date_time,10,2);
	$ss = substr($date_time,12,2);

	($yy, $mm, $dd, $hh, $mi, $ss) = Add_Delta_DHMS($yy, $mm, $dd, $hh, $mi, $ss, 0, $add_hour, $add_minute, $add_seconds);

	$mm = "0" . $mm if (length($mm) == 1);
	$dd = "0" . $dd if (length($dd) == 1);
	$hh = "0" . $hh if (length($hh) == 1);
	$mi = "0" . $mi if (length($mi) == 1);
	$ss = "0" . $ss if (length($ss) == 1);

	if ($option eq 'AS_TIMESTAMP')
		{
		return "$yy$mm$dd$hh$mi$ss";
		}

	return "$yy-$mm-$dd $hh:$mi:$ss";
	}

sub get_timestamp_delta_days_from_now
	{
	my $self	= shift;
	my $adddays	= shift;
	my $option	= shift || '';
	my @time	= localtime;

	$time[4] += 1;

	$time[0] = "0" . $time[0] if ($time[0] < 10);
	$time[1] = "0" . $time[1] if ($time[1] < 10);
	$time[2] = "0" . $time[2] if ($time[2] < 10);
	$time[3] = "0" . $time[3] if ($time[3] < 10);
	$time[4] = "0" . $time[4] if ($time[4] < 10);
	$time[5] = $time[5] + 1900;

	my ($yy, $mm, $dd, $hh, $mi, $ss) = Add_Delta_DHMS($time[5], $time[4], $time[3], $time[2], $time[1], $time[0], $adddays, 0, 0, 0);

	$mm = "0" . $mm if (length($mm) == 1);
	$dd = "0" . $dd if (length($dd) == 1);
	$hh = "0" . $hh if (length($hh) == 1);
	$mi = "0" . $mi if (length($mi) == 1);
	$ss = "0" . $ss if (length($ss) == 1);

	if ($option eq 'AS_TIMESTAMP')
		{
		return "$yy$mm$dd$hh$mi$ss";
		}

	return "$yy-$mm-$dd $hh:$mi:$ss";
	}

sub get_timestamp_delta_months_from_now
	{
	my $self		= shift;
	my $addmonths	= shift;
	my $option		= shift;
	my @time		= localtime;

	$time[4] += 1;

	$time[0] = "0" . $time[0] if ($time[0] < 10);
	$time[1] = "0" . $time[1] if ($time[1] < 10);
	$time[2] = "0" . $time[2] if ($time[2] < 10);
	$time[3] = "0" . $time[3] if ($time[3] < 10);
	$time[4] = "0" . $time[4] if ($time[4] < 10);
	$time[5] = $time[5] + 1900;

	my ($yy, $mm, $dd, $hh, $mi, $ss) = Add_Delta_YMDHMS($time[5], $time[4], $time[3], $time[2], $time[1], $time[0], 0, $addmonths, 0, 0, 0, 0);

	$mm = "0" . $mm if (length($mm) == 1);
	$dd = "0" . $dd if (length($dd) == 1);
	$hh = "0" . $hh if (length($hh) == 1);
	$mi = "0" . $mi if (length($mi) == 1);
	$ss = "0" . $ss if (length($ss) == 1);

	if ($option eq 'AS_TIMESTAMP')
		{
		return "$yy$mm$dd$hh$mi$ss";
		}

	return "$yy-$mm-$dd $hh:$mi:$ss";
	}

sub is_valid_date
	{
	my $self = shift;
	my $dateIs = shift;

	if ($dateIs =~ /(\ |T)/g) ## 0000-00-00T00:00:00
		{
		my ($date, $time) = split($&, $dateIs);
		$dateIs = $date;
		}

	my ($dyy, $dmm, $ddd);
	($dyy, $dmm, $ddd) = split(/-/, $dateIs) if $dateIs =~ /-/;
	($dmm, $ddd, $dyy) = split(/-/, $dateIs) if $dateIs =~ /\//;

	return check_date($dyy, $dmm, $ddd);
	}

=head2 get_day_of_week

	Get day of week for a given date or for current date if not specified. Value returned is 1-7 for Monday-Sunday.

	my $day_of_week = IntelliShip::DateUtils->get_day_of_week;

=cut

sub get_day_of_week
	{
	my $self = shift;
	my $date = shift;

	$date = $self->current_date('-') unless $date;
	$date =~ s/\D//g;

	my $yy = substr($date, 0, 4);
	my $mm = substr($date, 4, 2);
	my $dd = substr($date, 6, 2);

	return Day_of_Week($yy,$mm,$dd);
	}

sub get_future_business_date
	{
	my $self = shift;
	my ($start_date, $offset_days, $include_saturday, $include_sunday) = @_;

	my $parsed_start_date = ParseDate($start_date);
	my $normalized_start_date = UnixDate($parsed_start_date, "%Q");
	my $stop_date;

	# If no offset is given, return 'today' if it's a weekday, or the following business
	# day if it's a weekend or holiday
	my $DOW = UnixDate($parsed_start_date, "%a");

	if (length $offset_days == 0 and $DOW =~ m/(Sat|Sun)/i)
		{
		$offset_days = 1;
		}

	# One or both weekend days included
	if ( $include_saturday or $include_sunday )
		{
		$stop_date = new Date::Business(
			DATE     => $normalized_start_date,
			HOLIDAY  => \&Holiday
			);

		for ( my $i = 1; $i < ($offset_days + 1); $i ++ )
			{
			$stop_date->next();

			if ( $stop_date->day_of_week() == 6 and !$include_saturday )
				{
				$stop_date->next();
				}

			if ( $stop_date->day_of_week() == 0 and !$include_sunday )
				{
				$stop_date->next();
				}
			}
		}
	else # Normal
		{
		$stop_date = new Date::Business(
			DATE     => $normalized_start_date,
			OFFSET   => $offset_days,
			HOLIDAY  => \&Holiday
			);
		}

	$stop_date = $stop_date->image();
	$stop_date =~ s/(\d{4})(\d{2})(\d{2})/$2\/$3\/$1/;

	return $stop_date;
	}

sub Holiday
	{
	my $self = shift;
	my ($start, $end) = @_;
	my $year = (localtime)[5] + 1900;

	my ($numHolidays) = 0;
	my ($holiday, @holidays);

	my $Profiles = {};
	## United States of America - Shipping holidays
	$Profiles->{'US-Shipping'} = {
		"New Year's Day"	=> "1/1",
		"Memorial Day"		=> "5/Mon/May",
		"Independence Day"	=> "7/4",
		"Labor Day"			=> "1/Mon/Sep",
		"Thanksgiving Day"	=> "4/Thu/Nov",
		"Christmas Day"		=> "12/25",
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

			my $check_date = new Date::Business(DATE => $date);
			if ( $check_date != 0 and $check_date != 6 )
				{
				push(@holidays,$date);
				}
			}
		}

	foreach $holiday (@holidays)
		{
		$numHolidays++ if ($start le $holiday and $end ge $holiday);
		}

	return $numHolidays;
	}

sub get_business_days_between_two_dates
	{
	my $self = shift;
	my ($date1,$date2) = @_;

	my $d1 = $self->format_to_yyyymmdd($date1);
	my $d2 = $self->format_to_yyyymmdd($date2);

	#print STDERR "\n d1: " . $d1;
	#print STDERR "\n d2: " . $d2;

	my $day1 = new Date::Business( DATE => $d1 );
	my $day2 = new Date::Business( DATE => $d2 );

	my $days_diff = $day1->diffb($day2);

	my $holidays = $self->Holiday($d2,$d1);

	return ($days_diff-$holidays);
	}

sub parse_date
	{
	my $self = shift;
	my $dateStr = shift;
	$dateStr = ParseDate($dateStr);
	return (substr($dateStr,0,4), substr($dateStr,4,2), substr($dateStr,6,2), substr($dateStr,9,2), substr($dateStr,12,2), substr($dateStr,15,2));
	}

__PACKAGE__->meta()->make_immutable();

no Moose;

1;

__END__