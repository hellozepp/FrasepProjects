# Define environement, token and connection
source /opt/sas/viya/config/consul.conf
#/opt/sas/viya/home/bin/sas-admin profile show
/opt/sas/viya/home/bin/sas-admin auth login
# Show members of the selected folder
/opt/sas/viya/home/bin/sas-admin --output text folders list-members --path /public --recursive --tree

# Get folder id to export
folderid=$(/opt/sas/viya/home/bin/sas-admin --output json folders show --path /public | jq | jq -r '.["id"]')
# Generate the export package (in SAS Viya source environmenet content
/opt/sas/viya/home/bin/sas-admin --output text transfer export -u /folders/folders/$folderid --name publicExport$folderid
# Get generated package id and download the generated package for further delivery
packageid=$(/opt/sas/viya/home/bin/sas-admin --output json transfer list --name publicExport$folderid | jq | jq -r '.items[]["id"]')
/opt/sas/viya/home/bin/sas-admin transfer download -f /tmp/viyaExport_publicExport.json --id $packageid

# Connection on target environment
# Define environement, token and connection
source /opt/sas/viya/config/consul.conf
#/opt/sas/viya/home/bin/sas-admin profile show
/opt/sas/viya/home/bin/sas-admin auth login
# upload the exported package and generate associated mapping file
/opt/sas/viya/home/bin/sas-admin --output json transfer upload --file /tmp/viyaExport_publicExport.json -m /tmp/viyaExport_publicExport_mapping.json
importpackageid=$(/opt/sas/viya/home/bin/sas-admin --output json transfer list --filter "startsWith(name,publicExport)" | jq | jq -r '.items[]["id"]')
# Check content of the package details and with tree view
# /opt/sas/viya/home/bin/sas-admin --output text transfer show --details --id $importpackageid
# /opt/sas/viya/home/bin/sas-admin --output text transfer show --tree --id $importpackageid
# Import actually the package in the SAS Viya content
/opt/sas/viya/home/bin/sas-admin --output text transfer import --id $importpackageid