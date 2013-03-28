#!/usr/bin/perl -w
# --
# ConfigureApache.pl - script to configure the apache server
# Copyright (C) 2001-2012 OTRS AG, http://otrs.org/
# --
# $Id: ConfigureApache.pl,v 1.10 2012-11-20 19:18:21 mh Exp $
# --
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU AFFERO General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 USA
# or see http://www.gnu.org/licenses/agpl.txt.
# --

use strict;
use warnings;

use Getopt::Std;
use File::Find;

use vars qw($VERSION);
$VERSION = qw($Revision: 1.10 $) [1];

# get options
my %Opts = ();
getopt( 'd', \%Opts );

# check arguments
if ( !$Opts{'d'} ) {
    $Opts{'h'} = 1;
}
if ( $Opts{'h'} ) {
    print STDOUT "ConfigureApache.pl <Revision $VERSION> - script to configure the apache\n";
    print STDOUT "Copyright (C) 2001-2012 OTRS AG, http://otrs.org/\n";
    print STDOUT "usage: ConfigureApache.pl -d <install directory>\n\n";
    exit 1;
}

# check the given install directory
my $InstallDir = $Opts{'d'};
if ( !-e $InstallDir || !-d $InstallDir ) {
    print STDERR "Invalid install directory!\n\n";
    exit 1;
}

# check the apache directory
my $ApacheDir = $InstallDir . '\Apache';
if ( !-e $ApacheDir || !-d $ApacheDir ) {
    print STDERR "Invalid apache directory!\n\n";
    exit 1;
}

# quote the install directory
my $InstallDirQuoted = $InstallDir;
$InstallDirQuoted =~ s{\\}{/}xmsg;

# quote the apache directory
my $ApacheDirQuoted = $ApacheDir;
$ApacheDirQuoted =~ s{\\}{/}xmsg;

# replace C:/Apache with the install directory in all config files
find( \&ReplaceApacheDir, ($ApacheDir) );

# add OTRS configuration to the http.conf
OTRSApacheConfigAdd();

# config the OTRS server start and restart scripts
ConfigOTRSServiceStart();

# config the OTRS server stop and restart scripts
ConfigOTRSServiceStop();

1;

sub ReplaceApacheDir {

    # get filename

    my $File = $File::Find::name;

    # next file if no .conf file
    return if $File !~ m{ .+ \.conf \z }xms;

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

    # find and replace all C:/Apache
    $NewString =~ s{ C:\/Apache }{$ApacheDirQuoted}xmsg;

    # next file if no changes
    return 1 if $OrgString eq $NewString;

    # write new file
    return if !open my $FH2, '>', $File;
    print $FH2 $NewString;
    close $FH2;

    print STDERR "Replaced string C:/Apache in $File\n";

    return 1;
}

sub OTRSApacheConfigAdd {

    my $HttpdConf = $ApacheDir . '/conf/httpd.conf';

    # check if http.con exists
    return if !-e $HttpdConf;

    # check if file is writeable
    return if !-w $HttpdConf;

    my $OTRSConfig = "
# ---
# OTRS configuration
# ---

# load modules for otrs

LoadModule deflate_module modules/mod_deflate.so  
LoadModule headers_module modules/mod_headers.so  

LoadFile '$InstallDirQuoted/StrawberryPerl/perl/bin/perl512.dll'
LoadModule perl_module modules/mod_perl.so
LoadModule apreq_module modules/mod_apreq2.so

# include the OTRS configuration
Include '$InstallDirQuoted/OTRS/scripts/apache2-httpd.include.conf'

# redirect / to the Agent interface
# just use customer.pl if you want the Customer interface as default
RedirectMatch ^/\$ /otrs/index.pl

# ---
";

    # add config to the httpd.conf
    return if !open my $FH, '>>', $HttpdConf;
    print $FH $OTRSConfig;
    close $FH;

    return 1;
}

sub ConfigOTRSServiceStart {

    FILE:
    for my $FileName (qw(OTRSServicesStart.bat OTRSServicesRestart.bat)) {

        # add install directory
        my $File = $InstallDirQuoted . '/otrs4win/Scripts/' . $FileName;

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

        my $StartConfig = "REM Start Apache service
\"$ApacheDir\\bin\\httpd.exe\" -k start";

        # add the apache start part
        $NewString =~ s{ ^ REM \s ---ApacheStartPart--- }{$StartConfig}xmsg;

        # next file if no changes
        next FILE if $OrgString eq $NewString;

        # write new file
        return if !open my $FH2, '>', $File;
        print $FH2 $NewString;
        close $FH2;

        print STDERR "Replaced string 'REM ---ApacheStartPart---' in $File\n";
    }
}

sub ConfigOTRSServiceStop {

    FILE:
    for my $FileName (qw(OTRSServicesStop.bat OTRSServicesRestart.bat)) {

        # add install directory
        my $File = $InstallDirQuoted . '/otrs4win/Scripts/' . $FileName;

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

        my $StopConfig = "REM Stop Apache service
\"$ApacheDir\\bin\\httpd.exe\" -k stop";

        # add the apache stop part
        $NewString =~ s{ ^ REM \s ---ApacheStopPart--- }{$StopConfig}xmsg;

        # next file if no changes
        next FILE if $OrgString eq $NewString;

        # write new file
        return if !open my $FH2, '>', $File;
        print $FH2 $NewString;
        close $FH2;

        print STDERR "Replaced string 'REM ---ApacheStopPart---' in $File\n";
    }
}

exit 0;
