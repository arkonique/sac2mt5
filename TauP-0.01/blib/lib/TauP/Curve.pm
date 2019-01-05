package TauP::Curve;

use warnings;
use strict;
use Carp;
use File::Temp;

=head1 NAME

TauP::Curve - A perl interace to taup_curve

=cut

our @ISA = qw(TauP);

=head1 SYNOPSIS

=head1 FUNCTIONS

=head2 getTravelTimeCurve($self,$depth,@phases)>

Given a depth C<$depth> and a list of phases C<@phases>, calculate travel time
curves.

=cut

sub
getTravelTimeCurve
{
 my($self,$depth,@phases) = @_;

 my $phaseList = join(',',@phases);
 my $travelTime = File::Temp->new();
 qx/$self->{'taup_curve'} -ph $phaseList -h $depth -mod $self->{'model'} -o $travelTime/;

 my %travelTimes = ();
 while(<$travelTime>)
 {
  my($x,$y) = split;
  push(@{$travelTimes{'x'}},$x);
  push(@{$travelTimes{'y'}},$y);
 }
 
 return \%travelTimes;
}

1;
