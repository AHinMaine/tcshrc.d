#!/bin/sh
#
# Script for distributing tcsh configuration files to other
# hosts automatically via ssh.
#
# Run with no options, the script will look for destination
# hosts by simply looking for filenames in the directory
# $TCSHDIR/etc/.disthosts where the filename is actually
# used for the hostname.  Create using:
#
# touch ${TCSHDIR}/etc/.disthosts/user@server1.example.com
#
# You can override this by specifying destination hostnames
# with -H.
#
# And no, this script is not written in tcsh, nor should be
# any script worth writing.  It's just a great shell with
# better implementations of my favorite shell features than
# in others.
#

TCSHDIR="${HOME}/.tcshrc.d"

_DEFAULT_TAR_EXCLUDES="--exclude-vcs --exclude-backups --exclude=*.swp"

show_help() {

cat <<SHOWHELP

    `basename $0`

        -f      <filename or dirname>
                Filename to distribute.  The default is .tcshrc and .tcshrc.d.
                Wildcards are supported, but your shell's quoting rules apply.
                Multiple -f options are accepted.

        -l      Just prints a list of the destination hostnames.
                Use if you just want to sanity check your resulting list of 
                destination hosts.

        -L      Just prints a list of the default filenames to share
                Use if you just want to sanity check your resulting list of 
                files to be transferred.

        -H      <hostname>
                Destination hostname(s) to distribute files.
                Multiple -H options are accepted.

        -d      <directory>
                Destination (target) directory to distribute files.
                Default is your home directory and you can specify a
                path relative to your home directory.
                Only one destination option accepted.

        -x      <pattern>
                Add additional filename exclusions to the defaults.  Standard
                filename globbing patterns allowed.

        -r      <hostname>
                Relay host.  An intermediary ssh host in which to tunnel 
                through first.

        -n      Assume 'no' to all the host skipping prompts.  (Using -H 
                supresses this anyway...)


SHOWHELP

}

while getopts f:H:d:Llr:x:nRNDhV ARGS
    do
        case ${ARGS} in
            x)  _EXCLUDES="${_EXCLUDES}${OPTARG:+ --exclude=}${OPTARG}" ;;
            H)  TARGETHOSTS="${TARGETHOSTS}${OPTARG:+ }${OPTARG}"       ;;
            f)  FILESPEC="${FILESPEC}${OPTARG:+ }${OPTARG}"             ;;
            r)  RELAYHOST="${OPTARG}"                                   ;;
            d)  _DESTDIR="${OPTARG}"                                    ;;
            l)  SHOWLIST="TRUE"                                         ;;
            L)  SHOWFILES="TRUE"                                        ;;
            n)  NO_SKIP="TRUE"                                          ;;
            N)  TESTONLY="TRUE"                                         ;;
            R)  RM_FIRST="TRUE"                                         ;;
            V)  VERBOSE="TRUE"                                          ;;
            D)  DEBUG="TRUE"                                            ;;
            h)  show_help && exit 0                                     ;;
           \?)  show_help && exit 1                                     ;;
        esac
    done ; shift `expr ${OPTIND} - 1`


# Extra exludes are added to the defaults, rather than
# replacing the defaults.
#
TAR_EXCLUDES="${_DEFAULT_TAR_EXCLUDES}${_EXCLUDES:+ }${_EXCLUDES}"



[ -n "${DEBUG}" ] && echo "Enabling debug mode" && set -x


if [ -d "${HOME}" -a -w "${HOME}" ] ; then
    pushd ${HOME} > /dev/null 2>&1
else
    echo "Problem with home directory: ${HOME}"
    exit 1
fi

FILESPEC="${FILESPEC:-.tcshrc .tcshrc.d}"

[ -n "${VERBOSE}" ] && 
    echo "File specification for distribution: ${FILESPEC}" && echo


if [ -n "${TARGETHOSTS}" ] ; then
    NO_SKIP="TRUE"
    _DESTINATIONS="${TARGETHOSTS}"
else

    # Look for destination hosts
    #
    _DISTHOSTS="${TCSHDIR}/etc/.disthosts"
    if [ -d "${_DISTHOSTS}" ] ; then
        pushd ${_DISTHOSTS} > /dev/null 2>&1
        ALLHOSTS="`ls -1 * 2> /dev/null`"
        popd > /dev/null 2>&1
    fi

    if [ -n "${ALLHOSTS}" ] ; then
        _DESTINATIONS="${ALLHOSTS}"
    fi

fi

if [ -z "${_DESTINATIONS}" ] ; then
    echo "No hosts for distribution!"
    popd > /dev/null 2>&1
    exit 1
fi

if [ -n "${SHOWLIST}" ] ; then
    for DESTHOST in ${_DESTINATIONS} ; do
        echo ${DESTHOST}
    done
    popd > /dev/null 2>&1
    exit
fi


if [ -n "${SHOWFILES}" ] ; then

    # Using tar itself to show what files would be
    # transferred in the tar tunnel through ssh.
    #
    tar cf - ${FILESPEC} ${TAR_EXCLUDES} | tar t${VERBOSE:+v}f - | ${PAGER:-less}
    popd > /dev/null 2>&1
    exit

fi


echo

# Leaving this an undocumentation feature for now since it's
# very very dangerous if used improperly...
#
if [ -n "${RM_FIRST}" ] ; then

    echo "removal command for file specification:"
    echo "rm -rf ${FILESPEC}"
    echo
    echo -n "Abort removal option? [y/N] "
    read CHOICE

    if [ "${CHOICE}" = "y" ] ; then
        RM_FIRST=
    else
        RM_CMD="rm -rf ${FILESPEC}"
    fi

fi


# Start iterating our destination hosts and copying the tcsh
# configs by piping tar through ssh.
#
for DESTHOST in ${_DESTINATIONS} ; do

    echo
    echo "Current destination host: ${DESTHOST}"

    if [ -z "${NO_SKIP}" ] ; then
        echo -n "Skip this host? [y/N] "
        read CHOICE
        if [ "${CHOICE}" = "y" ] ; then
            continue
        fi
        if [ "${CHOICE}" = "q" ] ; then
            break
        fi
    fi

    if [ -z "${_DESTDIR}" ] ; then
        _DESTDIR="\${HOME}"
    fi

    [ -n "${VERBOSE}" ] &&
        echo "FILESPEC = " &&
        echo ${FILESPEC} | xargs echo -n filenames: &&
cat <<ENDVERBOSE

        tar c${VERBOSE:+v}f - ${FILESPEC} ${TAR_EXCLUDES} | ssh -x -o ConnectTimeout=30 ${RELAYHOST:+ -t }${RELAYHOST}${RELAYHOST:+ ssh -x} $DESTHOST "${_DESTDIR:+ cd ${_DESTDIR} ; }${RM_CMD}${RM_CMD:+ ; }tar x${VERBOSE:+v}fBp -" > /dev/null 2>&1

ENDVERBOSE

    [ -z "${TESTONLY}" ] &&
        tar c${VERBOSE:+v}f - ${FILESPEC} ${TAR_EXCLUDES} | ssh -x -o ConnectTimeout=30 ${RELAYHOST:+ -t }${RELAYHOST}${RELAYHOST:+ ssh -x} $DESTHOST "${_DESTDIR:+ cd ${_DESTDIR} ; }${RM_CMD}${RM_CMD:+ ; }tar x${VERBOSE:+v}fBp -" > /dev/null 2>&1

    RESULT=$?

    if [ $RESULT -gt 0 ] ; then
        echo "Error! Exit status: ${RESULT}"
        echo
    fi

done

popd > /dev/null 2>&1

