package Runnel;
use Mojo::Base 'Mojolicious', -signatures;

use Runnel::Catalog;

has 'catalog';
has 'playlist' => sub {[]};

# This method will run once at server start
sub startup ($self) {

  # Load configuration from config file
  my $config = $self->plugin('NotYAMLConfig');

  # Configure the application
  $self->secrets($config->{secrets});

  $self->renderer->cache->max_keys(0);
  
  # Router
  my $r = $self->routes;

  # Normal route to controller
  $r->get('/')->to('songs#index')->name("songs_index");

  # Songs 
  $r->get('/songs')->to('songs#index')->name("songs_index");
  $r->get('/songs/:path')->to('songs#show')->name("songs_show");

  $r->get('/playlists/current')->to('playlists#show_current')->name('playlists_show_current');
  $r->get('/playlists/current/add')->to('playlists#add_to_current')->name('playlists_add_to_current');
  $r->get('/playlists/current/remove')->to('playlists#remove_from_current')->name('playlists_from_from_current');
  $r->get('/playlists/current/clear')->to('playlists#clear_current')->name('playlists_clear_current');

  $r->get("/player")->to('players#index')->name('players_index');
  
  if ($config->{mp3BaseDirectory}) {
      my $cat = Runnel::Catalog->new(mp3BaseDirectory => $config->{mp3BaseDirectory}, app => $self);
      $self->catalog($cat);
      $self->app->log->info("Scanning mp3 directory: " . $self->catalog->mp3BaseDirectory);
      $self->catalog->find_songs;
      $self->app->log->info("Done.");
  } 

}

1;
