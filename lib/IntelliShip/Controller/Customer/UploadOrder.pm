package IntelliShip::Controller::Customer::UploadOrder;
use Moose;
use IO::File;
use Data::Dumper;
use namespace::autoclean;

BEGIN { extends 'IntelliShip::Controller::Customer'; }

=head1 NAME

IntelliShip::Controller::Customer::UploadOrder - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;
	my $params = $c->req->params;

    #$c->response->body('Matched IntelliShip::Controller::Customer::UploadOrder in Customer::UploadOrder.');$c->log->debug("BATCH SHIPPINH");
	my $do_value = $params->{'do'} || '';
	if ($do_value eq 'upload')
		{
		$self->upload_order_file;
		}
	else
		{
		$self->setup_upload_order;
		}
	}

sub setup_upload_order :Private
	{
	my $self = shift;
	my $c = $self->context;
	my $params = $c->req->params;
	$self->display_uploaded_order_files;
	$c->stash(template => "templates/customer/upload-order.tt");
	}

sub display_uploaded_order_files
	{
	my $self = shift;
	my $c = $self->context;

	my $dir = $self->get_order_directory;
	return unless $dir;

	my $DH = new IO::File;

	unless ( opendir $DH , $dir )
		{
		$c->log->debug("Could not open directory \"$dir\" $!");
		return;
		}

	my @files = grep (!/^\.$|^\.\.$/, readdir($DH));
	closedir ($DH);

	my ($dir_array,$file_array) = ([],[]);

	foreach my $file (@files) 
		{
		-d $dir . '/' . $file ? push(@$dir_array, $file) : push(@$file_array, $file);
		}

	@$dir_array  = sort {uc($a) cmp uc($b)} @$dir_array;
	@$file_array = sort {uc($a) cmp uc($b)} @$file_array;

	#$c->log->debug("dir_array: " . Dumper $dir_array);
	#$c->log->debug("file_array: " . Dumper $file_array);

	$c->stash->{directory_file_list} = [
		{ caption => 'Directory', items => $dir_array },
		{ caption => 'Files', items => $file_array },
		];
	}

sub upload_order_file :Private
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
	$FILE_name =~ s/\s+/\_/g;

	my $TARGET_dir = $self->get_order_directory;

	return unless $TARGET_dir;

	my $TARGET_file = $TARGET_dir . '/' . $FILE_name;

	if( $Upload->link_to($TARGET_file) or $Upload->copy_to($TARGET_file) ) 
		{
		$c->stash->{MESSAGE} = "File \"" . $FILE_name . "\" uploaded successfully!";
		$c->log->debug("Order File Upload Full Path, " . $TARGET_file);
		}

	$self->setup_upload_order;
	}

sub get_order_directory :Private
	{
	my $self = shift;
	my $TARGET_dir = IntelliShip::MyConfig->file_directory . '/orders';

	unless (IntelliShip::Utils->check_for_directory($TARGET_dir))
		{
		$self->context->log->debug("Unable to create target directory, " . $!);
		return;
		}

	return $TARGET_dir;
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
