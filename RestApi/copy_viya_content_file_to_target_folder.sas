/*******************************************************************************************/
/* Script to execute on Viya SPRE and user belonging to SAS Administrator custom group     */
/*******************************************************************************************/

/* Get all custom tasks file id from a specified user my tasks folder */


/* Copy all custom tasks to target user list my task folder */

%let BASE_URI=%sysfunc(getoption(SERVICESBASEURL));
%let fullpath=/;

/******************************************************************************/
/* Copy a custom task from designer folder to a target folder                 */
/******************************************************************************/

proc http
	url="&BASE_URI/files/files/ecd84167-617f-4eb3-b8ee-4a8bbe6871b2/copy?parentFolderUri=/folders/folders/11c9c85f-8333-4452-aef7-19c99b52a522" 
	method='POST' oauth_bearer=sas_services;
	debug level=1;
run;
quit;
