#!/usr/bin/perl -w
#
# svn-files-since.pl -- aggregate all files (added, modified, changed) in the specified
# revision range.
#

use strict;
use XML::Simple;
use Data::Dumper;

if ((scalar(@ARGV) == 0)
    or ($ARGV[0] eq '-?')
    or ($ARGV[0] eq '-h')
    or ($ARGV[0] eq '--help')) {
    print <<EOF;
Show the log message and diff for a revision.
usage: $0 REVISION [WC_PATH|URL]
EOF
    exit 0;
}

my $revision = shift || die ("Revision argument required.\n");
if ($revision =~ /r([0-9]+)/) {
  $revision = $1;
}

my $url = shift || "";

my $svn = "svn";

my $prev_revision = $revision - 1;

if (not $url) {
  # If no URL was provided, use the repository root from the current
  # directory's working copy.  We want the root, rather than the URL
  # of the current dir, because when someone's asking for a change
  # by name (that is, by revision number), they generally don't want
  # to have to cd to a particular working copy directory to get it.
  my @info_lines = `${svn} info`;
  foreach my $info_line (@info_lines) {
    if ($info_line =~ s/^Repository Root: (.*)$/$1/e) {
      $url = $info_line;
    }
  }
}

my $xmlLog = `${svn} log -v --xml -r${revision}:HEAD $url`;
my $xs = XML::Simple->new();
my $ref = $xs->XMLin($xmlLog);
my %alteredFiles = ();

#print Dumper($ref);

foreach my $rev (@{$ref->{'logentry'}}) {
#    print "revision: " . $rev->{'revision'} . "\n";
    foreach my $path ($rev->{'paths'}) {
        if (ref($path->{'path'}) eq 'ARRAY') {
            foreach my $p (@{$path->{'path'}}) {
                if ($p->{'kind'} eq 'file') {
                    my $fn = $p->{'content'};
                    if ($fn =~ /\.([ch]|cpp|hpp|cc)$/) {
                        $alteredFiles{$fn} = 1;
                    }
                }
            }
        } else {
            if ($path->{'path'}->{'kind'} eq 'file') {
                my $fn = $path->{'path'}->{'content'};
                if ($fn =~ /\.([ch]|cpp|hpp|cc)$/) {
                    $alteredFiles{$fn} = 1;
                }
            }
        }
    }
}

for my $key (sort keys %alteredFiles) {
    print $key . "\n";
}
