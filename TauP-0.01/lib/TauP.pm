package TauP;

use warnings;
use strict;
use Carp;

=head1 NAME

TauP - A perl interface to TauP

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

=head1 FUNCTIONS

=head2 new()

Create a new TauP object.

=cut

sub
new
{
 my($class,$taupHome) = @_;

 if ( defined $taupHome)
 { 
  $ENV{'TAUP_HOME'} = $taupHome; 
 }

 if ( not defined $ENV{'TAUP_HOME'} ) { croak "Could not find TauP\n"; }
 my $self = {};
 $self->{'taup_curve'} = $ENV{'TAUP_HOME'}.'/bin/taup_curve';
 $self->{'taup_time'} = $ENV{'TAUP_HOME'}.'/bin/taup_time';

 bless $self,$class;

 $self->setModel('iasp91');

 return $self;
}

=head2 setModel($self,$model)

Set the model to C<$model> for use in subsequent travel time calculations.

=cut

sub
setModel
{
 my($self,$model) = @_;;

 my $tvelFile = $ENV{'TAUP_HOME'}.'/StdModels/'.$model.'.tvel';
 my $ndFile = $ENV{'TAUP_HOME'}.'/StdModels/'.$model.'.nd';
 if ( (-e $tvelFile) or (-e $ndFile) )
 {
  $self->{'model'} = $model;
 }
 else
 {
  croak "Neither $tvelFile nor $ndFile found\n";
 }
}

=head2 getModel($self)

Return the current travel time model.

=cut

sub
getModel
{
 my($self) = @_;

 return $self->{'model'};
}

=head1 AUTHOR

Walter Szeliga, C<< <szeliga at colorado.edu> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-taup at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=TauP>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc TauP


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=TauP>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/TauP>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/TauP>

=item * Search CPAN

L<http://search.cpan.org/dist/TauP/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Walter Szeliga, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut
1;
