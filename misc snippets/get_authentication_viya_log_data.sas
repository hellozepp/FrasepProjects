options cashost="sepviya35.aws.sas.com" casport=5570;
cas mysess;
caslib _all_ assign;

libname evdm '/opt/sas/viya/config/var/lib/evmsvrops/evdm/subjects' access=readonly;

proc cas;
droptable / table='authentications_audit' caslib='public' quiet='true';
run;
quit;

data public.authentications_audit(promote=YES);
	set evdm.authentications;
run;

cas mysess terminate;


