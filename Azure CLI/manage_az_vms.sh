az login

az vm list --output table

# Show details of a selection of vm in a specified resource group
az vm list --resource-group FRASEPVIYA35MPP_RG --output table | cut -f1,3 -d" " | xargs -n2 sh -c 'az vm show --name "$0" --resource-group "$1"'

# Deallocate a selection of vm (with specific resource group)
az vm list --resource-group FRASEPVIYA35MPP_RG --output table | cut -f1,3 -d" " | xargs -n2 sh -c 'az vm deallocate --name "$0" --resource-group "$1" --verbose'

# start a selection of vm
az vm list --resource-group FRASEPVIYA35MPP_RG --output table | cut -f1,3 -d" " | xargs -n2 sh -c 'az vm start --name "$0" --resource-group "$1" --verbose'

# Start a specific VM
az vm start --name frasepviya35smp.cloud.com --resource-group FRASEPVIYA35MONOSERVER_RG --verbose