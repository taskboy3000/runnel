package Runnel::Command::test;
use Mojo::Base 'Mojolicious::Command', -signatures;

use Cwd 'abs_path';

has description => 'Run all tests (Perl and JavaScript)';

sub run ( $self, @args ) {
    my $home = $self->app->home;
    my $orig_dir = abs_path('.');

    print "Running Perl tests (prove t t/Service)...\n";
    system('prove', 't') == 0 or die "prove t failed: $?";
    system('prove', 't/Service') == 0 or die "prove t/Service failed: $?";

    print "Running JavaScript tests (npm test)...\n";
    chdir $home;
    system('npm', 'test') == 0 or die "npm test failed: $?";

    chdir $orig_dir;
    print "All tests passed!\n";
}

1;
