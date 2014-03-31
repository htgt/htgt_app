#!/usr/local/bin/perl -w

use strict;  
use Carp;    

my $file = $ARGV[0] || confess "Please supply a file containing sequences in fasta format.\n";
my $repeatmask = $ARGV[1] || "Please indicate whether you would like to repeatmask these sequences by typing rep or norep.\n";

if ( $repeatmask ne "rep" && $repeatmask ne "norep" ) {
    die "Incorrect input when indicating whether or not you require repeatmasking. Please enter either rep or norep.\n";
}

else {
    my $mt         = $ARGV[3];
    my $amp_size   = $ARGV[4]; 
    my $five_shim  = $ARGV[5]; if ( ! defined $five_shim  ) { $five_shim  = 60 }
    my $three_shim = $ARGV[6]; if ( ! defined $three_shim ) { $three_shim = 60 }
    
    print "The size of the shims: $five_shim :: $three_shim\n";
    
    
    my $outputfile = "output.temp";
    my $end        = $ARGV[2] || confess "Please enter 5 or 3 (in digit form) to indicate which end of the cassette you wish to design primers for.\n";

    if ( $end != 5 && $end != 3 ) {
        die
"Incorrect input when indicating cassette end. Please enter either 5 or 3.\n";
    }
    else {
        open( SEQUENCES,   $file );
        open( SEQUENCEOUT, ">$outputfile" );
        my @all_sequences = <SEQUENCES>;
        close(SEQUENCES);
        my @sequence_name;
        my $sequence_name;
        my %hash_sequences;
        my %hash_target_starts;
        my %hash_target_ends;

        my @revcomp;

        # Parse through the sequences, grabbing the names when encountered
        foreach my $sequence_line (@all_sequences) {
            if ( $sequence_line =~ />(\S+)\s+\+1/ ) {
                print "$1 sequence is on forward strand\n";
                $sequence_name = $1;
                if ( exists( $hash_sequences{$sequence_name} ) ) {
                    print "The sequence identifier $sequence_name has been used twice!  Please replace with unique identifiers and run program again.\n";
                    die "The sequence identifier $sequence_name has been used twice!  Please replace with unique identifiers and run program again.\n";
                }
            }
            elsif ( $sequence_line =~ />(\S+)\s+\-1/ ) {
                print "$1 sequence needs revcomping\n";
                #Put name into revcomp array.
                push( @revcomp, $1 );
                $sequence_name = $1;
                if ( exists( $hash_sequences{$sequence_name} ) ) {
                    print "The sequence identifier $sequence_name has been used twice!  Please replace with unique identifiers and run program again.\n";
                    die "The sequence identifier $sequence_name has been used twice!  Please replace with unique identifiers and run program again.\n";
                }
            }
            elsif ( $sequence_line =~ /[agctnAGCTN\[\]]+/ ) {
                $hash_sequences{$sequence_name} .= $sequence_line;
            }
        }

        #############################################
        # Section to do the reverse complementation #
        #############################################
        foreach my $revcomp_sequence_name (@revcomp) {
            my $revcomp_sequence = $hash_sequences{$revcomp_sequence_name};
            print "SEQ B4: $revcomp_sequence\n";
            $revcomp_sequence =~ tr/atgcATGC\[\]/tacgTACG\]\[/;
            $revcomp_sequence = reverse($revcomp_sequence);
            print "SEQ AF: $revcomp_sequence\n";
            $hash_sequences{$revcomp_sequence_name} = $revcomp_sequence;
        }

        ##################################################################################################
        # This explanation is for the 5 prime situation                                                  #
        #                                                                                                #
        # Minimum band size 100bp, maximum band size 400bp.                                              #
        #                                                                                                #
        # Round all figures to nearest 10.                                                               #
        #                                                                                                #
        # Closest 5` forward primer's 3` end can be to cassette is 60bp because cassette x          #
        # is 22bp, and 5` forward primer itself will be ~20bp, so 100 - (22 + 20) gives 58bp, ~60bp.     #
        #                                                                                                #
        # Furthest 5` forward primer's 5` end can be away from cassette is 380bp because cassette        #
        # primer is 22bp so 400 - (22) gives 378bp, ~380bp.                                              #
        #                                                                                                #
        # Closest 3` reverse primer's 3` end can be to cassette is 0bp because 5` forward primer         #
        # is ~20bp and a minimum of 58bp away from cassette, and 3` reverse primer itself will be ~20bp, #
        # so 20 + 20 + 58 gives 98bp (~100bp).                                                           #
        #                                                                                                #
        # Furthest 3` reverse primer's 5` end can be from cassette is 320bp because 5` forward           #
        # primer is ~20bp and a minimum of 58bp away from cassette, so 400 – (20 + 58) gives 322bp,   #
        # ~320bp.                                                                                        #
        ##################################################################################################

        my $five_outer_limit  = 0;
        my $five_inner_limit  = 0;
        my $three_outer_limit = 0;
        my $three_inner_limit = 0;

        if ( $end == 5 ) {
            #$five_outer_limit  = 380;
            #$five_inner_limit  = 60;
            #$three_outer_limit = 320;
            #$three_inner_limit = 0;
            
            $five_outer_limit  = 380;
            $five_inner_limit  = $five_shim;
            $three_outer_limit = 320;
            $three_inner_limit = $three_shim;
        }
        #Never actually see this.
        elsif ( $end == 3 ) {
            #$five_outer_limit  = 320;
            #$five_inner_limit  = 0;
            #$three_outer_limit = 380;
            #$three_inner_limit = 60;
            
            $five_outer_limit  = 320;
            $five_inner_limit  = $five_shim;
            $three_outer_limit = 380;
            $three_inner_limit = $three_shim;

        }

        # This foreach section is to find the coordinates of the two square brackets, so that they can be
        # removed prior to repeatmasking but we can then tell primer3 later on where to design the primers
        # around.
        foreach my $sequence_key ( keys %hash_sequences ) {
            print SEQUENCEOUT ">$sequence_key\n";
            my $sequence_string = $hash_sequences{$sequence_key};
            $sequence_string =~ s/\n//g;
            my @sequence = split( '', $sequence_string );

            my $count = 0;

            my @cleansed_sequence;

            if ( $end == 5 ) {
                foreach my $sequence_letter (@sequence) {
                    if ( $sequence_letter =~ /[agctnAGCTN]/ ) {
                        $cleansed_sequence[$count] = $sequence_letter;
                        $count++;
                    }
                    elsif ( $sequence_letter =~ /\[/ ) {
                        $hash_target_starts{$sequence_key} = $count;
                    }
                    elsif ( $sequence_letter =~ /\]/ ) {
                        $hash_target_ends{$sequence_key} = $count;
                    }
                }
            }
            elsif ( $end == 3 ) {
                foreach my $sequence_letter (@sequence) {
                    if ( $sequence_letter =~ /[agctnAGCTN]/ ) {
                        $cleansed_sequence[$count] = $sequence_letter;
                        $count++;
                    }
                    elsif ( $sequence_letter =~ /\]/ ) {
                        $hash_target_ends{$sequence_key} = $count;
                    }
                    elsif ( $sequence_letter =~ /\[/ ) {
                        $hash_target_starts{$sequence_key} = $count;
                    }
                }
            }
            my $size = $hash_target_ends{$sequence_key} -
              $hash_target_starts{$sequence_key};
            print "Target size is $size\n";

            # These next few lines just count out the section of the sequence you want for each gene, as defined
            # by the inner and out limits variables above.
            my $sequence_complete;
            for (
                my $int =
                $hash_target_starts{$sequence_key} - $five_outer_limit ;
                $int < $hash_target_starts{$sequence_key} + $three_outer_limit ;
                $int++
              )
            {
                $sequence_complete .= $cleansed_sequence[$int];
            }

            $sequence_complete =~ s/\W//g;
            print "Sequence $sequence_key formatted.\n";
            print SEQUENCEOUT "$sequence_complete\n\n";
            print "Sequence $sequence_key/n$sequence_complete\n\n";
        }

        close(SEQUENCEOUT);

        my $sequences_file;

        if ( $repeatmask eq "rep" ) {

            ########################
            # Repeatmasker section #
            ########################

            print "\n\nBeginning repeatmasking...\n\n";

            `mkdir ./temp/`;

            $sequences_file = "output.temp";
            my $repeatfinder_outputfile = './temp/temp.fa';
            open( SEQUENCE, $sequences_file );
            open( TEMP,     ">$repeatfinder_outputfile" );
            my @sequence        = <SEQUENCE>;
            my $sequence_string = "@sequence";

            close(SEQUENCE);
            
            #Attempt to get at the sequences for masking
            my $masked_outputfile = 'sequence.masked';
            open( MASKED_OUTPUTFILE, ">$masked_outputfile" );
            print TEMP "$sequence_string\n";    #print sequence to temp file
            my $pathname = '/software/pubseq/bin/RepeatMasker -species mouse -dir ./temp';
            my $cmd = "$pathname ./temp/temp.fa";
            #warn "running command ", $cmd, "\n\n";
            eval { system $cmd; };
            if ($@) { die "Problem running command $cmd\n$@" }
            my $masked_file = './temp/temp.fa.masked';   #open repeatfinder masked sequence file
            if ( -s $masked_file > 0 ) {
            open( MASKED_SEQUENCE, $masked_file );
                my @masked_sequence_array = <MASKED_SEQUENCE>;
                foreach my $masked_sequence_line (@masked_sequence_array) {
                    if ( $masked_sequence_line =~ />(\w+)/ ) {
                        print MASKED_OUTPUTFILE "\n\n$masked_sequence_line";
                    }
                    else {
                        chop $masked_sequence_line;
                        print MASKED_OUTPUTFILE "$masked_sequence_line";
                    }
                }

                close(MASKED_SEQUENCE);
                close(TEMP);
                #   `rm -r ./temp/*`;
                #close(MASKED_OUTPUTFILE);
                #print "\n...repeatmasking complete\n";
                #$sequences_file = "sequence.masked";
                `cp sequence.masked output.temp`;
                $sequences_file = "output.temp";
            }
            else {
                $sequences_file = "output.temp";                
            }
        }
        elsif ( $repeatmask eq "norep" ) {
            $sequences_file = "output.temp";
        }

        #########################
        # Primer design section #
        #########################

        #print "\n\nBeginning primer design...\n\n";

        open( SEQUENCES, $sequences_file )
          || confess "Could not open $sequences_file.";

        my @sequences = <SEQUENCES>;
        close(SEQUENCES);

        my $sequence_key;
        my $counter       = 0;
        my $next_sequence = 0;
#        `rm primer3output.txt`
          ; #temporary command, but just removes the file if it exists from a previous run of the program
        foreach (@sequences) {
            my $outputfile        = "boulder_formatted_input.temp";
            my $primer_outputfile = "primer3output.txt";
            if (/>(\w+)/) {
                $counter++;
                $sequence_key = $1;
                chomp($sequence_key);
            }
            elsif (/[agctnxAGCTNX]+/) {
                open( WHOLEOUT, ">$outputfile" )
                  || confess "Could not open output file.";
                print WHOLEOUT "PRIMER_SEQUENCE_ID=$sequence_key\n";
                my $sequence = $_;
                chomp($sequence);
                my $target_start  = 0;
                my $target_length = 0;
                if ( $end == 5 ) {

# Here the start of the targetted sequence must be reduced by 60bp to force the minimum possible product
# size to be 100bp....
                    $target_start = $hash_target_starts{$sequence_key} -
                      ( $hash_target_starts{$sequence_key} - $five_outer_limit )
                      - $five_inner_limit;

#...and to compensate for this shift in start location the targetted length must be extended by a
# corresponding amount
                    $target_length = $hash_target_ends{$sequence_key} -
                      $hash_target_starts{$sequence_key} + $five_inner_limit;
                }
                elsif ( $end == 3 ) {

# For the three prime situation the start of the targetted sequence remains unadjusted...
                    $target_start = $hash_target_starts{$sequence_key} -
                      ( $hash_target_starts{$sequence_key} -
                          $five_outer_limit );

             #...but the length of the targetted sequence must still be extended
                    $target_length = $hash_target_ends{$sequence_key} -
                      $hash_target_starts{$sequence_key} + $three_inner_limit;
                }
                print WHOLEOUT "SEQUENCE=$sequence\n";
                print WHOLEOUT "TARGET=$target_start,$target_length\n";
                
                print WHOLEOUT "PRIMER_PRODUCT_SIZE_RANGE=" . ($amp_size - 50) . '-' . ( $amp_size + 50 ) . "\n";
                #print WHOLEOUT "PRIMER_PRODUCT_SIZE_RANGE=100-400\n";
                
                print WHOLEOUT "PRIMER_OPT_TM=$mt\n";
                print WHOLEOUT "PRIMER_MAX_TM=" . ($mt +1) . "\n";
                print WHOLEOUT "PRIMER_MIN_TM=" . ($mt -1) . "\n";

                #print WHOLEOUT "PRIMER_OPT_TM=62.0\n";
                #print WHOLEOUT "PRIMER_MAX_TM=63.0\n";
                #print WHOLEOUT "PRIMER_MIN_TM=61.0\n";
                
                print WHOLEOUT "PRIMER_MAX_GC=60.0\n";
                print WHOLEOUT "PRIMER_MIN_GC=40.0\n";
                print WHOLEOUT "PRIMER_MAX_DIFF_TM=1.0\n";
                print WHOLEOUT "PRIMER_GC_CLAMP=1\n";
                print WHOLEOUT "PRIMER_SELF_ANY=5.0\n";
                print WHOLEOUT "PRIMER_SELF_END=2.0\n";
                print WHOLEOUT "PRIMER_EXPLAIN_FLAG=1\n";
                print WHOLEOUT "=\n";
                close(WHOLEOUT);
                $next_sequence = 1;
            }

            if ($next_sequence) {
                `/software/pubseq/bin/primer3_core -format_output < $outputfile >> $primer_outputfile`;
                $next_sequence = 0;
            }
        }

        ############################################
        # Primer design results formatting section #
        ############################################
        #print "...primer design complete\n\n\n";
        my $file       = 'primer3output.txt';
        my $outputfile = 'primers.txt';

        open( PRIMERS, $file ) || confess "Failed to open input file $file";
        my @primers = <PRIMERS>;
        close(PRIMERS);

        open( OUTPUT, ">$outputfile" )
          || confess "Failed to open output file $outputfile";

        my $count = 0;
        my %primer_details;
        my $sequence_id;
        my $additional_oligos;
        my @primer_array;
        my $number = 0;
        my $extras_seen = 0;

        foreach (@primers) {
            
            if ( /ADDITIONAL OLIGOS/ ) { $extras_seen = 1; next }
            
            if (/PRIMER PICKING RESULTS FOR (\w+)/) {
                $count++;
                $sequence_id       = $1;
                $additional_oligos = 0;
            }
            elsif (/ADDITIONAL OLIGOS/) {
                $additional_oligos = 1;
            }
            elsif (
/(LEFT) PRIMER\s+\d+\s+\d+\s+\d+.\d+\s+\d+.\d+\s+\d+.\d+\s+\d+.\d+\s+([agctnxAGCTNX]+)/
                & !$additional_oligos  & $extras_seen == 0)
            {
                print OUTPUT "$sequence_id" . "_F\t$2\n";
                my $left_primer_name = $sequence_id . "_F";
                $primer_array[$number]       = $left_primer_name;
                $primer_array[ $number + 1 ] = $2;
                $number                      = $number + 2;
            }
            elsif (
/(RIGHT) PRIMER\s+\d+\s+\d+\s+\d+.\d+\s+\d+.\d+\s+\d+.\d+\s+\d+.\d+\s+([agctnxAGCTNX]+)/
                & !$additional_oligos & $extras_seen == 0 )
            {
                print OUTPUT "$sequence_id" . "_R\t$2\n";
                my $right_primer_name = $sequence_id . "_R";
                $primer_array[$number]       = $right_primer_name;
                $primer_array[ $number + 1 ] = $2;
                $number                      = $number + 2;
            }
            elsif ( /(PRODUCT SIZE:\s\d+)/ & !$additional_oligos & $extras_seen == 0 ) {
                print OUTPUT "$1\n";
            }
            elsif (/NO PRIMERS FOUND/ & $extras_seen == 0) {
                print OUTPUT "$sequence_id" . "_F\tNO PRIMERS FOUND\n";
                print OUTPUT "$sequence_id" . "_R\tNO PRIMERS FOUND\n";
            }
            
            #Do actually get this far.
            #Hack to be like other hack?

            if ( $extras_seen == 1 ) {
                if (  /PRIMER/  ) {
                    s/^\s+\d{1,}//;
                    s/^\s+//;
                    if ( /left/i ) {
                        /(LEFT) PRIMER\s+\d+\s+\d+\s+\d+.\d+\s+\d+.\d+\s+\d+.\d+\s+\d+.\d+\s+([agctnxAGCTNX]+)/;
                        print OUTPUT "FORWARD_SPARE: $2\n";
                    } elsif ( /right/i ) {
                        /(RIGHT) PRIMER\s+\d+\s+\d+\s+\d+.\d+\s+\d+.\d+\s+\d+.\d+\s+\d+.\d+\s+([agctnxAGCTNX]+)/;
                        print OUTPUT "REVERSE_SPARE: $2\n";
                    }
                } elsif ( /PRODUCT SIZE/ ) { 
                    /PRODUCT SIZE:\s+(\d+),/;
                    my $psize = $1;       
                    print OUTPUT "P_SPARE: $psize\n";
                }
            }
            #End of hack
            
        }
        close(OUTPUT);

#        `rm output.temp`;
#        `rm sequence.masked`;
#        `rm boulder_formatted_input.temp`;
#        `rm -r temp`;

        print
"\nPlease see primers.txt file for results (see primer3output.txt for details).\n\n";
    }
}
