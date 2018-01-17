use strict;
use warnings;

use Test::More;
use Test::Trap;
use Path::Tiny;
use Capture::Tiny qw(capture);

BEGIN { sub _test_wrapper };    # for syntactic sugarness

my $gitbin = '/usr/bin/git';
if ( !-x $gitbin ) {
    plan skip_all => "$gitbin required for these tests";
}
else {
    plan tests => 57;
}

use File::Temp;
use Cwd;

use Git::Repository qw(Dirty);

diag("Testing Git::Repository::Plugin::Dirty $Git::Repository::Plugin::Dirty::VERSION");
ok( exists $INC{'Git/Repository/Plugin/Dirty.pm'}, "Dirty loaded as plugin" );

my $starting_dir = cwd();

_test_wrapper "current_branch()" => sub {
    my ( $git, $dir, $name ) = @_;
    is( $git->current_branch(), "master", "current_branch() returns current branch of initiated object" );
    capture { $git->run( "checkout", "-b", "ohhai-$$" ) };
    is( $git->current_branch(), "ohhai-$$", "current_branch() returns current branch after changing branch" );
};

_test_wrapper "clean repo" => sub {
    my ( $git, $dir, $name ) = @_;

    ok( !$git->is_dirty(), "$name: is_dirty() returns false" );
    ok( !$git->is_dirty( { untracked => 1 } ), "$name: is_dirty({untracked => 1}) returns false" );
    is_deeply( [ $git->has_untracked() ], [], "$name: has_untracked() returns empty list" );
    ok( !$git->has_unstaged_changes(), "$name: has_unstaged_changes() returns false" );
    ok( !$git->has_staged_changes(),   "$name: has_staged_changes() returns false" );
    is_deeply( [ $git->diff_unstaged() ], [], "$name: diff_unstaged() returns empty list" );
    is_deeply( [ $git->diff_staged() ],   [], "$name: diff_staged() returns empty list" );

    my @lines;
    $git->diff_unstaged( sub { my ( $git, $line ) = @_; push @lines, "$git$line" } );
    is_deeply( \@lines, [], "$name: diff_unstaged(\$handler) handler processes each line" );
    @lines = ();
    $git->diff_staged( sub { my ( $git, $line ) = @_; push @lines, "$git$line" } );
    is_deeply( \@lines, [], "$name: diff_staged(\$handler) handler processes each line" );
};

_test_wrapper "unstaged changes" => sub {
    my ( $git, $dir, $name ) = @_;
    path('baz/file')->spew("updated");

    ok( $git->is_dirty(), "$name: is_dirty() returns true" );
    ok( $git->is_dirty( { untracked => 1 } ), "$name: is_dirty({untracked => 1}) returns true" );
    is_deeply( [ $git->has_untracked() ], [], "$name: has_untracked() returns empty list" );
    ok( $git->has_unstaged_changes(),        "$name: has_unstaged_changes() returns true" );
    ok( !$git->has_staged_changes(),         "$name: has_staged_changes() returns false" );
    ok( scalar( $git->diff_unstaged() ) > 0, "$name: diff_unstaged() returns diff lines as list" );
    is_deeply( [ $git->diff_staged() ], [], "$name: diff_staged() returns diff lines as list" );

    my @lines;
    $git->diff_unstaged( sub { my ( $git, $line ) = @_; push @lines, "$git$line" } );
    ok( scalar(@lines) > 0, "$name: diff_unstaged(\$handler) handler processes each line" );
    @lines = ();
    $git->diff_staged( sub { my ( $git, $line ) = @_; push @lines, "$git$line" } );
    is_deeply( \@lines, [], "$name: diff_staged(\$handler) handler processes each line" );
};

_test_wrapper "staged changes" => sub {
    my ( $git, $dir, $name ) = @_;
    path('foo/file')->spew("updated");
    $git->run( "add", 'foo/file' );

    ok( $git->is_dirty(), "$name: is_dirty() returns true" );
    ok( $git->is_dirty( { untracked => 1 } ), "$name: is_dirty({untracked => 1}) returns true" );
    is_deeply( [ $git->has_untracked() ], [], "$name: has_untracked() returns empty list" );
    ok( !$git->has_unstaged_changes(), "$name: has_unstaged_changes() returns true" );
    ok( $git->has_staged_changes(),    "$name: has_staged_changes() returns false" );
    is_deeply( [ $git->diff_unstaged() ], [], "$name: diff_unstaged() returns empty list" );
    ok( scalar( $git->diff_staged() ) > 0, "$name: diff_staged() returns diff lines as list" );

    my @lines;
    $git->diff_unstaged( sub { my ( $git, $line ) = @_; push @lines, "$git$line" } );
    is_deeply( \@lines, [], "$name: diff_unstaged(\$handler) handler processes each line" );
    @lines = ();
    $git->diff_staged( sub { my ( $git, $line ) = @_; push @lines, "$git$line" } );
    ok( scalar(@lines) > 0, "$name: diff_staged(\$handler) handler processes each line" );
};

_test_wrapper "untracked files" => sub {
    my ( $git, $dir, $name ) = @_;
    path('foo/new')->spew("new file");

    ok( !$git->is_dirty(), "$name: is_dirty() returns false" );
    ok( $git->is_dirty( { untracked => 1 } ), "$name: is_dirty({untracked => 1}) returns true" );
    is_deeply( [ $git->has_untracked() ], ['foo/new'], "$name: has_untracked() returns list" );
    ok( !$git->has_unstaged_changes(), "$name: has_unstaged_changes() returns false" );
    ok( !$git->has_staged_changes(),   "$name: has_staged_changes() returns false" );
    is_deeply( [ $git->diff_unstaged() ], [], "$name: diff_unstaged() returns empty list" );
    is_deeply( [ $git->diff_staged() ],   [], "$name: diff_staged() returns empty list" );

    my @lines;
    $git->diff_unstaged( sub { my ( $git, $line ) = @_; push @lines, "$git$line" } );
    is_deeply( \@lines, [], "$name: diff_unstaged(\$handler) handler processes each line" );
    @lines = ();
    $git->diff_staged( sub { my ( $git, $line ) = @_; push @lines, "$git$line" } );
    is_deeply( \@lines, [], "$name: diff_staged(\$handler) handler processes each line" );
};

_test_wrapper "unstaged changes && staged changes" => sub {
    my ( $git, $dir, $name ) = @_;
    path('baz/file')->spew("updated");
    path('foo/file')->spew("updated");
    $git->run( "add", 'foo/file' );

    ok( $git->is_dirty(), "$name: is_dirty() returns true" );
    ok( $git->is_dirty( { untracked => 1 } ), "$name: is_dirty({untracked => 1}) returns true" );
    is_deeply( [ $git->has_untracked() ], [], "$name: has_untracked() returns empty list" );
    ok( $git->has_unstaged_changes(),        "$name: has_unstaged_changes() returns true" );
    ok( $git->has_staged_changes(),          "$name: has_staged_changes() returns true" );
    ok( scalar( $git->diff_unstaged() ) > 0, "$name: diff_unstaged() returns diff lines as list" );
    ok( scalar( $git->diff_staged() ) > 0,   "$name: diff_staged() returns diff lines as list" );

    my @lines;
    $git->diff_unstaged( sub { my ( $git, $line ) = @_; push @lines, "$git$line" } );
    ok( scalar(@lines) > 0, "$name: diff_unstaged(\$handler) handler processes each line" );
    @lines = ();
    $git->diff_staged( sub { my ( $git, $line ) = @_; push @lines, "$git$line" } );
    ok( scalar(@lines) > 0, "$name: diff_staged(\$handler) handler processes each line" );
};

_test_wrapper "unstaged changes && staged changes && untracked files" => sub {
    my ( $git, $dir, $name ) = @_;
    path('baz/file')->spew("updated");
    path('foo/file')->spew("updated");
    $git->run( "add", 'foo/file' );
    path('foo/new')->spew("new file");

    ok( $git->is_dirty(), "$name: is_dirty() returns true" );
    ok( $git->is_dirty( { untracked => 1 } ), "$name: is_dirty({untracked => 1}) returns true" );
    is_deeply( [ $git->has_untracked() ], ['foo/new'], "$name: has_untracked() returns list" );
    ok( $git->has_unstaged_changes(),        "$name: has_unstaged_changes() returns true" );
    ok( $git->has_staged_changes(),          "$name: has_staged_changes() returns true" );
    ok( scalar( $git->diff_unstaged() ) > 0, "$name: diff_unstaged() returns diff lines as list" );
    ok( scalar( $git->diff_staged() ) > 0,   "$name: diff_staged() returns diff lines as list" );

    my @lines;
    $git->diff_unstaged( sub { my ( $git, $line ) = @_; push @lines, "$git$line" } );
    ok( scalar(@lines) > 0, "$name: diff_unstaged(\$handler) handler processes each line" );
    @lines = ();
    $git->diff_staged( sub { my ( $git, $line ) = @_; push @lines, "$git$line" } );
    ok( scalar(@lines) > 0, "$name: diff_staged(\$handler) handler processes each line" );
};

###############
#### helpers ##
###############

sub _test_wrapper {
    my ( $note, $code ) = @_;

    note $note;

    my $dir = _setup_clean_repo();
    my $git = Git::Repository->new( { fatal => ["!0"] } );

    $code->( $git, $dir, $note );

    chdir $starting_dir || die "could not chdir back to starting dir ($starting_dir): $!\n";

    return;
}

sub _setup_clean_repo {
    my $dir = File::Temp->newdir;
    chdir $dir || die "could not chdir to temp dir ($dir): $!\n";

    for my $pth (qw(foo foo/bar baz baz/wop)) {
        mkdir $pth || die "Could not mkdir $pth: $!\n";
        path("$pth/file")->spew("$$: $pth/file");
    }

    capture {
        trap {
            system( $gitbin, "init", "." ) && die "Could not init: $?\n";
            system( $gitbin, "add",  "." ) && die "Could not add: $?\n";
            system( $gitbin, "commit", "-m", "init" ) && die "Could not commit: $?\n";
        };
        die( $trap->die ) if $trap->die;
    };

    return $dir;
}
