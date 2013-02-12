#!/usr/bin/perl -w
# Generate an instruction concordance with each instruction having a context in a
# function.
# usually called with something like this:
#    findins.pl `find . -name "*.o"`

use strict;

# use objdump to find the symbols and instuctions
my($saved_delim) = $/;
undef $/;
my($syms) = `objdump -d @ARGV`;
$/ = $saved_delim;

my(@lines) = split(/\n/s, $syms);
my $current_function;
my %instructions = ();
my $state;

# parse the symbols
$state = 0;
for (my($i)=0; $i <= $#lines; $i++) {
    my($line) = $lines[$i];
    if ($state == 0 && $line =~ /\p{PosixXDigit}{16} <([^>]*)>/) {
        $current_function = $1;
        $state = 1;
    } elsif ($line eq "") {
        $state = 0;
    } elsif ($state == 1) {
        my @instruction = split(/\t/, $line);
        my $current_instruction;
        if ($#instruction >= 2) {
            my @ins_parts = split(/ /, $instruction[2]);
            if ($#ins_parts > 1) {
                for (my ($j)=0; $j <= $#ins_parts && !defined $current_instruction; $j++) {
                    if ($ins_parts[$j] !~ /^data[0-9]+/) {
                        $current_instruction = $ins_parts[$j];
                    }
                }
            } else {
                $current_instruction = $ins_parts[0];
            }
        }
        if (defined $current_instruction) {
            if (!exists $instructions{$current_instruction}) {
                $instructions{$current_instruction} = ();
            }
            $instructions{$current_instruction}{$current_function} = 1;
        }
    }
}

foreach my $key (sort keys %instructions) {
    print "$key\t";
    my @sorted_func = sort(keys(%{$instructions{$key}}));

    for my $f (0..$#sorted_func) {
        print $sorted_func[$f];
        print ' ' unless $f == $#sorted_func;
    }
    print "\n";
}
