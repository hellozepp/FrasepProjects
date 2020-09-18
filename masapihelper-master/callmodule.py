import requests, base64, jwt, json


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
user     = config['username']
password = config['password']
baseurl  = config['baseurl']

headers = {}


#print(user + password + baseurl)

########## Step 1 - get token ##########
########################################

url = baseurl+ '/SASLogon/oauth/token'

querystring = {"grant_type":"password","username":user,"password":password}
#querystring = {"grant_type":"password"}

headers = {
    'Authorization': "Basic c2FzLmVjOg==",
    'Cache-Control': "no-cache"
    }

response = requests.request("GET", url, headers=headers, params=querystring)
step1_json = json.loads(response.text)
 
#print(step1_json['access_token'])


########## Step 2 - get public modules ###########
##################################################

url = baseurl+ '/microanalyticScore/modules/'

headers = {'Authorization': "Bearer " + step1_json['access_token']}

response = requests.request("GET", url, headers=headers)
step2_json = json.loads(response.text)

modules = []

#print(step2_json['items'])
print('\n')

for item in step2_json['items']:
    if item['scope'] == 'public':
        module = { 'name': item['name'], 'id': item['id'], 'inputs':[], 'outputs': []}
        #print(item['name'])
        modules.append(module)
        

    
########## Step 3 - get module variables ###########
####################################################


headers = {'Authorization': "Bearer " + step1_json['access_token']}

# get in and output variables per module
id = 0
for module in modules:
    url = baseurl+ '/microanalyticScore/modules/'+module['id']+'/steps'
    response = requests.request("GET", url, headers=headers)
    step3_json = json.loads(response.text)

    # save attributes to the module object
    for item in step3_json['items']:
        if item['id'] == 'execute':
            #print(item['name'])
            modules[id]['outputs'] = item['outputs']
            modules[id]['inputs'] = item['inputs']
            
    id = id+1

#pretty print the json objects
print(json.dumps(modules, indent=4, sort_keys=True))