#!/bin/bash
# gel.CASDiskCacheUserUsage.sh
#

_CASCDCPAth=$1
_userID=$2
_diskSizeUnit=$3
_hostname=$(hostname)
if [ "${_CASCDCPAth}" == "" ] || [ "${_userID}" == "" ];   then
      echo "The CAS Disk Cache path and a userID are required arguments!"
      echo "   Usage: gel.CASDiskCacheUserUsage.sh < /CASDiskCachePath > < userID >"
      echo "   You can pass the disk size unit as an argument. Supported units are: B (default), KB, MB, GB, TB"
      exit 1
fi

case "${_diskSizeUnit}" in
        "")
            _diskSizeUnit=B
            _factor=1
            ;;
        "B")
            _factor=1
            ;;
        "KB")
            _factor=1024
            ;;
         
        "MB")
            _factor=1048576
            ;;
         
        "GB")
            _factor=1073741824
            ;;
        "TB")
            _factor=1099511627776
            ;;
        *)
            echo $"Unknown or unsupported  disk size unit!"
            exit 1
esac

echo 

echo "CAS Disk Cache path on ${_hostname}: ${_CASCDCPAth}"

_CDCNumDataBlocks=$(lsof -a +L1 -u ${_userID} | wc -l)
echo "   Number of data blocks in the CAS disk cache for user ${_userID}: ${_CDCNumDataBlocks}"

_CDCDiskSize=$(df ${_CASCDCPAth} --output=size | awk "END {print \$1*1024/${_factor} }")
_CDCDiskSizeRound=$(echo $(printf "%0.2f\n" ${_CDCDiskSize}))
echo "   Size (${_diskSizeUnit}) of the CAS Disk Cache disk: ${_CDCDiskSizeRound}${_diskSizeUnit}"

_CDCSize=$(lsof -a +L1 -u ${_userID} | awk "{ total += \$7 }; END { print total/${_factor} }")
_CDCSizeRound=$(echo $(printf "%0.2f\n" ${_CDCSize}))
echo "   Size (${_diskSizeUnit}) of ${_userID} user data blocks in the CAS Disk Cache: ${_CDCSizeRound}${_diskSizeUnit}"

_CDCDiskUagePercent=$(awk "BEGIN {print ${_CDCSize}*100/${_CDCDiskSize}}")
_CDCDiskUagePercentRound=$(echo $(printf "%0.2f\n" ${_CDCDiskUagePercent}))
echo "   CAS Disk Cache disk %usage for user ${_userID}: ${_CDCDiskUagePercentRound}%"
echo " "
exit 0

