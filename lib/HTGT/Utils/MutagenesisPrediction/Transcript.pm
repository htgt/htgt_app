package HTGT::Utils::MutagenesisPrediction::Transcript;

use Moose;
use namespace::autoclean;
use Bio::Seq;
use Bio::SeqUtils;
use HTGT::Utils::MutagenesisPrediction::Constants;
use HTGT::Utils::MutagenesisPrediction::Exon;
use HTGT::Utils::MutagenesisPrediction::ORF;
use HTGT::Utils::MutagenesisPrediction::Cassette;
use List::MoreUtils qw( lastval );

has exons => (
    init_arg => 'exons',
    isa      => 'ArrayRef',
    traits   => [ 'Array' ],
    handles  => {
        exons => 'elements'
    },
);

has seq => (
    is         => 'ro',
    isa        => 'Bio::SeqI',
    init_arg   => undef,
    lazy_build => 1,
);

has orfs => (
    isa        => 'ArrayRef[HTGT::Utils::MutagenesisPrediction::ORF]',
    traits     => [ 'Array' ],
    handles    => {
        orfs => 'elements'
    },
    init_arg   => undef,
    lazy_build => 1,
);

has predicted_orf => (
    is        => 'ro',
    isa       => 'Maybe[HTGT::Utils::MutagenesisPrediction::ORF]',
    init_arg  => undef,
    writer    => 'set_predicted_orf',
    handles   => [
        'cdna_coding_start',
        'cdna_coding_end',
        'translation'
    ],
);

has description => (
    is         => 'ro',
    isa        => 'Str',
    writer     => 'set_description',
    init_arg   => undef,
);

has cassette => (
    is        => 'ro',
    isa       => 'Maybe[HTGT::Utils::MutagenesisPrediction::Cassette]',
    init_arg  => undef,
    writer    => 'set_cassette',
);

with qw( MooseX::Log::Log4perl );

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    my $cdna_start = 1;
    my @exons;
    for my $e ( @_ ) {
        my $cdna_end = $cdna_start + $e->length - 1;
        push @exons, HTGT::Utils::MutagenesisPrediction::Exon->new(
            ensembl_exon => $e,
            cdna_start   => $cdna_start,
            cdna_end     => $cdna_end,
        );
        $cdna_start += $e->length;
    }

    return $class->$orig( exons => \@exons );
};

around translation => sub {
    my $orig  = shift;
    my $self = shift;

    unless ( defined $self->predicted_orf ) {
        $self->log->warn( "Attempt to retrieve translation when no predicted ORF has been se t" );
        return Bio::Seq->new( -alphabet => 'protein', -seq => '' );
    }

    $self->$orig( @_ );
};

sub _build_seq {
    my $self = shift;

    my $seq = Bio::Seq->new( -alphabet => 'dna', -seq => '' );
    Bio::SeqUtils->cat( $seq, map $_->seq, $self->exons );

    # FIXME: check this is correct!
    if(defined $self->cassette){
        my $from_splice_site  = $self->cassette->seq->trunc(
                                   $self->cassette->first_splice_acceptor->end,
                                   $self->cassette->seq->length
                                );
        Bio::SeqUtils->cat( $seq, $from_splice_site );
    }

    return $seq;
}

sub _build_orfs {
    my $self = shift;

    my $seq = $self->seq;

    my @orfs;
    my $pos = 0;
    while ( ( my $start = index( $seq->seq, 'ATG', $pos ) ) >= 0 ) {
        $start += 1; # Bio::Seq expects 1-based coordinates
        # Now translate this ORF
        my $s = $seq->trunc( $start, $seq->length );
        $s->verbose(-1); # suppress warnings
        my $t = $self->translate_first_reading_frame( $s );
        my $orf = HTGT::Utils::MutagenesisPrediction::ORF->new(
            cdna_coding_start => $start,
            cdna_coding_end   => $start + ( $t->length * 3 ) - 1,
            translation       => $t
        );
        $self->log->debug( sprintf 'ORF cdna_coding_start %d, cdna_coding_end %d, translation %s',
                           $orf->cdna_coding_start, $orf->cdna_coding_end, $orf->translation->seq );
        push @orfs, $orf;
        $pos = $start;
    }

    return \@orfs;
}

=head translate_first_reading_frame

Translate the first reading frame of the sequence, sequence will always begin with a start codon.
We translate the sequence, identify the stop position and create a Bio::Seq object for the
amino acid sequence from the start to the stop codon.

NOTE: We do this to replicate the old behaviour of the translate( -orf => 1 ) method on Bio::PrimarySeqI.
Newer versions of BioPerl do not always translate the sequence from the first reading frame.

=cut
sub translate_first_reading_frame {
    my ( $self, $seq ) = @_;

    # defaults to frame 0, which is what we want as the start codon is the
    # first 3 bases of the sequence
    my $translation = $seq->translate();

    my $protein = $translation->seq;
    my $stop = index( $protein, '*' );
    return Bio::Seq->new( -alphabet => 'protein', seq => substr( $protein, 0, $stop + 1 ) );
}

sub is_nmd {
    my ( $self, $orf ) = @_;

    $orf ||= $self->predicted_orf;
    unless ( $orf ) {
        $self->log->warn( "cannot determine NMD without an ORF" );
        return;
    }

    my $last_splice_site = ( $self->exons )[-1]->cdna_start;

    # If the coding stops more than $NMD_SPLICE_LIMIT bases from the last splice site, this is NMD
    if ( $last_splice_site - $orf->cdna_coding_end > $NMD_SPLICE_LIMIT ) {
        return 1;
    }
    else {
        return 0;
    }
}

sub is_frameshift {
    my ( $self, $orf ) = @_;

    $orf ||= $self->predicted_orf;
    unless ( $orf ) {
        $self->log->warn( "cannot determine frameshift without an ORF" );
        return;
    }

    my $last_coding_exon = lastval { defined $_->cdna_coding_start( $orf ) } $self->exons;

    return undef unless $last_coding_exon;

    my $phase = $last_coding_exon->phase( $orf );
    my $orig_phase = $last_coding_exon->ensembl_exon->phase;

    # If the last coding exon is out of frame, this is a frameshift
    if ( defined $phase and defined $orig_phase and $phase == $orig_phase ) {
        return 0;
    }
    else {
        return 1;
    }
}

sub detail_to_hash {
    my ($self, $type) = @_;

    $type ||= "floxed";

    my %h;

    if ( defined $self->predicted_orf ) {
        %h = (
            $type."_transcript_description"       => $self->description,
            $type."_transcript_is_nmd"            => $self->is_nmd,
            $type."_transcript_is_frameshift"     => $self->is_frameshift,
            $type."_transcript_cdna_coding_start" => $self->cdna_coding_start,
            $type."_transcript_cdna_coding_end"   => $self->cdna_coding_end,
            $type."_transcript_translation"       => $self->translation ? $self->translation->seq : ''
        );
    }
    elsif ( defined $self->description ) {
        %h = ( $type."_transcript_description" => $self->description );
    }

    return \%h;
}

sub exons_to_hash {
    my $self = shift;

    my %exons;

    my $orf = $self->predicted_orf;
    unless ( $orf ) {
        $self->log->warn( "cannot produce hash without a predicted ORF" );
        return {};
    }

    for my $e ( $self->exons ) {
        $exons{ $e->ensembl_exon->stable_id } = {
            phase       => $e->phase( $orf ),
            end_phase   => $e->end_phase( $orf ),
            translation => $e->translation( $orf ) ? $e->translation( $orf )->seq : '',
        };
    }
    return \%exons;
}

sub add_cassette {
    my ($self, $cassette_name) = @_;

    my $cassette = HTGT::Utils::MutagenesisPrediction::Cassette->new({ cassette_name => $cassette_name });

    $self->set_cassette($cassette);
}

__PACKAGE__->meta->make_immutable;

1;

__END__
