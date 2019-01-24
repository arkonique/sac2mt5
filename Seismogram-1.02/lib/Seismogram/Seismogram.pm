#!/usr/local/bin/perl -w
# Seismogram::Seismogram.pm $Revision: 1.2 $

# Includes general routines shared by all seismogram subtypes

package Seismogram::Seismogram;
use Seismogram::Util;

%Seismogram::Seismogram::proxy = 
    ('year' => 'nzyear','jday' => 'nzjday','hour' => 'nzhour',
     'min' => 'nzmin','minute' => 'nzmin','sec' => 'nzsec',
     'msec' => 'nzmsec','station' => 'kstnm','stnm' => 'kstnm',
     'cmp' => 'kcmpnm','cmpnm' => 'kcmpnm',
     'distance' => 'dist','dt' => 'delta','azi' => 'az');

%Seismogram::Seismogram::special = ('amp' => get_amp);

AUTOLOAD {
  my $this  = shift;
  my $value = shift;
  my $key   = $AUTOLOAD;

  $key =~ s/^.*:://;

  return if $key eq 'DESTROY';

  if (defined($value)) {
    $this->Change($key => $value);
  }
  else {
    ($value) = $this->Fetch($key);
    return($value);
  }

}

sub Fetch {
  my $this   = shift;
  my @params = @_;
  my($param,$key,$trace,@list);
  
  foreach $param (@params) {
    ($key,$trace) = split(/\-/,$param);
    $key = $proxy{$key} if defined($proxy{$key});
    $trace = 0 if !defined($trace);
    if (defined($this->{$key}) and defined($this->{$key}->[$trace])) {
      push(@list,$this->{$key}->[$trace]);
    }
    elsif (defined($special{$key})) {
      push(@list,&{$special{$key}}($this,$trace));
    }
    else {
      push(@list,undef);
    }
  }
  
  return(@list);
}

sub Change {
  my $this = shift;
  my %changes = @_;
  my($rawkey,$value,$key,$trace);
  
  while (($rawkey,$value) = each(%changes)) {
    ($key,$trace) = split(/\-/,$rawkey);
    $key = $proxy{$key} if defined($proxy{$key});
    $trace = 0 if !defined($trace);
    $this->{$key}->[$trace] = $value;
  }
  
  1;
}


sub Split {
  my $class  = shift;
  my $this   = shift;
  my $number = shift;
  my($numtraces,@keys,$i,@keys_i,$j,@pieces);
  
  ($numtraces) = $this->Fetch('numtraces');
  $numtraces = 1 if !defined($numtraces);
  $number = (defined($number) and $number < $numtraces) ? 
      $number - 1 : $numtraces - 1;
  @keys = keys %$this;
  for ($i=0;$i<$number;$i++) {
    my %piece = &map_trace_hash($this,$i,0,@keys);
    my $piece = $class->new(%piece);
    $piece->Change('numtraces' => 1);
    push(@pieces,$piece);
  }
  my $leftover = $class->new;
  for($i=$number,$j=0;$i<$numtraces;$i++,$j++) {
    my %piece = &map_trace_hash($this,$i,$j,@keys);
    $leftover->Change(%piece);
  }
  $numtraces = $numtraces - $number;
  $leftover->Change('numtraces' => $numtraces);
  push(@pieces,$leftover);
  
  return(@pieces);
}


sub Join {
  my $class  = shift;
  my @pieces = @_;
  my($numpieces,$total,$joined,$i,$piece,@keys,$j,$k,@keys_j);
  
  $numpieces = @pieces;
  $total = 0;
  $joined = $class->new;
  for ($i=0;$i<$numpieces;$i++,$total += $numtraces) {
    $piece = shift(@pieces);
    if (!defined($piece)) {
      $numtraces = 1;
      next;
    }
    ($numtraces) = $piece->Fetch('numtraces');
    $numtraces = 1 if !defined($numtraces);
    @keys = keys %$piece;
    for ($j=0,$k=$total;$j<$numtraces;$j++,$k++) {
      my %piece = &map_trace_hash($piece,$j,$k,@keys);
      $joined->Change(%piece);
    }
#	$total += $numtraces;
  }
  $joined->Change('numtraces' => $total);
  
  return $joined;
}

sub map_trace_hash {
  my $ref   = shift;
  my $i     = shift;
  my $j     = shift;
  my @keys  = @_;
  my(@keys_i,@keys_j,@values,%hash);
  
  @keys_i = map("$_-$i",@keys);
  @values = $ref->Fetch(@keys_i);
  @keys_j = map("$_-$j",@keys);
  %hash = &Seismogram::Util::merge(\@keys_j,\@values);
}



%fault_order = ('tss' => 0,'tds' => 1,
		'xss' => 2,'xds' => 3,'xdd' => 4,
 		'zss' => 5,'zds' => 6,'zdd' => 7);
%cmp_order   = ('tan' => 0,'rad' => 1,'ver' => 2);

sub Mech {
  my $class  = shift; # Seismogram class
  my $trace  = shift;
  my $strike = shift;
  my $rake   = shift;
  my $dip    = shift;
  my $az     = shift;
  return(undef) if !defined($az);
  my($i,$j,@npts,@tr,@tmp,@keys,@vals,%header);
  my($tan,$rad,$ver,@tan,@rad,@ver,%cmp);
  my($tss,$tds,$xss,$xds,$xdd,$zss,$zds,$zdd);
  ($tss,$tds)      = ($fault_order{'tss'},$fault_order{'tds'});
  ($xss,$xds,$xdd) = 
      ($fault_order{'xss'},$fault_order{'xds'},$fault_order{'xdd'});
  ($zss,$zds,$zdd) = 
      ($fault_order{'zss'},$fault_order{'zds'},$fault_order{'zdd'});
  
  @A = &partl($strike,$rake,$dip,$az);
  
 TAN: {
   unless (defined($trace->{'tss'}) and defined($trace->{'tds'})) {
     $tan = undef;
     last TAN;
   }
   $tan = eval { $class->new };
   ($npts[$tss],$tr[$tss]) = $trace->{'tss'}->Fetch('npts','data');
   ($npts[$tds],$tr[$tds]) = $trace->{'tds'}->Fetch('npts','data');
   @tmp = sort { $a <=> $b } ($npts[$tss],$npts[$tds]);
   $npts = shift(@tmp);
   for ($j=0;$j<$npts;$j++) {
     $tan[$j] = $A[3]*$tr[$tss]->[$j] + $A[4]*$tr[$tds]->[$j];
   }
   @keys = keys %{$trace->{'tss'}};
   @vals = $trace->{'tss'}->Fetch(@keys);
   %header = &Seismogram::Util::merge(\@keys,\@vals);
   $tan->Change(%header);
   $tan->Change('numtraces' => 1,'cmp' => 'TAN',
		'npts' => $npts,'data' => \@tan,'cmpaz' => $az + 90);
 }
  
 RAD: {
   unless (defined($trace->{'xss'}) and defined($trace->{'xds'}) and 
	   defined($trace->{'xdd'})) {
     $rad = undef;
     last RAD;
   }
   $rad = eval { $class->new };
   ($npts[$xss],$tr[$xss]) = $trace->{'xss'}->Fetch('npts','data');
   ($npts[$xds],$tr[$xds]) = $trace->{'xds'}->Fetch('npts','data');
   ($npts[$xdd],$tr[$xdd]) = $trace->{'xdd'}->Fetch('npts','data');
   @tmp = sort { $a <=> $b } ($npts[$xss],$npts[$xds],$npts[$xdd]);
   $npts = shift(@tmp);
   for ($j=0;$j<$npts;$j++) {
     $rad[$j] = $A[0]*$tr[$xss]->[$j] + $A[1]*$tr[$xds]->[$j] + 
	 $A[2]*$tr[$xdd]->[$j];
   }
   @keys = keys %{$trace->{'xss'}};
   @vals = $trace->{'xss'}->Fetch(@keys);
   %header = &Seismogram::Util::merge(\@keys,\@vals);
   $rad->Change(%header);
   $rad->Change('numtraces' => 1,'cmp' => 'RAD',
		'npts' => $npts,'data' => \@rad,'cmpaz' => $az);
 }
  
 VER: {
   unless (defined($trace->{'zss'}) and defined($trace->{'zds'}) and 
	   defined($trace->{'zdd'})) {
     $ver = undef;
     last VER;
   }
   $ver = eval { $class->new };
   ($npts[$zss],$tr[$zss]) = $trace->{'zss'}->Fetch('npts','data');
   ($npts[$zds],$tr[$zds]) = $trace->{'zds'}->Fetch('npts','data');
   ($npts[$zdd],$tr[$zdd]) = $trace->{'zdd'}->Fetch('npts','data');
   @tmp = sort { $a <=> $b } ($npts[$zss],$npts[$zds],$npts[$zdd]);
   $npts = shift(@tmp);
   for ($j=0;$j<$npts;$j++) {
     $ver[$j] = $A[0]*$tr[$zss]->[$j] + $A[1]*$tr[$zds]->[$j] + 
	 $A[2]*$tr[$zdd]->[$j];
     $ver[$j] *= -1.0; # Verts need to be flipped because DVH con. + down
   }
   @keys = keys %{$trace->{'zss'}};
   @vals = $trace->{'zss'}->Fetch(@keys);
   %header = &Seismogram::Util::merge(\@keys,\@vals);
   $ver->Change(%header);
   $ver->Change('numtraces' => 1,'cmp' => 'VER',
		'npts' => $npts,'data' => \@ver);
 }
  
  $cmp{'tan'} = $tan;
  $cmp{'rad'} = $rad;
  $cmp{'ver'} = $ver;
  
  return(%cmp);
}

sub partl {
  my $phi    = shift; # strike
  my $lambda = shift; # rake
  my $delta  = shift; # dip
  my $azi    = shift;
  my($tc,$lc,$dc);
  my $con = 0.017453;
  
  $tc =($azi - $phi) *$con;
  $lc =$lambda*$con;
  $dc =$delta *$con;
  
  # The Following are the Ai Coefficients
  $A[0]=sin(2.0*$tc)*cos($lc)*sin($dc) + 
      0.5*cos(2.0*$tc)*sin($lc)*sin(2.0*$dc);
  
  $A[1]=cos($tc)*cos($lc)*cos($dc) - 
      sin($tc)*sin($lc)*cos(2.0*$dc);
  
  $A[2]=0.5*sin($lc)*sin(2.0*$dc);
  
  $A[3]=cos(2.0*$tc)*cos($lc)*sin($dc) - 
      0.5*sin(2.0*$tc)*sin($lc)*sin(2.0*$dc);
  
  $A[4]=sin($tc)*cos($lc)*cos($dc) + 
      cos($tc)*sin($lc)*cos(2.0*$dc);
  
  $A[4] *= -1.0;
  
  return(@A);
}

# Routines for 'special' header keys
sub get_amp {
  my $this = shift;
  my $trace = shift;
  my($neg,$pos,$amp);
  
  ($neg,$pos) = $this->Fetch("depmin-$trace","depmax-$trace");
  if (!defined($neg) or !defined($pos)) {
    return(undef);
  }

  $amp = abs($neg) < abs($pos) ? abs($pos) : abs($neg);
  
  return($amp);
}

1;

=pod

=head1 NAME

Seismogram::Seismogram - base class for seismogram objects

=head1 DESCRIPTION

This module defines methods shared by a set of seismogram classes.

Normally, this package is not imported directly by the user.  Instead,
the package for a specific seismogram format (SAC or Helm) is imported.
The specific format packages import Seismogram::Seismogram for the
generic seismogram functions.

Note that a single seismogram object can contain multiple records
containing distinct headers and waveforms.  Some seismogram formats
naturally contain multiple records (i.e., synthetics in Helm format), 
and others tend to contain only a single record (i.e., SAC format).

The generic functions in this module include methods to access and change 
the headers and waveforms of a seismogram object, to pack multiple objects 
into a single seismogram object, and to unpack a single seismogram object
into multiple objects.

=head1 METHODS

The following are 'public' methods, which are the intended API of this
module.  In addition, there are a few 'private' methods which are
intended only for internal module use, and which are not described here.

Where a method refers to a Seismogram object, this means an object created
by a B<new> command from one of the packages for a specific seismgram
format.

=head2 Fetch

    Retrieve the values of one or more header variables from a seismogram
    object.  Note the values are returned in ARRAY context.

    Usage: @values = $gram->Fetch(@header);

    Arguments:

        $gram   - a Seismogram object
        @header - header variable names, see below

    Returns:

        @values - values of header variables

=head2 Change

    Set the values of one or more header variables of a seismogram object.

    Usage: $gram->Change(%header);

    Arguments:

        $gram    - a Seismogram object
        %header  - a list of key => value pairs, where the key is a
                   header variable name.

=head2 Split

    Split a seismogram object with multiple records into an array of
    seismogram objects.

    Usage: @objects = Split $class ($gram [, $number]);

    Arguments:

        $class   - the class of the output objects (i.e., Seismogram::SAC
                   or Seismogram::Helm)
        $gram    - a Seismogram object
        $number  - (optional) number of new objects to be formed. The
                   default is to split the object up into single record
                   objects. Passing a smaller value for $number will
                   produce $number - 1 single record objects and one
                   multi-record object.

    Returns:

        @objects - an array of seismogram objects

=head2 Join

    Combine a set of seismogram objects into a single seismogram object.

    Usage: $gram = Join $class (@objects);

    Arguments:

        $class   - the class of the output object
        @objects - an array of seismogram objects

    Returns:

        $gram    - the output seismogram object

=head2 Mech

    Apply double-couple source parameters to a set of synthetic
    waveforms to generate radial, tangential, and vertical component
    records.

    Usage: %components = Mech $class ($traces,$strike,$rake,$dip,$azimuth);

    Arguments:

        $class   - the class of the output objects
        $traces  - reference to an associative array containing seismogram
                   objects.  The keys of the associative array indicate
                   the component and fault orientation of the synthetic
                   waveform:

                   tss - tangential component, vertical strike-slip fault
                   tds - tangential component, vertical dip-slip fault
                   xss - radial component, vertical strike-slip fault
                   xds - radial component, vertical dip-slip fault
                   xdd - radial component, 45 degree dip-slip fault
                   zss - vertical component, vertical strike-slip fault
                   zds - vertical component, vertical dip-slip fault
                   zdd - vertical component, 45 degree dip-slip fault

        $strike  - strike of fault
        $rake    - rake of slip on fault
        $dip     - dip of fault from horizontal
        $azimuth - azimuth of receiver from source, in degrees from North

    Returns:

        %components - associative array containing output seismogram
                      objects.  The keys of the array are 'tan','rad', and
                      'ver', indicating the three components of the output
                      synthetic. If one or more of the input waveforms for
                      a particular component were missing, then 'undef' is
                      is returned for that component.

=head2 AUTOLOAD

    Any header variable name can be used as a function name to retrieve
    or change the corresponding header value.  This is syntactic sugar
    for the methods Fetch and Change when only one header variable
    is being accessed.

    Referencing the header variable name without passing an argument will 
    return the variable value (like Fetch).  Passing an argument will 
    change the variable to that value (like Change).

    This is most easily demonstrated with some examples:

        $npts = $gram->npts; # same as $gram->Fetch('npts');
        $gram->npts(2500);   # same as $gram->Change('npts',2500);

    Note that the value is returned in SCALAR context.  This handy,
    but it is different from the normal Fetch behavior.

=head1 HEADER VARIABLE NAMES

The Fetch and Change methods take 'header variable name' arguments
which are strings refering to values stored in the seismogram header.
Examples of the more commonly referenced header values are 'npts' and 'dt'.
In seismogram objects containing multiple records, header values are
indexed (starting from 0) as 'npts-i', where 'i' is the index value for a
given record.  A header variable name without the explicit indexing (i.e.,
'npts') defaults to the 0 index.  Therefore header values of seismogram 
objects with only one record can always be referenced without the index.

While the names of some of the more important of these header variables are
shared by different types of seismogram objects, the bulk of them will be
defined only for a given seismogram format.

Some flexibility is introduced to the header variable names by a set of
proxies defined in this module.  For example, both 'delta' and 'dt' will
return the time increment of waveforms.  Similarly the SAC header date
variables 'nzyear', 'nzmin', etc. can be accessed with 'year', 'min', etc.
The basic idea of the proxies is to use the accurate header variable names
for a format when possible, but if you slip up, some of the more common
variants will work as well.

In addition, you can introduce header values with tags of your own using
the Change method, but unless they are defined for a format they will
not be written to file during a Write operation.

See the documentation of the modules for specific seismogram formats for
a complete list of header variable names for that format.

=head1 ACCESSING DATA

Passing 'data-i' to Fetch

    ($data) = $gram->Fetch('data-i');

will return a reference to the array of data
points for 'i'th record (starting from 0) in the seismogram object.
Similarly 

    $data = $gram->data;

will return a reference to the first record in the object.  B<Note>
that this is an array B<reference>, so changes to the array through
this reference change the data in the object.  In fact, a call to
Change is not needed to store the changes into the object.

This is often handy, but dangerous.  If you do not want changes
passed through automatically to the object, make a local copy of the
array

    @datacopy = @$data;

and work on this copy.

=head1 SEE ALSO

L<Seismogram::SAC> and L<Seismogram::Helm>

=head1 VERSION

$Revision: 1.2 $

=head1 AUTHOR

Craig Scrivner

=cut
