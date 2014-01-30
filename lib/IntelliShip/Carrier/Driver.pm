package IntelliShip::Carrier::Driver;

use Moose;
use Data::Dumper;
use IntelliShip::Utils;

BEGIN {

	extends 'IntelliShip::Errors';

	has 'CO' => ( is => 'rw' );
	has 'context' => ( is => 'rw' );
	has 'customer' => ( is => 'rw' );
	has 'DB_ref' => ( is => 'rw' );
	has 'data' => ( is => 'rw' );
	has 'customerservice' => ( is => 'rw' );
	has 'service' => ( is => 'rw' );
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

sub get_token_id
	{
	my $self = shift;
	return $self->context->controller->get_token_id;
	}

sub process_request
	{
	my $self = shift;
	}

sub TagPrinterString
	{
	my $self = shift;
	#my ($string,$ordernumber) = @_;
	#my $tagged_string = '';
    #
	#my @string_lines = split("\n",$string);
    #
	## Check for order stream, and add it to main stream, if it exists
	#my $CO = new CO($self->{'dbref'}, $self->{'customer'});
	#my ($ID) = $CO->GetCurrentCOID($ordernumber,$self->{'customer'}->GetValueHashRef()->{'customerid'});
	#$CO->Load($ID);
    #
	#my $Stream = $CO->GetValueHashRef()->{'stream'};
	#if ( defined($Stream) && $Stream ne '' )
	#{
	#	push(@string_lines,split(/\~/,$Stream));
	#}
    #
	#$tagged_string .= ".\n";
	#foreach my $line (@string_lines)
	#{
	#	# Need to reverse print direction of local labels
	#	if ( $line eq 'ZT' )
	#	{
	#		$line = 'ZB';
	#	}
    #
	#	if ( $line =~ /Svcs/ || $line =~ /TRCK/ || $line =~ /CLS/ )
	#	{
	#		next;
	#	}	
	#	$tagged_string .= "$line\n";
	#}
    #
	#$tagged_string .= "R0,0\n";
	#$tagged_string .= ".\n\n";
    #
	#return $tagged_string;
	}

sub log
	{
	my $self = shift;
	my $msg = shift;
	if ($self->context)
		{
		$self->context->log->debug($msg);
		}
	else
		{
		print STDERR "\n" . $msg;
		}
	}

__PACKAGE__->meta()->make_immutable();

no Moose;

1;

__END__