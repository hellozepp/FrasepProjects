
NS=mailtest

rm -rf ~/project/deploy/${NS}
mkdir ~/project/deploy/${NS}
cd ~/project/deploy/${NS}/

kubectl delete ns ${NS}
kubectl  create ns ${NS}

kubectl delete ns testready dailymirror

kubectl -n ${NS} apply -f ~/project/gelldap/gelldap-manifest.yaml

kubectl apply -n ${NS} -f https://gelgitlab.race.sas.com/GEL/utilities/gelldap/-/raw/master/gelmail-manifest.yaml


tee  ~/project/deploy/${NS}/mail.yaml > /dev/null << EOF
  mail:
    sas.mail:
      host: 'gelmail-service'
      port: '1025'
      properties:
        mail.debug: 'false'
    management.health.mail:
      enabled: 'true'
EOF
cd ~/project/deploy/${NS}/
cat ../testready/site-config/gelldap-sitedefault.yaml ./mail.yaml > mail-sitedefault.yaml

tee  ~/project/deploy/${NS}/kustomization.yaml > /dev/null << EOF
---
namespace: ${NS}
resources:
  - ../testready/

configMapGenerator:
  - name: ingress-input
    behavior: merge
    literals:
      - INGRESS_HOST=${NS}.pdcesx02002.race.sas.com
  - name: sas-shared-config
    behavior: merge
    literals:
      - SAS_URL_SERVICE_TEMPLATE=http://${NS}.pdcesx02002.race.sas.com
  - name: sas-consul-config
    behavior: merge
    files:
      - SITEDEFAULT_CONF=mail-sitedefault.yaml

EOF


cd ~/project/deploy/${NS}/
kustomize build -o ${NS}-manifest.yaml
diff ../testready/site.yaml  ${NS}-manifest.yaml

kubectl apply -n ${NS} -f ${NS}-manifest.yaml



function cons_kv() {

# replace with your namespace
NS=$1
# name of consul pod (might be dynamic in the future?
CONSUL_POD_NAME=sas-consul-server-0

# create the count_reg script
tee  ./kv_read.sh > /dev/null << "EOF"
SASDELPOYMENTROOT=/opt/sas
SASDELPOYMENTID=viya
TOKEN_FILE="${SASDELPOYMENTROOT}/${SASDELPOYMENTID}/config/etc/SASSecurityCertificateFramework/tokens/consul/default/client.token"

#${SASDELPOYMENTROOT}/${SASDELPOYMENTID}/home/bin/sas-bootstrap-config  --token-file $TOKEN_FILE kv read  config/application --recurse
${SASDELPOYMENTROOT}/${SASDELPOYMENTID}/home/bin/sas-bootstrap-config  --token-file $TOKEN_FILE kv read /  --recurse

EOF

# copy the script into the consul pod
kubectl -n $NS cp ./kv_read.sh  ${CONSUL_POD_NAME}:/tmp/kv_read.sh

# execute the script inside the pod
kubectl -n $NS exec -it ${CONSUL_POD_NAME} -- /bin/bash -c 'bash /tmp/kv_read.sh'

}

cons_kv mailtest

cons_kv mailtest | grep mail

gel_OKViya4 --wait -n mailtest