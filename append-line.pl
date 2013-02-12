#!/usr/bin/perl
#
# append-line.pl -- append a line to the beginning of a file
#
use strict;
use warnings;
use Carp;
use Getopt::Long;
require 5.004;

my %option = ();
GetOptions(\%option,'source=s', 'text=s');

die "$0: no source file defined" unless defined $option{source};
die "$0: no append text defined" unless defined $option{text};

{
    local @ARGV = ($option{source});
    local $^I = '.bak';
    while(<>){
        if ($. == 1) {
            print qq($option{text}) . "$/";
            print;
        }
        else {
            print;
        }
    }
}
