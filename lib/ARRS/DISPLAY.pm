#!/usr/bin/perl -w

#####################################################################
#####################################################################
##
## display.pl
##
#####################################################################
##
## Generic core module that handles displaying
## Engage TMS template files
##
#####################################################################
##
## Author(s):	Kirk Aksdal
##					Leigh Bohannon
## Created:		05/01/2001
##
#####################################################################
#####################################################################

{
	package ARRS::DISPLAY;

	use strict;

	use ARRS::COMMON;

	sub new
	{
		my $proto = shift;
		my $class = ref($proto) || $proto;

		my ($TemplateDir) = @_;

		my $self = {};

		$self->{'templatedir'} = $TemplateDir;

		bless($self, $class);

		return $self;
	}

	#####################################################################
	#
	# SubstituteToken
	#
	#####################################################################
	#
	# Does the actual token subs inteligently
	#
	#####################################################################
	sub SubstituteToken
	{
		my $self = shift;

		my ($HashRef, $VarRef) = @_;
		my $TemplateDir = $self->{'templatedir'};

		my $Value = '';

		$VarRef->{'type'} = defined($VarRef->{'type'}) ? $VarRef->{'type'} : 'string';

		if ( $VarRef->{'type'} eq 'dropdown' )
		{
			my $DropRef = $HashRef->{'hash_'.$VarRef->{'name'}};

			if (defined($VarRef->{'showzero'}) && $VarRef->{'showzero'} ne '0')
			{
				$Value = "<option value='0'>Select One</option>";
			}

			if (defined($DropRef))
			{
				foreach my $Counter (sort {$a <=> $b} keys(%$DropRef))
				{
					my $RowRef = $DropRef->{$Counter};
					my $Key = $RowRef->{'key'};
					my $ValueStr = $RowRef->{'value'};

					local $^W = 0;
					$Value .= "<option value='$Key'";

					if (
						(
							defined($VarRef->{'value'}) &&
							defined($HashRef->{$VarRef->{'value'}}) &&
							$Key eq $HashRef->{$VarRef->{'value'}}
						) ||
						(
							!defined($HashRef->{$VarRef->{'value'}}) &&
							defined($VarRef->{'default'}) &&
							$VarRef->{'default'} eq $Key
						)
					)
					{
						$Value .= " selected";
					}
					$Value .= ">" . $ValueStr . "</option>";
					local $^W = 1;
				}
			}
		}
		elsif ( $VarRef->{'type'} eq 'include' )
		{
			$Value = $self->TranslateTemplate($VarRef->{'name'}.'.include', $HashRef)
		}
		elsif ( $VarRef->{'type'} eq 'section' )
		{
			my $SectionRef = $HashRef->{'hash_'.$VarRef->{'name'}};

			if (defined($SectionRef))
			{
				foreach my $Key (sort {$a <=> $b} keys(%$SectionRef))
				{
					my %TempHash = (%$HashRef, %{$SectionRef->{$Key}});
					$TempHash{'linenumber'} = $Key;
					$Value .= $self->TranslateTemplate($VarRef->{'name'}.'.section', \%TempHash);
				}
			}
		}
		elsif ( $VarRef->{'type'} eq 'radio' )
		{
			my $HashValue = defined($HashRef->{$VarRef->{'name'}}) ? $HashRef->{$VarRef->{'name'}} : '';
			$Value = '<input type=radio name=' . $VarRef->{'name'};
			$Value .= ' value=' . $VarRef->{'value'};

			if ( $VarRef->{'javascript'} )
			{
				$Value .= ' ' . $VarRef->{'javascript'};
			}

			if ($HashValue eq $VarRef->{'value'})
			{
				$Value .= ' checked';
			}
			$Value .= '>';
		}
		elsif ( $VarRef->{'type'} eq 'checkbox' )
		{
			$Value = '<input type=checkbox name=' . $VarRef->{'name'};
			$Value .= ' value=1';

			if ( $VarRef->{'index'} )
			{
				 $Value .= " tabindex=$VarRef->{'index'}";
			}

			if ( $VarRef->{'javascript'} )
			{
				$Value .= ' ' . $VarRef->{'javascript'};
			}

			if ($HashRef->{$VarRef->{'name'}})
			{
				$Value .= ' checked';
			}

			$Value .= '>';
		}
		elsif ( $VarRef->{'type'} eq 'string' )
		{
			$VarRef->{'format'} = defined($VarRef->{'format'}) ? $VarRef->{'format'} : 'string';

			if ( $VarRef->{'format'} eq 'currency' )
			{
				$Value = $HashRef->{$VarRef->{'name'}};
				$Value = defined($Value) ? sprintf("%.2f", $Value) : "0.00";
			}
			elsif ( $VarRef->{'format'} eq 'numeric' )
			{
				$Value = $HashRef->{$VarRef->{'name'}};
				$Value = defined($Value) ? sprintf("%d", $Value) : "0";
			}
			elsif ( $VarRef->{'format'} eq 'date' )
			{
				$Value = $HashRef->{$VarRef->{'name'}};
				$Value = defined($Value) ? $Value : "";
			}
			elsif ( $VarRef->{'format'} eq 'time' )
			{
				$Value = $HashRef->{$VarRef->{'name'}};
				$Value = defined($Value) ? $Value : "";
			}
			elsif ( $VarRef->{'format'} eq 'string' )
			{
				$Value = $HashRef->{$VarRef->{'name'}};
				$Value = defined($Value) ? $Value : "";
			}

			if ($Value eq '' && defined($VarRef->{'default'}))
			{
				$Value = $VarRef->{'default'};
			}
		}

		return $Value;
	}

	#####################################################################
	#
	# SubstituteVariable
	#
	#####################################################################
	#
	#	Translates an html tag into a hash reference for later use
	#
	#####################################################################
	sub SubstituteVariable
	{
		my $self = shift;

		my ($VarString) = @_;
		my $VarHashRef = {};

		my $Count = 0;

		while (length($VarString))
		{
			if (substr($VarString, 0, 1) eq ' ')
			{	# Take care of leading spaces
				$VarString = substr($VarString, 1);
			}
			elsif ($VarString =~ m/^(\w+)="(.*)"/)
			{	# Take care of double quotes
				my $Length = length($1) + length($2) + 3;
				my $VarLength = length($VarString);
				my $NewLength = $VarLength - $Length;
				$VarString = substr($VarString, $Length, $NewLength);
				$VarHashRef->{$1} = $2;
			}
			elsif ($VarString =~ m/^(\w+)='(.*)'/)
			{	# Take care of single quotes
				my $Length = length($1) + length($2) + 3;
				my $VarLength = length($VarString);
				my $NewLength = $VarLength - $Length;
				$VarString = substr($VarString, $Length, $NewLength);
				$VarHashRef->{$1} = $2;
			}
			elsif($VarString =~ m/^(\w+)=(\w+)/)
			{	# Take care of no quotes
				my $Length = length($1) + length($2) + 1;
				my $VarLength = length($VarString);
				my $NewLength = $VarLength - $Length;
				$VarString = substr($VarString, $Length, $NewLength);
				$VarHashRef->{$1} = $2;
			}

			# The oh shit button.  makes sure we don't spin out of control
			if ($Count++ > 100)
			{
				die;
			}
		}

		return $VarHashRef;
	}

	#####################################################################
	#
	# DisplayScreen
	#
	#####################################################################
	#
	#	Outputs the contents of the screen substituting tokens.
	#
	#####################################################################

	sub TranslateTemplate
	{
		my $self = shift;
		my ($ScreenName, $HashRef) = @_;
#WarnHashRefValues($HashRef->{'hash_vought_bolpackagelist'});

		my $TemplateDir = $self->{'templatedir'};

		open(TEMPLATE, $TemplateDir . "/$ScreenName")
			or die "Cannot open $TemplateDir/$ScreenName";

		my $Output = '';
		foreach my $line (<TEMPLATE>)
		{
			$line =~ s/<var\s+(.*?)\s*>/$self->SubstituteToken($HashRef, $self->SubstituteVariable($1))/eg;
			$Output .= $line;
		}

		close(TEMPLATE);

		return $Output;
	}

	sub TranslateString
	{
		my $self = shift;
		my ($String, $HashRef) = @_;

		$String =~ s/<var\s+(.*?)\s*>/$self->SubstituteToken($HashRef, $self->SubstituteVariable($1))/eg;

		return $String;
	}

	sub DisplayScreen
	{
		my $self = shift;
		my ($ScreenName,$HashRef) = @_;

		my $TemplateDir = $self->{'templatedir'};

		# Stuff to handle template pagination
		open(TEMPLATE, $TemplateDir . "/$ScreenName")
			or die "Cannot open $TemplateDir/$ScreenName";

		my @Lines = <TEMPLATE>;
		my @SectionRefs = ();
		my $SectionName = '';
		my @Fields = ();

		if (  my ($Line) = grep(/maxperpage=\d+/, @Lines) )
		{
			# Get keys/values out of tag
			my ($Vars) = $Line =~ /<var\s+(.*?)\s*>/;
			my $VarRef = $self->SubstituteVariable($Vars);
			$SectionName = $VarRef->{'name'};

			my $SectionRef = $HashRef->{'hash_' . $SectionName};

			# Get list of fields in the section hash, for later use
			my $FieldRef = $SectionRef->{'0'};
			@Fields = keys(%$FieldRef);

			# Build dummy ref to fill page(s) out, if filltomax is true
			my $DummyRef = {};
			foreach my $Field (@Fields)
			{
				$DummyRef->{$Field} = '';
			}

			my @TempSectionRefs = ();
			foreach my $Key (sort {$a <=> $b}(keys (%$SectionRef)))
			{
				push(@TempSectionRefs,$SectionRef->{$Key});
			}

			# Fill out main page section
			my $MainRef = {};
			my $MainCounter = 0;

			while ( $MainCounter < $VarRef->{'maxperpage'} )
			{
				if ( @TempSectionRefs )
				{
					$MainRef->{$MainCounter++} = shift(@TempSectionRefs);

					if
					(
						scalar(keys(%$SectionRef)) > $VarRef->{'maxperpage'} &&
						$MainCounter == ($VarRef->{'maxperpage'} - 3) &&
						$VarRef->{'ofmsgfield'}
					)
					{
						$MainRef->{$MainCounter++} = $DummyRef;

						my $NextRef = {};
						foreach my $Field (@Fields)
						{
							if ( $Field = $VarRef->{'ofmsgfield'} )
							{
								$NextRef->{$Field} = $VarRef->{'ofmsg'};
							}
							else
							{
								$NextRef->{$Field} = '';
							}
						}

						$MainRef->{$MainCounter++} = $NextRef;

						$MainRef->{$MainCounter++} = $DummyRef;
					}
				}
				else
				{
					if ( $VarRef->{'filltomax'} )
					{
						$MainRef->{$MainCounter++} = $DummyRef;
					}
					else
					{
						last
					}
				}
			}
			push(@SectionRefs,$MainRef);

			# Fill out  overflow page sections
			$VarRef->{'maxperoverflow'} = $VarRef->{'maxperoverflow'} ? $VarRef->{'maxperoverflow'} : $VarRef->{'maxperpage'};

			my $OFRef = {};
			my $OFCounter = 0;

			while ( @TempSectionRefs )
			{
				$OFRef->{$OFCounter++} = shift(@TempSectionRefs);

				# If our ref arrray is empty, and we're supposed to fill the page, do so here
				if ( $VarRef->{'filltomax'}  && scalar(@TempSectionRefs) == 0 && $OFCounter < $VarRef->{'maxperoverflow'} )
				{
					while ( $OFCounter < $VarRef->{'maxperoverflow'} )
					{
						$OFRef->{$OFCounter++} = $DummyRef
					}
				}

				#  Push our hash out to the ref array, if we're at the max records per overflow, or if we're out of records
				if ( $OFCounter == $VarRef->{'maxperoverflow'} || scalar(@TempSectionRefs) == 0 )
				{
					push(@SectionRefs,$OFRef);
					$OFCounter = 0;
					$OFRef = {};
				}
			}
		}

		if ( scalar(@SectionRefs) > 0 )
		{
			$HashRef->{'totalpages'} = scalar(@SectionRefs);
			$HashRef->{'currentpage'} = 1;
			$HashRef->{'hash_' . $SectionName} = shift(@SectionRefs);
		}

		# Normal template output
		my $Output = $self->TranslateTemplate(@_);


		# Overflow template handling (for pagination)
		if ( scalar(@SectionRefs) > 0 )
		{
			my ($ScreenBase,$ScreenSuffix) = $ScreenName =~ /(\w+)\.(template)/;

			my $OFScreenName = $ScreenBase . 'of.' . $ScreenSuffix;

			if ( !-r "$TemplateDir/$OFScreenName" )
			{
				$OFScreenName = $ScreenName;
			}

			while ( @SectionRefs )
			{
				open(OFTEMPLATE, "$TemplateDir/$OFScreenName")
					or die "Cannot open $TemplateDir/$OFScreenName";

				$HashRef->{'currentpage'}++;
				$HashRef->{'hash_' . $SectionName} = shift(@SectionRefs);

				foreach my $line (<OFTEMPLATE>)
				{
					$line =~ s/<var\s+(.*?)\s*>/$self->SubstituteToken($HashRef, $self->SubstituteVariable($1))/eg;
					$Output .= $line;
				}

				close(OFTEMPLATE)
					or die "Could not close $TemplateDir/$OFScreenName";
			}
		}

		print $Output;
	}

	sub SaveScreen
	{
		my $self = shift;

		my ($Filename, $ScreenName, $HashRef) = @_;

		my $Output = $self->TranslateTemplate($ScreenName, $HashRef);

		open(OUTFILE, ">".$Filename)
			or die "Cannot open $Filename";

#		select(OUTFILE);
#
#		$self->DisplayScreen($ScreenName, $HashRef);
#
#		select(STDOUT);

		print OUTFILE $Output;

		close(OUTFILE);
	}


	sub sendemail
	{
		my $self = shift;

		my ($EmailInfo, $HashRef, $Screen) = @_;

		my
			(
				$FromEmail,
				$FromName,
				$ToEmail,
				$ToName,
				$Subject,
				$Cc,
				$Bcc,
			) =
			(
				$EmailInfo->{'fromemail'},
				$EmailInfo->{'fromname'},
				$EmailInfo->{'toemail'},
				$EmailInfo->{'toname'},
				$EmailInfo->{'subject'},
				$EmailInfo->{'cc'},
				$EmailInfo->{'bcc'},

			);


		my $TemplateDir = $self->{'templatedir'};

		my $EmailBody = $self->TranslateTemplate($Screen, $HashRef);

		my $OpenString = "/usr/sbin/sendmail -t ";
		$OpenString .= " -f\"$FromEmail\"";
		$OpenString .= " -F\"$FromName\"";

		if ( &GetServerType == 3 )
		{
			$Subject = 'TEST ' . $Subject;
		}

		open(ATMAIL, "|".$OpenString);
		print ATMAIL "From: $FromName <$FromEmail>\n";
		print ATMAIL "Reply-To: $FromName <$FromEmail>\n";

		if ( defined($ToEmail) && $ToEmail ne '' )
		{
			print ATMAIL "To: $ToName <$ToEmail>\n";
		}

		if ( defined($Cc) ) { print ATMAIL "Cc: <$Cc>\n"; }
		if ( defined($Bcc) ) { print ATMAIL "Bcc: <$Bcc>\n"; }
		print ATMAIL "Subject: $Subject\n";
		print ATMAIL "\n";
		print ATMAIL $EmailBody . "\n";
		close(ATMAIL);

		return;
	}
}

1;
