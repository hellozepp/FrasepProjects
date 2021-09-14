#!/bin/bash
# gel.CASDiskCacheListUsers.sh

_CASCDCPAth=$1
_hostname=$(hostname)
if [ "${_CASCDCPAth}" == "" ];   then
      echo "The CAS Disk Cache path is a required argument!"
      echo "   Usage: gel.CASDiskCacheListUsers.sh < /CASDiskCachePath >"
      exit 1
fi
echo
echo "CAS Disk Cache path on ${_hostname}: ${_CASCDCPAth}"

_CDCUsersList=$(lsof -a +L1 | grep "${_CASCDCPAth}" | awk '{print $3}' | sort | uniq)
echo "   List of users who have data blocks in the CAS disk cache: "$(echo "${_CDCUsersList[@]}")
echo " "
exit 0

