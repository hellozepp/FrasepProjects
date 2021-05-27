cas sessiomgmt001;

proc cas;

                session sessiomgmt001;
                accessControl.assumeRole / adminRole="superuser";
                accessControl.accessPersonalCaslibs;

                out_table = newtable("CAS Table size", {"CAS Library","CAS Table","Size in MB", "Number of rows"}, {"varchar","varchar","integer", "integer"});

                /**************** function to get a simple table with the cas table actual size in MB and the number of rows ****************/
                function get_table_size(caslib,castab_name);
                                               table.tabledetails result=r/ caslib=caslib name=castab_name;
                                               *out_table = newtable("caslib","castable","CAS Table size", {"Size in MB", "Number of rows"}, {"varchar","varchar","int64", "int64"});
                                               addrow(out_table, {caslib, castab_name,r.TableDetails[1].Datasize/1024/1024, r.TableDetails[1].Rows});
                end;



                table.caslibinfo result=listcaslib;

                do current_caslib over listcaslib.caslibInfo[1:listcaslib.caslibInfo.nrows];
                               table.tableinfo result=listtab / caslib=current_caslib.name;
                               if listtab.tableinfo.nrows>=1 then
                               do;
                                               print "CASLIB : " || current_caslib.name;
                                               do row over listtab.tableinfo[1:listtab.tableinfo.nrows];
                                                               print "Castable : " || row.name;
                                                               *table.tabledetails / caslib=current_caslib.name name=row.name ;
                                                               get_table_size(current_caslib.name,row.name);
                                               end;
                               end;
                end;
                print out_table;

quit;

cas sessiomgmt001 terminate;
