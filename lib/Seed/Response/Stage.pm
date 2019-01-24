package Seed::Response::Stage;

use warnings;
use strict;
use Carp;
use Math::Complex;

=head1 NAME

Seed::Response::Stage -- A perl module to store transfer function stage information from a seed RESP file.

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

Seed::Response::Stage is an object to store stage information
from a Seed Response file.

=head1 FUNCTIONS

=head2 new()

Create a new Seed::Response::Stage object.

=cut

sub
new
{
 my($class) = shift;

 my $self = {};
 $self->{'units'} = undef;
 $self->{'TransferFunctionType'} = undef;
 $self->{'A0NormalizationFactor'} = undef;
 $self->{'NormalizationFrequency'} = undef;
 $self->{'Sensitivity'} = undef;
 $self->{'Gain'} = undef;
 $self->{'NumberOfPoles'} = undef;
 $self->{'NumberOfZeros'} = undef;
 $self->{'Poles'} = ();
 $self->{'Zeros'} = ();

 bless $self, $class;

 return $self;
}

=head2 setUnits($self,$units)

Set the units to C<$units>.

=cut

sub
setUnits
{
 my($self,$units) = @_;

 $self->{'units'} = $units;
}

=head2 getUnits($self)

Return the units of the response.

=cut

sub
getUnits
{
 my($self) = @_;

 return $self->{'units'};
}

=head2 setNormalizationFactor($self,$constant)

Set the normalization factor C<$constant>.

=cut

sub
setNormalizationFactor
{
 my($self,$constant) = @_;

 $self->{'A0NormalizationFactor'} = $constant;
}

=head2 getNormalizationFactor($self)

Return the normalization factor.

=cut

sub
getNormalizationFactor
{
 my($self) = @_;
 
 return $self->{'A0NormalizationFactor'};
}

=head2 setNormalizationFrequency($self,$freq)

Set the normalization frequency to C<$freq>.

=cut

sub
setNormalizationFrequency
{
 my($self,$freq) = @_;

 $self->{'NormalizationFrequency'} = $freq;
}

=head2 getNormalizationFrequency($self)

Get the normalization frequency.

=cut

sub
getNormalizationFrequency
{
 my($self) = @_;

 return $self->{'NormalizationFrequency'};
}

=head2 setGain($self,$gain)

Set the instrument gain to C<$gain>.

=cut

sub
setGain
{
 my($self,$gain) = @_;

 $self->{'Gain'} = $gain;
}

=head2 getGain($self,$gain)

Get the instrument gain.

=cut

sub
getGain
{
 my($self) = @_;

 return $self->{'Gain'};
}

=head2 setSensitivity($self,$gain)

Set the instrument gain to C<$gain>.

=cut

sub
setSensitivity
{
 my($self,$gain) = @_;

 $self->{'Sensitivity'} = $gain;
}

=head2 getSensitivity($self,$gain)

Get the instrument gain.

=cut

sub
getSensitivity
{
 my($self) = @_;

 return $self->{'Sensitivity'};
}

=head2 setNumberOfZeros($self,$zeros)

Set the number of zeros to C<$zeros>.

=cut

sub
setNumberOfZeros
{
 my($self,$zeros) = @_;

 $self->{'NumberOfZeros'} = $zeros;
}

=head2 getNumberOfZeros($self)

Return the number of zeros.

=cut

sub
getNumberOfZeros
{
 my($self) = @_;
 
 return $self->{'NumberOfZeros'}; 
}

=head2 setNumberOfPoles($self,$poles)

Set the number of poles to C<$poles>.

=cut

sub
setNumberOfPoles
{
 my($self,$poles) = @_;

 $self->{'NumberOfPoles'} = $poles;
}

=head2 getNumberOfPoles($self,$poles)

Get the number of poles.

=cut

sub
getNumberOfPoles
{
 my($self) = @_;
 
 return $self->{'NumberOfPoles'}; 
}

=head2 addPole($self,$i,$pole)

Set the C<$i>th array entry to pole C<$pole>.

=cut

sub
addPole
{
 my($self,$i,$pole) = @_;

 $self->{'Poles'}[$i] = $pole;
}

=head2 getPole($self,$i)

Get the value for the C<$i>th pole.

=cut

sub
getPole
{
 my($self,$i) = @_;

 return $self->{'Poles'}[$i];
}

=head2 addZero($self,$i,$zero)

Set the C<$i>th array entry to zero C<$zero>.

=cut

sub
addZero
{
 my($self,$i,$zero) = @_;

 $self->{'Zeros'}[$i] = $zero;
}

=head2 getZero($self,$i)

Get the value for the C<$i>th zero.

=cut

sub
getZero
{
 my($self,$i) = @_;

 return $self->{'Zeros'}[$i];
}

sub
setTransferType
{
 my($self,$type) = @_;

 if ($type =~ /^A/ )
 {
  # Type is rad/sec
  $self->{'TransferFunctionType'} = 'A';
 } 
 elsif ( $type =~ /^B/ )
 {
  # Type is Hz/sec
  $self->{'TransferFunctionType'} = 'B';
 }
 else
 {
  # Unknown transfer function
  carp("Unknown Transfer Function Type $type\n");
 }
}

sub
getTransferType
{
 my($self) = @_;
 
 return $self->{'TransferFunctionType'};
}

=head1 AUTHOR

Walter Szeliga, C<< <szeliga at colorado.edu> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-seed-response at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Seed-Response>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Seed::Response::Stage


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
