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

#config     = readConfig('config.txt')
serverport = 8077
serverip   = socket.gethostbyname(socket.gethostname())
flaskDebug = False
print(serverip)

token    = ''

headers = {}


app = Flask(__name__)

@app.route("/")
def index():
  return render_template("index.html")

@app.route("/about")
def about():
  return render_template("about.html")






#### API ####
@app.route('/api/getconfig', methods=['GET'])
def get_config():
    print('Get config')
    config = readConfig('config.txt')
    config['baseUrlList'] = config['baseurl'].split()
    print(config)
    return jsonify(config)
    

@app.route('/api/gettoken', methods=['POST'])
def get_token():
    print('Get Token call initiated...')
    if not request.json or not 'user' in request.json:
        abort(400)
        
    #print(request.json)
        
    url = "http://" +request.json['baseUrl']+ '/SASLogon/oauth/token'
    print('url: ' + url)

    querystring = {"grant_type":"password","username":request.json['user'],"password":request.json['password']}
    #print(querystring)

    userpassbytes = bytes('sas.ec:', 'utf-8') ## username:password ### user: sas.ec and password is null
    userAndPass = base64.b64encode(userpassbytes).decode("ascii")
    headers = { 'Authorization' : 'Basic %s' %  userAndPass, "Content-Type": "application/json" }
    #print('headers: ' + json.dumps(headers))

    #headers = {'Authorization': "Basic c2FzLmVjOg==",'Cache-Control': "no-cache"}

    response = requests.request("GET", url, headers=headers, params=querystring)
    #print(response)
    step1_json = json.loads(response.text)
    
    if hasattr(step1_json, 'error'):
    #if (step1_json['error'] == 'unauthorized' ):
        print(step1_json) # {'error': 'unauthorized', 'error_description': 'Bad credentials'}
    #else:
        #token = step1_json['access_token']
    
    return jsonify(step1_json)
    

@app.route('/api/getmodules', methods=['POST'])
def get_modules():
    print('Get Modules call initiated...')
    token = request.json['token']
    

    ########## Step 2 - get public modules ###########
    ##################################################

    url = "http://" +request.json['baseUrl']+ '/microanalyticScore/modules?limit=400'
    print('url: ' + url)
    headers = {'Authorization': "Bearer " + token}
    #print('token: ' + token)

    response = requests.request("GET", url, headers=headers)
    #print(response.text)
    step2_json = json.loads(response.text)
    #print(json.dumps(step2_json, indent=4, sort_keys=True))

    modules = []

    #print(step2_json['items'])
    print('\n')

    for item in step2_json['items']:
        if item['scope'] == 'public':
            module = { 'name': item['name'], 'id': item['id'], 'inputs':[], 'outputs': []}
            modules.append(module)

    return jsonify(modules)

@app.route('/api/getmoduleparameters', methods=['POST'])
def get_module_parameters():
    print('Get Modules Parameters call initiated...')
    
    ########## Step 3 - get module variables ###########
    ####################################################
    token = request.json['token']
    headers = {'Authorization': "Bearer " + token}
    moduleid = request.json['moduleid']
    moduleParameters = {}

    url = "http://" +request.json['baseUrl']+ '/microanalyticScore/modules/'+moduleid+'/steps'
    response = requests.request("GET", url, headers=headers)
    #print(response)
    step3_json = json.loads(response.text)
    # save attributes to the module object
    for item in step3_json['items']:
        if item['id'] == 'execute' or item['id'] == 'score':
            moduleParameters['outputs'] = item['outputs']
            moduleParameters['inputs'] = item['inputs']
            moduleParameters['itemType'] = item['id']
            
    return jsonify(moduleParameters)


@app.route('/api/calldecision', methods=['POST'])
def call_decision():
    print('Call Decision initiated...')
    print(request.json)
    
    ########## Step 4 - call decision ###########
    #############################################
    token = request.json['token']
    itemType = request.json['itemType']
    ssl = request.json['ssl']
    headers = {'Content-Type': "application/json", 'Authorization': "Bearer " + token }
    moduleid = request.json['moduleid']
    payload = json.dumps(request.json['payload'])
    
    #url = "http://" +request.json['baseUrl']+ '/microanalyticScore/modules/'+moduleid+'/steps/execute'
    url = "http://" +request.json['baseUrl']+ '/microanalyticScore/modules/'+moduleid+'/steps/'+itemType
    if (ssl == True ):
      print('USE SSL')
      url = url.replace("http", "https")
    else:
      print('NO SSL')
    
    errortext=''
    try:
      response = requests.request("POST", url, data=payload, headers=headers)   
    except requests.exceptions.RequestException as e:  # This is the correct syntax
      print('---error start---')
      print(e)
      errortext=str(e)
      print('---error end---')
    
    if ( errortext == '' ):
      step4_json = json.loads(response.text)
    else:
      step4_json = { 'error': errortext }

    print("Call Decision Response: ")
    #print(json.dumps(step4_json, indent=4, sort_keys=True))
    
    return jsonify(step4_json)

if __name__ == "__main__":
  #app.run(debug=True)
  app.run(host='0.0.0.0',port=serverport,debug=flaskDebug)
