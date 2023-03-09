#!/bin/bash

#
# The epics-containers IOC startup script.
#
# This script is used to start an EPICS IOC in a Kubernetes pod. Implementers
# of generic IOCs are free to replace this script with their own. But
# this script as is should work for most IOCs.
#
# When a generic IOC runs in a kubernetes pod it is expected to have
# a config folder that defines the IOC instance.
# The helm chart for the generic IOC will mount the config folder
# as a configMap and this turns a generic IOC into aspecific IOC instance.
#
# Here we support the following set of options for the contents of
# the config folder:
#
# 1. start.sh ******************************************************************
#    If the config folder contains a start.sh script it will be executed.
#    This allows the instance implementer to provide a conmpletely custom
#    startup script.
#
# 2. ioc.yaml *************************************************************
#    If the config folder contains an ioc.yaml file we invoke the ibek tool to
#    generate the startup script and database. Then launch with the generated
#    startup script.
#
# 3. st.cmd + ioc.subst *********************************************************
#    If the config folder contains a st.cmd script and a ioc.subst file then
#    optionally generate ioc.db from the ioc.subst file and use the st.cmd script
#    as the IOC startup script. Note that the expanded database file will
#    be generated in /tmp/ioc.db
#
# 4. empty config folder *******************************************************
#    If the config folder is empty then this IOC will launch the example in
#    ./example folder
#
# RTEMS IOCS - RTEMS IOC startup files can be generated using 2,3,4 above. For
# RTEMS we do not execute the ioc inside of the pod. Instead we:
#  - copy the IOC directory to the RTEMS mount point
#  - send a reboot command to the RTEMS crate
#  - start a telnet session to the RTEMS IOC console
#

set -x -e

# environment setup ************************************************************

TOP=$(realpath $(dirname $0))
cd ${TOP}
CONFIG_DIR=${TOP}/config

# add module paths to environment for use in ioc startup script
source ${SUPPORT}/configure/RELEASE.shell

# override startup script
override=${CONFIG_DIR}/start.sh
# source YAML for IOC Builder for EPICS on Kubernetes (ibek)
ibek_src=${CONFIG_DIR}/ioc.yaml
# Startup script for EPICS IOC generated by ibek
ioc_startup=${CONFIG_DIR}/st.cmd
# expanded database file
epics_db=/tmp/ioc.db


# 1. start.sh ******************************************************************

if [ -f ${override} ]; then
    exec ${override}

# 2. ioc.yaml ******************************************************************

elif [ -f ${ibek_src} ]; then
    # Database generation script generated by ibek
    db_src=/tmp/make_db.sh
    final_ioc_startup=/tmp/st.cmd

    # get ibek the support yaml files this ioc's support modules
    defs=/ctools/*/*.ibek.support.yaml
    ibek build-startup ${ibek_src} ${defs} --out ${final_ioc_startup} --db-out ${db_src}

    # build expanded database using the db_src shell script
    if [ -f ${db_src} ]; then
        bash ${db_src} > ${epics_db}
    fi

# 3. st.cmd + ioc.substitutions ************************************************

elif [ -f ${ioc_startup} ] ; then
    if [ -f ${CONFIG_DIR}/ioc.substitutions ]; then
        # generate ioc.db from ioc.substitutions, including all templates from SUPPORT
        includes=$(for i in ${SUPPORT}/*/db; do echo -n "-I $i "; done)
        msi ${includes} -S ${CONFIG_DIR}/ioc.substitutions -o ${epics_db}
    fi
    final_ioc_startup=${ioc_startup}

# 4. empty config folder *******************************************************

else
    final_ioc_startup=${TOP}/example/st.cmd
fi

# Launch the IOC ***************************************************************

# Execute the IOC binary and pass the startup script as an argument
exec ${IOC}/bin/linux-x86_64/ioc ${final_ioc_startup}
