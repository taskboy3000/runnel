use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use File::Temp qw(tempdir);
use File::Slurp qw(write_file);

chdir $FindBin::Bin;

subtest 'scan_interval defaults to 60 when config key is missing' => sub {
    my $config_file = File::Temp->new( UNLINK => 1, SUFFIX => '.yml' );
    print {$config_file} "mp3BaseDirectory: /tmp\nsecrets: test\n";
    $config_file->close;

    $ENV{ RUNNEL_YML } = $config_file->filename;
    my $t = Test::Mojo->new( 'Runnel' );
    is( $t->app->scan_interval, 60, 'Default interval is 60' );
};

subtest 'scan_interval uses user-provided value when >= 60' => sub {
    my $config_file = File::Temp->new( UNLINK => 1, SUFFIX => '.yml' );
    print {$config_file} "mp3BaseDirectory: /tmp\nsecrets: test\nscan_interval: 120\n";
    $config_file->close;

    $ENV{ RUNNEL_YML } = $config_file->filename;
    my $t = Test::Mojo->new( 'Runnel' );
    is( $t->app->scan_interval, 120, 'Uses 120 when provided' );
};

subtest 'scan_interval clamps to 60 when user provides < 60' => sub {
    my $config_file = File::Temp->new( UNLINK => 1, SUFFIX => '.yml' );
    print {$config_file} "mp3BaseDirectory: /tmp\nsecrets: test\nscan_interval: 30\n";
    $config_file->close;

    $ENV{ RUNNEL_YML } = $config_file->filename;
    my $t = Test::Mojo->new( 'Runnel' );
    is( $t->app->scan_interval, 60, 'Clamps to 60 when 30 provided' );
};

subtest 'scan_interval handles non-integer values gracefully' => sub {
    my $config_file = File::Temp->new( UNLINK => 1, SUFFIX => '.yml' );
    print {$config_file} "mp3BaseDirectory: /tmp\nsecrets: test\nscan_interval: abc\n";
    $config_file->close;

    $ENV{ RUNNEL_YML } = $config_file->filename;
    my $t = Test::Mojo->new( 'Runnel' );
    is( $t->app->scan_interval, 60, 'Defaults to 60 for non-integer value' );
};

subtest 'scan_interval handles null/empty values gracefully' => sub {
    my $config_file = File::Temp->new( UNLINK => 1, SUFFIX => '.yml' );
    print {$config_file} "mp3BaseDirectory: /tmp\nsecrets: test\nscan_interval:\n";
    $config_file->close;

    $ENV{ RUNNEL_YML } = $config_file->filename;
    my $t = Test::Mojo->new( 'Runnel' );
    is( $t->app->scan_interval, 60, 'Defaults to 60 for null value' );
};

done_testing();
