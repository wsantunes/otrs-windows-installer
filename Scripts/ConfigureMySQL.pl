#!/usr/bin/perl -w
# --
# ConfigureMySQL.pl - script to configure MySQL
# Copyright (C) 2001-2008 OTRS AG, http://otrs.org/
# --
# $Id: ConfigureMySQL.pl,v 1.2 2008-11-27 14:17:11 mh Exp $
# --
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
# --

use strict;
use warnings;

use Getopt::Std;
use File::Find;

use vars qw($VERSION);
$VERSION = qw($Revision: 1.2 $) [1];

# get options
my %Opts = ();
getopt( 'd', \%Opts );

# check arguments
if ( !$Opts{'d'} ) {
    $Opts{'h'} = 1;
}
if ( $Opts{'h'} ) {
    print STDOUT "ConfigureMySQL.pl <Revision $VERSION> - script to configure MySQL\n";
    print STDOUT "Copyright (C) 2001-2008 OTRS AG, http://otrs.org/\n";
    print STDOUT "usage: ConfigureMySQL.pl -d <install directory>\n\n";
    exit 1;
}

# check the given install directory
my $InstallDir = $Opts{'d'};
if ( !-e $InstallDir || !-d $InstallDir ) {
    print STDERR "Invalid install directory!\n\n";
    exit 1;
}

# check the MySQL directory
my $MySQLDir = $InstallDir . '\MySQL';
if ( !-e $MySQLDir || !-d $MySQLDir ) {
    print STDERR "Invalid MySQL directory!\n\n";
    exit 1;
}

# quoate the install directory
my $InstallDirQuoated = $InstallDir;
$InstallDirQuoated =~ s{\\}{/}xmsg;

# quoate the MySQL directory
my $MySQLDirQuoated = $MySQLDir;
$MySQLDirQuoated =~ s{\\}{/}xmsg;

# set required parameters in my.ini
PrepareMyIni();

# config the OTRS server start and restart scripts
ConfigOTRSServiceStart();

# config the OTRS server stop and restart scripts
ConfigOTRSServiceStop();

1;

sub PrepareMyIni {

    my $File = $MySQLDirQuoated . '/my.ini';

    # check if file exists
    return if !-e $File;

    # check if file is a directory
    return if -d $File;

    # check if file is writeable
    return if !-w $File;

    # check if file is a link
    return if -l $File;

    # check if file is a text file
    return if !-T $File;

    # read file
    return if !open my $FH1, '<', $File;
    my $OrgString = do { local $/; <$FH1> };
    close $FH1;

    # copy the string
    my $NewString = $OrgString;

    # insert basedir
    $NewString =~ s{ \[mysqld\] }{[mysqld]\nbasedir = $MySQLDirQuoated}xms;

    # increase max_allowed_packet
    $NewString =~ s{ max_allowed_packet \s* = \s* \d M }{max_allowed_packet = 20M}xmsg;

    # return if no changes
    return 1 if $OrgString eq $NewString;

    # write new file
    return if !open my $FH2, '>', $File;
    print $FH2 $NewString;
    close $FH2;

    return 1;
}

sub ConfigOTRSServiceStart {

    FILE:
    for my $FileName (qw(OTRSServicesStart.bat OTRSServicesRestart.bat)) {

        # add install directory
        my $File = $InstallDirQuoated . '/otrs4win/Scripts/' . $FileName;

        # check if file exists
        next FILE if !-e $File;

        # check if file is a directory
        next FILE if -d $File;

        # check if file is writeable
        next FILE if !-w $File;

        # check if file is a link
        next FILE if -l $File;

        # check if file is a text file
        next FILE if !-T $File;

        # read file
        next FILE if !open my $FH1, '<', $File;
        my $OrgString = do { local $/; <$FH1> };
        close $FH1;

        # copy the string
        my $NewString = $OrgString;

        my $StartConfig = "REM Start MySQL service
NET START MySQL";

        # add the mysql start part
        $NewString =~ s{ ^ REM \s ---MySQLStartPart--- }{$StartConfig}xmsg;

        # next file if no changes
        next FILE if $OrgString eq $NewString;

        # write new file
        return if !open my $FH2, '>', $File;
        print $FH2 $NewString;
        close $FH2;

        print STDERR "Replaced string 'REM ---MySQLStartPart---' in $File\n";
    }
}

sub ConfigOTRSServiceStop {

    FILE:
    for my $FileName (qw(OTRSServicesStop.bat OTRSServicesRestart.bat)) {

        # add install directory
        my $File = $InstallDirQuoated . '/otrs4win/Scripts/' . $FileName;

        # check if file exists
        next FILE if !-e $File;

        # check if file is a directory
        next FILE if -d $File;

        # check if file is writeable
        next FILE if !-w $File;

        # check if file is a link
        next FILE if -l $File;

        # check if file is a text file
        next FILE if !-T $File;

        # read file
        next FILE if !open my $FH1, '<', $File;
        my $OrgString = do { local $/; <$FH1> };
        close $FH1;

        # copy the string
        my $NewString = $OrgString;

        my $StopConfig = "REM Stop MySQL service
NET STOP MySQL";

        # add the mysql stop part
        $NewString =~ s{ ^ REM \s ---MySQLStopPart--- }{$StopConfig}xmsg;

        # next file if no changes
        next FILE if $OrgString eq $NewString;

        # write new file
        return if !open my $FH2, '>', $File;
        print $FH2 $NewString;
        close $FH2;

        print STDERR "Replaced string 'REM ---MySQLStopPart---' in $File\n";
    }
}

exit 0;