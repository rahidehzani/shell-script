#!/bin/bash
set -u
################################################################################
# Author:       Rahi Dehzani <r.dehzani@gmail.ir>
# Description:  Directory disk usage watcher/limiter.
# Date:         06.26.2016
################################################################################
location=`pwd`;
################################################################################
checkRoot() {
    if ! [ $(id -u) = 0 ]; then
       echo "You are using a non-privileged account!" 1>&2
       exit 1
    fi
}
 
showHelp() {
cat << EOF
Directory disk usage watcher/limiter.
It will delete files from target directory and its sub-directory until usage
is within limit of max_usage.
 
Usage:  ${0##*/} [options] max_usage
        ${0##*/} -h
 
options:
 
    -l          Directory location
    -h          display this help and exit
 
max_usage unit is MegaByte (1024*1024 Byte)
EOF
}
 
getOptions() {
    OPTIND=1
    while getopts "l:h" opt; do
        case "${opt}" in
            l)
                location=$OPTARG
                ;;
            h)
                showHelp
                exit 0
                ;;
            '?')
                showHelp >&2
                exit 1
                ;;
        esac
    done
    shift "$((OPTIND-1))"
 
    if [ ${##@} = 1 ]; then
        maxUsage=$@
        maxUsage=$(($maxUsage * 1024))
    else
        showHelp
        exit 1
    fi
}
################################################################################
checkUsage() {
    usage=`du -s $location | awk  '{print $1;}'`
    if [ ! "$?" == "0" ]    
    then
        echo "Error: $location not found."
        exit 1
    fi
 
    if [ -z "$usage" ]
    then
        echo "Didn't get usage information of $location"
        echo "location does not exist"
        exit 1
    fi
 
    if [ "$usage" -gt "$maxUsage" ]
    then
        return 0
    else
        return 1
    fi
}
 
processFile() {
    f="$1"
 
    echo "   - Deleting $f"
    rm -f "$f"
}
 
doLimit() {
    if checkUsage
    then
        echo -n "* Usage of $usage exceeded limit ${maxUsage}KiB."
        echo " [$((100*$usage/$maxUsage))%]"
        echo "* start processing..."
    else
        return
    fi
 
    fileList=`find "$location" -type f | sort -n`
 
    for f in $fileList
    do
        if checkUsage
        then
            if [ -e "$f" ]
            then
                processFile "$f"
            fi
        else
            break;
        fi
    done
}
################################################################################
checkRoot
getOptions $@
 
doLimit
 
echo -n "* Usage of $usage is within limit ${maxUsage}KiB."
echo " [$((100*$usage/$maxUsage))%]"
 
exit 0
################################################################################
