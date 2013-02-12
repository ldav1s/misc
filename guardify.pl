#!/usr/bin/perl
#
# guardify.pl -- concoct unique guard macros using the file name and uuidgen
#
use strict;
use Carp;
use Getopt::Long;
require 5.004;
use POSIX qw(locale_h);

my %option = ();
GetOptions(\%option,'source=s', 'c99', 'c89', 'cxx');
my $significantChars;
$significantChars = 31 if defined $option{c89};
$significantChars = 63 if defined $option{c99};
$significantChars = 63 if defined $option{cxx};
$significantChars = 63 unless defined $significantChars;

die "$0: no source file defined" unless defined $option{source};
die "$0: cannot operate on `$option{source}'" unless (-w "$option{source}");

my $srcbase = `basename "$option{source}"`;
chomp($srcbase);
my $junk = `uuidgen -r | tr [a-f-] [A-F_]`;
chomp($junk);

my $newname;

# This is clunky...
if (defined $option{c99} || defined $option{cxx}) {
    use locale;

    $srcbase = uc $srcbase;
    $srcbase =~ s/\W/_/g;
    my $fc = substr($srcbase, 0, 1);
    $srcbase = "X" . $srcbase if $fc =~ m/\d/;
    $newname = substr($srcbase . "_" . $junk, 0, $significantChars);
} else {
    no locale;

    $srcbase = uc $srcbase;
    $srcbase =~ s/\W/_/g;
    my $fc = substr($srcbase, 0, 1);
    $srcbase = "X" . $srcbase if $fc =~ m/\d/;
    $newname = substr($srcbase . "_" . $junk, 0, $significantChars);
}

# Slurp...
open(FH, "<$option{source}") or die "$0: could not read `$option{source}'";
my @lines = <FH>;
close(FH);

# Burp...
open(my $fh, ">$option{source}") or die "$0: could not write `$option{source}'";
print $fh "#ifndef $newname\n";
print $fh "#define $newname\n";
print $fh @lines;
print $fh "#endif\n";
