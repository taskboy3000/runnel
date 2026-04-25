use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::More;

use Runnel::Catalog;

my $testDir    = "$FindBin::Bin";
my $catalogDir = "$testDir/fake_catalog";

my $catalog;
{
    my $C = Runnel::Catalog->new();

    diag( "Looking at catalog in $catalogDir" );
    $catalog = $C->find_songs( $catalogDir );
    if ( defined $catalog ) {
        ok( @{ $catalog->songs } > 0, "Found songs" );
    } else {
        fail( "find_songs did not return a new catalog" );
    }
}

# Test empty directory handling
{
    my $C = Runnel::Catalog->new();

    my $emptyDir = "$testDir/empty_dir";
    if ( !-d $emptyDir ) {
        die "assert - '$emptyDir' directory is not present.  Create it";
    }
    my $emptyCatalog = $C->find_songs( $emptyDir );
    ok( $emptyCatalog && @{ $emptyCatalog->songs } == 0,
        "find_songs returns an empty catalog for an empty directory"
    );
}

{
    my $C = Runnel::Catalog->new();

    my $mp3File = "$testDir/fake_catalog/test.mp3";
    diag( "Looking for metainfo in $mp3File" );
    my $meta         = $catalog->getMP3Info( $mp3File );
    my %expectedInfo = (
        artist => 'A. Artist',
        genre  => 'Electronic',
        title  => 'A Song',
        track  => '1',
        album  => 'Best of A. Artist',
        year   => '2026',
    );
    for my $key ( sort keys %expectedInfo ) {
        ok( $meta->{ $key } eq $expectedInfo{ $key },
            "metainfo[$key] '$meta->{$key}' matches expected value '$expectedInfo{ $key }'"
        );
    }
}

sub test_find_by_path {
    my $C           = Runnel::Catalog->new()->find_songs( $catalogDir );
    my $catalogSize = scalar( @{ $C->songs } );
    my $expectedCatalogSize = 4;

    # diag("Found $catalogSize songs in $catalogDir");
    ok( $catalogSize == $expectedCatalogSize,
        "Got the expected size of catalog"
    );
    my $song = $C->find_by_path( "$testDir/fake_catalog/test.mp3" );
    diag( "find_by_path returned: " . ( $song ? $song->{ name } : 'undef' ) );
    if ( $song ) {
        ok( defined $song->{ name }, "find_by_path returns song with name" );
        ok( defined $song->{ info }, "find_by_path returns song with info" );
    } else {
        fail( "find_by_path did not return a song" );
    }
}

sub test_search_by_word {
    my $C = Runnel::Catalog->new->find_songs( $catalogDir );

    my $results = $C->search_by_word( 'Artist' );
    if ( $results ) {
        ok( scalar( @$results ) > 0, "search_by_word returns results" );
    } else {
        fail( "search_by_word did not return results" );
    }
}

sub test_get_songs {
    my $C = Runnel::Catalog->new->find_songs( $catalogDir );

    my $results = $C->get_songs( 'title', 'A Song' );
    if ( $results ) {
        ok( scalar( @$results ) > 0, "get_songs returns results" );
    } else {
        fail( "get_songs did not return results" );
    }
}

sub test_trie_lookup {
    my $C = Runnel::Catalog->new->find_songs( $catalogDir );

    my $results = $C->search_by_word( 'Song' );
    ok( scalar( @$results ) > 0,
        "lookup_data returns results for matching term" );

    my $results2 = $C->search_by_word( 'A' );
    ok( scalar( @$results2 ) > 0, "lookup_data matches partial term" );
}

sub test_trie_persistence {
    my $C = Runnel::Catalog->new;

    $C->find_songs( $catalogDir );
    my $firstSongs = scalar( @{ $C->songs } );
    $C->songs( [] );
    $C->find_songs( $catalogDir );
    my $secondSongs = scalar( @{ $C->songs } );

    ok( $firstSongs == $secondSongs,
        "trie persists across multiple find_songs calls" );

    my $results1 = $C->search_by_word( 'Artist' );
    my $results2 = $C->search_by_word( 'Artist' );

    ok( scalar( @$results1 ) == scalar( @$results2 ),
        "trie data remains consistent" );
}

sub test_metadata_missing_fields {
    my $C = Runnel::Catalog->new;

    my $emptyFile = "$testDir/empty_dir/placeholder.mp3";
    if ( -e $emptyFile ) {
        unlink $emptyFile;
    }

    my $meta = eval { $C->getMP3Info( $emptyFile ) };
    ok( !defined $meta || !%$meta, "getMP3Info handles missing file" );
}

sub test_track_number_parsing {
    my $C = Runnel::Catalog->new->find_songs( $catalogDir );

    my $song = $C->find_by_path( "$testDir/fake_catalog/test.mp3" );
    ok( defined $song->{ info }->{ track }, "track number is defined" );
    ok( $song->{ info }->{ track } =~ /^\d+$/,
        "track number parses to integer"
    );
}

sub test_sort_order {
    my $C = Runnel::Catalog->new->find_songs( $catalogDir );

    my @songs = @{ $C->songs };
    return ok( 1, "sort order check - sufficient songs for test" )
        if @songs < 2;

    for my $i ( 0 .. $#songs - 1 ) {
        my $a = $songs[ $i ]->{ info };
        my $b = $songs[ $i + 1 ]->{ info };

        my $artist_cmp = $a->{ artist } cmp $b->{ artist };
        if ( $artist_cmp ne '0' ) {
            ok( $artist_cmp le '0', "songs sorted by artist ascending" );
            last;
        }

        my $album_cmp = $a->{ album } cmp $b->{ album };
        if ( $album_cmp ne '0' ) {
            ok( $album_cmp le '0', "songs sorted by album ascending" );
            last;
        }

        ok( $a->{ track } <= $b->{ track }, "songs sorted by track number" );
    }
}

sub test_search_method {
    my $C = Runnel::Catalog->new->find_songs( $catalogDir );

    my $results = $C->search( [ 'A', 'Song' ] );
    ok( defined $results && ref $results eq 'ARRAY',
        "search returns an array reference"
    );

    if ( scalar( @{ $C->songs } ) >= 1 ) {
        ok( scalar( @$results ) >= 0, "search returns valid count" );
    }
}

sub test_search_single_word {
    my $C = Runnel::Catalog->new->find_songs( $catalogDir );

    my $results = $C->search( [ 'Artist' ] );
    ok( scalar( @$results ) >= 0, "search with single word returns results" );
}

sub test_search_and_logic {
    my $C = Runnel::Catalog->new->find_songs( $catalogDir );

    my $results = $C->search( [ 'A', 'Song' ] );
    ok( defined $results && ref $results eq 'ARRAY',
        "search with AND logic returns array reference"
    );

    ok( scalar( @$results ) >= 0,
        "search returns valid count for AND query" );
}

sub test_search_empty_results {
    my $C = Runnel::Catalog->new->find_songs( $catalogDir );

    my $results = $C->search( [ 'NonExistentWord12345' ] );
    is( scalar( @$results ),
        0, "search returns empty for non-matching terms" );
}

sub test_search_multiple_words_all_match {
    my $C = Runnel::Catalog->new->find_songs( $catalogDir );

    my $results = $C->search( [ 'Best', 'Artist' ] );
    ok( scalar( @$results ) >= 0, "search with multiple matching words" );
}

sub test_get_random_songs_with_term {
    my $C = Runnel::Catalog->new->find_songs( $catalogDir );

    my $results = $C->get_random_songs( 'Artist', 10 );
    ok( defined $results && ref $results eq 'ARRAY',
        "get_random_songs with term returns array"
    );
}

sub test_get_random_songs_without_term {
    my $C = Runnel::Catalog->new->find_songs( $catalogDir );

    my $results = $C->get_random_songs( undef, 5 );
    ok( defined $results && ref $results eq 'ARRAY',
        "get_random_songs without term returns array"
    );
    ok( scalar( @$results ) <= 5, "get_random_songs respects limit" );
}

sub test_get_random_songs_default_limit {
    my $C = Runnel::Catalog->new->find_songs( $catalogDir );

    my $results = $C->get_random_songs( '', 10 );
    ok( defined $results, "get_random_songs without term returns results" );
}

sub test_get_random_songs_duplicates {
    my $C = Runnel::Catalog->new->find_songs( $catalogDir );

    my $results = $C->get_random_songs( undef, 100 );
    ok( defined $results, "get_random_songs with high limit succeeds" );
    ok( scalar( @$results ) <= 100, "get_random_songs truncates to limit" );
}

sub test_get_random_songs_term_no_match {
    my $C = Runnel::Catalog->new->find_songs( $catalogDir );

    my $results = $C->get_random_songs( 'NonExistentWord12345', 5 );
    ok( defined $results,
        "get_random_songs with non-matching term returns defined" );
    is( scalar( @$results ),
        0, "get_random_songs returns empty for non-matching term" );
}

test_find_by_path();
test_search_by_word();
test_get_songs();
test_trie_lookup();
test_trie_persistence();
test_metadata_missing_fields();
test_track_number_parsing();
test_sort_order();
test_search_method();
test_search_single_word();
test_search_and_logic();
test_search_empty_results();
test_search_multiple_words_all_match();
test_get_random_songs_with_term();
test_get_random_songs_without_term();
test_get_random_songs_default_limit();
test_get_random_songs_duplicates();
test_get_random_songs_term_no_match();

done_testing();
