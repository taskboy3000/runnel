package Runnel::Catalog;
use Mojo::Base '-base', '-signatures';
use Modern::Perl;
no warnings 'experimental::signatures';

use Cwd 'abs_path';
use Encode;
use JSON;
use MP3::Info;
use MP3::Tag;
use Tree::Trie;

has 'app';
has mp3BaseDirectory => '.';
has songs            => sub { [] };
has trie             => sub { Tree::Trie->new };

sub find_songs {
    my ( $self, $dir ) = @_;
    $dir //= $self->mp3BaseDirectory;

    opendir my $dh, $dir or die( $! );

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

        my $info = $self->getMP3Info( "$dir/$file" );

        my $songRec = {
            name => $info->{ title },
            info => $info,
        };
        my $s = $self->songs;
        push @$s, $songRec;
    }
    closedir $dh;

    for my $child ( @children ) {
        $self->find_songs( $child );
    }

    # Sort by artist first
    # Sort by Album next
    # Sort by Track last
    my @sorted = sort {
               $a->{ info }->{ artist } cmp $b->{ info }->{ artist }
            || $a->{ info }->{ album } cmp $b->{ info }->{ album }
            || $a->{ info }->{ track } <=> $b->{ info }->{ track }
    } @{ $self->songs };

    return $self->songs( \@sorted );
}

sub getMP3Info {
    my ( $self, $filename ) = @_;

    if ( !-e $filename ) {
        $self->app->log->warn( "cannot parse '$filename'" );
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
    $info{ artist } = $artist if defined $artist;
    $info{ album }  = $album  if defined $album;

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
    $info{ bitrate } = $mp3Info->{ BITRATE } * 1000;
    $info{ rate }    = $mp3Info->{ FREQUENCY } * 1000;
    $info{ mode }    = $mp3Info->{ VBR } ? 'vbr' : 'cbr';
    $info{ size }    = $mp3Info->{ SIZE };
    $info{ time }    = int( $mp3Info->{ SECS } );

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

1;
