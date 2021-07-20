cas mysess;

/* Import du catalogue de formats */
libname fmtloc "/tmp/utf8/src" inencoding=wlatin1;

proc format library=fmtloc.formats cntlout=fmtloc.outfmts;
run;

/* conversion en utf-8 du catalogue de formats */
libname fmtloc cvp "/tmp/utf8/src" inencoding="wlatin1";
libname fmtloc2 "/tmp/utf8/tgt" outencoding="utf-8" ;

proc format cntlin=fmtloc.outfmts casfmtlib="mycasformats";
run;

proc cas;
   sessionProp.listFmtLibs / showMemNames=true;
run;
quit;

cas mysess terminate;
