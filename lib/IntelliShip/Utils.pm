package IntelliShip::Utils;

use strict;
use Switch;
#use bignum;
use XML::Simple;
use Email::Valid;
use IntelliShip::Carrier::Constants;

=pod

=head1 NAME

IntelliShip::Utils

=head1 DESCRIPTION

Collection of various utilitarian methods.

=head1 METHODS

=cut

sub new
	{
	my $self = shift;
	my $obref = {};

	bless $obref, $self;

	return $obref;
	}

sub get_freight_class_from_density
	{
	my $self = shift;
	my ($Weight,$DimLength,$DimWidth,$DimHeight,$Density) = @_;

	if (length $Density == 0)
		{
		if ($DimLength > 0 and $DimWidth > 0 and $DimHeight > 0)
			{
			$Density = int(($Weight/($DimLength * $DimWidth * $DimHeight)) * 1728);
			}
		else
			{
			return 0;
			}
		}

	my $FreightClass;
	if ( $Density < 1 )
		{
		$FreightClass = 400;
		}
	elsif ( $Density >= 1 and $Density < 2 )
		{
		$FreightClass = 300;
		}
	elsif ( $Density >= 2 and $Density < 4 )
		{
		$FreightClass = 250;
		}
	elsif ( $Density >= 4 and $Density < 6 )
		{
		$FreightClass = 150;
		}
	elsif ( $Density >= 6 and $Density < 8 )
		{
		$FreightClass = 125;
		}
	elsif ( $Density >= 8 and $Density < 10 )
		{
		$FreightClass = 100;
		}
	elsif ( $Density >= 10 and $Density < 12 )
		{
		$FreightClass = 92.5;
		}
	elsif ( $Density >= 12 and $Density < 15 )
		{
		$FreightClass = 85;
		}
	elsif ( $Density >= 15 and $Density < 18 )
		{
		$FreightClass = 70;
		}
	elsif ( $Density >= 18 and $Density < 21 )
		{
		$FreightClass = 65;
		}
	elsif ( $Density >= 21 and $Density < 24 )
		{
		$FreightClass = 60;
		}
	elsif ( $Density >= 24 and $Density < 27 )
		{
		$FreightClass = 55;
		}
	elsif ( $Density >= 27 and $Density < 30 )
		{
		$FreightClass = 50;
		}

	return $FreightClass;
	}

sub hex_string
	{
	my $self = shift;
	my $string = shift;

	my %escapes;

	for (0..255)
		{
		$escapes{chr($_)} = sprintf("%%%02X", $_);
		}

	$string =~ s/([\x00-\x20\"#%;\@&=\*<>?{}\!\$\(\)|\\^~`\[\]\x7F-\xFF])/$escapes{$1}/g;
	$string =~ s/\+/\%2B/g;
	$string =~ s/ /+/g;

	return $string;
	}

sub hash_decode
	{
	my $self  = shift;
	my $param = shift;

	my ($key, $value);

	foreach $key (keys %$param)
		{
		$value = $param->{$key};
		$value =~ tr/+/ /;
		$value =~ s/%([\dA-Fa-f][\dA-Fa-f])/pack("C", hex ($1))/eg;
		$param->{$key} = $value;
		}

	return $param;
	}

sub parse_XML
	{
	my $self = shift;
	my $XML = shift;

	my $xs = XML::Simple->new(
		forcearray => 0,
		keeproot => 1,
		suppressempty => 1
		);

	my $xmlRequestDS = eval{ $xs->XMLin($XML) };

	if ($@)
		{
		print STDERR "\nXML Parse Error: " . $@;
		}

	return $xmlRequestDS;
	}

my $FILTER_CRITERIA_HASH = {
		'dateshipped'	=> 'Shipped Date',
		'carrier'		=> 'Carrier',
		'statusid'		=> 'Status',
		};

sub get_filter_value_from_key
	{
	my ($self,$key) = @_;
	(my $alias,$key) = split(/\./, $key) if $key =~ /\./g;
	return $FILTER_CRITERIA_HASH->{$key};
	}

sub jsonify
	{
	my $self = shift;
	my $struct = shift;
	my $json = [];
	if (ref($struct) eq "ARRAY")
		{
		my $list = [];
		foreach my $item (@$struct)
			{
				if (ref($item) eq "" ){
					$item = $self->clean_json_data($item);
					push @$list, "\"$item\"";
				}
				else{
					push @$list, $self->jsonify($item);
				}
			}

		return "[" . join(",",@$list) . "]";
		}
	elsif (ref($struct) eq "HASH")
		{
		my $list = [];
		foreach my $key (keys %$struct)
			{
			my $val = $struct->{$key};
			if (ref($val) eq "" )
				{
				$val = $self->clean_json_data($val);
				push @$list, "\"$key\":\"$val\"";
				}
			else
				{
				push @$list, "\"$key\":" . $self->jsonify($struct->{$key});
				}
			}
		return "{" . join(',',@$list) . "}";
		}
	}

sub clean_json_data
	{
	my $self = shift;
	my $item = shift;

	$item =~ s/"/\\"/g;
	$item =~ s/\t+//g;
	$item =~ s/\n+//g;
	$item =~ s/\r+//g;
	$item =~ s/^\s+//g;
	$item =~ s/\s+$//g;

	return $item;
	}

sub check_for_directory
	{
	my $self = shift;
	my $destination_dir = shift;

	my @dirs = split(/\//,$destination_dir);

	my $qualified_location;
	foreach my $dir (@dirs)
		{
		next unless $dir;
		$qualified_location .= '/' . $dir;
		mkdir $qualified_location or return unless stat $qualified_location;
		}

	return $qualified_location;
	}

sub is_valid_email
	{
	my $self = shift;
	my $email = shift;
	return Email::Valid->address($email);
	}

sub trim_hash_ref_values ## Trims all multiple internal whitespace down to a single space
	{
	my $self = shift;
	my $HashRef = shift;

	foreach my $Key (keys %$HashRef)
		{
		$HashRef->{$Key} =~ s/(.*?)\s*$/$1/;
		$HashRef->{$Key} =~ s/^\s*(.*)/$1/;
		$HashRef->{$Key} =~ s/\\//;
		$HashRef->{$Key} =~ s/\s+/ /g;
		}

	return $HashRef;
	}

my $SHIPMENT_CHARGE_NAMES = {
	freightcharge => 'Freight Charge',
	fuelsurcharge => 'Fuel Surcharge',
	declaredvalueinsurancecharge => 'Declared Value Insurance Charge',
	freightinsurancecharge => 'Freight Insurance Charge',
	codfeecharge => 'COD Fee Charge',
	collectfreightcharge => 'Collect Freight Charge',
	singleshipmentcharge => 'Single Shipment Charge',
	podservicecharge => 'POD Service Charge'
	};

sub get_shipment_charge_display_name
	{
	my $self = shift;
	my $ChargeType = shift;
	return $SHIPMENT_CHARGE_NAMES->{$ChargeType};
	}

sub get_status_ui_info
	{
	my $self = shift;
	my $IndicatorType = shift || 0;
	my $Condition = shift;

	my $dataHash = {};

	switch ($IndicatorType)
		{
		## indicator text
		case 1
			{
			switch ($Condition)
				{
				case 1 { $dataHash->{'conditioncolor'} = '#FF0000'; $dataHash->{'conditiontext'} = 'Routed'   } # Red
				case 2 { $dataHash->{'conditioncolor'} = '#FF6600'; $dataHash->{'conditiontext'} = 'Packed'   } # Orange
				case 3 { $dataHash->{'conditioncolor'} = '#9900FF'; $dataHash->{'conditiontext'} = 'Received' } # Yellow/Purple
				case 4 { $dataHash->{'conditioncolor'} = '#66CC33'; $dataHash->{'conditiontext'} = 'Entered'  } # Green
				case 5 { $dataHash->{'conditioncolor'} = '#0000CC'; $dataHash->{'conditiontext'} = 'Shipped'  } # Blue
				case 6 { $dataHash->{'conditioncolor'} = '#666666'; $dataHash->{'conditiontext'} = 'Voided'   } # Black
				else   { $dataHash->{'conditioncolor'} = '#000000'; $dataHash->{'conditiontext'} = 'Unknown'  } # Default
				}
			}
		## indicator graphic text
		case 2
			{
				switch ($Condition)
					{
					case 1 { $dataHash->{'conditioncolor'} = 'Green-Routed' }
					case 2 { $dataHash->{'conditioncolor'} = 'Yellow-Packed' }
					case 3 { $dataHash->{'conditioncolor'} = 'Orange-Received' }
					case 4 { $dataHash->{'conditioncolor'} = 'Red-Entered' }
					case 5 { $dataHash->{'conditioncolor'} = 'Shipped-Blue' }
					case 6 { $dataHash->{'conditioncolor'} = 'Voided-Black' }
					else   { $dataHash->{'conditioncolor'} = 'Unknown-Unknown' }
					}
			}
		## indicator balls
		else
			{
				switch ($Condition)
					{
					case 1 { $dataHash->{'conditioncolor'} = 'red'    ; $dataHash->{'conditiontext'} = '!'   }
					case 2 { $dataHash->{'conditioncolor'} = 'orange' ; $dataHash->{'conditiontext'} = '!'   }
					case 3 { $dataHash->{'conditioncolor'} = 'yellow' ; $dataHash->{'conditiontext'} = '&Delta;' }
					case 4 { $dataHash->{'conditioncolor'} = 'green'  ; $dataHash->{'conditiontext'} = '&#10004;'  }
					case 5 { $dataHash->{'conditioncolor'} = 'blue'   ; $dataHash->{'conditiontext'} = '&#10004;'  }
					case 6 { $dataHash->{'conditioncolor'} = 'black'  ; $dataHash->{'conditiontext'} = '&#10004;'   }
					else   { $dataHash->{'conditioncolor'} = 'unknown'; $dataHash->{'conditiontext'} = 'Unknown'  }
				}
			}
		}

	$dataHash->{'conditiontext'} = '';
	return ($dataHash->{'conditioncolor'},$dataHash->{'conditiontext'});
	}

my $CUSTOMER_CONTACT_RULES = [
   	{ name => 'Super User',                                     value => 'superuser' ,						type => 'CHECKBOX', datatypeid => 1 , ownertype => ['CUSTOMER']},
   	{ name => 'Administrator',                                  value => 'administrator' ,					type => 'CHECKBOX', datatypeid => 1 , ownertype => ['CUSTOMER']},
   	{ name => 'Third Party Billing',                            value=> 'thirdpartybill' ,					type => 'CHECKBOX', datatypeid => 1 , ownertype => ['CUSTOMER']},
   	{ name => 'Auto Print',                                     value => 'autoprint' ,						type => 'CHECKBOX', datatypeid => 1 , ownertype => ['CUSTOMER']},
   	{ name => 'Has Rates',                                      value => 'hasrates' ,						type => 'CHECKBOX', datatypeid => 1 , ownertype => ['CUSTOMER']},
   	{ name => 'Allow Postdating',                               value => 'allowpostdating' ,				type => 'CHECKBOX', datatypeid => 1 , ownertype => ['CUSTOMER']},
   	{ name => 'Auto Process',                                   value => 'autoprocess' ,					type => 'CHECKBOX', datatypeid => 1 , ownertype => ['CUSTOMER']},
   	{ name => 'Batch Shipping',                                 value => 'batchprocess' ,					type => 'CHECKBOX', datatypeid => 1 , ownertype => ['CUSTOMER']},
   	{ name => 'Quick Ship',                                     value => 'quickship' ,						type => 'CHECKBOX', datatypeid => 1 , ownertype => ['CUSTOMER', 'CONTACT']},
   	{ name => 'Default Declared Value',                         value => 'defaultdeclaredvalue' ,			type => 'CHECKBOX', datatypeid => 1 , ownertype => ['CUSTOMER']},
   	{ name => 'Default Freight Insurance',                      value => 'defaultfreightinsurance' ,		type => 'CHECKBOX', datatypeid => 1 , ownertype => ['CUSTOMER']},
   	{ name => 'Print Thermal BOL',                              value => 'printthermalbol',					type => 'CHECKBOX', datatypeid => 1 , ownertype => ['CUSTOMER']},
   	{ name => 'Print 8.5x11 BOL',                               value => 'print8_5x11bol' ,					type => 'CHECKBOX', datatypeid => 1 , ownertype => ['CUSTOMER']},
   	{ name => 'Has Product Data',                               value => 'hasproductdata' ,					type => 'CHECKBOX', datatypeid => 1 , ownertype => ['CUSTOMER']},
   	{ name => 'Export Shipment Tab',                            value => 'exportshipmenttab' ,				type => 'CHECKBOX', datatypeid => 1 , ownertype => ['CUSTOMER']},
   	{ name => 'Auto CS Select',                                 value => 'autocsselect' ,					type => 'CHECKBOX', datatypeid => 1 , ownertype => ['CUSTOMER']},
   	{ name => 'Auto Shipment Opimize',                          value => 'autoshipmentoptimize' ,			type => 'CHECKBOX', datatypeid => 1 , ownertype => ['CUSTOMER']},
   	{ name => 'Error on Past Ship Date',                        value => 'errorshipdate' ,					type => 'CHECKBOX', datatypeid => 1 , ownertype => ['CUSTOMER']},
   	{ name => 'Error on Past Due Date',                         value => 'errorduedate' ,					type => 'CHECKBOX', datatypeid => 1 , ownertype => ['CUSTOMER']},
   	{ name => 'Upload Orders',                                  value => 'uploadorders' ,					type => 'CHECKBOX', datatypeid => 1 , ownertype => ['CUSTOMER']},
   	{ name => 'ZPL2',                                           value => 'zpl2' ,							type => 'CHECKBOX', datatypeid => 1 , ownertype => ['CUSTOMER', 'CONTACT']},
   	{ name => 'Security Types',                                 value => 'hassecurity' ,					type => 'CHECKBOX', datatypeid => 1 , ownertype => ['CUSTOMER']},
   	{ name => 'Show Hazardous',                                 value => 'showhazardous' ,					type => 'CHECKBOX', datatypeid => 1 , ownertype => ['CUSTOMER']},
   	{ name => 'AM Delivery',                                    value => 'amdelivery' ,						type => 'CHECKBOX', datatypeid => 1 , ownertype => ['CUSTOMER']},
   	{ name => 'Print UCC128 Label',                             value => 'checkucc128' ,					type => 'CHECKBOX', datatypeid => 1 , ownertype => ['CUSTOMER']},
   	{ name => 'Require Order Number',                           value => 'reqordernumber' ,					type => 'CHECKBOX', datatypeid => 1 , ownertype => ['CUSTOMER']},
   	{ name => 'Require Customer Number',                        value => 'reqcustnum' ,						type => 'CHECKBOX', datatypeid => 1 , ownertype => ['CUSTOMER']},
   	{ name => 'Require PO Number',                              value => 'reqponum' ,						type => 'CHECKBOX', datatypeid => 1 , ownertype => ['CUSTOMER']},
   	{ name => 'Require Product Description',                    value => 'reqproddescr' ,					type => 'CHECKBOX', datatypeid => 1 , ownertype => ['CUSTOMER']},
   	{ name => 'Require Ship Date',                              value => 'reqdatetoship' ,					type => 'CHECKBOX', datatypeid => 1 , ownertype => ['CUSTOMER']},
   	{ name => 'Require Due Date',                               value => 'reqdateneeded' ,					type => 'CHECKBOX', datatypeid => 1 , ownertype => ['CUSTOMER']},
   	{ name => 'Require Customer Ref 2',                         value => 'reqcustref2' ,					type => 'CHECKBOX', datatypeid => 1 , ownertype => ['CUSTOMER']},
   	{ name => 'Require Customer Ref 3',                         value => 'reqcustref3' ,					type => 'CHECKBOX', datatypeid => 1 , ownertype => ['CUSTOMER']},
   	{ name => 'Require Department',                             value => 'reqdepartment' ,					type => 'CHECKBOX', datatypeid => 1 , ownertype => ['CUSTOMER']},
   	{ name => 'Require Ext ID',                                 value => 'reqextid' ,						type => 'CHECKBOX', datatypeid => 1 , ownertype => ['CUSTOMER']},
   	{ name => 'Manual Routing Control',                         value => 'manroutingctrl' ,					type => 'CHECKBOX', datatypeid => 1 , ownertype => ['CUSTOMER']},
   	{ name => 'Has AltSOPs',                                    value => 'hasaltsops' ,						type => 'CHECKBOX', datatypeid => 1 , ownertype => ['CUSTOMER']},
   	{ name => 'Custnum Address Lookup',                         value => 'custnumaddresslookup' ,			type => 'CHECKBOX', datatypeid => 1 , ownertype => ['CUSTOMER', 'CONTACT']},
   	{ name => 'Saturday Shipping',                              value => 'satshipping' ,					type => 'CHECKBOX', datatypeid => 1 , ownertype => ['CUSTOMER', 'CONTACT']},
   	{ name => 'Sunday Shipping',                                value => 'sunshipping' ,					type => 'CHECKBOX', datatypeid => 1 , ownertype => ['CUSTOMER', 'CONTACT']},
   	{ name => 'Auto DIM Classing',                              value => 'autodimclass' ,					type => 'CHECKBOX', datatypeid => 1 , ownertype => ['CUSTOMER', 'CONTACT']},
   	{ name => 'Save Order Upon Shipping',                       value => 'saveorder' ,						type => 'CHECKBOX', datatypeid => 1 , ownertype => ['CUSTOMER']},
   	{ name => 'Always Show Assessorials',                       value => 'alwaysshowassessorials' ,			type => 'CHECKBOX', datatypeid => 1 , ownertype => ['CUSTOMER']},
   	{ name => 'TAB Pick-N-Pack',                                value => 'pickpack' ,						type => 'CHECKBOX', datatypeid => 1 , ownertype => ['CUSTOMER']},
   	{ name => 'Date Specific Consolidation',                    value => 'dateconsolidation' ,				type => 'CHECKBOX', datatypeid => 1 , ownertype => ['CUSTOMER']},
   	{ name => 'Alert Cutoff Date Change',                       value => 'alertcutoffdatechange' ,			type => 'CHECKBOX', datatypeid => 1 , ownertype => ['CUSTOMER']},
   	{ name => 'Allow Consolidate/Combine',                      value => 'consolidatecombine' ,				type => 'CHECKBOX', datatypeid => 1 , ownertype => ['CUSTOMER']},
   	{ name => 'Default Multi Order Nums',                       value => 'defaultmultiordernum' ,			type => 'CHECKBOX', datatypeid => 1 , ownertype => ['CUSTOMER']},
   	{ name => 'Export PackProdata (requires shipment export)',  value => 'exportpackprodata' ,				type => 'CHECKBOX', datatypeid => 1 , ownertype => ['CUSTOMER']},
   	{ name => 'Default Commercial Invoice',                     value => 'defaultcomminv' ,					type => 'CHECKBOX', datatypeid => 1 , ownertype => ['CUSTOMER', 'CONTACT']},
   	{ name => 'Intelliship Notification',                       value => 'aosnotifications' ,				type => 'CHECKBOX', datatypeid => 1 , ownertype => ['CUSTOMER']},
   	{ name => 'DisAllow New Order',                             value => 'disallowneworder' ,				type => 'CHECKBOX', datatypeid => 1 , ownertype => ['CUSTOMER']},
   	{ name => 'Single Order Shipment',                          value => 'singleordershipment' ,			type => 'CHECKBOX', datatypeid => 1 , ownertype => ['CUSTOMER']},
   	{ name => 'DisAllow Ship Packages',                         value => 'disallowshippackages' ,			type => 'CHECKBOX', datatypeid => 1 , ownertype => ['CUSTOMER']},
   	{ name => 'Independent Quantity/Weight',                    value => 'quantityxweight' ,				type => 'CHECKBOX', datatypeid => 1 , ownertype => ['CUSTOMER']},
   	{ name => 'SOP' ,                                           value => 'sopid' ,							type => 'SELECT',   datatypeid => 2 , ownertype => ['CUSTOMER']},
   	{ name => 'Client ID' ,                                     value => 'clientid' ,						type => 'INPUT',    datatypeid => 2 , ownertype => ['CUSTOMER']},
   	{ name => 'Thermal Label Count' ,                           value => 'defaultthermalcount' ,			type => 'INPUT',    datatypeid => 2 , ownertype => ['CUSTOMER']},
   	{ name => '8.5x11 BOL Label Count' ,                        value => 'bolcount8_5x11' ,					type => 'INPUT',    datatypeid => 2 , ownertype => ['CUSTOMER']},
   	{ name => 'Thermal BOL Label Count' ,                       value => 'bolcountthermal' ,				type => 'INPUT',    datatypeid => 2 , ownertype => ['CUSTOMER']},
   	{ name => 'Label Printer Port' ,                            value => 'labelport' ,						type => 'INPUT',    datatypeid => 2 , ownertype => ['CUSTOMER', 'CONTACT']},
   	{ name => 'BOL Type' ,                                      value => 'boltype' ,						type => 'SELECT',   datatypeid => 1 , ownertype => ['CUSTOMER']},
   	{ name => 'BOL Detail' ,                                    value => 'boldetail' ,						type => 'SELECT',   datatypeid => 1 , ownertype => ['CUSTOMER']},
   	{ name => 'Auto Report Times' ,                             value => 'autoreporttime' ,					type => 'INPUT',    datatypeid => 2 , ownertype => ['CUSTOMER']},
   	{ name => 'Auto Report Email' ,                             value => 'autoreportemail' ,				type => 'INPUT',    datatypeid => 2 , ownertype => ['CUSTOMER']},
   	{ name => 'Auto Report Interval' ,                          value => 'autoreportinterval' ,				type => 'INPUT',    datatypeid => 2 , ownertype => ['CUSTOMER']},
   	{ name => 'Proxy IP' ,                                      value => 'proxyip' ,						type => 'INPUT',    datatypeid => 2 , ownertype => ['CUSTOMER']},
   	{ name => 'Proxy Port' ,                                    value => 'proxyport' ,						type => 'INPUT',    datatypeid => 2 , ownertype => ['CUSTOMER']},
   	{ name => 'Loss Prevention Email' ,                         value => 'losspreventemail' ,				type => 'INPUT',    datatypeid => 2 , ownertype => ['CUSTOMER']},
   	{ name => 'Loss Prevention Email (Manual Order Create)' ,   value => 'losspreventemailordercreate' ,	type => 'INPUT',    datatypeid => 2 , ownertype => ['CUSTOMER']},
   	{ name => 'Smart Address Book' ,                            value => 'smartaddressbook' ,				type => 'INPUT',    datatypeid => 2 , ownertype => ['CUSTOMER']},
   	{ name => 'API Intelliship Address' ,                       value => 'apiaosaddress' ,					type => 'INPUT',    datatypeid => 2 , ownertype => ['CUSTOMER']},
   	{ name => 'Charge Difference Threshold (flat)' ,            value => 'chargediffflat' ,					type => 'INPUT',    datatypeid => 2 , ownertype => ['CUSTOMER']},
   	{ name => 'Charge Difference Threshold (%/min)' ,           value => 'chargediffpct' ,					type => 'INPUT',    datatypeid => 2 , ownertype => ['CUSTOMER']},
   	{ name => '' ,                                              value => 'chargediffmin' ,					type => 'INPUT',    datatypeid => 2 , ownertype => ['CUSTOMER']},
   	{ name => 'Return Capability' ,                             value => 'returncapability' ,				type => 'SELECT',   datatypeid => 1 , ownertype => ['CUSTOMER', 'CONTACT'] , default => '0'},
   	{ name => 'Login Level' ,                                   value => 'loginlevel' ,						type => 'SELECT',   datatypeid => 1 , ownertype => ['CUSTOMER', 'CONTACT']},
   	{ name => 'Dropship Capability' ,                           value => 'dropshipcapability' ,				type => 'SELECT',   datatypeid => 1 , ownertype => ['CUSTOMER', 'CONTACT'] , default => '0'},
   	{ name => 'Display Quote Markup' ,                          value => 'quotemarkup' ,					type => 'SELECT',   datatypeid => 1 , ownertype => ['CUSTOMER', 'CONTACT'] , default => '0'},
   	{ name => 'Quote Markup Default' ,                          value => 'quotemarkupdefault' ,				type => 'SELECT',   datatypeid => 1 , ownertype => ['CUSTOMER', 'CONTACT'] , default => '0'},
   	{ name => 'Default Freight Class' ,                         value => 'defaultfreightclass' ,			type => 'INPUT',    datatypeid => 2 , ownertype => ['CUSTOMER', 'CONTACT']},
   	{ name => 'Cycle Time Threshold' ,                          value => 'cycletimethreshold' ,				type => 'INPUT',    datatypeid => 2 , ownertype => ['CUSTOMER']},
   	{ name => 'Due Date Offset (equal)' ,                       value => 'duedateoffsetequal' ,				type => 'INPUT',    datatypeid => 2 , ownertype => ['CUSTOMER']},
   	{ name => 'Due Date Offset (less than)' ,                   value => 'duedateoffsetlessthan' ,			type => 'INPUT',    datatypeid => 2 , ownertype => ['CUSTOMER']},
   	{ name => 'Default Package Unit Type' ,                     value => 'defaultpackageunittype' ,			type => 'SELECT',   datatypeid => 1 , ownertype => ['CUSTOMER', 'CONTACT']},
   	{ name => 'Default Product Unit Type' ,                     value => 'defaultproductunittype' ,			type => 'SELECT',   datatypeid => 1 , ownertype => ['CUSTOMER', 'CONTACT']},
   	{ name => 'PO Instructions' ,                               value => 'poinstructions' ,					type => 'SELECT',   datatypeid => 1 , ownertype => ['CUSTOMER', 'CONTACT']},
   	{ name => 'PO Auth Type' ,                                  value => 'poauthtype' ,						type => 'SELECT',   datatypeid => 1 , ownertype => ['CUSTOMER', 'CONTACT'] , default => '0'},
   	{ name => 'Company Type' ,                                  value => 'companytype' ,					type => 'SELECT',   datatypeid => 1 , ownertype => ['CUSTOMER'], },
   	{ name => 'Print Packing List' ,                            value => 'defaultpackinglist' ,				type => 'SELECT',   datatypeid => 1 , ownertype => ['CUSTOMER', 'CONTACT'] , default => '0'},
   	{ name => 'Packing List' ,                                  value => 'packinglist' ,					type => 'SELECT',   datatypeid => 1 , ownertype => ['CUSTOMER', 'CONTACT']},
   	{ name => 'Live Product TAB' ,                              value => 'liveproduct' ,					type => 'SELECT',   datatypeid => 2 , ownertype => ['CUSTOMER'] , default => '0'},
   	{ name => 'Freight Charge Editablity' ,                     value => 'fceditability' ,					type => 'SELECT',   datatypeid => 1 , ownertype => ['CUSTOMER'] , default => '0'},
   	{ name => 'Label Stub' ,                                    value => 'labelstub' ,						type => 'SELECT',   datatypeid => 2 , ownertype => ['CUSTOMER'] , default => '0'},
   	{ name => 'My Orders' ,                                     value => 'myorders' ,						type => 'CHECKBOX', datatypeid => 1 , ownertype => ['CONTACT']},
   	{ name => 'Text Status' ,                                   value => 'indicatortype' ,					type => 'SELECT',   datatypeid => 1 , ownertype => ['CONTACT'] , default => '0'},
   	{ name => 'SKU Manager' ,                                   value => 'skumanager' ,						type => 'CHECKBOX', datatypeid => 1 , ownertype => ['CONTACT']},
   	{ name => 'API Username' ,                                  value => 'apiusername' ,					type => 'INPUT',    datatypeid => 2 , ownertype => ['CUSTOMER', 'CONTACT']},
   	{ name => 'API Password' ,                                  value => 'apipassword' ,					type => 'INPUT',    datatypeid => 2 , ownertype => ['CUSTOMER', 'CONTACT']},
   	{ name => 'HALO Username' ,                                 value => 'halousername' ,					type => 'INPUT',    datatypeid => 2 , ownertype => ['CONTACT']},
   	{ name => 'HALO Password' ,                                 value => 'halopassword' ,					type => 'INPUT',    datatypeid => 2 , ownertype => ['CONTACT']},
   	{ name => 'HALO URL' ,                                      value => 'halourl' ,						type => 'INPUT',    datatypeid => 2 , ownertype => ['CONTACT']},
   	{ name => 'Label Type' ,                                    value => 'labeltype' ,						type => 'RADIO',    datatypeid => 2 , ownertype => ['CUSTOMER', 'CONTACT']},
	{ name => 'Auto Select-Multiply Qty X Weight' ,             value => 'auto_select_quantity_x_weight' ,  type => 'CHECKBOX', datatypeid => 1 , ownertype => ['CUSTOMER', 'CONTACT']},
	{ name => 'Only Show My Items' ,                            value => 'myonly' ,							type => 'CHECKBOX', datatypeid => 1 , ownertype => ['CUSTOMER', 'CONTACT']},
	];

sub get_rules
	{
	my $self = shift;
	my $type = shift || 'CUSTOMER';
	return [grep { scalar(grep /$type/, @{$_->{ownertype}}) > 0 } @{$CUSTOMER_CONTACT_RULES}];
	}

my $TRACK_URLS = {
		lc(&CARRIER_DHL)   => "http://track.dhl-usa.com/TrackByNbr.asp?ShipmentNumber=XXXX&nav=TrackBynumber",
		lc(&CARRIER_UPS)   => "http://wwwapps.ups.com/etracking/tracking.cgi?tracknums_displayed=5&TypeOfInquiryNumber=T&HTMLVersion=4.0&InquiryNumber1=XXXX&track=Track",
		lc(&CARRIER_FEDEX) => "http://www.fedex.com/Tracking?action=track&language=english&cntry_code=us&initial=x&tracknumbers=XXXX",
		lc(&CARRIER_USPS)  => "https://tools.usps.com/go/TrackConfirmAction.action?tLabels=XXXX"
		};

sub get_tracking_URL
	{
	my $self = shift;
	my $carrier_name = shift;
	my $tracking_number = shift;

	my $tracking_url = $TRACK_URLS->{lc $carrier_name};
	$tracking_url =~ s/XXXX/$tracking_number/g;

	return $tracking_url;
	}

1;

__END__