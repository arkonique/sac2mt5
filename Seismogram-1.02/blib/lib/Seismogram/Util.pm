use Carp;
package Seismogram::Util;

use vars qw( $VERSION );
$VERSION = sprintf("%d.%02d", q$1.2$ =~ /(\d+)\.(\d+)/);

# Documentation for all routines in pod format at end of module

sub compress {
	my($filename,$extension) = @_;
	my(%map,$status);

	%map = ("gz","gzip",
	        "z" ,"gzip",
		"Z" ,"compress");

	$status = system $map{$extension},$filename;
}



sub uncompress {
	my($filename) = @_;
	my(%map,$extension,$test,$status,$newfile);

	%map = ("gz","gunzip",
	        "z" ,"gunzip",
	        "Z" ,"uncompress");

	$extension = $filename;
	$extension =~ s#(.*)\.##;
	$newfile = $1;

	$test = grep(/$extension/,keys(%map));

	if ($test) {
		$status = system "$map{$extension} $filename";
	}
	else {
		$status = -256;
		$newfile = $filename
	}

	($status,$newfile);
}



sub getpath {
	my($filename) = @_;
	my(@part,$path,$file);

	$filename .= "+";  # tag the end of the string
	@part = split(m#\/#,$filename);
	if ($part[@part-1] eq "+") {
		chop($filename);   # remove the + tag
		$file = undef;
		$path = $filename;
	}
	else {
		$file = pop(@part);
		chop($file);      # remove the + tag
		$path = join("/",@part) . "/";
	}

	($path,$file);
}



sub assoc2normal {
	@_ == 2 or
	  ::croak("$0: assoc2normal passed wrong number of arguments");
	my $associative = shift;
	my $order       = shift;
	my(@normal,$i);

	for ($i=0;$i<@$order;$i++) {
		$normal[$i] = $$associative{$$order[$i]};
	}

	@normal;
}



sub normal2assoc {
    @_ == 2 or ::croak("$0: normal2assoc passed wrong number of arguments");

    my $normal = shift;
    my $order  = shift;
    my($key,%associative);

    for ($i=0;$i<@$order;$i++) {
	$associative{$$order[$i]} = $$normal[$i];
    }
    
    %associative;
}


sub merge {
    @_ == 2 or ::croak("$0: util::merge: requires 2 arguments ");

    my $first = shift;
    my $second = shift;
    my($i,$number,@output);

    $number = @$first < @$second ? @$first : @$second;
    for ($i=0;$i<$number;$i++) {
	push(@output,$first->[$i],$second->[$i]);
    }

    @output;
}

1;


=pod

=head1 NAME

util.pl - a set of commonly needed routines

=head1 SYNOPSIS

    require "util.pl";

    See routine descriptions below

=head1 DESCRIPTION

This module contains a few handy utility codes that compress and uncompress
files, convert associative arrays to normal arrays and vice versa, and get
the path of a filename.

=head1 ROUTINES

=head2 compress

Compress file using program determined by the filename extension passed

Arguments:

    $filename     - name of the uncompressed file

    $extension    - filename extension to be mapped to the compression
                    code. The extension should *not* have a leading 
                    period (.)

Return:

    $status       - return value of the system call

=head2 uncompress

Uncompress file using program determined by the filename extension

Argument:

    $filename     - name of the compressed file

Return:

    $status       - return value of the system call (a multiple of 256).
                    If filename extension is unknown, returns -256

    $filename     - name of uncompressed file if decompress was successful.
                    Otherwise, the original value of $filename.

Problem:

    will spew error message if the file does not exist

=head2 getpath

Separate the path from filename in the given string. If the string
ends in /, the file name is undefined.

Argument:

    $filename     - name of file including the path

Return:

    $path         - the path in $filename
    $file         - the file in $filename, without the path

=head2 assoc2normal

Convert an associative array to a normal array with the normal 
array organized according to an "order array"

Arguments:

    $associative  - reference to the original associative array
    $order        - reference to a normal array of the keys in order

Return:

    @normal       - the normal array with values from %$associative

Comments:

    The values of array @$order are the same keys as the original
    array %associative. The keys are stored in @$order in the order the
    values of %$associative values should go into @normal

    Any key, value pairs in %$associative that do not have a
    corresponding key in @$order will be skipped (this is intentional)

=head2 normal2assoc

Convert a normal array to an associative array organized by an "order" array.
Keys for the associative array are taken from the order array.

Arguments:

    $normal       - reference to the original normal array
    $order        - reference to the "order" normal array

Return:

    %associative  - the associative array of values from @$normal

Comment:

    This subroutine is the reverse of assoc2normal.  The same @$order array 
    is used for both routines.

=head2 merge

Merge two normal arrays by alternately pushing values of the two arrays
into the output array.

Arguments:

    $first        - reference to a normal array
    $second       - reference to a normal array

Return:

    @output       - a normal array

=head1 VERSION

1.2

=head1 AUTHOR

Craig Scrivner

=cut
