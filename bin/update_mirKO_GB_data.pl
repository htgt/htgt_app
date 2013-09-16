#!/usr/bin/env perl
package MirKO::Update;

use Bio::SeqIO;
use Sanitize::GenBankData 'sanitize_genbank_data';
use Data::Dump 'pp';
use File::Temp;
use HTGT::Utils::IdccTargRep;
use IO::String;
use Log::Log4perl ':levels';
use Moose;
use Try::Tiny;

with qw/ MooseX::Getopt MooseX::Log::Log4perl::Easy /;

has [qw/ commit verbose /] => ( is => 'ro', default => 0, isa => 'Bool' );

has _idcc =>
    ( lazy_build => 1, handles => [qw/ find_allele update_genbank_file /] );

sub _build__idcc { HTGT::Utils::IdccTargRep->new_with_config }

has _alleles => (
    traits     => ['Array'],
    lazy_build => 1,
    handles    => { next_allele => 'shift' }
);

sub _build__alleles {
    my $self = shift;
    my $page = 1;
    my @alleles;
    while (1) {
        my $alleles
            = $self->find_allele( { pipeline_id => 5, page => $page++ } );
        last unless @{$alleles};
        push @alleles, @{$alleles};
    }
    $self->log_info( "Processing " . @alleles . " mirKO Allele(s)" );
    return \@alleles;
}

sub BUILD { Log::Log4perl->easy_init( shift->verbose ? $DEBUG : $INFO ) }

sub _transform_data {
    my $self = shift;
    my $data = shift;
    my $is_circular = shift;
    
    my $file = File::Temp->new( 'SUFFIX' => '.gb' );

    $file->print($data);

    my $updated_file = sanitize_genbank_data( $file->filename );

    my $seq = Bio::SeqIO->new( -file => $updated_file )->next_seq;
    $seq = $self->_update_annotations($seq);
    $seq->is_circular($is_circular);

    # write the updated data to string
    my $updated_data;
    my $output_seqio = Bio::SeqIO->new(
        -fh     => IO::String->new($updated_data),
        -format => 'genbank'
    );
    
    $output_seqio->write_seq($seq);

    return $updated_data;
}

sub _update_annotations {
    my $self = shift;
    my $seq  = shift;

    # add cassette and backbone
    my $ann = $seq->annotation;

    for my $comment ( 'cassette : PGK_EM7_PuDtk_bGHpA', 'backbone : PL611' ) {
        $ann->add_Annotation( 'comment',
            Bio::Annotation::Comment->new( -text => $comment ) );
    }

    $seq->annotation($ann);

    # get the correct display id
    my ($vntname) = grep m/VNTNAME/, map $_->as_text, $ann->get_Annotations('comment');

    if ( my ($display_id) = $vntname =~ m/^Comment: VNTNAME\|(.+)\|$/ ) {
        $display_id =~ s/\s+//g;
        $seq->display_id($display_id);
    }

    return $seq;
}

sub run {
    my $self = shift;

    # fetch mirKO alleles
    while ( my $allele = $self->next_allele ) {
        $self->log_info( "Processing Allele ($allele->{id})" );

        my %modifications;

        # fetch GB files for current allele
        for my $molecular_structure (qw/escell_clone targeting_vector/) {
            my $data = $allele->{genbank_file}{$molecular_structure};

            next unless defined $data and length $data;

            my $is_circular  = $molecular_structure ne 'escell_clone';
            my $updated_data = $self->_transform_data($data, $is_circular);

            if ( $updated_data ne $data ) {
                $modifications{$molecular_structure} = $updated_data;
            }
        }

        if ( %modifications && $self->commit ) {
            $self->log_info( "Updating GenBank File ($allele->{genbank_file}{id})" );
            try {
                $self->update_genbank_file(
                    $allele->{genbank_file}{id} => \%modifications );
            }
            catch {
                $self->log_error( "Could not update GenBank File ($allele->{genbank_file}{id}):\n$_" );
            };
        }
    }
}

package main;

use strict;
use warnings FATAL => 'all';

MirKO::Update->new_with_options->run;

exit 0;
