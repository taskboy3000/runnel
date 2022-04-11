package Runnel;
use Mojo::Base 'Mojolicious', -signatures;

use FindBin;
use Runnel::Catalog;
use Runnel::Playlist;

has 'catalog';
has 'playlist'  => sub { Runnel::Playlist->new };
has 'cachePath' => "$FindBin::Bin/../cache";

# This method will run once at server start
sub startup ( $self ) {

    # Load configuration from config file
    my $config = $self->plugin( 'NotYAMLConfig' );

    # Configure the application
    $self->secrets( $config->{ secrets } );
    $self->renderer->cache->max_keys( 0 );

    my $cachePath = "$FindBin::Bin/../cache";
    if (-d $cachePath) {
        $self->app->log->info("Cleaning out old files in $cachePath");
        unlink(glob("$cachePath/*"));
    } else {
        mkdir $cachePath;
    }

    push @{ $self->static->paths }, $cachePath;

    $self->defaults(layout => 'default');

    # Router
    my $r = $self->routes;

    # Normal route to controller
    $r->get( '/' )->to( 'songs#index' )->name( "songs_index" );

    # Static mp3 files from user-specified directory
    push @{ $self->static->paths }, $config->{ mp3BaseDirectory };
    $r->get(
        "/media/*song",
        sub ( $self ) {
            my $path = $self->param( "song" );
            $self->app->log->info( "Server media path: " . $path );

            $self->reply->static( $path );
        }
    );

    # Songs
    $r->get( '/songs' )->to( 'songs#index' )->name( "songs_index" );
    $r->get( '/songs/songs_table' )->to( 'songs#song_table' )
        ->name( "songs_table" );
    $r->get( '/songs/search' )->to( 'songs#search' )->name( 'songs_search' );

    # $r->get('/songs/:path')->to('songs#show')->name("songs_show");

    $r->get( '/playlists/current' )->to( 'playlists#show_current' )
        ->name( 'playlists_show_current' );
    $r->get( '/playlists/current/playlist_table' )
        ->to( 'playlists#playlist_table' )->name( 'playlists_table' );
    $r->get( '/playlists/current/add' )->to( 'playlists#add_to_current' )
        ->name( 'playlists_add_to_current' );
    $r->get( '/playlists/current/add/artist' )->to( 'playlists#add_artist' )
        ->name( 'playlists_add_artist' );
    $r->get( '/playlists/current/add/album' )->to( 'playlists#add_album' )
        ->name( 'playlists_add_album' );
    $r->get( '/playlists/current/add/genre' )->to( 'playlists#add_genre' )
        ->name( 'playlists_add_genre' );
    $r->get( '/playlists/current/remove' )
        ->to( 'playlists#remove_from_current' )
        ->name( 'playlists_remove_from_current' );
    $r->post( '/playlists/current/clear' )->to( 'playlists#clear_current' )
        ->name( 'playlists_clear_current' );

    $r->get( "/player" )->to( 'players#index' )->name( 'players_index' );

    if ( $config->{ mp3BaseDirectory } ) {

        # Aggressive...
        unlink glob( $self->cachePath . "/*" );

        my $cat = Runnel::Catalog->new(
            mp3BaseDirectory => $config->{ mp3BaseDirectory },
            app              => $self
        );
        $self->catalog( $cat );
        $self->app->log->info(
            "Scanning mp3 directory: " . $self->catalog->mp3BaseDirectory );
        $self->catalog->find_songs;
        $self->app->log->info( "Done." );
    }

}

1;
