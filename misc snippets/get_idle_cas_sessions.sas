filename in url 'https://frasepviya35smp/cas-shared-default-http/cas/sessions'  debug user='viyademo01' pass='demopw';

libname in json automap=replace;

data all;
<<<<<<< HEAD
    merge in.root
    in.idleTime;
run;

proc print data=all;
    title 'display of current sessions, showing length of time since last CAS action';
    title2 'and total number of CAS actions run in this session';
    var uuid name user actioncount isidle hours minutes seconds;
run;
=======
	merge in.root
	in.idleTime;
run;

proc print data=all;
	title 'display of current sessions, showing length of time since last CAS action';
	title2 'and total number of CAS actions run in this session';
	var uuid name user actioncount isidle hours minutes seconds;
run;

>>>>>>> dc5484d50dbb35accfcd9bf7bbb72a96f39c96af
