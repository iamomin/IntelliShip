package IntelliShip::Carrier::Handler;

use Moose;
use Data::Dumper;
use IntelliShip::Carrier::Response;
use IntelliShip::Carrier::Constants;

BEGIN {
	has 'CO' => ( is => 'rw' );
	has 'token' => ( is => 'rw' );
	has 'context' => ( is => 'rw' );
	has 'carrier' => ( is => 'rw' );
	has 'customer' => ( is => 'rw' );
	has 'request_data' => ( is => 'rw' );
	has 'request_type' => ( is => 'rw' );
	}

my $carriers = {
	'FEDEX' => &CARRIER_FEDEX,
	};

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
	return $self->model->('MyDBI');
	}


sub process_request
	{
	my $self = shift;
	my $input_hash = shift;

	###############################################
	# GET INPUT
	###############################################
	my ($context,$myDBI);

	$context  = $input_hash->{'CONTEXT'};
	$myDBI    = $input_hash->{'MYDBI'};

	###############################################
	# SETUP DB CONNECTION
	###############################################

	my $Response = IntelliShip::Carrier::Response->new;

	unless ($context)
		{
		$Response->message('Accessed is denied. Invalid request context');
		$Response->response_code('100');
		return $Response;
		}

	unless ($myDBI)
		{
		$myDBI = $self->myDBI;
		}

	unless ($myDBI)
		{
		$Response->message('Accessed is denied. Invalid DB');
		$Response->response_code('1001');
		return $Response;
		}

	###############################################
	# AUTHORIZE CUSTOMER USER
	###############################################

	my $userProfile;

	unless ($input_hash->{'NO_TOKEN_OPTION'})
		{
		unless ($self->token)
			{
			$Response->message('Accessed is denied. Invalid token');
			$Response->response_code('102');
			return $Response;
			}

		unless (my $Token = $self->model('MyDBI::Token')->find({ tokenid => $self->tokenid}))
			{
			$Response->message('Accessed is denied. Invalid token');
			$Response->response_code('103');
			return $Response;
			}
		}

	###############################################
	# IDENTIFY TRANSACTION BROKER
	###############################################
	my $DriverModule = "IntelliShip::Carrier::Driver::" . $carriers->{uc $self->carrier} . "::" . $self->request_type;

	eval "use $DriverModule;";

	if ($@)
		{
		print STDERR "\n$@\n";
		$Response->message($@);
		$Response->response_code('103');
		return $Response;
		}

	###############################################
	# CALL BROKER AND POPULATE REQUEST INFO
	###############################################

	my $Driver = $DriverModule->new;
	$Driver->DB_ref($myDBI);
	$Driver->context($self->context);
	$Driver->customer($self->customer);
	$Driver->data($self->request_data);

	###############################################
	# GET POPULATED RESPONSE OBJECT
	###############################################

	my $response;

	eval {
	$response = $Driver->process_request;
	};

	if ($@)
		{
		my $error_detail = $@;
		chomp $error_detail;
		$Response->message($error_detail);
		$Response->response_code('104');
		return $Response;
		}

	$Response->response_code('0');
	$Response->is_success(1);
	$Response->data($response);

	return $Response;
	}

__PACKAGE__->meta()->make_immutable();

no Moose;

1;

__END__