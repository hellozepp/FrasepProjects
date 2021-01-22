options sastrace='d,d,,d' sastraceloc=saslog nostsuffix sql_ip_trace=(note,source) msglevel=i fullstimer ;


libname mydb mongo server="192.168.1.32" 
port=27017 
db='thepolyglotdeveloper' 
trace=YES TRACEFLAGS=ALL TRACEFILE="/tmp/test_mongo.trc";


proc FEDSQL libs=(mydb);
     select * from connection to mydb
     (ARBOCALCUL.find({"REG_CODE":"R84","PSR":"2020M12","VERSION":"VERSION 20"}) withoptions({"projection":{"_id":0,"STRATE_ID":1}}));
quit;
run;
