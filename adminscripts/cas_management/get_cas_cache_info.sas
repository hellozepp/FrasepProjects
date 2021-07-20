/* Monitor the CAS disk cache using SAS code */
options set=CASCLIENTDEBUG=1;
cas MonitorCDC cashost="frasepviya35smp" casport=5570;

proc cas;
   session MonitorCDC;
   accessControl.assumeRole / adminRole="superuser";
   builtins.getCacheInfo result=results;
   describe results;
run;

print results.diskCacheInfo;
run;

quit;

cas MonitorCDC terminate;
