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

	$c->log->debug("TOTAL PRODUCT SKU FOUND: " . Dumper $ps_resultset->as_query);

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

	if (length $params->{'productskuid'})
		{
		my $Productsku = $c->model('MyDBI::Productsku')->find({ productskuid => $params->{'productskuid'} });
		}

	$c->stash->{unittypelist} = $self->get_select_list('UNIT_TYPE');

	$c->stash->{SETUP_PRODUCT_SKU} = 1;
	$c->stash->{SKU_MANAGEMENT} = 1;

	$c->stash(template => "templates/customer/settings.tt");
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
