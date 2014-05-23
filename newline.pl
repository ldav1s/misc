#!/usr/bin/perl
#
# newline.pl -- check C sources for violation of section 2.1.1.2 of the ANSI C 1989 standard.
# Also in Section 5.1.1.2 of the ISO C 1999 standard
#
# Optionally fixes files and checks them into subversion.
#
use strict;
use Carp;
use Getopt::Long;
use Digest::MD5;
use SVN::Client;
use SVN::Core;
use SVN::Wc;
use Encode;

my %option = ();
GetOptions(\%option, 'update', 'commit');

my $ctx;

if (defined $option{commit} && $ARGV[0]) {
    my %svnClientOpts = ();
    $svnClientOpts{auth} = [SVN::Client::get_simple_provider(),
                            SVN::Client::get_simple_prompt_provider(\&simple_prompt,2),
                            SVN::Client::get_username_provider()];
    $ctx = new SVN::Client(%svnClientOpts);
    $ctx->log_msg(\&log_comments);
}

foreach (@ARGV) {
    my $source = $_;

    unless ((defined $option{update}) ? (-w "$source") : (-r "$source")) {
        carp "$0: cannot operate on `$source'";
        next;
    }

    my $srcfile = ((defined $option{update}) ? "+" : "") . "<$source";

    unless (open(FH, $srcfile)) {
        carp "$0: could not read `$source'";
        next;
    }

    my $fsize;
    (undef , undef, undef, undef, undef, undef , undef, $fsize) = stat FH;

    # empty files need not end with a newline
    next if ($fsize == 0);

    unless (seek(FH, -1,2)) {
        carp "$0: could not seek to the end of `$source'";
        close(FH);
        next;
    }

    my $b;

    unless (read(FH, $b, 1)) {
        carp "$0: could not read at EOF `$source'";
        close(FH);
        next;
    }

    unless ($b eq "\n") {
        if (defined $option{update}) {
            unless (seek(FH, 0,2)) {
                carp "$0: could not seek to EOF `$source'";
                close(FH);
                next;
            }
            print FH "\n";
            close(FH);

            if (defined $option{commit}) {
                my ($commit_val) = $ctx->commit(Encode::encode('utf8', $source), 0);

                if (!defined $commit_val || $commit_val->revision() == $SVN::Core::INVALID_REVNUM) {
                    croak "$0: svn commit failed `$source'";
                }
            }
        }
        print "$source\n";
    }
}

# callback for authentication
sub simple_prompt {
    my ($cred,$realm,$default_username,$may_save,$pool) = @_;

    print "Enter authentication info for realm: $realm\n";
    print "Username: ";
    my $username = <>;
    chomp($username);
    $cred->username($username);
    print "Password: ";
    my $password = <>;
    chomp($password);
    $cred->password($password);
}

# callback for comments
sub log_comments {
    my ($msg,$tmpFile,$commit_ary,$pool) = @_;
    $$msg = Encode::encode('utf8', "fixed violation of section 2.1.1.2 of the ANSI C 1989 standard");
}

# end of newline.pl
