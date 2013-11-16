package IntelliShip::Controller::Customer::Report;
use Moose;
use Data::Dumper;
use namespace::autoclean;

BEGIN { extends 'IntelliShip::Controller::Customer'; }

sub index :Path :Args(0) 
	{
	my ( $self, $c ) = @_;
	my $params = $c->req->params;

	$c->stash->{REPORT_SETUP} = 1;
	$c->stash->{CARRIER_LOOP} = $self->get_select_list('CARRIER');

	$c->stash(template => "templates/customer/report.tt");
	}

sub run :Local
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	my $parameter_loop = [];
	push (@$parameter_loop,{name => 'Start Date',value => '2012',});
	push (@$parameter_loop,{name => 'End Date',value => '2013',});
	push (@$parameter_loop,{name => 'Carriers',value => '1,2,3',});

	$c->stash->{RUN_REPORT} = 1;
	$c->stash(PARAMETER_LOOP => $parameter_loop);
	$c->stash(template => "templates/customer/report.tt");
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
