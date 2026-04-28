package Runnel;
use Mojo::Base 'Mojolicious', -signatures;

use Runnel::Catalog;
use Runnel::Command::scan;
use Runnel::Playlist;
use Runnel::Service::SongSearch;
use Runnel::Service::PlaylistManager;

has 'catalog';
has 'playlist'  => sub { Runnel::Playlist->new };
has 'cachePath' => sub { shift->home->child('cache') };

has 'song_search' => sub {
    my $app     = shift;
    my $catalog = $app->catalog or die "catalog not set";
    Runnel::Service::SongSearch->new(
        catalog => $catalog,
        logger  => sub ( $level, $msg ) { $app->log->$level( $msg ) },
    );
};

has 'playlist_manager' => sub {
    my $app      = shift;
    my $catalog  = $app->catalog  or die "catalog not set";
    my $playlist = $app->playlist or die "playlist not set";
    Runnel::Service::PlaylistManager->new(
        catalog  => $catalog,
        playlist => $playlist,
        logger   => sub ( $level, $msg ) { $app->log->$level( $msg ) },
    );
};

# This method will run once at server start
sub startup ( $self ) {
    push @{$self->commands->namespaces}, 'Runnel::Command';

    # Load configuration from config file
    my $config_file = $ENV{ 'RUNNEL_YML' } || $self->home->child('runnel.yml');
    my $config = $self->plugin( 'NotYAMLConfig', { file => $config_file } );

    # Configure the application
    $self->secrets( $config->{ secrets } );
    $self->renderer->cache->max_keys( 0 );

    my $cachePath = $self->cachePath;
    if (! -d $cachePath ) {
        mkdir $cachePath;
    }

    push @{ $self->static->paths }, $cachePath;

    # $self->defaults(layout => 'default');

    # Router
    my $r = $self->routes;
    if ( $config->{ mp3BaseDirectory } ) {
        my $cat = Runnel::Catalog->new(
            mp3BaseDirectory => $config->{ mp3BaseDirectory },
            app              => $self
        );
        $self->catalog( $cat );
    }

    # Static mp3 files from user-specified directory
    push @{ $self->static->paths }, $config->{ mp3BaseDirectory };

    # Songs
    $r->get( '/' )->to( 'songs#index' )->name( "songs_index" );
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
    $r->get( '/playlists/random' )->to( 'playlists#random' )
        ->name( 'playlists_random' );
    $r->get( "/player" )->to( 'players#index' )->name( 'players_index' );
    $r->get(
        "/media/*song",
        sub ( $self ) {
            my $path = $self->param( "song" );
            $self->app->log->info( "Server media path: " . $path );

            $self->reply->static( $path );
        }
    );

    $self->hook(
        before_server_start => sub ($server, $app) {
            $self->log->debug("Booting...");
            $self->init_catalog();
        }
    )
}

sub init_catalog ($self) {
    return if $self->mode eq 'test';

    $ENV{RUNNEL_MANAGER} ||= $$;

    # Start scanning mp3 directory
    if ($self->is_manager) {
        my $runnel_script = $self->home->child('script', 'runnel');
        Mojo::IOLoop->subprocess->run_p(sub {
            system("perl $runnel_script scan");
        });
        # ->then(sub { sleep XXX; system....})
    }

    Mojo::IOLoop->recurring(15 => sub ($ioloop) {
        $self->reload_catalog_cache;
    });

    $self->reload_catalog_cache;
}

sub is_manager ($self) {
    return $ENV{RUNNEL_MANAGER} && $ENV{RUNNEL_MANAGER} eq $$;
}

sub catalog_scan($self, $catalogObject=undef) {
    my $catalog //= $self->catalog;
    die("assert") if !$catalog;

    $self->log->info(
            "mp3 directory: " . $self->catalog->mp3BaseDirectory );
    my $start = time();
    my $changed = $catalog->find_songs;
    $self->log->info(
            sprintf(
                "Scan took %d seconds; Found %d songs",
                ( time - $start ),
                scalar( @{ $catalog->songs } )
            )
    );
    if ($changed) {
        $self->log->info("Changes detected, saving catalog");
        $catalog->save;
    } else {
        $self->log->debug("No changes detected, skipping save");
    }
}

sub reload_catalog_cache ($self, $catalog = undef) {
    $catalog //= $self->catalog;

    if ($catalog->has_cache_changed) {
        $self->app->log->debug("Cache appears to have been updated since last check");
        $catalog->load;
    }

}

1;
