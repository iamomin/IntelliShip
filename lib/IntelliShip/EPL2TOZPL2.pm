package IntelliShip::EPL2TOZPL2;

use Moose;
use Data::Dumper;

# Convert entire EPL2 print stream to ZPL2
sub ConvertStreamEPL2ToZPL2
{
	my $self = shift;
	my ($EPL2Stream) = @_;
	my $ZPL2Stream;

	my @EPL2Stream = split(/\n/,$EPL2Stream);

	$ZPL2Stream .= "^XA\n";

	# This tweaks the 'top of label'.  Maybe needed, maybe not (showed necessary in UPS testing)
	# Values = +/- 120 (in dots).  Negative values move printing up on label.
	$ZPL2Stream .= "^LT-20\n";

	foreach my $EPL2String (@EPL2Stream)
	{
		# Skip blank lines
		if ( $EPL2String eq "" ) { next }

		# Skip . lines
		if ( $EPL2String eq "." ) { next }

		if ( defined($EPL2String) && $EPL2String ne '' )
		{
			if ( my $ZPL2Line = $self->ConvertStringEPL2ToZPL2($EPL2String) )
			{
				$ZPL2Stream .= $ZPL2Line . "\n";
			}
			else
			{
			}
		}
		else
		{
			$ZPL2Stream .= "\n";
		}

	}

	$ZPL2Stream .= "^XZ\n";

	return $ZPL2Stream;
}

# Convert individual EPL2 string to ZPL2
sub ConvertStringEPL2ToZPL2
{
	my $self = shift;
	my ($EPL2String) = @_;
	my $ZPL2String;

	my ($StringType,$StringData) = $EPL2String =~ /^(.)(.*)$/;

	if ( $StringType eq 'A' )
	{
		local $^W = 0;
		my ($XPos,$YPos,$Rot,$FontType,$XMult,$YMult,$Rev,$Data) =
			$StringData =~ /(\d+),(\d+),(\d),(\w),(\d),(\d),(\w),"(.*)"/;
		local $^W = 1;

		my ($FO,$ZRot,$ZXMult,$ZYMult,$ZFont,$FD,$FR);

		# Rotation translation
		if ( $Rot eq '0' )
		{
			$FO = 'FO';
			$ZRot = 'N';
		}
		elsif ( $Rot eq '1' )
		{
			$FO = 'FO';
			$ZRot = 'R';
		}
		elsif ( $Rot eq '2' )
		{
			$FO = 'FO';
			$ZRot = 'I';
		}
		elsif ( $Rot eq '3' )
		{
			$FO = 'FT';
			$ZRot = 'B';
		}

		# Basic font translation
		# Kludge for EGL Airport Code and Zone
		if ( $EPL2String =~ /A180,360,0,5,4,4,R/ || $EPL2String =~ /A620,360,0,5,4,4,R/ )
		{
			$ZXMult = 60;
			$ZYMult = 60;
			$ZFont = '^CI,157,48,240,45^A0';
		}
		elsif ( $FontType eq '1' )
		{
			$ZXMult = 20;
			$ZYMult = 16;
			$ZFont = '^CI,157,48,240,45^A0';
		}
		elsif ( $FontType eq '2' )
		{
			$ZXMult = 10;
			$ZYMult = 18;
			$ZFont = '^CI,48,48,45,45^AD';
		}
		elsif ( $FontType eq '3' )
		{
			$ZXMult = 25;
			$ZYMult = 20;
			$ZFont = '^CI,157,48,240,45^A0';
		}
		elsif ( $FontType eq '4' )
		{
			$ZXMult = 31;
			$ZYMult = 28;
			$ZFont = '^CI,157,48,240,45^A0';
		}
		elsif ( $FontType eq '5' )
		{
			$ZXMult = 60;
			$ZYMult = 70;
			$ZFont = '^CI,157,48,240,45^A0';
		}
		elsif ( $FontType eq 't' )
		{
			$ZXMult = 13;
			$ZYMult = 13;
			$ZFont = '^CI,157,48,240,45^A0';
		}

		# Font multiplier/size translation
		if ( defined($XMult) && $XMult > 0 )
		{
			$ZXMult = $ZXMult * $XMult
		}

		if ( defined($YMult) && $YMult > 0 )
		{
			$ZYMult = $ZYMult * $YMult
		}

		# Data translation
		# Kludge to do carrier specific 'black boxes' for proper reverse-video output in ZPL2
		{
			my $BlackDrawn;
			# DHL Service
			if
			(
				$EPL2String eq 'A25,530,0,4,4,4,R," 2ND "' ||
				$EPL2String eq 'A25,530,0,4,4,4,R," 2NL "' ||
				$EPL2String eq 'A25,530,0,4,4,4,R," GRD "' ||
				$EPL2String eq 'A25,530,0,4,4,4,R," WPX "' ||
				$EPL2String eq 'A25,530,0,4,4,4,R," DOC "'
			)
			{
				$ZPL2String .= "^FO25,515^GB295,120,120^FS\n";
			}

			# DHL Package Count
			if ( $EPL2String =~ /A530,240,0,3,1,1,R,"Package #: \d+ of \d+"/ )
			{
				$ZPL2String .= "^FO520,235^GB210,0,28^FS\n";
			}

			# DHL Ground airport codes
			if ( $EPL2String =~ /A400,410,0,5,1,1,R,"  \w+\/\w+  "/ )
			{
				$ZPL2String .= "^FO375,400^GB345,0,75^FS\n";
			}

			# DHL TOS
			if ( $EPL2String eq 'A280,1205,0,2,1,1,R,"Please place in pouch"' )
			{
				$ZPL2String .= "^FO270,1200^GB280,0,32^FS\n";
			}

			# Generic Carrier
			if ( $EPL2String =~ /A25,690,0,3,2,2,R/ )
			{
				$ZPL2String .= "^FO0,670^GB815,0,70^FS\n";
			}

			# Generic Service
			if ( $EPL2String =~ /A25,750,0,3,2,2,R/ )
			{
				$ZPL2String .= "^FO0,740^GB815,0,60^FS\n";
			}

			# Generic Label Banner
			if ( $EPL2String =~ /A25,1015,0,3,1,1,R/ )
			{
				$ZPL2String .= "^FO0,1010^GB815,0,25^FS\n";
			}

			# BOL Header
			if ( $EPL2String eq 'A0,20,0,3,3,3,R,"  BILL OF LADING   "' )
			{
				$ZPL2String .= "^FO0,0^GB815,0,80^FS\n";
			}

			# Eagle Service
			if ( $EPL2String =~ /A540,50,0,3,5,6,R/ )
			{
				$ZPL2String .= "^FO530,45^GB240,0,110^FS\n";
			}

			# Eagle Dest Airport Code
			if ( $EPL2String =~ /A180,360,0,5,4,4,R/ )
			{
				$ZPL2String .= "^FO170,355^GB410,0,200^FS\n";
			}

			# Eagle Zone
			if ( $EPL2String =~ /A620,360,0,5,4,4,R/ )
			{
				$ZPL2String .= "^FO610,355^GB160,0,200^FS\n";
			}

			# Eagle Title
			if ( $EPL2String eq 'A45,835,0,3,2,2,R,"EGL Eagle Global Logistics"' )
			{
				$ZPL2String .= "^FO0,830^GB815,0,50^FS\n";
			}

			# FedEx Ground 'EPDI' line
			if ( $EPL2String eq 'A0,1173,0,3,1,1,R,"EPDI  EPDI  EPDI  EPDI  EPDI  EPDI  EPDI  EPDI  EPDI  EPDI"' )
			{
				$ZPL2String .= "^FO0,1164^GB830,0,30^FS\n";
				$Data = "EPDI  " x 13;
			}

			# UPS Ground Black Box Service Icon
			if ( $EPL2String eq 'A645,630,0,4,3,4,R,"  "' )
			{
				$ZPL2String .= "^FO645,630^GB95,0,95^FS\n";
			}

			if ( defined($ZPL2String) && $ZPL2String ne '' )
			{
				$BlackDrawn = 'Y';
			}

			if
			(
				( defined($Rev) && $Rev eq 'R' ) &&
				( defined($BlackDrawn) && $BlackDrawn eq 'Y' )
			)
			{
				$FR = '^FR';
			}
		}

		if ( defined($Data) && $Data ne '' )
		{
			$FD = '^FD';
			$Data =~ s/^"(.*)"$/$1/;
		}
		elsif ( defined($Data) && $Data eq 'V' )
		{
			$FD = '^FN';
		}

		# Build return string
		local $^W = 0;
		$ZPL2String .= "^" . $FO . $XPos . "," . $YPos . $ZFont . "," . $ZYMult . "," . $ZXMult . $FR . $FD . $Data . "^FS";
		local $^W = 1;
	}
	elsif ( $StringType eq 'B' )
	{
		my ($XPos,$YPos,$Rot,$Symbology,$NarrowBarWidth,$WideBarWidth,$BarHeight,$HumanReadable,$Data) =
			$StringData =~ /(\d+),(\d+),(\d+),(\w+),(\d+),(\d+),(\d+),(\w),"(.*)"/;

		my ($FO,$ZRot,$FD,$BC);

		# Convert 'HumanReadable'.  EPL2 and ZPL2 both agree that 'N'='no', but EPL2 has 'B'='yes'
		if ( $HumanReadable eq 'B' ) { $HumanReadable = 'Y' }

		# Rotation translation
		if ( $Rot eq '0' )
		{
			$FO = 'FO';
			$ZRot = 'N';
		}
		elsif ( $Rot eq '1' )
		{
			$FO = 'FO';
			$ZRot = 'R';
		}
		elsif ( $Rot eq '2' )
		{
			$FO = 'FO';
			$ZRot = 'I';
		}
		elsif ( $Rot eq '3' )
		{
			$FO = 'FT';
			$ZRot = 'B';
			$XPos = $XPos + $BarHeight;
		}

		# Data translation
		if ( defined($Data) && $Data ne "" )
		{
			$FD = '^FD';
			$Data =~ s/^"(.*)"$/$1/;
		}
		elsif ( defined($Data) && $Data eq 'V' )
		{
			$FD = '^FN';
		}

		# Weird ratio calc to translate barcode height and width
		my $BCRatio = int(($WideBarWidth * 100)/$NarrowBarWidth);
		my $RatioLength = length($BCRatio);
		my ($RATL,$RATR,$E);

		if ( $RatioLength > 3 )
		{
			$RATL = substr($BCRatio,0,2);
			$RATR = substr($BCRatio,2,3);
		}
		else
		{
			$RATL = substr($BCRatio,0,1);
			$RATR = substr($BCRatio,1,2);
		}

		if ( substr($RATR,1,1) > 4 )
		{
			$E = substr($RATR,0,1) + 1;
			$RATR = substr($RATR,0,1,$E);
		}

		# Symbology specific info
		# Code 128
		if ( $Symbology eq '1' )
		{
			$BC = "^BC" . $ZRot . "," . $BarHeight . "," . $HumanReadable . ",N,N,A";
		}
		# Code 39
		elsif ( $Symbology eq '3' || $Symbology eq '3C' )
		{
			my $CheckSum = 'N';
			if ( $Symbology eq '3C' )
			{
				$CheckSum = 'Y';
			}

			$BC = "^B3" . $ZRot . "," . $CheckSum . "," . $BarHeight . "," . $HumanReadable . ",N";
		}
		# UCC128
		elsif ( $Symbology eq '1E' )
		{
			$BC = "^BC" . $ZRot . ","  . $BarHeight . ",N,N,Y,D";
		}

		# Build return string
		$ZPL2String = "^BY" . $NarrowBarWidth . "," . $RATL . "." . $RATR . "^FS\n";
		$ZPL2String .= "^" . $FO . $XPos . "," . $YPos . $BC . $FD . $Data . "^FS";
	}
	elsif ( $StringType eq 'b' )
	{
		my ($XPos,$YPos,$Mode,$BarSpec,$Data) = $StringData =~ /(\d+),(\d+),(\w+),(.*),"(.*)"/;

		$Data =~ s/\x1e/_1E/g;
		$Data =~ s/\x1d/_1D/g;
		$Data =~ s/\x04/_04/g;

		# UPS Maxicode
		if ( $Mode eq 'M' )
		{
			$Data =~ s/(\d+),(\d{3}),(\d{5}),(\d{4}),(.*)/${1}840$3$4$5/;
			$Data = 0 . $Data;

			$ZPL2String = "^FO35,395^BD^FH^FD${Data}^FS";
		}
		# FedEx PDF417
		elsif ( $Mode eq 'P' )
		{
			$ZPL2String = "^FO63,725^BY2,2^B7N,13,5,12^FH^FWN^FH^FD${Data}^FS";
		}
	}
	elsif ( $StringType eq 'L' )
	{
		my ($LineType,$StringData) = $StringData =~ /^(.)(.*)$/;
		my ($XPos,$YPos,$HorizontalLength,$VerticalLength) = split(/,/,$StringData);

		# Determine Line Thickness
		my $LineThickness;
		if ( $VerticalLength < $HorizontalLength )
		{
			$LineThickness = $VerticalLength;
			$VerticalLength = 0;
		}
		else
		{
			$LineThickness = $HorizontalLength;
			$HorizontalLength = 0;
		}

		$ZPL2String =
			"^FO" . $XPos . "," . $YPos . "^GB" . $HorizontalLength . "," . $VerticalLength . "," . $LineThickness . "^FS";
	}
	elsif ( $StringType eq 'X' )
	{
		my ($XStart,$YStart,$LineThickness,$XEnd,$YEnd) = split(/,/,$StringData);

		my $HorizontalLength = $XEnd - $XStart;
		my $VerticalLength = $YEnd - $YStart;

		$ZPL2String =
			"^FO" . $XStart . "," . $YStart . "^GB" . $HorizontalLength . "," . $VerticalLength . "," . $LineThickness . "^FS";
	}
	elsif ( $StringType eq 'P' )
	{
		my ($LabelSets,$LabelQuantity) = split(/,/,$StringData);

		$LabelQuantity = defined($LabelQuantity) ? $LabelQuantity : 0;

		$ZPL2String = "^PQ" . $LabelSets . ",0," . $LabelQuantity;
	}
	elsif ( $StringType eq 'N' )
	{
		$ZPL2String = "^XZ^XA";
	}
	elsif ( $StringType eq 'F' )
	{
		# Never used - form stuff
	}
	elsif ( $StringType eq 'V' )
	{
		# Never used - variable stuff
	}
	elsif ( $StringType eq '?' )
	{
		# Never used - variable stuff
	}
	elsif ( $StringType eq 'S' )
	{
#		$ZPL2String = "^PR$StringData";
		# Hardcode the speed to 6 for now.  Our default 8 is too fast for TC.
		$ZPL2String = "^PR6";
	}
	elsif ( $StringType eq '^' )
	{
		# Not a clue
	}
	elsif ( $StringType eq 'Z' )
	{
		if ( $StringData eq 'T' )
		{
			$ZPL2String = "^POI";
		}
		elsif ( $StringData eq 'B' )
		{
			$ZPL2String = "^PON";
		}
	}

	return $ZPL2String;
}

__PACKAGE__->meta()->make_immutable();

no Moose;

1;

__END__