package IntelliShip::Errors;

use Moose;
use namespace::autoclean;

BEGIN { has 'errors' => ( is => 'rw', isa => 'ArrayRef' ); }

sub BUILD
	{
	my $self = shift;
	$self->errors([]);
	}

sub clear_errors
	{
	my $self = shift;
	$self->errors([]);
	return 1;
	}

sub has_errors
	{
	my $self = shift;
	return scalar @{$self->errors};
	}

sub add_error
	{
	my $self = shift;
	my $error_msg = shift;
	return undef unless $error_msg;
	my $err_array = $self->errors;
	push (@$err_array, $error_msg);
	}

sub print_errors
	{
	my $self = shift;
	my $type = shift || "COMMENTS"; ### HTML, COMMENTS, TEXT

	my $errors_output = "";

	if ($self->errors)
		{
		my $errors_array = $self->errors;

		foreach my $errorMsg (@$errors_array)
			{
			if ($type =~ /HTML/)
				{
				$errors_output .= "<LI>$errorMsg\n";
				}
			elsif ($type =~ /COMMENTS/)
				{
				$errors_output .= "<!----- $errorMsg ------>\n";
				}
			elsif ($type =~ /TEXT/)
				{
				$errors_output .= "$errorMsg\n";
				}
			}
		}
	else
		{
		return undef;
		}

	return $errors_output;
	}

__PACKAGE__->meta()->make_immutable();

no Moose;

1;

__END__