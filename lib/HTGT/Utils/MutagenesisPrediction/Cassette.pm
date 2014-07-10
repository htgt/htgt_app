package HTGT::Utils::MutagenesisPrediction::Cassette;

use Moose;
use Moose::Util::TypeConstraints;
use namespace::autoclean;
use Bio::SeqIO;
use HTGT::QC::Util::RunCmd qw(run_cmd);

has cassette_name => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has seq => (
    is         => 'ro',
    isa        => 'Bio::SeqI',
    init_arg   => undef,
    lazy_build => 1,
);

has first_splice_acceptor => (
    is         => 'ro',
    isa        => 'Maybe[Bio::LocationI]',
    init_arg   => undef,
    lazy_build => 1,
);

with 'MooseX::Log::Log4perl';

sub _build_seq{
	my $self = shift;

	my @args = ("eng-seq-builder","fetch-seq","--name",$self->cassette_name,"--format","genbank");

    $self->log->debug("Attempting to fetch seq for cassette ".$self->cassette_name);

    # FIXME: check for errors
	my $output = run_cmd(@args);

    open(my $stringfh, "<", \$output) or die "Could not open string for reading: $!";

    my $seqio = Bio::SeqIO->new( -fh => $stringfh, -format => 'genbank');

    return $seqio->next_seq;
}

sub _build_first_splice_acceptor{
    my $self = shift;

    my @features = sort { $a->start <=> $b->start} $self->seq->top_SeqFeatures;

    foreach my $feature (@features){
        my @notes = $feature->get_tag_values('note');
        if(grep {$_ eq 'Splice Acceptor'} @notes){
            $self->log->debug("Splice acceptor feature found at position ".$feature->start." of cassette");
            return $feature->location;
        }
    }

    $self->log->debug("No splice acceptor feature found in cassette");
    return undef;
}
