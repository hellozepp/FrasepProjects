import requests, base64, jwt, json, socket
from flask import Flask, render_template, jsonify, abort, make_response, request, url_for

##### functions #####
def readConfig(configFile):
    keys = {}
    seperator = '='
    with open(configFile) as f:
        for line in f:
            if line.startswith('#') == False and seperator in line: 
                # Find the name and value by splitting the string
                name, value = line.split(seperator, 1)
                # Assign key value pair to dict
                keys[name.strip()] = value.strip()
    return keys
#####################

config   = readConfig('config.txt')
serverport = 8080
serverip = socket.gethostbyname(socket.gethostname())
print(serverip)
user     = config['username']
password = config['password']
baseurl  = config['baseurl']
token    = ''

headers  = {}


        
url = "http://" +baseurl+ '/SASLogon/oauth/token'
print('url: ' + url)
querystring = {"grant_type":"password","username":user,"password":password}
#print(querystring)

#userpassbytes = bytes('sas.ec:', 'utf-8') ## username:password ### user: sas.ec and password is null
#userAndPass = base64.b64encode(userpassbytes).decode("ascii")
#headers = { 'Authorization' : 'Basic %s' %  userAndPass, "Content-Type": "application/json" }
headers = {'Authorization': "Basic c2FzLmVjOg==",'Cache-Control': "no-cache"}
print('headers: ' + json.dumps(headers))

response = requests.request("GET", url, headers=headers, params=querystring)
print(response)
step1_json = json.loads(response.text)
print(step1_json)
    
if hasattr(step1_json, 'error'):
    print(step1_json) # {'error': 'unauthorized', 'error_description': 'Bad credentials'}

    

