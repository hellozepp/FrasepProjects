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

viya_host = "localhost"
port = ":80"
host_url="http://" + viya_host + port
destination_url = host_url + "/modelPublish/destinations/"

mm_auth = mmAuthorization.mmAuthorization("myAuth")

admin_userId = "SAS_USER_ADMIN_ID"
user_passwd = "SAS_USER_PASSWD"

admin_auth_token = mm_auth.get_auth_token(host_url, admin_userId, user_passwd)

destination_admin_headers = {
    mmAuthorization.AUTHORIZATION_HEADER: mmAuthorization.AUTHORIZATION_TOKEN + admin_auth_token
}

destination_aws_headers = {
    "If-Match":"false",
    "Content-Type":"application/vnd.sas.models.publishing.destination.aws+json",
    mmAuthorization.AUTHORIZATION_HEADER: mmAuthorization.AUTHORIZATION_TOKEN + admin_auth_token
}

# create new destination, expecting 201
dest_name = "AWS"
print("Creating " + dest_name + " destination...")

destination_attrs = {
    "name":dest_name,
    "destinationType":"aws",
     "properties": [{"name": "accessKeyId",                
                 "value": "MY_AWS_KEY_ID"},
                {"name": "secretAccessKey",                 
                 "value": "MY_AWS_ACCESS_KEY"},
                {"name": "region",                 
                 "value": "us-east-1"},
                {"name": "kubernetesCluster",                 
                 "value": "MY_EKS_NAME"}
                   ]
}

destination = requests.post(destination_url, 
                       data=json.dumps(destination_attrs), headers=destination_aws_headers)

print(destination)

