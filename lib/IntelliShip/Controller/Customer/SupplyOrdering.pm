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

	my $CustomerID = $self->customer->customerid;
	my $SQL = "SELECT DISTINCT carrier FROM productsku WHERE customerid = '$CustomerID'";
	my $sth = $self->myDBI->select($SQL);

	my $first_carrier;
	my $carrier_loop = [];
	foreach (my $row=0; $row < $sth->numrows; $row++)
		{
		my $data = $sth->fetchrow($row);
		next unless $data->{carrier};
		$data->{carrier} =~ s/^\s+//;
		$data->{carrier} =~ s/\s+$//;
		$first_carrier = $data->{carrier} unless $first_carrier;
		push(@$carrier_loop, { name => $data->{carrier}, value => $data->{carrier} });
		}

	$c->log->debug("... Total carriers found: " . @$carrier_loop);

	my @arr = $c->model('MyDBI::Productsku')->search({ customerid => $CustomerID, carrier => $first_carrier });

	$c->log->debug("... Total Productsku found: " . @arr);

	my $productsku_loop = [];
	foreach my $Productsku (@arr)
		{
		my $data = $Productsku->{_column_data};
		my $img = '/static/branding/engage/images/sku/fedex/' . $Productsku->customerskuid . '.jpg';
		if (-e IntelliShip::MyConfig->branding_file_directory . '/engage/images/sku/fedex/' . $Productsku->customerskuid . '.jpg')
			{
			$data->{SRC} = $img;
			}

		push(@$productsku_loop, $data);
		}

	$c->stash(carrier_loop => $carrier_loop);
	$c->stash(productsku_loop => $productsku_loop);
	$c->stash(toAddress => $self->customer->address);
	$c->stash(ordernumber => $self->get_auto_order_number);
	$c->stash(datetoship => IntelliShip::DateUtils->current_date('/'));
	$c->stash(countrylist_loop => $self->get_select_list('COUNTRY'));
	$c->stash(customerlist_loop => $self->get_select_list('ADDRESS_BOOK_CUSTOMERS'));

	$c->stash(requiredfield_list => [
			{ name => 'toname',  details => "{ minlength: 2 }"},
			{ name => 'supplyquantity',  details => "{ numeric: true }"},
			{ name => 'carrier', details => "{ minlength: 2 }"},
			{ name => 'toemail', details => "{ email: false }"},
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

	my $deliverEmail = $params->{'toemail'};
	$deliverEmail =~ s/\s+|\t+//g;

	my $UserEmail = IntelliShip::Email->new();
	my $CompanyEmail = IntelliShip::Email->new();

	## Start Body
	$UserEmail->add_line('<PRE>');
	$CompanyEmail->add_line('<PRE>');

	## Header
	$UserEmail->add_line(qq~Your order for supplies has been send to FEDEX on $params->{'datetoship'}.\nThank You\n\n~);
	$CompanyEmail->add_line(qq~Below is an order for FEDEX supplies, requested on $params->{'datetoship'}.\nThank You\n\n~);

	$UserEmail->add_line(qq~SHIP TO:\t\t$params->{'toname'}\n\t\t\t$params->{'toaddress1'}, $params->{'toaddress2'}\n\t\t\t$params->{'tocity'}, $params->{'tostate'} $params->{'tozip'} $params->{'tocountry'}\n\t\t\t$params->{'tocontact'} $params->{'todepartment'}\n\t\t\t$params->{'tophone'}\n~);
	$CompanyEmail->add_line(qq~SHIP TO:\t\t$params->{'toname'}\n\t\t\t$params->{'toaddress1'}, $params->{'toaddress2'}\n\t\t\t$params->{'tocity'}, $params->{'tostate'} $params->{'tozip'} $params->{'tocountry'}\n\t\t\t$params->{'tocontact'} $params->{'todepartment'}\n\t\t\t$params->{'tophone'}\n~);

	$UserEmail->add_line(qq~\nQty\t\tPart\#\t\tDescription\n-------\t\t------------\t--------------------------------------~);
	$CompanyEmail->add_line(qq~\nQty\t\tPart\#\t\tDescription\n-------\t\t------------\t--------------------------------------~);

	## Loop to generate shipment details
	foreach my $key (keys %$params)
		{
		next unless $key =~ /^quantity_(.+)/;
		next unless $params->{$key};

		my $ProductSku = $c->model('MyDBI::Productsku')->find({ productskuid => $1 });

		next unless $ProductSku;

		my $productskudetails = "\n" . $params->{$key} . "\t\t" . $ProductSku->customerskuid . "\t\t" . $ProductSku->description;

		$UserEmail->add_line($productskudetails);
		$CompanyEmail->add_line($productskudetails);
		}

	my $carrier = uc($params->{'carrier'});

	## Footer
	$UserEmail->add_line(qq~\n\n\n***************************************\n** This email is not authorized for redistribution **\n***************************************~);
	$CompanyEmail->add_line(qq~\n\n\n*****************************************\n** This email is not authorized for redistribution      **\n** The confidential $params->{'toname'} $carrier **\n** Acct\# is 494036924 and cannot be disclosed          **\n** verbally or electronically                                                 **\n*****************************************~);

	## END Body
	$UserEmail->add_line('</PRE>');
	$CompanyEmail->add_line('</PRE>');

	## From Name
	$UserEmail->from_name('Intelliship');
	$UserEmail->from_address('supplies@motorolasolutions.com');

	$CompanyEmail->from_name('Intelliship');
	$CompanyEmail->from_address('supplies@motorolasolutions.com');

	## Send To
	$UserEmail->add_to($Contact->email) if IntelliShip::Utils->is_valid_email($Contact->email);
	$UserEmail->add_to($params->{'toemail'}) if IntelliShip::Utils->is_valid_email($params->{'toemail'});

	$CompanyEmail->add_to('focmemteam3b@fedex.com');
	$CompanyEmail->add_to('tsharp@engagetechnology.com');

	## Subject
	$UserEmail->subject("NOTICE: $carrier, Supply Order");
	$CompanyEmail->subject("REQUEST: $carrier, Supply Order");

	## Send email
	$UserEmail->send;
	$CompanyEmail->send;

	$c->log->debug("UserEmail: " . $UserEmail->to_string);
	$c->log->debug("CompanyEmail: " . $CompanyEmail->to_string);

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
	my @arr = $c->model('MyDBI::Productsku')->search({ customerid => $self->customer->customerid, carrier => $params->{'carrier'} });

	$c->log->debug("... Total Productsku found: " . @arr);

	my $productsku_loop = [];
	foreach my $Productsku (@arr)
		{
		my $data = $Productsku->{_column_data};
		my $img = '/static/branding/engage/images/sku/fedex/' . $Productsku->customerskuid . '.jpg';
		if (-e IntelliShip::MyConfig->branding_file_directory . '/engage/images/sku/fedex/' . $Productsku->customerskuid . '.jpg')
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
