#! /bin/bash

function htgt {
    if [[ ! "$1" ]] ; then
        htgt_help
    elif [[ $1 == "esmp" ]] ; then
        esmp
    elif [[ $1 == "esmt" ]] ; then
        esmt
    elif [[ ( $1 == "production" ) || ( $1 == "live" ) ]] ; then
        production_htgt
    elif [[ $1 == "devel" ]] ; then
        devel_htgt $2
    elif [[ $1 == "webapp" ]] ; then
        htgt_webapp $2
    elif [[ $1 == "debug" ]] ; then
        htgt_debug $2
    elif [[ $1 == "help" ]] ; then
        htgt_help
    elif [[ $1 == "show" ]] ; then
        htgt_show
    elif [[ $1 == "cpanm" ]] ; then
        htgt_cpanm $1
    else 
        printf "ERROR: unrecongnized htgt command\n"
    fi


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
    synthesize_htgt_db
    set_prompt
}

function esmt {
    export HTGT_SHORT_DB=esmt
    synthesize_htgt_db
    set_prompt
}

function synthesize_htgt_db {
    export HTGT_DB=eucomm_vector_$HTGT_SHORT_DB
}

function devel_or_live {
# Check for the HTGT_DEV_ROOT variable setting and use that for HTGT_MIGRATION_ROOT, otherwise
# use the standard lcoation
    if [[ ( "$HTGT_DEV_ROOT" ) && ( -d "$HTGT_DEV_ROOT" ) ]] ; then
        export HTGT_MIGRATION_ROOT=$HTGT_DEV_ROOT
        export HTGT_SHARED=$HTGT_DEV_ROOT
        export HTGT_ENV=Devel
        esmt
    else
        export HTGT_MIGRATION_ROOT=/htgt/live/current
        export HTGT_SHARED=/htgt/live/current
        export HTGT_ENV=Live
        esmp
    fi
    set_htgt_paths
}

function production_htgt {
    export SAVED_HTGT_DEV_ROOT="$HTGT_DEV_ROOT"
    unset HTGT_DEV_ROOT
    printf "==> saved your HTGT_DEV_ROOT setting, use 'devel_htgt' command to switch back.\n"
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

    webapp       - starts the webapp server on the default port, or the port sepecified in
                 \$HTGT_WEBAPP_SERVER_PORT with the options specified in
                 \$HTGT_WEBAPP_SERVER_OPTIONS (-d, -r etc as desired)

    webapp <port_num> - starts the webapp server on the specified port, overriding the value
                 specified by \$HTGT_WEBAPP_SERVER_PORT (default $HTGT_WEBAPP_SERVER_PORT)

    debug        - starts the server using 'perl -d '
    show         - show the value of useful HTGT variables
    cpanm        - installs a CPAN module to the correct lib location

    set_colour_prompt - use colours in the prompt and in directory listings
    set_mono_prompt   - don't use any colour in prompt or directory listings
    help         - displays this help message
Files:
    ~/.htgt_local     - sourced near the end of the setup phase for you own mods
END
}

function htgt_help {
    printf "Perhaps you meant 'help_htgt'...\n\n"
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

\$PERL5LIB :
`perl -e 'print( join("\n", split(":", $ENV{PERL5LIB}))."\n")'`

\$PATH :
`perl -e 'print( join("\n", split(":", $ENV{PATH}))."\n")'`

\$HTGT_DBCONNECT  : $HTGT_DBCONNECT
\$HTGT_DB         : $HTGT_DB
\$HTGT_SHORT DB   : $HTGT_SHORT_DB
\$HTGT_ENV        : $HTGT_ENV
END
}

function show_htgt {
    htgt_show
}

function htgt_cpanm {
    if [[ "$1" ]] ; then
        $HTGT_MIGRATION_ROOT/bin/cpanm -l $HTGT_MIGRATION_ROOT/perl5 $1
    else
        printf "ERROR: no module specified: htgt_cpanm <module>"
    fi
}

function perlmodver () {
        test -n "$1" || { echo 'Usage: perlmodver MODULE' >&2; return; }
        perl -m"$1" -le 'print $ARGV[0]->VERSION' "$1"
}

function perlmodpath () {
        test -n "$1" || { echo 'Usage: perlmodpath MODULE' >&2; return; }
        perl -m"$1" -le '$ARGV[0]=~s/::/\//g; print $INC{"$ARGV[0].pm"}' "$1"
}


LSB_DEFAULTGROUP=team87-grp

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
    export PERL5LIB="$PERL5LIB:/software/pubseq/PerlModules/Ensembl/www_72_1/ensembl/modules:/software/pubseq/PerlModules/Ensembl/www_72_1/ensembl-compara/modules"
    # config file locations all depend on HTGT_MIGRATION_ROOT
    export HTGT_DBCONNECT=$HTGT_MIGRATION_ROOT/config/dbconnect.cfg
    export HTGT_QC_CONF=$HTGT_MIGRATION_ROOT/config/qc.conf
    export HTGT_QC_DIST_LOGIC_CONF=$HTGT_MIGRATION_ROOT/config/qc-dist-logic.conf
#source /software/oracle-ic-11.2/etc/profile.oracle-ic-11.2
# Oracle setup copied from the above because I can't locate append_path function
    export LD_LIBRARY_PATH=
    export CLASSPATH=
    export ORACLE_HOME=/software/oracle-ic-11.2
    export CLASSPATH=$CLASSPATH:${ORACLE_HOME}/ojdbc14.jar:./
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${ORACLE_HOME}
    export PATH=$PATH:${ORACLE_HOME}
    export PERL5LIB=$PERL5LIB:${ORACLE_HOME}/lib/perl5
#export PERL5LIB=$PERL5LIB:${ORACLE_HOME}/lib/perl5:/nfs/WWWdev/SHARED_docs/lib/core

# Sanger authorisation
    export PERL5LIB=$PERL5LIB:/nfs/WWWdev/SHARED_docs/lib/core:/nfs/WWWdev/SANGER_docs/perl:/nfs/WWWdev/SANGER_docs/bin-offline:/nfs/WWWdev/INTWEB_docs/lib/badger:/nfs/WWWdev/CCC_docs/lib/:/software/badger/lib/perl5

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

export KERMITS_DB=external_mi_esmt
export VECTOR_QC_DB=vector_qc_esmt

printf "Environment setup for htgt2. Type help_htgt for help on commands.\n"
if [[ -f $HOME/.htgt_local ]] ; then
    printf "Sourcing local mods to htgt2 environment\n"
    source $HOME/.htgt_local
fi

# This runs at first startup, so check the saved deve root and transfer to htgt_dev_root so that
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
devel_or_live
set_prompt

