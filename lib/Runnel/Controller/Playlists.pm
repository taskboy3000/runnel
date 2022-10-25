package Runnel::Controller::Playlists;
use Mojo::Base 'Runnel::Controller', '-signatures';

sub show_current ( $self ) {
    my $p = $self->app->playlist;

    return $self->respond_to(
        html => sub {
            $self->stash( playlist => $p->sort_by_path );
            $self->render(layout => "default");
        },
        json => sub {
            my $list = $p->sort_by_path;
            for my $song ( @$list ) {
                $song->{ addSongToPlaylist } =
                    $self->url_for( 'playlists_add_to_current' )
                    ->query( 'path', $song->{ info }->{ partialPath } );
                $song->{ removeSongFromPlaylist } =
                    $self->url_for( 'playlists_remove_from_current' )
                    ->query( 'path', $song->{ info }->{ partialPath } );
            }
            $self->render( json => $list );
        }
    );
}

sub playlist_table ( $self ) {
    my $p = $self->app->playlist;
    $self->stash( playlist => $p->sort_by_path );
    $self->render(
        template => "playlists/fragments/playlist_table",
        format   => "html",
        handler  => "ep"
    );
}

sub add_to_current ( $self ) {
    my $path = $self->param( "path" );

    my $song;
    if ( $song = $self->app->catalog->find_by_path( $path ) ) {
        $self->app->log->info(
            "Adding to playlist: " . $song->{ info }->{ partialPath } );
        $self->app->playlist->add( $song );
    } else {
        $self->app->log->warn(
            "Could not find a song with path: " . ( $path || "-" ) );
    }

    my $msg = sprintf( 'Added %s', $song->{ info }->{ title } );
    $self->respond_to(
        'json' =>
            sub { $self->render( json => { success => 1, msg => $msg } ) },
        'html' => sub { $self->redirect_to( "playlists_show_current" ) }
    );
}

sub remove_from_current ( $self ) {
    my $path = $self->param( "path" );

    my $song;
    if ( $song = $self->app->catalog->find_by_path( $path ) ) {
        $self->app->playlist->remove( $song );
    }

    my $msg = 'Removed song ' . $song->{ info }->{ title };
    $self->respond_to(
        'json' =>
            sub { $self->render( json => { success => 1, msg => $msg } ) },
        'html' => sub { $self->redirect_to( "playlists_show_current" ) }
    );
}

sub clear_current ( $self ) {
    $self->app->playlist->clear();

    $self->respond_to(
        'json' => sub { $self->render( json => { success => 1 } ) },
        'html' => sub {
            $self->redirect_to( 'playlists_show_current' );
        }
    );

}

sub add_artist ( $self ) {
    my $name  = $self->param( "name" );
    my $songs = $self->app->catalog->get_songs( artist => $name );

    for my $song ( @$songs ) {
        $self->app->playlist->add( $song );
    }

    my $msg = sprintf(
        'Added %d song%s from artist %s',
        scalar @$songs,
        ( @$songs == 1 ? '' : 's' ), $name
    );
    $self->respond_to(
        'json' =>
            sub { $self->render( json => { success => 1, msg => $msg } ) },
        'html' => sub {
            $self->redirect_to( 'playlists_show_current' );
        }
    );
}

sub add_album ( $self ) {
    my $name  = $self->param( "name" );
    my $songs = $self->app->catalog->get_songs( album => $name );

    for my $song ( @$songs ) {
        $self->app->playlist->add( $song );
    }

    my $msg = sprintf(
        'Added %d song%s from album %s',
        scalar @$songs,
        ( @$songs == 1 ? '' : 's' ), $name
    );
    $self->respond_to(
        'json' =>
            sub { $self->render( json => { success => 1, msg => $msg } ) },
        'html' => sub {
            $self->redirect_to( "playlists_show_current" );
        }
    );
}

sub add_genre ( $self ) {
    my $name  = $self->param( "name" );
    my $songs = $self->app->catalog->get_songs( genre => $name );
    for my $song ( @$songs ) {
        $self->app->playlist->add( $song );
    }

    my $msg = sprintf(
        'Added %d song%s from genre %s',
        scalar @$songs,
        ( @$songs == 1 ? '' : 's' ), $name
    );
    $self->respond_to(
        'json' =>
            sub { $self->render( json => { success => 1, msg => $msg } ) },
        'html' => sub {
            $self->redirect_to( "playlists_show_current" );
        }
    );
}

sub random {
    my ($self) = @_;
    my $limit = $self->param("limit") || 100;

    my $songs = $self->app->catalog->get_random_songs('', $limit);
    for my $song  (@$songs) {
        $self->app->playlist->add($song);
        my $msg = sprintf( 'Added %s', $song->{ info }->{ title } );
        $self->app->log->info($msg);
    }

    $self->respond_to(
                      'html' => sub { $self->redirect_to("playlists_show_current") }
                     );
}

1;
