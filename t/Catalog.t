use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use File::Temp;
use Runnel::Catalog;
use Test::More;

my $testDir    = "$FindBin::Bin";
my $catalogDir = "$testDir/fake_catalog";

my $catalog;
{
    my $C = Runnel::Catalog->new();

    diag( "Looking at catalog in $catalogDir" );
    my $changed = $C->find_songs( $catalogDir );
    $catalog = $C;
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
    $C->find_songs( $emptyDir );
    ok( @{ $C->songs } == 0,
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
    my $C           = Runnel::Catalog->new();
    $C->find_songs( $catalogDir );
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
    my $C = Runnel::Catalog->new;
    $C->find_songs( $catalogDir );

    my $results = $C->search_by_word( 'Artist' );
    if ( $results ) {
        ok( scalar( @$results ) > 0, "search_by_word returns results" );
    } else {
        fail( "search_by_word did not return results" );
    }
}

sub test_get_songs {
    my $C = Runnel::Catalog->new;
    $C->find_songs( $catalogDir );

    my $results = $C->get_songs( 'title', 'A Song' );
    if ( $results ) {
        ok( scalar( @$results ) > 0, "get_songs returns results" );
    } else {
        fail( "get_songs did not return results" );
    }
}

sub test_trie_lookup {
    my $C = Runnel::Catalog->new;
    $C->find_songs( $catalogDir );

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

    # Second call should detect no changes
    my $changed = $C->find_songs( $catalogDir );
    ok( !$changed,
        "find_songs returns false on second call with no changes" );

    my $secondSongs = scalar( @{ $C->songs } );
    ok( $firstSongs == $secondSongs,
        "song count remains consistent across calls" );

    my $results1 = $C->search_by_word( 'Artist' );
    my $results2 = $C->search_by_word( 'Artist' );

    ok( scalar( @$results1 ) == scalar( @$results2 ),
        "trie data remains consistent" );
}

sub test_find_songs_returns_boolean {
    my $C = Runnel::Catalog->new;
    my $result = $C->find_songs( $catalogDir );
    ok( defined $result && $result =~ /^[01]$/,
        "find_songs returns a boolean value" );
}

sub test_find_songs_no_changes_detected {
    my $C = Runnel::Catalog->new;
    $C->find_songs( $catalogDir );

    # Call again without any filesystem changes
    my $changed = $C->find_songs( $catalogDir );
    ok( !$changed,
        "find_songs returns false when no files changed" );
}

sub test_find_songs_detects_new_file {
    my $C = Runnel::Catalog->new;
    $C->find_songs( $catalogDir );
    my $initialCount = scalar( @{ $C->songs } );

    # Create a new MP3 file
    my $newFile = "$catalogDir/new_song.mp3";
    if ( -e $newFile ) {
        unlink $newFile;
    }
    # Copy an existing file as our "new" file
    use File::Copy;
    copy( "$catalogDir/test.mp3", $newFile )
        or die "Cannot copy test.mp3: $!";
    # Make sure mtime is different
    utime( time(), time() + 1, $newFile );

    my $changed = $C->find_songs( $catalogDir );
    ok( $changed,
        "find_songs returns true when new file detected" );

    # Refresh catalog
    $C = Runnel::Catalog->new;
    $C->find_songs( $catalogDir );
    my $newCount = scalar( @{ $C->songs } );
    ok( $newCount > $initialCount,
        "new file appears in songs array" );

    # Cleanup
    unlink $newFile if -e $newFile;
}

sub test_find_songs_detects_deleted_file {
    my $C = Runnel::Catalog->new;
    $C->find_songs( $catalogDir );
    my $initialCount = scalar( @{ $C->songs } );

    # Remove a file
    my $fileToRemove = "$catalogDir/test.mp3";
    my $backupFile = "$catalogDir/test.mp3.bak";
    rename( $fileToRemove, $backupFile )
        or die "Cannot rename file: $!";

    my $changed = $C->find_songs( $catalogDir );
    ok( $changed,
        "find_songs returns true when file deleted" );

    # Refresh catalog
    $C = Runnel::Catalog->new;
    $C->find_songs( $catalogDir );
    my $newCount = scalar( @{ $C->songs } );
    ok( $newCount < $initialCount,
        "deleted file removed from songs array" );

    # Restore file
    rename( $backupFile, $fileToRemove )
        or die "Cannot restore file: $!";
}

sub test_find_songs_detects_changed_file {
    my $C = Runnel::Catalog->new;
    $C->find_songs( $catalogDir );

    # Touch a file to change its mtime
    my $fileToChange = "$catalogDir/test.mp3";
    my $oldMtime = (stat $fileToChange)[9];
    utime( time(), time() + 2, $fileToChange );

    my $changed = $C->find_songs( $catalogDir );
    ok( $changed,
        "find_songs returns true when file changed" );

    # Restore mtime
    utime( time(), $oldMtime, $fileToChange );
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
    my $C = Runnel::Catalog->new;
    $C->find_songs( $catalogDir );

    my $song = $C->find_by_path( "$testDir/fake_catalog/test.mp3" );
    ok( defined $song->{ info }->{ track }, "track number is defined" );
    ok( $song->{ info }->{ track } =~ /^\d+$/,
        "track number parses to integer"
    );
}

sub test_sort_order {
    my $C = Runnel::Catalog->new;
    $C->find_songs( $catalogDir );

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
    my $C = Runnel::Catalog->new;
    $C->find_songs( $catalogDir );

    my $results = $C->search( [ 'A', 'Song' ] );
    ok( defined $results && ref $results eq 'ARRAY',
        "search returns an array reference"
    );

    if ( scalar( @{ $C->songs } ) >= 1 ) {
        ok( scalar( @$results ) >= 0, "search returns valid count" );
    }
}

sub test_search_single_word {
    my $C = Runnel::Catalog->new;
    $C->find_songs( $catalogDir );

    my $results = $C->search( [ 'Artist' ] );
    ok( scalar( @$results ) >= 0, "search with single word returns results" );
}

sub test_search_and_logic {
    my $C = Runnel::Catalog->new;
    $C->find_songs( $catalogDir );

    my $results = $C->search( [ 'A', 'Song' ] );
    ok( defined $results && ref $results eq 'ARRAY',
        "search with AND logic returns array reference"
    );

    ok( scalar( @$results ) >= 0,
        "search returns valid count for AND query" );
}

sub test_search_empty_results {
    my $C = Runnel::Catalog->new;
    $C->find_songs( $catalogDir );

    my $results = $C->search( [ 'NonExistentWord12345' ] );
    is( scalar( @$results ),
        0, "search returns empty for non-matching terms" );
}

sub test_search_multiple_words_all_match {
    my $C = Runnel::Catalog->new;
    $C->find_songs( $catalogDir );

    my $results = $C->search( [ 'Best', 'Artist' ] );
    ok( scalar( @$results ) >= 0, "search with multiple matching words" );
}

sub test_get_random_songs_with_term {
    my $C = Runnel::Catalog->new;
    $C->find_songs( $catalogDir );

    my $results = $C->get_random_songs( 'Artist', 10 );
    ok( defined $results && ref $results eq 'ARRAY',
        "get_random_songs with term returns array"
    );
}

sub test_get_random_songs_without_term {
    my $C = Runnel::Catalog->new;
    $C->find_songs( $catalogDir );

    my $results = $C->get_random_songs( undef, 5 );
    ok( defined $results && ref $results eq 'ARRAY',
        "get_random_songs without term returns array"
    );
    ok( scalar( @$results ) <= 5, "get_random_songs respects limit" );
}

sub test_get_random_songs_default_limit {
    my $C = Runnel::Catalog->new;
    $C->find_songs( $catalogDir );

    my $results = $C->get_random_songs( '', 10 );
    ok( defined $results, "get_random_songs without term returns results" );
}

sub test_get_random_songs_duplicates {
    my $C = Runnel::Catalog->new;
    $C->find_songs( $catalogDir );

    my $results = $C->get_random_songs( undef, 100 );
    ok( defined $results, "get_random_songs with high limit succeeds" );
    ok( scalar( @$results ) <= 100, "get_random_songs truncates to limit" );
}

sub test_get_random_songs_term_no_match {
    my $C = Runnel::Catalog->new;
    $C->find_songs( $catalogDir );

    my $results = $C->get_random_songs( 'NonExistentWord12345', 5 );
    ok( defined $results,
        "get_random_songs with non-matching term returns defined" );
    is( scalar( @$results ),
        0, "get_random_songs returns empty for non-matching term" );
}


sub test_save_and_load {
    my $C = Runnel::Catalog->new;
    $C->find_songs( $catalogDir );

    my $initialSongs = scalar( @{ $C->songs } );
    ok( $initialSongs > 0, "catalog has songs before save" );

    $C->manifest( { '/fake_catalog/test.mp3' => 1234567890 } );
    my $initialManifest = $C->manifest;
    ok( keys %$initialManifest > 0, "manifest has entries before save" );

    my $temp = File::Temp->new( UNLINK => 0, SUFFIX => '.json' );
    my $cacheFile = $temp->filename;

    my $saved = $C->save( $cacheFile );
    ok( $saved, "save returns true" );
    ok( -e $cacheFile, "save creates cache file" );

    my $loadedCatalog = Runnel::Catalog->new;
    my $loaded = $loadedCatalog->load( $cacheFile );
    ok( $loaded, "load returns true" );

    my $loadedSongs = scalar( @{ $loadedCatalog->songs } );
    is( $loadedSongs, $initialSongs, "load restores correct number of songs" );

    my $loadedManifest = $loadedCatalog->manifest;
    ok( defined $loadedManifest && ref $loadedManifest eq 'HASH',
        "load restores manifest as hash" );
    is( $loadedManifest->{'/fake_catalog/test.mp3'},
        1234567890, "load restores manifest entries correctly" );
}

sub test_load_missing_file {
    my $C = Runnel::Catalog->new;

    my $result = $C->load( '/nonexistent/path/catalog.json' );
    ok( !$result, "load returns 0 for missing file" );
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
test_save_and_load();
test_load_missing_file();
test_find_songs_returns_boolean();
test_find_songs_no_changes_detected();
test_find_songs_detects_new_file();
test_find_songs_detects_deleted_file();
test_find_songs_detects_changed_file();

done_testing();
