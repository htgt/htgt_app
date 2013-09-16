#!/usr/bin/env perl
#
# $HeadURL: svn+ssh://svn.internal.sanger.ac.uk/repos/svn/htgt/projects/htgt-utils-allele-name-updater/trunk/bin/allele-name-updater.pl $
# $LastChangedRevision: 5194 $
# $LastChangedDate: 2011-06-08 11:15:44 +0100 (Wed, 08 Jun 2011) $
# $LastChangedBy: rm7 $
#

use strict;
use warnings FATAL => 'all';

use HTGT::Utils::AlleleNameUpdater::CLI;

my $rc = HTGT::Utils::AlleleNameUpdater::CLI->new_with_options->load_allele_names;

exit $rc;

__END__
