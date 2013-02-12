#!/usr/bin/perl
#
# bin2string.pl -- encode a binary file as a C string
#
use strict;
use Carp;
use Getopt::Long;

use constant false => 0;
use constant true  => 1;

my %option = ();
GetOptions(\%option,'name=s', 'source=s');

die "$0: no variable name defined" unless defined $option{name};
die "$0: no source file defined" unless defined $option{source};

open(FH, "<$option{source}") or die "$0: could not read `$option{source}'";
binmode(FH);
binmode(STDOUT);

my $bin_size = (stat(FH))[7];
my $buff;
my $buff_size;
my $first_time = true;
print "const unsigned char " . $option{name} . "[" . $bin_size. "] = { \n";
while (($buff_size = read(FH, $buff, 8)) != 0) {
    if (!$first_time) {
        print ",\n";
    } else {
        $first_time = false;
    }
    print "    ";
    my @data = unpack("C*", $buff);
    for (my $i = 0; $i < @data; ++$i) {
        printf("'\\x%02x'%s", int($data[$i]), ($i < ($buff_size - 1)) ? ",": "");
    }
}
print "\n};\n";
close(FH);

# End of bin2string.pl
