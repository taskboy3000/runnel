package Runnel::Catalog;
use Mojo::Base '-base';
use Modern::Perl;

use experimental 'signatures';

use Cwd 'abs_path';
use Encode;
use File::Spec::Functions;
use JSON;
use MP3::Info;
use MP3::Tag;
use Tree::Trie;

has 'app';
has mp3BaseDirectory => '.';
has songs            => sub { [] };
has trie             => sub { Tree::Trie->new };
has manifest         => sub { {} };
has catalog_file_mtime => 0;

sub catalog_cache_file ($self) {
  die('assert - no cachePath') if !($self->app && $self->app->cachePath);  
  return catfile($self->app->cachePath, 'catalog.json');
}

sub find_songs ( $self, $dir = '', $is_recursive = 0, $seen_ref = undef ) {
    $dir ||= $self->mp3BaseDirectory;

    my $changed = 0;

    # Build lookup hash on top-level call if we have existing songs
    my %path_to_song_idx;
    if ( !$is_recursive && @{ $self->songs } ) {
        for my $i ( 0 .. $#{ $self->songs } ) {
            my $path = $self->songs->[$i]->{info}->{partialPath}
                    || $self->songs->[$i]->{info}->{fullPath};
            $path_to_song_idx{$path} = $i if $path;
        }
    }

    # Initialize or use shared seen hash
    if ( !$seen_ref ) {
        $seen_ref = {};
    }

    opendir my $dh, $dir or die( "catalog[$dir]: $!" );

    my @children;

    while ( my $file = readdir $dh ) {
        $file = Encode::decode_utf8( $file );
        next if $file =~ /^\./;
        next if $file eq 'dups';

        if ( -d "$dir/$file" ) {
            push @children, "$dir/$file";
            next;
        }

        next if $file !~ /\.mp3$/;
        my $path = "$dir/$file";
        my $mtime = (stat($path))[9];
        $seen_ref->{$path} = $mtime;

        my $existing_mtime = $self->manifest->{$path};

        if ( !defined $existing_mtime ) {
            # New file
            $changed = 1;
            my $info = $self->getMP3Info( $path );
            my $songRec = {
                name => $info->{ title },
                info => $info,
            };
            push @{ $self->songs }, $songRec;
        } elsif ( $mtime > $existing_mtime ) {
            # Changed file
            $changed = 1;
            my $info = $self->getMP3Info( $path );
            my $songRec = {
                name => $info->{ title },
                info => $info,
            };
            if ( defined $path_to_song_idx{$path} ) {
                $self->songs->[ $path_to_song_idx{$path} ] = $songRec;
            } else {
                push @{ $self->songs }, $songRec;
            }
        }
        # else: unchanged, skip
    }
    closedir $dh;

    for my $child ( @children ) {
        my $child_changed = $self->find_songs( $child, 1, $seen_ref );
        $changed ||= $child_changed;
    }

    if ( !$is_recursive ) {
        # Detect deleted files
        for my $path ( keys %{ $self->manifest } ) {
            if ( !$seen_ref->{$path} ) {
                $changed = 1;
                # Remove from songs array
                @{ $self->songs } = grep {
                    my $p = $_->{info}->{partialPath}
                         || $_->{info}->{fullPath};
                    $p ne $path;
                } @{ $self->songs };
                delete $self->manifest->{$path};
            }
        }

        # Update manifest with current mtimes
        for my $path ( keys %$seen_ref ) {
            $self->manifest->{$path} = $seen_ref->{$path};
        }

        if ( $changed ) {
            # Sort by artist first, then album, then track
            my @sorted = sort {
                       $a->{ info }->{ artist } cmp $b->{ info }->{ artist }
                    || $a->{ info }->{ album } cmp $b->{ info }->{ album }
                    || $a->{ info }->{ track } <=> $b->{ info }->{ track }
            } @{ $self->songs };

            $self->songs( \@sorted );

            # Rebuild trie from scratch
            $self->rebuild_trie;
        }
    }

    return $changed;
}

sub getMP3Info ( $self, $filename = '' ) {
    if ( !-e $filename ) {
        $self->app->log->warn( "cannot find '$filename'" );
        return;
    }

    # Three options:
    #  1. Top-level song file
    #  2. Album/songs
    #  3. Artist/Album/Songs
    my $baseDir = $self->mp3BaseDirectory;
    ( my $parentDir = $filename ) =~ s{^$baseDir/}{};
    my ( $artist, $album, $songfile );
    ( $artist, $album, $songfile ) = (
        $parentDir =~ m{
                                    ^(?:([^/]+)/)?
                                    (?:([^/]+)/)?
                                    ([^/]+\.mp3)$
                                    }x
    );
    my $mp3 = MP3::Tag->new( $filename ) || die( "[$filename]: $!" );

    my %info = ( fullPath => $filename, partialPath => $parentDir );
    @info{ qw(title track artist album comment year genre) } =
        $mp3->autoinfo();

    # prefer on-disk ontology
    $info{ title } ||= "unknown";
    if ( !defined $info{ artist } && defined $artist ) {
        $info{ artist } = $artist;
    }
    if ( !defined $info{ album } && defined $album ) {
        $info{ album } = $album;
    }
    if ( $info{ track } eq '0/0' ) {
        if ( $filename =~ /^(\d+)/ ) {
            $info{ track } = sprintf( "%d", $1 );
        } else {
            $info{ track } = 1;
        }
    } elsif ( $info{ track } =~ /(\d+)/ ) {
        $info{ track } = $1 + 0;
    } else {
        $info{ track } = 0;
    }

    my $mp3Info = get_mp3info( $filename );
    if ( $mp3Info->{ BITRATE } ) {
        $info{ bitrate } = $mp3Info->{ BITRATE } * 1000;
    }

    if ( $mp3Info->{ FREQUENCY } ) {
        $info{ rate } = $mp3Info->{ FREQUENCY } * 1000;
    }

    $info{ mode } = $mp3Info->{ VBR } ? 'vbr' : 'cbr';
    $info{ size } = $mp3Info->{ SIZE };
    $info{ time } = int( $mp3Info->{ SECS } // 0 );

    # convert to hh::mm::ss
    my $minutes = int( $info{ time } / 60 );
    my $seconds = int( $info{ time } % 60 );
    $info{ time_pretty } = sprintf( "%d:%02d", $minutes, $seconds );

    $info{ channels } = $mp3Info->{ STEREO } ? 2 : 1;

    my %terms = map { lc( $_ ) => 1 } split( /(?:\s|_)+/, $info{ title } ),
        split( /(?:\s|_)+/, $info{ artist } ),
        split( /(?:\s|_)+/, $info{ album } ),
        split( /(?:\s|_)+/, $info{ genre } );

    for my $word ( keys %terms ) {
        next if !$word;
        my $arefs = $self->trie->lookup_data( $word );
        if ( !$arefs ) {
            $arefs = [];
        }
        push @$arefs, \%info;
        $self->trie->add_data( $word, $arefs );
    }

    return \%info;
}

sub find_by_path ( $self, $path ) {
    return $self->get_songs( partialPath => $path )->[ 0 ];
}

# All terms are ANDed
sub search ( $self, $wordsAPtr, $sortBy = 'title' ) {
    my %seen;
    my @found;

    my %paths;
    for my $word ( @$wordsAPtr ) {
        my $result = $self->search_by_word( $word );

        for my $info ( @$result ) {
            if ( $paths{ $info->{ partialPath } } ) {
                push @{ $paths{ $info->{ partialPath } } }, $info;
            } else {
                $paths{ $info->{ partialPath } } = [ $info ];
            }
        }
    }

    # Each %info has to appear in *all* results to be returned
    while ( my ( $path, $recs ) = each %paths ) {

       # Comparing the number of matched records to the number of search terms
        if ( @$recs == @$wordsAPtr ) {
            push @found,
                $recs->[ 0 ];    # all of these recs point to the same hash
        }
    }

    return [ sort { $a->{ $sortBy } cmp $b->{ $sortBy } } @found ];
}

sub search_by_word ( $self, $word ) {
    my %seen;
    my @found;
    my $aref = $self->trie->lookup_data( lc( $word ) );
    if ( $aref ) {
        for my $info ( @$aref ) {
            if ( $seen{ $info->{ partialPath } } ) {
                next;
            }
            push @found, $info;
            $seen{ $info->{ partialPath } } = 1;
        }
    }

    return \@found;
}

sub get_songs ( $self, $type, $criterion ) {
    my @found;
    for my $song ( @{ $self->songs } ) {
        if ( $song->{ info }->{ $type } eq $criterion ) {
            push @found, $song;
        }
    }

    return \@found;
}

sub get_random_songs ( $self, $term, $limit ) {
    $limit //= 200;

    my $songs = [];
    if ( $term ) {
        $songs = $self->search_by_word( $term );
    } else {
        my $listSize = @{ $self->songs };
        my %seen;
        for ( my $i = 0; $i < $limit; $i++ ) {
            my $idx = int( rand( $listSize ) );
            if ( exists $seen{ $idx } ) {
                next;
            }
            push @$songs, $self->songs->[ $idx ];
            $seen{ $idx } = 1;
        }
    }

    if ( $limit && @$songs > $limit ) {
        @$songs = @{ $songs }[ 0 .. ( $limit - 1 ) ];
    }

    return $songs;
}

sub add_to_trie ( $self, $info ) {
    my %terms = map { lc( $_ ) => 1 } split( /(?:\s|_)+/, $info->{ title } ),
        split( /(?:\s|_)+/, $info->{ artist } ),
        split( /(?:\s|_)+/, $info->{ album } ),
        split( /(?:\s|_)+/, $info->{ genre } );

    for my $word ( keys %terms ) {
        next if !$word;
        my $arefs = $self->trie->lookup_data( $word );
        if ( !$arefs ) {
            $arefs = [];
        }
        push @$arefs, $info;
        $self->trie->add_data( $word, $arefs );
    }
}

sub remove_from_trie ( $self, $info ) {
    my %terms = map { lc( $_ ) => 1 } split( /(?:\s|_)+/, $info->{ title } ),
        split( /(?:\s|_)+/, $info->{ artist } ),
        split( /(?:\s|_)+/, $info->{ album } ),
        split( /(?:\s|_)+/, $info->{ genre } );

    for my $word ( keys %terms ) {
        next if !$word;
        my $arefs = $self->trie->lookup_data( $word );
        next if !$arefs;

        my @filtered = grep { $_ != $info } @$arefs;

        if ( @filtered ) {
            $self->trie->add_data( $word, \@filtered );
        } else {
            $self->trie->remove( $word );
        }
    }
}

sub rebuild_trie ( $self ) {
    $self->trie( Tree::Trie->new );
    for my $song ( @{ $self->songs } ) {
        $self->add_to_trie( $song->{ info } );
    }
}

sub has_cache_changed ($self, $cacheFile = undef) {
    $cacheFile //= $self->catalog_cache_file;
    my $cacheUpdatedAt = $self->catalog_file_mtime;
    if (!$cacheUpdatedAt) {
        $self->app->log->debug("No catalog mtime set");
        return 1;
    }
    my $mtime = (stat $cacheFile)[9];
    return $mtime > $cacheUpdatedAt;
}

sub save ( $self, $cacheFile = undef ) {
    $cacheFile //= $self->catalog_cache_file;

    my $data = {
        'songs'    => $self->{songs},
        'manifest' => $self->{manifest},
    };

    my $temp_file = $cacheFile . "-$$.tmp";
    my $json_content = JSON->new->pretty( 1 )->encode( $data );

    open(my $cacheFH, '>:encoding(UTF-8)', $temp_file) or die("$temp_file: $!");
    print $cacheFH $json_content;
    close $cacheFH;

    rename( $temp_file, $cacheFile )
        or die "Cannot rename $temp_file to $cacheFile: $!";

    return 1;
}

sub load ( $self, $cacheFile = undef ) {
    my $logger = $self->app && $self->app->log ? $self->app->log : undef;

    $cacheFile //= $self->catalog_cache_file;

    return 0 unless -e $cacheFile;
    my $mtime = (stat $cacheFile)[9];
    $self->catalog_file_mtime($mtime);

    my $start = time();
    
    $logger->debug("Loading cache from $cacheFile") if $logger;
    open(my $cacheFH, '<:encoding(UTF-8)', $cacheFile) or die("$cacheFile: $!");
    my $json_content;
    {
        local $/ = undef;
        $json_content = <$cacheFH>;
    }
    close $cacheFH;

    if (!$json_content) {
        return;
    }

    my $data = JSON->new->decode( $json_content );
    if (!($data && ref $data eq ref {})) {
        return;
    }

    $self->songs([ @{$data->{songs} || [] } ]);
    $self->manifest({ %{$data->{manifest} || {}} });

    $self->{trie} = Tree::Trie->new;
    for my $song ( @{ $self->{songs} || [] } ) {
        my $path = $song->{info}{partialPath}
            || $song->{info}{fullPath}
            || next;
        $self->{trie}->add( $path );
    }
    my $numSongs = scalar(@{$self->songs});
    my $duration = time() - $start;
    $logger->debug("Loaded $numSongs songs from cache in $duration seconds") if $logger;

    return 1;
}

sub has_file_changed ($self, $relativePathMP3, $manifest=undef) {
    $manifest //= $self->manifest;
    my $mtime = (stat $relativePathMP3)[9];
    return $mtime > $manifest->{$relativePathMP3};
}

1;
