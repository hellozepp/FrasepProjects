/* Specify a host and port that are valid for your site.*/
*options cashost="cloud.example.com" casport=5570;  

/* If not already done, start session Casauto. */ 
*cas casauto;

cas casauto sessopts=(caslib='public');

options noquotelenmax;

proc cas;
  session casauto;

  source pgm;                                                       /* 1 */
    tables = ${hmeq hmeq_customer};
    do i = 1 to dim(tables);
      sc_sess[i] = create_parallel_session();                       /* 2 */
      fname = tables[i] || '.sashdat';
      sessionProp.setSessOpt session=sc_sess[i] / caslib='public'; /* 3 */
      dropTable session=sc_sess[i] / table=tables[i] quiet=True;    /* 4 */
      loadtable session=sc_sess[i] async=tables[i]  /               /* 5 */
        path=fname
        casOut={
                name=tables[i]
                promote=True};
    end;

    results = newtable( 'In-Memory Tables',                         /* 6 */
      {'Name'='Table Name', 'Caslib'= 'Caslib', 'Severity'='Severity'},
      ${varchar,varchar,int64});

    job = wait_for_next_action(0);
    do while(job);
      do;
        addrow(results,
          {job.result.tableName, job.result.caslib, job.status.severity});
        job = wait_for_next_action(0);
      end;
    end;

    send_response({table=results});                                 /* 7 */
  endsource;

  sccasl.runCasl result=outer / code=pgm;
run;

  mytables = outer.Table[,'Name'];                                  /* 8 */

  print "Results from the parallel subsessions:";
  print mytables;

  table.tableInfo result=ti / caslib='public';
run;

  print ti.TableInfo.where(Name in (mytables))[,{'Name', 'Label', 'Rows', 'Columns'}];
run;
quit;