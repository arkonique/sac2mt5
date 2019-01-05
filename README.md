# sac2mt5
sac2mt5 v1.3
SAC to DSN format converter

-------------------------
sac2mt5 is an abstraction layer for the SACtoDSN.pl perl script written by McCaffrey & Walter available at http://www.geology.cwu.edu/facstaff/walter/mt5/SACtoDSN.pl

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

    -o/--output      Specify the name of the output DSN file. This will be created inside a directory called selected_s2m in                      the data directory. Preferrably a 6 digit code.

    -h/--help        Display this help

    -t/--date        Specify the date and time in YY/MM/DD/HH/mm/ss.s format

    -l/--latlong     Specify the latitude and longitude of the event in LAT/LON format

    -n/--depth       Specify the depth of the event in km


**NOTE:**

1. Please make the required libraries and make sure all the paths are specified correctly in the perl script SACtoDSN.pl
2. Before using this script please make sure to install the three libraries provided along with this (No need to do this if you installed using `install.sh`)
3. Additional paths might need to be changed based on your TauP installation. Check where your ".tvel" files are within your installation. Put in the required directory name in TauP.pm inside Taup-0.01

--------------------

### Updates:

The older repository containing v1.0 has been removed so those changes are no longer available. This is a complete list of changes that have been made:


1. Added capability to also mark P and S wave arrival times, along with adding the necessary headers and selecting only those seismograms with a P or S wave arrival within the specified window

2. Added capability to create separate DSN files for each 100 stations in the data directory as the maximum limit for MT5 for the number of stations in 100

3. Added capability to separately created different DSN files for P ans S waves for an easier handling of the results when using MT5INT


### Bugfixes:

- Changed the input format for dates due to a datetime input error, which caused the script to fail when passing inputs from an event list file through a script when time is in single digits. The change in format also allows for more readable inputs.
- Fixed station selection algorithm for selecting each 100 stations, which caused stations with similar names to get selected.
- Fixed creation of S wave DSN files, which are created with the E component of a station, followed by the N component, which were being created haphazardly in the beginning
- Fixed datetime parsing which caused wrong inputs to be given as event dates

--------------------

### Known Bugs and Problems:

- Stations with clear P and S wave marks are sometimes not used
- SAC files need to be copied to the present working directory for this to work, making the script much slower
- Installation script trashes .bashrc sometimes

### Upcoming updates:

- [ ] A settings file to enable selection of required paths to avoid manual adjustments
- [ ] A possible GUI
- [ ] A powershell port


#### No longer required:

~~The data directory must only contain files which have a valid P and S wave arrival time within the seismogram. If not, the program will exit with an error. So select all good usable waveforms, put them in a directory, along with their response files as specified above and provide the path to that directory to the script.~~
