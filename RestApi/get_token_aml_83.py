def vitapy_get_token(VIPROTOCOL, VIPORT, VIHOST, VITENANT, VIDBOWNER, VIDBPASSWORD, VIUSERNAME, VIPASSWORD, top_debug, service):

    import requests
    import base64

    if service == 'viya':
        VIURL=vitapy_build_vi_url(VIPROTOCOL, VIPORT, VIHOST, VITENANT)
        requestUrl = (VIURL + '/SASLogon/oauth/token')
        requestHeaders = {'Accept': 'application/json','Content-Type': 'application/x-www-form-urlencoded'}

        if VIPROTOCOL == 'http':
            resp = requests.post(url=requestUrl,
            headers=requestHeaders,
            auth=('sas.ec', ''),
            data='grant_type=password&username=' + VIUSERNAME + '&password=' + VIPASSWORD)
        else:
            resp = requests.post(url=requestUrl,
            headers=requestHeaders,
            auth=('sas.ec', ''),
            data='grant_type=password&username=' + VIUSERNAME + '&password=' + VIPASSWORD,verify=False)
            json = resp.json()

            if 'access_token' in json:
                token=json['access_token']
            else:
                token='X'
            elif service == 'sirene':
                requestUrl=sirene_auth_endpoint
                userpass=sirene_consumer_key + ":" + sirene_consumer_secret
                userpass_b64=base64.b64encode(userpass.encode())
                requestHeaders = { 'Authorization': "Basic " + format(userpass_b64.decode()) }
                resp = requests.post(url=requestUrl,
                headers=requestHeaders,
                data='grant_type=client_credentials')
                json = resp.json()
                if 'access_token' in json:
                    token=json['access_token']
                else:
                    token='X'
                elif service == 'pappers':
                    token=papper_api_key
                elif service == 'opencorporates':
                    token="xxxxxx"
                else:
                    print('Not yet implemented')
                    if top_debug == "Y":
                        print(token)
return(token)