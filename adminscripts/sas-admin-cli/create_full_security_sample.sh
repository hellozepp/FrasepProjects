# Create groups
/opt/sas/viya/home/bin/sas-admin identities create-group --name "NACSELPoleObsNat" --id NACSELPoleObsNat --description "NACSEL : Pôle observatoire National"
/opt/sas/viya/home/bin/sas-admin identities create-group --name "NACSELRefExpert" --id NACSELRefExpert --description "NACSEL : Référents expert"
/opt/sas/viya/home/bin/sas-admin identities create-group --name "NACSELRefNonExpert" --id NACSELRefNonExpert --description "NACSEL : référents non expert "
/opt/sas/viya/home/bin/sas-admin identities create-group --name "NACSELDirRegion" --id NACSELDirRegion --description "NACSEL : Directeur régional "

# Create capabilities limits groups
/opt/sas/viya/home/bin/sas-admin identities create-group --name "OnlyVADesigner" --id OnlyVADesigner --description "Only VA view and edit"
/opt/sas/viya/home/bin/sas-admin identities create-group --name "OnlyVAReader" --id OnlyVAReader --description "Only VA view"

# Defined Create capabilities limits groups
# OnlyVADesigner

/opt/sas/viya/home/bin/sas-admin authorization prohibit --permissions "read" --object-uri /SASDataStudio/** --group OnlyVADesigner
/opt/sas/viya/home/bin/sas-admin authorization prohibit --permissions "read" --object-uri /ModelStudio/** --group OnlyVADesigner
/opt/sas/viya/home/bin/sas-admin authorization prohibit --permissions "read" --object-uri /SASStudioV/** --group OnlyVADesigner
/opt/sas/viya/home/bin/sas-admin authorization prohibit --permissions "read" --object-uri /SASWorkflowManager/** --group OnlyVADesigner
/opt/sas/viya/home/bin/sas-admin authorization prohibit --permissions "read" --object-uri /SASThemeDesigner/** --group OnlyVADesigner
/opt/sas/viya/home/bin/sas-admin authorization prohibit --permissions "read" --object-uri /SASModelManager/ --group OnlyVADesigner
/opt/sas/viya/home/bin/sas-admin authorization prohibit --permissions "read" --object-uri /SASModelManager --group OnlyVADesigner
/opt/sas/viya/home/bin/sas-admin authorization prohibit --permissions "read" --object-uri /SASGraphBuilder/** --group OnlyVADesigner
/opt/sas/viya/home/bin/sas-admin authorization prohibit --permissions "read" --object-uri /SASLineage/** --group OnlyVADesigner

# Apply rules on accessible GUIs (OnlyVAReader)
/opt/sas/viya/home/bin/sas-admin authorization prohibit --permissions "read" --object-uri /SASVisualAnalytics_capabilities/edit --group OnlyVAReader

# Affect group to capability group
/opt/sas/viya/home/bin/sas-admin identities add-member  --group-id OnlyVADesigner  --group-member-id NACSELRefExpert
/opt/sas/viya/home/bin/sas-admin identities add-member  --group-id OnlyVADesigner  --group-member-id NACSELRefNonExpert
/opt/sas/viya/home/bin/sas-admin identities add-member  --group-id OnlyVADesigner  --group-member-id NACSELDirRegion
/opt/sas/viya/home/bin/sas-admin identities add-member  --group-id OnlyVAReader  --group-member-id NACSELRefNonExpert
/opt/sas/viya/home/bin/sas-admin identities add-member  --group-id OnlyVAReader  --group-member-id NACSELDirRegion

# Affect users to groups
/opt/sas/viya/home/bin/sas-admin identities add-member  --group-id NACSELPoleObsNat  --user-member-id provuser01
/opt/sas/viya/home/bin/sas-admin identities add-member  --group-id NACSELRefExpert  --user-member-id provuser02
/opt/sas/viya/home/bin/sas-admin identities add-member  --group-id NACSELRefNonExpert  --user-member-id provuser03
/opt/sas/viya/home/bin/sas-admin identities add-member  --group-id NACSELDirRegion  --user-member-id provuser04

# Create folder and secure access
FOLDER_ID1=`/opt/sas/viya/home/bin/sas-admin folders create --name "NACSEL" --description "Application NACSEL : production"  | grep \"id\": | cut -f4 -d\"`
FOLDER_ID2=`/opt/sas/viya/home/bin/sas-admin folders create --name "reports" --parent-path "/NACSEL" --description "Application NACSEL : reports"  | grep \"id\": | cut -f4 -d\"`
FOLDER_ID3=`/opt/sas/viya/home/bin/sas-admin folders create --name "jobs" --parent-path "/NACSEL" --description "Application NACSEL : jobs"  | grep \"id\": | cut -f4 -d\"`

# Apply rules on main folder
/opt/sas/viya/home/bin/sas-admin authorization create-rule --permissions "read,update,add" --object-uri /folders/folders/$FOLDER_ID1 --group NACSELPoleObsNat
/opt/sas/viya/home/bin/sas-admin authorization create-rule --permissions "read" --object-uri /folders/folders/$FOLDER_ID1 --group NACSELRefExpert
/opt/sas/viya/home/bin/sas-admin authorization create-rule --permissions "read" --object-uri /folders/folders/$FOLDER_ID1 --group NACSELRefNonExpert
/opt/sas/viya/home/bin/sas-admin authorization create-rule --permissions "read" --object-uri /folders/folders/$FOLDER_ID1 --group NACSELDirRegion

# Apply rules to all child of main folder
/opt/sas/viya/home/bin/sas-admin authorization create-rule --permissions "read,update,add" --container-uri /folders/folders/$FOLDER_ID1 --group NACSELPoleObsNat
/opt/sas/viya/home/bin/sas-admin authorization create-rule --permissions "read,update" --container-uri /folders/folders/$FOLDER_ID1 --group NACSELRefExpert
/opt/sas/viya/home/bin/sas-admin authorization create-rule --permissions "read" --container-uri /folders/folders/$FOLDER_ID1 --group NACSELRefNonExpert
/opt/sas/viya/home/bin/sas-admin authorization create-rule --permissions "read" --container-uri /folders/folders/$FOLDER_ID1 --group NACSELDirRegion


# Add row-level security on specific cas tables
/opt/sas/viya/home/bin/sas-admin cas tables add-control --server cas-shared-default --caslib public --table megacorp5_4m --group NACSELDirRegion --grant select --where "upcase(FacilityRegion) in ('WEST','EAST')" --su
