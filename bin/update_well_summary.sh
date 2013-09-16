#!/bin/bash
#
# $Id: update_well_summary.sh,v 1.3 2009-07-14 16:08:24 rm7 Exp $

set -e

function die () {
	test -n "$1" && echo $1 >&2
	exit 1
}

CURRENT_WELL_SUMMARY="$(manage_synonym.pl well_summary)"
if test "${CURRENT_WELL_SUMMARY}" = "WELL_SUMMARY_T2"; then
	NEW_WELL_SUMMARY="WELL_SUMMARY_T3"
elif test "${CURRENT_WELL_SUMMARY}" = "WELL_SUMMARY_T3"; then
	NEW_WELL_SUMMARY="WELL_SUMMARY_T2"
else
	die "well_summary synonym not recognized"
fi

CURRENT_WELL_SUMMARY_BY_DI="$(manage_synonym.pl well_summary_by_di)"
if test "${CURRENT_WELL_SUMMARY_BY_DI}" = "WELL_SUMMARY_BY_DI_T2"; then
	NEW_WELL_SUMMARY_BY_DI="WELL_SUMMARY_BY_DI_T3"
elif test "${CURRENT_WELL_SUMMARY_BY_DI}" = "WELL_SUMMARY_BY_DI_T3"; then
	NEW_WELL_SUMMARY_BY_DI="WELL_SUMMARY_BY_DI_T2"
else
	die "well_summary_by_di synonym not recognized"
fi

set -x

fill_well_summary_by_di.pl --updatedb \
	--well_summary_by_di=${NEW_WELL_SUMMARY_BY_DI} 

fill_well_summary.pl --updatedb \
	--well_summary=${NEW_WELL_SUMMARY} 

update_allele_project_kermits_and_set_latest2.pl -cp -mls -afps --updatedb \
	--well_summary=${NEW_WELL_SUMMARY} --well_summary_by_di=${NEW_WELL_SUMMARY_BY_DI} 

stamp_project_id_onto_well_summary.pl \
	--well_summary=${NEW_WELL_SUMMARY} --well_summary_by_di=${NEW_WELL_SUMMARY_BY_DI}

manage_synonym.pl --update WELL_SUMMARY ${NEW_WELL_SUMMARY}
manage_synonym.pl --update WELL_SUMMARY_BY_DI ${NEW_WELL_SUMMARY_BY_DI}
