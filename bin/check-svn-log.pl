#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use IO::File;

my $MIN_WORDS = 4;
my $WORD_FILE = '/usr/share/dict/words';

my @PASSTHROUGH_MATCHES = (
    qr/tag(ged)?/i,
    qr/perltid(y|ied)/i,
    qr/initial\s+(commit|checkin|check-in)/i,
    qr/update.*version/i,
    qr/merge.*branch/i,
    qr/refs\s+#\d+/i,
    qr/closes\s+#\d+/i,
);

my @REJECT_MATCHES = (
);

die "Invalid log message: try writing a more descriptive commit log\n"
    unless is_valid_text();

exit 0;

sub is_valid_text {

    my $text;
    {
        local $/ = undef;
        $text = <STDIN>;
    }    

    for my $rx ( @REJECT_MATCHES ) {
        return 0 if $text =~ $rx;
    }
    
    for my $rx ( @PASSTHROUGH_MATCHES ) {
        return 1 if $text =~ $rx;
    }

    my @words = $text =~ m/(\w+)/g;

    return unless @words >= $MIN_WORDS;

    my %is_valid_word;

    my $ifh = IO::File->new( $WORD_FILE, O_RDONLY )
        or die "Failed to open $WORD_FILE: $!";
    while ( <$ifh> ) {
        chomp;
        $is_valid_word{lc($_)}++;
    }

    my %distinct_words = map { $_ => 1 } grep $is_valid_word{$_}, @words;

    return keys %distinct_words >= $MIN_WORDS;
}
