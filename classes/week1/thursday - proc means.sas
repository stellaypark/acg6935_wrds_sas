/* setup wrds connection */

%let wrds = wrds.wharton.upenn.edu 4016;options comamid = TCP remote=WRDS;
signon username=_prompt_;

/* get some data to play with 
  gvkey: compustat firm identifier
  fyear: fiscal year
  datadate: end of fiscal year date (closest end of month)
  cik: sec firm identifier (central index key)
  ni: net income
  at: assets
  sale: sales
  ceq: equity
  prcc_f: end of fiscal year stock price
  csho: common shares outstanding
  sich: SIC industry, historic
*/
rsubmit;
data myComp (keep = gvkey fyear datadate cik ni at sale ceq prcc_f csho sich roa mtb size);
set comp.funda;
/* require fyear to be within 2001-2015 */
if 2001 <=fyear <= 2015;
/* require assets, etc to be non-missing */
if cmiss (of at sale ceq ni) eq 0;
/* construct some variables */
roa = ni / at;
mtb = csho * prcc_f / ceq;
size = log(csho * prcc_f);
/* prevent double records */
if indfmt='INDL' and datafmt='STD' and popsrc='D' and consol='C' ;
run;
proc download data=myComp out=myComp;run;
endrsubmit;

/* proc means can generate the following statistics:

    Keyword   Description
    MIN       Minimum
    MEAN      Mean
    MEDIAN    Median
    MAX       Maximum
    STD       Standard deviation
    QRANGE    Interquartile range
    VAR       Variance
    SKEW      Skew
    In addition, there are several percentiles: P1, P5, P10, P25, P50 (=Median), P75, P90, P95 and P99.

    When used with 'by' (i.e., statistics for each group) the data needs to be sorted
*/

/*  Statistics by firm => by gvkey */
proc sort data=myComp; by gvkey fyear ;run;
proc means data=myComp NOPRINT; /* suppress output to screen */
  /* but, do output to dataset */
  OUTPUT OUT=myOutput n= mean= max= median= stddev= /autoname;
  var roa mtb size;
  by gvkey; /* without gvkey would give full sample statistics */
run;

/*  Statistics by industry => by SICH */
proc sort data=myComp; by sich ;run;
proc means data=myComp NOPRINT; /* suppress output to screen */
  /* but, do output to dataset */
  OUTPUT OUT=myOutput n= mean= max= median= stddev= /autoname;
  var roa mtb size;
  by sich; /* without gvkey would give full sample statistics */
run;

/*  Statistics by year => by fyear */
proc sort data=myComp; by fyear ;run;
proc means data=myComp NOPRINT; /* suppress output to screen */
  /* but, do output to dataset */
  OUTPUT OUT=myOutput n= mean= max= median= stddev= /autoname;
  var roa mtb size;
  by fyear; /* without gvkey would give full sample statistics */
run;

/*  No need to make extra datasets if you need statistics on part of the sample => use 'where'  */

/*  Example: full sample (no 'by'), but only for loss firms */
proc means data=myComp (where= (ni < 0) ) NOPRINT; /* suppress output to screen */
  /* but, do output to dataset */
  OUTPUT OUT=myOutput n= mean= max= median= stddev= /autoname;
  var roa mtb size;  
run;
