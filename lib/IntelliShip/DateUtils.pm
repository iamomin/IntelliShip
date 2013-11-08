package IntelliShip::DateUtils;

use strict;
use DateTime;
use Date::Calc qw(check_date Delta_Days Add_Delta_Days Delta_DHMS Add_Delta_DHMS Day_of_Week N_Delta_YMD Add_Delta_YMDHMS Timezone);

=head1 NAME

IntelliShip::DateUtils

=head1 SYNOPSIS

Collection of subroutines to manipulate date/time information.

=head1 METHODS

List below are the subroutines available.

=cut

=head2 american_date

	my $american_date = IntelliShip::DateUtils->american_date('2007-05-01');
	print $american_date; # 05/01/2007

	my $american_date = IntelliShip::DateUtils->american_date('2007/05/01');
	print $american_date; # 05/01/2007

=cut

sub american_date
	{
	my $self	= shift;
	my $date	= shift;
	my $split;

	$split = "-" if ($date =~ /-/);
	$split = "\/" if ($date =~ /\//);

	my ($yy, $mm, $dd) = split(/$split/, $date);

	return "$mm/$dd/$yy";
	}

=head2 current_date

	my $date = IntelliShip::DateUtils->current_date;
	print $date; $ 2008/12/31

	my $date = IntelliShip::DateUtils->current_date('-');
	print $date; $ 2008-12-31

=cut

sub current_date
	{
	my $self	= shift;
	my $separator = shift;

	$separator = "/" if (!$separator);

	my @tm		= localtime;
	my ($tm, $date);

	$tm[4] += 1;

	$tm[3] = "0" . $tm[3] if ($tm[3] < 10);
	$tm[4] = "0" . $tm[4] if ($tm[4] < 10);

	$tm[5] = $tm[5] + 1900;
	$date = $tm[5] . $separator . $tm[4] . $separator . $tm[3];

	return ($date);
	}

sub get_db_format_date_time
	{
	my $self = shift;
	my $datetime = shift;

	my ($date, $time) = split(/\ /, $datetime);
	my ($mm, $dd, $yy) = split(/\//, $date);
	$mm = '0' . $mm if (length($mm) == 1);
	$dd = '0' . $dd if (length($dd) == 1);

	$datetime = "$yy-$mm-$dd $time";

	return $datetime;
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

	my $microsecond = '952674';
	my $timezone = Timezone();

	$timestamp = $year.'-'.$month.'-'.$day.' '.$hours.':'.$min.':'.$sec.'.'.$microsecond.'-'.$timezone;

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

	$timestamp = "$year$separator$month$separator$day $hours:$min:$sec" if($separator);

	return $timestamp;
	}

=head2 get_delta_days_from_this_date

Get delta days from a given date and the current date.  Given date can be in the future or past.  Value returned is
positive if given date is in the future, the value is negative if given date is in the past.

=cut

sub get_delta_days_from_this_date
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

	return Delta_Days($cyy, $cmm, $cdd, $dyy, $dmm, $ddd);
	}

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

sub get_date_delta_days_from_given_date
	{
	my $self = shift;
	my $cdate = shift;
	my $delta = shift;
	my $separator = shift;

	$separator = "/" if (!$separator);

	$cdate = $self->current_date($separator) unless($cdate);

	my ($cyy, $cmm,$cdd);
	($cyy, $cmm,$cdd) = split(/\//, $cdate) if($separator eq '/');
	($cyy, $cmm,$cdd) = split(/\-/, $cdate) if($separator eq '-');

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
	my $self		= shift;
	my $adddays		= shift;
	my $option		= shift;
	my @time		= localtime;

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

	if ($dateIs =~ /\:/g) ## 0000-00-00 00:00:00
		{
		my ($date,$time) = split(/\ /,$dateIs);
		$dateIs = $date;
		}

	my ($dyy, $dmm, $ddd) = split(/-/, $dateIs);

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

1;

__END__