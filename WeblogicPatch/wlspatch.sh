#!/bin/sh
########################################################################################
# Program     : wlspatch.sh
# Parameters  : -i ID: Patch switch along with ID to install
#               -d ID: Patch switch along with ID to deinstall
#               --startup : 1 If server start is required. Set this 0 if not required.
#
#
# Purpose     : To patch weblogic server on EXA
#               All environments variables must be set before running this script
#
# Author      : Abhijee Nazar
# Date        : 29-07-2016
#
# Example     : wlspatch.sh -i DEM4 -d S8CP --startup 0
#               wlspatch.sh -i DEM4 -d dummy : IN case deinstall is not required
#######################################################################################

#Display usage of script
usage()
{
cat << EOF
usage: $0 options

OPTIONS:
   -i                   Install patch number
   -d                   Deinstall patch number
   --startup            1 If server start is required. Set this 0 if not required.
   ./wls_patch.sh -i NUM -d NUM --startup 0
EOF
}

#Set Variables
setvariables()
{
    export PATCH_CLIENT=$MW_HOME/utils/bsu/patch-client.jar
    export JAVA_HOME=`echo $(cd $MW_HOME/../*jdk*; pwd)`
    export OOD_FOLDER=.
    export PATCH_NAME=$INSTALL.zip
    MEM_ARGS="-Xms256m -Xmx4096m"

}

#Check if folder are available
checkfolders()
{
    if [ ! -d  "${OOD_FOLDER}/${INSTALL}" ]; then
        echo "=========================="
        echo "Directory does not exists"
        echo "=========================="
        exit
    fi
}

#Check if patch is already downloaded
checkdownload()
{
     if [ -d  "${OOD_FOLDER}/${INSTALL}" ];  then
        echo "=========================================="
        echo "File Already exists so skip download part."
        echo "=========================================="
        downloadpatch=0
     fi
}



#Start Patching
patchweblogic()
{
    echo "==============================="
    echo "Copy patches to download folder"
    cp -r ${OOD_FOLDER}/${INSTALL}/* ${MW_HOME}/utils/bsu/cache_dir

    cd ${MW_HOME}/utils/bsu

    echo "Status of patches"
    $JAVA_HOME/bin/java ${MEM_ARGS} -jar ${PATCH_CLIENT} -view -status=applied -prod_dir=${WL_HOME}

    echo "Deinstall patch" = ${DEINSTALL}
    $JAVA_HOME/bin/java ${MEM_ARGS} -jar ${PATCH_CLIENT} -remove -patchlist=${DEINSTALL} -prod_dir=${WL_HOME}

    echo "Install patch" = ${INSTALL}
    $JAVA_HOME/bin/java ${MEM_ARGS} -jar ${PATCH_CLIENT} -install -patch_download_dir=${MW_HOME}/utils/bsu/cache_dir -patchlist=${INSTALL} -prod_dir=${WL_HOME}
    echo "==============================="

}

startweblogic()
{
    if [ ! -f ${HOME}/bin/rc.obi ]; then
        echo "==============================="
        echo "Using rc.obia to start services"
        rc.obia start
        echo "==============================="
    else
        echo "==============================="
        echo "Using rc.obi to start services"
        rc.obi start
        echo "==============================="
    fi
}

stopweblogic()
{
    if [ ! -f ${HOME}/bin/rc.obi ]; then
        echo "==============================="
        echo "Using rc.obia to stop services"
        rc.obia stop
        echo "==============================="

    else
        echo "==============================="
        echo "Using rc.obi to stop services"
        rc.obi stop
        echo "==============================="
    fi
}

downloadpatches()
{
    wget --no-check-certificate -O $PATCH_NAME --header 'X-JFrog-Art-Api: AKCp5Z2hayUKnbKQaJ8cBv9QEXvMDn82r23bJupFXH4yusL4vueMwQiXj7tfnXeQHiU1rM9dG' "https://artifactory.ing.net/artifactory/releases_generic_FSO_AM_REPORTING/BINARIES/WLS/WLS_PATCHES/$PATCH_NAME"
    if [ $? -eq 0 ]; then
        echo "Patch downloaded..."
    else
        echo "Failed"
        exit
    fi
    unzip -o $PATCH_NAME -d $INSTALL
}


echo "Using ORACLE_HOME as $ORACLE_HOME"
echo "Using MW_HOME as $MW_HOME"
echo "Using WL_HOME as $WL_HOME"
echo "Using INSTANCE_HOME as $INSTANCE_HOME"

if [ $# -lt 5 ]
 then
  echo "Insufficnent arguments..."
  echo "Please check usage"
  usage
  exit 1
fi

while [[ $# -gt 1 ]]
do
key="$1"

case $key in
    -i|--install)
        INSTALL="$2"
        shift # past argument
        ;;
    -d|--deinstall)
        DEINSTALL="$2"
        shift # past argument
        ;;
    -s|--startup)
        STARTUP="$2"
        shift # past argument
        ;;
    \?)
        echo "Invalid option: -$OPTARG" >&2
        usage
        exit 1
        ;;
    :)
        echo "Option -$OPTARG requires an argument." >&2
        usage
        exit 1
        ;;
esac
shift # past argument or value
done

echo $INSTALL
echo $DEINSTALL

#Start of the script
setvariables

#Check if patch already downloaded
checkdownload

#Download Patches from artifactory
if [[ "$downloadpatch" != 0 ]]; then
   downloadpatches
fi

#Step 1 check all folder are available
checkfolders

#Step 2 After confirmation stop all Weblogic and OBIEE services
if [[ "$STARTUP" == 1 ]]; then
    stopweblogic
fi


#Step 3 Start patching
patchweblogic

#Step 4 Start Weblogic and OBIEE
if [[ "$STARTUP" == 1 ]]; then
    startweblogic
fi
