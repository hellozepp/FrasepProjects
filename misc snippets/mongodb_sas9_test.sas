options sastrace='d,d,,d' sastraceloc=saslog nostsuffix sql_ip_trace=(note,source) msglevel=i fullstimer ;


libname mydb mongo server="192.168.1.32" 
port=27017 
db='thepolyglotdeveloper' 
trace=YES TRACEFLAGS=ALL TRACEFILE="/tmp/test_mongo.trc";

