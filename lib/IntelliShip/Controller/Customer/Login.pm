package IntelliShip::Controller::Customer::Login;
use Moose;
use namespace::autoclean;

BEGIN { extends 'IntelliShip::Controller::Customer'; }

=head1 NAME

IntelliShip::Controller::Customer::Login - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0)
	{
	my ( $self, $c ) = @_;

	#$c->response->body('Matched IntelliShip::Controller::Customer::Login in Customer::Login.');

	$c->log->debug("********* LOG IN CUSTOMER USER *********");

	$self->flush_expired_tokens;

	my $params = $c->request->parameters;
	my $Token = $self->get_token;

	if ($Token)
		{
		$c->log->debug('--------- TOKEN FOUND ---------');
		$self->token($Token);

		$c->log->debug('redirect to customer dashboard');
		$c->response->redirect($c->uri_for('/customer/dashboard'));
		}
	elsif (defined $params->{'username'} and defined $params->{'password'})
		{
		my $TokenID = $self->authenticate_user($params->{'username'}, $params->{'password'});

		unless ($TokenID)
			{
			$c->log->debug('$$$$$$ CUSTOMER USER NOT FOUND $$$$$$');
			$c->stash(template => "templates/customer/login.tt");
			$c->stash(error => "Invalid username or password");
			return 0;
			}

		$c->res->cookies->{'TokenID'} = { value => $TokenID, expires => '+3600' };

		$c->stash(template => "templates/customer/dashboard.tt");
		}
	else
		{
		$c->stash(template => "templates/customer/login.tt"); ## SHOW LOGIN PAGE FIRST
		}

	return 1;
	}

sub authenticate_user :Private
	{
	my $self = shift;
	my $c = $self->context;

	my ($Username, $Password, $BrandingID, $SSOUsername, $SSOAuth) = @_;

	my ($Customer, $Contact ) = $self->get_customer_contact($Username,$Password);

	my ($CustomerID, $ContactID, $ActiveUser);

	if ($Customer and $Contact)
		{
		$ContactID = $Contact->contactid;
		$CustomerID = $Customer->customerid;

		#$ActiveUser = ($Contact->firstname ? $Contact->firstname : $Contact->username);
		$ActiveUser = $Contact->username;
		$BrandingID = $self->get_branding_id;

		$c->log->debug("ActiveUser: " . $ActiveUser);
		$c->log->debug("BrandingID: " . $BrandingID) if $BrandingID;

		$self->contact($Contact);
		$self->customer($Customer);
		}
	else
		{
		$self->token(undef);
		}

	my $TokenID = undef;
	my $myDBI = $c->model("MyDBI");

	if ($ContactID)
		{
		$TokenID = $self->get_token_id;

		$c->stash->{TokenID} = $TokenID;

		$c->log->debug("#### Creating new TOKEN: " . $TokenID);

		($BrandingID, $SSOUsername, $SSOAuth) = ('','',''); ##**

		my $sql = "INSERT INTO token
					(tokenid, customerid, datecreated, dateexpires,active_username,brandingid,ssoid)
				VALUES
					('$TokenID', '$ContactID', timestamp 'now', timestamp 'now' + '2 hours', '$Username', '$BrandingID', '$SSOAuth')";

		$myDBI->dbh->do($sql);

		$self->token($c->model("MyDBI::Token")->find($TokenID));
		}

	$self->flush_expired_tokens;

	return $TokenID;
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
