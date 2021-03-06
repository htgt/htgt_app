#! /bin/bash

function htgt {
case $1 in
    esmp)
        esmp
        ;;
    esmt)
        esmt
        ;;
    production|live)
        production_htgt
        ;;
    devel)
        devel_htgt $2
        ;;
    webapp)
        htgt_webapp $2
        ;;
    debug)
        htgt_debug $2
        ;;
    help)
        htgt_help
        ;;
    show)
        htgt_show
        ;;
    cpanm)
        htgt_cpanm $2
        ;;
    service)
        htgt_service $2
        ;;
    apache)
        htgt_apache $2
        ;;
    deploy)
        htgt_deploy $2
        ;;
     fcgi)
        htgt_fcgi $2
        ;;
    t87perl)
        htgt_t87perl
        ;;
    colour)
        set_colour_prompt
        set_colour_ls
        ;;
    mono)
        set_mono_prompt
        set_mono_ls
        ;;
    *)
        printf "Usage: htgt sub-command [option]\n"
        printf "see 'htgt help' for commands and options\n"
esac
}

function set_colour_prompt {
    #
    # Set the prompt so that it is obvious we are in the correct environment
    #
    Black='\e[0;30m'        # Black
    Red='\e[0;31m'          # Red
    Green='\e[0;32m'        # Green
    Yellow='\e[0;33m'       # Yellow
    Blue='\e[0;34m'         # Blue
    Purple='\e[0;35m'       # Purple
    Cyan='\e[0;36m'         # Cyan
    White='\e[0;37m'        # White
    if [[ $HTGT_SHORT_DB == esmt ]] ; then
        PS1="\[$Green\]\u@\h-\w-[$HTGT_ENV/\[$Cyan\]$HTGT_SHORT_DB\[$Green\]]>\[$White\] "
    else
        PS1="\[$Green\]\u@\h-\w-[$HTGT_ENV/\[$Yellow\]$HTGT_SHORT_DB\[$Green\]]>\[$White\] "
    fi
    export HTGT_COLOURS=1
}

function set_mono_prompt {
    export HTGT_COLOURS=
    PS1="\u@\h-\w-[$HTGT_ENV/$HTGT_SHORT_DB]> "

}

function set_prompt {
    if [[ "$HTGT_COLOURS" ]] ; then
        set_colour_ls
        set_colour_prompt
    else
        alias ls='ls -FqC'
        set_mono_prompt

    fi
}


function esmp {
    export HTGT_SHORT_DB=esmp
    export VECTOR_QC_DB=vector_qc_esmp
    synthesize_htgt_db
    set_prompt
}

function esmt {
    export HTGT_SHORT_DB=esmt
    export VECTOR_QC_DB=vector_qc_esmt
    synthesize_htgt_db
    set_prompt
}

function synthesize_htgt_db {
    export HTGT_DB=eucomm_vector_$HTGT_SHORT_DB
}

function check_and_set {
    if [[ ! -f $2 ]] ; then
        printf "WARNING: $2 does not exist but you are setting $1 to its location\n"
    fi
    export $1=$2
}

function check_and_set_dir {
    if [[ ! -d $2 ]] ; then
        printf "WARNING: directory $2 does not exist but you are setting $1 to its location\n"
    fi
    export $1=$2
}

function eng_seq_devel {
    check_and_set ENG_SEQ_BUILDER_CONF $HTGT_MIGRATION_ROOT/config/eng-seq-builder.devel.yaml
}

function eng_seq_live {
    check_and_set ENG_SEQ_BUILDER_CONF $HTGT_MIGRATION_ROOT/config/eng-seq-builder.yaml
}

function lims_rest_client_devel {
    check_and_set LIMS2_REST_CLIENT $HTGT_MIGRATION_ROOT/config/lims2-rest-client.devel.conf
}

function lims_rest_client_live {
    check_and_set LIMS2_REST_CLIENT $HTGT_MIGRATION_ROOT/config/lims2-rest-client.conf
}

function tarmits_live {
    # Tarmits setup
    check_and_set TARMITS_CLIENT_CONF $HTGT_MIGRATION_ROOT/config/tarmits-client-live.yml
}

function tarmits_devel {
    # Tarmits setup
    check_and_set TARMITS_CLIENT_CONF $HTGT_MIGRATION_ROOT/config/tarmits-client-test.yml
}



function devel_or_live {
# Check for the HTGT_DEV_ROOT variable setting and use that for HTGT_MIGRATION_ROOT, otherwise
# use the standard lcoation
    if [[ ( "$HTGT_DEV_ROOT" ) && ( -d "$HTGT_DEV_ROOT" ) ]] ; then
        check_and_set_dir HTGT_MIGRATION_ROOT $HTGT_DEV_ROOT
        check_and_set_dir HTGT_SHARED $HTGT_DEV_ROOT
        export HTGT_ENV=Devel
        lims_rest_client_devel
        eng_seq_devel
        tarmits_devel
        esmt
    else
        if [[ -d /htgt/live/current ]] ; then
            check_and_set_dir HTGT_MIGRATION_ROOT /htgt/live/current
            check_and_set_dir HTGT_SHARED /htgt/live/current
        elif [[ (! -z "$HTGT_NFS_STARTUP_DIR" ) && ( $HOSTNAME =~ farm3-head ) ]] ; then
            # This is for batch processing on farm3 - HTGT_MIGRATION_NFS_ROOT must already have been set
            check_and_set_dir HTGT_MIGRATION_ROOT $HTGT_NFS_STARTUP_DIR
            check_and_set_dir HTGT_SHARED $HTGT_NFS_STARTUP_DIR
        elif [[ $HOSTNAME =~ farm3-head ]] ; then
            printf "ERROR: On farm3 you must set the symbol HTGT_STARTUP_DIR\n"
            printf "==> using standard location: /nfs/team87/htgt/htgt_root\n"
            check_and_set_dir HTGT_MIGRATION_ROOT /nfs/team87/htgt/htgt_root
            check_and_set_dir HTGT_SHARED /nfs/team87/htgt/htgt_root
        fi
        export HTGT_ENV=Live
        lims_rest_client_live
        eng_seq_live
        tarmits_live
        esmp
    fi
    set_htgt_paths
}

function production_htgt {
    export SAVED_HTGT_DEV_ROOT="$HTGT_DEV_ROOT"
    unset HTGT_DEV_ROOT
    printf "==> saved your HTGT_DEV_ROOT setting, use 'htgt devel' command to switch back.\n"
    devel_or_live
}

function live_htgt {
    production_htgt
}

function htgt_live {
    production_htgt
}

function devel_htgt {
    if [[ ("$1") && ( -d "$1" ) ]] ; then
        export HTGT_DEV_ROOT=$1
    elif [[ ( "$SAVED_HTGT_DEV_ROOT" )]] ; then
        printf "==> switching to saved HTGT_DEV_ROOT: %s\n" $SAVED_HTGT_DEV_ROOT
        export HTGT_DEV_ROOT=$SAVED_HTGT_DEV_ROOT
    else
        printf "==> no saved HTGT_DEV_ROOT, using current working directory: %s\n" `pwd`
        export HTGT_DEV_ROOT=`pwd`;
    fi
    devel_or_live
}

function htgt_devel {
    devel_htgt $1
}

function htgt_webapp {
    export HTGT_HTTPS_DOMAIN='htgt2.internal.sanger.ac.uk';
    export HTGT_HTTP_DOMAIN='htgt2.internal.sanger.ac.uk'; 
    export WGE_ENABLE_HTTPS=1;

    if [[  "$1"   ]] ; then
        HTGT_PORT=$1
    elif [[ "$HTGT_WEBAPP_SERVER_PORT"  ]] ; then
        HTGT_PORT=$HTGT_WEBAPP_SERVER_PORT
    else
        HTGT_PORT=3000
    fi
    printf "starting htgt webapp on port $HTGT_PORT";
    if [[ "$HTGT_WEBAPP_SERVER_OPTIONS" ]] ; then
        printf " with options $HTGT_WEBAPP_SERVER_OPTIONS";
    fi
    printf "\n\n"
    printf "$HTGT_DEBUG_COMMAND $HTGT_MIGRATION_ROOT/htgt_app/script/htgt_server.pl -p $HTGT_PORT $HTGT_WEBAPP_SERVER_OPTIONS\n"
    $HTGT_DEBUG_COMMAND $HTGT_MIGRATION_ROOT/htgt_app/script/htgt_server.pl -p $HTGT_PORT $HTGT_WEBAPP_SERVER_OPTIONS
}

function htgt_debug {
    HTGT_DEBUG_COMMAND=$HTGT_DEBUG_DEFINITION
    htgt_webapp $1
    unset HTGT_DEBUG_COMMAND
}

function help_htgt {
cat <<END
Summary of commands in the htgt2 environment:

htgt <command> <optional parameter>
commands avaiable:
    production  - use the production codebase and database (esmp)
    live        - synonym for production_htgt
    devel <dir> - use the development codebase with root at <dir> and test database (esmt)
    esmp        - use the production database with the currently selected codebase
    esmt        - use the test database with the currently selected codebase

    note: 'htgt production' saves the development codebase root so that you can switch back
          with 'htgt devel'

    To set your development codebase root use:

    htgt devel \`pwd\` -or- export HTGT_DEV_ROOT=\`pwd\`
          or some other suitable setting

    webapp       - starts the webapp server on the default port, or the port specified in
                 \$HTGT_WEBAPP_SERVER_PORT with the options specified in
                 \$HTGT_WEBAPP_SERVER_OPTIONS (-d, -r etc as desired)

    webapp <port_num> - starts the catalyst server on the specified port, overriding the value
                 specified by \$HTGT_WEBAPP_SERVER_PORT (default $HTGT_WEBAPP_SERVER_PORT)

    deploy <devel | live>
    debug        - starts the catalyst server using 'perl -d '
    show         - show the value of useful HTGT variables
    cpanm        - installs a CPAN module to the correct lib location

    service start|stop|restart      - manages apache and fcgi together
     -- or --
    fcgi start|stop|restart        - manages the fcgi server
    apache start|stop|restart      - manages the apache webserver

    colour       - use colours in the prompt and in directory listings
    mono         - don't use any colour in prompt or directory listings
    help         - displays this help message
Files:
    ~/.htgt_local     - sourced near the end of the setup phase for you own mods
END
}

function htgt_help {
    help_htgt
}

function htgt_show {
cat << END
HTGT useful environment variables:

\$HTGT_MIGRATION_ROOT         : $HTGT_MIGRATION_ROOT
\$HTGT_MIGRATION_NFS_ROOT     : $HTGT_MIGRATION_NFS_ROOT
\$HTGT_DEV_ROOT               : $HTGT_DEV_ROOT
\$SAVED_HTGT_DEV_ROOT         : $SAVED_HTGT_DEV_ROOT
\$HTGT_LIVE_DEPLOYMENT_ROOT   : $HTGT_LIVE_DEPLOYMENT_ROOT
\$HTGT_DEVEL_DEPLOYMENT_ROOT  : $HTGT_DEVEL_DEPLOYMENT_ROOT
\$HTGT_WEBAPP_SERVER_PORT     : $HTGT_WEBAPP_SERVER_PORT
\$HTGT_WEBAPP_SERVER_OPTIONS  : $HTGT_WEBAPP_SERVER_OPTIONS
\$HTGT_DEBUG_DEFINITION       : $HTGT_DEBUG_DEFINITION

For QC Farm submission:
\$NFS_HTGT_DBCONNECT          : $NFS_HTGT_DBCONNECT
\$NFS_HTGT_QC_CONF            : $NFS_HTGT_QC_CONF
\$NFS_HTGT_QC_DIST_LOGIC_CONF : $NFS_HTGT_QC_DIST_LOGIC_CONF
\$NFS_LIMS2_REST_CLIENT_CONF  : $NFS_LIMS2_REST_CLIENT_CONF
\$NFS_GLOBAL_SYNTHVEC_DATADIR : $NFS_GLOBAL_SYNTHVEC_DATADIR
\$NFS_ENG_SEQ_BUILDER_CONF    : $NFS_ENG_SEQ_BUILDER_CONF

\$PERL5LIB :
`perl -e 'print( join("\n", split(":", $ENV{PERL5LIB}))."\n")'`

\$PATH :
`perl -e 'print( join("\n", split(":", $ENV{PATH}))."\n")'`

\$HTGT_DBCONNECT       : $HTGT_DBCONNECT
\$ENG_SEQ_BUILDER_CONF : $ENG_SEQ_BUILDER_CONF
\$TARMITS_CLIENT_CONF  : $TARMITS_CLIENT_CONF
\$LIMS2_REST_CLIENT    : $LIMS2_REST_CLIENT
\$HTGT_ENSEMBL_HOST    : $HTGT_ENSEMBL_HOST
\$HTGT_ENSEMBL_USER    : $HTGT_ENSEMBL_USER

\$HTGT_DB              : $HTGT_DB
\$HTGT_SHORT_DB        : $HTGT_SHORT_DB
\$HTGT_ENV             : $HTGT_ENV
END
}

function show_htgt {
    htgt_show
}

function htgt_cpanm {
    if [[ "$1" ]] ; then
        $HTGT_MIGRATION_ROOT/bin/cpanm -l $HTGT_MIGRATION_ROOT/perl5 $1
    else
        printf "ERROR: no module specified: htgt_cpanm <module>\n"
    fi
}

function htgt_apache {
    if [[ "$1" ]] ; then
        /usr/sbin/apachectl -f $HTGT_MIGRATION_ROOT/htgt_app/conf/apache.conf -k $1
    else
        printf "ERROR: must supply start|stop|restart to htgt apache command\n"
    fi
}

function htgt_fcgi {
    if [[ "$1" ]] ; then
        # Fast CGI setup
        export FCGI_INSTANCE='htgt'
        export DESC='HTGT (htgt2) FastCGI server'
        check_and_set LOG4PERL $HTGT_MIGRATION_ROOT/htgt_app/conf/log4perl-htgt.conf;
        $HTGT_MIGRATION_ROOT/htgt_app/conf/htgt $1
    else
        printf "ERROR: must supply start|stop|restart to htgt fcgi command\n"
    fi
}


function htgt_service {
    if [[ "$1" ]] ; then
        htgt_fcgi $1
        htgt_apache $1
    else
        printf "ERROR: must supply start|stop|restart to htgt fcgi command\n"
    fi
}

function htgt_deploy {
    if [[ $USER == "t87perl" ]] ; then
        if [[ "$1" == 'live' ]] ; then
            printf "INFO: deploying production code...\n"
            APPENV=live $HTGT_MIGRATION_ROOT/bin/deploy.sh
        elif [[ "$1" == 'devel' ]] ; then
            printf "INFO: deploying devel code...\n"
            APPENV=devel $HTGT_MIGRATION_ROOT/bin/deploy.sh
        else
            printf "ERROR: unrecognised deployment mode: $1\n"
        fi
    else
        printf "ERROR: must be user t87perl to deploy\n"
    fi
}

function htgt_t87perl {
    sudo -u t87perl -Hi
}

function perlmodver () {
        test -n "$1" || { echo 'Usage: perlmodver MODULE' >&2; return; }
        perl -m"$1" -le 'print $ARGV[0]->VERSION' "$1"
}

function perlmodpath () {
        test -n "$1" || { echo 'Usage: perlmodpath MODULE' >&2; return; }
        perl -m"$1" -le '$ARGV[0]=~s/::/\//g; print $INC{"$ARGV[0].pm"}' "$1"
}



function set_batch_paths {
    export _HTGT_BATCH=false
}

function set_htgt_paths {
    export PATH=/bin:/usr/bin
    # QC Farm Job submission path
    if [ -f /usr/local/lsf/conf/profile.lsf ] ; then
      source /usr/local/lsf/conf/profile.lsf
    fi
    # This is where all symbols should go that depend on HTGT_MIGRATION_ROOT
    # This function gets called when the user switches between live and devel environments
    export HTGT_HOME=$HTGT_MIGRATION_ROOT/htgt_app
    export PATH="/software/perl-5.14.4/bin:$HTGT_MIGRATION_ROOT/perl5/bin:$HTGT_MIGRATION_ROOT/bin:$HTGT_MIGRATION_ROOT/htgt_app/bin:$PATH"
    export PATH="$PATH:$HTGT_SHARED/Eng-Seq-Builder/bin:$HTGT_SHARED/HTGT-QC-Common/bin:$HTGT_SHARED/LIMS2-REST-Client/bin"
    export PERL_LOCAL_LIB_ROOT=$HTGT_MIGRATION_ROOT/perl5;
    export PERL_MB_OPT="--install_base $HTGT_MIGRATION_ROOT/perl5";
    export PERL_MM_OPT="INSTALL_BASE=$HTGT_MIGRATION_ROOT/perl5";
    export PERL5LIB="$HTGT_MIGRATION_ROOT/htgt_app/lib:$HTGT_MIGRATION_ROOT/perl5/lib/perl5"
    export PERL5LIB="$PERL5LIB:$HTGT_SHARED/Eng-Seq-Builder/lib:$HTGT_SHARED/HTGT-QC-Common/lib:$HTGT_SHARED/LIMS2-REST-Client/lib"
    export PERL5LIB="$PERL5LIB:/software/pubseq/PerlModules/Ensembl/www_80_1/ensembl/modules:/software/pubseq/PerlModules/Ensembl/www_80_1/ensembl-compara/modules"

    # Add nfs root to end of perl path for modules used by farm3
    export HTGT_MIGRATION_NFS_ROOT=/nfs/team87/htgt/htgt_root
    check_and_set_dir HTGT_MIGRATION_NFS_ROOT $HTGT_MIGRATION_NFS_ROOT
    export PERL5LIB=$PERL5LIB:$HTGT_MIGRATION_NFS_ROOT/htgt_batch/lib:$HTGT_MIGRATION_NFS_ROOT/perl5/lib/perl5
    export PERL5LIB=$PERL5LIB:$HTGT_MIGRATION_NFS_ROOT/HTGT-QC-Common/lib
    export PERL5LIB=$PERL5LIB:$HTGT_MIGRATION_NFS_ROOT/imits-perl-api/lib
    export PERL5LIB=$PERL5LIB:$HTGT_MIGRATION_NFS_ROOT/LIMS2-REST-Client/lib
    export PERL5LIB=$PERL5LIB:$HTGT_MIGRATION_NFS_ROOT/Eng-Seq-Builder/lib

    # And add nfs bin dirs to path
    export PATH=$PATH:$HTGT_MIGRATION_NFS_ROOT/htgt_batch/bin
    export PATH=$PATH:$HTGT_MIGRATION_NFS_ROOT/Eng-Seq-Builder/bin:$HTGT_MIGRATION_NFS_ROOT/HTGT-QC-Common/bin:$HTGT_MIGRATION_NFS_ROOT/LIMS2-REST-Client/bin

    # export PERL_LOCAL_LIB_ROOT=$HTGT_MIGRATION_NFS_ROOT/perl5:$HTGT_MIGRATION_ROOT

    # local config file locations all depend on HTGT_MIGRATION_ROOT
    check_and_set HTGT_DBCONNECT $HTGT_MIGRATION_ROOT/config/dbconnect.cfg
    check_and_set HTGT_QC_CONF $HTGT_MIGRATION_ROOT/config/qc.conf
    check_and_set HTGT_QC_DIST_LOGIC_CONF $HTGT_MIGRATION_ROOT/config/qc-dist-logic.conf
    check_and_set LIMS2_REST_CLIENT_CONF $HTGT_MIGRATION_ROOT/config/lims2-rest-client.conf
    # farm config file locations all depend on HTGT_NFS_MIGRATION_ROOT
    check_and_set NFS_HTGT_DBCONNECT $HTGT_MIGRATION_NFS_ROOT/config/dbconnect.cfg
    check_and_set NFS_HTGT_QC_CONF $HTGT_MIGRATION_NFS_ROOT/config/qc.conf
    check_and_set NFS_HTGT_QC_DIST_LOGIC_CONF $HTGT_MIGRATION_NFS_ROOT/config/qc-dist-logic.conf
    check_and_set NFS_LIMS2_REST_CLIENT_CONF $HTGT_MIGRATION_NFS_ROOT/config/lims2-rest-client.conf
    check_and_set_dir NFS_GLOBAL_SYNTHVEC_DATADIR $HTGT_MIGRATION_NFS_ROOT/data/mutant_sequences
    check_and_set NFS_ENG_SEQ_BUILDER_CONF $HTGT_MIGRATION_NFS_ROOT/config/eng-seq-builder.yaml
    # data file locations all depend on HTGT_MIGRATION_ROOT
    check_and_set_dir GLOBAL_SYNTHVEC_DATADIR $HTGT_MIGRATION_ROOT/data/mutant_sequences
    # Oracle setup
    export LD_LIBRARY_PATH=
    export CLASSPATH=
    export ORACLE_HOME=/software/oracle-ic-11.2
    export CLASSPATH=$CLASSPATH:${ORACLE_HOME}/ojdbc14.jar:./
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${ORACLE_HOME}
    export PATH=$PATH:${ORACLE_HOME}
    export PERL5LIB=$PERL5LIB:${ORACLE_HOME}/lib/perl5
#export PERL5LIB=$PERL5LIB:${ORACLE_HOME}/lib/perl5:/nfs/WWWdev/SHARED_docs/lib/core
    # HTTP API to file system
    export FILE_API_URL=http://t87-batch-farm3.internal.sanger.ac.uk:3000/

    # Location of LIMS2 managed sequencing files for use in QC
    export LIMS2_SEQ_FILE_DIR=/warehouse/team229_wh01/lims2_managed_sequencing_data

# Sanger authorisation
    export PERL5LIB=$PERL5LIB:/nfs/WWWdev/SHARED_docs/lib/core:/nfs/WWWdev/SANGER_docs/perl:/nfs/WWWdev/SANGER_docs/bin-offline:/nfs/WWWdev/INTWEB_docs/lib/badger:/nfs/WWWdev/CCC_docs/lib/:/software/badger/lib/perl5
    export LSB_DEFAULTGROUP=team87-grp

    set_batch_paths
}

# These are required to avoid Datetime column inflation issues in DBIx::Class
export NLS_DATE_FORMAT=DD-MON-RR
export NLS_TIMESTAMP_FORMAT='YYYY-MM-DD HH24:MI:SSXFF'
export NLS_TIMESTAMP_TZ_FORMAT='YYYY-MM-DD HH24:MI:SSXFFTZD'

export ORA_NLS11=${ORACLE_HOME}/nls/data


if [[ -z ${TNS_ADMIN} ]]
then
    export TNS_ADMIN=/etc
fi

export EDITOR=/usr/bin/vim
export VISUAL=$EDITOR

# Other HTGT local setup not dependent on HTGT_MIGRATION_ROOT
# Don't put anything here that depends on HTGT_MIGRATION_ROOT as the sumbols
# will not be reset when user switches between live and devel environments
export HTGT_CACHE_ROOT=/var/tmp/htgt-cache.$USER
export HTGT_ENSEMBL_HOST=ensembldb.ensembl.org
export HTGT_ENSEMBL_USER=anonymous
export HTGT_SUBMITQC_FORCE_RUN=
export HTGT_WEBAPP_SERVER_OPTIONS="-d"
export HTGT_WEBAPP_SERVER_PORT=3131

# These are the *really* important symbols...
export HTGT_DEVEL_DEPLOYMENT_ROOT=/htgt/devel/current
export HTGT_LIVE_DEPLOYMENT_ROOT=/htgt/live/current

export HTGT_DEBUG_DEFINITION="perl -d"

function set_colour_ls {
#
# Directory colouring:
#
LS_COLORS='rs=0:di=01;34:ln=01;36:mh=00:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:su=37;41:sg=30;43:ca=30;41:tw=30;42:ow=34;42:st=37;44:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.lzma=01;31:*.tlz=01;31:*.txz=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.dz=01;31:*.gz=01;31:*.lz=01;31:*.xz=01;31:*.bz2=01;31:*.bz=01;31:*.tbz=01;31:*.tbz2=01;31:*.tz=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.war=01;31:*.ear=01;31:*.sar=01;31:*.rar=01;31:*.ace=01;31:*.zoo=01;31:*.cpio=01;31:*.7z=01;31:*.rz=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.svg=01;35:*.svgz=01;35:*.mng=01;35:*.pcx=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.m2v=01;35:*.mkv=01;35:*.webm=01;35:*.ogm=01;35:*.mp4=01;35:*.m4v=01;35:*.mp4v=01;35:*.vob=01;35:*.qt=01;35:*.nuv=01;35:*.wmv=01;35:*.asf=01;35:*.rm=01;35:*.rmvb=01;35:*.flc=01;35:*.avi=01;35:*.fli=01;35:*.flv=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.yuv=01;35:*.cgm=01;35:*.emf=01;35:*.axv=01;35:*.anx=01;35:*.ogv=01;35:*.ogx=01;35:*.aac=00;36:*.au=00;36:*.flac=00;36:*.mid=00;36:*.midi=00;36:*.mka=00;36:*.mp3=00;36:*.mpc=00;36:*.ogg=00;36:*.ra=00;36:*.wav=00;36:*.axa=00;36:*.oga=00;36:*.spx=00;36:*.xspf=00;36:';
export LS_COLORS
alias ls='ls -FqC --color'
}

function set_mono_ls {
#
# Directory colouring:
#
unset LS_COLORS
alias ls='ls -FqC'
}

export KERMITS_DB=external_mi_esmt

printf "Environment setup for htgt2. Type help_htgt for help on commands.\n"
if [[ -f $HOME/.htgt_local ]] ; then
    printf "Sourcing local mods to htgt2 environment\n"
    source $HOME/.htgt_local
fi

function init_interactive_developer {
# This runs at first startup, so check the saved dev root and transfer to htgt_dev_root so that
# we start in the correct dev location
if [[ ( -z "$HTGT_DEV_ROOT" ) && (! -z "$SAVED_HTGT_DEV_ROOT" )]] ; then
    export HTGT_DEV_ROOT=$SAVED_HTGT_DEV_ROOT
fi

if [[ -z "$HTGT_DEV_ROOT" ]] ; then
    printf "WARNING: you have not set HTGT_DEV_ROOT to the root of your checkout\n"
    if [[ (-d htgt_app ) && ( -d perl5 ) && ( -d htgt_batch ) ]] ; then
        printf "==> you appear to have a valid checkout to run the webserver and batch in this directory\n"
        printf "==> setting HTGT_DEV_ROOT to the current directory\n"
        export HTGT_DEV_ROOT=`pwd`
    else
        printf "WARNING: setting HTGT_DEV_ROOT to \$HTGT_DEVEL_DEPLOYMENT_ROOT: $HTGT_DEVEL_DEPLOYMENT_ROOT\n"
        printf "WARNING: this is almost certainly not what you want... but at least its not live\n"
        export HTGT_DEV_ROOT="$HTGT_DEVEL_DEPLOYMENT_ROOT"
    fi
fi
}

if [[ ! $HOSTNAME =~ farm3-head ]] ; then
    init_interactive_developer
else
    printf "Setting up for batch session on $HOSTNAME\n"
fi
devel_or_live
set_prompt

