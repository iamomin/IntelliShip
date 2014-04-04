package IntelliShip::Carrier::EPLTemplates;

use Moose;

sub get_UPS_EPL
	{
	my $self = shift;
	my $DATA = shift;

	my $EPL = <<END;
.

OD
JF
Q1370,24
q812
R5,140
S8
D15
N
ZB

LO10,10,800,2
LO10,10,2,1210
LO810,10,2,1210
LO10,1220,800,2

LO10,377,800,2
LO265,377,2,234
LO10,611,800,10
LO10,749,800,2
A452,20,0,4,1,1,N,"$DATA->{'displayweight'}   $DATA->{'currentpiece'} OF $DATA->{'totalquantity'}"
A40,20,0,2,1,1,N,"$DATA->{'shipasname'}"
A40,42,0,2,1,1,N,"$DATA->{'branchcontact'}"
A40,64,0,2,1,1,N,"$DATA->{'branchphone'}"
A470,64,0,2,1,1,N,"SHP #: $DATA->{'shipmentnumber'}"
A40,86,0,2,1,1,N,"$DATA->{'branchaddress1'}"
A470,86,0,2,1,1,N,"SHP WT: $DATA->{'displayweight'}"
A40,108,0,2,1,1,N,"$DATA->{'branchaddress2'}"
A470,108,0,2,1,1,N,"SHP DWT: $DATA->{'dimweight'}"
A40,130,0,2,1,1,N,"$DATA->{'branchaddresscity'} $DATA->{'branchaddressstate'} $DATA->{'branchaddresszip'}"
A470,130,0,2,1,1,N,"DATE:  $DATA->{'shipdate'}"

A40,170,0,1,2,2,N,"SHIP"
A40,196,0,1,2,2,N,"TO:"

A125,172,0,4,1,1,N,"$DATA->{'shiptoname'}"
A125,198,0,4,1,1,N,"$DATA->{'contactphone'}"
A125,224,0,4,1,1,N,"$DATA->{'shiptocompany'}"
A125,250,0,4,1,1,N,"$DATA->{'address1'}"
A125,276,0,4,1,1,N,"$DATA->{'address2'}"
A125,302,0,3,2,2,N,"$DATA->{'addresscity'} $DATA->{'addressstate'} $DATA->{'addresszip'}"

A350,390,0,4,2,3,N,"$DATA->{'routingcode'}"
B320,474,0,1,3,8,110,N,"$DATA->{'barcodezip'}"
A375,575,0,4,1,1,N,""
A30,640,0,3,2,2,N,"UPS $DATA->{'servicename'}"
A20,720,0,4,1,1,N,"TRACKING #: $DATA->{'spacedtracking1'}"
B120,770,0,1,3,8,200,N,"$DATA->{'tracking1'}"
LO10,1000,800,10
A40,1020,0,2,1,1,N,"BILLING: $DATA->{'billingtype'}"
A40,1040,0,2,1,1,N,"DESC: $DATA->{'productdescr'}"
A40,1060,0,2,1,1,N,"$DATA->{'asslist'}"
A40,1080,0,2,1,1,N,"$DATA->{'dryice'}"
A40,1105,0,2,1,1,N,"Ref: $DATA->{'refnumber'}"
A40,1125,0,2,1,1,N,"PO: $DATA->{'ponumber'}"
A450,1105,0,2,1,1,N,"DIMS: $DATA->{'dims'}"
A450,1125,0,2,1,1,N,"Density: $DATA->{'density'}"
A40,1148,0,3,1,1,N,"Comments: $DATA->{'comments'}"
A45,1185,0,1,1,1,N,"Powered by Intelliship(tm)"
A45,1205,0,1,1,1,N,"$DATA->{'footer_datetime'}"
A670,1205,0,1,1,1,N,"$DATA->{'routingversion'}"
b30,390,M,m2,"$DATA->{'servicecode'},$DATA->{'isocountry'},$DATA->{'maxicode_zip5'},$DATA->{'maxicode_zip4'},[)>0196$DATA->{'maxicode_tracking1'}UPSN$DATA->{'webaccount'}$DATA->{'julianpickup'}$DATA->{'currentpiece'}/$DATA->{'totalquantity'}$DATA->{'maxi_weight'}N$DATA->{'maxicity'}$DATA->{'iso2state'}"
END

	return $EPL;
	}

sub get_GENERIC_EPL
	{
	my $self = shift;
	my $DATA = shift;

	my $EPL = <<END;
.

OD
JF
Q1370,24
q812
R5,140
S8
D15
N
ZB
LO5,10,805,2
LO5,10,2,1410
LO810,10,2,1410
LO5,1380,805,2

A220,20,0,3,2,2,R,""
LO10,80,800,2
A25,100,0,3,1,1,N,"From:"
A150,100,0,2,1,1,N,"$DATA->{'shipasname'}"
A150,125,0,2,1,1,N,"$DATA->{'branchaddress1'}"
A150,150,0,2,1,1,N,"$DATA->{'branchaddress2'}"
A150,175,0,2,1,1,N,"$DATA->{'branchaddresscity'} $DATA->{'branchaddressstate'} $DATA->{'branchaddresszip'}"
A150,200,0,2,1,1,N,"$DATA->{'branchaddresscountry'}"
A515,100,0,2,1,1,N,"$DATA->{'branchcontact'}"
A515,125,0,2,1,1,N,"$DATA->{'branchphone'}"
A515,150,0,2,1,1,N,"Ref: $DATA->{'refnumber'}"
A515,175,0,2,1,1,N,"Ship Date: $DATA->{'shipdate'}"
A515,200,0,2,1,1,N,"Airport Code: $DATA->{'branchairportcode'}"
LO10,230,800,2
A25,250,0,3,1,1,N,"To:"
A150,250,0,2,1,1,N,"$DATA->{'addressname'}"
A150,275,0,2,1,1,N,"$DATA->{'address1'}"
A150,300,0,2,1,1,N,"$DATA->{'address2'}"
A150,325,0,2,1,1,N,"$DATA->{'addresscity'}, $DATA->{'addressstate'} $DATA->{'addresszip'}"
A150,350,0,2,1,1,N,"$DATA->{'addresscountry'}"
A515,250,0,2,1,1,N,"$DATA->{'contactname'}"
A515,275,0,2,1,1,N,"$DATA->{'contactphone'}"
A515,300,0,2,1,1,N,"PO: $DATA->{'ponumber'}"
A515,325,0,2,1,1,N,"ETA: $DATA->{'datedue'}"
A515,350,0,2,1,1,N,"Airport Code: $DATA->{'airportcode'}"
LO10,380,800,2
A515,400,0,2,1,1,N,"Weight: $DATA->{'weight'} Lbs"
A515,425,0,2,1,1,N,"DIM Weight: $DATA->{'dimweight'}"
A515,450,0,2,1,1,N,"DIMS: $DATA->{'dims'}"
A515,475,0,2,1,1,N,"Density: $DATA->{'density'}"
A515,500,0,2,1,1,N,"Packages: $DATA->{'totalquantity'}"
A515,525,0,2,1,1,N,"Zone: $DATA->{'zonenumber'}"
A515,550,0,2,1,1,N,"Tracking: $DATA->{'tracking1'}"
LO10,580,800,2
A25,600,0,3,1,1,N,"Description:"
A215,600,0,2,1,1,N,"$DATA->{'extcd'}"
A25,640,0,3,1,1,N,"Comments:"
A215,640,0,2,1,1,N,"$DATA->{'comments'}"
LO10,670,800,2
A25,690,0,3,2,2,R,"$DATA->{'carrier'}"
A515,690,0,3,2,2,N,"$DATA->{'hazardstring'}"
A25,750,0,3,2,2,R,"$DATA->{'service'}"
B50,810,0,3C,3,7,150,N,"$DATA->{'tracking1'}"
A350,980,0,3,1,1,N,"$DATA->{'tracking1'}"
A25,1015,0,3,1,1,R,"$DATA->{'labelbanner'}"

A25,400,0,3,1,1,N,"Bill To:"
A150,400,0,2,1,1,N,"$DATA->{'billingaddressname'}"
A150,425,0,2,1,1,N,"$DATA->{'billingaddress1'}"
A150,450,0,2,1,1,N,"$DATA->{'billingaddress1'}"
A150,475,0,2,1,1,N,"$DATA->{'billingcity'}, $DATA->{'billingstate'}  $DATA->{'billingzip'}"
A150,500,0,2,1,1,N,"$DATA->{'billingcountry'}"

A25,1255,0,3,1,1,N,"Pro#:"
A25,1280,0,3,1,1,N,"Carrier:"
A25,1305,0,3,1,1,N,"Service:"
A25,1330,0,3,1,1,N,"Origin:"
A25,1355,0,3,1,1,N,"Dest:"
A150,1255,0,3,1,1,N,"$DATA->{'tracking1'}"
A150,1280,0,3,1,1,N,"$DATA->{'carrier'}"
A150,1305,0,3,1,1,N,"$DATA->{'service'}"
A150,1330,0,3,1,1,N,"$DATA->{'branchaddressstate'} $DATA->{'branchaddresszip'}"
A150,1355,0,3,1,1,N,"$DATA->{'addressstate'} $DATA->{'addresszip'}"

A410,1255,0,3,1,1,N,"Customer Number"
A410,1280,0,3,1,1,N,"Consignee:"
A410,1305,0,3,1,1,N,"Zone:"
A410,1330,0,3,1,1,N,"Quantity:"
A410,1355,0,3,1,1,N,"Est Charge:"

A570,1255,0,3,1,1,N,"$DATA->{'truncd_custnum'}"
A570,1280,0,3,1,1,N,"$DATA->{'truncd_addressname'}"
A570,1305,0,3,1,1,N,"$DATA->{'zonenumber'}"
A570,1330,0,3,1,1,N,"$DATA->{'quantitydisplay'}"
A570,1355,0,3,1,1,N,"$DATA->{'chargeamount'}"
P1
R0,0
.
END

	}

sub get_USPS_EPL_1
	{
	my $self = shift;
	my $DATA = shift;

	my $EPL = <<END;
.

N
OD10
Q1218,24
q812
D13
ZB
LO10,80,790,2
LO205,80,2,150
LO10,80,2,1042
LO800,80,2,1042
A60,110,0,5,3,2,N,"F"
LO10,230,790,2
A15,240,0,5,1,1,N,"USPS FIRST-CLASS MAIL"
A750,240,0,4,1,1,N,"®"
LO10,300,790,2
A25,330,0,2,1,1,N,"$DATA->{FromName}"
A25,350,0,2,1,1,N,"$DATA->{'customername'} "
A25,370,0,2,1,1,N,"$DATA->{'branchaddress2'}"
A25,390,0,2,1,1,N,"$DATA->{'branchaddress2'}"
A25,410,0,2,1,1,N,"$DATA->{'branchaddresscity'}, $DATA->{'branchaddressstate'} $DATA->{'branchaddresszip'}"
A100,510,0,3,1,1,N,"$DATA->{'contactname'}"
A100,530,0,3,1,1,N,"$DATA->{'addressname'}"
A100,550,0,3,1,1,N,"$DATA->{'address1'}"
A100,570,0,3,1,1,N,"$DATA->{'address2'}"
A100,590,0,3,1,1,N,"$DATA->{'addresscity'}, $DATA->{'addressstate'} $DATA->{'addresszip'}"
A550,330,0,2,1,1,N,"Ship Date:$DATA->{'datetoship'}"
A630,350,0,2,1,1,N,"Weight: $DATA->{'weightinounces'} oz"
A710,370,0,1,2,2,N,"$DATA->{'RDC'}"
LO590,430,1,40
LO500,430,1,40
LO500,430,90,1
LO500,470,90,1
A510,440,0,1,2,2,N,"$DATA->{'CarrierRoute'}"
LO10,700,790,10
A190,740,0,3,2,2,N,"USPS TRACKING #"
B80,790,0,1E,3,7,150,N,"$DATA->{'barcodedata'}"
A220,970,0,3,1,1,N,"$DATA->{'tracking1'}"
LO10,1020,790,10
A120,1070,0,4,1,1,N,"Electronic Rate Approved # $DATA->{'ElectronicRateApproved'}"
LO10,1120,790,4
P1
N
R0,0
.
END

	return $EPL;
	}

sub get_USPS_EPL_2
	{
	my $self = shift;
	my $DATA = shift;

	my $EPL = <<END;
.

N
OD10
Q1218,24
q812
D13
ZB
LO10,80,790,2
LO205,80,2,150
LO10,80,195,150
LO10,80,2,1042
LO800,80,2,1042
LO10,230,790,2
A90,240,0,5,1,1,N,"USPS STANDARD POST"
LO10,300,790,2
A25,330,0,2,1,1,N,"$DATA->{FromName}"
A25,350,0,2,1,1,N,"$DATA->{'customername'} "
A25,370,0,2,1,1,N,"$DATA->{'branchaddress1'}"
A25,390,0,2,1,1,N,"$DATA->{'branchaddress2'}"
A25,410,0,2,1,1,N,"$DATA->{'branchaddresscity'}, $DATA->{'branchaddressstate'} $DATA->{'branchaddresszip'}"
A100,510,0,3,1,1,N,"$DATA->{'contactname'}"
A100,530,0,3,1,1,N,"$DATA->{'addressname'}"
A100,550,0,3,1,1,N,"$DATA->{'address1'}"
A100,570,0,3,1,1,N,"$DATA->{'address2'}"
A100,590,0,3,1,1,N,"$DATA->{'addresscity'}, $DATA->{'addressstate'} $DATA->{'addresszip'}"
A550,330,0,2,1,1,N,"Ship Date:$DATA->{'datetoship'}"
A630,350,0,2,1,1,N,"Weight: $DATA->{'weightinounces'} oz"
A710,370,0,1,2,2,N,"$DATA->{'RDC'}"
LO590,430,1,40
LO500,430,1,40
LO500,430,90,1
LO500,470,90,1
A510,440,0,1,2,2,N,"$DATA->{'CarrierRoute'}"
LO10,700,790,10
A190,740,0,3,2,2,N,"USPS TRACKING #"
B80,790,0,1E,3,7,150,N,"$DATA->{'barcodedata'}"
A220,970,0,3,1,1,N,"$DATA->{'tracking1'}"
LO10,1020,790,10
A120,1070,0,4,1,1,N,"Electronic Rate Approved # $DATA->{'ElectronicRateApproved'} "
LO10,1120,790,4
P1
N
R0,0
.
END

	return $EPL;
	}

sub get_USPS_EPL_3
	{
	my $self = shift;
	my $DATA = shift;

	my $EPL = <<END;
.

N
OD10
Q1218,24
q812
D13
ZB
LO10,80,790,2
LO205,80,2,150
LO10,80,2,1042
LO800,80,2,1042
A60,110,0,5,3,2,N,"P"
LO10,230,790,2
A50,240,0,5,1,1,N,"PRIORITY MAIL $DATA->{'commintmentName'}"
A735,245,0,4,1,1,N,"TM"
LO10,300,790,2
A25,330,0,2,1,1,N,"$DATA->{FromName}"
A25,350,0,2,1,1,N,"$DATA->{'customername'} "
A25,370,0,2,1,1,N,"$DATA->{'branchaddress1'}"
A25,390,0,2,1,1,N,"$DATA->{'branchaddress2'} "
A25,410,0,2,1,1,N,"$DATA->{'branchaddresscity'}, $DATA->{'branchaddressstate'} $DATA->{'branchaddresszip'}"
A100,510,0,3,1,1,N,"$DATA->{'contactname'}"
A100,530,0,3,1,1,N,"$DATA->{'addressname'}"
A100,550,0,3,1,1,N,"$DATA->{'address1'}"
A100,570,0,3,1,1,N,"$DATA->{'address2'}"
A100,590,0,3,1,1,N,"$DATA->{'addresscity'}, $DATA->{'addressstate'} $DATA->{'addresszip'}"
A545,330,0,2,1,1,N,"Ship Date:$DATA->{'datetoship'}"
A450,350,0,2,1,1,N,"Expected Delivery:$DATA->{'expectedDelivery'}"
A630,370,0,2,1,1,N,"Weight: $DATA->{'weightinounces'} oz"
A710,390,0,1,2,2,N,"$DATA->{'RDC'}"
LO590,430,1,40
LO500,430,1,40
LO500,430,90,1
LO500,470,90,1
A510,440,0,1,2,2,N,"$DATA->{'CarrierRoute'}"
LO10,700,790,10
A190,740,0,3,2,2,N,"USPS TRACKING #"
B80,790,0,1E,3,7,150,N,"$DATA->{'barcodedata'}"
A220,970,0,3,1,1,N,"$DATA->{'tracking1'}"
LO10,1020,790,10
A120,1070,0,4,1,1,N,"Electronic Rate Approved # $DATA->{'ElectronicRateApproved'} "
LO10,1120,790,4
P1
N
R0,0
.
END

	return $EPL;
	}

sub get_USPS_EPL_4
	{
	my $self = shift;
	my $DATA = shift;

	my $EPL = <<END;
.

N
OD10
Q1218,24
q812
D13
ZB
LO10,80,790,2
LO205,80,2,150
LO10,80,195,150
LO10,80,2,1042
LO800,80,2,1042
LO10,230,790,2
A90,240,0,5,1,1,N,"USPS MEDIA MAIL"
LO10,300,790,2
A25,330,0,2,1,1,N,"$DATA->{FromName}"
A25,350,0,2,1,1,N,"$DATA->{'customername'} "
A25,370,0,2,1,1,N,"$DATA->{'branchaddress1'}"
A25,390,0,2,1,1,N,"$DATA->{'branchaddress2'}"
A25,410,0,2,1,1,N,"$DATA->{'branchaddresscity'}, $DATA->{'branchaddressstate'} $DATA->{'branchaddresszip'}"
A100,510,0,3,1,1,N,"$DATA->{'contactname'}"
A100,530,0,3,1,1,N,"$DATA->{'addressname'}"
A100,550,0,3,1,1,N,"$DATA->{'address1'}"
A100,570,0,3,1,1,N,"$DATA->{'address2'}"
A100,590,0,3,1,1,N,"$DATA->{'addresscity'}, $DATA->{'addressstate'} $DATA->{'addresszip'}"
A550,330,0,2,1,1,N,"Ship Date:$DATA->{'datetoship'}"
A630,350,0,2,1,1,N,"Weight: $DATA->{'weightinounces'} oz"
A710,370,0,1,2,2,N,"$DATA->{'RDC'}"
LO590,430,1,40
LO500,430,1,40
LO500,430,90,1
LO500,470,90,1
A510,440,0,1,2,2,N,"$DATA->{'CarrierRoute'}"
LO10,700,790,10
A190,740,0,3,2,2,N,"USPS TRACKING #"
B80,790,0,1E,3,7,150,N,"$DATA->{'barcodedata'}"
A220,970,0,3,1,1,N,"$DATA->{'tracking1'}"
LO10,1020,790,10
A120,1070,0,4,1,1,N,"Electronic Rate Approved # $DATA->{'ElectronicRateApproved'}"
LO10,1120,790,4
P1
N
R0,0
.
END

	return $EPL;
	}

sub get_USPS_EPL_5
	{
	my $self = shift;
	my $DATA = shift;

	my $EPL = <<END;
.

N
OD10
Q1218,24
q812
D13
ZB
LO10,80,790,2
LO205,80,2,150
LO10,80,195,150
LO10,80,2,1042
LO800,80,2,1042
LO10,230,790,2
A90,240,0,5,1,1,N,"USPS LIBRARY MAIL"
LO10,300,790,2
A25,330,0,2,1,1,N,"$DATA->{FromName}"
A25,350,0,2,1,1,N,"$DATA->{'customername'} "
A25,370,0,2,1,1,N,"$DATA->{'branchaddress1'}"
A25,390,0,2,1,1,N,"$DATA->{'branchaddress2'}"
A25,410,0,2,1,1,N,"$DATA->{'branchaddresscity'}, $DATA->{'branchaddressstate'} $DATA->{'branchaddresszip'}"
A100,510,0,3,1,1,N,"$DATA->{'contactname'}"
A100,530,0,3,1,1,N,"$DATA->{'addressname'}"
A100,550,0,3,1,1,N,"$DATA->{'address1'}"
A100,570,0,3,1,1,N,"$DATA->{'address2'}"
A100,590,0,3,1,1,N,"$DATA->{'addresscity'}, $DATA->{'addressstate'} $DATA->{'addresszip'}"
A550,330,0,2,1,1,N,"Ship Date:$DATA->{'datetoship'}"
A630,350,0,2,1,1,N,"Weight: $DATA->{'weightinounces'} oz"
A710,370,0,1,2,2,N,"$DATA->{'RDC'}"
LO590,430,1,40
LO500,430,1,40
LO500,430,90,1
LO500,470,90,1
A510,440,0,1,2,2,N,"$DATA->{'CarrierRoute'}"
LO10,700,790,10
A190,740,0,3,2,2,N,"USPS TRACKING #"
B80,790,0,1E,3,7,150,N,"$DATA->{'barcodedata'}"
A220,970,0,3,1,1,N,"$DATA->{'tracking1'}"
LO10,1020,790,10
A120,1070,0,4,1,1,N,"Electronic Rate Approved # $DATA->{'ElectronicRateApproved'}"
LO10,1120,790,4
P1
N
R0,0
.
END

	return $EPL;
	}

sub get_USPS_EPL_6
	{
	my $self = shift;
	my $DATA = shift;

	my $EPL = <<END;
.

N
OD10
Q1218,24
q812
D13
ZB
LO10,80,790,2
LO205,80,2,150
A600,130,0,4,1,1,N,"POSTAGE"
A600,160,0,4,1,1,N,"REQUIRED"
LO10,80,2,1042
LO800,80,2,1042
A60,110,0,5,3,2,N,"E"
LO10,230,790,2
A20,240,0,3,2,3,N,"PRIORITY MAIL EXPRESS $DATA->{'commintmentName'}"
A755,250,0,4,1,1,N,"TM"
LO10,300,790,2
A25,330,0,2,1,1,N,"$DATA->{FromName}"
A25,350,0,2,1,1,N,"$DATA->{'customername'} "
A25,370,0,2,1,1,N,"$DATA->{'branchaddress1'}"
A25,390,0,2,1,1,N,"$DATA->{'branchaddress2'} "
A25,410,0,2,1,1,N,"$DATA->{'branchaddresscity'}, $DATA->{'branchaddressstate'} $DATA->{'branchaddresszip'}"
A100,510,0,3,1,1,N,"$DATA->{'contactname'}"
A100,530,0,3,1,1,N,"$DATA->{'addressname'}"
A100,550,0,3,1,1,N,"$DATA->{'address1'}"
A100,570,0,3,1,1,N,"$DATA->{'address2'}"
A100,590,0,3,1,1,N,"$DATA->{'addresscity'}, $DATA->{'addressstate'} $DATA->{'addresszip'}"
A550,330,0,2,1,1,N,"Ship Date:$DATA->{'datetoship'}"
A475,350,0,2,1,1,N,"Expected Delivery:$DATA->{'expectedDelivery'}"
A630,370,0,2,1,1,N,"Weight: $DATA->{'weightinounces'} oz"
A710,390,0,1,2,2,N,"$DATA->{'RDC'}"
LO590,430,1,40
LO500,430,1,40
LO500,430,90,1
LO500,470,90,1
A510,440,0,1,2,2,N,"$DATA->{'CarrierRoute'}"
LO10,640,790,10
A90,680,0,2,2,2,N,"USPS SIGNATURE TRACKING #"
B80,730,0,1E,3,7,150,N,"$DATA->{'barcodedata'}"
A220,890,0,3,1,1,N,"$DATA->{'tracking1'}"
LO10,920,790,60
A20,940,0,4,2,1,R,"POSTAL USE ONLY"
A20,1000,0,2,1,1,N,"Date In:"
A110,1010,0,1,1,1,N,"Mo"
A220,1010,0,1,1,1,N,"Day"
A360,1010,0,1,1,1,N,"Year"
A480,1000,0,2,1,1,N,"Time In:"
LO705,985,15,1
LO705,1000,15,1
LO705,985,1,15
LO720,985,1,15
A730,990,0,2,1,1,N,"AM"
LO705,1005,15,1
LO705,1020,15,1
LO705,1005,1,15
LO720,1005,1,15
A730,1010,0,2,1,1,N,"PM"
LO10,1025,790,1
A20,1045,0,2,1,1,N,"Day of Delivery:"
LO225,1040,15,1
LO225,1055,15,1
LO225,1040,1,15
LO240,1040,1,15
A250,1045,0,2,1,1,N,"Next"
LO355,1040,15,1
LO355,1055,15,1
LO355,1040,1,15
LO370,1040,1,15
A380,1045,0,2,1,1,N,"Second"
A510,1045,0,2,1,1,N,"10:30AM"
A620,1045,0,2,1,1,N,"12 Noon"
A730,1045,0,2,1,1,N,"3 Pm"
LO485,1040,15,1
LO485,1055,15,1
LO485,1040,1,15
LO500,1040,1,15
LO595,1040,15,1
LO595,1055,15,1
LO595,1040,1,15
LO610,1040,1,15
LO705,1040,15,1
LO705,1055,15,1
LO705,1040,1,15
LO720,1040,1,15
LO470,1025,1,95
LO240,1075,1,45
LO10,1075,790,1
A20,1085,0,1,1,1,N,"Return"
A20,1105,0,1,1,1,N,"Receipt"
A260,1095,0,1,1,1,N,"C00"
A480,1085,0,1,1,1,N,"Additional"
A480,1105,0,1,1,1,N,"Receipt"
LO10,1120,790,4
P1
N
R0,0
.
END

	return $EPL;
	}

sub get_BOL_EPL
	{
	my $self = shift;
	my $DATA = shift;

	my $EPL = <<END;
.

OD
JF
Q1370,24
q812
R5,140
S8
D15
N
ZB
A0,20,0,3,3,3,R,"  BILL OF LADING   "
LO0,80,1000,2
A25,100,0,3,1,1,N,"From:"
A150,100,0,2,1,1,N,"$DATA->{shipasname}"
A150,125,0,2,1,1,N,"$DATA->{branchaddress1}"
A150,150,0,2,1,1,N,"$DATA->{branchaddress2}"
A150,175,0,2,1,1,N,"$DATA->{branchaddresscity}, $DATA->{branchaddressstate} $DATA->{branchaddresszip}"
A150,200,0,2,1,1,N,"$DATA->{branchaddresscountry}"
A550,100,0,2,1,1,N,"$DATA->{branchcontact}"
A550,125,0,2,1,1,N,"$DATA->{branchphone}"
A550,150,0,2,1,1,N,"Ref: $DATA->{refnumber}"
A550,175,0,2,1,1,N,"Ship Date: $DATA->{shipdate}"
A550,200,0,2,1,1,N,"Airport Code: $DATA->{branchairportcode}"
LO0,230,1000,2
A25,250,0,3,1,1,N,"To:"
A150,250,0,2,1,1,N,"$DATA->{addressname}"
A150,275,0,2,1,1,N,"$DATA->{address1}"
A150,300,0,2,1,1,N,"$DATA->{address2}"
A150,325,0,2,1,1,N,"$DATA->{addresscity}, $DATA->{addressstate} $DATA->{addresszip}"
A150,350,0,2,1,1,N,"$DATA->{addresscountry}"
A550,250,0,2,1,1,N,"$DATA->{contactname}"
A550,275,0,2,1,1,N,"$DATA->{contactphone}"
A550,300,0,2,1,1,N,"PO: $DATA->{ponumber}"
A550,325,0,2,1,1,N,"ETA: $DATA->{etadate}"
A550,350,0,2,1,1,N,"Airport Code: $DATA->{airportcode}"
LO0,380,1000,2
A25,400,0,3,1,1,N,"Bill To:"
A150,400,0,2,1,1,N,""
A150,425,0,2,1,1,N,"$DATA->{billingname}"
A150,450,0,2,1,1,N,"$DATA->{billingaddress1}"
A150,475,0,2,1,1,N,"$DATA->{billingcity}, $DATA->{billingstate} $DATA->{billingzip}"
A150,500,0,2,1,1,N,"US"
A150,525,0,2,1,1,N,"$DATA->{billingphone}"
A550,400,0,2,1,1,N,"Weight: $DATA->{aggregateweight} Lbs"
A550,425,0,2,1,1,N,"$DATA->{dimweightdisplay}"
A550,450,0,2,1,1,N,"$DATA->{dimsdisplay}"
A550,475,0,2,1,1,N,"$DATA->{densitydisplay}"
A550,500,0,2,1,1,N,"Packages: $DATA->{totalquantity}"
A550,525,0,2,1,1,N,"Zone: $DATA->{zonenumber}"
A550,550,0,2,1,1,N,"Tracking: $DATA->{tracking1}"
LO0,580,1000,2
A25,600,0,3,1,1,N,"Description:"
A215,600,0,2,1,1,N,"$DATA->{extcd}"
A25,640,0,3,1,1,N,"Comments:"
A215,640,0,2,1,1,N,"$DATA->{description}"
LO0,670,1000,2
A25,690,0,3,2,2,R,"$DATA->{carrier}"
A25,750,0,3,2,2,R,"$DATA->{service}"
A25,1015,0,3,1,1,R,"$DATA->{labelbanner}"
P1
R0,0
.
END

	return $EPL;
	}

sub get_EFREIGHT_EPL
	{
	my $self = shift;
	my $DATA = shift;

	my $EPL = <<END;
.

OD
JF
Q1370,24
q812
R5,140
S8
D15
N
ZB
LO5,10,805,2
LO5,10,2,1410
LO810,10,2,1410
LO5,1380,805,2

A220,20,0,3,2,2,R,""
LO10,80,800,2
A25,100,0,3,1,1,N,"From:"
A150,100,0,2,1,1,N,"$DATA->{'shipasname'}"
A150,125,0,2,1,1,N,"$DATA->{'branchaddress1'}"
A150,150,0,2,1,1,N,"$DATA->{'branchaddress2'}"
A150,175,0,2,1,1,N,"$DATA->{'branchaddresscity'} $DATA->{'branchaddressstate'} $DATA->{'branchaddresszip'}"
A150,200,0,2,1,1,N,"$DATA->{'branchaddresscountry'}"
A515,100,0,2,1,1,N,"$DATA->{'branchcontact'}"
A515,125,0,2,1,1,N,"$DATA->{'branchphone'}"
A515,150,0,2,1,1,N,"Ref: $DATA->{'refnumber'}"
A515,175,0,2,1,1,N,"Ship Date: $DATA->{'shipdate'}"
A515,200,0,2,1,1,N,"Airport Code: $DATA->{'branchairportcode'}"
LO10,230,800,2
A25,250,0,3,1,1,N,"To:"
A150,250,0,2,1,1,N,"$DATA->{'addressname'}"
A150,275,0,2,1,1,N,"$DATA->{'address1'}"
A150,300,0,2,1,1,N,"$DATA->{'address2'}"
A150,325,0,2,1,1,N,"$DATA->{'addresscity'}, $DATA->{'addressstate'} $DATA->{'addresszip'}"
A150,350,0,2,1,1,N,"$DATA->{'addresscountry'}"
A515,250,0,2,1,1,N,"$DATA->{'contactname'}"
A515,275,0,2,1,1,N,"$DATA->{'contactphone'}"
A515,300,0,2,1,1,N,"PO: $DATA->{'ponumber'}"
A515,325,0,2,1,1,N,"ETA: $DATA->{'datedue'}"
A515,350,0,2,1,1,N,"Airport Code: $DATA->{'airportcode'}"
LO10,380,800,2
A515,400,0,2,1,1,N,"Weight: $DATA->{'weight'} Lbs"
A515,425,0,2,1,1,N,"DIM Weight: $DATA->{'dimweight'}"
A515,450,0,2,1,1,N,"DIMS: $DATA->{'dims'}"
A515,475,0,2,1,1,N,"Density: $DATA->{'density'}"
A515,500,0,2,1,1,N,"Packages: $DATA->{'totalquantity'}"
A515,525,0,2,1,1,N,"Zone: $DATA->{'zonenumber'}"
A515,550,0,2,1,1,N,"Tracking: $DATA->{'tracking1'}"
LO10,580,800,2
A25,600,0,3,1,1,N,"Description:"
A215,600,0,2,1,1,N,"$DATA->{'extcd'}"
A25,640,0,3,1,1,N,"Comments:"
A215,640,0,2,1,1,N,"$DATA->{'comments'}"
LO10,670,800,2
A25,690,0,3,2,2,R,"$DATA->{'carrier'}"
A515,690,0,3,2,2,N,"$DATA->{'hazardstring'}"
A25,750,0,3,2,2,R,"$DATA->{'service'}"
B50,810,0,3C,3,7,150,N,"$DATA->{'tracking1'}"
A350,980,0,3,1,1,N,"$DATA->{'tracking1'}"
A25,1015,0,3,1,1,R,"$DATA->{'labelbanner'}"

A25,400,0,3,1,1,N,"Bill To:"
A150,400,0,2,1,1,N,"$DATA->{'billingaddressname'}"
A150,425,0,2,1,1,N,"$DATA->{'billingaddress1'}"
A150,450,0,2,1,1,N,"$DATA->{'billingaddress1'}"
A150,475,0,2,1,1,N,"$DATA->{'billingcity'}, $DATA->{'billingstate'}  $DATA->{'billingzip'}"
A150,500,0,2,1,1,N,"$DATA->{'billingcountry'}"

A25,1255,0,3,1,1,N,"Pro#:"
A25,1280,0,3,1,1,N,"Carrier:"
A25,1305,0,3,1,1,N,"Service:"
A25,1330,0,3,1,1,N,"Origin:"
A25,1355,0,3,1,1,N,"Dest:"
A150,1255,0,3,1,1,N,"$DATA->{'tracking1'}"
A150,1280,0,3,1,1,N,"$DATA->{'carrier'}"
A150,1305,0,3,1,1,N,"$DATA->{'service'}"
A150,1330,0,3,1,1,N,"$DATA->{'branchaddressstate'} $DATA->{'branchaddresszip'}"
A150,1355,0,3,1,1,N,"$DATA->{'addressstate'} $DATA->{'addresszip'}"

A410,1255,0,3,1,1,N,"Customer Number"
A410,1280,0,3,1,1,N,"Consignee:"
A410,1305,0,3,1,1,N,"Zone:"
A410,1330,0,3,1,1,N,"Quantity:"
A410,1355,0,3,1,1,N,"Est Charge:"

A570,1255,0,3,1,1,N,"$DATA->{'truncd_custnum'}"
A570,1280,0,3,1,1,N,"$DATA->{'truncd_addressname'}"
A570,1305,0,3,1,1,N,"$DATA->{'zonenumber'}"
A570,1330,0,3,1,1,N,"$DATA->{'quantitydisplay'}"
A570,1355,0,3,1,1,N,"$DATA->{'chargeamount'}"
P1
R0,0
.
END

	}

__PACKAGE__->meta()->make_immutable();

no Moose;

1;

__END__