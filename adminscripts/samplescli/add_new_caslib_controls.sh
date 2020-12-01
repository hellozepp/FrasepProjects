#!/bin/bash
#
# Copyright (c) 2018, SAS Institute Inc., Cary, NC, USA, All Rights Reserved
#############################################################################

#set -x

##############################################################
### Functions                                              ###
##############################################################

function grant_access_control() {
########################################################
## Grants an access control to the specified user or group
## for the specified caslib on the specified cas server
## ** superuser assumed **
########################################################
  local cli_path
  local control
  local identity_type
  local identity
  local server
  local caslib
  local session_id

  while [ -n "$1" ]
  do
    case "$1" in
      --clipath) # Path to the sas-admin cli
        shift
        cli_path="$1"
        ;;

      --control) # The access control to be granted
        shift
        control="$1"
        ;;

      --user) # The user associated with the control
        shift
        identity_type="user"
        identity="$1"
        ;;

      --group) # The group associated with the control
        shift
        identity_type="group"
        identity="$1"
        ;;

      --server) # The cas server where the control is to be set
        shift
        server="$1"
        ;;

      --caslib) # The caslib where the control is to be set
        shift
        caslib="$1"
        ;;

      --session-id) # The existing cas session to use (must be superuser session)
        shift
        session_id="$1"
        ;;

      *)
        break # unrecognized option
        ;;
    esac
    shift
  done

  ${cli_path} cas caslibs add-control --grant "${control}" --${identity_type} "${identity}" --server "${server}" --caslib "${caslib}" --session-id "${session_id}"
}

function grant_sasapp_full_control() {
########################################################
## Grants "full control" to members of the 'sasapp'
## group, which represents internal SAS service accounts.
## Full control is required for all services to interact
## with common, system-wide caslibs.
##
## "Full control" grants the following permissions:
##   - ReadInfo
##   - Select
##   - LimitedPromote
##   - Promote
##   - CreateTable
##   - DropTable
##   - DeleteSource
##   - Insert
##   - Update
##   - Delete
##   - AlterTable
##   - AlterCaslib
##   - ManageAccess
########################################################
  local clipath
  local server
  local session_id
  local caslib
  local sasapp_grp="sasapp"

  while [ -n "$1" ]
  do
    case "$1" in
      --clipath) # Path to the sas-admin cli
        shift
        cli_path="$1"
        ;;

      --server) # The cas server where the control is to be set
        shift
        server="$1"
        ;;

      --caslib) # The caslib where the control is to be set
        shift
        caslib="$1"
        ;;

      --session-id) # The existing cas session to use (must be superuser session)
        shift
        session_id="$1"
        ;;

      *)
        break # unrecognized option
        ;;
    esac
    shift
  done

  local _controls="readInfo select limitedPromote promote createTable dropTable deleteSource insert update delete alterTable alterCaslib manageAccess"
  while IFS=' ' read -ra controls; do
    for control in "${controls[@]}"; do

      grant_access_control --clipath "${cli_path}" --group "${sasapp_grp}" --server "${server}" --caslib "${caslib}" --session-id "${session_id}" --control "${control}"

    done
  done <<< ${_controls}
}

function print_help() {
########################################################
## Displays help information
########################################################
  printf "\nThis script sets new, required access controls on SAS-created CASLibs for all available CAS servers.\n"
  printf "\nUSAGE:\n    add_new_caslib_controls.sh [command options...]\n"
  printf "\nCOMMAND OPTIONS:\n"
  printf "    --sas-endpoint    Sets the URL to the SAS services. (required | default: n/a | example: --sas-endpoint \"http://my.sas.services.com:80\")\n"
  printf "    --sas-home        Sets the path to the SAS home directory (optional | default: /opt/sas/viya/home | example: --sas-home \"/my/sas/home\")\n"
  printf "    --help            Shows help.\n"
  exit 0
}



##############################################################
### Main Program                                           ###
##############################################################

# constants
profile="_sasupdate_"
ops_agent_user="sas.ops-agentsrv"
admin_group="SASAdministrators"

# defaults
sas_home="/opt/sas/viya/home"
sas_endpoint=""

while [ -n "$1" ]
do
  case "$1" in
    --sas-home) # The location of the SAS Viya home directory
      shift
      sas_home="$1"
      ;;

    --sas-endpoint) # The URL of the SAS services
      shift
      sas_endpoint="$1"
      ;;

    --help)
      print_help
      ;;
    *)
      break # unrecognized option
      ;;
  esac
  shift
done

# Make sure sas_endpoint is set
if [[ -z "${sas_endpoint}" ]]; then
  printf "\nERROR: The URL to the SAS services has not been set. Use '--sas-endpoint' to set this value. (example: --sas-endpoint \"http://my.sas.services.com:80\")\n"
  exit 1
fi

# Set command for sas-admin cli
sas_admin_cmd="${sas_home}/bin/sas-admin --profile ${profile}"

# Create a profile
${sas_admin_cmd} profile set-endpoint ${sas_endpoint}
${sas_admin_cmd} profile set-output json
${sas_admin_cmd} profile toggle-color off

# Prompt for authentication
printf "\n***User must be a member of the SASAdministrators group***\n\n"
exec 5>&1
_login=$( ${sas_admin_cmd} auth login | tee >(cat ->&5 ))
if [[ ${_login} == *"Login failed."* ]]; then
  exit 1
fi

# Get a list of all cas servers
_casservers=$( ${sas_admin_cmd} cas servers list --all | grep "\"name\":\s\"" | sed -e 's/.*"name":\s\"//g' -e 's/".*//' )

while IFS=' ' read -ra casservers; do
  for casserver in "${casservers[@]}"; do

    # Print current cas server
    printf "\nCAS Server: ${casserver}\n\n"

    # Create a session and assume superuser for all transactions
    session_id=$( ${sas_admin_cmd} --quiet cas sessions create --name "sasUpdateSession" --server "${casserver}" --superuser )
    if [ $? != 0 ]; then
        printf "ERROR: An error occurred creating a session on the CAS server. This server will be skipped.\n"
        printf "HINT: Make sure the current user can assume SuperUser privileges on this CAS server.\n\n"
        break
    fi

    # Add access controls to AppData caslib
    caslib="AppData"
    printf "Caslib: ${caslib}\n\n"
    grant_sasapp_full_control --clipath "${sas_admin_cmd}" --server "${casserver}" --caslib "${caslib}" --session-id "${session_id}"

    # Add access controls to SystemData caslib
    caslib="SystemData"
    printf "\nCaslib: ${caslib}\n\n"
    grant_sasapp_full_control --clipath "${sas_admin_cmd}" --server "${casserver}" --caslib "${caslib}" --session-id "${session_id}"
    _controls="readInfo select promote createTable dropTable deleteSource insert update delete alterTable"
    while IFS=' ' read -ra controls; do
      for control in "${controls[@]}"; do
        grant_access_control --clipath "${sas_admin_cmd}" --user "${ops_agent_user}" --server "${casserver}" --caslib "${caslib}" --session-id "${session_id}" --control "${control}"
      done
    done <<< ${_controls}

    # Add access controls to Samples caslib
    caslib="Samples"
    printf "\nCaslib: ${caslib}\n\n"
    grant_sasapp_full_control --clipath "${sas_admin_cmd}" --server "${casserver}" --caslib "${caslib}" --session-id "${session_id}"

    # Add access controls to Models caslib
    caslib="Models"
    printf "\nCaslib: ${caslib}\n\n"
    grant_sasapp_full_control --clipath "${sas_admin_cmd}" --server "${casserver}" --caslib "${caslib}" --session-id "${session_id}"
    grant_access_control --clipath "${sas_admin_cmd}" --group "*" --server "${casserver}" --caslib "${caslib}" --session-id "${session_id}" --control limitedPromote


    # Add access controls to VAModels caslib
    caslib="VAModels"
    printf "\nCaslib: ${caslib}\n\n"
    grant_sasapp_full_control --clipath "${sas_admin_cmd}" --server "${casserver}" --caslib "${caslib}" --session-id "${session_id}"

    # Add access controls to ReferenceData caslib
    caslib="ReferenceData"
    printf "\nCaslib: ${caslib}\n\n"
    grant_access_control --clipath "${sas_admin_cmd}" --group "*" --server "${casserver}" --caslib "${caslib}" --session-id "${session_id}" --control promote
    grant_access_control --clipath "${sas_admin_cmd}" --group "*" --server "${casserver}" --caslib "${caslib}" --session-id "${session_id}" --control dropTable
    grant_access_control --clipath "${sas_admin_cmd}" --group "${admin_group}" --server "${casserver}" --caslib "${caslib}" --session-id "${session_id}" --control createTable
    grant_access_control --clipath "${sas_admin_cmd}" --group "${admin_group}" --server "${casserver}" --caslib "${caslib}" --session-id "${session_id}" --control update

    # Add access controls to search caslib
    caslib="search"
    printf "\nCaslib: ${caslib}\n\n"
    grant_access_control --clipath "${sas_admin_cmd}" --user "sas.searchIndex" --server "${casserver}" --caslib "${caslib}" --session-id "${session_id}" --control "delete"
    grant_access_control --clipath "${sas_admin_cmd}" --user "sas.searchIndex" --server "${casserver}" --caslib "${caslib}" --session-id "${session_id}" --control "deleteSource"

    # Delete the session
    ${sas_admin_cmd} --quiet cas sessions delete --session-id "${session_id}" --server "${casserver}" --superuser --force

    echo

  done
done <<< ${_casservers}

# Logout
${sas_admin_cmd} auth logout

exit 0
