package Runnel::Controller::Songs;

use File::Basename;
use File::Slurp;
use FindBin;
use Mojo::Base 'Runnel::Controller', '-signatures';
use Mojo::File;

sub index ( $self ) {
    $self->respond_to( html => sub { $self->render( layout => "default" ) } );
}

sub song_table ( $self ) {
    $self->stash( "songs" => $self->app->catalog->songs );
    $self->respond_to(
        html => sub {
            return $self->render(
                template => "songs/fragments/song_table",
                format   => "html",
                handler  => "ep",
            );
        },
    );
}

sub search ( $self ) {
    my $term = $self->param( "q" );
    my $svc  = $self->app->song_search;

    my $found = $svc->search( $term );

    return $self->respond_to(
        html => sub {
            $self->stash( "songs" => $found );
            $self->render(
                template => "songs/fragments/song_table",
                format   => "html",
                handler  => "ep",
            );
        },
        json => sub {
            $self->render( json => $found );
        }
    );
}

1;
