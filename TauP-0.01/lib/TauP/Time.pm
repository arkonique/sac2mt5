package TauP::Time;

use warnings;
use strict;
use Carp;
use TauP;

=head1 NAME

TauP::Time - A perl interace to taup_time

=cut

our @ISA = qw(TauP);

=head1 SYNOPSIS

=head1 FUNCTIONS

=head2 calculateTravelTimes($deg, $depth, $phase)

Given a distance in degrees C<$deg>, a depth in km C<$depth> and a phase
C<$phase>, calculate the travel time.

Returns: a reference to a list of travel times.

=cut

sub
calculateTravelTimes
{
 my($self,$deg,$depth,$phase) = @_;

 my $time = qx/$self->{'taup_time'} -ph $phase -h $depth -deg $deg -mod $self->{'model'} -time/;

 my(@times) = split /\s+/,$time;

 if ((scalar @times) == 0) { croak "No Travels Times Returned";}
 return \@times;
}

1;
