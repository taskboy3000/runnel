use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Carp;

use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

chdir $FindBin::Bin;    # needs to be in t for the yml catalog path
$ENV{ RUNNEL_YML } = "$FindBin::Bin/runnel-test.yml";
ok( -e $ENV{ RUNNEL_YML }, "Test configuration is present" );

my $t = Test::Mojo->new( 'Runnel' );

subtest 'homepage' => sub {
    $t->get_ok( '/' )->status_is( 200 )
        ->content_like( qr!<title>Runnel</title>! );
};

subtest 'song search via controller' => sub {
    $t->get_ok( '/songs/search?q=A' )->status_is( 200 );
};

subtest 'playlists show current' => sub {
    $t->get_ok( '/playlists/current' )->status_is( 200 );
};

subtest 'playlists clear' => sub {
    $t->post_ok( '/playlists/current/clear' )->status_is( 302 );
};

subtest 'playlists add by path' => sub {
    $t->get_ok( '/playlists/current/add?path=test.mp3' )->status_is( 302 );
};

subtest 'playlists add by artist' => sub {
    $t->get_ok( '/playlists/current/add/artist?name=A' )->status_is( 302 );
};

subtest 'playlists add by album' => sub {
    $t->get_ok( '/playlists/current/add/album?name=Test' )->status_is( 302 );
};

subtest 'playlists random' => sub {
    $t->get_ok( '/playlists/random?limit=5' )->status_is( 302 );
};

subtest 'services are lazy singletons' => sub {
    my $app = $t->app;
    ok( $app->song_search,      "song_search service exists" );
    ok( $app->playlist_manager, "playlist_manager service exists" );
    is( $app->song_search, $app->song_search, "same song_search instance" );
    is( $app->playlist_manager, $app->playlist_manager,
        "same playlist_manager instance" );
};

done_testing();
