package IntelliShip::Controller::Customer::Report;
use Moose;
use Data::Dumper;
use namespace::autoclean;
use IntelliShip::Utils;
use IntelliShip::MyConfig;
use IntelliShip::DateUtils;
use Spreadsheet::WriteExcel;
use IntelliShip::Controller::Customer::ReportDriver;

BEGIN { extends 'IntelliShip::Controller::Customer'; }

sub index :Path :Args(0)
	{
	my ( $self, $c ) = @_;

	$c->log->debug("DISPLAY REPORT LINKS");

	## Display reports
	my $report_list = [
				{ name => 'Shipment Report', url => '/customer/report/setup?report=SHIPMENT' },
				{ name => 'Manifest Report', url => '/customer/report/setup?report=MANIFEST' },
				{ name => 'Summary Service Report', url => '/customer/report/setup?report=SUMMARY_SERVICE' },
#				{ name => 'EOD Report', url => '/customer/report/setup?report=EOD' },
			];

	$c->stash->{report_list} = $report_list;
	$c->stash->{template} = "templates/customer/report.tt";
	}

sub setup :Local
	{
	my ( $self, $c ) = @_;
	my $params = $c->req->params;

	$c->stash->{report_setup} = 1;
	$c->stash->{report_name} = $params->{'report'};
	$c->stash->{template} = "templates/customer/report.tt";
	}

sub run :Local
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	my $ReportDriver = IntelliShip::Controller::Customer::ReportDriver->new;
	$ReportDriver->context($self->context);
	$ReportDriver->contact($self->contact);
	$ReportDriver->customer($self->customer);

	my ($report_heading_loop,$report_output_row_loop,$filter_criteria_loop) = $ReportDriver->make_report;

	if ($ReportDriver->has_errors)
		{
		$c->log->debug('Error ' . Dumper $ReportDriver->error);
		$c->detach("index",$params);
		}

	$c->stash->{filter_criteria_loop} = $filter_criteria_loop;
	$c->stash->{report_heading_loop} = $report_heading_loop;

	if (scalar @$report_output_row_loop > 0)
		{
		$c->stash->{report_output_row_loop} = $report_output_row_loop;
		}

	my $report_name = $params->{'report'};
	$report_name =~ s/\_/\ /g;
	$c->stash->{report_name} = $report_name;

	$self->format_report;
	}

sub format_report
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	if ($params->{'format'} eq 'HTML')
		{
		$self->format_HTML;
		}
	elsif ($params->{'format'} eq 'CSV')
		{
		$self->format_CSV;
		}
	elsif ($params->{'format'} eq 'PDF')
		{
		$self->format_PDF;
		}
	}

sub format_HTML
	{
	my $self = shift;
	my $c = $self->context;
	$c->stash->{HTML} = 1;
	$c->stash->{MEDIA_PRINT} = 1;
	$c->stash->{template} = "templates/customer/report.tt";
	}

sub format_CSV
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	my $REPORT_dir = IntelliShip::MyConfig->report_file_directory;

	unless (IntelliShip::Utils->check_for_directory($REPORT_dir))
		{
		$self->add_error("Unable to create report directory");
		return;
		}

	my $EXCEL_file = $params->{'report'} . '_' . IntelliShip::DateUtils->timestamp . '.xls';

	$c->log->debug("REPORT EXCEL FILE: " . $REPORT_dir . '/' . $EXCEL_file);

	# Create a new Excel workbook
	my $workbook = Spreadsheet::WriteExcel->new($REPORT_dir . '/' . $EXCEL_file);

	# Add a worksheet
	my $worksheet = $workbook->add_worksheet();
	$worksheet->set_column('A:M', 20);

	my $report_heading_loop = $c->stash->{report_heading_loop};

	# Write a formatted and unformatted string, row and column notation.
	my ($col,$row)=(0,1);

	# Report Title
	my $format = $workbook->add_format(border  => 0, valign  => 'vcenter', align   => 'left');
	$format->set_bold();
	$worksheet->merge_range("A$row:M$row", "Report Name: " . $c->stash->{report_name}, $format);

	# Report Date
	$row++;
	$worksheet->merge_range("A$row:M$row", "Date: " . IntelliShip::DateUtils->american_date(IntelliShip::DateUtils->current_date('-')), $format);

	# Report header row format
	$format = $workbook->add_format(); # Add a format
	$format->set_bold();
	$format->set_color('black');
	$format->set_align('center');

	$row++;
	foreach my $Column (@$report_heading_loop)
		{
		$worksheet->write($row, $col++, uc $Column->{name}, $format);
		}

	# Report header row format
	$format = $workbook->add_format(); # Add a format
	$format->set_align('center');

	my $report_output_row_loop = $c->stash->{report_output_row_loop};
	foreach my $report_output_columns (@$report_output_row_loop)
		{
		$col=0;$row++;
		foreach my $Column (@$report_output_columns)
			{
			$worksheet->write($row, $col++, $Column->{value}, $format);
			}
		}

	unless ($workbook->close)
		{
		$c->log->debug("Error closing file: $!");
		}

	$self->download($EXCEL_file,$REPORT_dir);
	}

sub format_PDF
	{
	my $self = shift;
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
