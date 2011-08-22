#!/usr/bin/env perl

use strict;
use warnings;

use Pod::Find qw(pod_find);
use Getopt::Long;

my $opts = {};

if ( defined $ENV{TCSHDIR} && -d $ENV{TCSHDIR} . '/etc' ) {
    $opts->{podlist} = $ENV{TCSHDIR} . '/etc/podlist.txt';
} else {
    $opts->{podlist} = '/tmp/podlist.txt';
}

$opts->{perl}    = 1;
$opts->{inc}     = 1;

GetOptions( $opts,
                    'podlist=s',
                    'xargs',
                    '0',

                    # Pod::Find options
                    #
                    'dirs=s@{,}',
                    'verbose',
                    'perl',
                    'inc',
);

my %pf_options;
my $directories = [];

my $joiner = 
    defined $opts->{0}
    ? "\000"
    : "\n";

# Both --dirs and regular ARGV options will be treated as
# directory names.  Only valid, readable directories will be
# passed to Pod::Find.
#
for ( @{ $opts->{dirs} } ) {
    push @$directories, $_ if -d $_ and -r $_;
}

if ( scalar @ARGV > 0 ) {
    for (@ARGV) {
        push @$directories, $_ if -d $_ and -r $_;
    }
}

if ( scalar @$directories ) {
    $pf_options{'-dirs'} = $directories;
} else {
    $pf_options{'-inc'} = $opts->{inc};
}

$pf_options{'-verbose'} = $opts->{verbose};
$pf_options{'-perl'}    = $opts->{perl};

# Squash the stderr duplicate warnings from Pod::Find
#
open STDERR, '>', '/dev/null';
my %bypath = pod_find({%pf_options});

for ( keys %bypath ) {

    delete $bypath{$_} if $bypath{$_} =~ m/^[.]/;

}

close STDERR;

if ( defined $opts->{xargs} ) {
    
    print join( $joiner, sort keys %bypath );

} else {

    my %byname = reverse %bypath;

    open my $fh, '>', $opts->{podlist}
        or die "Unable to open podlist file: $opts->{podlist} $!";

    select( $fh );

    print join( $joiner, sort keys %byname);


    close $fh;

}

