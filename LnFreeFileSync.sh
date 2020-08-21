#!/bin/bash

#############################
function ctrl_c() {
    echo "** Trapped CTRL-C"
    rCode=1
    exit 1
}

# trap ctrl-c and call ctrl_c()
trap ctrl_c INT
#############################





function prepareTemplate {
    # set -x
    dirName=$1
    local workingProfile=$profileDir/dynProfile/${dirName}.ffs_gui

    if [ ! -s $profileTemplate ]; then
        echo "file "$profileTemplate" doesn't exists or its size is zero..."
        exit 2
    fi

    # default convertion WLS path to Windows path. Will be overridden if necessary.
    _sourceDir=$(wslpath -m -a "$SourceDIR/$dirName")
    _destDir=$(wslpath -m -a "$DestDIR/$dirName")
    _variant='<Variant>TwoWay</Variant>'
    # sftpServer=""
    # OPTIONS=""
    _include='<Include><Item>*</Item></Include>'

    case $dirName in
        'PI_etc')
            _sourceDir="/etc"
            _destDir=$(wslpath -m -a "$DestDIR/etc")
            _exclude='<Exclude>
                        <Item>*.tmp|*.bak</Item>
                        <Item>*\thumbs.db</Item>
                        <Item>*.log|*.log.?|*.log.1?</Item>
                        <Item>*.cache|*.log|*_tmp|*.pid|</Item>
                        <Item>*\cache\</Item>
                        <Item>*\cache2\</Item>
                        <Item>*\log\</Item>
                        <Item>*\tmp\</Item>
                        <Item>*\ssh\ssh_host_dsa_key</Item>
                        <Item>*\ssh\ssh_host_ecdsa_key</Item>
                        <Item>*\ssh\ssh_host_ed25519_key</Item>
                        <Item>*\ssh\ssh_host_rsa_key</Item>
                    </Exclude>'
            _include='<Include>
                        <Item>/apt/</Item>
                        <Item>/cron.d/</Item>
                        <Item>/cron.daily/</Item>
                        <Item>/cron.daily/</Item>
                        <Item>/dhcp/</Item>
                        <Item>/fstab</Item>
                        <Item>/hosts</Item>
                        <Item>/init.d/</Item>
                        <Item>/iproute2/</Item>
                        <Item>/minidlna.conf</Item>
                        <Item>/mosquitto/</Item>
                        <Item>/network/</Item>
                        <Item>/samba/</Item>
                        <Item>/ssh/</Item>
                        <Item>/vim/</Item>
                        <Item>/wpa_supplicant/</Item>
                        <Item>/udev/</Item>
                    </Include>'
            ;;

        'PI_home')
            _sourceDir="/home/pi"
            _destDir=$(wslpath -m -a "$DestDIR/home/pi")
            _include='<Include>
                        <Item>/GIT-REPO/</Item>
                        <Item>/PiProd/</Item>
                        <Item>/PiColl/</Item>
                        <Item>/.aMule/</Item>
                        <Item>/.ssh</Item>
                        <Item>/.Loreto</Item>
                        <Item>/.bash_aliases</Item>
                        <Item>/.gitconfig</Item>
                        <Item>/.vimrc</Item>
                    </Include>'
            _exclude='<Exclude>
                        <Item>*.tmp| *.bak</Item>
                        <Item>*\.git\</Item>
                        <Item>*\thumbs.db</Item>
                        <Item>*.log|*.log.?|*.log.1?</Item>
                        <Item>*.cache|*.log|*_tmp|*.pid|</Item>
                        <Item>*\cache\</Item>
                        <Item>*\cache2\</Item>
                        <Item>*\log\</Item>
                        <Item>*\tmp\</Item>
                        <Item>*\.git\</Item>
                        <Item>/GIT-REPO/</Item>
                    </Exclude>'
            ;;

        'LnFree')
            _exclude='<Exclude>
                        <Item>\System Volume Information\</Item>
                        <Item>\$Recycle.Bin\</Item>
                        <Item>\RECYCLER\</Item>
                        <Item>\RECYCLED\</Item>
                        <Item>*\desktop.ini</Item>
                        <Item>*\thumbs.db</Item>
                        <Item>*_tmp|*\tmp\|*.pid|*.bak|</Item>
                        <Item>*.log|*.log.?|*.log.1?|*\log\|</Item>
                        <Item>*.cache|*\cache.*|*\cache2\|*\cache\|</Item>
                        <Item>*\DoubleCmd\doublecmd.xml</Item>
                        <Item>*\DoubleCmd\history.xml</Item>
                        <Item>*\DoubleCmd\session.ini</Item>
                        <Item>*\Editors\SublimeText_3\Data\Local</Item>
                        <Item>*\Executor\scancache.dat</Item>
                        <Item>*\Kitty\Launcher\*</Item>
                        <Item>*\Network\Browser\Opera_XXXX</Item>
                        <Item>*\SublimeText\Data\Backup\*</Item>
                        <Item>*\SublimeText\Data\Index\*</Item>
                        <Item>*\SynchBackup\FreeFileSync\_LnProfiles\dynProfile</Item>
                        <Item>*\uninstall.exe</Item>
                        <Item>*\uninstall.bmp</Item>
                    </Exclude>'
            ;;

        *)
            _exclude='<Exclude>
                        <Item>\System Volume Information\</Item>
                        <Item>\$Recycle.Bin\</Item>
                        <Item>\RECYCLER\</Item>
                        <Item>\RECYCLED\</Item>
                        <Item>*\desktop.ini</Item>
                        <Item>*\thumbs.db</Item>
                        <Item>*_tmp|*\tmp\|*.pid|*.bak|</Item>
                        <Item>*.log|*.log.?|*.log.1?|*\log\|</Item>
                        <Item>*.cache|*\cache.*|*\cache2\|*\cache\|</Item>
                        <Item>*\.git\</Item>
                    </Exclude>'
            ;; # default...
    esac

    # change strings
    /usr/bin/python3 "$thisDir/replaceinFile.py" --in "$profileTemplate" --out "$workingProfile"\
        --old-string "%SourceDIR%" "%DestDIR%" "%sftpServer%" "%OPTIONS%" '<Include><Item>*</Item></Include>' '<Exclude><Item>*</Item></Exclude>'  '<Variant>Mirror</Variant>' \
        --new-string "$_sourceDir" "$_destDir" "$sftpServer"  "$OPTIONS"  "$_include"                          "$_exclude"                            "$_variant"

    # read
    # set -x
    file=$(wslpath -m -a "$workingProfile")
    if [ -z "$all_profiles" ]; then
        all_profiles="$file"
    else
        all_profiles="$all_profiles $file"
    fi
}


########################
#   M y   L n D i s k
########################
function process_LnDisk {
    sftpServer=""
    OPTIONS=""
    LnSrc_RootDir='/mnt/k/Filu'
    LnDst_RootDir='/mnt/d/Filu'
    LnDst_RootDir='/mnt/c/Filu_C'

    profileTemplate="$thisDir/_LnProfiles/Main/@LnTemplate.ffs_gui"

    SourceDIR="$LnSrc_RootDir/LnDisk"
    DestDIR="$LnDst_RootDir/Lndisk"
    displayVars

    all_profiles=''
    prepareTemplate GIT-REPO
    prepareTemplate Technical-DOC
    prepareTemplate Ln-eBooks
    # prepareTemplate Ln-AudioBooks
    prepareTemplate LnSite
    prepareTemplate LnStart
    prepareTemplate LnFree
    prepareTemplate Loreto
    prepareTemplate Lesla
    prepareTemplate LnPi
    prepareTemplate PortableApps

    # Loreto e Lesla sono stati spostati sullo zip con psw
}



########################
#   M y   D A T A
########################
function process_MyData {
    sftpServer=""
    OPTIONS=""
    LnSrc_RootDir='/mnt/k/Filu'
    LnDst_RootDir='/mnt/d/Filu'
    LnDst_RootDir='/mnt/c/Filu_C'

    profileTemplate="$thisDir/_LnProfiles/Main/@LnTemplate.ffs_gui"

    SourceDIR="$LnSrc_RootDir/MyData"
    DestDIR="$LnDst_RootDir/MyData"
    displayVars

    # set -x
    all_profiles=''
    prepareTemplate Photos
    prepareTemplate MP3
    prepareTemplate Movies
    prepareTemplate LnProducts
    prepareTemplate BdI

}


########################
#   LnPi23
########################
function process_LnPi23 {
    sftpServer=sftp://pi@192.168.1.23:22
    OPTIONS="|chan=10|agent"

    profileTemplate="$thisDir/_LnProfiles/Main/@LnTemplate.ffs_gui"

    SourceDIR="/"
    DestDIR="/mnt/k/Filu/LnDisk/LnPi/LnPi23_BACKUP_2019-09"


    if [ ! -d $DestDIR ]; then
        echo "creating directory: $DestDIR"
        mkdir $DestDIR
    fi

    displayVars
    all_profiles=""

    prepareTemplate PI_etc
    prepareTemplate PI_home
}




########################
#   UserProfile
########################
function process_UserProfile {
    sftpServer=""
    OPTIONS=""
    SourceDIR='/mnt/c/Users/Loreto'
    DestDIR='/mnt/k/Filu/LnDisk/LnFree/_LnPortable/UserProfileSavedData'

    profileTemplate="$thisDir/_LnProfiles/Main/@LnTemplate.ffs_gui"

    displayVars

    # set -x
    all_profiles=''
    prepareTemplate .platformio

}


########################
#   LnPi31
########################
function process_LnPi31 {
    sftpServer=sftp://pi@192.168.1.31:22
    OPTIONS="|chan=10|agent"

    profileTemplate="$thisDir/_LnProfiles/Main/@LnTemplate.ffs_gui"

    SourceDIR="/"
    DestDIR="/mnt/k/Filu/LnDisk/LnPi/LnPi31_BACKUP_2020-06"


    if [ ! -d $DestDIR ]; then
        echo "creating directory: $DestDIR"
        mkdir $DestDIR
    fi

    displayVars
    all_profiles=""
    # set -x
    prepareTemplate PI_etc
    prepareTemplate PI_home

}




########################
#
########################
function Execute {
    # set -x
    cp $GlobalConfigFile_base $GlobalConfigFile
    if [ $? -ne 0 ]; then
        echo "ERROR creating file..."
        exit 1
    fi
    local config_file=$(wslpath -m -a "$GlobalConfigFile")

    Comando="\"$EXE_File\" $* $config_file"
    echo $Comando
    eval $Comando
    echo "$TAB RCODE=$?"
}


###############################
# get Windows variable value
###############################
function getwinvar() { # definita anche in $HOME/.Loreto
    local varname=$1
    local win_var_value=$(cmd.exe /C echo "%${varname}%"|tr -d '\r')
    # wslpath syntax
    #   -a    force result to absolute path format
    #   -u    translate from a Windows path to a WSL path (default)
    #   -w    translate from a WSL path to a Windows path
    #   -m    translate from a WSL path to a Windows path, with ‘/’ instead of ‘\\’
    lnx_var_value=$(wslpath -u -a "$win_var_value")
    echo $lnx_var_value
}


function displayVars() {
    echo "------------ DISPLAY -------------"
    echo "$TAB profileDir:                 $profileDir"
    echo "$TAB EXE_File:                   $EXE_File"
    echo "$TAB Source:                     $SourceDIR"
    echo "$TAB Destination:                $DestDIR"
    echo "$TAB APPDATA:                    $APPDATA"
    echo "$TAB GlobalConfigFile_base:      $GlobalConfigFile_base"
    echo "$TAB GlobalConfigFile:           $GlobalConfigFile"
}

# ##################################
# # M A I N
# ##################################
    thisDir="$(dirname  "$(test -L "$0" && readlink "$0" || echo "$0")")"     # risolve anche eventuali LINK presenti sullo script
    thisDir=$(cd $(dirname "$thisDir"); pwd -P)/$(basename "$thisDir")        # GET AbsolutePath
    baseDir=${thisDir%/.*}                                                    # Remove /. finale (se esiste)
    echo $baseDir
    echo $EXE_File

    # set -x
    profileDir="$thisDir/_LnProfiles"
    # il programma deve essere installato sul pc ....
    EXE_File='/mnt/c/Program Files/FreeFileSync/FreeFileSync.exe'
    # EXE_File='/mnt/k/Filu/LnDisk/LnFree/SynchBackup/FreeFileSync/FreeFileSync.exe'
    APPDATA=$(getwinvar "APPDATA")

    GlobalConfigFile_base="$profileDir/GlobalSettings_base.xml"
    GlobalConfigFile=$APPDATA/FreeFileSync/GlobalSettings.xml


    SYNC_TYPE=$(echo "$1" | tr '[:upper:]' '[:lower:]')

    case $SYNC_TYPE in
        'mydata')
            process_MyData
            ;;

        'lndisk')
            # /mnt/k/Filu/LnDisk/GIT-REPO/Scripts/Bash/zip_directory.sh Loreto Lesla
            # alias 'zippa=python3 /mnt/k/Filu/LnDisk/GIT-REPO/Scripts/Python/Sources/zip_Backup/__main__.py' Loreto Lesla
            # /usr/bin/python3 '/mnt/k/Filu/LnDisk/GIT-REPO/Scripts/Python/Sources/zip_Backup/__main__.py' Loreto Lesla
            echo
            echo
            process_LnDisk
            ;;

        'userprofile')
            process_UserProfile
            ;;

        'lnpi23')
            process_LnPi23
            ;;

        'lnpi31b')
            process_LnPi31B
            ;;

        *)
            echo "Please enter one of the following:"
            echo "  mydata, lndisk, lnpi23, userprofile\n"
            exit 1
            ;; # default...
    esac

    Execute $all_profiles

