#!/usr/bin/env perl
use strict;
use warnings FATAL => 'all';
use English '-no_match_vars';
use IO 'File';
use HTGT::DBFactory;
use TargetedTrap::IVSA::SeqRead;
use TraceServer;

# Trying to detect wrongly duplicated clone names: HEPD0632_A_A03<<_1>>, HEPD0632_A_A03<<_2>>

die 'no previous_run' unless @ARGV >= 1;

my $previous_run     = shift;
my $file_prefix      = shift;
my $htgt             = HTGT::DBFactory->connect('vector_qc');
my $all_test_runs_rs = $htgt->resultset('QctestRun')->search_rs(
    { stage    => { like  => 'allele%' } },
    { order_by => { -desc => 'qctest_run_id' } }
);
my $trace_server = undef;
my %processed_plates = retrieve_prievious_plates($previous_run);

# output and error handles
my $out = $file_prefix ? IO::File->new( "$file_prefix.out", 'w' ) : \*STDOUT;
my $err = $file_prefix ? IO::File->new( "$file_prefix.err", 'w' ) : \*STDERR;

$_->autoflush(1) for $out, $err;

print {$out} join( ',', qw( project clone_count _digit _2 ) ) . "\n";

while ( my $run = $all_test_runs_rs->next ) {
  if ( $processed_plates{ $run->clone_plate } ) {
    print {$err} "skipping [" . $run->clone_plate . "] alreaty seen\n";
    next;
  }
  my $results_rs = $run->qctestResults;

  my $allele = $run->stage =~ m/allele/;
  $trace_server = find_duplicate_seq_reads(
       $run->clone_plate, $allele, \%processed_plates, $trace_server );
}

exit 0;

sub find_duplicate_seq_reads {
    my $project      = shift;
    my $allele       = shift;
    my $seen_ref     = shift;
    my $trace_server = shift;

    if ( !$trace_server ) {
        $trace_server = eval { TraceServer->new( TS_DIRECT, TS_READ_ONLY, "" ) };
        if ($EVAL_ERROR) {
            print {$err} "TraceServer connection error for [$project]: $EVAL_ERROR";
            return;
        }
    }

    my $seqreads = eval {
        TargetedTrap::IVSA::SeqRead->new_from_traceserver_project( $project,
            $trace_server );
    };
    if ($EVAL_ERROR) {
        if ( $EVAL_ERROR =~ m/Database\serror/ ) {
            print {$err} "Database error for [$project] ... retrying\n";
            find_duplicate_seq_reads( $project, $allele, $seen_ref,
                $trace_server );
        }
        elsif ( $EVAL_ERROR =~ m/Could\snot\sget\sgroup/ ) {
            if ( $project =~ m/^(.+)_\D$/ ) {
                print {$err}
                    "MisLabel error for [$project] ... retrying with [$1]\n";
                find_duplicate_seq_reads( $1, $allele, $seen_ref,
                    $trace_server );
            }
        }
        else {
            print {$err} $EVAL_ERROR;
        }
        return $trace_server;
    }
    my %CLONES = map_seq_reads( $seqreads, { allele => $allele } );

    my @clone_tags = keys %CLONES;

    print {$out} join( ',',
        $project, scalar(@clone_tags),
        scalar( grep m/_\d+$/, @clone_tags ),
        scalar( grep m/_2$/,   @clone_tags ) )
        . "\n";

    return $trace_server;
}

sub map_seq_reads {
    my $seq_reads         = shift;
    my $params            = shift;
    my %CLONES            = ();
    my %SEQREADS          = ();
    my $primer_read_count = {};

    foreach my $seqread (@$seq_reads) {
        my $clone_plate = $seqread->project;

        #store all the seqreads hashed by trace_label
        $SEQREADS{ $seqread->trace_label } = $seqread;

        unless ( defined( $primer_read_count->{ $seqread->oligo_name } ) ) {
            $primer_read_count->{ $seqread->oligo_name } = 0;
        }
        $primer_read_count->{ $seqread->oligo_name } += 1;

        my $clone = $CLONES{ $seqread->clone_tag };
        unless ( defined($clone) ) {
            if ( $params->{allele} ) {
                $clone = TargetedTrap::IVSA::ConstructClone->new_from_seqread(
                    $seqread, $params->{allele} );
            }
            else {
                $clone = TargetedTrap::IVSA::ConstructClone->new_from_seqread(
                    $seqread);
            }
            $CLONES{ $seqread->clone_tag } = $clone;
            if ( $params->{post_gateway} || $params->{custom_gateway} ) {
                $clone->vector_type('final');
            }
            elsif ( $params->{allele} ) { $clone->vector_type('allele'); }
            else { $clone->vector_type('intermediate'); }
        }

        $clone->add_seqread($seqread);
    }

    return %CLONES;
}

sub retrieve_prievious_plates {
  my $file = shift;
  my %seen = ();
  my $pre = IO::File->new($file);
  while ( my $line = $pre->getline ) {
    $seen{ ( split /,/, $line )[0] }++;
  }
  $pre->close;
  return %seen;
}
