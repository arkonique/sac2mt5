#!/usr/local/bin/perl -w
use Carp;

# Seismogram::SAC.pm $Revision: 1.2 $
# C. Scrivner
# January 28 - Februrary 8, 1995
# A Perl class for SAC format files

# Methods:
#  $sac    = new Seismogram::SAC (%initialvalues);
#  $status = Read $sac ($filehandle);
#  $status = Write $sac ($filehandle);
#  $sac_gram = Translate SAC ($other_gram);
# The following are Seismogram::Seismogram methods (a superclass of SAC)
#  @list  = Fetch $sac (@headerkeys);   - returns values to header keys
#           Change $sac (%values);      - returns number of successful changes
#  @list  = Split Seismogram::SAC ($sac[,$number]); - split record into pieces
#  $sac   = Join Seismogram::SAC (@list);           - join records into single record

package Seismogram::SAC;

use vars qw( $VERSION );
$VERSION   = sprintf("%d.%02d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/);

require Seismogram::Seismogram;
use Seismogram::Util;
@Seismogram::SAC::ISA = qw( Seismogram::Seismogram );


sub new {
  my $class    = shift;
  # the following is not required at time of construction
  my %initial = @_;
  
  my $self = {};
  bless $self;
  
  $self->Change(%defaults);
  if (%initial) {
    $self->Change(%initial);
  }
  
  return $self;
}


sub Read {
  @_ == 2 or ::croak("$0 Seismogram::SAC::Read: expects 2 arguments ");
  
  my $this       = shift;
  my $filehandle = shift;
  
  $this->ReadHeader($filehandle) or return(0);
  $this->ReadData($filehandle);
}

sub ReadHeader {
  @_ == 2 or ::croak("$0 Seismogram::SAC::ReadHeader: expects 2 arguments ");

  my $this       = shift;
  my $filehandle = shift;

  my $sacfile = 'empty';
  my(@header,%header,$npts,$b,$delta,$e,$leven,$type);

  read($filehandle,$sacfile,$SACSIZE) == $SACSIZE or return(0);
  
  @header = unpack($SACPACK,$sacfile);
  %header = &Seismogram::Util::merge(\@sackeys,\@header);
  $this->Change(%header);
  
  # check for inconsistent flags
  ($leven,$type) = $this->Fetch('leven','iftype');
  return(0) if !defined($leven) or !defined($type);
  if ($leven != $const{TRUE} and $type == $const{ITIME}) {
    warn "$0: probable error - leven FALSE while iftype ITIME\n";
  }
  
  ($npts,$b,$delta) = $this->Fetch('npts','b','delta');
  return(0) if !defined($npts) or !defined($b) or !defined($delta);
  $e = $b + ($npts - 1) * $delta;
  $this->Change('e' => $e);

  1;
}

sub ReadData {
  @_ == 2 or ::croak("$0 Seismogram::SAC::ReadData: expects 2 arguments ");

  my $this       = shift;
  my $filehandle = shift;

  my $sacfile    = "empty";
  my(@header,%header,%header1,
     $npts,$delta,$leven,$type,$datasize);
  my $data  = [];
  my $data1 = [];
  
  $npts = $this->npts;
  $datasize = $npts*4;           # 4 is sizeof(float)
  read($filehandle,$sacfile,$datasize) == $datasize or return(0);
  @$data = unpack("f$npts",$sacfile);
  $this->Change('data' => $data);
  
  $type  = $this->iftype;
  $leven = $this->leven;
  if ($type != $const{'ITIME'}) {
    while (my($key,$val) = each(%header)) {
      $key .= '-1';
      $header1{$key} = $val;
    }
    $this->Change(%header1);
    if ($type == $const{IXY} and $leven == $const{TRUE}) {
      $val = $this->b;
      $data1->[0] = $val;
      $delta = $this->delta;
      for ($i=1;$i<$npts;$i++) {
	$val += $delta;
	$data1->[$i] = $val;
      }
    }
    else {
      read($filehandle,$sacfile,$datasize) == $datasize or return(0);
      @$data1 = unpack("f$npts",$sacfile);	
    }
    $this->Change('data-1' => $data1);
    if ($type == $const{IXY}) {
      my $b = $data1->[0];
      my $e = $data1->[$npts-1];
      $this->Change('b' => $b,'e' => $e,'b-1' => $b,'e-1' => $e);
    }
  }
  
  1;
}


sub ReadAscii {
  @_ == 2 or ::croak("$0 Seismogram::SAC::Read: expects 2 arguments ");
  
  my $this       = shift;
  my $filehandle = shift;
  my $sacfile    = "empty";
  my(@sacfile,@header,%header,%header1);
  my($npts,$b,$delta,$e,$leven,$type,$i,$line);
  my $data  = [];
  my $data1 = [];
  
#  read($filehandle,$sacfile,$SACSIZE) == $SACSIZE or return(0);
  @header = ();
  for ($i=0;$i<$SACASCII_FLOATLINES;$i++) {
    $line = <$filehandle>;
    push(@header,unpack($SACASCII_FLOATPACK,$line));
  }
  for ($i=0;$i<$SACASCII_INTLINES;$i++) {
    $line = <$filehandle>;
    push(@header,unpack($SACASCII_INTPACK,$line));
  }
  for ($i=0;$i<@header;$i++) {
    $header[$i] =~ s/^\s*//;
    $header[$i] =~ s/\s*$//;
  }

  $line = <$filehandle>;
  push(@header,unpack($SACASCII_CHARPACK1,$line));
  for ($i=1;$i<$SACASCII_CHARLINES;$i++) {
    $line = <$filehandle>;
    push(@header,unpack($SACASCII_CHARPACK,$line));
  }    
  %header = &Seismogram::Util::merge(\@sackeys,\@header);
  $this->Change(%header);
  
  # check for inconsistent flags
  ($leven,$type) = $this->Fetch('leven','iftype');
  return(0) if !defined($leven) or !defined($type);
  if ($leven != $const{TRUE} and $type == $const{ITIME}) {
    warn "$0: probable error - leven FALSE while iftype ITIME\n";
  }
  
  ($npts,$b,$delta) = $this->Fetch('npts','b','delta');
  return(0) if !defined($npts) or !defined($b) or !defined($delta);
  $e = $b + ($npts - 1) * $delta;
  $this->Change('e' => $e);
  
  @$data = ();
  $i = 0;
  foreach $line (<$filehandle>) {
    push(@$data,unpack($SACASCII_DATAPACK,$line));
    $i += $SACASCII_DATA_NUMPERLINE;
    last if $i >= $npts;
  }
  return(0) if @$data < $npts;
  $this->Change('data' => $data);
  
  if ($type != $const{'ITIME'}) {
    while (($key,$val) = each(%header)) {
      $key .= '-1';
      $header1{$key} = $val;
    }
    $this->Change(%header1);
    if ($type == $const{IXY} and $leven == $const{TRUE}) {
      $val = $b;
      $data1->[0] = $val;
      for ($i=1;$i<$npts;$i++) {
	$val += $delta;
	$data1->[$i] = $val;
      }
    }
    else {
      @$data1 = ();
      $i = 0;
      foreach $line (<$filehandle>) {
	push(@$data1,unpack($SACASCII_DATAPACK,$line));
	$i += $SACASCII_DATA_NUMPERLINE;
	last if $i >= $npts;
      }
      return(0) if @$data1 < $npts;
    }
    $this->Change('data-1' => $data1);
    if ($type == $const{IXY}) {
      $b = $data1->[0];
      $e = $data1->[$npts-1];
      $this->Change('b' => $b,'e' => $e,'b-1' => $b,'e-1' => $e);
    }
  }
  
  1;
}

# - should write some ascii equivalents of the ReadHeader and ReadData subs
# - should also document the ReadHeader and ReadData subs
# - also consider whether WriteHeader and WriteData subs would be useful


sub Write {
  @_ == 2 or ::croak("$0 Seismogram::SAC::Write: passed wrong number of arguments ");
  no strict 'subs';
  my $this       = shift;
  my $filehandle = shift;
  my(@sac,$sacfile,$npts,$b,$delta,$e,$data);
  my($leven,$type,$depmin,$depmax,$depmen,$this_data);
  
  ($leven,$type) = $this->Fetch('leven','iftype');
  return(0) if $leven != $const{TRUE} and $type == $const{ITIME};
  ($npts,$b,$delta) = $this->Fetch('npts','b','delta');
  if (!defined($npts) or !defined($b) or !defined($delta)) {
    return(0);
  }
  $e = $b + ($npts - 1) * $delta;
  $this->Change('e' => $e);
  
  # set depmin, depmax, depmen
  ($data) = $this->Fetch('data');
  $depmin = $depmax = $depmen = $data->[0];
  for ($i=1;$i<$npts;$i++) {
    $this_data = $data->[$i];
    $depmin = $this_data if $this_data < $depmin;
    $depmax = $this_data if $this_data > $depmax;
    $depmen += $this_data;
  }
  $depmen /= $npts;
  $this->Change('depmin' => $depmin,'depmax' => $depmax,'depmen' => $depmen);
  
  @sac = $this->Fetch(@sackeys);
  push(@sac,$data);
  for ($i=0;$i<@sac;$i++) {
    $sac[$i] = $defaults{$sackeys[$i]} if !defined($sac[$i]);
  }
  
  $data = pop(@sac);
  $sacfile  = pack("${SACPACK}f$npts",@sac,@$data);
  if ($type != $const{ITIME}) {
    ($data) = $this->Fetch('data-1');
    return(0) if !defined($data);
    $sacfile .= pack("f$npts",@$data);
  }
  
  print $filehandle $sacfile;
}

sub Translate {
  @_ == 2 or ::croak("$0 Seismogram::SAC::Translate: expects 2 arguments");
  
  my $class = shift;
  my $that  = shift;
  my %translating = %$that;
  my $translated = \%translating;
  
  bless $translated;
}

# set depmin and depmax in header based on current data
sub store_range {
  my $this  = shift;
  my $trace = shift || 0;

  my($min,$max) = (0,0);
  my($data) = $this->Fetch("data-$trace");
  foreach my $pt (@$data) {
    $min = $pt, next if $pt < $min;
    $max = $pt       if $pt > $max;
  }

  $this->Change("depmin-$trace" => $min,
                "depmax-$trace" => $max);

  return;
}


# some necessary values
$Seismogram::SAC::SACPACK = 
    "f70l40A8A16A8A8A8A8A8A8A8A8A8A8A8A8A8A8A8A8A8A8A8A8A8";
$Seismogram::SAC::SACSIZE = 632;

$Seismogram::SAC::SACASCII_FLOATPACK  = "a15a15a15a15a15";
$Seismogram::SAC::SACASCII_FLOATLINES = 14;
$Seismogram::SAC::SACASCII_INTPACK    = "a10a10a10a10a10";
$Seismogram::SAC::SACASCII_INTLINES   = 8;
$Seismogram::SAC::SACASCII_CHARPACK1  = "a8a16";
$Seismogram::SAC::SACASCII_CHARPACK   = "a8a8a8";
$Seismogram::SAC::SACASCII_CHARLINES  = 8;
$Seismogram::SAC::SACASCII_DATAPACK   = "a15a15a15a15a15";
$Seismogram::SAC::SACASCII_DATA_NUMPERLINE = 5;


#The order of these matters, so don't mess with them offhand
@Seismogram::SAC::sackeys = 
    ("delta","depmin","depmax","scale","odelta","b","e","o","a",
     "internal1","t0","t1","t2","t3","t4","t5","t6","t7","t8",
     "t9","f","resp0","resp1","resp2","resp3","resp4","resp5",
     "resp6","resp7","resp8","resp9","stla","stlo","stel","stdp",
     "evla","evlo","evel","evdp","mag","user0","user1",
     "user2","user3","user4","user5","user6","user7","user8",
     "user9","dist","az","baz","gcarc","internal2","internal3",
     "depmen","cmpaz","cmpinc","unused2","unused3","unused4",
     "unused5","unused6","unused7","unused8","unused9","unused10",
     "unused11","unused12","nzyear","nzjday","nzhour","nzmin",
     "nzsec","nzmsec","internal4","internal5","internal6",
     "npts","internal7","internal8","unused13","unused14",
     "unused15","iftype","idep","iztype","unused16","iinst",
     "istreg","ievreg","ievtyp","iqual","isynth","unused17",
     "unused18","unused19","unused20","unused21","unused22",
     "unused23","unused24","unused25","unused26","leven","lpspol",
     "lovrok","lcalda","unused27","kstnm","kevnm","khole","ko",
     "ka","kt0","kt1","kt2","kt3","kt4","kt5","kt6","kt7","kt8",
     "kt9","kf","kuser0","kuser1","kuser2","kcmpnm","knetwk",
     "kdatrd","kinst"
     );

%Seismogram::SAC::const = 
    ("TRUE"   =>  1,"FALSE"  =>  0,"IREAL"  =>  0,"ITIME"  =>  1,
     "IRLIM"  =>  2,"IAMPH"  =>  3,"IXY"    =>  4,"IUNKN"  =>  5,
     "IDISP"  =>  6,"IVEL"   =>  7,"IACC"   =>  8,"IB"     =>  9,
     "IDAY"   => 10,"IO"     => 11,"IA"     => 12,"IT0"    => 13,
     "IT1"    => 14,"IT2"    => 15,"IT3"    => 16,"IT4"    => 17,
     "IT5"    => 18,"IT6"    => 19,"IT7"    => 20,"IT8"    => 21,
     "IT9"    => 22,"IRADNV" => 23,"ITANNV" => 24,"IRADEV" => 25,
     "ITANEV" => 26,"INORTH" => 27,"IEAST"  => 28,"IHORZA" => 29,
     "IDOWN"  => 30,"IUP"    => 31,"ILLLBB" => 32,"IWWSN1" => 33,
     "IWWSN2" => 34,"IHGLP"  => 35,"ISRO"   => 36,"INUCL"  => 37,
     "IPREN"  => 38,"IPOSTN" => 39,"IQUAKE" => 40,"IPREQ"  => 41,
     "IPOSTQ" => 42,"ICHEM"  => 43,"IOTHER" => 44,"IGOOD"  => 45,
     "IGLCH"  => 46,"IDROP"  => 47,"ILOWSN" => 48,"IRLDTA" => 49,
     "IVOLTS" => 50,"INIV51" => 51,"INIV52" => 52,"INIV53" => 53,
     "INIV54" => 54,"INIV55" => 55,"INIV56" => 56,"INIV57" => 57,
     "INIV58" => 58,"INIV59" => 59,"INIV60" => 60,
     );

%Seismogram::SAC::defaults = 
    ("data"      => "filling space",
     # float values
     "delta"     => -12345.,"depmin"    => -12345.,"depmax"    => -12345.,
     "scale"     => -12345.,"odelta"    => -12345.,"b"         => -12345.,
     "e"         => -12345.,"o"         => -12345.,"a"         => -12345.,
     "internal1" =>  2.0   ,"t0"        => -12345.,"t1"        => -12345.,
     "t2"        => -12345.,"t3"        => -12345.,"t4"        => -12345.,
     "t5"        => -12345.,"t6"        => -12345.,"t7"        => -12345.,
     "t8"        => -12345.,"t9"        => -12345.,"f"         => -12345.,
     "resp0"     => -12345.,"resp1"     => -12345.,"resp2"     => -12345.,
     "resp3"     => -12345.,"resp4"     => -12345.,"resp5"     => -12345.,
     "resp6"     => -12345.,"resp7"     => -12345.,"resp8"     => -12345.,
     "resp9"     => -12345.,"stla"      => -12345.,"stlo"      => -12345.,
     "stel"      => -12345.,"stdp"      => -12345.,"evla"      => -12345.,
     "evlo"      => -12345.,"evel"      => -12345.,"evdp"      => -12345.,
     "mag"       => -12345.,"user0"     => -12345.,"user1"     => -12345.,
     "user2"     => -12345.,"user3"     => -12345.,"user4"     => -12345.,
     "user5"     => -12345.,"user6"     => -12345.,"user7"     => -12345.,
     "user8"     => -12345.,"user9"     => -12345.,"dist"      => -12345.,
     "az"        => -12345.,"baz"       => -12345.,"gcarc"     => -12345.,
     "internal2" => -12345.,"internal3" => -12345.,"depmen"    => -12345.,
     "cmpaz"     => -12345.,"cmpinc"    => -12345.,"unused2"   => -12345.,
     "unused3"   => -12345.,"unused4"   => -12345.,"unused5"   => -12345.,
     "unused6"   => -12345.,"unused7"   => -12345.,"unused8"   => -12345.,
     "unused9"   => -12345.,"unused10"  => -12345.,"unused11"  => -12345.,
     "unused12"  => -12345.,
     # long values
     "nzyear"    => -12345,"nzjday"    => -12345,"nzhour"    => -12345,
     "nzmin"     => -12345,"nzsec"     => -12345,"nzmsec"    => -12345,
     "internal4" =>  6    ,"internal5" =>  0    ,"internal6" =>  0,
     "npts"      => -12345,"internal7" => -12345,"internal8" => -12345,
     "unused13"  => -12345,"unused14"  => -12345,"unused15"  => -12345,
     "iftype"    => $const{"ITIME"}             ,"idep"      => -12345,
     "iztype"    => -12345,"unused16"  => -12345,"iinst"     => -12345,
     "istreg"    => -12345,"ievreg"    => -12345,"ievtyp"    => -12345,
     "iqual"     => -12345,"isynth"    => -12345,"unused17"  => -12345,
     "unused18"  => -12345,"unused19"  => -12345,"unused20"  => -12345,
     "unused21"  => -12345,"unused22"  => -12345,"unused23"  => -12345,
     "unused24"  => -12345,"unused25"  => -12345,"unused26"  => -12345,
     "leven"     => $const{"TRUE"}              ,"lpspol"    => -12345,
     "lovrok"    => $const{"TRUE"}              ,
     "lcalda"    => $const{"TRUE"},"unused27"  => $const{"FALSE"},
     # char values
     "kstnm"  => "-12345  ","kevnm"  => "-12345          ",
     "khole"  => "-12345  ","ko"     => "-12345  ","ka"     => "-12345  ",
     "kt0"    => "-12345  ","kt1"    => "-12345  ","kt2"    => "-12345  ",
     "kt3"    => "-12345  ","kt4"    => "-12345  ","kt5"    => "-12345  ",
     "kt6"    => "-12345  ","kt7"    => "-12345  ","kt8"    => "-12345  ",
     "kt9"    => "-12345  ","kf"     => "-12345  ","kuser0" => "-12345  ",
     "kuser1" => "-12345  ","kuser2" => "-12345  ","kcmpnm" => "-12345  ",
     "knetwk" => "-12345  ","kdatrd" => "-12345  ","kinst"  => "-12345  ",
     );


1;

=pod

=head1 NAME

Seismogram::SAC - class for SAC format seismogram objects

=head1 SYNOPSIS

    use Seismogram::SAC;

    $gram   = new Seismogram::SAC (%initialvalues);
    $status = $gram->Read($filehandle);
    $status = $gram->Write($filehandle);
    $sac_gram = Translate SAC ($other_gram);

    # The following are Seismogram::Seismogram methods
    # inherited by Seismogram::SAC
    @values = $gram->Fetch(@headerkeys);
              $gram->Change(%values);
    @grams  = Split Seismogram::SAC ($gram,$number);
    $gram   = Join Seismogram::SAC (@grams);

    # Also any header variable name can act as a get/set function.
    # I.e.,
    $npts = $gram->npts;
    $gram->npts(2500);   # npts in seismogram header now 2500

    # it may be necessary to set amplitude range in the header
    # I.e.,
    $gram->store_range if $gram->depmax == -12345;


=head1 DESCRIPTION

This module extends the general B<Seismogram::Seismogram> class to handle
Seismic Analysis Code (SAC) format data.  SAC is a collection of tools to
work with seismic data, developed at Lawrence Livermore National Lab:

http://www-ep.es.llnl.gov/tvp/sac.html

The format for seismic data expected by this code has become one of a few 
commonly used seismic data formats.

In this module there are methods to create SAC objects, read SAC objects
from disk, write SAC objects to disk, and translate SAC objects into other
seismogram formats.  The header variables defined for the SAC object are
those listed in the SAC manual:

http://www-ep.es.llnl.gov/tvp/sac_manual/users_manual6.html

Note that default null values in SAC format are -12345 in either
integer, float, or string representations.

=head1 METHODS

=head2 new

    Create a SAC object with default null values or (optionally) some
    initial values.

    Usage: $gram = Seismogram::SAC->new(%initialvalues);

    Arguments:

        %initialvalues - (optional) an associative array with header
                         variable name and value pairs.  This can also
                         include a 'data' key and data array reference
                         to load waveform data into the object.

    Return:

        $gram          - a Seismogram::SAC object

=head2 Read

    Read a SAC format file and load into the Seismogram::SAC object.

    Usage: $status = $gram->Read($filehandle);

    Argument:

        $filehandle - a reference to a file handle to a SAC format file,
                      open for reading.  See the IO::File manpage for
                      information on opening file handle references.

    Return:

        $status     - status of the attempted read operation.  1 if
                      successful. 0 if failed.

=head2 Write

    Write a SAC format file with data from the Seismogram::SAC object

    Usage: $status = $gram->Write($filehandle);

    Argument:

        $filehandle - a reference to a file handle to a SAC format file,
                      open for writing.

    Return:

        $status     - status of the attempted write operation.  1 if
                      successful.  0 if failed.

=head2 Translate

    Translate another kind of Seismogram:: object into a Seismogram::SAC
    object.

    Usage: $sac_gram = Translate Seismogram::SAC ($other_gram);

    Argument:

        Seismogram::SAC - this string verbatim
        $other_gram     - Seismogram:: object of some type other than
                          Seismogram::SAC.

    Return:

        $sac_gram       - a Seismogram::SAC object

    Comment:

        The first argument of this method directs the perl interpreter
        to use the Translate method from the Seismogram::SAC class, so 
        the output will be a Seismogram::SAC object.

=head2 store_range

    New SAC files extracted from a SEED or miniSEED file often don't
    have depmin and depmax values set in the header.  The store_range
    function will set these based on the current data in the SAC object.

    Usage: $sac_gram->store_range($trace);

    Argument:

        $trace  - the index of the trace (in a multi-trace object) to
                  be fixed.  The argument is optional.  If not given
                  the first trace (index 0) is assumed.

    Return:

        none

    Comment:

        Looping through the data to determine the data to determine
        the amplitude range is an expensive operation for a large trace.
        It is best to check whether the process is needed with some code
        like

            $gram->store_range if $gram->depmax == -12345

        using the default header value as an indicator the header is
        not yet correctly set.

=head1 SEE ALSO

L<Seismogram::Seismogram>

=head1 VERSION

$Revision: 1.2 $

=head1 AUTHOR

Craig Scrivner

=cut
