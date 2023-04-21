#!/bin/bash

ioc=${1}
start=${2}
shift 2
thisdir=$(realpath $(dirname ${BASH_SOURCE[0]}))

if [ -z $(which docker 2> /dev/null) ]
then
    # try podman if we dont see docker installed
    shopt -s expand_aliases
    alias docker='podman'
    opts= "--privilege "
fi

image=ghcr.io/epics-containers/edm:latest
environ="-e DISPLAY -e EPICS_CA_ADDR_LIST -e EPICS_CA_AUTO_ADDR_LIST -e EPICS_CA_SERVER_PORT -e EDMDATAFILES=/screens"
volumes="-v ${thisdir}/${ioc}:/screens -v /tmp:/tmp"
opts=${opts}"-ti --privileged --net=host"

set -x
docker run --rm -d ${environ} ${volumes} ${@} ${opts} ${image} edm -x -noedit ${start} ${@}


