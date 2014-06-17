package IntelliShip::Controller::Customer::SupplyOrdering;
use Moose;
use Data::Dumper;
use IntelliShip::Email;
use namespace::autoclean;

BEGIN { extends 'IntelliShip::Controller::Customer::Order'; }

=head1 NAME

IntelliShip::Controller::Customer::SupplyOrdering - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

my $COMPANY_EMAILS = {
	FEDEX => 'focmemteam3b@fedex.com',
	UPS => 'customer.service@ups.com',
	};

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;
	my $params = $c->req->params;

    #$c->response->body('Matched IntelliShip::Controller::Customer::SupplyOrdering in Customer::SupplyOrdering.');

	my $do_value = $params->{'do'} || '';

	if ($do_value eq 'send')
		{
		$self->send_email;
		}
	else
		{
		$self->setup_supply_ordering;
		}
}

sub setup_supply_ordering :Private
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;
	my $Contact = $self->contact;

	my $CustomerID = $self->customer->customerid;
	my $SQL = "SELECT DISTINCT carrier FROM productsku WHERE carrier <> ''";
	my $sth = $self->myDBI->select($SQL);

	my $customerCarrierDetails = $self->API->get_carrier_list($self->customer->get_sop_id,$CustomerID);

	my %customerCarriers = map { $_ => 1 } split(/\t/,$customerCarrierDetails->{'cnames'});

	my $first_carrier;
	my $carrier_loop = [];
	foreach (my $row=0; $row < $sth->numrows; $row++)
		{
		my $data = $sth->fetchrow($row);

		$data->{carrier} =~ s/^\s+//;
		$data->{carrier} =~ s/\s+$//;

		next unless $data->{carrier};
		next unless $customerCarriers{$data->{carrier}};

		unless ($first_carrier)
			{
			$first_carrier = $data->{carrier};
			$data->{selected} = 1;
			}

		push(@$carrier_loop, { name => $data->{carrier}, value => $data->{carrier} });
		}

	$c->log->debug("... Total carriers found: " . @$carrier_loop);

	$SQL = "SELECT * FROM productsku WHERE carrier = '$first_carrier'";
	$c->log->debug("... SQL 1: " . $SQL);
	$sth = $self->myDBI->select($SQL);

	$c->log->debug("... Total Productsku found: " . $sth->numrows);

	my $ToAddress = $Contact->address;
	$ToAddress = $self->customer->address if !$ToAddress && !$Contact->get_contact_data_value('myonly');

	my $tocontact = ($Contact->lastname ? $Contact->firstname . ' ' .  $Contact->lastname : $Contact->firstname);

	$c->stash(carrier_loop => $carrier_loop);
	$c->stash(toAddress => $ToAddress);
	$c->stash(tocontact => $tocontact);
	$c->stash(tophone => $Contact->phonebusiness);
	$c->stash(todepartment => $Contact->department);
	$c->stash(toemail => $Contact->email);
	$c->stash(ordernumber => $self->get_auto_order_number);
	$c->stash(datetoship => IntelliShip::DateUtils->current_date('/'));
	$c->stash(countrylist_loop => $self->get_select_list('COUNTRY'));
	$c->stash(customerlist_loop => $self->get_select_list('ADDRESS_BOOK_CUSTOMERS'));

	$c->stash(requiredfield_list => [
			{ name => 'toname',  details => "{ minlength: 2 }"},
			{ name => 'toaddress1',  details => "{ minlength: 2 }"},
			{ name => 'tocity',  details => "{ minlength: 2 }"},
			{ name => 'tostate',  details => "{ minlength: 2 }"},
			{ name => 'tozip',  details => "{ minlength: 2 }"},
			{ name => 'tocountry',  details => "{ minlength: 2 }"},
			{ name => 'tocontact', details => "{ minlength: 2 }"},
			{ name => 'tophone', details => "{ phone: true }"},
			{ name => 'toemail', details => "{ email: true }"},
			{ name => 'todepartment', details => "{ minlength: 2 }"},
			{ name => 'supplyquantity',  details => "{ numeric: true }"},
			]);

	$c->stash(template => "templates/customer/supply-ordering.tt");
	}

sub send_email :Private
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	return if !$params->{'supplyquantity'} || $params->{'supplyquantity'} == 0;

	my $Contact = $self->contact;

	my $carrier = uc($params->{'carrier'});

	my $deliverEmail = $params->{'toemail'};
	$deliverEmail =~ s/\s+|\t+//g;

	my $UserEmail = IntelliShip::Email->new();
	my $CompanyEmail = IntelliShip::Email->new();

	## Loop to generate shipment details
	my $productskudetail_loop = [];
	foreach my $key (keys %$params)
		{
		next unless $key =~ /^quantity_(.+)/;
		next unless $params->{$key};

		my $ProductSku = $c->model('MyDBI::Productsku')->find({ productskuid => $1 });

		next unless $ProductSku;
		my $productskudetails = { Qty => $params->{$key}, Part => $ProductSku->customerskuid , Description => $ProductSku->description};

		push(@$productskudetail_loop, $productskudetails);
		}

	$c->stash->{productskudetail_loop} = $productskudetail_loop;
	my $sql = "SELECT DISTINCT(webaccount) FROM customerservice INNER JOIN service ON service.serviceid = customerservice.serviceid INNER JOIN carrier ON carrier.carrierid = service.carrierid WHERE lower(carrier.carriername) = lower('$carrier') AND customerid = '" . $Contact->customerid . "' AND webaccount <> ''";
	my $sth = $c->model('MyArrs')->select($sql);
	my $WebAccount = $sth->fetchrow(0)->{'webaccount'} if $sth->numrows;

	## From Name
	$UserEmail->from_name('Intelliship');
	$UserEmail->from_address('supplies@motorolasolutions.com');

	$CompanyEmail->from_name('Intelliship');
	$CompanyEmail->from_address('supplies@motorolasolutions.com');

	#Address detail
	$c->stash->{toname}       = $params->{'toname'};
	$c->stash->{toaddress1}   = $params->{'toaddress1'};
	$c->stash->{toaddress2}   = $params->{'toaddress2'};
	$c->stash->{tocity}       = $params->{'tocity'};
	$c->stash->{tostate}      = $params->{'tostate'};
	$c->stash->{tozip}        = $params->{'tozip'};
	$c->stash->{tocountry}    = $params->{'tocountry'};
	$c->stash->{tocontact}    = $params->{'tocontact'};
	$c->stash->{todepartment} = $params->{'todepartment'};
	$c->stash->{tophone}      = $params->{'tophone'};

	## Send To
	$UserEmail->add_to($Contact->email) if IntelliShip::Utils->is_valid_email($Contact->email);
	$UserEmail->add_to($params->{'toemail'}) if IntelliShip::Utils->is_valid_email($params->{'toemail'});

	$CompanyEmail->add_to($COMPANY_EMAILS->{$carrier});
	$CompanyEmail->add_to('tsharp@engagetechnology.com');

	## Subject
	$UserEmail->subject("NOTICE: $carrier, Supply Order");
	$CompanyEmail->subject("REQUEST: $carrier, Supply Order");

	$c->stash->{carrier}    = $carrier;
	$c->stash->{datetoship} = $params->{'datetoship'};
	$c->stash->{WebAccount}      = $WebAccount;

	$c->stash->{UserEmail} = 1;
	$c->stash->{CompanyEmail} = 0;

	$UserEmail->body($UserEmail->body . $c->forward($c->view('Email'), "render", [ 'templates/email/supply-order-notification.tt' ]));
	if ($UserEmail->send)
		{
		$self->context->log->debug("Supply Ordering notification User email successfully sent");
		}

	$c->stash->{CompanyEmail} = 1;
	$c->stash->{UserEmail} = 0;
	$CompanyEmail->body($CompanyEmail->body . $c->forward($c->view('Email'), "render", [ 'templates/email/supply-order-notification.tt' ]));
	if ($CompanyEmail->send)
		{
		$self->context->log->debug("Supply Ordering notification CompanyEmail successfully sent");
		}

	#$c->log->debug("UserEmail: " . $UserEmail->to_string);
	#$c->log->debug("CompanyEmail: " . $CompanyEmail->to_string);

	$self->setup_supply_ordering;
	}

sub ajax :Local
	{
	my ( $self, $c ) = @_;
	my $params = $c->req->params;

	if ($params->{'type'} eq 'HTML')
		{
		$self->get_HTML;
		}
	}

sub get_HTML :Private
	{
	my $self = shift;
	my $c = $self->context;

	my $action = $c->req->param('action');
	if ($action eq 'get_carrier_productsku')
		{
		$self->get_carrier_productsku;
		}
	}

sub get_carrier_productsku :Private
	{
	my $self = shift;
	my $c = $self->context;

	my $params = $c->req->params;
	my @arr = $c->model('MyDBI::Productsku')->search({ carrier => $params->{'carrier'} });

	$c->log->debug("... Total Productsku found: " . @arr);

	my $productsku_loop = [];
	foreach my $Productsku (@arr)
		{
		my $data = $Productsku->{_column_data};
		my $img = '/static/branding/engage/images/sku/' . lc($params->{carrier}) . '/' . $Productsku->customerskuid . '.gif';
		if (-e IntelliShip::MyConfig->branding_file_directory . '/engage/images/sku/' . lc($params->{carrier}) . '/' . $Productsku->customerskuid . '.gif')
			{
			$data->{SRC} = $img;
			}

		push(@$productsku_loop, $data);
		}

	$c->stash(CARRIER_PRODUCT_SKU => 1);
	$c->stash(productsku_loop => $productsku_loop);
	$c->stash(template => "templates/customer/supply-ordering-ajax.tt");
	}

=encoding utf8

=head1 AUTHOR

root

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
