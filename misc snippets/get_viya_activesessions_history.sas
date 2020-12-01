/* Specify query time below in datetime. format */
%let qrytime='10JAN20:08:39:18'dt;

libname evdm '/opt/sas/viya/config/var/lib/evmsvrops/evdm/subjects' access=readonly;

data activesessions;
	set evdm.authentications;
	endtime=datetime+duration;
	format datetime datetime.;
	format endtime datetime.;
	where (datetime>=&qrytime) and (duration>0 and session_sig ne '');
run;

proc print data=activesessions;
run;