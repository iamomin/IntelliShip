package IntelliShip::Controller::Root;
use Moose;
use Data::Dumper;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config(namespace => '');

=encoding utf-8

=head1 NAME

IntelliShip::Controller::Root - Root Controller for IntelliShip

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=head2 index

The root page (/)

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    # Hello World
    #$c->response->body( $c->welcome_message );
	$c->log->debug('IN ROOT index');
	$c->response->redirect($c->uri_for('/customer/login'));
}

=head2 default

Standard 404 error page

=cut

sub default :Path {
    my ( $self, $c ) = @_;
    #$c->response->body( 'Page not found' );
    #$c->response->status(404);
	$c->response->redirect($c->uri_for('/customer/login'));
}

sub access_denied :Private
	{
	my ( $self, $c ) = @_;
	my $params = $c->request->parameters;

	$c->response->body( "Access Denied" );
	}

=head2 end

Attempt to render a view, if needed.

=cut

#sub end : ActionClass('RenderView') {}


=head1

auto : Private

auto actions will be run after any begin, but before your URL-matching action is processed.
Unlike the other built-ins, multiple auto actions can be called; they will be called in turn,
starting with the application class and going through to the most specific class.

=cut

sub auto :Private {
	my($self, $c) = @_;

	$c->log->debug('Auto Divert to ' . $c->action);
	#$c->log->debug('##** Setting catalyst context in ' . $c->controller);

	## Catalyst context is not accessible in every user defined function
	$c->controller->context($c) if ($c->controller ne $c->controller('Root') );
	####################

	#$c->log->debug('##### COOKIES TokenID: ' . Dumper $c->req->cookies->{'TokenID'});

	my $url_action = $c->request->action;
	if ($url_action !~ /login$/ and $url_action =~ /customer/g)
		{
		unless ($c->controller->authorize_user)
			{
			$c->log->debug('**** Root::auto Not a valid user, forwarding to customer/login ');
			$c->response->redirect($c->uri_for('/customer/login'));
			$c->stash->{template} = undef;
			return 0;
			}

		if ($c->res->cookies->{'TokenID'})
			{
			$c->res->cookies->{'TokenID'} = { value => $c->stash->{TokenID}, expires => '+3600' };
			}

		$c->log->debug("**** User Authorized Successfully");
		}

	return 1;
}

sub end : Private {
	my ($self, $c) = @_;

	$c->log->debug("In end : Private ");
	#$c->log->debug("\nPARAMS : " . Dumper $c->req->params);

	return unless $c->stash->{template};

	$c->response->body($c->stash->{template});

	my $Token = $c->controller->token;
	my $ajax = $c->req->param('ajax') || 0;
	if ($Token and $ajax)
		{
		#$c->log->debug("============== Ajax");
		$c->forward($c->view('Ajax'));
		}
	elsif ($Token)
		{
		$c->log->debug("============== CustomerMaster: " . $Token->tokenid);
		$c->stash->{active_username} = $Token->active_username;
		$c->forward($c->view('CustomerMaster'));
		}
	else
		{
		#$c->log->debug("============== Login");
		$c->forward($c->view('Login'));
		}
}

=head1 AUTHOR

root

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
