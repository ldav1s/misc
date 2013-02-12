#!/usr/bin/perl
#
# ccmap.pl -- map areas of conditional compilation in a .c file
#
# Usage: ccmap.pl <.c|.h file>
#
use strict;
use Carp;
use Getopt::Long;

my %option = ();
GetOptions(\%option,'verbose');

my $c_filename = shift;
my @stack = ();

open(FH, "<$c_filename") or die "$0: could not read `$c_filename'";
my $lc = 1;
my $depth = 0;
my $total_d0 = 0;
my $cond_count = 0;
my $nested_count = 0;
my $deepest = 0;
while (<FH>) {
    my $line = $_;
    my $cond;
    if ($line =~ m/^(\s*\x23\s*(?:if|ifdef|ifndef))(.*)/) {
        for (my $i = 0; $i < ($depth + 1); ++$i) {
            print "+" if defined $option{verbose};
        }
        $cond = fixup_cond($2);
        print "line $lc, startif: $cond\n" if defined $option{verbose};
        push @stack,$lc;
        ++$depth;
        ++$cond_count;
        if ($depth > 1) {
            ++$nested_count;
        }
        $deepest = ($depth > $deepest) ? $depth : $deepest;
    } elsif ($line =~ m/^(\s*\x23\s*elif)(.*)/) {
        for (my $i = 0; $i < $depth; ++$i) {
            print "+" if defined $option{verbose};
        }
        $cond = fixup_cond($2);
        print "line $lc, elif: $cond\n" if defined $option{verbose};
    } elsif ($line =~ m/^(\s*\x23\s*else)(.*)/) {
        for (my $i = 0; $i < $depth; ++$i) {
            print "+" if defined $option{verbose};
        }
        print "line $lc, else\n" if defined $option{verbose};
    } elsif ($line =~ m/^(\s*\x23\s*endif)(.*)/) {
        for (my $i = 0; $i < $depth; ++$i) {
            print "+" if defined $option{verbose};
        }
        print "line $lc, endif\n" if defined $option{verbose};
        my $start_line = pop @stack;
        if ($depth == 1) {
            my $size = ($lc - $start_line);
            print "-lines: $size\n" if defined $option{verbose};
            $total_d0 += $size;
        }
        --$depth;
    }
    ++$lc;
}

if (defined $option{verbose}) {
    printf("=%s: total lines %d, depth0 %d, %g%%\n", $c_filename, $lc, $total_d0, (($total_d0/$lc) * 100.0));
} else {
    printf("%s: LineRatio %g%%, CondCount: %d, NestedPercent: %g%%, Deepest: %d\n",
           $c_filename, (($lc == 0) ? 0.0 : (($total_d0/$lc) * 100.0)),
           $cond_count, (($cond_count == 0) ? 0.0 : (($nested_count/$cond_count)*100.0)), $deepest);
}
sub usage
{
  warn "@_\n" if @_;
  die "usage: $0 <.{ch} file>\n";
}

sub fixup_cond
{
    my ($cond) = @_;
    $cond =~ s:\/\/.*$::; # remove // comments
    $cond =~ s:\/\*.*\*\/::g; # remove /*...*/ comments
    return $cond;
}

