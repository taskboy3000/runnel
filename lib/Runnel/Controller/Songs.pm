package Runnel::Controller::Songs;

use FindBin;
use File::Slurp;
use Mojo::Base 'Mojolicious::Controller', '-signatures';
use Mojo::File;

sub index ( $self ) {
    $self->respond_to( html => sub { $self->render() } );
}

sub song_table ( $self ) {
    $self->stash( "songs" => $self->app->catalog->songs );
    $self->respond_to(
        html => sub {
            my $path =
                Mojo::File->new( $self->app->cachePath . "/song_table.html" );
            if ( -e $path ) {
                $self->app->log->info(
                    "Using cached song table from: " . $path );
                $self->reply->file( $path );
                return;
            }

            my $html = $self->render_to_string(
                template => "songs/fragments/song_table",
                format   => "html",
                handler  => "ep",
            );
            $self->app->log->info( "Caching complete song table" );
            write_file( $path, { binmode => ':utf8' }, $html );
            $self->reply->static( "song_table.html" );
            return;
        },
    );
}

sub search ( $self ) {
    my $term  = $self->param( "q" );
    my @words = split( /\s+/, $term );
    my $found = $self->app->catalog->search( \@words );

    return $self->respond_to(
        html => sub {

            # transform $found into catalog format
            my $catalogFormat = [];
            for my $info ( @$found ) {
                push @$catalogFormat,
                    {
                    info => $info,
                    name => $info->{ title },
                    };
            }

            $self->stash( "songs" => $catalogFormat );
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
