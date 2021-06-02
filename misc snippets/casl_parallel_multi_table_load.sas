proc cas;
  source pgm;
    table.fileinfo result=fI / caslib="public";
    do i = 1 to dim(fI.fileInfo[,"name"]);
      cfile =  fI.fileInfo[i,"name"];
      ctable = scan(cfile,1,".");
      sc_sess[i] = create_parallel_session();
      table.dropTable / table=ctable caslib="public";
      table.loadtable session=sc_sess[i] async=cfile  /            
        path=cfile caslib='public'
        casOut={name=ctable caslib='public' promote=True};
    end;

    job = wait_for_next_action(0);
    do while(job); 
          print job;
          job = wait_for_next_action(0);
    end;

  endsource;

  sccasl.runCasl / code=pgm;
run;