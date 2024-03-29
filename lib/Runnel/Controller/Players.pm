package Runnel::Controller::Players;
use Mojo::Base 'Runnel::Controller', '-signatures';

use JSON;

sub index ( $self ) {
    my $playlistARef = [];
    if ( my $p = $self->app->playlist ) {
        $playlistARef = $p;
    }

    $self->stash( "playlist", $playlistARef );
    $self->respond_to( 'html' => sub { $self->render(layout=>"default") } );
}

1;
