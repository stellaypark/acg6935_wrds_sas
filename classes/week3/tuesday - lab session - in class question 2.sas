in class question 2


/*
	Create an indicator variable largSize; set it to 1 for firm-years with sales above 
the industry-year median sales, 0 otherwise

*/

%let wrds = wrds.wharton.upenn.edu 4016;options comamid = TCP remote=WRDS;
signon username=_prompt_;

rsubmit;
data myComp (keep = gvkey fyear datadate sich at sale ceq prcc_f csho mtb fyr);
set comp.funda;
/* require fyear to be within 2001-2015 */
if 2001 <=fyear <= 2015;
/* require assets, etc to be non-missing */
if cmiss (of at sale ceq) eq 0;
/* construct some variables */
mtb = csho * prcc_f / ceq;
/* prevent double records */
if indfmt='INDL' and datafmt='STD' and popsrc='D' and consol='C' ;
run;
proc download data=myComp out=myComp;run;
endrsubmit;


proc sql;
	create table largeIndQuestion as
		select sich, fyear, gvkey, sale, median(sale) as sale_m, ( sale > calculated sale_m ) as largSize
		from mycomp
		group by sich, fyear
	;
quit;

/* todo: what if sale is missing, and we want largSize to be missing if sale is misisng (and not 0) */


rsubmit;
data myComp (keep = gvkey fyear datadate sich at sale ceq prcc_f csho mtb fyr);
set comp.funda;
/* require fyear to be within 2001-2015 */
if 2001 <=fyear <= 2015;
/* require assets, etc to be non-missing */
/*if cmiss (of at sale ceq) eq 0; */ /* allow for missing sale */
/* construct some variables */
mtb = csho * prcc_f / ceq;
/* prevent double records */
if indfmt='INDL' and datafmt='STD' and popsrc='D' and consol='C' ;
run;
proc download data=myComp out=myCompMiss;run;
endrsubmit;

/* if sale is missing, largSize must be missing */
proc sql;
	create table largeIndQuestion as
		select sich, fyear, gvkey, sale, median(sale) as sale_m, 
			/* only compare if sale is non-missing */
/*			ifn( condition, value if true, value if false, value if missing  )*/
			ifn ( missing(sale), . , ( sale > calculated sale_m ) ) as largSize
		from myCompMiss
		group by sich, fyear
	;
quit;

