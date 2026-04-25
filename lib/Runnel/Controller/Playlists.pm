package Runnel::Controller::Playlists;
use Mojo::Base 'Runnel::Controller', '-signatures';

sub show_current ( $self ) {
    my $p = $self->app->playlist;

    return $self->respond_to(
        html => sub {
            $self->stash( playlist => $p->sort_by_track_number );
            $self->render( layout => "default" );
        },
        json => sub {
            my $list = $p->sort_by_track_number;
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
    $self->stash( playlist => $p->sort_by_track_number );
    $self->render(
        template => "playlists/fragments/playlist_table",
        format   => "html",
        handler  => "ep"
    );
}

sub add_to_current ( $self ) {
    my $path = $self->param( "path" );
    my $svc  = $self->app->playlist_manager;

    my ( $result, $error );
    eval { $result = $svc->add_by_path( $path ); 1 }
        or do { $error = $@ };

    if ( $error ) {
        return $self->respond_to(
            'json' => sub {
                $self->render( json => { success => 0, msg => $error } );
            },
            'html' => sub { $self->redirect_to( "playlists_show_current" ) }
        );
    }

    return $self->respond_to(
        'json' => sub { $self->render( json => $result ) },
        'html' => sub { $self->redirect_to( "playlists_show_current" ) }
    );
}

sub remove_from_current ( $self ) {
    my $path = $self->param( "path" );
    my $svc  = $self->app->playlist_manager;

    my ( $result, $error );
    eval { $result = $svc->remove_by_path( $path ); 1 }
        or do { $error = $@ };

    if ( $error ) {
        return $self->respond_to(
            'json' => sub {
                $self->render( json => { success => 0, msg => $error } );
            },
            'html' => sub { $self->redirect_to( "playlists_show_current" ) }
        );
    }

    return $self->respond_to(
        'json' => sub { $self->render( json => $result ) },
        'html' => sub { $self->redirect_to( "playlists_show_current" ) }
    );
}

sub clear_current ( $self ) {
    my $svc    = $self->app->playlist_manager;
    my $result = $svc->clear_all;

    return $self->respond_to(
        'json' => sub { $self->render( json => $result ) },
        'html' => sub { $self->redirect_to( 'playlists_show_current' ) },
    );
}

sub add_artist ( $self ) {
    my $name = $self->param( "name" );
    my $svc  = $self->app->playlist_manager;

    my $result = $svc->add_by_artist( $name );

    return $self->respond_to(
        'json' => sub { $self->render( json => $result ) },
        'html' => sub { $self->redirect_to( 'playlists_show_current' ) }
    );
}

sub add_album ( $self ) {
    my $name = $self->param( "name" );
    my $svc  = $self->app->playlist_manager;

    my $result = $svc->add_by_album( $name );

    return $self->respond_to(
        'json' => sub { $self->render( json => $result ) },
        'html' => sub { $self->redirect_to( "playlists_show_current" ) }
    );
}

sub add_genre ( $self ) {
    my $name = $self->param( "name" );
    my $svc  = $self->app->playlist_manager;

    my $result = $svc->add_by_genre( $name );

    return $self->respond_to(
        'json' => sub { $self->render( json => $result ) },
        'html' => sub { $self->redirect_to( "playlists_show_current" ) }
    );
}

sub random ($self) {
    my $limit    = $self->param( "limit" ) || 100;
    my $svc      = $self->app->playlist_manager;

    my $result = $svc->add_random( $limit );

    return $self->respond_to(
        'html' => sub { $self->redirect_to( "playlists_show_current" ) } );
}

1;
