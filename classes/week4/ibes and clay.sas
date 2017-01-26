/* topics 

Macros: %ARRAY
Macros: %DO_OVER
Matching Compustat, CRSP with IBES
IBES Summary
IBES Detail
*/

/*  Include array function macros */
filename m1 url 'http://www.wrds.us/macros/array_functions.sas';
%include m1;
/*  Include runquit macro */
filename m2 url 'http://www.wrds.us/macros/runquit.sas';
%include m2;

/* turn on macro debugging */
filename mprint 'C:\temp\tempSAScode.SAS';
options mprint mfile;

/* Clay %array and %do_over documentation: http://www2.sas.com/proceedings/sugi31/040-31.pdf */

/* remember the join funda-fundq where we passed 'ceqq atq niq' to a macro 
  and we needed to replace spaces with commas => 'ceqq, atq, niq'
  or even 'b.ceqq, b.atq, b.niq'  */
%macro addFundQ(dsin=, dsout=, varsFundq=);
  /* construct comma separated varlist */
  * %let varList= %sysfunc(tranwrd(&varsFundq, %str( ) , %str(,) )) ;
  /* push macro variables to wrds */
  %SYSLPUT dsin=&dsin;
  %SYSLPUT dsout=&dsout;
  * %SYSLPUT varsFundq=&varList;
  %SYSLPUT varsFundq=&varsFundq;

  rsubmit;
  /* need to load clay macros */
  filename m1 url 'http://www.wrds.us/macros/array_functions.sas';
  %include m1;
  proc upload data=&dsin out = myComp3;run;
  /* join with fundq */
  proc sql;
    create table myComp4 as
    /* select a.* , b.datadate as datadate_fundq, &varsFundq;
		varsFundq holds: 
		%do_over(values=atq ceqq niq, phrase=b.?, between=comma)
	=> generates: b.atq,b.ceqq,b.niq
	*/
    select a.* , b.datadate as datadate_fundq, %do_over(values=&varsFundq, phrase=b.?, between=comma)
    
    from myComp3 a left join comp.fundq b
    on a.gvkey = b.gvkey and a.fyear = b.fyearq;
  quit;
  /* download as &dsout */
  proc download data=myComp4 out=&dsout;run;
  endrsubmit;

%mend;


/* start with a dataset from funda: gvkey, fyear, roa and roe */

%let wrds = wrds.wharton.upenn.edu 4016;options comamid = TCP remote=WRDS;
signon username=_prompt_;
rsubmit;
data a_funda (keep = gvkey fyear sich roa roe);
set comp.funda;
if at > 0;
if ceq > 0;
if fyear >= 2010;
roa = ni / at;
roe = ni / ceq;
if indfmt='INDL' and datafmt='STD' and popsrc='D' and consol='C' ;
run;
proc download data=a_funda out=a_funda;run;
endrsubmit;

/* lets make year-indicator variables */

/* simple way */
data b_indicators;
set a_funda;
d2010 = (fyear eq 2010);
d2011 = (fyear eq 2011);
d2012 = (fyear eq 2012);
d2013 = (fyear eq 2013);
run;

/* using Ted Clay's %do_over */
data b_indicators;
set a_funda;
%do_over(values=2010-2013, phrase=d? = (fyear eq ?););
run;

/* replace missings with zero for these variables */
%let varlist = xrd dltt .....;

data clean;
set start;
$do_over(values=&varlist, phrase=if missing(?) then ? = 0;);
run;


/* fancy way */
/* figure out first and last fyear */
proc sql; select min(fyear), max(fyear) into :minYr, :maxYr from a_funda;quit;

%put start year: &minYr ending year: &maxYr;
/* create dummies */
data b_indicators;
set a_funda;
%do_over(values=&minYr - &maxYr, phrase=d? = (fyear eq ?););
run;

/* another way -- just in case there are jumps in the years , if 2012 would be missing */
proc sql;
	create table myYears as select distinct fyear from a_funda ;
quit;

%array(kangaroo, data=myYears, var=fyear);
%put kangarooN: &kangarooN;
%put kangaroo1: &kangaroo1;
%put kangaroo2: &kangaroo2;


data b_indicators;
set a_funda;
%do_over(kangaroo, phrase=d? = (fyear eq ?););
run;


/* example: processing files in some folder 
  folder example_files_to_import has files that need to be imported and merges

  copied from "Obtaining A List of Files In A Directory Using SAS - ResearchGate" 
*/
 %let folder = "E:\teaching\2017_wrds\acg6935_wrds_sas\classes\week4\example_files_to_import";
data yfiles (keep = filename path);
 length fref $8 filename $80 path $300;
 rc = filename(fref, &folder);
 if rc = 0 then  do;
  did = dopen(fref);
  rc = filename(fref);
  end;
 else do;
  length msg $200.;
  msg = sysmsg();
  put msg=;
  did = .;
 end;
 if did <= 0  then  putlog 'ERR' 'OR: Unable to open directory.';
 dnum = dnum(did);
 do i = 1 to dnum;
   filename = dread(did, i);
   path = &folder || "\" || filename;
  /* If this entry is a file, then output. */
  fid = mopen(did, filename);
  if fid > 0 then output;
 end;
 rc = dclose(did);
 run;
 proc print data=yfiles;
run;

/* path holds the file name paths, assign to an array */
%ARRAY(files, DATA=yfiles, VAR=path) ;

%put number of files: &filesN;

%put %do_over(files, phrase =file: ? ?_I_);

%macro doImport(f);

    /* import file f */
    filename MYFILE "&f";
    data myData; /* should add index */
    infile MYFILE dsd delimiter='09'x /* tab delimited */ firstobs=2 LRECL=32767 missover;
    input score gvkey fyear mymeasure  auditfee  filinglength  delay fog numberWords  mkvalt  size  roa numest institutHold;
    run;

    %if %sysfunc(exist(allInputData)) %then %do;
      /* allInputData exists, append the newly imported data */
      proc append base=allInputData data=myData; run;
    %end;
    %else %do;
      /* it is the first dataset -> set allInputData to equal newly imported dataset */
      data allInputData; set myData;run;
    %end;
%mend;

/* repeat the import for each item in array files */
%do_over(files, macro=doImport);


/* another example: industry-adjust variables */

/* simple way: industry(-year)-adjusted roa 
	compute average roa by sich-year and subtract that from firm roa*/


/*  Helper macro to compute industry adjusted numbers */
%macro computedIAdj(var);    &var._IA = &var - &var._median;%mend;
 
%macro industryAdjust(dsin=, dsout=, industry=, year=, vars=);
 
/*  Create variable to group by: industry-year */
data work.a_ia1;
set &dsin;
keyYrInd = &industry || &year;
%runquit;
 
/*  Compute industry medians */
proc sort data = work.a_ia1; by keyYrInd;run;
proc means data=work.a_ia1 n mean median noprint;
OUTPUT OUT=work.a_ia2
        median= /autoname;
var &vars;
by keyYrInd;
%runquit;
 
/*  Append industry-adjusted */
proc sql;
     create table work.a_ia3 as
	 /* generates: a.*, b.roa_median, b.roe_median */
        select a.*, %DO_OVER(VALUES=&vars, PHRASE=b.?_median, BETWEEN=COMMA ) 
        from
            work.a_ia1 a, work.a_ia2 b
        where
            a.keyYrInd = b.keyYrInd;
%runquit;
 /*
%macro computedIAdj(var);    &var._IA = &var - &var._median;%mend;
*/
/*  Create output dataset and Drop keyYrInd and medians */
data &dsout (drop =keyYrInd %DO_OVER(VALUES=&vars, PHRASE=?_median));
set work.a_ia3;
%DO_OVER(VALUES=&vars, MACRO = computedIAdj);
%runquit;

/* will generate 
data &dsout (drop =keyYrInd roa_median roe_median);
set work.a_ia3;
roa_IA = roa - roa_median;
roe_IA = roe - roe_median;
%runquit;
*/
/*  Clean up */    
proc datasets 
library=work;      
    delete a_ia1 - a_ia3;    
%runquit;

%mend;

* invoke macro;
%industryAdjust(dsin=a_funda, dsout=c_funda_ia, industry=sich, year=fyear, vars=roa roe);

/* take a look at IBES STATSUMU_EPSUS */

data c_ibespeek (keep = ticker oftic cname statpers measure fiscalp fpi fpedats numest numup numdown medest meanest stdev highest lowest);
set ibes.STATSUMU_EPSUS;
where OFTIC eq "DELL";
run;


/* IBES: number of analysts 
*/

data a_funda (keep = key gvkey fyear datadate conm);
set comp.funda;
/* limit to firms with more than $20 mln sales and fiscal years 2010-2012 */
if sale > 20;
if 2010 <= fyear <= 2012;
/* create key to uniquely identify firm-year */
key = gvkey || fyear; 
/* general filter to drop doubles from Compustat Funda */
if indfmt='INDL' and datafmt='STD' and popsrc='D' and consol='C' ;
run;
 
/* get permno */
proc sql;
  create table b_permno as
  select a.*, b.lpermno as permno
  from a_funda a left join crsp.ccmxpf_linktable b
    on a.gvkey = b.gvkey
    and b.lpermno ne .
    and b.linktype in ("LC" "LN" "LU" "LX" "LD" "LS")
    and b.linkprim IN ("C", "P") 
    and ((a.datadate >= b.LINKDT) or b.LINKDT = .B) and 
       ((a.datadate <= b.LINKENDDT) or b.LINKENDDT = .E)   ;
quit;

/* retrieve historic cusip */
proc sql;
  create table c_cusip as
  select a.*, b.ncusip
  from b_permno a, crsp.dsenames b
  where 
        a.permno = b.PERMNO
    and b.namedt <= a.datadate <= b.nameendt
    and b.ncusip ne "";
  quit;
 
/* force unique records */
proc sort data=c_cusip nodupkey; by key;run;
 
/* get ibes ticker */
proc sql;
  create table d_ibestick as
  select distinct a.*, b.ticker as ibes_ticker
  from c_cusip a, ibes.idsum b
  where 
        a.NCUSIP = b.CUSIP
    and a.datadate > b.SDATES 
;
quit;
 
/* get number of estimates -- last month of fiscal year*/
proc sql;
  create table e_numanalysts as
  select a.*, b.STATPERS, b.numest as num_analysts
  from d_ibestick a, ibes.STATSUMU_EPSUS b
  where 
        a.ibes_ticker = b.ticker
    and b.MEASURE="EPS"
    and b.FISCALP="ANN"
    and b.FPI = "1"
    and a.datadate - 30 < b.STATPERS < a.datadate 
    and a.datadate -5 <= b.FPEDATS <= a.datadate +5
;
quit;
 
/* force unique records */
proc sort data=e_numanalysts nodupkey; by key;run;
 
/* append num_analysts to b_permno */
proc sql;
    create table f_funda_analysts as 
    select a.*, b.num_analysts 
    from b_permno a 
    left join e_numanalysts b 
    on a.key=b.key;
quit;
 
/* missing num_analysts means no analysts following */
data f_funda_analysts;
set f_funda_analysts;
if permno ne . and num_analysts eq . then num_analysts = 0;
run;

/* relevant data for reported earnings
	- earnings announcement date
	- actual earnings

	Compustat Fundq holds 'rdq' (reporting date), 
	cshoq (#shares oustanding), and net income (niq)

	Nevertheless, IBES data is preferred:
	- Actual earnings are 'street' earnings, more in line with how
	analyst forecast earnings
	- Announcement date in IBES has less error
	- There is also announcement time
		- some papers add 1 day if earnings are announced after hours 
*/

/* take a look at actuals for DELL: ACTU_EPSUS */
proc sql;
  create table g_actuals as
  select *
  from ibes.ACTU_EPSUS  b
  where ticker eq "DELL" and year(PENDS) >= 2010;
quit;
 
/* analyst detail: DETU_EPSUS */

proc sql;
  create table h_details as
  select *
  from ibes.DETU_EPSUS  b
  where ticker eq "DELL" and year(FPEDATS) eq 2010;
quit;

proc sort data=h_details; by ANALYS FPEDATS ANNDATS ;run;

data i_021096;
set h_details;
if analys eq "021096";
run;

/* notice how FPI 'counts' down from 3, 2, 1 for annual forcasts and
   from O, N, 9, ... to 6 for quarterly forecasts */

data j_021096_ann (keep = oftic estimator analys fpi measure value fpedats revdats anndats);
set h_details;
if FPI IN ("3", "2", "1");
if estimator eq 11;
run;

