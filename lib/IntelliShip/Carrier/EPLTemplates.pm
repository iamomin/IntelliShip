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

sub get_USPS_EPL
	{
	my $self = shift;
	my $DATA = shift;

	my $EPL = <<END;
.

N
OD10
q912
Q1218,24
D15
ZB
LO0,80,1000,2
LO205,80,2,150
LO0,80,2,1042
LO813,80,2,1042
A60,80,0,5,3,3,N,"F"
LO0,230,1000,2
A60,250,0,2,3,3,N,"USPS FIRST-CLASS MAIL"
LO0,300,1000,2
A25,330,0,2,1,1,N,"$DATA->{FromName}"
A25,350,0,2,1,1,N,"$DATA->{'customername'} "
A25,370,0,2,1,1,N,"$DATA->{'customername'}"
A25,390,0,2,1,1,N,"$DATA->{'branchaddress2'} "
A25,410,0,2,1,1,N,"$DATA->{'branchaddresscity'}, $DATA->{'branchaddressstate'} $DATA->{'branchaddresszip'}"
A100,510,0,3,1,1,N,"$DATA->{'contactname'}"
A100,530,0,3,1,1,N,"$DATA->{'addressname'}"
A100,550,0,3,1,1,N,"$DATA->{'address1'}"
A100,570,0,3,1,1,N,"$DATA->{'address2'}"
A100,590,0,3,1,1,N,"$DATA->{'addresscity'}, $DATA->{'addressstate'} $DATA->{'addresszip'}"
A600,330,0,2,1,1,N,"$DATA->{datetoship}"
A600,350,0,2,1,1,N,"Weight: $DATA->{weightinounces} oz"
A600,370,0,1,2,2,N,"0005"
LO590,430,1,40
LO500,430,1,40
LO500,430,90,1
LO500,470,90,1
A510,440,0,1,2,2,N,"C000"
LO0,700,1000,10
A190,740,0,3,2,2,N,"USPS TRACKING #"
B150,790,0,1E,3,7,150,B,"$DATA->{tracking1}"
LO0,1020,1000,10
A100,1070,0,4,1,1,N,"Electronic Rate Approved # 699329"
LO0,1120,1000,4
P1
N
R0,0
.
END

	return $EPL;
	}

__PACKAGE__->meta()->make_immutable();

no Moose;

1;

__END__