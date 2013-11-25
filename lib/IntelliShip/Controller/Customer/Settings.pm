package IntelliShip::Controller::Customer::Settings;
use Moose;
use Data::Dumper;
use IntelliShip::Email;
use IntelliShip::MyConfig;
use namespace::autoclean;

BEGIN { extends 'IntelliShip::Controller::Customer'; }

=head1 NAME

IntelliShip::Controller::Customer::Settings - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    #$c->response->body('Matched IntelliShip::Controller::Customer::Settings in Customer::Settings.');

	$c->log->debug("DISPLAY SETTING LINKS");

	## Display settings
	my $settings = [
				{ name => 'Change Password', url => '/customer/settings/changepassword'},
				{ name => 'Sku Management', url => '/customer/settings/skumanagement'},
			];

	$c->stash->{settings_loop} = $settings;
	$c->stash(template => "templates/customer/settings.tt");
}

sub changepassword :Local
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	if (length $params->{'oldpassword'} and
		length $params->{'newpassword1'} and
		$params->{'newpassword1'} eq $params->{'newpassword2'})
		{
		$self->update_password;
		}
	else
		{
		$c->stash->{CHANGE_PASSWORD_SETUP} = 1;
		}

	$c->stash(template => "templates/customer/settings.tt");
	}

sub update_password :Private
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	my $Contact = $self->contact;
	my $Customer = $self->customer;

	$c->log->debug("Contact->password: " . $Contact->password);
	$c->log->debug("Customer->password: " . $Customer->password);

	if ($params->{'oldpassword'} ne $Contact->password)
		{
		$c->stash->{ERR_MESSAGE} = "Old password isn't valid";
		$c->stash->{CHANGE_PASSWORD_SETUP} = 1;
		}
	else
		{
		$Contact->password($params->{'newpassword1'});
		$Customer->password($params->{'newpassword1'});

		$Contact->update;
		$Customer->update;

		my $customername = $Customer->customername;
		my $customerdomain = $Customer->username;
		my $username = $Contact->username;
		my $fullname = $Contact->full_name;

		# don't add a domain if it looks like they are an old style contact ie TX-VOYAGER
		my $who;
		if ( $customerdomain ne $username )
			{
			$who = $customerdomain . "/" . $username;
			}
		else
			{
			$who = $username;
			}

		my $Email = IntelliShip::Email->new;
		$Email->send_to($Contact->email ? $Contact->email : $Customer->email);
		$Email->allow_send_from_dev(1);

		my $body = "Login Password Changed, " . $customername . " " . $fullname . " (" . IntelliShip::DateUtils->american_date_time . " by " . $who . ")";
		$Email->add_line('');
		$Email->add_line('');

		$Email->set_company_template;
		#$Email->send_now;

		$c->stash->{MESSAGE} = "Your password has been successfully updated!";

		$c->detach("index",$params);
		}
	}

sub skumanagement :Local
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	$c->log->debug("SKU MANAGEMENT");

	my $WHERE = {};
	#$WHERE->{customerid} = $self->customer->customerid;
	my $ps_resultset = $c->model('MyDBI::Productsku')->search($WHERE, { rows => 100 , order_by => 'description'});

	#$c->log->debug("TOTAL PRODUCT SKU FOUND: " . Dumper $ps_resultset->as_query);

	$c->stash->{productskulist} = $ps_resultset;

	$c->stash->{PRODUCT_SKU_LIST} = 1;
	$c->stash->{SKU_MANAGEMENT} = 1;

	$c->stash(template => "templates/customer/settings.tt");
	}

sub productskusetup :Local
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	my $ProductSku = $self->get_product_sku;
	if ($params->{'do'} eq 'setup')
		{
		if ($ProductSku)
			{
			#$c->log->debug("PRODUCT SKU DUMP: " . Dumper $ProductSku->{'_column_data'});
			$c->stash($ProductSku->{'_column_data'});
			}

		$c->log->debug(($ProductSku ? "EDIT (ID: " . $ProductSku->productskuid . ")" : "SETUP NEW") . " PRODUCT SKU SETUP");

		$c->stash->{dimention_list} = $self->get_select_list('DIMENTION');
		$c->stash->{unittype_list} = $self->get_select_list('UNIT_TYPE');
		$c->stash->{yesno_list} = $self->get_select_list('YES_NO_NUMERIC');
		$c->stash->{weighttype_list} = $self->get_select_list('WEIGHT_TYPE');
		$c->stash->{unitofmeasure_list} = $self->get_select_list('UNIT_OF_MEASURE');

		#my $unit_type_description = {};
		#$unit_type_description->{$_->unittypeid} = $_->unittypename foreach $self->context->model('MyDBI::Unittype')->all;
		#$c->stash->{unit_type_description} = $unit_type_description;

		$c->stash->{SETUP_PRODUCT_SKU} = 1;
		}
	elsif ($params->{'do'} eq 'configure')
		{
		$ProductSku = $c->model('MyDBI::Productsku')->new unless $ProductSku;

		$ProductSku->description($params->{description});
		$ProductSku->customerskuid($params->{customerskuid});
		$ProductSku->upccode($params->{upccode});
		$ProductSku->manufacturecountry($params->{manufacturecountry});
		$ProductSku->value($params->{value});
		$ProductSku->class($params->{class});
		$ProductSku->hazardous($params->{hazardous});
		$ProductSku->nmfc($params->{nmfc});
		$ProductSku->unitofmeasure($params->{unitofmeasure});
		$ProductSku->balanceonhand($params->{balanceonhand});
		$ProductSku->unittypeid($params->{unittypeid});
		## SKU
		$ProductSku->weight($params->{weight});
		$ProductSku->weighttype($params->{weighttype});
		$ProductSku->length($params->{length});
		$ProductSku->width($params->{width});
		$ProductSku->height($params->{height});
		$ProductSku->dimtype($params->{dimtype});
		## CASE
		$ProductSku->caseweight($params->{caseweight});
		$ProductSku->caseweighttype($params->{caseweighttype});
		$ProductSku->caselength($params->{caselength});
		$ProductSku->casewidth($params->{casewidth});
		$ProductSku->caseheight($params->{caseheight});
		$ProductSku->casedimtype($params->{casedimtype});
		$ProductSku->skupercase($params->{skupercase});
		## PALLET
		$ProductSku->palletweight($params->{palletweight});
		$ProductSku->palletweighttype($params->{palletweighttype});
		$ProductSku->palletlength($params->{palletlength});
		$ProductSku->palletwidth($params->{palletwidth});
		$ProductSku->palletheight($params->{palletheight});
		$ProductSku->palletdimtype($params->{palletdimtype});
		$ProductSku->casesperpallet($params->{casesperpallet});

		my $msg;
		if ($ProductSku->productskuid)
			{
			$ProductSku->update;
			$c->log->debug("PRODUCT SKU UPDATED, ID: ".$ProductSku->productskuid);
			$msg = "Product sku update successfully!";
			}
		else
			{
			$ProductSku->productskuid($self->get_token_id);
			$ProductSku->insert;
			$c->log->debug("NEW PRODUCT SKU INSERTED, ID: ".$ProductSku->productskuid);
			$msg = "New product sku configured successfully!";
			}

		$c->stash->{MESSAGE} = $msg;
		$c->detach("skumanagement",$params);
		}

	$c->stash->{SKU_MANAGEMENT} = 1;
	$c->stash->{template} = "templates/customer/settings.tt";
	}

sub get_product_sku
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	my $WHERE = {};
	if (length $params->{'productskuid'})
		{
		$WHERE->{productskuid} = $params->{'productskuid'};
		}
	elsif (length $params->{'productsku'})
		{
		$WHERE->{description} = $params->{'productsku'};
		}

	return undef unless scalar keys %$WHERE;
	return $c->model('MyDBI::Productsku')->find($WHERE);
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
