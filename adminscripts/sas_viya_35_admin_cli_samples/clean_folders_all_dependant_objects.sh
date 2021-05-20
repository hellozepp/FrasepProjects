# Remove all folders 

/opt/sas/viya/home/bin/sas-admin folders delete help --path /NACSEL --recursive 

# Remove all groups 

/opt/sas/viya/home/bin/sas-admin identities delete-group --id NACSELPoleObsNat 
/opt/sas/viya/home/bin/sas-admin identities delete-group --id NACSELRefExpert 
/opt/sas/viya/home/bin/sas-admin identities delete-group --id NACSELRefNonExpert 
/opt/sas/viya/home/bin/sas-admin identities delete-group --id NACSELDirRegion 
/opt/sas/viya/home/bin/sas-admin identities delete-group --id OnlyVADesigner 
/opt/sas/viya/home/bin/sas-admin identities delete-group --id OnlyVAReader

