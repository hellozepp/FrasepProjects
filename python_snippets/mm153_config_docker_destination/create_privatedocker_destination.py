#
# Copyright (c) 2019, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

import mmAuthorization
import requests
import json

viya_host = "frasepviya35smp.cloud.com"
port = ":80"
host_url="http://" + viya_host + port
destination_url = host_url + "/modelPublish/destinations/"

mm_auth = mmAuthorization.mmAuthorization("myAuth")

admin_userId = "viyademo01"
user_passwd = "demopw"

admin_auth_token = mm_auth.get_auth_token(host_url, admin_userId, user_passwd)

destination_privatedocker_headers = {
    "If-Match":"false",
    "Content-Type":"application/vnd.sas.models.publishing.destination.privatedocker+json",
    mmAuthorization.AUTHORIZATION_HEADER: mmAuthorization.AUTHORIZATION_TOKEN + admin_auth_token
}

# create new destination, expecting 201
dest_name = "PrivateDocker"
print("Creating " + dest_name + " destination...")

destination_attrs = {
    "name":dest_name,
    "destinationType":"privateDocker",
     "properties": [{"name": "baseRepoUrl",
                     "value": "90.127.115.247"},
                    {"name": "dockerHost",
                     "value": "tcp://90.127.115.247:5000"}
                   ]
}

destination = requests.post(destination_url, 
                       data=json.dumps(destination_attrs), headers=destination_privatedocker_headers)

print(destination)
