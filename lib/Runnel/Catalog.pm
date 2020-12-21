package Runnel::Catalog;
use Mojo::Base '-base', '-signatures';
use Modern::Perl;
no warnings 'experimental::signatures';

use Cwd 'abs_path';
use Encode;
use JSON;
use MP3::Info;
use MP3::Tag;

has 'app';
has mp3BaseDirectory => '.';
has songs   => sub {[]};

sub find_songs {
    my ($self, $dir) = @_;
    $dir //= $self->mp3BaseDirectory;

    opendir my $dh, $dir or die($!);

    my @children;
    while (my $file = readdir $dh) {
        $file = Encode::decode_utf8($file);
        next if $file =~ /^\./;
        next if $file eq 'dups';

        if (-d "$dir/$file") {
            push @children, "$dir/$file";
            next;
        }

        next if $file !~ /\.mp3$/;

        my $info = $self->getMP3Info("$dir/$file");

        my $songRec = { name => $info->{title}, info => $info };
        my $s = $self->songs;
        push @$s, $songRec;
    }
    closedir $dh;

    for my $child (@children) {
        $self->find_songs($child);
    }

    # Sort
    $self->songs  ( [ sort { $a->{name} cmp $b->{name} } @{ $self->songs } ]);
}


sub getMP3Info {
    my ($self, $filename) = @_;

    if (!-e $filename) {
        $self->app->log->warn("cannot parse '$filename'");
        return;
    }
    # Three options:
    #  1. Top-level song file
    #  2. Album/songs
    #  3. Artist/Album/Songs
    my $baseDir = $self->mp3BaseDirectory;
    (my $parentDir = $filename) =~ s{^$baseDir/}{};
    my ($artist, $album, $songfile);
    ($artist, $album, $songfile) = ($parentDir =~ m{
                                    ^(?:([^/]+)/)?
                                    (?:([^/]+)/)?
                                    ([^/]+\.mp3)$
                                    }x);
    my $mp3 = MP3::Tag->new($filename) || die("[$filename]: $!");;
    
    # get some information about the file in the easiest way
    # /mp3 is a special route
    my %info = (fullPath => $filename, partialPath => "/mp3/$parentDir");
    @info{ qw(title track artist album comment year genre) } = $mp3->autoinfo();

    # prefer on-disk ontology
    $info{title} ||= "unknown";
    $info{artist} = $artist if defined $artist;
    $info{album} = $album if defined $album;

    if ($info{track} eq '0/0') {
        if ($filename =~ /^(\d+)/) {
            $info{track} = sprintf("%d", $1);
        } else {
            $info{track} = 1;
        }
    } else {
        ($info{track}) = split('/', $info{track});
    }

    my $mp3Info = get_mp3info($filename);
    $info{bitrate} = $mp3Info->{BITRATE} * 1000;
    $info{rate} = $mp3Info->{FREQUENCY} * 1000;
    $info{mode} = $mp3Info->{VBR} ? 'vbr' : 'cbr';
    $info{size} = $mp3Info->{SIZE};
    $info{time} = int($mp3Info->{SECS});

    # convert to hh::mm::ss
    my $minutes = int($info{time}/60);
    my $seconds = int($info{time} % 60);
    $info{time_pretty} = sprintf("%d:%02d", $minutes, $seconds);

    $info{channels} = $mp3Info->{STEREO} ? 2 : 1;

    return \%info;
}

sub find_by_path ($self, $path) {
    return $self->get_songs(partialPath => $path)->[0];
}

sub get_songs ($self, $type, $criterion) {
    my @found;  
    for my $song (@{ $self->songs }) {
        if ($song->{info}->{$type} eq $criterion) {
            push @found, $song;
        }
    }

    return \@found;
}

1;
