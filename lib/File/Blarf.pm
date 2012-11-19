package File::Blarf;
# ABSTRACT: Simple reading and writing of files

use warnings;
use strict;
use 5.008;

use Fcntl qw( :flock );

=head1 NAME

File::Blarf - Simple reading and writing of files.

=head1 SYNOPSIS

    use File::Blarf;

    my $foo = File::Blarf::slurp('/etc/passwd');

=func slurp

Read a whole file into a string.

=cut

sub slurp {
    my $file = shift;
    my $opts = shift || {};

    if ( -e $file && open( my $FH, '<', $file ) ) {
        flock( $FH, LOCK_SH ) if $opts->{Flock};
        my @lines = <$FH>;
        flock( $FH, LOCK_UN ) if $opts->{Flock};
        # DGR: we just read it, what could possibly go wrong?
        ## no critic (RequireCheckedClose)
        close($FH);
        ## use critic
        if (wantarray) {
            if ( $opts->{Chomp} ) {
                chomp(@lines);
            }
            return @lines;
        }
        else {
            my $out = join q{}, @lines;
            if ( $opts->{Chomp} ) {
                chomp($out);
            }
            return $out;
        }
    }
    else {
        return;
    }
}

=func blarf

Write a string into a file.

=cut

sub blarf {
    my $file = shift;
    my $str  = shift;
    my $opts = shift || {};

    my $mode = '>';
    if ( $opts->{Append} ) {
        $mode = '>>';
    }
    # DGR: due to flock and newlines we can't be anymore brief
    ## no critic (RequireBriefOpen)
    if ( open( my $FH, $mode, $file ) ) {
        flock( $FH, LOCK_EX ) if $opts->{Flock};
        if(!print $FH $str) {
            return;
        }
        if ( $opts->{'Newline'} ) {
            if(!print $FH "\n") {
                return;
            }
        }
        flock( $FH, LOCK_UN ) if $opts->{Flock};
        if(close($FH)) {
            return 1;
        }
    }
    ## use critic

    return;
}

=func cat

Append on file to another.

=cut
sub cat {
    my $source_file = shift;
    my $dest_file   = shift;
    my $opts        = shift || {};

    my $mode = '>';
    if ( $opts->{Append} ) {
        $mode = '>>';
    }
    # DGR: the files could be huge, so we MUST no read them into main memory
    ## no critic (RequireBriefOpen)
    if ( open( my $IN, '<', $source_file ) ) {
        flock( $IN, LOCK_SH ) if $opts->{Flock};
        my $status = 0;
        if ( open( my $OUT, $mode, $dest_file ) ) {
            flock( $OUT, LOCK_EX ) if $opts->{Flock};
            while ( my $line = <$IN> ) {
                if(!print $OUT $line) {
                    return;
                }
            }
            flock( $OUT, LOCK_UN ) if $opts->{Flock};
            if(close($OUT)) {
                $status = 1;
            }
        }
        flock( $IN, LOCK_UN ) if $opts->{Flock};
        # DGR: we were just reading ...
        ## no critic (RequireCheckedClose)
        close($IN);
        ## use critic
        if ($status) {
            return $status;
        }
    }
    ## use critic
    # something went wrong ...
    return;
}

=head1 SEE ALSO

=for :list
 * File::Slurp - L<File::Slurp> provides a more sophisticated implementation of much of the same functiality

=cut

1; # End of File::Blarf
