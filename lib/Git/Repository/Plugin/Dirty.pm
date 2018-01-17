package Git::Repository::Plugin::Dirty;

use strict;
use warnings;

our $VERSION = '0.01';

use Git::Repository::Plugin;
our @ISA = qw( Git::Repository::Plugin );

sub _keywords { return qw( is_dirty has_untracked has_unstaged_changes has_staged_changes diff_unstaged diff_staged current_branch ) }

sub is_dirty {
    my ( $git, $opts ) = @_;
    return 1 if $git->has_staged_changes() || $git->has_unstaged_changes();
    return 1 if $opts->{untracked} && $git->has_untracked();
    return;
}

sub has_untracked {
    my ($git) = @_;
    my @untracked = map { my $l = $_; $l =~ s/^\?\? //; $l } grep { m/^\?\? / } $git->run( "status", "-u", "-s", "--porcelain" );
    return @untracked;
}

sub has_unstaged_changes {
    my ($git) = @_;
    eval { $git->run( "diff", "--quiet" ) };
    my $err  = $@;
    my $exit = $? >> 8;

    die $@ if $exit != 0 && $exit != 1;
    return if $exit == 0;
    return $exit;    # has to be 1 at this point (unless we break it above!!!)
}

sub has_staged_changes {
    my ($git) = @_;
    eval { $git->run( "diff", "--quiet", "--cached" ) };
    my $err  = $@;
    my $exit = $? >> 8;

    die $@ if $exit != 0 && $exit != 1;
    return if $exit == 0;
    return $exit;    # has to be 1 at this point (unless we break it above!!!)
}

sub diff_unstaged {
    my ( $git, $handler, $undocumented_cached_flag ) = @_;
    my @output;
    $handler ||= sub { my ( $self, $line ) = @_; push @output, $line; return 1; };

    my $diffcmd =
        $undocumented_cached_flag
      ? $git->command( 'diff', '--cached' )
      : $git->command('diff');
    my $diffout = $diffcmd->stdout;
    my $buffer;
    while ( $buffer = <$diffout> ) {
        last if !$handler->( $git, $buffer );
    }
    $diffcmd->close;

    return @output;
}

sub diff_staged {
    my ( $git, $handler ) = @_;
    @_ = ( $git, $handler, 1 );
    goto &diff_unstaged;
}

sub current_branch {
    my ($git) = @_;
    return $git->run(qw(rev-parse --abbrev-ref HEAD));
}

1;

__END__

=head1 NAME

Git::Repository::Plugin::Dirty - Methods to inspect the dirtyness of a git repository

=head1 VERSION

This document describes Git::Repository::Plugin::Dirty version 0.01

=head1 SYNOPSIS

    use Git::Repository qw(Dirty);

    my $git = Git::Repository->new( { fatal => ["!0"], quiet => ( $verbose ? 0 : 1 ), } );

    if ($git->is_dirty) {
        if ($force) {
            …
        }
        else {
            die "Repo is dirty. Please commit or stash any staged or unstaged changes and try again.\n";
        }
    }

=head1 DESCRIPTION

=for author to fill in:
    Write a full description of the module and its features here.
    Use subsections (=head2, =head3) as appropriate.


=head1 INTERFACE

=for author to fill in:
    Write a separate section listing the public components of the modules
    interface. These normally consist of either subroutines that may be
    exported, or methods that may be called on objects belonging to the
    classes provided by the module.


=head1 DIAGNOSTICS

=for author to fill in:
    List every single error and warning message that the module can
    generate (even the ones that will "never happen"), with a full
    explanation of each problem, one or more likely causes, and any
    suggested remedies.

=over

=item C<< Error message here, perhaps with %s placeholders >>

[Description of error here]

=item C<< Another error message here >>

[Description of error here]

[Et cetera, et cetera]

=back


=head1 CONFIGURATION AND ENVIRONMENT

=for author to fill in:
    A full explanation of any configuration system(s) used by the
    module, including the names and locations of any configuration
    files, and the meaning of any environment variables or properties
    that can be set. These descriptions must also include details of any
    configuration language used.

Git::Repository::Plugin::Dirty requires no configuration files or environment variables.


=head1 DEPENDENCIES

=for author to fill in:
    A list of all the other modules that this module relies upon,
    including any restrictions on versions, and an indication whether
    the module is part of the standard Perl distribution, part of the
    module's distribution, or must be installed separately. ]

None.


=head1 INCOMPATIBILITIES AND LIMITATIONS

=for author to fill in:
    A list of any modules that this module cannot be used in conjunction
    with. This may be due to name conflicts in the interface, or
    competition for system or program resources, or due to internal
    limitations of Perl (for example, many modules that use source code
    filters are mutually incompatible).

None reported.


=head1 BUGS AND FEATURES

Please report any bugs or feature requests (and a pull request for bonus points)
 through the issue tracker at L<https://github.com/drmuey/p5-Git-Repository-Plugin-Dirty/issues>.

=head1 AUTHOR

Daniel Muey  C<< <http://drmuey.com/cpan_contact.pl> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2018, Daniel Muey C<< <http://drmuey.com/cpan_contact.pl> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
