package IntelliShip::Controller::Customer::UploadFile;
use Moose;
use IO::File;
use Data::Dumper;
use IntelliShip::DateUtils;
use namespace::autoclean;

require IntelliShip::Import::Orders;

BEGIN { extends 'IntelliShip::Controller::Customer'; }

=head1 NAME

IntelliShip::Controller::Customer::UploadFile - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    #$c->response->body('Matched IntelliShip::Controller::Customer::UploadFile in Customer::UploadFile.');$c->log->debug("BATCH SHIPPINH");

	## Display file upload type link
	my $links = [
				{ name => 'Order File Upload', url => '/customer/uploadfile/setup?type=ORDER'},
				{ name => 'Product Sku Upload', url => '/customer/uploadfile/setup?type=PRODUCTSKU'},
			];

	$c->stash->{UPLOADFILE_LINKS} = $links;
	$c->stash(template => "templates/customer/upload-file.tt");
	}

sub setup :Local
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	$c->stash($params);
	$c->stash->{SETUP_UPLOAD_FILE} = 1;
	$self->display_uploaded_order_files;
	$c->stash->{TITLE} = 'Upload ' . ucfirst(lc($params->{type})) . ' File';
	$c->stash(template => "templates/customer/upload-file.tt");
	}

sub display_uploaded_order_files
	{
	my $self = shift;
	my $c = $self->context;

	my $dir = $self->get_directory;
	return unless $dir;

	my $DH = new IO::File;

	unless ( opendir $DH , $dir )
		{
		$c->log->debug("Could not open directory \"$dir\" $!");
		return;
		}

	my @files = grep (!/^\.$|^\.\.$/, readdir($DH));
	@files = sort { -M "$dir/$a" cmp -M "$dir/$b" } @files;

	closedir ($DH);

	my $file_list = [];
	foreach my $file (@files)
		{
		next if -d $dir . '/' . $file;
		my $fileDetails = { name => $file };
		($fileDetails->{datecreated},$fileDetails->{size}) = $self->get_file_size_and_date_creation("$dir/$file");
		 push(@$file_list, $fileDetails);
		}

	#$c->log->debug("file_list: " . Dumper $file_list);

	$c->stash->{directory_file_list} = $file_list if @$file_list;
	}

sub upload :Local
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;

	my $Upload = $c->request->upload('orderfile');

	unless ($Upload)
		{
		$c->log->debug("File to be uploaded is not provided");
		return;
		}

	my $FILE_name = $Upload->filename;
	#$c->log->debug("Remote File: " . $Upload->filename . ", Server File: " . $FILE_name);

	my $token_id = $self->get_token_id;
	my $TMP_file = '/tmp/' . $token_id . '.csv';

	if( $Upload->link_to($TMP_file) or $Upload->copy_to($TMP_file) )
		{
		$c->stash->{MESSAGE} = "File '" . $Upload->filename . "' uploaded successfully!";
		$c->log->debug("Order File Upload Path, " . $TMP_file);
		}

	my $TARGET_file = $self->get_directory . "/\Q$FILE_name\E";
	$TARGET_file .= '.' . IntelliShip::DateUtils->timestamp if stat $TARGET_file;

	$c->log->debug("##### Target file $TARGET_file");
	$c->log->debug("##### Target file $TARGET_file");
	$c->log->debug("cp $TMP_file $TARGET_file");

	if (system "cp $TMP_file $TARGET_file")
		{
		$c->log->debug("... Unable to copy to destination " . $TARGET_file);
		$c->stash->{MESSAGE} = "File Copy Error: " . $!;
		$c->detach("setup",$params);
		}
=cut
	if (system "/opt/engage/intelliship/html/uploadorders.sh $token_id")
		{
		$c->stash->{MESSAGE} = "Upload Order Error: " . $!;
		$c->detach("setup",$params);
		return;
		}

	$c->log->debug("... File converted successfully from CSV to TXT");

	if (system "/opt/engage/intelliship/html/import_tab.pl")
		{
		$c->stash->{MESSAGE} = "File Import Process Error: " . $!;
		$c->detach("setup",$params);
		return;
		}
=cut
	my $ImportHandler = IntelliShip::Import::Orders->new;
	$ImportHandler->API($self->API);
	$ImportHandler->context($self->context);
	$ImportHandler->contact($self->contact);
	$ImportHandler->customer($self->customer);
	$ImportHandler->import_file($TMP_file);
	$ImportHandler->import;

	my $msg;
	if ($ImportHandler->has_errors)
		{
		$msg = $ImportHandler->errors->[0];
		}
	else
		{
		$msg = "File imported successfully";
		}

	$c->log->debug("... " . $msg);
	$c->stash->{MESSAGE} = $msg;

	$c->detach("setup",$params);
	}

sub get_directory :Private
	{
	my $self = shift;
	my $params = $self->context->req->params;

	my $TARGET_dir = IntelliShip::MyConfig->import_directory;
	$TARGET_dir .= '/' . 'co' if $params->{type} eq 'ORDER';
	$TARGET_dir .= '/' . 'productsku' if $params->{type} eq 'PRODUCTSKU';
	$TARGET_dir .= '/' . $self->customer->username;

	unless (IntelliShip::Utils->check_for_directory($TARGET_dir))
		{
		$self->context->log->debug("Unable to create target directory, " . $!);
		return;
		}

	return $TARGET_dir;
	}

sub get_file_size_and_date_creation
	{
	my $self = shift;
	my $file_path = shift;

	my @file_status = stat($file_path);

	my $bytes = $file_status[7];
	my $size = sprintf "%.2f KB", ($bytes/1024);

	my $datetime_string = IntelliShip::DateUtils->display_timestamp(IntelliShip::DateUtils->timestamp($file_status[9]));

	#$self->context->log->debug("File: " . $file_path . ", Created On: " . $datetime_string . ", Size: " . $size);

	return ($datetime_string,$size);
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
