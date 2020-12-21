package Runnel::Controller::Playlists;
use Mojo::Base 'Mojolicious::Controller', '-signatures';

sub show_current ($self) {
    my $p = $self->app->playlist;
    $self->app->log->info("Songs in current playlist: " . scalar(@$p));
    $self->stash(playlist => $p);
    $self->render();
};

sub add_to_current ($self) {
    my $path = $self->param("path");

    if (my $song = $self->app->catalog->find_by_path($path)) {
        $self->app->log->info("Adding to playlist: " . $song->{info}->{partialPath});
        push @{ $self->app->playlist }, $song;
    } else {
        $self->app->log->warn("Could not find a song with path: " . ($path || "-"));
    }

    $self->respond_to(
                      'json' => sub { $self->render(json => {success => 1}) },
                      'html' => sub { $self->redirect_to("playlists_show_current") }
                     );
}

sub remove_from_current ($self) {
    my $path = $self->param("path");

    my @tmp;
    for my $song (@{ $self->app->playlist }) {
        if ($song->{info}->{partialPath} ne $path) {
            push @tmp, $song;
        }
    }

    @{ $self->app->playlist } = @tmp;
    
    $self->respond_to(
                      'json' => sub { $self->render(json => {success => 1} ) },
                      'html' => sub { $self->redirect_to("playlists_show_current") }
                     );
}

sub clear_current ($self) {
    $self->app->playlist = [];
    # @todo: respond_to
    $self->respond_to(
                      'json' => sub { $self->render(json => {success => 1} ) },
                                        'html' => sub {
                                          $self->redirect_to("playlist_show_current");
                                        }
                     );
    
}

1;
