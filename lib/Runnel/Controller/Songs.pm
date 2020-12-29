package Runnel::Controller::Songs;

use FindBin;
use File::Slurp;
use Mojo::Base 'Mojolicious::Controller', '-signatures';
use Mojo::File;

{
  my $cacheFile;
  sub cachePath {
    if (defined $cacheFile) {
      return $cacheFile;
    }
    return $cacheFile = "$FindBin::Bin/../cache";
  }
}


sub index ($self) {
    $self->respond_to(
                      html => sub { $self->render() }
                     );
}


sub song_table ($self) {
    $self->stash("songs" => $self->app->catalog->songs);
    $self->respond_to(
                      html => sub {
                        my $path = Mojo::File->new($self->cachePath . "/song_table.html");
                        if (-e $path) {
                          # my $html = read_file($path, {binmode=>':utf8'});
                          $self->app->log->info("Using cached song table: " . $path);
                          return $self->reply->file($path);
                        }

                        my $html = $self->render_to_string(template => "songs/fragments/song_table",
                                                           format => "html",
                                                           handler => "ep",
                                                          );
                        write_file($path, $html, { binmode => ':utf8'});
                        return $self->reply->static($html);
                      },
                     );
}


sub search ($self) {
    my $term = $self->param("q");
    my @words = split(/\s+/, $term);
    my $found = $self->app->catalog->search(\@words);

    return $self->respond_to(
        html => sub {
            # transform $found into catalog format
            my $catalogFormat = [];
            for my $info (@$found) {
                push @$catalogFormat, {
                    info => $info,
                    name => $info->{title},
                };
            }

            $self->stash("songs" => $catalogFormat);
            $self->render(template => "songs/fragments/song_table",
                          format => "html",
                          handler => "ep",
                );
        },
        json => sub {
            $self->render(json => $found);
        }
        );
}

1;
