#!/usr/bin/perl -w

#==========================================================
#   Project:	ARRS
#
#   Filename:	SERVICE.pm
#
#   Date:		04/25/2002
#
#   Purpose:	Service Handling
#
#   Company:	Engage TMS
#
#   Author(s):	Kirk Aksdal
#					Leigh Bohannon
#
#==========================================================

{
	package ARRS::SERVICE;

	use strict;
	use ARRS::DBOBJECT;
	@ARRS::SERVICE::ISA = ("ARRS::DBOBJECT");

	use ARRS::COMMON;
	use ARRS::CUSTOMERSERVICE;

	sub new
	{
		my $proto = shift;
		my $class = ref($proto) || $proto;

		my $self = $class->SUPER::new(@_);

		$self->{'object_tablename'} = 'service';
		$self->{'object_primarykey'} = 'serviceid';
		$self->{'object_fieldlist'}=['serviceid','carrierid','servicename','webname','webhandlername','international','heavy','webname2','servicecode','fscrate','dimfactor','decvalinsrate','decvalinsmin','decvalinsmax','decvalinsmincharge','freightinsrate','freightinsincrement','decvalinsmaxperlb','carrieremail','pickuprequest','servicetypeid','allowcod','valuedependentrate','codfee','collectfreightcharge','guaranteeddelivery','saturdaysunday','liftgateservice','podservice','constructionsite','insidepickupdelivery','singleshipment','thirdpartyacct','aggregateweightcost','callforappointment','discountpercent','extservicecode','serviceicon','weekendupcharge','amc','sattransit','suntransit','maxtruckweight','alwaysshow','modetypeid','defaultzonetypeid','timeneededmin','timeneededmax'];

		bless($self, $class);
		return $self;
	}

	sub GetZoneTypeDropDown
	{
		my $self = shift;

		return $self->{'dbref'}->getdropdownref("
			SELECT
				typeid,
				zonetypename
			FROM
				zonetype
			WHERE
				serviceid='".$self->{'serviceid'}."' order by zonetypename
		");
	}

	sub GetRateTypeDropDown
	{
		my $self = shift;

		return $self->{'dbref'}->getdropdownref("
			SELECT
				typeid,
				ratetypename
			FROM
				ratetype
			WHERE
				serviceid='".$self->{'serviceid'}."' order by ratetypename
		");
	}
}

1;
