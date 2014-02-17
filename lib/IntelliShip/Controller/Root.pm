package IntelliShip::Controller::Root;
use Moose;
use Data::Dumper;
use IntelliShip::Utils;
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
    $c->response->body( 'Page not found' );
    $c->response->status(404);
}

=head1

auto : Private

auto actions will be run after any begin, but before your URL-matching action is processed.
Unlike the other built-ins, multiple auto actions can be called; they will be called in turn,
starting with the application class and going through to the most specific class.

=cut

sub auto :Private
	{
	my($self, $c) = @_;

	$c->log->debug('Auto Divert to ' . $c->action);

	return 1 unless $c->request->action =~ /customer/;

	$c->stash->{TokenID} = undef;
	$c->stash->{coid} = undef;
	$c->stash->{CO} = undef;

	my $Controller = $c->controller;

	## Catalyst context is not accessible in every user defined function
	$Controller->context($c);
	####################

	return 1 if $c->request->action =~ /login$/;

	#$c->log->debug("c->request->cookies: " . Dumper $c->request->cookies);
	#$c->log->debug("c->response->cookies: " . Dumper $c->response->cookies);

	my $tokenid;
	unless ($tokenid = $Controller->authorize_user)
		{
		if ($c->req->param('ajax') == 1)
			{
			$c->response->body(IntelliShip::Utils->jsonify({ error => 'You are not logged in. Please login first.' }));
			}
		else
			{
			#$c->log->debug('**** Root::auto Not a valid user, forwarding to customer/login ');
			$c->response->redirect($c->uri_for('/customer/login'));
			$c->stash->{template} = undef;
			}

		return 0;
		}

	$tokenid = '' unless $tokenid;
	#$c->log->debug("**** User Authorized Successfully, set TokenID in cookies: " . $tokenid);
	$c->response->cookies->{'TokenID'} = { value => $tokenid, expires => '+20M' };

	return 1;
	}

=head2 end

Attempt to render a view, if needed.

=cut

#sub end : ActionClass('RenderView') {}

sub end : Private {
	my ($self, $c) = @_;

	#$c->log->debug("In end : Private ");
	#$c->log->debug("stash: " . Dumper $c->stash);
	#$c->log->debug("\nPARAMS : " . Dumper $c->req->params);

	return unless $c->stash->{template};

	$c->response->body($c->stash->{template});

	$self->set_selected_menu($c);
	$c->stash->{landing_page} = '/customer/order/multipage';

	my $Controller = $c->controller;
	my $Token = $Controller->token;
	my $ajax = $c->req->param('ajax') || 0;
	my $print_label = $c->stash->{print_label} || 0;

	if ($Token and $ajax)
		{
		$c->forward($c->view('Ajax'));
		}
	elsif ($Token and $print_label)
		{
		$c->forward($c->view('Label'));
		}
	elsif ($Token)
		{
		$Controller->set_navigation_rules;
		$c->stash->{login_username} = $Controller->contact->full_name;
		$c->forward($c->view('CustomerMaster'));
		}
	else
		{
		$c->forward($c->view('Login'));
		}
}

my $DEFAULT_MENU_SELECTED = {
	login => 'dashboard',
	};

sub set_selected_menu :Private
	{
	my $self = shift;
	my $context = shift;
	my @urlParts = split(/\//,$context->action);
	my $selected_mnu = ($urlParts[-1] =~ /index/ ? $urlParts[-2] : $urlParts[-1]);
	$context->stash->{selected_mnu} = 'mnu_' . ($DEFAULT_MENU_SELECTED->{$selected_mnu} ? $DEFAULT_MENU_SELECTED->{$selected_mnu} : $selected_mnu);
	}

=head1 AUTHOR

root

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
