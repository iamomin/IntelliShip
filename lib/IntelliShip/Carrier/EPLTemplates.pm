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

__PACKAGE__->meta()->make_immutable();

no Moose;

1;

__END__