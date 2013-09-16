package HTGT::Utils::RepositoryQCtoTargrep;

use strict;
use warnings FATAL => 'all';

use HTGT::Utils::IdccTargRep;
use IO::File;
use Log::Log4perl ':easy';
use Readonly;
use Text::CSV_XS;

Readonly my @CSV_COLUMNS => qw(
    clone_name
    well_name
    fp_well_id
    first_test_start_date
    latest_test_completion_date
    karyotype
    copy_number_equals_one
    threep_loxp_srpcr
    fivep_loxp_lr_sr_pcr
    vector_integrity
    loss_of_allele
    threep_loxp_taqman
    wtsi_fivep_lrpcr
    wtsi_threep_lrpcr
    wtsi_threep_loxp_junction
    wtsi_distribute
);

my $targrep           = HTGT::Utils::IdccTargRep->new_with_config();
my $updated           = 0;
my $not_in_targrep    = 0;
my $update_went_wrong = 0;

sub load_qc_to_targrep {
    my $filename = shift;
    my $fh = IO::File->new( $filename, O_RDONLY )
        or die "can't open the file $! ";
    my $csv = Text::CSV_XS->new( { allow_whitespace => 1 } );

    $csv->column_names(@CSV_COLUMNS);
    $fh->getline;    # remove the first line
  
    while ( not $fh->eof ) {
        my $data = $csv->getline_hr($fh);
        INFO( $data->{karyotype} );

        my ( $five_prime_srpcr, $five_prime_lrpcr, $karyotype_low, $karyotype_high);

        # convert the result to targrep accepted value
        unless ( !$data->{karyotype} || $data->{karyotype} =~ /not\s*done/ ){
            my ( $klow, $khigh ) = $data->{karyotype} =~ qr/^(\d+)\s*-\s*(\d+)\%$/
                or die "failed to parse karyotype '$data->{karyotype}'";
            $karyotype_low  = $klow / 100;
            $karyotype_high = $khigh / 100;
        }

        my $distribution_qc_copy_number = $data->{copy_number_equals_one} =~ /pass/ ? 'pass' :
            $data->{copy_number_equals_one} =~ /fail/ ? 'fail' : undef;
        my $vector_integrity = $data->{vector_integrity} =~ /pass/ ? 'pass' :
            $data->{vector_integrity} =~ /fail/ ? 'fail' : undef;
        my $three_prime_srpcr = $data->{threep_loxp_srpcr} =~ /pass/ ? 'pass' :
            $data->{threep_loxp_srpcr} =~ /fail/ ? 'fail' : undef;
        my $loa = $data->{loss_of_allele} =~ /pass/ ? 'pass' :
            $data->{loss_of_allele} =~ /fail/ ? 'fail' : undef;
        my $threep_loxp_taqman = $data->{threep_loxp_taqman} =~ /pass/ ? 'pass' :
            $data->{threep_loxp_taqman} =~ /not confirmed/ ? 'not confirmed' :
                $data->{threep_loxp_taqman} =~ /no reads detected/ ? 'no reads detected' :
                    undef;
        if ( $data->{fivep_loxp_lr_sr_pcr} =~ /short_range/ ){
            $five_prime_srpcr = $data->{fivep_loxp_lr_sr_pcr} =~ /pass/ ? 'pass' :
                $data->{fivep_loxp_lr_sr_pcr} =~ /fail/ ? 'fail' : undef;
        }
        else{
            $five_prime_lrpcr = $data->{fivep_loxp_lr_sr_pcr} =~ /pass/ ? 'pass' :
                $data->{fivep_loxp_lr_sr_pcr} =~ /fail/ ? 'fail' : undef;
        }

        #find escell
        my $tr_es_cell = $targrep->find_es_cell( { name => $data->{well_name} } );
        if ( scalar(@$tr_es_cell) > 0 ) {
            my $escell_id = $tr_es_cell->[0]->{id};

            #update escell
            eval {
                INFO( "Updating es cell: " . $data->{well_name} );
                $updated++;
                $targrep->update_es_cell(
                    $escell_id,
                    {   distribution_qc_copy_number => $distribution_qc_copy_number,
                        distribution_qc_three_prime_sr_pcr => $three_prime_srpcr,
                        distribution_qc_five_prime_sr_pcr  => $five_prime_srpcr,
                        distribution_qc_five_prime_lr_pcr  => $five_prime_lrpcr,
                        distribution_qc_karyotype_low      => $karyotype_low,
                        distribution_qc_karyotype_high     => $karyotype_high,
                        production_qc_loss_of_allele       => $loa,
                        production_qc_vector_integrity     => $vector_integrity,
                        production_qc_loxp_screen          => $threep_loxp_taqman
                    }
                );
            };
            if ($@) {
                $update_went_wrong++;
                INFO("Update went wrong: $@");
            }
        }
        else {
            $not_in_targrep++;
            INFO( $data->{well_name}."(".$data->{loss_of_allele}." ".$data->{threep_loxp_taqman}.") not found in targrep. \n");
        }
    }
    INFO( "Total updated: $updated" );
    INFO( "Total not in targrep: $not_in_targrep" );
    INFO( "Total update went wrong: $update_went_wrong" );
}

1;
