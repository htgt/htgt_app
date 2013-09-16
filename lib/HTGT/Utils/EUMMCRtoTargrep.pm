package HTGT::Utils::EUMMCRtoTargrep;

use strict;
use warnings FATAL => 'all';

use Spreadsheet::ParseExcel;
use Data::Dumper;

=head

read the file (from Andreas andreas_clone_data_28_sept_2010.xls ) and return three_prime_srpcr, five_prime_srpcr, three_lrpcr, five_lrpcr

=cut

sub get_pcr_data {
    my $file = shift;

    my $parser    = Spreadsheet::ParseExcel->new();
    my $workbook  = $parser->parse($file);
    my $worksheet = $workbook->worksheet('targeting');

    my ( $r_min, $r_max ) = $worksheet->row_range();

    my %data;

    # read from the 3rd line
    foreach my $i ( 2 ... $r_max ) {
        my $cell = $worksheet->get_cell( $i, 2 );
        if ($cell) {
            my $clone = $cell->value;

            # convert the data value that targrep can accept

            ##
            ## 3' SR-PCR
            ##

            my $three_prime_srpcr_1 = $worksheet->get_cell( $i, 15 );
            my $three_prime_srpcr_2 = $worksheet->get_cell( $i, 16 );

            $three_prime_srpcr_1 = convert_input( $three_prime_srpcr_1->value, 'three_prime_srpcr' ) if $three_prime_srpcr_1;
            $three_prime_srpcr_2 = convert_input( $three_prime_srpcr_2->value, 'three_prime_srpcr' ) if $three_prime_srpcr_2;
            
            my $three_prime_srpcr = undef;
            
            if (   ( $three_prime_srpcr_1 and ( $three_prime_srpcr_1 eq 'fail' ) )
                or ( $three_prime_srpcr_2 and ( $three_prime_srpcr_2 eq 'fail' ) ) )
            {
                $three_prime_srpcr = 'fail';
            }
            elsif (( $three_prime_srpcr_1 and ( $three_prime_srpcr_1 eq 'pass' ) )
                or ( $three_prime_srpcr_2 and ( $three_prime_srpcr_2 eq 'pass' ) ) )
            {
                $three_prime_srpcr = 'pass';
            }
            
            if ( defined $data{$clone}{three_prime_srpcr} ) {
                if ( defined $three_prime_srpcr ) {
                    $data{$clone}{three_prime_srpcr} = $three_prime_srpcr unless $data{$clone}{three_prime_srpcr} eq 'pass';
                }
            } else {
                $data{$clone}{three_prime_srpcr} = $three_prime_srpcr;
            }
            
            ##
            ## 5' SR-PCR
            ##

            my $five_prime_srpcr = $worksheet->get_cell( $i, 17 );
            $five_prime_srpcr = convert_input( $five_prime_srpcr->value, 'five_prime_srpcr' ) if defined $five_prime_srpcr;
            if ( defined $data{$clone}{five_prime_srpcr} ) {
                if ( defined $five_prime_srpcr ) {
                    $data{$clone}{five_prime_srpcr} = $five_prime_srpcr unless $data{$clone}{five_prime_srpcr} eq 'pass';
                }
            } else {
                $data{$clone}{five_prime_srpcr} = $five_prime_srpcr;
            }
            
            ##
            ## 5' LR-PCR and 3' LR-PCR
            ##

            my $five_prime_lrpcr = $worksheet->get_cell( $i, 25 );
            $five_prime_lrpcr = convert_input( $five_prime_lrpcr->value, 'five_prime_lrpcr' ) if defined $five_prime_lrpcr;
            if ( defined $data{$clone}{five_prime_lrpcr} ) {
                if ( defined $five_prime_lrpcr ) {
                    $data{$clone}{five_prime_lrpcr} = $five_prime_lrpcr unless $data{$clone}{five_prime_lrpcr} eq 'pass';
                }
            } else {
                $data{$clone}{five_prime_lrpcr} = $five_prime_lrpcr;
            }
            
            my $three_prime_lrpcr = $worksheet->get_cell( $i, 26 );
            $three_prime_lrpcr = convert_input( $three_prime_lrpcr->value, 'three_prime_lrpcr' ) if defined $three_prime_lrpcr;
            if ( defined $data{$clone}{three_prime_lrpcr} ) {
                if ( defined $three_prime_lrpcr ) {
                    $data{$clone}{three_prime_lrpcr} = $three_prime_lrpcr unless $data{$clone}{three_prime_lrpcr} eq 'pass';
                }
            } else {
                $data{$clone}{three_prime_lrpcr} = $three_prime_lrpcr;
            }
        }
    }
    return \%data;
}

=head

method to get the thaw data from file (from Andreas andreas_clone_data_28_sept_2010.xls )

=cut

sub get_thaw_data {
    my $file   = shift;
    my $parser = Spreadsheet::ParseExcel->new();

    my $workbook  = $parser->parse($file);
    my $worksheet = $workbook->worksheet('tote clone');

    my ( $r_min, $r_max ) = $worksheet->row_range();

    my %data;

    # read from the 4th line
    for my $i ( 3 ... $r_max ) {
        my $cell = $worksheet->get_cell( $i, 2 );
        if ($cell) {
            my $clone                        = $cell->value;
            my $feeder_oder_audifferenzierte = $worksheet->get_cell( $i, 13 );
            my $keine_Zellen                 = $worksheet->get_cell( $i, 14 );
            my $gestorben                    = $worksheet->get_cell( $i, 15 );
            my $kontaminiert                 = $worksheet->get_cell( $i, 16 );

            if (   ( $feeder_oder_audifferenzierte and $feeder_oder_audifferenzierte->value eq 'X' )
                or ( $keine_Zellen and $keine_Zellen->value eq 'X' )
                or ( $gestorben    and $gestorben->value    eq 'X' )
                or ( $kontaminiert and $kontaminiert->value eq 'X' ) )
            {
                $data{$clone}{distribution_qc_thawing} = 'fail';
            }
        }
    }
    return \%data;
}

sub convert_input {
    my ( $value, $type_of_data ) = @_;

    if ( $type_of_data eq 'three_prime_srpcr' ) {
        if ( ( $value =~ /positiv/ ) or ( $value eq 'TR pos' ) ) {
            return 'pass';
        }
        elsif ( ( $value eq 'negative' ) or ( $value =~ /fail/ ) ) {
            return 'fail';
        }
        elsif ( ( $value =~ /n.d/ ) or ( $value eq '-' ) or ( $value eq '?' ) or ( $value =~ /^\s*$/ ) ) {
            return undef;
        }
        else {
            die "un-recognised three_prime_srpcr input '$value'\n";
        }
    }
    elsif ( $type_of_data eq 'five_prime_srpcr' ) {
        if ( $value =~ /positiv/ ) {
            return 'pass';
        }
        elsif ( ( $value =~ /negative/ ) or ( $value =~ /fail/ ) ) {
            return 'fail';
        }
        elsif (( $value =~ /n.d/ )
            or ( $value eq '-' )
            or ( $value eq '?' )
            or ( $value =~ /^\s*$/ )
            or ( $value eq 'new pr.!!' ) )
        {
            return undef;
        }
        else {
            die "un-recognised five_prime_srpcr input '$value'\n";
        }
    }
    elsif ( $type_of_data eq 'three_prime_lrpcr' ) {
        if ( ( $value =~ /positiv/ ) or ( $value =~ /positve/ ) ) {
            return 'pass';
        }
        elsif ( $value =~ /negative/ ) {
            return 'fail';
        }
        elsif ( $value =~ /^\s*$/ ) {
            return undef;
        }
        else {
            die "un-recognised three_prime_lrpcr input '$value'\n";
        }
    }
    elsif ( $type_of_data eq 'five_prime_lrpcr' ) {
        if ( $value =~ /positive/ ) {
            return 'pass';
        }
        elsif ( $value =~ /negative/ ) {
            return 'fail';
        }
        elsif ( ( $value =~ /^\s*$/ ) or ( $value =~ /neue Lyse/ ) ) {
            return undef;
        }
        else {
            die "un-recognised five_prime_lrpcr input '$value'\n";
        }
    }
    else {
        die "not recognised data type\n";
    }
}

1;
