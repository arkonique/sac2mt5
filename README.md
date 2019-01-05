# sac2mt5
sac2mt5 v1.3
SAC to DSN format converter

-------------------------
sac2mt5 is an abstraction layer for the SACtoDSN.pl perl script written by McCaffrey available at http://www.geology.cwu.edu/facstaff/walter/mt5/SACtoDSN.pl

-------------------------


## Installation
Before installing sac2mt5, please make sure some of the paths used in the package are consistent with your system.
1. Inside sac2mt5/TauP-0.01/lib/Taup.pm, there are the paths of the Taup binaries and velocity models, relative to the path of your Taup installation. Please change these accordingly.
    ```perl
     $self->{'taup_curve'} = $ENV{'TAUP_HOME'}.'/bin/taup_curve';
     $self->{'taup_time'} = $ENV{'TAUP_HOME'}.'/bin/taup_time';
    ```
    ```perl
     my $tvelFile = $ENV{'TAUP_HOME'}.'/StdModels/'.$model.'.tvel';
     my $ndFile = $ENV{'TAUP_HOME'}.'/StdModels/'.$model.'.nd';
    ```

2. Inside sac2mt5/SAC2DSN.pl, change the following paths according to your installation:

	```perl
	use lib 'usr/local/share/perl/5.26.1/'; # Path to perl libraries
	```
	```perl
	my $taup_path='/home/arkonique/TauP-2.4.5'; # Path to Taup installation
	```

To install sac2mt5, run:

```bash
source install.sh
```

## Usage


### Usage:

```bash 
    sac2mt5 [-d/--directory<data directory>] [-o/--output<output file>] [-t/--date <YYMMDDHHmmss.s = date and time>] [-l/--latlong <LAT/LONG>] [-n/--depth <event depth>] [-h/--help]
```

### Options:

    -d/--directory   Specify the directory containing all the SAC files. 
                     This directory must also contain a subdirectory called RESP containing all the instrument response files

    -o/--output      Specify the name of the output DSN file. This will be created inside the data directory.

    -h/--help        Display this help

    -o/--output      Specify the name of the output DSN file. This will be created inside the data directory. Do not include the filename extension.

    -t/--date        Specify the date and time in YY/MM/DD/HH/mm/ss.s format

    -l/--latlong     Specify the latitude and longitude of the event in LAT/LON format

    -n/--depth       Specify the depth of the event in km


**NOTE:**

1. Please make the required libraries and make sure all the paths are specified correctly in the perl script SACtoDSN.pl
2. Before using this script please make sure to install the three libraries provided along with this (No need to do this if you installed using `install.sh`)
3. Additional paths might need to be changed based on your TauP installation. Check where your ".tvel" files are within your installation. Put in the required directory name in TauP.pm inside Taup-0.01

--------------------
The data directory must only contain files which have a valid P and S wave arrival time within the seismogram. If not, the program will exit with an error. So select all good usable waveforms, put them in a directory, along with their response files as specified above and provide the path to that directory to the script.

--------------------