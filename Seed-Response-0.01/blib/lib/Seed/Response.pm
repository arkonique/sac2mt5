package Seed::Response;

use warnings;
use strict;
use Carp;
use DateTime;
use Math::Complex;
use Seed::Response::Stage;

=head1 NAME

Seed::Response - A SAC Response File Parser

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Seed::Response is a parser for Seed Response files.

=head1 FUNCTIONS

=head2 new()

Create a new Seed::Response object.

=cut

sub
new
{
 my($class) = shift;

 my $self = {};
 $self->{'Station'} = undef;
 $self->{'Network'} = undef;
 $self->{'Location'} = undef;
 $self->{'Channel'} = undef;
 $self->{'StartDate'} = undef;
 $self->{'EndDate'} = undef;
 $self->{'Stage'} = ();

 bless $self, $class;

 return $self;
}

=head2 parseFile($self,$file)

Parse the response file C<$file>.

=cut

sub
parseFile
{
 my($self,$file) = @_;

 my $stageRE = qr/(^B053F04|^B054F04|^B057F03|^B058F03)/;

 my $transferType = undef;
 my $currentStage = undef;
 open my $fp, "$file" or croak "Could not open $file";
 while(<$fp>)
 {
  my $line = $self->_trim($_);
  if ( $line =~/^B050F03/)
  {
   my(undef,$val) = split /:/,$line;
   $val = $self->_trim($val);
   $self->setStation($val);
  }
  elsif ( $line =~ /^B050F16/)
  {
   my(undef,$val) = split /:/,$line;
   $val = $self->_trim($val);
   $self->setNetwork($val);
  }
  elsif ( $line =~ /^B052F03/)
  {
   my(undef,$val) = split /:/,$line;
   $val = $self->_trim($val);
   $self->setLocation($val);
  }
  elsif ( $line =~ /^B052F04/)
  {
   my(undef,$val) = split /:/,$line;
   $val = $self->_trim($val);
   $self->setChannel($val);
  }
  elsif ( $line =~ /^B052F22/)
  {
   my(undef,$val) = split /date:/,$line;
   $val = $self->_trim($val);
   $self->setStartDate($val);
  }
  elsif ( $line =~ /^B052F23/)
  {
   my(undef,$val) = split /date:/,$line;
   $val = $self->_trim($val);
   $self->setEndDate($val);
  }
  elsif ( $line =~ /^B053F03/)
  {
   # The transfer function type comes before the 
   # the current stage number is set, this could cause trouble
   my(undef,$val) = split /:/,$line;
   $val = $self->_trim($val);
   $transferType = $val;
  }
  elsif ( $line =~ $stageRE )
  {
   my(undef,$val) = split /:/,$line;
   $currentStage = $self->_trim($val);
   $self->addStage($currentStage);
   if ( defined $transferType )
   {
    $self->getStage($currentStage)->setTransferType($transferType);
    undef $transferType;
   }
  }
  elsif ( $line =~ /^B053F05/)
  {
   my(undef,$val) = split /:/,$line;
   $val = $self->_trim($val);
   $self->getStage($currentStage)->setUnits($val);
  }
  elsif($line =~ /^B053F07/)
  {
   my(undef,$val) = split /:/,$line;
   $val = $self->_trim($val);
   $self->getStage($currentStage)->setNormalizationFactor($val);
  }
  elsif( $line =~ /^B053F08/)
  {
   my(undef,$val) = split /:/,$line;
   $val = $self->_trim($val);
   $self->getStage($currentStage)->setNormalizationFrequency($val);
  }
  elsif( $line =~ /^B053F09/)
  {
   my(undef,$zeros) = split /:/,$line;
   $zeros = $self->_trim($zeros);
   $self->getStage($currentStage)->setNumberOfZeros($zeros);
  }
  elsif( $line =~ /^B053F14/)
  {
   my(undef,$poles) = split /:/,$line;
   $poles = $self->_trim($poles);
   $self->getStage($currentStage)->setNumberOfPoles($poles);
  }
  elsif($line =~ /^B053F10-13/)
  {
   # Complex Zeros
   my(undef,$i,$real,$imag) = split /\s+/,$line;
   my $zero = Math::Complex->new($real,$imag);
   $self->getStage($currentStage)->addZero($i,$zero);
  }
  elsif($line =~ /B053F15-18/)
  {
   # Complex Poles
   my(undef,$i,$real,$imag) = split /\s+/,$line;
   my $pole = Math::Complex->new($real,$imag);
   $self->getStage($currentStage)->addPole($i,$pole);
  }
  elsif ( $line =~ /^B058F04/)
  {
   my($label,$gain) = split /:/,$line;
   $gain = $self->_trim($gain);
   if ( $currentStage == 0 )
   {
    $self->getStage($currentStage)->setSensitivity($gain);
   }
   else
   {
    $self->getStage($currentStage)->setGain($gain);
   }
  }
 } 

 close $fp;
}

=head2 setStation($self,$name)

Set the station name to C<$name>.

=cut

sub
setStation
{
 my($self,$name) = @_;

 $self->{'Station'} = $name;
}

=head2 setNetwork($self,$net)

Set the network name to C<$net>.

=cut

sub
setNetwork
{
 my($self,$net) = @_;

 $self->{'Network'} = $net;
}

=head2 setLocation($self,$loc)

Set the location to C<$loc>.

=cut

sub
setLocation
{
 my($self,$loc) = @_;

 if( $loc eq '??')
 {
  $self->{'Location'} = undef;
 }
 else
 {
  $self->{'Location'} = $loc;
 }
}

=head2 setChannel($self,$channel)

Set the channel to C<$channel>.

=cut

sub
setChannel
{
 my($self,$channel) = @_;

 $self->{'Channel'} = $channel;
}

=head2 setStartDate($self,$date)

Set the start date to C<$start>.

=cut

sub
setStartDate
{
 my($self,$date) = @_;

 my($year,$doy,$time) = split /,/,$date; 
 my($month,$day) = $self->_doyConvert($year,$doy);
 my($hour,$minute,$second) = split /:/,$time;
 $self->{'StartTime'} = DateTime->new(year => $year, month => $month, day => $day,
                                      hour => $hour, minute => $minute, second => $second);
}

=head2 setEndDate($self,$date)

Set the end date to C<$start>.

=cut

sub
setEndDate
{
 my($self,$date) = @_;

 if ($date eq 'No Ending Time')
 {
  $self->{'EndTime'} = undef;
 }
 else
 {
  my($year,$doy,$time) = split /,/,$date; 
  my($month,$day) = $self->_doyConvert($year,$doy);
  my($hour,$minute,$second) = split /:/,$time;
  $self->{'EndTime'} = DateTime->new(year => $year, month => $month, day => $day,
                                     hour => $hour, minute => $minute, second => $second);
 }
}

=head2 addStage($self,$stage)

Add a new Seed::Reponse::Stage object for stage number C<$stage>.

=cut

sub
addStage
{
 my($self,$stage) = @_;

 if ( not defined $self->{'Stage'}[$stage] )
 {
  $self->{'Stage'}[$stage] = Seed::Response::Stage->new();
 }
}

=head2 getStage($self,$stage)

Return the Seed::Response::Stage object for stage number C<$stage>.

=cut

sub
getStage
{
 my($self,$stage) = @_;

 return $self->{'Stage'}[$stage];
}

sub
_trim
{
 my($self,$string) = @_;

 $string =~ s/^\s+//;
 $string =~ s/\s+$//;

 return $string;
}

sub
_doyConvert
{
 my($self,$year,$doy) = @_;

 my $dt = DateTime->new(month => 1, day => 1, year => $year);
 $doy--;
 $dt->add( days => $doy );
 
 return $dt->month(),$dt->day();
}

=head1 AUTHOR

Walter Szeliga, C<< <szeliga at colorado.edu> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-seed-response at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Seed-Response>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Seed::Response


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Seed-Response>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Seed-Response>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Seed-Response>

=item * Search CPAN

L<http://search.cpan.org/dist/Seed-Response/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2009 Walter Szeliga, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut
1;
