SAS ML Based sensor Monitoring application (developed on SAS Viya 3.5)
**********************************************************************

This application deliverable is composed of several artifacts :

* A json file containing all the SAS Viya contents : jobs, SAS viya reports and SAS code
* 4 HTML files (to be put on /var/www/html)
* 3 directories containing SAS VA DATA Driven necessary libraries (to be put also on /var/www/html on SAS Viya server)
* A powerpoint explaining the architecture of  the application
* 4 consistent zipped dataset in sashdat format (to be imported or copied in public caslib)

Deployment note :
*****************
All the HTML files, SAS Viya jobs and url in SAS VA report, contain a reference
to the development hostname. You have to change this reference to the correct 
hostname.