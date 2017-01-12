/*

topics

- Proc SQL: Inner Join, left join, group by
- Compustat Fundamental Quarterly (Fundq)
- Compustat Segment files
*/


/* get a dataset to work with */

%let wrds = wrds.wharton.upenn.edu 4016;options comamid = TCP remote=WRDS;
signon username=_prompt_;

rsubmit;

libname myfiles "~"; /* ~ is home directory in Linux, e.g. /home/ufl/imp */
proc sql;
	create table myfiles.a_funda as
		select gvkey, fyear, datadate, sich, sale, ni
	  	from comp.funda 
  	where 		
		2000 <= fyear <= 2013
	and 6000 <= SICH <= 6999
	and indfmt='INDL' and datafmt='STD' and popsrc='D' and consol='C' ;
quit;

/* drop doubles */
proc sort data=myfiles.a_funda nodupkey; by gvkey fyear;run;

/* create unique key for each firm-year */
data myfiles.a_funda;
	set myfiles.a_funda;
	key = gvkey || fyear;
run;

proc download data=myfiles.a_funda out=a_funda;run;
endrsubmit;

/* side-steps */

/* as promised: label (bonus: formatting of variables) */
proc sql;
	create table myTable as 
		select sich, sum(sale) as sumSale LABEL="Sum of Sales" format=comma20. 
		from a_funda group by sich;
quit;

/* another side step: using 'calculated' to refer to a newly constructed variable */
proc sql;
	create table myTable as 
		select sich, sum(sale) as sumSale ,	calculated sumSale * 2 as twiceSumSale
		from a_funda 
		group by sich
		having sumSale > 10
;
quit;

/* creating indicator variables: create loss dummy  */

proc sql;
	create table myTable as select *, (ni < 0) as loss 
		from a_funda;
	quit;

/*
	suppose we want to create a dataset with:
		1. financial firms in Funda (SIC codes 6000-6999), with fiscal years in 2000-2013
		2. for each firm-year, compute the standard deviation in ROA for the last 20 quarters
			drop firm-years with less than 12 obs
*/

/* step 1: get financial firms with fiscal years 2000-2013 */

/* use a_funda created above */



/* step 2. for each firm-year, compute the standard deviation in ROA for the last 20 quarters */

rsubmit;
libname myfiles "~"; 

/* get only data for firms that are in a_funda -- this is an example of inner join */
proc sql;
	create table myfiles.b_fundq as
	/* get the key from the funda dataset and the relevant fundq variables
		we don't really need b.gvkey, b.fyearq and b.fqtr, but get them nonetheless
		(helpful for debugging, easier to see if we made mistakes) 
	*/
	select a.key, b.gvkey, b.fyearq, b.datadate, b.fqtr, b.niq / b.atq as roa 
	/* datasets to use: 'a' will refer to a_funda, 'b' to comp.fundq 
		so, a.key in select comes from a_funa, b.<vars> come from comp.fundq
	*/
	from myfiles.a_funda a, comp.fundq b
	where
		/* make sure it is the same firm */ 
		a.gvkey = b.gvkey 
		/* last 20 quarters means last 5 fiscal years: fiscal year of fundq
		must be between 0 and 4 years before the funda fyear*/
	and a.fyear -4 <= b.fyearq <= a.fyear;
quit;

proc download data=myfiles.b_fundq out=b_fundq;run;
endrsubmit;

/* drop some doubles */
proc sort data = b_fundq nodupkey; by key fyearq fqtr;run;

/* stdev roa */
proc means data=b_fundq noprint;
  OUTPUT OUT=c_stdevroa  stddev= /autoname;
  var roa;
  by key;
run;

/* require at least 12 obs 
	this step could be added as 'where' restriction in the next step
*/
data c_stdevroa;
set c_stdevroa;
if _FREQ_ >= 12;
run;

 /* we have 2 datasets:
 	a_funda: with key, gvkey, fyear, datadate
 	c_stdevroa: with key, _freq_, roa_stddev */

 /* inner join: requires both sides to be nonmissing */

proc sql;
	create table d_inner as
		select a.*, b.roa_stddev 
		from a_funda a, c_stdevroa b
		where a.key = b.key;
quit;

/* left join: will keep 'left' obs that have no match 
 	(i.e. firms with fewer than 12 quarters)
	note 'left join' and 'on' instead of 'where'
 	note the difference in #obs compared with inner join

 	also, the number of obs should normally not increase with a left join
	if it does (when it shouldn't) the 'left' side or the 'right' side
	may have doubles
*/
proc sql;
	create table d_left as
		select a.*, b.roa_stddev 
		from a_funda a left join c_stdevroa b
		on a.key = b.key;
quit;

/* self join */

/* using the quarterly roa in b_fundq, suppose we want to add lagged roa 
 (same quarter 1 year before) */

proc sql;
 	create table e_withlag as
	select a.*, b.roa as roa_prev, b.fyearq as fyearq_prev /* for debugging */
	/* note that b_fundq is both a and b: a self join */
	from b_fundq a left join b_fundq b
    on  a.key = b.key /* same firm-year */
	and a.fyearq -1 = b.fyearq /* b.roa needs to be 1 year before a.fyearq */
	and	a.fqtr = b.fqtr
	and b.roa > 0
; /* same fiscal quarter (1, 2, 3, 4) */
quit;

/* just for illustration: inner join with condition */
proc sql;
 	create table e_withlag as
	select a.*, b.roa as roa_prev, b.fyearq as fyearq_prev /* for debugging */
	/* note that b_fundq is both a and b: a self join */
	from b_fundq a , b_fundq b
    where  a.key = b.key /* same firm-year */
	and a.fyearq -1 = b.fyearq /* b.roa needs to be 1 year before a.fyearq */
	and	a.fqtr = b.fqtr
	and -50 <= b.roa <-2;
; 
quit;

proc sort data= e_withlag; by key gvkey fyearq fqtr;run;

/* group by */

/* do 'something' for each group, such as count, sum, average */

/* example, number of observations per year in a_funda 
	count(*) means: count all obs in the group
*/

proc sql;
	create table f_obsbyyr as
	select fyear, count(*) from a_funda group by fyear;
 quit;

/* without group by: instructive (but not very useful) */
proc sql;
	create table f_obsbyyr2 as
	select fyear, count(*) from a_funda ;
 quit;

/* name the generated variable using 'as' */
proc sql;
	create table f_obsbyyr3 as
	select fyear, count(*) as numobs from a_funda group by fyear;
quit;

/* segment files */

/* lets inspect the segment files for microsoft 

	first find companies with 'microsoft' in their company name using comp.company

	SQL 'LIKE' is a simple text match where % is a wildcard; it is case sensitive
*/

rsubmit;
proc sql;
	create table g_microsoft as 
	select * from comp.company where conm like '%MICROSOFT%';
quit;
proc download data=g_microsoft out=g_microsoft;run;
endrsubmit;

/* microsoft gvkey: 012141, fetch segment data for 2010-2013 */

rsubmit;
libname segm "/wrds/comp/sasdata/naa/segments_current";
proc sql;
	create table h_segment as 
	select * from segm.WRDS_SEGMERGED where gvkey = "012141" and year(datadate) >= 2010 ;
quit;
proc download data=h_segment out=h_segment;run;
endrsubmit;

/* can we count the number of segments ? */

/* 'distinct' forces unique rows */
proc sql;
	create table i_count as 
	select distinct year(datadate) as year, count(*) as numobs from h_segment group by year(datadate);
quit;

/* no -- still needs cleaning up, industrial and geographic segments combined, duplicates for years, 
	includes corporate as segment, etc */
