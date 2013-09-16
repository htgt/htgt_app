#/usr/bin/env perl
use strict;
use warnings FATAL => 'all';

use HTGT::Utils::IdccTargRep;
use Log::Log4perl ':easy';
use Data::Dumper;

my $targrep = HTGT::Utils::IdccTargRep->new_with_config();

use HTGT::Utils::EUMMCRtoTargrep;
my $file = shift;

# load pcr qc data
my $pcr_data = HTGT::Utils::EUMMCRtoTargrep::get_pcr_data($file);
my %pcr_data = %{$pcr_data};

# print "ES Cell,3' SR-PCR,5' SR-PCR,5' LR-PCR,3' LR-PCR\n";
# foreach my $key ( keys %pcr_data ) {
#     print $key . ",";
#     print $pcr_data{$key}{three_prime_srpcr} . ",";
#     print $pcr_data{$key}{five_prime_srpcr} . ",";
#     print $pcr_data{$key}{five_prime_lrpcr} . ",";
#     print $pcr_data{$key}{three_prime_lrpcr} . ",";
#     print "\n";
# }
# 
# exit;

my $total_pcr                = 0;
my $number_of_updated_pcr    = 0;
my $number_of_went_wrong_pcr = 0;
my $not_in_targrep_pcr       = 0;

foreach my $key ( keys %pcr_data ) {
    $total_pcr++;
    my $tr_es_cell = $targrep->find_es_cell( { name => $key } );
    if ( scalar(@$tr_es_cell) > 0 ) {
        my $escell_id = $tr_es_cell->[0]->{id};
        print "found es cell " . $escell_id . "\n";
        eval {
            print "Updating es cell: " . $key . "\n";

            $targrep->update_es_cell(
                $escell_id,
                {   distribution_qc_three_prime_sr_pcr => $pcr_data{$key}{three_prime_srpcr},
                    distribution_qc_five_prime_sr_pcr  => $pcr_data{$key}{five_prime_srpcr},
                    distribution_qc_three_prime_lr_pcr => $pcr_data{$key}{three_prime_lrpcr},
                    distribution_qc_five_prime_lr_pcr  => $pcr_data{$key}{five_prime_lrpcr},
                }
            );
            $number_of_updated_pcr++;
        };
        if ($@) {
            $number_of_went_wrong_pcr++;
            print "Update went wrong: $@\n";
        }
    }
    else {
        $not_in_targrep_pcr++;
        print "not found es cell $key in targrep\n";
    }
}

print "Total: " . $total_pcr . "\n";
print "updated: " . $number_of_updated_pcr . "\n";
print "number of update went wrong: " . $number_of_went_wrong_pcr . "\n";
print "number of not found es cell in targrep: " . $not_in_targrep_pcr . "\n";

# load thaw data
print "-----------------\n";
print "load thaw column\n";
my $thaw_data = HTGT::Utils::EUMMCRtoTargrep::get_thaw_data($file);
my %thaw_data = %{$thaw_data};

my $total_thaw             = 0;
my $updated_thaw           = 0;
my $update_went_wrong_thaw = 0;
my $not_in_targrep_thaw    = 0;

foreach my $key (%thaw_data) {
    if ( $key =~ /EPD/ ) {
        $total_thaw++;
        my $cell_in_tr = $targrep->find_es_cell( { name => $key } );

        if ( scalar( @{$cell_in_tr} ) > 0 ) {
            my $es_cell_id = $cell_in_tr->[0]->{id};
            print "found es cell in targrep :" . $es_cell_id . "\n";
            eval {
                print "updating es cell " . $key . "\n";
                $targrep->update_es_cell( $es_cell_id, { distribution_qc_thawing => $thaw_data{$key}{distribution_qc_thawing}, } );
                $updated_thaw++;
            };
            if ($@) {
                $update_went_wrong_thaw++;
                print "update went wrong $@\n";
            }
        }
        else {
            $not_in_targrep_thaw++;
            print "not found in targrep\n";
        }
    }
}

print "Total for thaw: " . $total_thaw . "\n";
print "updated thaw: " . $updated_thaw . "\n";
print "update went wrong:" . $update_went_wrong_thaw . "\n";
print "not found in targrep: " . $not_in_targrep_thaw . "\n";
