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

with 'MooseX::Log::Log4perl';

sub _build_seq{
	my $self = shift;

	my @args = ("eng-seq-builder","fetch-seq","--name",$self->cassette_name,"--format","genbank");

    $self->log->debug("Attempting to fetch seq for cassette ".$self->cassette_name);

	my $output = run_cmd(@args);

    open(my $stringfh, "<", \$output) or die "Could not open string for reading: $!";

    my $seqio = Bio::SeqIO->new( -fh => $stringfh, -format => 'genbank');

    return $seqio->next_seq;
}
