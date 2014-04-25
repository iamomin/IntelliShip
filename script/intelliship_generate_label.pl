#!/usr/bin/perl -w

use strict;
use File::Copy;
use Image::Magick;
use File::Basename;
use Barcode::Code128 qw(:all);

my $Debug = 0;

my $rootDir = '/opt/engage/intelliship2/IntelliShip';

############ Input and Output directories ###############
my $inpdir = $rootDir . '/root/print/label';
my $outdir = $rootDir . '/root/print/label';

########## Filename without directory structure passed as first argument ########
my $EPLfile=$ARGV[0];
warn "EPL=$EPLfile" if $Debug;

######### Taking all files to be converted in an array ######
my @list = ($EPLfile);

########## initialising variables ###############
my $argLen = @ARGV;
my $opType = '';
my $opFormat = '';
my $opAngle = '';
my $argsText = '';
my $typeFlag="0";my $formatFlag="0";my $angleFlag = "0";

################## Checking for number of arguments passed should be less then 5-(filename [angle] [outputFormat] [outputType])#############
if($argLen > 4)
	{
	print "\n Too many input arguments!!!\n";
	exit;
	}

############ Checking for angle,outputFormat and outputType from the arguments ############
while($argLen > 1)
	{
	$ARGV[$argLen-1]=~ s/\s+|\t+|\n+|\r+//ig;#### Removing extra spaces and newline in argument
	if (($ARGV[$argLen-1] =~ m/^(s|m)$/ig) && ("$typeFlag" eq "0"))
		{
		######## Check for single or multiple #######
		$typeFlag ="1";
		$opType = $ARGV[$argLen-1];
		if($opType =~ m/^s$/i){$opType=1;}elsif($opType =~ m/^m$/i){$opType=2;}else{}
		}
	elsif (($ARGV[$argLen-1] =~ m/^(jpg|png|pdf)$/ig) &&  ("$formatFlag" eq "0"))
		{
		##### Check for output format jpg or png or pdf ####
		$formatFlag ="1";
		$opFormat = $ARGV[$argLen-1];
		if($opFormat =~ m/^jpg$/i){$opFormat=1;}elsif($opFormat =~ m/^png$/i){$opFormat=2;}elsif($opFormat =~ m/^pdf$/i){$opFormat=3;}else{}
		}
	elsif (($ARGV[$argLen-1] =~ m/^(0|90|180|270)$/ig) && ("$angleFlag" eq "0"))
		{
		##### Check for angle 0 or 90 or 180 or 270 #######
		$angleFlag="1";
		$opAngle = $ARGV[$argLen-1];
		if($opAngle =~ m/^0$/ig){$opAngle=1;}elsif($opAngle =~ m/^90$/ig){$opAngle=2;}elsif($opAngle =~ m/^180$/ig){$opAngle=3;}elsif($opAngle =~ m/^270$/ig){$opAngle=4;}else{}
		}
	else
		{
		######### if none of the above condition matched with the argument printing invalid argument sent ########
		print "\n Invalid input found \'$ARGV[$argLen-1]\' \n";
		exit;
		}

	$argLen--;
	}

############ if angle, format and type is not set from arguments setting it to default #############
if ("0" eq "$typeFlag")
	{
	$opType=2;###### output type default multiple #####
	}
if ("0" eq "$formatFlag")
	{
	$opFormat=1;####### output format default jpg #####
	}
if ("0" eq "$angleFlag")
	{
	$opAngle=1;###### output angle default 0 #########
	}

warn "Final input to converter type=$opType format=$opFormat angle=$opAngle epl=$list[0]";
#####################################################################################################

######### Generating output for each input file #####################################################
foreach my $FileName (@list)
	{
	my $file = $inpdir.'/'.$FileName;### Prefix input directory to input file ####
	warn "Input file is $file" if $Debug;

	my $inpFileName = "$FileName";

	######## Removing extension in filename ######
	if ( index($inpFileName, '.dat') != -1 )
		{
		$inpFileName =~ s/.dat//;
		}
	elsif ( index($inpFileName, '.txt') != -1 )
		{
		$inpFileName =~ s/.txt//;
		}
	else
		{
		}

	my $fileName = "$inpFileName";
	my @dataGot=&readFileContent($file);####### Calling sub routine readFileContent to read file content ###

	my $size=$#dataGot + 1;
	my $count=1;
	my @fileNameList =();

	foreach my $imgNo (@dataGot) ##### checking for each element to generate jpg #######
		{
		my $fileImage = $fileName;
		if($size > 1) ##### size > 1 - multiple images to be generated ##
			{
			$fileImage=$fileImage."_".$count;
			push(@fileNameList,"$fileImage"); #### pushing multiple image filenames to an array ###
			}

		&createImage("$fileImage","$imgNo",$size);##### Creating image for the data #####
		$count++;
		}

	if ($size > 1)
		{
		&mergeImage($fileName,@fileNameList); #### merging multiple images to single output ###
		}
	}

##################################################################################################
sub readFileContent()
{

		my $file =shift;
#=================READ CONTENT WITH IMAGE COUNT ===============
		my $imageData= "";
		my @images = ();
		my $imageCount=0;
		open my $info, $file or die "Could not open $file: $!";
		while ( my $line = <$info> ) {

#==================== NEW IMAGE ===============================
					$imageData.=$line."+||-||+";
					if ($line =~ /^P1/){
								$imageCount++;
								push(@images,"$imageData");
								$imageData="";
					}

		}

		close $file;
		return @images;
}



sub createImage()
{
		my $file =shift;
		my $fileData=shift;
		my $sizeGot=shift;
		my $blob ="";
		warn "createImage file=$file";
		warn "fileData=$file";
		warn "sizeGot=$sizeGot";
		my $searchString = qq~$fileData~;
		$searchString =~ s/\n+|\r+|\s+|\t+//ig;
		my @lines = split(/\+\|\|\-\|\|\+/,"$searchString");
		my $labelSize = "0";
		foreach my $line (@lines){
					if ($line =~ /^A/){
								$line =~ s/"//g;
								my @lineArray = split(',',$line);
								for(my $arrInd=0;$arrInd<@lineArray;$arrInd++){ $lineArray[$arrInd]=~ s/\#\-\#/\,/g; }
								if($lineArray[1] >=1255){
										$labelSize = "1";
								}
					}
		}

		my $image = "";
		if("1" eq $labelSize){
					$image = Image::Magick->new(size=>'400x675');
		}else{
					$image = Image::Magick->new(size=>'400x600');
		}
		$image->Read("xc:white");
		my @lineData = split(/\+\|\|\-\|\|\+/,"$fileData");
		my $font = "/opt/engage/EPL2JPG/Tahoma.ttf";
		foreach my $line (@lineData)
		{


#=======================================================================================================
					my $x;
					$line =~ s/(?<=")([^"]*)(?=")/($x = $1) =~ s|\,|\#\-\#|g;$x/ge;

					my @lineArray;
					if($line =~ /^;/)
					{
								if($line =~ /arial/i)
								{
										$font = "/opt/engage/EPL2JPG/arial.ttf";
								}
								elsif($line =~ /tahoma/i)
								{
										$font = "/opt/engage/EPL2JPG/Tahoma.ttf";
								}
								elsif($line =~ /TIMESNEWROMAN/i)
								{
										$font = "/opt/engage/EPL2JPG/12950.ttf";
								}
								elsif($line =~ /OCRAEXTENDED/i)
								{
										$font = "/opt/engage/EPL2JPG/ocraextended.ttf";
								}
								else
								{
										$font = "/opt/engage/EPL2JPG/Tahoma.ttf";
								}
					}
#====================TEXT READING =============================
					if ($line =~ /^A/){
								$line =~ s/"//g;
								@lineArray = split(',',$line);
								for(my $arrInd=0;$arrInd<@lineArray;$arrInd++){ $lineArray[$arrInd]=~ s/\#\-\#/\,/g; }
								$lineArray[0] =~ s/A//g;
								$lineArray[0] = $lineArray[0]*0.489;
								$lineArray[1] = $lineArray[1]*0.489;

								my $horGeo = $lineArray[0];
								my $verGeo = $lineArray[1]-5;
								my $rotation = $lineArray[2];
								my $fontType = $lineArray[3];
								my $horMul = "";
								if ($lineArray[4]>1){
										$horMul = $lineArray[4] * 1.05;
								}else{
										$horMul = $lineArray[4] * 1;
								}
								my $verMul = "";
								if ($lineArray[5]>1 && $lineArray[5]<=3){
										$verMul = $lineArray[5] * 0.7;
								}elsif ($lineArray[4]>=3){
										$verMul = $lineArray[5] * 0.9;
								}else{
										$verMul = $lineArray[5] * 0.85;
								}
								my $dataText  = $lineArray[7];
								my $geo = "+$horGeo+$verGeo";
#my $font = "";
								my $fontSize;
								my $angle;

								if($fontType eq 1){
#$font = 'Tahoma.ttf';
										$fontSize = 9;
								}elsif($fontType eq 2){
#$font = 'Tahoma.ttf';
										$fontSize = 10;
								}elsif($fontType eq 3){
#$font = 'Tahoma.ttf';
										$fontSize = 12;
								}elsif($fontType eq 4){
#$font = 'TahomaBold.ttf';
										$fontSize = 15;
								}elsif($fontType eq 5){
#$font = 'TahomaBold.ttf';
										$fontSize = 30;
								}elsif($fontType eq 6){
#$font = 'TahomaBold.ttf';
										$fontSize = 60;
								}else{
								}

								if($rotation eq 0){
										$angle = 0;
								}elsif($rotation eq 1){
										$angle = 90;
								}elsif($rotation eq 2){
										$angle = 180;
								}elsif($rotation eq 3){
										$angle = 270;
								}else{
								}
								if($lineArray[6] eq 'N'){
										$image->Annotate(text => "$dataText",	geometry => "$geo",rotate => "$angle",
																scale => "$horMul,$verMul",
																pen => "black",font => "$font",gravity => "NorthWest",
																pointsize => "$fontSize");
								}elsif($lineArray[6] eq 'R'){
											if("$fontType" eq "3"){
											$fontSize = 20;
								}
										$verMul = $verMul-1;
											$horMul = $horMul-1;
											$dataText =~ s/\n+|\r+$//g;
										if($dataText =~ m/^\s\s$/ig){
													$image->Annotate(text => "    ",
																		undercolor=> "black",
																		geometry => "$geo",
																		rotate => "$angle",
																		#scale => "$horMul,$verMul",
																		pen => "white",
																		font => "$font",
																		gravity => "NorthWest",
																		pointsize => "$fontSize");



										}elsif($dataText ne "" ){
													$image->Annotate(text => "$dataText",
																		undercolor=> "black",
																		geometry => "$geo",
																		rotate => "$angle",
																		#scale => "$horMul,$verMul",
																		pen => "white",
																		font => "$font",
																		gravity => "NorthWest",
																		pointsize => "$fontSize");

										}else{
										}

								}else{
								}

					}

#============= BAR CODES READING ==========================

#=============CODE 128 =================
					if ($line =~ /^B/){


								my @lineArray = split(',',$line);
								for(my $arrInd=0;$arrInd<@lineArray;$arrInd++){ $lineArray[$arrInd]=~ s/\#\-\#/\,/g; }
								$lineArray[0] =~ s/B//g;
								my $lineSize = @lineArray;
								$lineArray[1] = $lineArray[1] - 5;
								$lineArray[0] = $lineArray[0]*0.489;
								$lineArray[1] = $lineArray[1]*0.489;
								my $geom = "+$lineArray[0]+$lineArray[1]";
								my $barcodeData = "$lineArray[$lineSize-1]";
								$barcodeData =~ s/"//g;
								$barcodeData =~ s/\r|\n//g;

								$lineArray[4] = $lineArray[4]*0.489;
								$lineArray[6] = $lineArray[6]*0.489;

								my $barHeight = "$lineArray[6]";

								if($lineArray[3] eq "3C"){
										system("/opt/engage/EPL2JPG/zint-2.4.3/build/frontend/zint -o /opt/engage/EPL2JPG/code39C.png --notext -b 8 --height=60 -d '$barcodeData'");
										system("/usr/bin/convert /opt/engage/EPL2JPG/code39C.png -resize '1000x80' /opt/engage/EPL2JPG/code39C.png");
										my $img39 =  Image::Magick->new;
										$img39->Read(filename => '/opt/engage/EPL2JPG/code39C.png');
										$image->Composite(image => $img39,
																width => 1000,
																geometry => "$geom");
										unlink "/opt/engage/EPL2JPG/code39C.png";


								}else{
										warn "ELSE not a code39 barHeight=$barHeight" if $Debug;
										if( $barHeight < 20){
													system("/opt/engage/EPL2JPG/zint-2.4.3/build/frontend/zint -o /opt/engage/EPL2JPG/code128C.png --notext --height=12 -d '$barcodeData'");
													system("/usr/bin/convert /opt/engage/EPL2JPG/code128C.png -resize '310x50' /opt/engage/EPL2JPG/code128C.png");
										}elsif($barHeight > 40 && $barHeight < 50){
													if( $lineArray[3] eq 'K'){
																system("/opt/engage/EPL2JPG/zint-2.4.3/build/frontend/zint -o /opt/engage/EPL2JPG/code128C.png --height=27 --notext -d '$barcodeData'");
																system("/usr/bin/convert /opt/engage/EPL2JPG/code128C.png -resize '224x70' /opt/engage/EPL2JPG/code128C.png");
													}else{
																system("/opt/engage/EPL2JPG/zint-2.4.3/build/frontend/zint -o /opt/engage/EPL2JPG/code128C.png --height=37  --notext -d '$barcodeData'");
																system("/usr/bin/convert /opt/engage/EPL2JPG/code128C.png -resize '270x80' /opt/engage/EPL2JPG/code128C.png");
													}
										}elsif($barHeight > 50 && $barHeight < 60){
													warn "======52.5======" if $Debug;
													system("/opt/engage/EPL2JPG/zint-2.4.3/build/frontend/zint -o /opt/engage/EPL2JPG/code128C.png --height=30  --notext -d '$barcodeData'");
													system("/usr/bin/convert /opt/engage/EPL2JPG/code128C.png -resize '240x60' /opt/engage/EPL2JPG/code128C.png");
										}elsif($barHeight > 90 && $barHeight < 120){
													system("/opt/engage/EPL2JPG/zint-2.4.3/build/frontend/zint -o /opt/engage/EPL2JPG/code128C.png  --notext --height=60 -d '$barcodeData'");
													system("/usr/bin/convert /opt/engage/EPL2JPG/code128C.png -resize '340x100' /opt/engage/EPL2JPG/code128C.png");
										}elsif($barHeight > 135){
													substr($barcodeData, 0, 0) = '[';
													substr($barcodeData, 3, 0) = ']';
													system("/opt/engage/EPL2JPG/zint-2.4.3/build/frontend/zint -o /opt/engage/EPL2JPG/code128C.png -b 16 --height=90  --notext  -d '$barcodeData'");
													system("/usr/bin/convert /opt/engage/EPL2JPG/code128C.png -resize '500x145' /opt/engage/EPL2JPG/code128C.png");
										}elsif($barHeight > 65 && $barHeight < 80){
													system("/opt/engage/EPL2JPG/zint-2.4.3/build/frontend/zint -o /opt/engage/EPL2JPG/code128C.png --notext --height=45 -d '$barcodeData'");
													system("/usr/bin/convert /opt/engage/EPL2JPG/code128C.png -resize '320x80' /opt/engage/EPL2JPG/code128C.png");
										}else{
										}


										my $img =  Image::Magick->new;
										$img->Read(filename => '/opt/engage/EPL2JPG/code128C.png');
										$image->Composite(image => $img,
																width => 370,
																geometry => "$geom");
										unlink "/opt/engage/EPL2JPG/code128C.png";
								}
					}

#============= ZINT BAR CODES ================

					if ($line =~ /^b/){
								warn $line . "is like ^b";
								$line=~ s/\s/\|\|\|/g;
								$line=~ s/[^!-~\s]//g;
								$line=~ s/\|\|\|/ /g;
								my @dataArray = split('"',$line);
								my $barcodeData = $dataArray[1];
								my @lineArray = split(',',$dataArray[0]);
								for(my $arrInd=0;$arrInd<@lineArray;$arrInd++){ $lineArray[$arrInd]=~ s/\#\-\#/\,/g; }
								$lineArray[0] =~ s/b//g;
								$lineArray[1] = $lineArray[1]+5;
								$lineArray[0] = $lineArray[0]*(0.489);
								$lineArray[1] = $lineArray[1]*(0.489);
#my $geom = "+$lineArray[0]+$lineArray[1]";
								my $Maxicodeimg = Image::Magick->new;
								my $PDFimg = Image::Magick->new;

								if ( $lineArray[2] eq 'P'){
										$lineArray[1] = $lineArray[1]+5;
										my $geom = "+$lineArray[0]+$lineArray[1]";

										system("/opt/engage/EPL2JPG/zint-2.4.3/build/frontend/zint  -o /opt/engage/EPL2JPG/PDF.png -b 55 --height=40 --cols=4 -d '$barcodeData'");
#system("convert PDF.png  -resize 360x90  PDF.png");
										$PDFimg->Read(filename => '/opt/engage/EPL2JPG/PDF.png');
										$image->Composite(image => $PDFimg,
																geometry => "$geom");
										unlink "/opt/engage/EPL2JPG/PDF.png";
								}
								elsif ( $lineArray[2] eq 'M'){
										my $geom = "+$lineArray[0]+$lineArray[1]";
										system("/opt/engage/EPL2JPG/zint-2.4.3/build/frontend/zint --height=2 -o /opt/engage/EPL2JPG/Maxi.png -b 57 -d '$barcodeData'");
										system("/usr/bin/convert /opt/engage/EPL2JPG/Maxi.png  -resize 100x100  /opt/engage/EPL2JPG/Maxi.png");
										$Maxicodeimg->Read(filename => '/opt/engage/EPL2JPG/Maxi.png');
										$image->Composite(image => $Maxicodeimg,
																geometry => "$geom");
										unlink "/opt/engage/EPL2JPG/Maxi.png";
								}
								elsif ( $lineArray[2] eq 'Q'){

								}
								else{
								}
					}

#===============LINES READING ===================================================

					if ($line =~ /^LO/){
								$line =~ s/"//g;
								my @lineArray = split(',',$line);
								for(my $arrInd=0;$arrInd<@lineArray;$arrInd++){ $lineArray[$arrInd]=~ s/\#\-\#/\,/g; }
								$lineArray[0] =~ s/LO//g;
								$lineArray[1] =  $lineArray[1] - 5;
								$lineArray[0] = $lineArray[0]*0.489;
								$lineArray[1] = $lineArray[1]*0.489;
								$lineArray[2] = $lineArray[2]*0.489;
								$lineArray[3] = $lineArray[3]*0.489;

								my $xaxis = $lineArray[0] + $lineArray[2];
								my $yaxis = $lineArray[1] + $lineArray[3];

								if( $lineArray[3]>10){
										my $add = $lineArray[1] + $lineArray[3];
										$image->Draw(
																primitive => 'rectangle',
																points    => "$lineArray[0],$lineArray[1], $xaxis, $yaxis",
																fill => "black",
																gravity => "West",
																stroke    => '#000',
														);
								}else {
										my $add = $lineArray[0] + $lineArray[2];
										$image->Draw(
																primitive => 'rectangle',
																points    => "$lineArray[0],$lineArray[1], $xaxis, $yaxis",
																fill => "black",
																gravity => "West",
																stroke    => '#000',
														);
								}
					}

		}

		$image->Set(magick=>'jpg');

		$blob = $image->ImageToBlob();
		warn "file jpg created=$outdir/$file.jpg";
		open(FH,"> $outdir/$file.jpg")or die "$!\n";
		print FH $blob;
		close FH;

		########################################
		## ADD BORDER OF 2px to the image
		########################################
		#system("/usr/bin/convert $outdir/$file.jpg -bordercolor opaque -border 2 $outdir/$file.jpg");

		#system("/usr/bin/convert -border 1x1 -bordercolor black /opt/engage/intelliship/html/$file.jpg /opt/engage/intelliship/html/$file.jpg");

		if($sizeGot < 2)
		{
############### Code here to rotate and format type for Single input streams##############
					warn "$file.jpg\n";
					if("$opAngle" eq 1){
								system("/usr/bin/convert $outdir/$file.jpg -rotate 0 $outdir/$file.jpg");
					}elsif("$opAngle" eq 2){
								system("/usr/bin/convert $outdir/$file.jpg -rotate 90 $outdir/$file.jpg");
					}elsif("$opAngle" eq 3){
								system("/usr/bin/convert $outdir/$file.jpg -rotate 180 $outdir/$file.jpg");
					}elsif("$opAngle" eq 4){
								system("/usr/bin/convert $outdir/$file.jpg -rotate 270 $outdir/$file.jpg");
					}else{
					}

					if("$opFormat" eq 1){
								warn "JPG: $outdir/$file.jpg to $outdir/";
								my $fromfile = $outdir.'/'.$file.'.jpg';
								my $tofile = $outdir.'/' . $file.'.jpg';
								warn "FINAL file=$tofile";
								move($fromfile,$tofile)
										or die("Could not move $fromfile to $tofile: $!");

					}elsif("$opFormat" eq 2){
								system("convert $outdir/$file.jpg $outdir/$file.png");
								my $fromfile = $outdir.'/'.$file.'.png';
								my $tofile = $outdir.'/'.$file.'.png';
								move($fromfile,$tofile) or die("Could not move $fromfile to $tofile: $!");
								unlink "$outdir/$file.jpg";
					}elsif("$opFormat" eq 3){
								if("$opAngle" eq 1 || "$opAngle" eq 3){
										system("convert -density 100 -size 500x800 xc:white $outdir/$file.jpg -composite $outdir/$file.pdf");
										my $fromfile = $outdir.'/'.$file.'.pdf';
										my $tofile = $outdir.'/'.$file.'.pdf';
										move($fromfile,$tofile) or die("Could not move $fromfile to $tofile: $!");
										unlink "$outdir/$file.jpg";
								}elsif("$opAngle" eq 2 || "$opAngle" eq 4){
										system("convert -density 100 -size 800x500 xc:white $outdir/$file.jpg -composite $outdir/$file.pdf");
										my $fromfile = $outdir.'/'.$file.'.pdf';
										my $tofile = $outdir.'/'.$file.'.pdf';
										move($fromfile,$tofile) or die("Could not move $fromfile to $tofile: $!");
										unlink "$outdir/$file.jpg";
								}else{
								}
					}elsif("$opFormat" eq 4){

								system("convert $outdir/$file.jpg -composite $file.html");
								my $fromfile = $outdir.'/'.$file.'.html';
								my $tofile = $outdir.'/HTML/';
								move($fromfile,$tofile) or die("Could not move $fromfile to $tofile: $!");
								$fromfile = $outdir.'/'.$file.'.gif';
								$tofile = "$outdir/HTML/";
								move($fromfile,$tofile) or die("Could not move $fromfile to $tofile: $!");
								unlink "$outdir/$file.jpg";
					}else{
					}

		}
}

sub mergeImage()
{
		my ($mainFileName,@filename) = @_;
		my $size = @filename;
		my $imagesize = "";
		if($size eq 3){
					$imagesize = "1215x680";
		}elsif($size eq 2){
					$imagesize = "810x680";
		}else{
		}
		warn "mergeImage =$mainFileName,@filename";
		if("$opType" eq 1)
		{
					my $image2 = Image::Magick->new(size=>"$imagesize");
					$image2->Read("xc:white");
					my $blob2 = "";

					my $img1 =  Image::Magick->new;
					$img1->Read(filename => "$outdir/$filename[0].jpg");
					$image2->Composite(image => $img1,
										geometry => '+5+0');
					unlink "$outdir/$filename[0].jpg";
					my $img2 =  Image::Magick->new;
					$img2->Read(filename => "$outdir/$filename[1].jpg");
					$image2->Composite(image => $img2,
										geometry => '+405+0');
					unlink "$outdir/$filename[1].jpg";

					if($size eq 3){
								my $img3 = Image::Magick->new;
								$img3->Read(filename => "$outdir/$filename[2].jpg");
								$image2->Composite(image => $img3,
													geometry => '+810+0');
								unlink "$outdir/$filename[2].jpg";
					}

					$image2->Set(magick=>'jpg');
					$blob2 = $image2->ImageToBlob();
					open(FH,"> $outdir/$mainFileName.jpg")or die "$!\n";
					print FH $blob2;
					close FH;

				if("$opAngle" eq 1){
						system("/usr/bin/convert $outdir/$mainFileName.jpg -rotate 0 $outdir/$mainFileName.jpg");
				}elsif("$opAngle" eq 2){
						system("/usr/bin/convert $outdir/$mainFileName.jpg -rotate 90 $outdir/$mainFileName.jpg");
				}elsif("$opAngle" eq 3){
						system("/usr/bin/convert $outdir/$mainFileName.jpg -rotate 180 $outdir/$mainFileName.jpg");
				}elsif("$opAngle" eq 4){
						system("/usr/bin/convert $outdir/$mainFileName.jpg -rotate 270 $outdir/$mainFileName.jpg");
				}else{
				}


					if("$opFormat" eq 1){
						my $fromfile = '$outdir/'.$mainFileName.'.jpg';
						my $tofile = "$outdir/".$mainFileName.".jpg";
						move($fromfile,$tofile) or die("Could not move $fromfile to $tofile: $!");
					}elsif("$opFormat" eq 2){
								system("convert $outdir/$mainFileName.jpg $outdir/$mainFileName.png");
								my $fromfile = '$outdir/'.$mainFileName.'.png';
								my $tofile = "$outdir/".$mainFileName.".png";
								move($fromfile,$tofile) or die("Could not move $fromfile to $tofile: $!");
								unlink "$outdir/$mainFileName.jpg";
					}elsif("$opFormat" eq 3){
								if("$opAngle" eq 1 || "$opAngle" eq 3){
										if($size eq 2){
													system("convert -density 100 -size 850x800 xc:white $outdir/$mainFileName.jpg -composite $outdir/$mainFileName.pdf");
										}elsif($size eq 3){
													system("convert -density 100 -size 1300x800 xc:white $outdir/$mainFileName.jpg -composite $outdir/$mainFileName.pdf");
										}else{}
										my $fromfile = '$outdir/'.$mainFileName.'.pdf';
										my $tofile = "$outdir/".$mainFileName.".pdf";
										move($fromfile,$tofile) or die("Could not move $fromfile to $tofile: $!");
										unlink "$outdir/$mainFileName.jpg";
								}elsif("$opAngle" eq 2 || "$opAngle" eq 4){
										if($size eq 2){
													system("convert -density 100 -size 800x850 xc:white $outdir/$mainFileName.jpg -composite $outdir/$mainFileName.pdf");
										}elsif($size eq 3){
													system("convert -density 100 -size 800x1300 xc:white $outdir/$mainFileName.jpg -composite $outdir/$mainFileName.pdf");
										}else{}
												my $fromfile = '$outdir/'.$mainFileName.'.pdf';
												my $tofile = "$outdir/".$mainFileName.".pdf";
												move($fromfile,$tofile) or die("Could not move $fromfile to $tofile: $!");
												unlink "$outdir/$mainFileName.jpg";
								}else{
								}
					}elsif("$opFormat" eq 4){

								system("convert $outdir/$mainFileName.jpg -composite $outdir/$mainFileName.html");
								my $fromfile = '$outdir/'.$mainFileName.'.html';
								my $tofile = "$outdir/HTML/".$mainFileName.".html";
								move($fromfile,$tofile) or die("Could not move $fromfile to $tofile: $!");
								$fromfile = '$outdir/'.$mainFileName.'.gif';
								$tofile = "$outdir/HTML/".$mainFileName.".gif";
								move($fromfile,$tofile) or die("Could not move $fromfile to $tofile: $!");
								unlink "$outdir/$mainFileName.jpg";
					}else{
					}
		}elsif("$opType" eq 2){
					for(my $i=0; $i < $size; $i++)
					{
############### Code here to rotate and format type for Single input streams##############
								if("$opAngle" eq 1){
										system("convert $outdir/$filename[$i].jpg -rotate 0 $outdir/$filename[$i].jpg");
								}elsif("$opAngle" eq 2){
										system("convert $outdir/$filename[$i].jpg -rotate 90 $outdir/$filename[$i].jpg");
								}elsif("$opAngle" eq 3){
										system("convert $outdir/$filename[$i].jpg -rotate 180 $outdir/$filename[$i].jpg");
								}elsif("$opAngle" eq 4){
										system("convert $outdir/$filename[$i].jpg -rotate 270 $outdir/$filename[$i].jpg");
								}else{
								}

								if("$opFormat" eq 1){
								my $fromfile = '$outdir/'.$filename[$i].'.jpg';
								my $tofile = "$outdir/".$filename[$i].".jpg";
								move($fromfile,$tofile) or die("Could not move $fromfile to $tofile: $!");
								}elsif("$opFormat" eq 2){
										system("convert $outdir/$filename[$i].jpg $outdir/$filename[$i].png");
										my $fromfile = '$outdir/'.$filename[$i].'.png';
										my $tofile = "$outdir/".$filename[$i].".png";
										move($fromfile,$tofile) or die("Could not move $fromfile to $tofile: $!");
										unlink "$outdir/$filename[$i].jpg";
								}elsif("$opFormat" eq 3){
										if("$opAngle" eq 1 || "$opAngle" eq 3){
													system("convert -density 100 -size 500x800 xc:white $outdir/$filename[$i].jpg -composite $outdir/$filename[$i].pdf");
													my $fromfile = '$outdir/'.$filename[$i].'.pdf';
													my $tofile = "$outdir/".$filename[$i].".pdf";
													move($fromfile,$tofile) or die("Could not move $fromfile to $tofile: $!");
													unlink "$outdir/$filename[$i].jpg";
										}elsif("$opAngle" eq 2 || "$opAngle" eq 4){
													system("convert -density 100 -size 800x500 xc:white $outdir/$filename[$i].jpg -composite $outdir/$filename[$i].pdf");
													my $fromfile = '$outdir/'.$filename[$i].'.pdf';
													my $tofile = "$outdir/".$filename[$i].".pdf";
													move($fromfile,$tofile) or die("Could not move $fromfile to $tofile: $!");
													unlink "$outdir/$filename[$i].jpg";
										}else{
										}
								}elsif("$opFormat" eq 4){

										system("convert $outdir/$filename[$i].jpg -composite $outdir/$filename[$i].html");
										my $fromfile = '$outdir/'.$filename[$i].'.html';
										my $tofile = "$outdir/HTML/".$filename[$i].".html";
										move($fromfile,$tofile) or die("Could not move $fromfile to $tofile: $!");
										$fromfile = '$outdir/'.$filename[$i].".gif";
										$tofile = "$outdir/HTML/".$filename[$i].".gif";
										move($fromfile,$tofile) or die("Could not move $fromfile to $tofile: $!");
										unlink "$outdir/$filename[$i].jpg";
								}else{
								}
					}
		}else{
		}
}
