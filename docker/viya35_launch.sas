#! /bin/bash -e

IMAGE=ses.sas.download/va-125-x64_redhat_linux_7-docker/sas-viya-programming:3.5.13-20210830.1630366147028
SAS_HTTP_PORT=8081

run_args="
--name=sas-programming
--rm
--hostname sas-programming
--env RUN_MODE=developer
--env CASENV_ADMIN_USER=sasdemo
--env CASENV_CAS_VIRTUAL_HOST=$(hostname -f)
--env CASENV_CAS_VIRTUAL_PORT=${SAS_HTTP_PORT}
--env CASENV_CASDATADIR=/cas/data
--env CASENV_CASPERMSTORE=/cas/permstore
--publish-all
--publish 5570:5570
--publish 8591:8591
--publish ${SAS_HTTP_PORT}:80
--volume ${PWD}/sasinside:/sasinside
--volume ${PWD}/sasdemo:/data
--volume ${PWD}/cas/data:/cas/data
--volume ${PWD}/cas/cache:/cas/cache 
--volume ${PWD}/cas/permstore:/cas/permstore"

# Run in detached mode
docker run --detach ${run_args} $IMAGE "$@"

# For debugging startup, comment out the detached mode
# command and uncomment the following

#docker run --interactive --tty ${run_args} $IMAGE "$@"
