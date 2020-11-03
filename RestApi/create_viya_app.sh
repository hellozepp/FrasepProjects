export TOKEN=`cat /opt/sas/viya/config/etc/SASSecurityCertificateFramework/tokens/consul/default/client.token`
export TOKEN=`curl -X POST "http://frasepviya35smp.cloud.com/SASLogon/oauth/clients/consul?callback=false&serviceId=frasepapp"  -H "X-Consul-Token: $TOKEN" | python -m json.tool | grep "\"access_token\"" | awk -F[\:,] '{print $2}' | tr -d \"`

curl -X POST "http://frasepviya35smp.cloud.com/SASLogon/oauth/clients" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $TOKEN" \
        -d '{ 
          "client_id": "frasepapp", 
          "client_secret": "frasepsecret", 
          "scope": ["openid"], 
          "authorized_grant_types": ["password"], 
          "access_token_validity": 43199 
         }' | python -m json.tool

