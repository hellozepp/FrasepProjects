#!/bin/bash

# for later:
# kubectl run curl_test --image=radial/busyboxplus:curl -i -tty -rm --generator=run-pod/v1
# kubectl -n functional run curl-test --image=radial/busyboxplus:curl -i --tty --rm --generator=run-pod/v1

## stop, start, bounce
## all
## parts   (--all or --consul --postgres --rabbit --identities --cas )
## path to site.yaml (--manifest)

# kubectl get ingress -o jsonpath='{range .items[*]}{.spec.rules[].http.paths[].path}{"\n"}{end}'  | sort


####################### Assigning Default Values - Begin #####################
gel_OKViya4_VERSION="Alpha 0.018"
K8S_POD_FILTER=${K8S_POD_FILTER:--l "sas.com/deployment=sas-viya"}
MANIFEST=${MANIFEST:-${PWD}/site.yaml}
MAX_RETRIES=${MAX_RETRIES:-0}            ## set to 0 for unlimited
MIN_SUCCESS_RATE=${MIN_SUCCESS_RATE:-90}
CURL_OUTPUT=${CURL_OUTPUT:-blocks}         ## none or csv
RETRY_GAP=${RETRY_GAP:-20}               ## How many seconds to sleep between retries
START_MODE=${START_MODE:-parallel}
TIMINGS=${TIMINGS:-no}
MAX_CHICKLET_PER_LINE=${MAX_CHICKLET_PER_LINE:-50}
MAX_CURL_TIME=${MAX_CURL_TIME:-1}         ## endpoints have to respond within 2 seconds or it's considered a fail

####################### Assigning Default Values - End #####################



####################### Functions Definition - Begin #####################
function usage() {
   printf "\ngel_OKViya4: (On Kubernetes) Viya

    a utility script to help start, stop, restart, and check Viya 4 On Kubernetes (OK)\n
    Version: ${gel_OKViya4_VERSION}

    The source code for this can be found at:
        https://gitlab.sas.com/GEL/utilities/gel_OKViya4

    The Draft Documentation for Start/Stop can be found at:
        http://pubshelpcenter.unx.sas.com:8080/test/?cdcId=sasadmincdc&cdcVersion=v_003&docsetId=calchkadm&docsetTarget=p17xfmmjjkma1dn1b5dcx3e5ejxq.htm&locale=en#p0szdr59qn1uwkn13ktqmzqjwpyh

    ****** current ********

    --help|-h|--version|-v         (This help information)

    --namespace|-n <namespace>     (The namespace you want to work in)
    --manifest <./site.yaml>       (The manifest file associated with your deployment. Required for --start, otherwise ignored)

    --start
    --start-mode <parallel|sequential>
    --stop
    --restart

    --wait                         (with --start, will wait until everything is healthy to return to the prompt)
                                   (with --stop, will wait until all Viya pods are gone to return to the prompt)

    --min-success-rate <1..100>    (Change success rate value - Default value is ${MIN_SUCCESS_RATE})
    --max-retries <0..999>         (How many times to retry - Default value is ${MAX_RETRIES} - 0 = unlimited)
    --retry-gap <1..999>           (How many seconds to wait before re-trying - Default value is ${RETRY_GAP} seconds)

    --pod-status|-ps               (Display a summarized view of the pods)

    -co|--curl-output <blocks|lines>    (the type of output from curl. Default is ${CURL_OUTPUT} )

    ****** future options *******

    --dnscheck
    --health                               (Will check the endpoint's health)
    --health-mode|-hm <internal/external>  (Either inside the pods, or outside, using the ingress)
    --ingress|--ingress-host|-i <ingress_alias/auto>
    --ingress-port|-p <ingress_port>
    --output-type|-o <none|csv>            (This option will determine what type of output the script creates - Default value is ${CURL_OUTPUT})
    --verbose

"
}


function pause() {
   read -n1 -rsp $'Press any key to continue (or Ctrl+C to exit)...\n'
}


function state() {
   # local msg="$(date -I) $1"
   local msg="$(date '+%Y%m%d-%H%M%S') $1"
   local flag=$2
   if [ "${flag}" -eq 0 ]; then
      echo -e "\e[92m OK    \033[0m ${msg}"
   elif [ "${flag}" -eq -1 ]; then
      echo -e "\e[36m LEARN:  $1 \033[0m"
   elif [ "${flag}" -eq 1 ]; then
      echo -e "\e[93m       \033[0m ${msg}"
   elif [ "${flag}" -eq 2 ]; then
      echo -e "\e[93m WAIT  \033[0m ${msg}"
   else
      echo -e "\e[91m FAIL  \033[0m ${msg}"
   fi
}


function if_learn() {
   if [ "${LEARN}" == "yes" ]
   then
      state "$1"  -1
      #pause
   fi
}


function MANIFEST_CHECK() {
   if_learn "Some operations require referencing the manifest file."
   if [  -f ${MANIFEST} ]
   then
       state "The provided  manifest (${MANIFEST}) exists" 0
   else
       state "The provided  manifest (${MANIFEST}) does not exists" 3
       state "If you did not provide a path the manifest, do so with:   --manifest ~/folder/site.yaml" 3
       exit 1
   fi
}


function colors() {
   # Reset
   res="\[\033[0m\]"      # Text Reset

   # Regular Colors
   bla="\[\033[0;30m\]"        # black
   red="\[\033[0;31m\]"          # red
   gre="\[\033[0;32m\]"        # green
   yel="\[\033[0;33m\]"       # yellow
   blu="\[\033[0;34m\]"         # blue
   pur="\[\033[0;35m\]"       # purple
   cya="\[\033[0;36m\]"         # cyan
   whi="\[\033[0;37m\]"        # white
}


function POD_STATUS() {
   ## credits to  Wouter Van de Weghe for this piece of code!
   if [[ "${POD_STATUS}" == "yes" ]];
   then
      colors
      state "Displaying summarized pod status" 0
      kubectl -n ${NS} get pods --no-headers | sort | \
      awk 'BEGIN {TOTAL=0;RUNNING=0;STARTING;ERROR=0;PULLERRORS=0;EVICTED=0;COMPLETED=0;CRASH=0;PENDING=0;INITIALIZING=0;TERMINATING=0} \
      {if ($3 == "Running") \
          {if (substr($2, 1,1) == substr($2, 3,1)) \
               {RUNNING=RUNNING+1;TOTAL=TOTAL+1;                             printf"\033[0;32m.\033[0m"} \
          else {STARTING=STARTING+1;TOTAL=TOTAL+1;                           printf"\033[0;33ms\033[0m"}} \
      else if (($3 == "Error")||($3 == "Init:Error")) \
                          {ERROR=ERROR+1;TOTAL=TOTAL+1;                      printf"\033[0;31mE\033[0m"} \
      else if ($3 == "Evicted"){EVICTED= EVICTED+1;TOTAL=TOTAL+1;            printf"\033[0;33me\033[0m"} \
      else if ($3 == "ImagePullBackOff"){PULLERRORS= PULLERRORS+1;TOTAL=TOTAL+1;            printf"\033[0;31mp\033[0m"} \
      else if ($3 == "Completed"){COMPLETED=COMPLETED+1;TOTAL=TOTAL+1;       printf"\033[0;32mC\033[0m"} \
      else if (($3 == "CrashLoopBackOff")||($3 == "Init:CrashLoopBackOff")) \
                          {CRASH=CRASH+1;TOTAL=TOTAL+1;                      printf"\033[0;33mc\033[0m"} \
      else if ($3 == "Pending"){PENDING=PENDING+1;TOTAL=TOTAL+1;             printf"\033[0;33mP\033[0m"} \
      else if (($3 == "PodInitializing")||($3 == "ContainerCreating")||($3 == "Init:0/1")||($3 == "Init:0/2")||($3 == "Init:1/2")) \
                          {INITIALIZING=INITIALIZING+1;TOTAL=TOTAL+1;        printf"\033[0;33mI\033[0m"} \
      else if ($3 == "Terminating"){TERMINATING=TERMINATING+1;TOTAL=TOTAL+1; printf"\033[0;31mT\033[0m"} \
      else {OTHERS=OTHERS+1;TOTAL=TOTAL+1;                                   printf"\033[0;31mO\033[0m"}} END\
      {printf "\n" ; \
       printf "\033[0;31mOthers (O) ------------\033[0m: %d\n", OTHERS; \
       printf "\033[0;31mPull Error (p) --------\033[0m: %d\n", PULLERRORS; \
       printf "\033[0;31mTerminating (T) -------\033[0m: %d\n", TERMINATING ; \
       printf "\033[0;31mError (E) -------------\033[0m: %d\n", ERROR; \
       printf "\033[0;33mEvicted (e) -----------\033[0m: %d\n", EVICTED; \
       printf "\033[0;33mPending (P) -----------\033[0m: %d\n", PENDING ; \
       printf "\033[0;33mInitializing (I) ------\033[0m: %d\n", INITIALIZING; \
       printf "\033[0;33mCrashLoopBackOff (c) --\033[0m: %d\n", CRASH; \
       printf "\033[0;33mStarting (s) ----------\033[0m: %d\n", STARTING; \
       printf "\033[0;32mCompleted (C) ---------\033[0m: %d\n", COMPLETED; \
       printf "\033[0;32mRunning (.) -----------\033[0m: %d\n", RUNNING; \
       printf "\n"; \
       printf "Total -----------------: %d\n",TOTAL}'

        OLDEST_VIYA_POD_NAME=$(kubectl -n ${NS} get pods \
                             --sort-by=.status.startTime \
                            "${K8S_POD_FILTER}" \
                             --no-headers \
                             | head -n 1 \
                             | awk '{print $1}')
        POD_AGE_OLD=$(kubectl -n ${NS} get pods ${OLDEST_VIYA_POD_NAME} \
                                     --no-headers \
                             | awk '{print $5}')

        state "The oldest Viya pod in the namespace (${OLDEST_VIYA_POD_NAME}) is ${POD_AGE_OLD} old" 0

   fi
}


function podname() {
   kubectl -n ${NS} get pods | grep "$1" | awk  '{ print $1 }'
}


function NS_Check() {
    if [ "${NS}" == "" ]
    then
      state "You need to supply at least a namespace (with -n <namespace_name>)" 3
      state "Exiting" 3
      exit
    else
      if [ $(kubectl get ns ${NS} | awk '{ print $1 }' | grep -c ${NS}) -ge 1 ]
      then
         state "You provided the namespace \"${NS}\"" 0
         state "That namespace does exist. Continuing...." 0
      else
        state "The namespace provided (\"${NS}\") is not valid" 3
        state "Here is a list of the valid namespaces in your environment:" 3
        state "(although that might not work if you don't have the permission to see that list):" 3
        CMD="kubectl get ns"
        if_learn "${CMD}"
        ${CMD}

        while [ $(kubectl get ns ${NS} 2> /dev/null | awk '{ print $1 }' | grep -c ${NS}) -lt 1 ]
        do
            state "I'll try again in 60 seconds." 3
            state "But I advise you to cancel (Ctrl-C) " 3
            state "You most likely mistyped the namespace." 3
            sleep 60
        done

      fi
   fi
   if_learn "We expect to work in a specific namespace\n to see all namespaces in your environment, execute the following: \n    kubectl get namespaces"
}

function CADENCE_VERSION() {

    # find the name of the configmap
    CM_NAME=$(   kubectl -n ${NS} get configmaps | grep "sas-deployment-metadata" | awk  '{ print $1 }' )

    #kubectl -n ${NS} get configmap ${CM_NAME} -o yaml | grep '\ \ SAS_'

    # save everything as vars, for conditional stuff in the future
    SAS_BUILD_TYPE=$(kubectl -n ${NS} get configmap ${CM_NAME} -o custom-columns='data:data.SAS_BUILD_TYPE' --no-headers)
    SAS_CADENCE_DISPLAY_NAME=$(kubectl -n ${NS} get configmap ${CM_NAME} -o custom-columns='data:data.SAS_CADENCE_DISPLAY_NAME' --no-headers)
    SAS_CADENCE_NAME=$(kubectl -n ${NS} get configmap ${CM_NAME} -o custom-columns='data:data.SAS_CADENCE_NAME' --no-headers)
    SAS_CADENCE_RELEASE=$(kubectl -n ${NS} get configmap ${CM_NAME} -o custom-columns='data:data.SAS_CADENCE_RELEASE' --no-headers)
    SAS_CADENCE_VERSION=$(kubectl -n ${NS} get configmap ${CM_NAME} -o custom-columns='data:data.SAS_CADENCE_VERSION' --no-headers)
    SAS_DEPLOYMENT_TYPE=$(kubectl -n ${NS} get configmap ${CM_NAME} -o custom-columns='data:data.SAS_DEPLOYMENT_TYPE' --no-headers)
    SAS_REPOSITORY_WAREHOUSE_URL=$(kubectl -n ${NS} get configmap ${CM_NAME} -o custom-columns='data:data.SAS_REPOSITORY_WAREHOUSE_URL' --no-headers)

    # display message
    state "#######################################################" 0
    state "######### Viya 4 Cadence Information ##################" 0
    state "#######################################################" 0
    state "#####   Cadence Name   : ${SAS_CADENCE_NAME}" 0
    state "#####   Cadence Version: ${SAS_CADENCE_VERSION}" 0
    state "#####   Cadence Release: ${SAS_CADENCE_RELEASE}" 0
    state "#######################################################" 0

}


function DETERMINE_INGRESS_TYPE () {
    # try to determine if using NGINX or ISTIO

    N_ING=$(kubectl -n ${NS} get ing 2> /dev/null | wc -l )
    if [ "${N_ING}" -ge "1" ]
    then
        ING_TYPE="NGINX"
        state "Looks like there are "${N_ING}" Kubernetes Ingresses in the namespace, so we assume it's ${ING_TYPE}" 0
    fi

    N_VIRT_SERVICE=$(kubectl -n ${NS} get virtualservices 2> /dev/null | wc -l)
    if [ "${N_VIRT_SERVICE}" -ge "1" ]
    then
        ING_TYPE="ISTIO"
        state "Looks like there are "${N_VIRT_SERVICE}" Kubernetes Virtual Services in the namespace, so we assume it's ${ING_TYPE}" 0
    fi

    ## and it it's neither
    ING_TYPE=${ING_TYPE:-UNKNOWN}

}


function Wait_for_Endpoint_success() {
   local MIN_SUCC_RATE=$1
   local SUCC_RATE=0
   local RETRIES=0

   until [ "${SUCC_RATE}" -ge "${MIN_SUCC_RATE}" ]
      do
         local ENDPOINTS_COUNT=0
         local ENDPOINT_CODE=0
         local ENDPOINT=0
         local ENDPOINT_RESULT=""
         local COUNT_FAIL=0
         local COUNT_SUCC=0
         local COUNTER=0
         local URL_COUNTER=0

         RETRIES=$[$RETRIES +1]

        if [[ "${CURL_OUTPUT}" == "blocks" ]]; then
            state "Showing one square for each endpoint checked (--curl-output ${CURL_OUTPUT}), up to ${MAX_CHICKLET_PER_LINE} per line" 2
        fi
        if [[ "${CURL_OUTPUT}" == "lines" ]]; then
            state "Showing one line for each endpoint checked (--curl-output ${CURL_OUTPUT})" 2
        fi

         for url in ${VIYA_URL_LIST[@]}
         do
            COUNTER=$[${COUNTER} +1]
            ENDPOINT=${url%$'\r'}commons/health
            ENDPOINT_CODE=$(curl -L --max-time ${MAX_CURL_TIME} -k -s -o /dev/null -w '%{http_code}' ${ENDPOINT}  | tr -d '[:space:]' )
            URL_COUNTER=$[$URL_COUNTER +1]


            if [[ "${ENDPOINT_CODE}" =~ ^(200)$ ]]
            then
               ENDPOINT_RESULT="Success"
               COUNT_SUCC=$[${COUNT_SUCC} +1]
            else
               ENDPOINT_RESULT="Failure"
               COUNT_FAIL=$[${COUNT_FAIL} +1]
            fi

            if [[ "${CURL_OUTPUT}" == "blocks" ]]; then
                if [[ "${ENDPOINT_RESULT}" == "Success" ]] ; then
                    printf '\e[92m\u25A0 \033[0m'
                else
                    printf '\e[93m\u25A0 \033[0m'
                fi
                ## newline every tenth test
                (( $URL_COUNTER % ${MAX_CHICKLET_PER_LINE} == 0)) && printf '\n'
            fi
            if [[ "${CURL_OUTPUT}" == "lines" ]]; then
                if [[ "${ENDPOINT_RESULT}" == "Success" ]] ; then
                    state "Using curl on ${ENDPOINT} returns HTTP code ${ENDPOINT_CODE}, which is a ${ENDPOINT_RESULT}" 0
                else
                    state "Using curl on ${ENDPOINT} returns HTTP code ${ENDPOINT_CODE}, which is a ${ENDPOINT_RESULT}" 2
                fi
            fi
         done
        printf '\n'

        state "We have checked ${COUNTER} endpoints. We found ${COUNT_SUCC} working, and ${COUNT_FAIL} failing" 0

        if [ "${COUNTER}" -le 0 ]
        then
            state "Because we can't find any endpoints, we can't assess their health" 3
            state "Are you sure there is a Viya in that namespace?" 3
            state "Exiting the script" 3
            exit
        fi


         SUCC_RATE=$(awk -v COUNT_SUCC=${COUNT_SUCC} -v COUNTER=${COUNTER} 'BEGIN{printf("%.0f\n", COUNT_SUCC / COUNTER * 100 )}' )

         if [ "${SUCC_RATE}" -lt "${MIN_SUCC_RATE}" ]
         then
            state "Success Rate (${SUCC_RATE} % ) is lower than the requested minimum (--min-success-rate ${MIN_SUCC_RATE}) %  " 3
            if [[ ${RETRIES} -ge ${MAX_RETRIES} && ${MAX_RETRIES} -ne 0 ]]
            then
               echo -e "Reached Maximum number of tries (--max-retries ${MAX_RETRIES}) before minimum success rate (--min-success-rate ${MIN_SUCC_RATE} ) %. Exiting.  "
               exit ${COUNT_FAIL}
            fi
            state "This was try # ${RETRIES}. Trying again in (--retry-gap ${RETRY_GAP}) seconds, up to (--max-retries ${MAX_RETRIES}) times.  " 3

            POD_STATUS

            sleep ${RETRY_GAP}
         fi
      done

   if [ "${SUCC_RATE}" -ge "${MIN_SUCC_RATE}" ]
   then
      state "Success Rate (${SUCC_RATE} % ) is higher than requested minimum (--min-success-rate ${MIN_SUCC_RATE} ). Not looping anymore." 0
      POD_STATUS
   fi
}


function scaleto() {
   # deployment or statefulset, then the name, then the number.
   state "Scaling k8s $1 called \"$2\" to $3" 1
   if_learn "kubectl -n ${NS} scale $1 $2 --replicas=$3"
   for item in $(kubectl -n ${NS} get $1 $2 --no-headers |  awk '{print $1}')
      do
         cur_desired_replicas=$(kubectl -n ${NS} get $1 ${item} -o=jsonpath='{.status.replicas}' )

         if [ "${cur_desired_replicas}" == "" ]
         then
            cur_desired_replicas=0
         fi

         # echo ${item} ${cur_desired_replicas}
         if [ "${cur_desired_replicas}" == "$3" ]
         then
            state "The desired replicas for Kubernetes $1 called ${item} is already ${cur_desired_replicas}. Skipping." 0
         else
            state "Scaling Kubernetes $1 called ${item} from ${cur_desired_replicas} to $3 replicas. " 2
            kubectl -n ${NS} scale $1 ${item} --replicas=$3  > /dev/null
         fi
      done
}


function conditional_scaleto_one() {
    # deployment or statefulset, then the name, then the number.
    kubectl get sts,deploy -l "app.kubernetes.io/name=sas-rabbit-mq"
}

function waitforpod() {
   PODSTATUS=$(kubectl -n ${NS} get pods | grep $1 | awk '{print $3}')
   while [ "${PODSTATUS}" != "Running" ]
      do
         sleep 5
         PODSTATUS=$(kubectl -n ${NS} get pods | grep Running | grep $1 | awk '{print $3}')
         state "Waiting for pod $1 to be running before continuing" 2
      done
   state "Pod $1 is running. Continuing" 0
}


function waitforcontainers() {
   for pause in 5 5 5 5 5 10 10 10 10 10 20 20 20 20
      do
         CONTAINERSREADY=$(( $(kubectl -n ${NS} get pods  | grep $1 | awk '{print $2}') ))
         if [ "${CONTAINERSREADY}" -lt "1" ]
         then
            state "Waiting for all containers in pod '$1' to start. So far, $(kubectl -n ${NS} get pods  | grep $1 | awk '{print $2}') are running." 2
            sleep ${pause}
         else
            state "All Containers in pod '$1' are running" 0
            break
         fi
      done
}


function curlwaitforhttp() {
   # state "Waiting for endpoint $1 in ${NS} to return an http code of $2." 2
   MYHTTPCODE=$(kubectl -n ${NS} exec -it sas-consul-server-0 -- bash -c 'curl -k -s -o /dev/null -w ''%{http_code}'' sas-viya-httpproxy:8080'$1' | tr -d '[:space:]'')
   # state "Endpoint $1 returned HTTP code: ${MYHTTPCODE}" 2
   while [ "${MYHTTPCODE}" != "$2" ]
      do
         state "Endpoint $1 returned HTTP code: ${MYHTTPCODE}. Was hoping for $2" 2
         state "DEBUG STEP:         kubectl -n ${NS} exec -it sas-viya-httpproxy-0 -- bash -c 'curl -k -v sas-viya-httpproxy:8080$1' " 2
         sleep 5
         MYHTTPCODE=$(kubectl -n ${NS} exec -it sas-viya-httpproxy-0 -- bash -c 'curl -k -s -o /dev/null -w ''%{http_code}'' sas-viya-httpproxy:8080'$1' | tr -d '[:space:]'')
      done
   state "Endpoint $1 in ${NS} is responding with HTTP $2" 0
}


function check_port_inside_pod() {
   # pod, port, good RC:
   MYRC=$(kubectl -n ${NS} exec -it $(podname $1) -- bash -c 'curl -k -s -q -o /dev/null localhost:'$2' ; res=$? ; echo ${res} | tr -d '[:space:]'')
   while [ "${MYRC}" != "$3" ]
      do
         state "Service $1 in ${NS} is not listening on port $2. Got the return code: ${MYRC}. Was hoping for $3" 2
         sleep 5
         MYRC=$(kubectl -n ${NS} exec -it $(podname $1) -- bash -c 'curl -k -s -q -o /dev/null localhost:'$2' ; res=$? ; echo ${res} | tr -d '[:space:]'')
      done
   state "Success! service $1 in ${NS} is listening on port $2" 0
}


function curlwaitforport() {
   # host, port, good RC:
   MYRC=$(kubectl -n ${NS} exec -it sas-viya-httpproxy-0 -- bash -c 'curl -k -s -q -o /dev/null '$1':'$2' ; res=$? ; echo ${res} | tr -d '[:space:]'')
   while [ "${MYRC}" != "$3" ]
      do
         state "Service $1 in ${NS} is not listening on port $2. Got the return code: ${MYRC}. Was hoping for $3" 2
         sleep 5
         MYRC=$(kubectl -n ${NS} exec -it sas-viya-httpproxy-0 -- bash -c 'curl -k -s -q -o /dev/null '$1':'$2' ; res=$? ; echo ${res} | tr -d '[:space:]'')
      done
   state "Success! service $1 in ${NS} is listening on port $2" 0
}


function FIND_URL_LIST() {

    DETERMINE_INGRESS_TYPE

    if  [[ "${ING_TYPE}" == "NGINX" ]]
    then
        VIYA_URL_LIST=($(kubectl -n ${NS} get ing \
                -o custom-columns='host:spec.rules[*].host, backendpath:spec.rules[*].http.paths[*].path' \
                --no-headers \
                | sed 's/[(/|$)(*)]//g'  \
                | sed 's|\.\,ModelStudio||g' \
                | awk  '{  print "http://" $1 "/" $2 "/" }' \
                | sed 's/\.\//\//g' \
                | sed 's/\.\,\//\//g' \
                | sort \
                | uniq \
                ))

        state "Found ${#VIYA_URL_LIST[@]} distinct Kubernetes Ingresses in namespace ${NS}" 0

    elif [[ "${ING_TYPE}" == "ISTIO" ]]
    then

        GATEWAY_HOST=$(kubectl get gateway -n $NS  \
                       -o custom-columns='host:spec.servers[*].hosts[*]' \
                       --no-headers \
                       -l "sas.com/deployment=sas-viya" \
                       | head -n 1\
                       )



        VIYA_URL_LIST=($(kubectl -n ${NS} get virtualservices  \
                    -o custom-columns='backendpath:spec.http[*].match[*].uri.prefix' \
                    --no-headers \
                    | grep -v '\<none\>' \
                    | sed 's|\/SASModelStudio\/\,||g' \
                    | sed 's|\,\,||g' \
                    | sort \
                    | uniq \
                    | awk  -v GATEWAY_HOST="${GATEWAY_HOST}" '{  print "http://" GATEWAY_HOST  $1  }' \
                    ))

        state "Found ${#VIYA_URL_LIST[@]} distinct Virtual Services in namespace ${NS}" 0

        #  for url in ${VIYA_URL_LIST[@]}
        #  do
        #     echo $url
        # done

        #local ING_COUNT="$(VIYA_URL_LIST) | wc -l"
    else
        state "Can't determine what ingress you are using. You cannot use the (--wait) option" 3
        #exit 1
    fi

}


function Find_Service_Names() {
   SERVICE_LIST=($(kubectl -n ${NS} get service \
      -o custom-columns='host:metadata.name' \
      --no-headers  \
         | sort \
         | uniq \
         ))
   SERVICE_LIST_HTTP=($(kubectl -n ${NS} get service  --no-headers \
      | grep ' 80/TCP'  \
      |    awk '{ print $1 }' \
         | sort \
         | uniq \
         ))
   state "Found ${#SERVICE_LIST[@]} distinct Kubernetes Services in namespace ${NS}" 0
   state "Found ${#SERVICE_LIST_HTTP[@]} distinct HTTP Kubernetes Services in namespace ${NS}" 0
}



function STOP_VIYA() {
    if  [[ "${STOP}" == "yes" ]] || [[ "${RESTART}" == "yes" ]]
    then

        state "Pod Status BEFORE Stopping" 1
        POD_STATUS

        state "Scaling statefulsets in the namespace down to zero" 1
        scaleto statefulsets "${K8S_POD_FILTER}" 0

        state "Scaling deployments in the namespace down to zero" 1
        scaleto deployments "${K8S_POD_FILTER}" 0

        #CAS: Delete all the CAS pods that are running:
        state "Stopping CAS by deleting its Pods" 1
        for caspods in $( kubectl -n ${NS} get pod --selector='app.kubernetes.io/managed-by=sas-cas-operator' \
            --no-headers | \
            awk '{print $1}' \
            )
            do
            state "Deleting the CAS Pod called ${caspods} " 2
            kubectl -n ${NS} delete pod ${caspods} > /dev/null &
        done

        # List the pods that are in a completed state and delete them:
        for completedjobs in $( kubectl -n ${NS} get pod --field-selector=status.phase==Succeeded \
            --no-headers | \
            grep Completed| \
            awk '{print $1}' \
            )
            do
            state "Deleting the Completed Kubernetes Job ${completedjobs} " 2
            kubectl -n ${NS} delete  pod ${completedjobs} > /dev/null
        done

        # List the pods that are in an error state and delete them:
        for failedjobs in $( kubectl -n ${NS} get pod --field-selector=status.phase==Failed \
            --no-headers | \
            grep Error | \
            awk '{print $1}' \
            )
            do
            state "Deleting the Failed Kubernetes Job ${failedjobs} " 2
            kubectl -n ${NS} delete  pod ${failedjobs} > /dev/null
        done


        state "Stopping crunchy" 1
        scaleto deployment " -l vendor=crunchydata" 0

        #Suspend all the cron jobs that are running
        for cronjob in $(kubectl -n ${NS} get cronjobs.batch --no-headers \
                         | grep 'sas-' \
                         | grep 'False' \
                         | awk '{print $1}')
        do
            state "Suspending Kubernete Cronjob called ${cronjob}" 2
            kubectl -n ${NS} patch cronjobs ${cronjob}  -p '{"spec" :{"suspend":true}}' \
                > /dev/null
        done

        POD_STATUS

   fi
}

WAIT_FOR_STOP () {

    if  [[ "${STOP}" == "yes" ]] && [[ "${WAIT}" == "yes" ]]
    then
        PODS_LEFT=99
        while [ "${PODS_LEFT}" != "0" ]
        do
            PODS_LEFT=$(kubectl get pods -n ${NS} --no-headers \
                        "${K8S_POD_FILTER}" \
                        | wc -l)
            state "The following pod(s) are still around:" 2
            kubectl get pods -n ${NS}
            sleep 5
        done
        state "All pods seem to be gone! " 0
    fi

}


function START_VIYA() {
   if [[ "${START}" == "yes" ]] || [[ "${RESTART}" == "yes" ]]
   then
        # we will need the manifest
        MANIFEST_CHECK

        #Suspend all the cron jobs that are running
        for cronjob in $(kubectl -n ${NS} get cronjobs.batch --no-headers \
                            | grep 'sas-' \
                            | grep 'True' \
                            | awk '{print $1}')
        do
            state "Un-Suspending Kubernete Cronjob called ${cronjob}" 1
            kubectl -n ${NS} patch cronjobs ${cronjob}  -p '{"spec" :{"suspend":false}}' \
                > /dev/null
        done

        if  [[ "${START_MODE}" == "parallel" ]]
        then

            state "Applying manifest" 1
            CMD="kubectl -n ${NS} apply -f ${MANIFEST} "
            if_learn "${CMD}"
            ${CMD} > /dev/null

            state "Scaling up k8s deployments " 1
            scaleto deployments "${K8S_POD_FILTER}" 1

            # try to force cache server to behave
            kubectl apply -n ${NS} -f ${MANIFEST} \
                --selector="app.kubernetes.io/name=sas-cacheserver" \
                > /dev/null

            # if cache server still has zero replicas, start it up:
            for cacheserver in $( kubectl -n ${NS} get sts --no-headers \
                                | grep sas-cacheserver \
                                | grep '/0' \
                                | awk '{print $1}')
                do
                state "Cache Server (${cacheserver}) is still at zero replicas. Spinning it up to 1" 1
                scaleto statefulset ${cacheserver} 1
            done

        fi

        if [[ "${START_MODE}" == "sequential" ]]
        then

            # scaleto statefulset sas-consul-server 1
            # Start Consul
            state "Starting Consul, if needed" 0
            kubectl apply -n ${NS} -f ${MANIFEST} \
                --selector="app.kubernetes.io/name=sas-consul-server" > /dev/null

            waitforpod sas-consul-server
            waitforcontainers sas-consul-server
            check_port_inside_pod consul 8500 0

            ## better for postgres
            state "Starting Crunchy, if defined in manifest" 0
            kubectl apply -n ${NS} -f ${MANIFEST} \
                --selector="vendor=crunchydata" > /dev/null

            if [ $(kubectl -n ${NS} get deploy  --selector="vendor=crunchydata" --no-headers | wc -l) -gt 0  ]
            then
                waitforpod sas-crunchy-data-postgres-operator
                waitforpod sas-crunchy-data-postgres-backrest


                waitforcontainers sas-crunchy-data-postgres-operator
                waitforcontainers sas-crunchy-data-postgres-backrest


                #waitforpod sas-crunchy-data-postgres
            fi

            ## hard to check postgres when it might not be in K8S.

            state "Starting RabbitMQ, if needed" 0

            # scale up rabbit
            kubectl apply -n ${NS} -f ${MANIFEST} \
                --selector="app.kubernetes.io/name=sas-rabbitmq-server" > /dev/null

            waitforpod sas-rabbitmq-server-0
            #waitforcontainers sas-crunchy-data-postgres-operator
            waitforcontainers sas-rabbitmq-server-0


            # if cache server still has zero replicas, start it up:
            for cacheserver in $( kubectl -n ${NS} get sts --no-headers \
                                | grep sas-cacheserver \
                                | grep '/0' \
                                | awk '{print $1}')
                do
                state "Cache Server (${cacheserver}) is still at zero replicas. Spinning it up to 1" 1
                scaleto statefulset ${cacheserver} 1
            done
            waitforpod sas-cacheserver-0
            waitforcontainers sas-cacheserver-0



            #scaleto deployment " -l vendor=crunchydata" 1
            scaleto deployment sas-cachelocator 1
            waitforpod sas-cachelocator-
            waitforcontainers sas-cachelocator-

            #waitforpod sas-crunchy-data-postgres-operator


            #waitforpod sas-crunchy-data-postgres-backrest
            #waitforcontainers sas-crunchy-data-postgres-backrest
            scaleto deployment sas-logon-app 1
            waitforpod sas-logon-app
            waitforcontainers sas-logon-app


            scaleto deployment sas-identities 1
            waitforpod sas-identities-
            waitforcontainers sas-identities-


            scaleto deployment sas-environment-manager-app 1
            scaleto deployment sas-drive-app 1
            scaleto deployment sas-folders 1
            scaleto deployment sas-folders 1
            scaleto deployment sas-themes 1
            scaleto deployment sas-theme-content 1
            scaleto deployment sas-app-registry 1
            scaleto deployment sas-arke 1
            scaleto deployment sas-cas-operator 1
            scaleto deployment sas-files 1
            scaleto deployment sas-fonts 1
            scaleto deployment sas-links 1
            scaleto deployment sas-launcher 1



            scaleto deployment sas-drive-app 1
            waitforpod sas-drive-app
            waitforcontainers sas-drive-app

            waitforpod sas-environment-manager-app
            waitforcontainers sas-environment-manager-app

            waitforpod sas-cacheserver-0
            waitforcontainers sas-cacheserver-0


            waitforpod sas-cacheserver-0
            waitforcontainers sas-cacheserver-0

            waitforpod sas-logon-app
            waitforpod sas-identities-
            waitforpod sas-drive-app
            waitforcontainers sas-identities-
            waitforcontainers sas-logon-app
            waitforcontainers sas-drive-app

            waitforpod sas-cacheserver-0
            waitforcontainers sas-cacheserver-0

            scaleto deployment "${K8S_POD_FILTER}" 1
            #scaleto sts "${K8S_POD_FILTER}" 1
            waitforpod sas-cacheserver-0
            waitforcontainers sas-cacheserver-0

            kubectl -n ${NS} apply -f ${MANIFEST} > /dev/null
      fi
   state "Pod Status After Starting" 1
   POD_STATUS

   fi
}


function start_deployments() {
   if  [ "$1" == "" ]
   then
       PATT="sas-"
   else
       PATT="$1"
   fi
   local DEPLOYMENT_LIST=($(kubectl -n ${NS} get deploy -o NAME | grep -E "${PATT}"))

   for dep in ${DEPLOYMENT_LIST[@]}
      do
         dep_status=$(kubectl -n ${NS} get ${dep} )
         ### only scale the deployment up to 1 if it's not available yet
      done
}


function WAIT_FOR_ING() {
    if [[ "${WAIT}" == "yes" ]] && [[ "${START}" != "yes" ]] && [[ "${STOP}" == "yes" ]]
    then
        echo "not checking ingresses"
    else
        if [[ "${WAIT}" == "yes" ]]
        then
            Wait_for_Endpoint_success ${MIN_SUCCESS_RATE}
        fi
    fi
}
####################### Functions Definition - End #####################



####################### Parse Command Arguments and Flags - Begin #####################
while [[ $# -gt 0 ]]
   do
      key="$1"
      case ${key} in
         --check-ing)
            shift # past argument
            CHECK_ING="yes"
            ;;
         --dnscheck)
            shift # past argument
            DNSCHECK="yes"
            ;;
         --help|-h|--version|-v)
            shift # past argument
            usage
            exit 0
            ;;
         --health)
            shift # past argument
            HEALTH="yes"
            ;;
         --health-mode|-hm)
            shift # past argument
            ENDPOINT_TEST="$1"
            shift # past value
            ;;
         --ingress|--ingress-host|-i)
            shift # past argument
            INGRESS_PREFIX="$1"
            shift # past value
            ;;
         --ingress-port|-p)
            shift # past argument
            INGRESS_PREFIX="$1"
            shift # past value
            ;;
         --learn)
            shift # past argument
            LEARN="yes"
            ;;
         --manifest)
            shift # past argument
            MANIFEST="$1"
            shift # past argument
            ;;
         --max-retries)
            shift # past argument
            MAX_RETRIES="$1"
            shift # past argument
            ;;
         --min-success-rate)
            shift # past argument
            MIN_SUCCESS_RATE="$1"
            shift # past value
            ;;
         --namespace|-n)
            shift # past argument
            NS="$1"
            shift # past value
            ;;
        #  --output-type|-o)
        #     shift
        #     OUTPUT_TYPE="$1"
        #     shift
        #     ;;
         --pod-status|-ps)
            shift # past argument
            POD_STATUS="yes"
            ;;
         --restart)
            shift # past argument
            RESTART="yes"
            ;;
         --retry-gap)
            shift # past argument
            RETRY_GAP="$1"
            shift # past value
            ;;
         --start)
            shift # past argument
            START="yes"
            ;;
         --start-mode)
            shift # past argument
            START_MODE="$1"
            shift # past value
            ;;
         -co|--curl-output)
            shift # past argument
            CURL_OUTPUT="$1"
            shift # past value
            ;;
         --status)
            shift # past argument
            STATUS="yes"
            ;;
         --stop)
            shift # past argument
            STOP="yes"
            ;;
         --verbose)
            shift # past argument
            VERBOSE=true
            ;;
         --wait)
            shift # past argument
            WAIT="yes"
            ;;
         *)
            usage
            echo -e "\n\nOne or more arguments were not recognized: \n$@"
            echo
            exit 1
            shift # past argument
            ;;
      esac
   done
####################### Parse Command Arguments and Flags - End #####################



####################### Main - Begin #####################
# Start_deployments

# State "Chosen namespace is : ${NS} " 0

if [[ "${INGRESS_PREFIX}" == "" ]] || [[ "${INGRESS_PREFIX}" == "auto" ]]
then
   # INGRESS_PREFIX=$(kubectl describe  ing -n ${NS}  | grep insecure | head -n 1 | awk '{print $1}')
   echo
fi

# State "The Ingress hostname is: ${INGRESS_PREFIX}" 0
if [[ "${DNSCHECK}" == "yes" ]]
then
   for p in $(kubectl get pods -n ${NS} | grep Running | awk  '{ print $1 }' )
      do
         NODE=$(kubectl -n ${NS} describe pod ${p}  | grep 'Node\:' | awk '{ print $2 }' )
         DNS=$(kubectl -n ${NS} exec  ${p} -- bash -c ' ping -q -W 1 -c 1 sas-viya-httpproxy &> /dev/null ; echo $? ')
         if [ "${DNS}" -eq 0 ]
         then
            state "On node ${NODE}, inside of pod ${p}, the DNS is ................Working" 0
         else
            state "On node ${NODE}, inside of pod ${p}, the DNS is ................Failing" 3
         fi
   done
fi

state "gel_OKViya4 Version: ${gel_OKViya4_VERSION} " 0

if_learn "Get your LEARN on! \n \
You have enabled the learn mode, which will be a lot slower but a lot more descriptive"

# Check that the namespace is provided and accurate
NS_Check

CADENCE_VERSION

# # Check that the manifest is provided
# MANIFEST_CHECK

# determine the names.
FIND_URL_LIST
Find_Service_Names

# Stop Viya (if asked)
STOP_VIYA

WAIT_FOR_STOP

# Start Viya (if asked)
START_VIYA

POD_STATUS

# Wait for all the ingresses to be healthy
WAIT_FOR_ING
####################### Main - End #####################
