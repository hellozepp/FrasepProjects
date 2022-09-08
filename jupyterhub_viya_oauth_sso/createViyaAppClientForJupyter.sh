# To be customized
export VIYA_BASE_URL=https://frasepviya35vm1.cloud.com
export JUPYTERHUB_BASE_URL=https://frasepviya35vm1.cloud.com:8443
export CLIENTID=jupyterapp2
export CLIENTSECRET=jupsecret

# Get viya token
# Use the SAS Viya Consul token to obtain a SASLogon access token in order to register a new application:
# As a sudo user, run the following commands from the server where consul lives. Update VIYA_BASE_URL with the base url used to access Viya web applications.

export CONSUL_TOKEN=`sudo cat /opt/sas/viya/config/etc/SASSecurityCertificateFramework/tokens/consul/default/client.token`
export ACCESS_TOKEN=`curl -k -X POST "$VIYA_BASE_URL/SASLogon/oauth/clients/consul?callback=false&serviceId=app" -H "X-Consul-Token: $CONSUL_TOKEN" | jq .access_token | tr -d \"`

# Register a new client using the access token with the authorization_code and refresh_token grant types. Update export JUYPYTERHUB_BASE_URL=
# with the base URL to access JupyterHub, and client_id and client_secret with your own values.
 
curl -k -X POST "$VIYA_BASE_URL/SASLogon/oauth/clients" \
-H "Content-Type: application/json" \
-H "Authorization: Bearer $ACCESS_TOKEN" \
-d "{
 \"client_id\": \"$CLIENTID\", 
 \"client_secret\": \"$CLIENTSECRET\",
 \"scope\": [\"openid\"],
 \"authorized_grant_types\": [\"authorization_code\",\"refresh_token\"],
 \"redirect_uri\": \"$JUPYTERHUB_BASE_URL/hub/oauth_callback\",
 \"access_token_validity\": 1296000,
 \"autoapprove\": true
}"

