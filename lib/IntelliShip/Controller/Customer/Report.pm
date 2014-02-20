package IntelliShip::Controller::Customer::Report;
use Moose;
use Data::Dumper;
use namespace::autoclean;
use IntelliShip::Utils;
use IntelliShip::Email;
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

	$self->set_report_title;

	$c->stash($c->req->params);
	$c->stash->{report_setup} = 1;
	$c->stash->{template} = "templates/customer/report.tt";
	}

sub run :Local
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	$self->set_report_title;

	if ($params->{'toemail'} and !IntelliShip::Utils->is_valid_email($params->{'toemail'}))
		{
		$c->stash->{MESSAGE} = "Invalid email address, please enter valid email address";
		$c->detach("setup",$params);
		return;
		}

	my $ReportDriver = IntelliShip::Controller::Customer::ReportDriver->new;
	$ReportDriver->context($self->context);
	$ReportDriver->contact($self->contact);
	$ReportDriver->customer($self->customer);

	my ($report_heading_loop,$report_output_row_loop,$filter_criteria_loop) = $ReportDriver->make_report;

	if ($ReportDriver->has_errors)
		{
		$c->log->debug('Error ' . Dumper $ReportDriver->print_errors('TEXT'));
		$c->stash->{MESSAGE} = $ReportDriver->errors->[0];
		$c->detach("setup",$params);
		return;
		}

	$c->stash->{filter_criteria_loop} = $filter_criteria_loop;
	$c->stash->{report_heading_loop} = $report_heading_loop;
	$c->stash->{column_count} = scalar @$report_heading_loop if $report_heading_loop;

	if (scalar @$report_output_row_loop > 0)
		{
		$c->stash->{report_output_row_loop} = $report_output_row_loop;
		}

	$self->format_report;

	if ($params->{'toemail'})
		{
		$self->email_report;
		}
	elsif ($params->{'format'} =~ /(CSV|PDF)/i)
		{
		$self->download($c->stash->{FILE});
		}
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

	
	# Add Company Logo
	my $BrandingID = $self->get_branding_id;
	my $image_path = IntelliShip::MyConfig->image_file_directory . "/$BrandingID/report-logo.png";
	$c->log->debug(" image_path: " . $image_path);

	# Increase the cell size of the merged cells to highlight the formatting.
    #$worksheet->set_column( 0, 1, 30 );
    #$worksheet->set_row( 1, 35 );     
    # Create logo Backgorund
    #my $imageBackgroundformat = $workbook->add_format(center_across => 1,size => 15,pattern => 1,align => 'vcenter');   
    #$worksheet->write_blank( 1, 0, $imageBackgroundformat );	
	$worksheet->insert_image(1, 0, $image_path, 16, 9) if ( -r $image_path);
		
	if ($params->{'report'} == 'SHIPMENT')
		{
		$self->format_SHIPMENT_xls($workbook, $worksheet);
		}
	elsif ($params->{'report'} == 'SUMMARY_SERVICE')
		{
		$self->format_SUMMARY_SERVICE_xls;
		}
	else
		{
		my $report_heading_loop = $c->stash->{report_heading_loop};	

		# Write a formatted and unformatted string, row and column notation.
		my ($col,$row)=(0,0);

		my $format = $workbook->add_format(border  => 0, valign  => 'vcenter', align   => 'left', bold => 1);
		
		# Report Date
		$worksheet->merge_range("A$row:M$row", "Date: " . IntelliShip::DateUtils->american_date(IntelliShip::DateUtils->current_date('-')) , $format);

		# Report Title
		$row++;
		$worksheet->merge_range("A$row:M$row", "Report Name: " . $c->stash->{report_title}, $format);

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
		}
	unless ($workbook->close)
		{
		$c->log->debug("Error closing file: $!");
		}

	$c->stash->{FILE} = $REPORT_dir . '/' . $EXCEL_file;
	}

sub format_SHIPMENT_xls
	{
	my $self = shift;
	my $workbook = shift;
	my $worksheet = shift;
	my $c = $self->context;
	
	# Write a formatted and unformatted string, row and column notation.
	my ($col,$row)=(0,14);

	# Add Company Address Box
	my $company_address = $self->customer->address;
	
	my $addressHeaderBorderFormat = $workbook->add_format(bold => 1, align => 'left', top=>2, bottom=>1, left=>2,right=>2);
	my $addressFirstBorderFormat = $workbook->add_format(bold => 1, align => 'left', left=>2, right=>2);
	my $addressSecondaryBorderFormat = $workbook->add_format( align => 'left', left=>2,right=>2);
	my $addressBottomBorderFormat = $workbook->add_format(align => 'left', bottom => 2, left=>2,right=>2);

	$worksheet->merge_range("E4:G4", 'Service & Billing For:', $addressHeaderBorderFormat);
	$worksheet->merge_range("E5:G5", $company_address->addressname, $addressFirstBorderFormat);
	$worksheet->merge_range("E6:G6", $company_address->address1, $addressSecondaryBorderFormat);
	$worksheet->merge_range("E7:G7", $company_address->address2, $addressSecondaryBorderFormat);
	$worksheet->merge_range("E8:G8", $company_address->city . ', ' . $company_address->state . ' ' . $company_address->zip, $addressSecondaryBorderFormat);
	$worksheet->merge_range("E9:G9", 'Contact:', $addressSecondaryBorderFormat);
	$worksheet->merge_range("E10:G10", $self->customer->contact, $addressSecondaryBorderFormat);
	$worksheet->merge_range("E11:G11", $self->customer->phone, $addressSecondaryBorderFormat);
	$worksheet->merge_range("E12:G12", $self->customer->email, $addressBottomBorderFormat);
	
	# Add Report Summary Box
	my $summaryTopBorderFormat = $workbook->add_format(bold => 1, align => 'left', top=>2, left=>2, bottom=> 6);
	my $summaryMiddleCellFormat = $workbook->add_format(bold => 1, align => 'left', left=>2, right=>2);
	my $summaryBottomBorderFormat = $workbook->add_format(bold => 1,align => 'left', border => 2);
	
	$worksheet->merge_range("I5:J5", 'Report Totals:', $summaryTopBorderFormat);
	$worksheet->merge_range("I6:J6",'Report Date', $summaryMiddleCellFormat);
	$worksheet->merge_range("I7:J7", 'Shipments', $summaryMiddleCellFormat);
	$worksheet->merge_range("I8:J8", 'Pounds', $summaryMiddleCellFormat);
	$worksheet->merge_range("I9:J9", 'Total Charges *', $summaryBottomBorderFormat);
	
	my $reportMessageFormat = $workbook->add_format(color => 'red', valign => 'vcenter', align => 'left', bold => 1);
	
	# Add charge disclaimer
	$worksheet->merge_range("A$row:M$row", "* Charges displayed in Intelliship may not include freight, fuel, or other miscellaneous accessorial charges", $reportMessageFormat);
	$row += 2;

	my $current_date = IntelliShip::DateUtils->american_date(IntelliShip::DateUtils->current_date('-'));
	my $reportTitleDateFormat = $workbook->add_format(border => 0, valign => 'vcenter', align => 'left', bold => 1);

	# Report Title
	$worksheet->merge_range("A$row:M$row", "Date: " . $current_date , $reportTitleDateFormat);

	# Report Date
	$row++;
	$worksheet->merge_range("A$row:M$row", "Report Name: " . $c->stash->{report_title}, $reportTitleDateFormat);
	
	# Report header row format
	my $report_heading_loop = $c->stash->{report_heading_loop};	
	my $reportHeaderFormat = $workbook->add_format(border => 1, align => 'center', bold => 1); # Add a format
	
	$row++;
	foreach my $Column (@$report_heading_loop)
		{
		$worksheet->write($row, $col++, uc $Column->{name}, $reportHeaderFormat);
		}

	# Report data row format
	my $reportDataFormat = $workbook->add_format(align => 'center', border => 1); # Add a format
	
	my $report_output_row_loop = $c->stash->{report_output_row_loop};
	
	foreach my $report_output_columns (@$report_output_row_loop)
		{
		$col=0;$row++;
		foreach my $Column (@$report_output_columns)
			{
			$worksheet->write($row, $col++, $Column->{value}, $reportDataFormat);
			}
		}

		# Totals Top box
		# Special stypes for Top Totals Box
		my $totalBoxValueTop = $workbook->addformat(top=> 2,bottom=>6,left=>1,right=>2,align=>'center');
		my $totalBoxValueCommon = $workbook->addformat(top=>1,bottom=>1,left=>1,right=>2,align=>'center');
		my $totalBoxValueBottom = $workbook->addformat(top=>2,bottom=>2, left=>1, right=>2,align=>'center');
		my $report_summary_row_loop = pop(@$report_output_row_loop);
		$c->log->debug("DATA : " . Dumper @$report_summary_row_loop);
		$worksheet->write("K5", '', $totalBoxValueTop);
		$worksheet->write("K6", $current_date, $totalBoxValueCommon);
		
		# Top Toatl Box
		$worksheet->write("K7", scalar @$report_output_row_loop, $totalBoxValueCommon);
		$worksheet->write("K8", ${$report_summary_row_loop}[1]->{value}, $totalBoxValueCommon);
		$worksheet->write("K9", ${$report_summary_row_loop}[8]->{value} + ${$report_summary_row_loop}[9]->{value}, $totalBoxValueBottom);
		$row += 2;			
			
	}

sub format_PDF
	{
	my $self = shift;
	my $c = $self->context;
	$c->stash->{MESSAGE} = "PDF formatting is under construction";
	$c->detach("setup",$c->req->params);
	}

sub set_report_title
	{
	my $self = shift;
	my $c = $self->context;
	my $report_title = $c->req->params->{'report'};
	$report_title =~ s/\_/\ /g;
	$c->stash->{report_title} = $report_title;
	}

sub email_report
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	$c->log->debug("Sending Email To: " . $params->{'toemail'});

	$c->stash->{template} = "templates/customer/report.tt";

	my $Email = IntelliShip::Email->new;
	$Email->add_to($params->{'toemail'});
	$Email->subject('IntelliShip Report');

	if ($params->{'format'} eq 'HTML')
		{
		$Email->body($c->forward($c->view('Email'), "render", [ $c->stash->{template} ]));
		}
	elsif ($params->{'format'} =~ /(CSV|PDF)/i)
		{
		$Email->attach($c->stash->{FILE}) if $c->stash->{FILE};
		$Email->add_line('<h3>' . uc $c->stash->{report_title} . ' REPORT</h3>');
		$Email->add_line('<p>');
		$Email->add_line('Please find attached report');
		$Email->add_line('</p>');
		}

	$self->set_company_template($Email);

	if ($Email->send)
		{
		$c->stash->{MESSAGE} = "Email successfully sent to " . $c->req->params->{'toemail'};
		}

	$c->detach("setup",$params) if $params->{'format'} =~ /(CSV|PDF)/i;
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
