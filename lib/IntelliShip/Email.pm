package IntelliShip::Email;

use Moose;
use IO qw(File);
use Email::Stuff;
use IntelliShip::MyConfig;

has 'to'			=> ( is => 'rw', isa => 'ArrayRef' );
has 'cc'			=> ( is => 'rw', isa => 'ArrayRef' );
has 'bcc'			=> ( is => 'rw', isa => 'ArrayRef' );
has 'subject'		=> ( is => 'rw' );
has 'body'			=> ( is => 'rw' );
has 'from_address'	=> ( is => 'rw' );
has 'from_name'		=> ( is => 'rw' );
has 'attach'		=> ( is => 'rw' );
has 'sendmail_path'	=> ( is => 'rw' );
has 'content_type'	=> ( is => 'rw' );

has 'allow_send_from_dev' => ( is => 'rw' );

sub BUILD
	{
	my $self = shift;
	$self->to([]);
	$self->cc([]);
	$self->bcc([]);
	$self->sendmail_path(IntelliShip::MyConfig->getSendmailPath);
	}

sub send_to
	{
	my $self = shift;
	$self->add_to(@_);
	}

sub add_to
	{
	my $self = shift;
	if (@_)
		{
		my $value = shift;
		push (@{$self->to}, $value);
		}
	}

sub add_cc
	{
	my $self = shift;
	if (@_)
		{
		my $value = shift;
		push (@{$self->cc}, $value);
		}
	}

sub add_bcc
	{
	my $self = shift;
	if (@_)
		{
		my $value = shift;
		push (@{$self->bcc}, $value);
		}
	}

sub add_line
	{
	my $self = shift;
	if (@_)
		{
		my $line = shift;
		my $body = $self->body;
		$body .= $line . ($self->content_type =~ /HTML/i ? "<br>" : "\n");
		$self->body($body);
		}
	}

sub send_now
	{
	my $self = shift;
	return $self->send(@_);
	}

sub send
	{
	my $self = shift;

	my $EMAIL = new IO::File;

	my ($bcc_list, $to_list, $cc_list) = ('','','');

	$to_list  .= join(',', @{$self->to});
	$cc_list  .= join(',', @{$self->cc});
	$bcc_list .= join(',', @{$self->bcc});


	my $from_address = $self->from_address;
	$from_address =~ s/,//g;

	my $from;
	if ($self->from_name)
		{
		my $from_name = $self->from_name;
		$from_name =~ s/,//g;
		$from = "$from_name <$from_address>";
		}
	else
		{
		$from = $from_address;
		}

	#print STDERR "\n From   : " . $from;
	#print STDERR "\n To     : " . $to_list;
	#print STDERR "\n CC     : " . $cc_list if $cc_list;
	#print STDERR "\n BCC    : " . $bcc_list if $bcc_list;
	#print STDERR "\n Subject: " . $self->subject;
	#print STDERR "\n Body   : \n" . $self->body;
	#return;

	if (IntelliShip::MyConfig->getDomain eq &DEVELOPMENT)
		{
		if ($self->allow_send_from_dev)
			{
			#$to_list  = 'imranm@alohatechnology.com';
			#$cc_list  = 'tsharp@engagetechnology.com';
			}
		else
			{
			#return 1;
			}

		$to_list  = 'imranm@alohatechnology.com';
		$cc_list  = 'noc@engagetechnology.com';
		}

	if ($self->attach)
		{
		my $EmailStuff = Email::Stuff->new;
		$EmailStuff->To($to_list);
		$EmailStuff->CC($cc_list) if ($cc_list);
		$EmailStuff->BCC($bcc_list) if ($bcc_list);
		$EmailStuff->From($from);
		$EmailStuff->Subject($self->subject);

		if ($self->content_type =~ /HTML/i)
			{
			$EmailStuff->html_body($self->body);
			}
		else
			{
			$EmailStuff->text_body($self->body);
			}

		$EmailStuff->attach_file($self->attach);
		$EmailStuff->send;
		}
	else
		{
		my $mailprog = $self->sendmail_path;

		unless (open ($EMAIL,"|$mailprog -t"))
			{
			print STDERR "\nFailed to communicate with sendmail";
			print STDERR "\nSendmail not accessible $!";
			return undef;
			}

		print $EMAIL "To: $to_list\n" if ($to_list);
		print $EMAIL "CC: $cc_list\n" if ($cc_list);
		print $EMAIL "BCC: $bcc_list\n" if ($bcc_list);
		print $EMAIL "From: " . $from . "\n"; 
		print $EMAIL "Subject: " . $self->subject . "\n";

		if ($self->content_type)
			{
			print $EMAIL "Content-Type: " . $self->content_type . "\n";
			}

		print $EMAIL "\n";
		print $EMAIL $self->body;
		close ($EMAIL);
		}

	return 1;
	}

__PACKAGE__->meta()->make_immutable();

no Moose;

1;

__END__