#!/bin/bash

THIS_DIR=$(dirname ${BASH_SOURCE[0]})

export EPICS_CA_SERVER_PORT=7064
${THIS_DIR}/launcher.sh example example.edl

caput -S EXAMPLE:CAM:URL1 /tmp/millie.jpg
cp ${THIS_DIR}/millie.jpg /tmp/millie.jpg

caput EXAMPLE:CAM:Acquire.PROC 1

c2dv --pv EXAMPLE:IMAGE

