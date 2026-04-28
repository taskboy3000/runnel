use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../lib";

use Test::More;
use Test::Exception;

use Runnel::Catalog;
use Runnel::Playlist;
use Runnel::Service::PlaylistManager;

my $testDir    = "$FindBin::Bin/..";
my $catalogDir = "$testDir/fake_catalog";

my $catalog = Runnel::Catalog->new();
$catalog->find_songs( $catalogDir );
my $playlist = Runnel::Playlist->new;

subtest 'constructor validation' => sub {
    dies_ok( sub { Runnel::Service::PlaylistManager->new() },
        "dies without catalog" );
    dies_ok(
        sub {
            Runnel::Service::PlaylistManager->new( catalog => $catalog );
        },
        "dies without playlist"
    );
    dies_ok(
        sub {
            Runnel::Service::PlaylistManager->new(
                catalog  => $catalog,
                playlist => $playlist,
                logger      => 1
            );
        },
        "dies when logger is not a code ref"
    );
};

subtest 'add_by_path with valid song' => sub {
    my $svc = Runnel::Service::PlaylistManager->new(
        catalog  => $catalog,
        playlist => $playlist,
        logger      => sub { },
    );

    my $song = $catalog->songs->[ 0 ];
    my $path = $song->{ info }{ partialPath };

    my $result = $svc->add_by_path( $path );
    ok( defined $result, "add_by_path returns defined" );
    is( ref $result, 'HASH', "add_by_path returns hash" );
    ok( exists $result->{ success }, "result has success key" );
    ok( $result->{ success }, "add was successful" ) if $result->{ success };
};

subtest 'add_by_path with invalid path' => sub {
    my $svc = Runnel::Service::PlaylistManager->new(
        catalog  => $catalog,
        playlist => $playlist,
        logger      => sub { },
    );

    dies_ok(
        sub { $svc->add_by_path( 'nonexistent/path.mp3' ) },
        "add_by_path throws when song not found"
    );
};

subtest 'remove_by_path with invalid path' => sub {
    my $svc = Runnel::Service::PlaylistManager->new(
        catalog  => $catalog,
        playlist => $playlist,
        logger      => sub { },
    );

    dies_ok(
        sub { $svc->remove_by_path( 'nonexistent/path.mp3' ) },
        "remove_by_path throws when song not found"
    );
};

subtest 'add_by_artist' => sub {
    my $svc = Runnel::Service::PlaylistManager->new(
        catalog  => $catalog,
        playlist => $playlist,
        logger      => sub { },
    );

    my $result = $svc->add_by_artist( 'A' );
    ok( defined $result, "add_by_artist returns defined" );
    is( ref $result, 'HASH', "add_by_artist returns hash" );
    ok( exists $result->{ added }, "result has added key" );
    ok( exists $result->{ msg },   "result has msg key" );
};

subtest 'add_by_album' => sub {
    my $svc = Runnel::Service::PlaylistManager->new(
        catalog  => $catalog,
        playlist => $playlist,
        logger      => sub { },
    );

    my $result = $svc->add_by_album( 'Test Album' );
    ok( defined $result, "add_by_album returns defined" );
    is( ref $result, 'HASH', "add_by_album returns hash" );
    ok( exists $result->{ added }, "result has added key" );
    ok( exists $result->{ msg },   "result has msg key" );
};

subtest 'add_by_genre' => sub {
    my $svc = Runnel::Service::PlaylistManager->new(
        catalog  => $catalog,
        playlist => $playlist,
        logger      => sub { },
    );

    my $result = $svc->add_by_genre( 'Genre' );
    ok( defined $result, "add_by_genre returns defined" );
    is( ref $result, 'HASH', "add_by_genre returns hash" );
    ok( exists $result->{ added }, "result has added key" );
    ok( exists $result->{ msg },   "result has msg key" );
};

subtest 'add_random' => sub {
    my $svc = Runnel::Service::PlaylistManager->new(
        catalog  => $catalog,
        playlist => $playlist,
        logger      => sub { },
    );

    my $result = $svc->add_random( 5 );
    ok( defined $result, "add_random returns defined" );
    is( ref $result, 'HASH', "add_random returns hash" );
    ok( exists $result->{ added }, "result has added key" );
};

subtest 'clear_all' => sub {
    my $svc = Runnel::Service::PlaylistManager->new(
        catalog  => $catalog,
        playlist => $playlist,
        logger      => sub { },
    );

    my $result = $svc->clear_all;
    ok( defined $result, "clear_all returns defined" );
    is( ref $result, 'HASH', "clear_all returns hash" );
    ok( exists $result->{ success }, "result has success key" );
};

done_testing();
