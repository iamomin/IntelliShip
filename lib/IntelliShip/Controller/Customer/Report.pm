package IntelliShip::Controller::Customer::Report;
use Moose;
use Data::Dumper;
use namespace::autoclean;
use IntelliShip::Controller::Customer::ReportDriver;

BEGIN { extends 'IntelliShip::Controller::Customer'; }

sub index :Path :Args(0)
	{
	my ( $self, $c ) = @_;

	$c->log->debug("DISPLAY REPORT LINKS");

	## Display reports
	my $report_list = [
				{ name => 'Shipment Report', url => '/customer/report/setup?report=SHIPMENT' },
				{ name => 'New ABC Report', url => '/customer/report/setup?report=ABC' },
			];

	$c->stash->{report_list} = $report_list;
	$c->stash->{template} = "templates/customer/report.tt";
	}

sub setup :Local
	{
	my ( $self, $c ) = @_;
	my $params = $c->req->params;

	if ($params->{'report'} eq 'SHIPMENT')
		{
		$c->stash->{carrier_loop} = $self->get_select_list('CARRIER');
		}

	$c->stash->{report_setup} = 1;
	$c->stash->{report_name} = $params->{'report'};
	$c->stash->{template} = "templates/customer/report.tt";
	}

sub run :Local
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	if ($params->{'format'} eq 'HTML')
		{
		$self->run_HTML_report;
		}
	elsif ($params->{'format'} eq 'CSV')
		{
		$self->run_CSV_report;
		}
	elsif ($params->{'format'} eq 'MANIFEST')
		{
		$self->run_MANIFEST_report;
		}
	elsif ($params->{'format'} eq 'SUMMARY_SERVICE')
		{
		$self->run_SUMMARY_SERVICE_report;
		}
	}

sub run_HTML_report
	{
	my $self = shift;
	$self->generate_report;
	}

sub run_CSV_report
	{
	my $self = shift;
	$self->generate_report;
	}

sub run_MANIFEST_report
	{
	my $self = shift;
	$self->generate_report;
	}

sub run_SUMMARY_SERVICE_report
	{
	my $self = shift;
	$self->generate_report;
	}

sub generate_report
	{
	my $self = shift;
	my $msg = shift;

	my $c = $self->context;
	my $params = $c->req->params;

	my $ReportDriver = IntelliShip::Controller::Customer::ReportDriver->new;
	$ReportDriver->context($self->context);
	$ReportDriver->contact($self->contact);
	$ReportDriver->customer($self->customer);

	my ($report_heading_loop,$report_output_row_loop,$filter_criteria_loop) = $ReportDriver->make_report;

	#if ($ReportDriver->has_errors)
	#	{
	#	$c->log->debug('Error ' . Dumper $ReportDriver->error);
	#	$c->detach("index",$params);
	#	}

		$c->stash->{report_heading_loop} = $report_heading_loop;
	if (scalar @$report_output_row_loop > 0)
		{
		#$self->save_report($report_heading_loop,$report_output_row_loop,$filter_criteria_loop);
		$c->stash->{report_heading_loop} = $report_heading_loop;
		$c->stash->{report_output_row_loop} = $report_output_row_loop;
		}

	if ($filter_criteria_loop)
		{
		$c->stash->{filter_criteria} = $filter_criteria_loop;
		}

	$c->stash->{message} = $msg if ($msg);

	my $report_name = $params->{'report'};
	$report_name =~ s/\_/\ /g;
	$c->stash->{report_name} = $report_name;
	$c->stash->{report_output} = 1;

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
