import os
import warnings
import urllib
import json
from oauthenticator.generic import GenericOAuthenticator
from tornado.httputil import url_concat
from tornado.httpclient import HTTPRequest, AsyncHTTPClient, HTTPClientError
 
class SASViyaOAuthenticator(GenericOAuthenticator):
    # Pass access token to notebook server as environment variable
    async def pre_spawn_start(self, user, spawner):
        auth_state = await user.get_auth_state()
        if not auth_state:
            return
 
        spawner.environment['ACCESS_TOKEN'] = auth_state['access_token']
        
        # BLOC A ADAPTER
        spawner.environment['CAS_CLIENT_SSL_CA_LIST'] = '/opt/sas/viya/config/etc/SASSecurityCertificateFramework/cacerts/trustedcerts.pem'
        # FIN DU BLOC A ADAPTER

        self.log.info("Passing refresh token variable to user spawn process %s", auth_state['refresh_token'])
 
    # Refresh user access and refresh tokens (called periodically, defined by auth_refresh_age)
    async def refresh_user(self, user, handler=None):
        auth_state = await user.get_auth_state()
        if not auth_state:
            return
 
        http_client = AsyncHTTPClient()
 
        access_token = auth_state['access_token']
        refresh_token = auth_state['refresh_token']
 
        # Check to see if current access_token is valid by calling userdata_url. 
        # Will get 200 OK if valid, 401 Unauthorized if expired. 
        req = HTTPRequest(self.userdata_url,
                      method="GET",
                      headers={"Authorization":"Bearer %s" % access_token},
                      validate_cert=self.tls_verify,
                      )
 
        try:
            resp = await http_client.fetch(req)
            # Token doesn't need to be refreshed. 
            if resp.code == 200: 
                return True
        except HTTPClientError:
            self.log.info("Refreshing OAuth Access Token...")
 
        if self.token_url:
            url = self.token_url
        else:
            raise ValueError("Please set the OAUTH2_TOKEN_URL environment variable")
 
        params = dict(
            grant_type = 'refresh_token',
            refresh_token = refresh_token
        )
        headers = {
        "Content-Type": "application/x-www-form-urlencoded"
        }
 
        # Refresh token
        req = HTTPRequest(url,
                      method="POST",
                      headers=headers,
                      auth_username=self.client_id,
                      auth_password=self.client_secret,
                      validate_cert=self.tls_verify,
                      body=urllib.parse.urlencode(params)  # Body is required for a POST...
                      )
 
        resp = await http_client.fetch(req)
 
        resp_json = json.loads(resp.body.decode('utf8', 'replace'))
 
        access_token = resp_json['access_token']
        refresh_token = resp_json.get('refresh_token', None)
        token_type = resp_json['token_type']
        scope = resp_json.get('scope', '')
        if (isinstance(scope, str)):
            scope = scope.split(' ')
 
       # Determine who the logged in user is
        headers = {
            "Accept": "application/json",
            "User-Agent": "JupyterHub",
            "Authorization": "{} {}".format(token_type, access_token)
        }
 
        if self.userdata_url:
            url = url_concat(self.userdata_url, self.userdata_params)
        else:
            raise ValueError("Please set the OAUTH2_USERDATA_URL environment variable")
 
        if self.userdata_token_method == "url":
            url = url_concat(self.userdata_url, dict(access_token=access_token))
 
        req = HTTPRequest(url,
                        method=self.userdata_method,
                        headers=headers,
                        validate_cert=self.tls_verify,
                        )
 
        resp = await http_client.fetch(req)
        resp_json = json.loads(resp.body.decode('utf8', 'replace'))
 
        if not resp_json.get(self.username_key):
            self.log.error("OAuth user contains no key %s: %s", self.username_key, resp_json)
            return
 
        refresh_user_return = {
            'name': resp_json.get(self.username_key),
            'auth_state': {
                'access_token': access_token,
                'refresh_token': refresh_token,
                'oauth_user': resp_json,
                'scope': scope,
            }
        }
 
        return refresh_user_return
 
c.JupyterHub.authenticator_class = SASViyaOAuthenticator

# BLOC A ADAPTER
c.GenericOAuthenticator.client_id = 'jupyterapp2'
c.GenericOAuthenticator.client_secret = 'jupsecret'
c.GenericOAuthenticator.callback_url = 'https://frasepViya35vm1.cloud.com:8443/hub/oauth_callback'
c.GenericOAuthenticator.token_url = 'https://frasepViya35vm1.cloud.com/SASLogon/oauth/token'
c.GenericOAuthenticator.authorize_url = 'https://frasepViya35vm1.cloud.com/SASLogon/oauth/authorize'
c.GenericOAuthenticator.userdata_url = 'https://frasepViya35vm1.cloud.com/SASLogon/userinfo'
c.GenericOAuthenticator.username_key = 'user_name'
# FIN DU BLOC A ADAPTER

c.GenericOAuthenticator.auto_login = True
c.GenericOAuthenticator.auth_refresh_age = 21600
c.GenericOAuthenticator.refresh_pre_spawn = True
c.GenericOAuthenticator.tls_verify = False
 
c.GenericOAuthenticator.enable_auth_state = True
 
if 'JUPYTERHUB_CRYPT_KEY' not in os.environ:
    warnings.warn(
        "Need JUPYTERHUB_CRYPT_KEY env for persistent auth_state.\n"
        "    export JUPYTERHUB_CRYPT_KEY=$(openssl rand -hex 32)"
    )
    c.CryptKeeper.keys = [ os.urandom(32) ]