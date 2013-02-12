#!/usr/bin/perl
use strict;
use warnings;

use File::Find;

my $SVN_DIR = '.svn';
my $SVN_PROG = "svn";

die "$0: usage: find_noprops.pl <working copy directory>"
    unless defined $ARGV[0] && -d "$ARGV[0]/$SVN_DIR";

find(
    {
        preprocess  => sub { grep { -f $_ || (-d $_ && -d "$_/$SVN_DIR") } grep(!/$SVN_DIR|\.\./, @_); },
        wanted      => sub { print $File::Find::name . "\n"
                                 if (-f $_) && (`$SVN_PROG proplist $_ 2>&1` eq "");},
    },
    $ARGV[0]
);
