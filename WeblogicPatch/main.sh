#!/bin/sh
###################################################################################
# Program     : wlspatch.sh
# Parameters  : -i ID: Patch switch along with ID to install
#               -d ID: Patch switch along with ID to deinstall
#
#
# Purpose     : To patch weblogic server on EXA
#               All environments variables must be set before running this script
#
# Author      : Abhijee Nazar
# Date        : 29-07-2016
#
# Example     : wlspatch.sh -i DEM4 -d S8CP
#               wlspatch.sh -i DEM4 -d dummy : IN case deinstall is not required
###################################################################################

#Display usage of script
usage()
{
cat << EOF
usage: $0 options

OPTIONS:
   -i                   Install patch number
   -d                   Deinstall patch number
   ./wls_patch.sh -i NUM -d NUM
EOF
}

echo "Using ORACLE_HOME as $ORACLE_HOME"
echo "Using MW_HOME as $MW_HOME"
echo "Using WL_HOME as $WL_HOME"
echo "Using INSTANCE_HOME as $INSTANCE_HOME"


export PATCH_CLIENT=$MW_HOME/utils/bsu/patch-client.jar
export JAVA_HOME=`echo $(cd $MW_HOME/../*jdk*; pwd)`
export OOD_FOLDER=/ood_repository/obiee/obiee111190/wlspatch
MEM_ARGS="-Xms256m -Xmx4096m"


if [ $# -lt 4 ]
 then
  echo "Insufficnent arguments..."
  echo "Please check usage"
  usage
  exit 1
fi

while getopts "i:d:" OPTION;
do
case $OPTION in
 i)
   INSTALL=$OPTARG
   ;;
 d)
  DEINSTALL=$OPTARG
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
done

if [ ! -d  "${OOD_FOLDER}/${INSTALL}" ]; then
        echo "Directory does not exists"
        exit
fi

if [ ! -f ${HOME}/bin/rc.obi ]; then
        echo "Using rc.obia to stop services"
        rc.obia stop
else
        echo "Using rc.obi to stop services"
        rc.obi stop
fi

echo "Copy patches to download folder"
cp -r ${OOD_FOLDER}/${INSTALL}/* ${MW_HOME}/utils/bsu/cache_dir

cd ${MW_HOME}/utils/bsu

echo "Status of patches"
$JAVA_HOME/bin/java ${MEM_ARGS} -jar ${PATCH_CLIENT} -view -status=applied -prod_dir=${WL_HOME}

echo "Deinstall patch" = ${DEINSTALL}
$JAVA_HOME/bin/java ${MEM_ARGS} -jar ${PATCH_CLIENT} -remove -patchlist=${DEINSTALL} -prod_dir=${WL_HOME}

echo "Install patch" = ${INSTALL}
$JAVA_HOME/bin/java ${MEM_ARGS} -jar ${PATCH_CLIENT} -install -patch_download_dir=${MW_HOME}/utils/bsu/cache_dir -patchlist=${INSTALL} -prod_dir=${WL_HOME}

if [ ! -f ${HOME}/bin/rc.obi ]; then
        echo "Using rc.obia to start services"
#        rc.obia start
else
        echo "Using rc.obi to start services"
#        rc.obi start
fi
