package IntelliShip::Controller::Customer::Order;
use Moose;
use Data::Dumper;
use namespace::autoclean;

BEGIN { extends 'IntelliShip::Controller::Customer'; }

sub get_order
	{
	my $self = shift;
=cut
	my $c = $self->context;
	my $params = $c->req->params;
	$c->log->debug("\n get customer order");

	$DataRef->{'addressid'} = undef;

	if ( !defined($DataRef) || $DataRef eq '' )
		{
		$DataRef = $self->GetValueparams();
		}

	# Undef any incoming coid...we need to get the 'current' for non-quotes, and make a new for quotes
	undef($DataRef->{'coid'});

	# Only do this for non-quote orders.  Quotes get new entry every time through
	if ( !$DataRef->{'cotypeid'} || $DataRef->{'cotypeid'} != 10 )
		{
		# This should make things backwards compatible with the (unused?) PO types.
		my $order_only = ( $DataRef->{'cotypeid'} && $DataRef->{'cotypeid'} == 1 ) ? 1 : 0;

		# See if we have an existing co with the specified ordernumber
		my ($ExistingCOID) = $self->GetCurrentCOID(
			$DataRef->{'ordernumber'},
			$DataRef->{'customerid'},
			$DataRef->{'cotypeid'},
			undef,
			undef,
			$order_only
			);

		# If we found a coid for our order number, set the coid for our current co to the existing one.
		# Update the 'datecreated', too.
		if ( defined($ExistingCOID) && $ExistingCOID ne '' )
			{
			$self->UnCombineOrders($ExistingCOID,$DataRef->{'contactid'});

			$DataRef->{'datecreated'} = $self->{'dbref'}->gettimestamp();
			$DataRef->{'coid'} = $ExistingCOID;
			}
		}

	# Default the 'keep' field to 0
	if ( !defined($DataRef->{'keep'}) || $DataRef->{'keep'} eq '' )
		{
		$DataRef->{'keep'} = 0;
		}

	# Get mode
	if ( defined($DataRef->{'extcarrier'}) && $DataRef->{'extservice'} ne '' )
		{
		($DataRef->{'mode'}) = &GetMode($DataRef->{'extcarrier'},$DataRef->{'extservice'});
		}

	# Strip out odd punctuation and abbreviate common words
	my $StringSubstitution = new STRINGSUBSTITUTION($self->{'dbref'});
	$DataRef->{'description'} = $StringSubstitution->SubstituteString($DataRef->{'description'});
	$DataRef->{'contactname'} = $StringSubstitution->SubstituteString($DataRef->{'contactname'});

	# Truncate specific field lengths (for carrier acceptance, mainly)
	if ( defined($DataRef->{'extcd'}) && $DataRef->{'extcd'} ne '' )
		{
		$DataRef->{'extcd'} = substr($DataRef->{'extcd'},0,35);
		}

	#if ( defined($DataRef->{'description'}) && $DataRef->{'description'} ne '' )
	#{
	#	$DataRef->{'description'} = substr($DataRef->{'description'},0,35);
	#}

	my $Address = new ADDRESS($self->{'dbref'},$self->{'customer'});

	$DataRef->{'addressid'} = $Address->NewCreateOrLoadCommit({
		addressname => $DataRef->{'addressname'},
		address1    => $DataRef->{'address1'},
		address2    => $DataRef->{'address2'},
		city        => $DataRef->{'addresscity'},
		state       => $DataRef->{'addressstate'},
		zip         => $DataRef->{'addresszip'},
		country     => $DataRef->{'addresscountry'},
		});

	# Sort out dropship address/id
	if ($DataRef->{'dropname'} || $DataRef->{'dropaddress1'} || $DataRef->{'dropaddress2'} ||
		$DataRef->{'dropcity'} || $DataRef->{'dropstate'} || $DataRef->{'dropzip'} ||
		$DataRef->{'dropcountry'})
		{
		$DataRef->{'dropaddressid'} = $Address->NewCreateOrLoadCommit({
			addressname => $DataRef->{'dropname'},
			address1    => $DataRef->{'dropaddress1'},
			address2    => $DataRef->{'dropaddress2'},
			city        => $DataRef->{'dropcity'},
			state       => $DataRef->{'dropstate'},
			zip         => $DataRef->{'dropzip'},
			country     => $DataRef->{'dropcountry'},
		});
		}

	# Sort out return address/id
	if ( $DataRef->{'rtaddr'} )
		{
		my @rta = split(/\|/,$DataRef->{'rtaddr'});
		$DataRef->{'rtphone'} = $rta[7];
		$DataRef->{'rtcontact'} = $rta[8];

		$DataRef->{'rtaddressid'} = $Address->NewCreateOrLoadCommit({
			addressname => $rta[0],
			address1    => $rta[1],
			address2    => $rta[2],
			city        => $rta[3],
			state       => $rta[4],
			zip         => $rta[5],
			country     => $rta[6],
			});
		}

	if ( defined($DataRef->{'usingaltsop'}) && $DataRef->{'usingaltsop'} eq '0' )
		{
		$DataRef->{'usealtsop'} = 0;
		}

	# Set default cotypeid (Default to vanilla 'Order')
	$DataRef->{'cotypeid'} = !$DataRef->{'cotypeid'} ? 1 : $DataRef->{'cotypeid'};

	# Sort out volume/density/class issues - if we have volume (and of course weight), and nothing
	# else, calculate density.  If we have density and no class, get class.
	# Volume assumed to be in cubic feet - density would of course be #/cubic foot
	if ( $DataRef->{'estimatedweight'} && $DataRef->{'volume'} && !$DataRef->{'density'} )
		{
		$DataRef->{'density'} = int($DataRef->{'estimatedweight'}/$DataRef->{'volume'});
		}

	if ( $DataRef->{'density'} && !$DataRef->{'class'} )
		{
		$DataRef->{'class'} = GetFreightClassFromDensity($DataRef->{'estimatedweight'},undef,undef,undef,$DataRef->{'density'});
		}

	if ( !$DataRef->{'consolidationtype'} )
		{
		$DataRef->{'consolidationtype'} = 0;
		}

	# If this order has non-voided shipments, keep it's status as 'shipped' (statusid = 5)
	if ( $DataRef->{'coid'} && $self->Load($DataRef->{'coid'}) && $self->GetShipmentCount() > 0 )
		{
		$DataRef->{'statusid'} = 5;
		}

	# Sort out 'Other' carrier nonsense
	if ( $DataRef->{'customerserviceid'} && $DataRef->{'customerserviceid'} =~ /^OTHER_(\w{13})/ )
		{
		my $Other = new OTHER($self->{'dbref'}, $self->{'customer'});
		$Other->Load($1);
		$DataRef->{'extcarrier'} = "Other - " . $Other->GetValueparams()->{'othername'};
		}

	return $self->SUPER::CreateOrLoadCommit($DataRef);
=cut
	}

sub save_order
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;
=as
	my $CO = new CO($self->{'dbref'}->{'aos'}, $self->{'customer'});

	my $OrderRef = {};
	$OrderRef->{'customerid'} = $self->{'customer'}->GetValueparams()->{'customerid'};
	$OrderRef->{'contactid'} = $params->{'contactid'};
	$OrderRef->{'statusid'} = 1;
	$OrderRef->{'ordernumber'} = $params->{'ordernumber'};
	$OrderRef->{'datetoship'} = $params->{'datetoship'};
	$OrderRef->{'dateneeded'} = $params->{'dateneeded'};
	$OrderRef->{'estimatedweight'} = $params->{'aggregateweight'};
	$OrderRef->{'description'} = $params->{'description'};
	$OrderRef->{'extloginid'} = $self->{'customer'}->GetValueparams()->{'username'};
	$OrderRef->{'extcustnum'} = $params->{'custnum'};
	$OrderRef->{'unitquantity'} = $params->{'quantity'};
	$OrderRef->{'contactname'} = $params->{'contactname'};
	$OrderRef->{'contactphone'} = $params->{'contactphone'};
	$OrderRef->{'extcd'} = $params->{'description1'};
	$OrderRef->{'dimlength'} = $params->{'dimlength1'};
	$OrderRef->{'dimwidth'} = $params->{'dimwidth1'};
	$OrderRef->{'dimheight'} = $params->{'dimheight1'};
	$OrderRef->{'class'} = $params->{'class1'};
	$OrderRef->{'department'} = $params->{'department'};
	$OrderRef->{'ponumber'} = $params->{'ponumber'};
	$OrderRef->{'hazardous'} = $params->{'hazardous'};
	$OrderRef->{'contacttitle'} = $params->{'contacttitle'};
	$OrderRef->{'datereceived'} = $params->{'datereceived'};
	$OrderRef->{'daterouted'} = $params->{'daterouted'};
	$OrderRef->{'datepacked'} = $params->{'datepacked'};
	$OrderRef->{'shipmentnotification'} = $params->{'shipmentnotification'};
	$OrderRef->{'deliverynotification'} = $params->{'deliverynotification'};
	$OrderRef->{'extid'} = $params->{'extid'};
	$OrderRef->{'custref2'} = $params->{'custref2'};
	$OrderRef->{'custref3'} = $params->{'custref3'};
	$OrderRef->{'quantityxweight'} = $params->{'quantityxweight'};

	$OrderRef->{'addressname'} = $params->{'addressname'};
	$OrderRef->{'address1'} = $params->{'address1'};
	$OrderRef->{'address2'} = $params->{'address2'};
	$OrderRef->{'addresscity'} = $params->{'addresscity'};
	$OrderRef->{'addressstate'} = $params->{'addressstate'};
	$OrderRef->{'addresszip'} = $params->{'addresszip'};
	$OrderRef->{'addresscountry'} = $params->{'addresscountry'};

	$OrderRef->{'dropname'} = $params->{'dropname'};
	$OrderRef->{'dropaddress1'} = $params->{'dropaddress1'};
	$OrderRef->{'dropaddress2'} = $params->{'dropaddress2'};
	$OrderRef->{'dropcity'} = $params->{'dropcity'};
	$OrderRef->{'dropstate'} = $params->{'dropstate'};
	$OrderRef->{'dropzip'} = $params->{'dropzip'};
	$OrderRef->{'dropcountry'} = $params->{'dropcountry'};
	$OrderRef->{'dropcontact'} = $params->{'dropcontact'};
	$OrderRef->{'dropphone'} = $params->{'dropphone'};

	$OrderRef->{'isdropship'} = $params->{'isdropship'};
	$OrderRef->{'isinbound'} = $params->{'isinbound'};

	$OrderRef->{'clientdatecreated'} = $params->{'clientdatecreated'};

	$OrderRef->{'coid'} = $params->{'coid'};

	$OrderRef->{'cotypeid'} = $params->{'action'} eq 'clearquote' ? 10 : 1;

	if
	(
		$params->{'loginlevel'} == 35 ||
		$params->{'loginlevel'} == 40 ||
		( $params->{'cotypeid'} && $params->{'cotypeid'} == 2 )
	)
	{
		$OrderRef->{'cotypeid'} = 2;
	}		

	if ( defined($params->{'insurance'}) && $params->{'insurance'} > 0 )
	{
		$OrderRef->{'estimatedinsurance'} = $params->{'insurance'};
	}

	if
	(
		( defined($params->{'freightinsurance'}) && $params->{'freightinsurance'} > 0 )
		&&
		( defined($params->{'insurance'}) && $params->{'insurance'} > 0 )
		&&
		$params->{'freightinsurance'} > $params->{'insurance'}
	)
	{
		$OrderRef->{'estimatedinsurance'} = $params->{'freightinsurance'};
	}

	$OrderRef->{'keep'} = $params->{'keep'} ? $params->{'keep'} : 0;

	if
	(
		defined($params->{'customerserviceid'}) &&
		$params->{'customerserviceid'} ne '' &&
		$params->{'customerserviceid'} ne '0'
	)
	{
		($OrderRef->{'extcarrier'},$OrderRef->{'extservice'}) = &GetCarrierServiceName($params->{'customerserviceid'});
	}
	else
	{
		undef($OrderRef->{'extcarrier'});
		undef($OrderRef->{'extservice'});
		undef($OrderRef->{'mode'});
	}

	# Hazardous
	if ( !$params->{'hazardous'} ) { $OrderRef->{'hazardous'} = 0; }

	# Security type
	if ( !$params->{'securitytype'} ) { $OrderRef->{'securitytype'} = 0; }

	# Combine
	if ( !$params->{'combine'} ) { $OrderRef->{'combine'} = 0; }
	
	if ( $params->{'consolidatedorder'} && $params->{'consolidationtype'} eq '2' )
	{
		$OrderRef->{'consolidationtype'} = 2;
	}
	else
	{
		my $C = new CO($self->{'dbref'}->{'aos'}, $self->{'customer'});
		$C->Load($OrderRef->{'coid'});
		$OrderRef->{'consolidationtype'} = $C->GetValueparams()->{'consolidationtype'};
	}
	
#WarhRefValues($OrderRef);
	$CO->CreateOrLoadCommit($OrderRef);

	my $COValues = $CO->GetValueparams();
	my $COID = $COValues->{'coid'};
#warOID: $COID";
	# Pop the order number with the coid, if it didn't get set.  Should only be on Quote type orders.
	if ( !$COValues->{'ordernumber'} && $COValues->{'cotypeid'} == 10 )
	{
		$OrderRef->{'coid'} = $COID;
		$OrderRef->{'ordernumber'} = $COID;

		$CO->CreateOrLoadCommit($OrderRef);
	}

	# Preserve contactid
	my $real_contactid = $params->{'contactid'};

	$params = {%$params,%$COValues};
	
	$params->{'contactid'} = $real_contactid;

	# Deal with packages/products.
	# Delete packages & products for combined coids
	if ( $params->{'consolidatedorder'} )
	{
		for ( my $i = 1; $i <= $params->{'productcount'}; $i ++ )
		{
			# Only packages are relevent for normal consolidates, skip products
			if ( !$params->{'cotypeid'} || $params->{'cotypeid'} != '2' )
			{
				next if $params->{"datatypeid$i"} == 2000;
			}

			my $ComboCO = new CO($self->{'dbref'}->{'aos'}, $self->{'customer'});
			$ComboCO->Load($params->{"consolidatedcoid$i"});
			$ComboCO->DeleteItems(undef,$params->{'pseudoscreen'});

			my $ConsolidationType = $ComboCO->GetValueparams()->{'consolidationtype'};
        my $Status = $ComboCO->GetValueparams()->{'statusid'};
 			#warn  $params->{"consolidatedcoid$i"} . " |$params->{'consolidationtype'}|$ConsolidationType|$Status|";

			if ( defined($ConsolidationType) && $Status eq '200' )
        {
        	$ComboCO->SetValuesArray('consolidationtype', $ConsolidationType);
        }
			elsif ( defined($ConsolidationType) && (!defined($params->{'consolidationtype'}) || $params->{'consolidationtype'} eq '') )
        {
        	$ComboCO->SetValuesArray('consolidationtype', $ConsolidationType);
        }
        else
        {
        	$ComboCO->SetValuesArray('consolidationtype', $params->{'consolidationtype'});
        }

        $ComboCO->Commit();
		}
	}
	# Delete packages & products for order
	else
	{
		$CO->DeleteItems(undef,$params->{'pseudoscreen'});
	}

	my $PPD = new PACKPRODATA($self->{'dbref'}->{'aos'}, $self->{'customer'});
	$PPD->SaveItems($params,1000);

	# Save order assessorials
	$self->SaveAssessorials($params,$COID,1000);

	if ( $params->{'action2'} eq 'uncombine' )
	{
		my $CO = new CO($self->{'dbref'}->{'aos'}, $self->{'customer'});
		$CO->UnCombine($params->{'uncombinecoid'},$params->{'coid'},$params->{'ordernumber'},$params->{'contactid'});
	}
	elsif ( $params->{'action2'} eq 'uncombine/void' )
	{
		my $CO = new CO($self->{'dbref'}->{'aos'}, $self->{'customer'});
		$CO->Load($params->{'coid'});
		my (@CombinedCOIDs) = $CO->GetCombinedCOIDs();
	
		foreach my $CombinedCOID (@CombinedCOIDs)
		{
			my $CCO = new CO($self->{'dbref'}->{'aos'}, $self->{'customer'});
			$CCO->UnCombine($CombinedCOID,$params->{'coid'},$params->{'ordernumber'},$params->{'contactid'});
		}
	
		$CO->VoidCO($params->{'contactid'});
	}

	return $COID;
=cut
	}

__PACKAGE__->meta->make_immutable;

1;
