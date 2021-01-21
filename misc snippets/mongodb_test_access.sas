cas mysess;


caslib mycaslib desc='MongoDB Caslib'
         dataSource=(srctype='mongodb'
                     server='cluster0.yprqf.mongodb.net'
                     username='testuser'
                     password='demopw'
                     db="sample_airbnb");

caslib _all_ assign;

proc cas;
	table.fileinfo / caslib='mycaslib';
quit;


cas mysess terminate;
