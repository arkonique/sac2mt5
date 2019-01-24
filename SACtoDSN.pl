#!/usr/bin/perl

use strict;
use DateTime;
use File::Temp;
use Math::Complex;
use Getopt::Long;
use TauP::Time;
use Seed::Response;
use lib '/usr/local/share/perl/5.26.2'; # Path to perl libraries
use Seismogram::SAC;

my(@input,$output);
GetOptions('input=s{,}' => \@input, 'output=s' => \$output);
# A perl module to convert from SAC to DSN (a format used by MT5)
open my $out_fp,">$output";
my $taup_path='/usr/local/bin/TauP-2.4.5'; # Path to Taup installation

foreach my $file (<@input>)
{
 my $phase = 'S';
 if ( $file =~ /BHZ/ ) { $phase = 'P';}

 # Decimate the data
 my $decData=File::Temp->new();
 decimateData($file,$decData);
 # Read the decimated file
 my($sac) = readSAC($decData);
 my($station,$network,$component,$channel) = $sac->Fetch(qw(kstnm knetwk kcmpnm khole));

 my($resp) = readResponse($sac);

 my($waveform,$initialTime) = extractWaveform($sac,$phase);
 my $waveformSize = (scalar @$waveform);
 my($header) = createSeismogramHeader($sac,$resp,$waveform,$initialTime);
 $header .= printPolesAndZeros($sac,$resp,$waveformSize); 
 $header .= printWaveform($waveform);
 print $out_fp $header;
}
close $out_fp;

0;

sub
readSAC
{
 my($file) = @_;

 my $sac = Seismogram::SAC->new();
 open my $fp,"$file";
 my $status = $sac->Read($fp);
 close $fp;

 return $sac;
}

sub
readResponse
{
 my($sac)=@_;
 my($station,$network,$component,$channel) = $sac->Fetch(qw(kstnm knetwk kcmpnm khole));
 my $respName = "RESP.$network.$station.$channel.$component";
 print "Response file: $respName\n\n";
 my $resp = Seed::Response->new();
 $resp->parseFile($respName);

 return $resp;
}

=pod

B<decimateData($file,$decFile)>

Given an input SAC file C<$input>, remove the instrument response, convert from
nanometers to micrometers, and decimate the data by 10 and write the results to
C<$decFile>.

=cut

sub
decimateData
{
 my($file,$decFile) = @_;

 my $sac2000 = 'sac'; 
 open my $sac_fp, "|$sac2000";
 print $sac_fp qq(READ $file
DECIMATE 5
DECIMATE 2
WRITE $decFile
QUIT
);
 close $sac_fp;
}

=pod

B<createSeismogramHeader($sac,$waveform,$initialTime)>

Given a SAC object C<$sac>, a reference to an array containing the waveform C<$waveform>,
and a DateTime object C<$initialTime> containing the starting time for the waveform, output
a header in MT5's DSN format.

=cut

sub
createSeismogramHeader
{
 my($sac,$resp,$waveform,$initialTime) = @_;

 my($min,$max) = calculateMinMax($waveform);
 my($sta,$component,$event,$offset,$dt,$lat,$lon) = $sac->Fetch(qw(kstnm kcmpnm kevnm o delta stla stlo));
 $sta = lc $sta;
 my $hour = $initialTime->hour();
 my $minute = $initialTime->minute();
 my $second = $initialTime->second() + ($initialTime->nanosecond()/1e9);

 if ( $event == -12345 )
 {
  $event = $initialTime->year().' '.$initialTime->month().' '.$initialTime->day();
 }
 $component = translateComponent($component,$resp);

 my $responseType = 'pza';
 #my $gain = calculateGain($resp);
 my $gain = $resp->getStage(1)->getGain();
 if ( not defined $gain )
 {
  $gain = 1.0;
 }
 my $header = sprintf("%-4s%1d%3s%10.4e%12s%2d%2d%5.2f%5.2f%7.2f%7.2f%3s\r\n",$sta,4,$component,$gain,$event,$hour,$minute,$second,$dt,$lat,$lon,$responseType);

 return $header;
}

=pod

B<printPolesAndZeros($sac,$numpoints)>



=cut

sub
printPolesAndZeros
{
 my($sac,$resp,$numPoints) = @_;


 my $numZeros = $resp->getStage(1)->getNumberOfZeros();
 my $numPoles = $resp->getStage(1)->getNumberOfPoles();
 my $normFactor = $resp->getStage(1)->getNormalizationFactor();
 my $normFrequency = $resp->getStage(1)->getNormalizationFrequency();

 # Now print the header
 my $header = sprintf("%5d%5d%5d %10.4e %6.4f\r\n",$numPoints,$numZeros,$numPoles,$normFactor,$normFrequency);
 # Print out the poles and zeros
 my $data = '';
 for(my $i=0;$i<=$numZeros;$i+=4)
 {
  $data .= ' ';
  for(my $j=0;$j<4;$j++)
  {
   my $zero = $resp->getStage(1)->getZero($i+$j); 
   next if ( not defined $zero);
   $data .= sprintf("%.4e %.4e ",Re($zero),Im($zero));
  }
  $data .= "\r\n";
 }
 for(my $i=0;$i<$numPoles;$i+=4)
 {
  $data .= ' ';
  for(my $j=0;$j<4;$j++)
  {
   my $pole = $resp->getStage(1)->getPole($i+$j);
   next if ( not defined $pole);
   $data .= sprintf("%.4e %.4e ",Re($pole),Im($pole));
  }
  $data .= "\r\n";
 }

 return $header.$data;
}

sub
doyConvert
{
 my($year,$doy) = @_;

 my $dt = DateTime->new(month => 1, day => 1, year => $year);
 $doy--;
 $dt->add( days => $doy );
 
 return $dt->month(),$dt->day();
}

sub
extractWaveform
{
 my($sac,$phase) = @_;

 # First, calculate the expected arrival time of the phase 
 # This is the time in seconds from the origin time
 my $time = getTravelTime($sac,$phase);

 # Get the offset between the event origin time and the beginning of the trace
 # and the sampling interval
 my($offset,$dt,$npts) = $sac->Fetch(qw(o delta npts));
 # The offset is the difference between the origin time and the start of the time series
 $offset = abs($offset);
 # ten seconds, in data points
 my $tenSeconds = int(10/$dt);

 # Calculate the time of the first point in the waveform
 my($year,$doy,$hour,$min,$second,$msec) = $sac->Fetch(qw(nzyear nzjday nzhour nzmin nzsec nzmsec));
 my($month,$day) = doyConvert($year,$doy);
 my $initialTime = DateTime->new(year => $year, month => $month, day => $day,
                                 hour => $hour, minute => $min, second => $second,
                                 nanosecond => ($msec*1e6));

 # Calculate the data point number from the
 # beginning of the time series to the phase
 my $arrival = int (($time - $offset)/$dt);

 # Calculate the window length for the waveform
 my($start,$end);
 if ( $phase eq 'P' )
 {
  # Extract a minute on either side
  $start = $arrival - 1*$tenSeconds;
  $end = $arrival + 9*$tenSeconds;
  $initialTime->add(nanoseconds => ($time - $offset - 10)*1e9);
 }
 elsif ( $phase eq 'S' )
 {
  # Extract a minute before and 2 minutes after
  $start = $arrival - 2*$tenSeconds;
  $end = $arrival + 10*$tenSeconds;
  $initialTime->add(nanoseconds => ($time - $offset - 20)*1e9);
 }
 if ( $start < 0 ) { die "Can't window one minute for waveform\nstart < 0 : $start"; }
 if ( $end > $npts ) { die "Can't window one minute for waveform\nend > $npts: $end"; }

 my @waveform = ();
 # Extract the waveform
 for(my $i=$start;$i<$end;$i++)
 {
  push(@waveform,($sac->data()->[$i]*1e6)); # meters/s -> micrometers/s? 
 } 

 return \@waveform,$initialTime;
}

sub
printWaveform
{
 my($waveform) = @_;

 my $numPoints = (scalar @$waveform);

 my $data = '';
 for(my $i=0;$i<$numPoints;$i+=8)
 {
  $data .= ' ';
  for(my $j=0;$j<8;$j++)
  {
   next if (($i+$j) > ($numPoints-1)); 
   $data .= sprintf("%.4e ",$waveform->[$i+$j]/1e6);
  }
  $data .= "\r\n";
 }

 return $data; 
}

sub
getTravelTime
{
 my($sac,$phase) = @_;

 my $taup = TauP::Time->new($taup_path);
 $taup->setModel('iasp91'); # Set the travel time model to IASPEI91 model
 my($deg,$depth) = $sac->Fetch(qw(gcarc evdp));
 $depth /= 1000;

 my $time = $taup->calculateTravelTimes($deg,$depth,$phase);

 return $time->[0]; 
}

sub
calculateMinMax
{
 my($x) = @_;

 my @sorted_x = sort {$a <=> $b} @$x;

 my $min = $sorted_x[0]; 
 my $max = $sorted_x[-1]; 

 return $min,$max;
}

sub
calculateGain
{
 my($resp) = @_;

 my $totalGain = 1.0;
 for(my $i=0;$i<=6;$i++)
 {
  my $stage = $resp->getStage($i);
  if ( defined $stage )
  { 
   my $stageGain = $stage->getGain();
   if ( defined $stageGain )
   {
    $totalGain *= $stageGain;
   }
  }
 }

 return $totalGain;
}

=head2 translateComponent($component,$resp)

Translate IRIS component names like BHZ to MT5 component names
like lpz.

=cut

sub
translateComponent
{
 my($component,$resp) = @_;

 my $mt5Component = $component;
 $mt5Component =~ s/^B|^L/l/;
 if ( $resp->getStage(1)->getUnits() =~ /Displacement/ )
 {
  $mt5Component =~ s/H/p/; 
 }
 elsif ( $resp->getStage(1)->getUnits() =~ /^M\/S/ )
 {
  $mt5Component =~ s/H/v/; 
 }
 elsif ( $resp->getStage(1)->getUnits() =~ /Acceleration/ )
 {
  $mt5Component =~ s/H/a/; 
 }
 $mt5Component = lc $mt5Component;

 return $mt5Component;
}
