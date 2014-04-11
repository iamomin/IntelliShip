	package ARRS::handler_web_fedex;

	use strict;

	use ARRS::CARRIERHANDLER;
	@ARRS::handler_web_fedex::ISA = ("ARRS::CARRIERHANDLER");

	use ARRS::COMMON;

	use POSIX qw(ceil);
			
	my $Debug = 0;

	sub new
	{
		my $proto = shift;
		my $class = ref($proto) || $proto;

		my ($DBRef, $Customer) = @_;
		my $self = $class->SUPER::new($DBRef,$Customer);

		bless($self, $class);
		return $self;
	}
	
	sub DimCheck
	{
		my $self = shift;
		my ($Dim1,$Dim2,$Dim3,$ServiceID) = @_;

		if
		(
			defined($Dim1) && $Dim1 ne '' &&
			defined($Dim2) && $Dim2 ne '' &&
			defined($Dim3) && $Dim3 ne ''
		)
		{
			my $TotalDims = $self->GetTotalDims($Dim1,$Dim2,$Dim3);
			my $Length = $self->GetDimLength($Dim1,$Dim2,$Dim3);

			# Ground
			if ( $ServiceID eq '0000000000004' )
			{
				if ( $TotalDims > 130 ) { return 0; }
				if ( $Length >= 108 ) { return 0; }
			}
			# Express
			elsif
			(
				$ServiceID eq '0000000000005' || $ServiceID eq '0000000000002' || $ServiceID eq 'FEDEXNFO00000' ||
				$ServiceID eq '0000000000007' || $ServiceID eq '0000000000006'
			)
			{
				if ( $TotalDims > 165 ) { return 0; }
				if ( $Length > 119 ) { return 0; }
			}
		}

		return 1;
	}

	sub GetDimWeight
	{
		my $self = shift;
		my ($Dim1,$Dim2,$Dim3,$DimFactor,$ServiceID) = @_;

		# Ground
		if ( $ServiceID eq '0000000000004' )
		{
			return $self->GetGroundDimWeight($Dim1,$Dim2,$Dim3);
		}
		# Express
		elsif
		(
			$ServiceID eq '0000000000005' || $ServiceID eq '0000000000002' || $ServiceID eq 'FEDEXNFO00000' ||
			$ServiceID eq '0000000000007' || $ServiceID eq '0000000000006'
		)
		{
			return $self->GetExpressDimWeight($Dim1,$Dim2,$Dim3);
		}
		else
		{
			return $self->SUPER::GetDimWeight($Dim1,$Dim2,$Dim3,$DimFactor);
		}
	}

	sub GetGroundDimWeight
	{
		my $self = shift;
		my ($Dim1,$Dim2,$Dim3) = @_;
		my $DimWeight = 0;

		if
		(
			defined($Dim1) && $Dim1 ne '' &&
			defined($Dim2) && $Dim2 ne '' &&
			defined($Dim3) && $Dim3 ne ''
		)
		{
			my $TotalDims = $self->GetTotalDims($Dim1,$Dim2,$Dim3);

			if ( $TotalDims > 84 && $TotalDims <= 108 )
			{
				$DimWeight = 30;
			}
			elsif ( $TotalDims > 108 && $TotalDims <= 130 )
			{
				$DimWeight = 50;
			}
			elsif ( $TotalDims > 130 && $TotalDims <= 165 )
			{
				$DimWeight = 90;
			}
		}

		if ( $DimWeight )
		{
			return $DimWeight;
		}
		else
		{
			return undef;
		}
	}

	sub GetExpressDimWeight
	{
		my $self = shift;
		my ($Dim1,$Dim2,$Dim3) = @_;
		my $DimWeight = 0;

		if
		(
			defined($Dim1) && $Dim1 ne '' &&
			defined($Dim2) && $Dim2 ne '' &&
			defined($Dim3) && $Dim3 ne ''
		)
		{
			my $TotalDims = $self->GetTotalDims($Dim1,$Dim2,$Dim3);

			if ( $TotalDims > 130 && $TotalDims <= 165 )
			{
				$DimWeight = 90;
			}
		}

		if ( $DimWeight )
		{
			return $DimWeight;
		}
		else
		{
			return undef;
		}
	}

	sub GetETADate
	{
		my $self = shift;
		my ($ETARef) = @_;

		# Only do this for ground (commercial/residential)
		if ( $ETARef->{'serviceid'} eq '0000000000004' )
		{
			my $TransitSQL = "
				SELECT
					transittime
				FROM
					ziptransittime
				WHERE
					carrierid = '$ETARef->{'carrierid'}'
					AND originbegin <= '$ETARef->{'fromzip'}'
					AND originend >= '$ETARef->{'fromzip'}'
					AND destbegin <= '$ETARef->{'tozip'}'
					AND destend >= '$ETARef->{'tozip'}'
					AND serviceid = '$ETARef->{'serviceid'}'
			";

			my $STH = $self->{'dbref'}->prepare($TransitSQL)
				or TraceBack("Could not prepare transittime sql statement",1);

			$STH->execute
				or TraceBack("Could not execute transittime sql statement",1);

			($ETARef->{'transitdays'}) = $STH->fetchrow_array();
		}

		return $self->SUPER::GetETADate($ETARef);
	}
=b
	sub GetTotalDims
	{
		my $self = shift;
		my @Dims = @_;

		my @SortedDims = sort {$b <=> $a} (@Dims);
		
		my $Length = shift(@SortedDims);
		my $Width = shift(@SortedDims);
		my $Height = shift(@SortedDims);	

		return $Length + 2 * $Width + 2 * $Height;
	}

	# Dim Length presumably the longest dimension
	sub GetDimLength
	{
		my $self = shift;
		my @Dims = @_;

		my @SortedDims = sort {$b <=> $a} (@Dims);

		return shift(@SortedDims);
	}
=cut

1;
