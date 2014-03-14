package ARRS;

use strict;
use ARRS::COMMON;
use ARRS::IDBI;
use ARRS::CONTACT;
use ARRS::ONLINE;
use ARRS::CUSTOMERSERVICE;
use ARRS::SERVICE;
use ARRS::CARRIER;
use ARRS::ZONE;
use ARRS::MODETYPE;
use ARRS::CSOVERRIDE;
use ARRS::ASSDATA;
use ARRS::INVOICEDATA;
use IntelliShip::MyConfig;

=b
This API should generally be called from outside using the 'APIRequest' function which can
be found in COMMON.pm (the most current version is under AOS).

The APIRequest always takes a hashref for its argument.

This hashref must always have an 'action' key, with the value being one of the functions
in this screen handler (excepting 'new', 'HandleErrors', 'HandleDisplay', 'HandleStates',
and 'BuildReturnString') - proper case required.

The additinal elements should contain the arguments to the function, and will be passed to the
the function as a hashref.

Each function will further call whatever underlying functions it needs.  The return values will
*always* be hashrefs.  These are put into a format (using 'BuildReturnString') that the 'APIRequest'
function will automatically convert back to a hashref on the calling side.

As a convention, arrays should always be passed into and out of the API in tab delimitted format.
At least currently, either end of the API call will be responsible for converting said tab-delimited
strings into arrays as needed.
=cut

my $config = IntelliShip::MyConfig->get_ARRS_configuration;

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my ($Ref) = @_;

	my $self = {};

	$self->{'dbref'} = ARRS::IDBI->connect(
		{
			dbname		=> $config->{DB_NAME},
			dbhost		=> $config->{DB_HOST},
			dbuser	 	=> $config->{DB_USER},
			dbpassword	=> $config->{DB_PASSWORD},
			autocommit	=> 0,
		}
	);

	$self->{'contact'} = new ARRS::CONTACT( $self->{'dbref'} );
	$self->{'contact'}->Authenticate( undef, $config->{ADMIN_USER},
		$config->{ADMIN_PASSWORD} );

	bless( $self, $class );
	return $self;
}

sub DESTROY {
	my $self = shift;

# This has every arrs call delete its own token.  Still not sure what to do with remote call logouts, though,
# so leave it off until we can sort that out.
#		$self->{'contact'}->Logout($self->{'contact'}->TokenID());
	$self->{'dbref'}->disconnect();
}

sub APICall {
	my $self = shift;
	my ($Ref) = @_;

	#WarnHashRefValues(eval '$self->' . $Ref->{'action'} . '($Ref)');
	return eval '$self->' . $Ref->{'action'} . '($Ref)';
}

sub GetCSList {
	my $self = shift;
	my ($Ref) = @_;

# Given the whole slew of arguments required, returns a list of csnames, a list of csids,
# the defaultcsid, the defaultcost (freight), the defaulttotalcost (freight + fsc + whatever),
# and the costlist (a js array string with all package costs and fscs for a shipment).

# fromzip = (r)
# fromstate = (r)
# fromcountry = (r)
# tozip = (r)
# tostate = (r)
# tocountry = (r)
# datetoship = (r)
# dateneeded = (r) if rating needed, otherwise (o)
# hasrates = flag to show whether customers shipments should be rated for proper display (o)
# autocsselect = flag to determine whether the default csid should be determined (o)
# allowraterecalc = flag to determin whether rates should be recaclulated (r)
# manroutingctrl = flag that determines whether the customer needs to explicitly hit the 'route' button (o)
# weightlist = js style string containing package weights (r)
# quantitylist = js style string containing package quantity (r)
# dimlengthlist = js style string containing package dimlengths (o)
# dimwidthlist = js style string containing package dimwidths (o)
# dimheightlist = js style string containing package dimheights (o)
# productcount = total number of product line items (r)
# route = flag triggered by the customer explicitly hitting the 'route' button (o)
# sopid = generally the customerid - could be altsopid, or customer level sopid
# class = freight class (r) to rate tariff based carriers, otherwise (o)
# csid = default/incoming co csid (o)
# quantityxweight = flag determining whether to multiply quantity times weight in rate calcs(o)
# productparagidm = flag to set rating to product based (Vought only, at this point) (o)
# customerid = real customerid to allow for customerspecific CS spins
# required_assessorials = list of assessorials that all returned CS's must have

	my $Online =
	  new ARRS::ONLINE( $self->{'dbref'}, $self->{'contact'} );

	return $Online->GetServicesDropdown($Ref);
}

sub GetCSID {
	my $self = shift;
	my ($Ref) = @_;

	# Given the carrier, service, and sopid, get the customerserviceid

	# carrier = Carrier name (r)
	# service = Service Name (r)
	# sopid = Customerid or altsopid (r)
	my $Online =
	  new ARRS::ONLINE( $self->{'dbref'}, $self->{'contact'} );

	return $Online->GetCSID($Ref);
}

sub GetCSShippingValues {
	my $self = shift;
	my ($Ref) = @_;

	# Given a singular csid, return ref for most values needed for template work
	# use (such as in shipconfirm)

	# csid = Singular csid (r)

	my $CS = new ARRS::CUSTOMERSERVICE( $self->{'dbref'}, $self->{'contact'} );

	return $CS->GetCSShippingValues($Ref);
}

sub GetCSJSArrays {
	my $self = shift;
	my ($Ref) = @_;

   # Given a tab delimited list of CSIDs, return JS style array for template use
   # use (such as in shipconfirm)

	# csids =  Tab delimited list of CSIDs (r)

	my $CS =
	  new ARRS::CUSTOMERSERVICE( $self->{'dbref'}, $self->{'contact'} );

	return $CS->GetCSJSArrays($Ref);
}

sub GetCSValue {
	my $self = shift;
	my ($Ref) = @_;

# Get specific field values from servicecsdata table (or legacy service and cs fields)

# customerserviceid = (r)
# datatypename = field name (e.g. fscrate) (r)
# allownull = a null value will return 0, unless this flag is passed (o)
# customerid = original customerid (to allow for CS overrides) (r)

	my $CS =
	  new ARRS::CUSTOMERSERVICE( $self->{'dbref'}, $self->{'contact'} );
	$CS->Load( $Ref->{'customerserviceid'} );

	my $Value = $CS->GetCSValue( $Ref->{'datatypename'},
		$Ref->{'allownull'}, $Ref->{'customerid'} );

	my $ValueRef = {};
	$ValueRef->{'value'} = $Value;

	return $ValueRef;
}

sub GetCost {
	my $self = shift;
	my ($Ref) = @_;

# This interfaces with the basic vanilla CS::GetCost.  Won't work for tariff carriers -
# should probably be beefed up to use 'GetSuperCost' at some point.

	# csid = customerserviceid (r)
	# fromzip = (r)
	# fromstate = (r)
	# fromcountry = (r)
	# tozip = (r)
	# tostate = (r)
	# tocountry = (r)
	# weight = (r)
	# dimlenth = (o)
	# dimwidth = (o)
	# dimheight = (o)
	# type		 = (o) - ar/ap, defaults to ar
	# band		 = (o) - variable rate bands (currently UPS)
	# zonenumber   = (o) - if passed, will use rather than lookup
	# cwt	= (o) - explicitly grab CWT rates
	# intelliship = (0) - are we costing an AOS based shipment or not?

	my $CS =
	  new ARRS::CUSTOMERSERVICE( $self->{'dbref'}, $self->{'contact'} );
	$CS->Load( $Ref->{'csid'} );

	my $DimWeight =
	  $CS->GetDimWeight( $Ref->{'dimlength'}, $Ref->{'dimwidth'},
		$Ref->{'dimheight'} );

	my $Weight =
	  ( defined($DimWeight) && $DimWeight > $Ref->{'weight'} )
	  ? $DimWeight
	  : $Ref->{'weight'};

	my ( $Cost, $Zone ) = $CS->GetCost(
		$Weight,
		$CS->GetValueHashRef()->{'ratetypeid'},
		$Ref->{'fromzip'},
		$Ref->{'tozip'},
		$Ref->{'fromstate'},
		$Ref->{'tostate'},
		$Ref->{'fromcountry'},
		$Ref->{'tocountry'},
		$Ref->{'type'},
		$Ref->{'band'},
		$Ref->{'zonenumber'},
		$Ref->{'cwt'},
		$Ref->{'dollaramount'},
		$Ref->{'lookuptype'},
		$Ref->{'quantity'},
		$Ref->{'unittype'},
		$Ref->{'automated'},
		$Ref->{'customerid'},
		$Ref->{'dateshipped'},
	);

	my $CostRef = {};

	$CostRef->{'cost'} = $Cost;
	$CostRef->{'zone'} = $Zone;

	return $CostRef;
}

sub GetZone {
	my $self = shift;
	my ($Ref) = @_;

# This interfaces with the basica vanilla CS::GetZone.  Won't work for tariff carriers.

	# csid = customerserviceid (r)
	# fromzip = (r)
	# fromstate = (r)
	# fromcountry = (r)
	# tozip = (r)
	# tostate = (r)
	# tocountry = (r)

	my $CS =
	  new ARRS::CUSTOMERSERVICE( $self->{'dbref'}, $self->{'contact'} );
	$CS->Load( $Ref->{'csid'} );

	my $Zone = $CS->GetZoneNumber(
		$Ref->{'fromzip'},	 $Ref->{'tozip'},
		$Ref->{'fromstate'},   $Ref->{'tostate'},
		$Ref->{'fromcountry'}, $Ref->{'tocountry'},
	);

	return ( { zone => $Zone } );
}

sub GetDimWeight {
	my $self = shift;
	my ($Ref) = @_;

	# csid = customerserviceid (r)
	# dimlenth = (r)
	# dimwidth = (r)
	# dimheight = (r)
	my $CS =
	  new ARRS::CUSTOMERSERVICE( $self->{'dbref'}, $self->{'contact'} );
	$CS->Load( $Ref->{'csid'} );

	my $DimWeight =
	  $CS->GetDimWeight( $Ref->{'dimlength'}, $Ref->{'dimwidth'},
		$Ref->{'dimheight'} );

	return { dimweight => $DimWeight };
}

sub DeleteZone {
	my $self = shift;
	my ($Ref) = @_;

# Given a typeid, fromzip, and tozip - delete the zip from the zone.  Used in cases where a carrier
# explicitly errors that a given zip combo is not valid for a given service

	# typeid = zonetypeid (r)
	# fromzip = (r)
	# tozip = (r)

	my $Zone = new ARRS::ZONE( $self->{'dbref'}, $self->{'contact'} );

	return $Zone->Delete($Ref);
}

sub GetETADate {
	my $self = shift;
	my ($ETARef) = @_;

	# Get the ETA Date for a given cs
	# If none of the optional parameters are included, no ETA data can be calc'd

	# csid = customerserviceid (r)
	# datetoship = (r)
	# dateneeded = (r)
	# timeneededmax = default cs value for the max days needed (o)
	# fromzip = (o)
	# tozip = (o)
	# carrierid = (o)
	# serviceid = (o)

	use Date::Manip qw(ParseDate UnixDate);
	my $ParsedDueDate = ParseDate( $ETARef->{'dateneeded'} );
	$ETARef->{'downeeded'} = UnixDate( $ParsedDueDate, "%a" );

	my $CS =
	  new ARRS::CUSTOMERSERVICE( $self->{'dbref'}, $self->{'contact'} );
	$CS->Load( $ETARef->{'csid'} );
	$ETARef->{'cs'} = $CS;

	my $Online =
	  new ARRS::ONLINE( $self->{'dbref'}, $self->{'contact'} );
	my $DateDue = $Online->GetETADate($ETARef);

	return { datedue => $DateDue };
}

sub GetValueHashRef {
	my $self = shift;
	my ($Ref) = @_;

# Analogous to the normal DBOBJECT GetValueHashRef - just a bit clunkier of an interface,
# though it does take care of loading the module and the like. Obviously only works for ARRS modules.

	# module = db module we want to access (r)
	# moduleid = db pk for the record we want to load (r)
	# field = specific db field we're interested in (o)

	eval 'use ARRS::' . $Ref->{'module'};
	my $Module =
		eval 'new ARRS::'
	  . $Ref->{'module'}
	  . '($self->{"dbref"}, $self->{"contact"})';

	if ( $Module->Load( $Ref->{'moduleid'} ) ) {
		if ( $Ref->{'field'} ) {
			return { $Ref->{'field'} =>
				  $Module->GetValueHashRef()->{ $Ref->{'field'} } };
		}
		else {
			return $Module->GetValueHashRef();
		}
	}
}

sub GetMode {
	my $self = shift;
	my ($Ref) = @_;

	# Given a carriername and a servicename, get the mode

	# carriername = (r)
	# servicename = (r)

	my $MT = new ARRS::MODETYPE( $self->{'dbref'}, $self->{'contact'} );

	return { modetype =>
		  $MT->GetMode( $Ref->{'carriername'}, $Ref->{'servicename'} )
	};
}

sub GetFullServiceDropdown {
	my $self = shift;
	my ($Ref) = @_;

# Gets a complete list of csids and csnames for a given sop (customer) -
# regardless of rating or anything - if the sop has a cs, it's returned

	# sopid = customerid or sopid (r)
	# customerid = customerid (r) - used for exclusions

	my $Online =
	  new ARRS::ONLINE( $self->{'dbref'}, $self->{'contact'} );
	return $Online->GetFullServiceDropdown( $Ref->{'sopid'},
		$Ref->{'customerid'} );
}

sub GetMyCarriers {
	my $self = shift;
	my ($Ref) = @_;

	# Gets a complete list of all carriers for the customer

	my $Carrier =
	  new ARRS::CARRIER( $self->{'dbref'}, $self->{'contact'} );
	return $Carrier->GetMyCarriers( $Ref->{'customerid'} );
}

sub GetCarrierList {
	my $self = shift;
	my ($Ref) = @_;

	# Gets a complete list of carriers that fall under a given sop

	# sopid = customerid or sopid (r)
	# customerid = customerid (r) - used for carrier exlusions

	my $Online =
	  new ARRS::ONLINE( $self->{'dbref'}, $self->{'contact'} );
	return $Online->GetCarrierList( $Ref->{'sopid'},
		$Ref->{'customerid'} );
}

sub GetCarrierServiceList {
    my $self = shift;
	my ($Ref) = @_;

	# Gets a complete list of services that fall under a given sop

	# sopid = customerid or sopid (r)
	# customerid = customerid (r) - used for carrier exlusions

	my $Online =
	  new ARRS::ONLINE( $self->{'dbref'}, $self->{'contact'} );
	return $Online->GetCarrierServiceList( $Ref->{'sopid'});
}

sub GetServiceTariff {
    warn "########## 4";
    my $self = shift;
    my ($Ref) = @_;

    # Gets a complete list of services that fall under a given sop

    # sopid = customerid or sopid (r)
    # customerid = customerid (r) - used for carrier exlusions

    my $Online =
      new ARRS::ONLINE( $self->{'dbref'}, $self->{'contact'} );
    return $Online->GetServiceTariff( $Ref->{'csid'});
}


sub GetShipmentCosts {
	my $self = shift;
	my ($Ref) = @_;

	# Access to the raw 'GetShipmentCosts' function

	# fromzip = (r)
	# fromstate = (r)
	# fromcountry = (r)
	# tozip = (r)
	# tostate = (r)
	# tocountry = (r)
	# weightlist = js style string containing package weights (r)
	# quantitylist = js style string containing package quantity (r)
	# dimlengthlist = js style string containing package dimlengths (o)
	# dimwidthlist = js style string containing package dimwidths (o)
	# dimheightlist = js style string containing package dimheights (o)
	# productcount = total number of product line items (r)
	# csid = default/incoming co csid (o)
	# band = rate band to use for costing

	my $CS =
	  new ARRS::CUSTOMERSERVICE( $self->{'dbref'}, $self->{'contact'} );

	$CS->Load( $Ref->{'csid'} );

	my ( $Cost, $Zone, $PackageCosts ) = $CS->GetShipmentCosts($Ref);

	return (
		{ cost => $Cost, zone => $Zone, packagecosts => $PackageCosts }
	);
}

sub GetCarrierServiceName {
	my $self = shift;
	my ($Ref) = @_;

	my $CS =
	  new ARRS::CUSTOMERSERVICE( $self->{'dbref'}, $self->{'contact'} );

	if ( $CS->Load( $Ref->{'csid'} ) ) {
		my $Service =
		  new ARRS::SERVICE( $self->{'dbref'}, $self->{'contact'} );
		my $Carrier =
		  new ARRS::CARRIER( $self->{'dbref'}, $self->{'contact'} );

		if (
			$Service->Load( $CS->GetValueHashRef()->{'serviceid'} )
			&& $Carrier->Load(
				$Service->GetValueHashRef()->{'carrierid'}
			)
		  )
		{
			return (
				{
					carriername =>
					  $Carrier->GetValueHashRef()->{'carriername'},
					servicename =>
					  $Service->GetValueHashRef()->{'servicename'}
				}
			);
		}
	}
	elsif ( $Ref->{'groupname'} && $Ref->{'servicecode'} ) {
		my $Online =
		  new ARRS::ONLINE( $self->{'dbref'}, $self->{'contact'} );
		my ( $CarrierName, $ServiceName ) =
		  $Online->GetCarrierServiceName( $Ref->{'groupname'},
			$Ref->{'servicecode'} );

		return (
			{
				carriername => $CarrierName,
				servicename => $ServiceName
			}
		);
	}

	return undef;
}

sub ExcludeCS {
	my $self = shift;
	my ($Ref) = @_;

	my $CSOverride =
	  new ARRS::CSOVERRIDE( $self->{'dbref'}, $self->{'contact'} );
	my $ExcludeCS =
	  $CSOverride->ExcludeCS( $Ref->{'customerid'}, $Ref->{'csid'} );

	return { excludecs => $ExcludeCS };
}

sub Test {
	my $self = shift;
	my ($Ref) = @_;

	return ( { test => $Ref->{'teststring'} } );
}

sub GetARRSShipmentData {
	my $self = shift;
	my ($Ref) = @_;

	my $DateDueRef		= $self->GetETADate($Ref);
	my $CostZoneRef	   = $self->GetCost($Ref);
	my $CarrierServiceRef = $self->GetCarrierServiceName($Ref);
	my $ModeRef		   = $self->GetMode($Ref);

	my %ReturnRef =
	  ( %$DateDueRef, %$CostZoneRef, %$CarrierServiceRef, %$ModeRef );

	return \%ReturnRef;
}

sub GetCustomersByCarrier {
	my $self = shift;
	my ($Ref) = @_;

	# Gets a complete list of all customers for the carrier

	my $Online =
	  new ARRS::ONLINE( $self->{'dbref'}, $self->{'contact'} );
	return $Online->GetCustomersByCarrier( $Ref->{'carrierid'} );
}

sub GetSuperCost {
	my $self = shift;
	my ($Ref) = @_;

# This interfaces with the basic vanilla CS::GetCost.  Won't work for tariff carriers -
# should probably be beefed up to use 'GetSuperCost' at some point.

	# csid = customerserviceid (r)
	# fromzip = (r)
	# fromstate = (r)
	# fromcountry = (r)
	# tozip = (r)
	# tostate = (r)
	# tocountry = (r)
	# weight = (r)
	# dimlenth = (o)
	# dimwidth = (o)
	# dimheight = (o)
	# type		 = (o) - ar/ap, defaults to ar
	# band		 = (o) - variable rate bands (currently UPS)
	# zonenumber   = (o) - if passed, will use rather than lookup
	# cwt	= (o) - explicitly grab CWT rates
	# class	= (o) - freight class

	my $CS =
	  new ARRS::CUSTOMERSERVICE( $self->{'dbref'}, $self->{'contact'} );
	$CS->Load( $Ref->{'csid'} );

	my ( $Cost, $Zone ) =
	  $CS->GetSuperCost( $Ref->{'weight'}, $Ref->{'dimlength'},
		$Ref->{'dimwidth'}, $Ref->{'dimheight'}, $Ref, );

	my $CostRef = {};

	$CostRef->{'cost'} = $Cost;
	$CostRef->{'zone'} = $Zone;

	return $CostRef;
}

sub GetDHLConfigData {
	my $self = shift;

	# Gets DHL config data from DB for use in manifest file

	my $Online =
	  new ARRS::ONLINE( $self->{'dbref'}, $self->{'contact'} );
	return $Online->GetDHLConfigData();
}

sub CalculateDHLDueDate {
	my $self = shift;
	my ($Ref) = @_;

	my $Online =
	  new ARRS::ONLINE( $self->{'dbref'}, $self->{'contact'} );
	return $Online->CalculateDHLDueDate(
		$Ref->{'servicename'},  $Ref->{'dateshipped'},
		$Ref->{'originstring'}, $Ref->{'deststring'}
	);
}

sub GetDHLUSSAC {
	my $self = shift;
	my ($Ref) = @_;

	my $Online =
	  new ARRS::ONLINE( $self->{'dbref'}, $self->{'contact'} );
	return $Online->GetDHLUSSAC( $Ref->{'postalcode'}, $Ref->{'city'},
		$Ref->{'state'} );
}

sub GetDHLINTLSAC {
	my $self = shift;
	my ($Ref) = @_;

	my $Online =
	  new ARRS::ONLINE( $self->{'dbref'}, $self->{'contact'} );
	return $Online->GetDHLINTLSAC(
		$Ref->{'postalcode'}, $Ref->{'country'},
		$Ref->{'city'},	   $Ref->{'state'}
	);
}

sub GetSOPAssListing {
	my $self = shift;
	my ($Ref) = @_;

# This interfaces with the ASSDATA::GetSOPAssListing.  Just gets a listing of all assessorials
# That a given SOP has

	# sopid = (r) - customerid

	my $AD = new ARRS::ASSDATA( $self->{'dbref'}, $self->{'contact'} );
	return $AD->GetSOPAssListing( $Ref->{'sopid'} );
}

sub GetAssCharge {
	my $self = shift;
	my ($Ref) = @_;

 # Given a CSID, ass_name, and weight, get an assessorial charge value
 # csid = (r) - customerserviceid
 # ass_name = (r)
 # weight = (o)
 # quantity = (o)
 # freight_cost = (o)
 # dateshipped = (o)
 # ownertypeid = (o) - specify an ownertype 3 = service, 4 = customerservice

	my $CS =
	  new ARRS::CUSTOMERSERVICE( $self->{'dbref'}, $self->{'contact'} );

	$CS->Load( $Ref->{'csid'} );

	my $Value = $CS->GetAssValue(
		'ar',				   $Ref->{'ass_name'},
		$Ref->{'weight'},	   $Ref->{'quantity'},
		$Ref->{'freight_cost'}, $Ref->{'dateshiped'},
		$Ref->{'ownertypeid'},  $Ref->{'customerid'},
	);

	my $ValueRef = {};
	$ValueRef->{'value'} = $Value;

	return $ValueRef;
}

sub GetBand {
	my $self = shift;
	my ($Ref) = @_;

  # Given a CSID, type (AP/AR), and dollar amount, get carrier rate band
  # csid = (r) - customerserviceid
  # type = (r) - ar or ap (probably superfluous)
  # date = (r) - invoice date

	my $CS =
	  new ARRS::CUSTOMERSERVICE( $self->{'dbref'}, $self->{'contact'} );

	$CS->Load( $Ref->{'csid'} );

	my ( $band, $dollar_amount ) =
		  $CS->GetBand( $Ref->{'type'}, $Ref->{'date'}, );

		my $band_ref = {};
		$band_ref->{'band'} = $band;

		return ( { band => $band, dollar_amount => $dollar_amount } );
	}

sub SaveInvoiceData {
	my $self = shift;
	my ($Ref) = @_;

  # Save invoice band data to invoicedata table for future band calculations
  # sopid = (r) - sopid/customerid for a given invoice file
  # carrierid = (r) - carrier that the invoice belongs to
  # batchnumber = (r) - HALO batch number
  # invoicedate = (r)
  # freightcharges = (r)

	my $ID =
	  new ARRS::INVOICEDATA( $self->{'dbref'}, $self->{'contact'} );

	my $success = $ID->CreateOrLoadCommit($Ref);

	$self->{'dbref'}->commit();

	return ( { success => $success } );
}

sub GetAssCode {
	my $self = shift;
	my ($Ref) = @_;

	# Given a CSID, ass_name, get the asses asscode
	# csid = (r) - customerserviceid
	# ass_name = (r)

	my $CS =
	  new ARRS::CUSTOMERSERVICE( $self->{'dbref'}, $self->{'contact'} );

	$CS->Load( $Ref->{'csid'} );

	my $Code = $CS->GetAssCode( $Ref->{'csid'}, $Ref->{'ass_name'}, );

	return $Code;
}

1;
