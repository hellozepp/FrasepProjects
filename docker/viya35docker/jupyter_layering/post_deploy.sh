#!/bin/bash

###############################################################################
# Run Jupyter notebook
###############################################################################
export SASSERVICENAME="jupyter"
export JPY_COOKIE_SECRET=`openssl rand -hex 32`
export SSLCALISTLOC="${SASHOME}/SASSecurityCertificateFramework/cacerts/trustedcerts.pem"
export CAS_CLIENT_SSL_CA_LIST="/data/casconfig/sascas.pem"

# create it here also (instead of just in sasdemo user creation)
runuser --shell "/bin/sh" --login ${RUN_USER} \
    --command "mkdir -p ~/jupyter"

cp /usr/local/lib/python3.6/site-packages/saspy/sascfg.py /usr/local/lib/python3.6/site-packages/saspy/sascfg_personal.py
sed -i -e "s#/opt/sasinside/SASHome/SASFoundation/9.4/bin/sas_u8#/opt/sas/spre/home/SASFoundation/sas#g" /usr/local/lib/python3.6/site-packages/saspy/sascfg_personal.py

echo "Starting ${SASSERVICENAME}..."

#docker_create_pid_file
_jupyterpid=${DOCKERPIDFILE}

# create jupyter config file
runuser --shell "/bin/sh" --login ${RUN_USER} \
    --command "jupyter notebook --generate-config"

runuser --shell "/bin/sh" --login ${RUN_USER} \
    --command "JPY_COOKIE_SECRET=${JPY_COOKIE_SECRET} \
    SSLCALISTLOC=${SSLCALISTLOC} \
    CAS_CLIENT_SSL_CA_LIST=${CAS_CLIENT_SSL_CA_LIST} \
    jupyter notebook \
    --ip='*' \
    --no-browser \
    --NotebookApp.token='${JUPYTER_TOKEN}' \
    --NotebookApp.terminals_enabled=False \
    --NotebookApp.base_url=/jupyter \
    --KernelSpecManager.ensure_native_kernel=False \
    --notebook-dir=~/jupyter &"

# pgrep jupyter > ${_jupyterpid}
