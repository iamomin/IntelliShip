package IntelliShip::Controller::Customer::Login;
use Moose;
use MIME::Base64;
use REST::Client;
use Data::Dumper;
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

	my $params = $c->request->parameters;

	$self->flush_expired_tokens;

	$c->stash(template => "templates/customer/login.tt");

	if (my $Token = $self->get_token)
		{
		$c->log->debug('--------- TOKEN FOUND ---------');
		$self->token($Token);
		$c->log->debug('--------- AUTHORIZE USER ---------');
		$self->authorize_user;
		return;
		}

	#$c->log->debug('Login.pm - PARAMS: ' . Dumper $params);

	if ($ENV{HTTP_HOST} =~ /motorolasolutions/i)
		{
		unless ($params->{'ID'})
			{
			# initialize SSO
			# redirect to sso server which will send a request to motorola
			my $moto_sso_url = $self->get_sso_URL;
			$c->log->debug("Status: 302 Moved, Location: $moto_sso_url");
			$c->response->redirect($moto_sso_url);
			}
		else
			{
			my $SSO_host = 'sso.engagetechnology.com/EasyConnect';
			my $headers = { 'Authorization' => 'Basic ' . encode_base64('intelliship:password') };

			$c->log->debug('***** Set up a REST session *****');
			## Set up a REST session
			my $REST = REST::Client->new( { host => "http://$SSO_host" } );
			$REST->GET( "/REST/IntegrationToken/Default.aspx?ID=".$params->{'ID'}, $headers );

			my $SSORespCode = $REST->responseCode();
			my $SSOResponse = $REST->responseContent();

			$c->log->debug('***** SSORespCode: ' . $SSORespCode);
			$c->log->debug('***** SSOResponse: ' . $SSOResponse);

			if ($SSORespCode eq '200')
				{
				$params->{'ssoauth'} = $params->{'myssoid'};
				my @ssodata = split(/\n/, $SSOResponse);

				my $SSO_username = '';
				foreach my $ssodata ( @ssodata )
					{
					$ssodata =~ s/\r//;
					$ssodata =~ s/\n//;

					if ( $ssodata =~ /UserName/i )
						{
						$SSO_username = $ssodata;
						$SSO_username =~ s/#UserName=//i;
						$c->log->debug("TOKEN UserName=$SSO_username");
						}
					}

				$params->{'username'} = $SSO_username . '@motorolasolutions.com';
				$params->{'password'} = 'SSOLOGIN';
				#$params->{'username'} = 'FCJ016@motorolasolutions.com';
				#$params->{'password'} = '8ETNA05SCWSM2';
				}
			else
				{
				$c->stash(error => 'Unable to authenticate ID ' . $params->{'ID'} . ' against ' . $SSO_host);
				$c->log->debug('Unable to authenticate ID ' . $params->{'ID'} . ' against ' . $SSO_host);
				return;
				}
			}
		}

	#$c->log->debug("********* LOG IN CUSTOMER USER *********");

	$self->token(undef); ## IMP

	$c->stash->{branding_id} = $self->get_branding_id;

	if (defined $params->{'username'} and defined $params->{'password'})
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

		$c->stash(NO_CACHE => 1);
		}

	return 1;
	}

sub authenticate_user :Private
	{
	my $self = shift;
	my ($Username, $Password, $BrandingID, $SSOUsername, $SSOAuth) = @_;

	my $c = $self->context;

	my ($Customer, $Contact ) = $self->get_customer_contact($Username,$Password);

	my ($CustomerID, $ContactID, $ActiveUser);

	if ($Customer and $Contact)
		{
		$ContactID = $Contact->contactid;
		$CustomerID = $Customer->customerid;

		#$c->log->debug("ContactID: " . $ContactID . ", CustomerID: " . $CustomerID);

		#$ActiveUser = ($Contact->firstname ? $Contact->firstname : $Contact->username);
		$ActiveUser = $Contact->username;
		$BrandingID = $self->get_branding_id;

		#$c->log->debug("ActiveUser: " . $ActiveUser);
		#$c->log->debug("BrandingID: " . $BrandingID) if $BrandingID;

		$self->contact($Contact);
		$self->customer($Customer);
		}
	else
		{
		$self->token(undef);
		}

	my $TokenID = undef;
	my $myDBI = $c->model("MyDBI");

	if ($CustomerID)
		{
		$TokenID = $self->get_token_id;

		$c->stash->{TokenID} = $TokenID;

		#$c->log->debug("#### Creating new TOKEN: " . $TokenID);

		($BrandingID, $SSOUsername, $SSOAuth) = ('','',''); ##**

		my $sql = "INSERT INTO token
					(tokenid, customerid, datecreated, dateexpires,active_username,brandingid,ssoid)
				VALUES
					('$TokenID', '$CustomerID', timestamp 'now', timestamp with time zone 'now' + '1 hour', '$Username', '$BrandingID', '$SSOAuth')";

		#$c->log->debug("sql: " . $sql);
		$myDBI->dbh->do($sql);

		$self->token($c->model("MyDBI::Token")->find($TokenID));
		}

	return $TokenID;
	}

sub get_sso_URL :Private
	{
	my $self = shift;
	my $URL = 'https://ct11redwebappl.motorolasolutions.com/fed/idp/initiatesso?providerid=EngageTechnologySP&returnurl=https://shipping-test.motorolasolutions.com';
	return $URL;
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
