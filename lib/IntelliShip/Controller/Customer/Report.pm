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
	if ($params->{'carriers'} and ref $params->{'carriers'} eq 'ARRAY' and grep(/all/, @{$params->{'carriers'}}))
		{
		$params->{'carriers'} = 'all';
		}

	my $ReportDriver = IntelliShip::Controller::Customer::ReportDriver->new;
	$ReportDriver->API($self->API);
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

	#$c->log->debug("REPORT EXCEL FILE: " . $REPORT_dir . '/' . $EXCEL_file);

	# Create a new Excel workbook
	my $workbook = Spreadsheet::WriteExcel->new($REPORT_dir . '/' . $EXCEL_file);

	# Add a worksheet
	my $worksheet = $workbook->add_worksheet();

	# Add Company Logo
	my $BrandingID = $self->get_branding_id;
	my $image_path = IntelliShip::MyConfig->image_file_directory . "/$BrandingID/report-logo.png";

	$worksheet->insert_image(1, 0, $image_path, 16, 9) if ( -r $image_path);

	if ($params->{'report'} eq 'SHIPMENT')
		{
		$self->format_SHIPMENT_xls($workbook, $worksheet);
		}
	elsif ($params->{'report'} eq 'SUMMARY_SERVICE')
		{
		#$self->format_SUMMARY_SERVICE_xls($workbook, $worksheet);
		$self->format_SHIPMENT_xls($workbook, $worksheet);
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
	my $params = $c->req->params;

	# Let's set the column widths specified values...
	$worksheet->set_column(0, 0, 17);				# Column 1 -Wt
	$worksheet->set_column(1, 1, 15);				# Column 2 -DimWt
	$worksheet->set_column(2, 2, 20);				# Column 3 -Dims
	$worksheet->set_column(3, 3, 22);				# Column 4 -Carrier
	$worksheet->set_column(4, 4, 17);				# Column 5 -Zone
	$worksheet->set_column(5, 5, 27);				# Column 6 -Srvc
	$worksheet->set_column(6, 6, 27);				# Column 7 -Airbill #
	$worksheet->set_column(7, 7, 20);				# Column 8 -Freight Charge
	$worksheet->set_column(8, 8, 20);				# Column 9 -Other Charge
	$worksheet->set_column(9, 9, 20);				# Column 10 -Other Charges
	$worksheet->set_column(10,10, 23);				# Column 11 -Total Charges
	$worksheet->set_column(11,11, 25);				# Column 12 -
	$worksheet->set_column(12,12, 20);				# Column 13
	$worksheet->set_column(13,13, 20);				# Column 14
	$worksheet->set_column(14,14, 20);				# Column 15
	$worksheet->set_column(15,15, 20);				# Column 16
	$worksheet->set_column(16,16, 18);				# Column 17
	$worksheet->set_column(17,17, 17);				# Column 18
	$worksheet->set_column(18,18, 25);				# Column 19
	$worksheet->set_column(19,19, 25);				# Column 20
	$worksheet->set_column(20,20, 20);				# Column 21
	$worksheet->set_column(21,21, 22);				# Column 22
	$worksheet->set_column(22,22, 20);				# Column 23
	$worksheet->set_column(23,23, 30);				# Column 24
	$worksheet->set_column(24,24, 20);				# Column 25
	$worksheet->set_column(25,25, 25);				# Column 26
	
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

	# Report Date
	$worksheet->merge_range("A$row:M$row", "Date: " . $params->{'startdate'} . ' - ' . $params->{'enddate'} , $reportTitleDateFormat);

	# Report Title
	$row++;
	$worksheet->merge_range("A$row:M$row", "Report Name: " . $c->stash->{report_title}, $reportTitleDateFormat);

	# Report header row format
	my $report_heading_loop = $c->stash->{report_heading_loop};
	my $reportHeaderFormat = $workbook->add_format(pattern => 1, color => 'white', fg_color => 54, align => 'center', font => 'Arial', size => 11, bold => 1); # Add a format

	$row++;
	foreach my $Column (@$report_heading_loop)
		{
		$worksheet->write($row, $col++, uc $Column->{name}, $reportHeaderFormat);
		}
		
	my $reportCarrierNameFormat = $workbook->add_format(pattern => 1, color => 'black', fg_color => 31, align	=> 'center', bold => 1);
	# Report data row format
	my $LinkFormat = $workbook->add_format( align => 'center', underline => 1, color => 'blue' );
	$LinkFormat->set_num_format(0x01);

	my $report_output_row_loop = $c->stash->{report_output_row_loop};

	foreach my $report_output_columns (@$report_output_row_loop)
		{
		my $carrier_name	= '';
		my $tracking_number = '';
		my $tracking_url	= '';
		$col=0;$row++;
		if ( defined ${ $report_output_columns }[0]->{carriername})
			{
			# Carrier header
			$worksheet->write($row, 0, ${ $report_output_columns }[0]->{value}, $reportCarrierNameFormat);
			$worksheet->write($row, 1, '', $reportCarrierNameFormat);
			next;
			}
		foreach my $Column (@$report_output_columns)
			{
			if($col == 6 && !(defined $Column->{grandtotal}))
				{
				$carrier_name  = ${ $report_output_columns }[3]->{value} || '';
				if ($carrier_name)
					{
						$tracking_number = $Column->{value};
						if ( $carrier_name eq 'Airborne Express' || $carrier_name eq 'DHL' )
						{
							$tracking_url = "http://track.dhl-usa.com/TrackByNbr.asp?ShipmentNumber=$tracking_number&nav=TrackBynumber"
						}
						elsif ( $carrier_name eq 'FedEx' )
						{
							$tracking_url = "HTTP://www.fedex.com/cgi-bin/tracking?action=track&language=english&cntry_code=us&initial=x&tracknumbers=$tracking_number";
						}
						elsif ( $carrier_name eq 'UPS' )
						{
							$tracking_url = "HTTP://wwwapps.ups.com/etracking/tracking.cgi?tracknums_displayed=5&TypeOfInquiryNumber=T&HTMLVersion=4.0&InquiryNumber1=$tracking_number&InquiryNumber2=&InquiryNumber3=&InquiryNumber4=&InquiryNumber5=&track=Track";
						}
						else
						{
							$tracking_url = '';
						}
					}
				$worksheet->write_url($row, $col++, $tracking_url, $tracking_number,$LinkFormat );
				}
			else
				{
				my $reportDataFormat;
				if( defined $Column->{grandtotal})
					{
					$reportDataFormat = $workbook->add_format(pattern => 1, color => 'white', fg_color => 54, align	=> 'center', font => 'Arial', size => 11, bold => 1);
					}
				elsif( defined $Column->{carriertotal})
					{
					$reportDataFormat = $workbook->add_format(pattern => 1, color => 'black', fg_color => 31, align	=> 'center', bold => 1);
					}
				else
					{
					$reportDataFormat = $workbook->add_format(align => 'center');
					}
					
				if (defined $Column->{currency})
					{
					$reportDataFormat->set_num_format('$0.00');
					}
				if (defined $Column->{align})
					{
					$reportDataFormat->set_align('right');
					}
				$worksheet->write($row, $col++, $Column->{value}, $reportDataFormat);
				}
			}
		}

		# Totals Top box
		# Special stypes for Top Totals Box
		my $totalBoxValueTop = $workbook->addformat(top=> 2,bottom=>6,left=>1,right=>2,align=>'center');
		my $totalBoxValueCommon = $workbook->addformat(top=>1,bottom=>1,left=>1,right=>2,align=>'center');
		my $totalBoxValueBottom = $workbook->addformat(top=>2,bottom=>2, left=>1, right=>2,align=>'center', num_format => '$0.00');
		my $report_summary_row_loop = pop(@$report_output_row_loop);

		$worksheet->write("K5", '', $totalBoxValueTop);
		$worksheet->write("K6", $current_date, $totalBoxValueCommon);
		my $total_shipments = 0;
		my $total_weight = 0;
		my $total_charge = 0;
		if ($params->{'report'} eq 'SHIPMENT')
			{
			$total_shipments = scalar @$report_output_row_loop;
			$total_weight	= ${$report_summary_row_loop}[0]->{value};
			$total_charge	= ${$report_summary_row_loop}[7]->{value} + ${$report_summary_row_loop}[8]->{value};
			}
		elsif ($params->{'report'} eq 'SUMMARY_SERVICE')
			{
			$total_shipments = ${$report_summary_row_loop}[2]->{value};
			$total_weight	= ${$report_summary_row_loop}[4]->{value};
			$total_charge	= ${$report_summary_row_loop}[3]->{value};
			}
		$worksheet->write("K7", $total_shipments, $totalBoxValueCommon);
		$worksheet->write("K8", $total_weight,    $totalBoxValueCommon);
		$worksheet->write("K9", $total_charge ,   $totalBoxValueBottom);
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
		$Email->body($c->forward($c->view('Ajax'), "render", [ $c->stash->{template} ]));
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
