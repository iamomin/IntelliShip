package IntelliShip::Carrier::Driver;

use Moose;
use Data::Dumper;
use IntelliShip::Utils;

BEGIN {
	has 'CO' => ( is => 'rw' );
	has 'context' => ( is => 'rw' );
	has 'customer' => ( is => 'rw' );
	has 'DB_ref' => ( is => 'rw' );
	}

sub model
	{
	my $self = shift;
	my $model = shift;

	if ($self->context)
		{
		return $self->context->model($model);
		}
	}

sub myDBI
	{
	my $self = shift;
	$self->DB_ref($self->model->('MyDBI')) unless $self->DB_ref;
	return $self->DB_ref if $self->DB_ref;
	}

sub process_request
	{
	my $self = shift;
	}

__PACKAGE__->meta()->make_immutable();

no Moose;

1;

__END__