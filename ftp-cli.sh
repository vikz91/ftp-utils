#!/bin/sh
#================================================================
# HEADER
#================================================================
#% SYNOPSIS
#+    ./ftp-util.sh <command> [...arg1, ...arg2]
#%
#% DESCRIPTION
#%    FTP utils to make managing 
#%    ftp accounts easier.
#%
#% Commands
#%    add <username> <password>     Creates <username>  user and 
#%                                  adds to ftp list
#%    del <username>                Deletes <username> from home
#%                                  and ftp list
#%    list                          Lists all ftp users
#%    cleanall  [--expiredDay]      Deletes all files after 
#%                                  <expiredDay> days for all 
#%                                  registered users. Default 
#%                                  <expiredDay> value is 2 days  
#%    cleanuser <user> <expired>    Deletes <user>'s files 
#%                                  after <expired> days 
#%    cleanall <dir> <expired>      Deletes <dir>'s files 
#%                                  after <expired> days 
#%    help                          This help
#% EXAMPLES
#%    ./ftp-util.sh add user1 p@$$|w|0r|)
#%
#================================================================
#- IMPLEMENTATION
#-    version         v0.1.1
#-    author          Abhishek Deb
#-    copyright       Copyright (c) Abhishek Deb
#-    license         MIT
#-    script_id       12345
#-
#================================================================
#  HISTORY
#     2021/03/25 : vikz91 : Script creation
# 
#================================================================
#  DEBUG OPTION
#    set -n  # Uncomment to check your syntax, without execution.
#    set -x  # Uncomment to debug this shell script
#
#================================================================
# END_OF_HEADER
#================================================================



DEFAULT_EXPIRED_DAYS=2
FTP_USER_LIST=/etc/vsftpd.userlist

function Help(){
    cat << EOF
    [ ftp-cli v0.1.1 ]
    @Author : Abhishek Deb

    usage:
    ftp-cli help
    ftp-cli add <username> <password>
    ftp-cli del <username>
    ftp-cli list
    ftp-cli cleanraw <directory> <expired days>
    ftp-cli cleanuser <username> <expired days>
    ftp-cli cleanall [...<expired days>, default is 2]

    Report bugs to:
    up home page:
EOF
}

function CreateUser() {
    USER=$1
    PASS=$2

    echo "Adding User ..."
    adduser --gecos "" --disabled-password $USER
    chpasswd <<<"$USER:$PASS"


    echo "Adding Directories ..."
    sudo mkdir /home/$USER/ftp
    sudo chown nobody:nogroup /home/$USER/ftp
    sudo chmod a-w /home/$USER/ftp


    sudo mkdir /home/$USER/ftp/files
    sudo chown $USER:$USER /home/$USER/ftp/files

    sudo ls -la /home/$USER/ftp


    echo "$USER" | sudo tee -a $FTP_USER_LIST

    echo "Restarting FTP service ..."
    systemctl restart vsftpd

    echo "user $USER added to FTP service (/home/$USER/ftp/files)."
}

function DeleteUser() {
    USER=$1
    echo "Deleting User $USER..."

    deluser --remove-home  $USER
    sed -i "/$USER/d" $FTP_USER_LIST
    echo "user $USER deleted from FTP service."
}

function ListUsers(){
    cat $FTP_USER_LIST
}

function CleanOldFilesRaw(){
    DIR=$1
    ExpiredDays=${2:-$DEFAULT_EXPIRED_DAYS}

    echo "Starting Old Files CleanUp in $DIR ..."
    find $DIR* -mtime +$ExpiredDays -exec rm {} \;
    echo "Completed Old Files CleanUp ..."
}

function CleanOldFilesUser(){
    USER=$1

    DIR=/home/$USER/ftp/files
    ExpiredDays=${2:-$DEFAULT_EXPIRED_DAYS}

    CleanOldFilesRaw $USER $ExpiredDays
}

function CleanOldFilesUserAll(){
    ExpiredDays=${1:-$DEFAULT_EXPIRED_DAYS}
    while read line; do
    if [ ! -z "$line" ]; then
        CURRENT_FTP_DIR="/home/$line/ftp/files"
        echo "→ Scanning $CURRENT_FTP_DIR ..."
        CleanOldFilesRaw "$CURRENT_FTP_DIR/" $ExpiredDays
    fi
    done < $FTP_USER_LIST
}

function MenuExecutor(){
    COMMAND=$1
    ARG1=$2
    ARG2=$3

    echo "cmd: ftp-cli $COMMAND $ARG1 $ARG2"

    case $COMMAND in

    help)
        Help
        ;;

    add)
        CreateUser $ARG1 $ARG2
        ;;

    del)
        DeleteUser $ARG1
        ;;

    list)
        ListUsers
        ;;
    cleanraw)
        CleanOldFilesRaw $ARG1 $ARG2
        ;;

    cleanuser)
        CleanOldFilesUser $ARG1 $ARG2
        ;;

    cleanall)
        CleanOldFilesUserAll
        ;;

    *)
        Help
        ;;
    esac
}

MenuExecutor $1 $2 $3