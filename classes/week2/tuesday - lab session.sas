/*

	reminder: read proc sql doc before this Thursday


	overview:
	so far we have covered:
		- data step, using
			by
			retain
			ifn ifc
			lag, lag2, lag3
			missing, cmiss
			keep=, drop=
		- proc means, using
			by
			where=
			out output=
			class 
		- proc sort
			nodupkey
			dupout

	today: anything related to data step, proc means, assignments, etc

	Tuesday January 10, 2017

	lab session
*/

%let wrds = wrds.wharton.upenn.edu 4016;options comamid = TCP remote=WRDS;
signon username=_prompt_;

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

/* nick for q1, sum of sales for each company --- using class */
proc sort data=myComp; by sich ;run;
proc means data=myComp NOPRINT;
OUTPUT OUT=myOutput_class sum= /autoname;
class gvkey; /* does not require a sort which is nice */
var sale;
run;

proc sort data=myComp; by gvkey ;run;
proc means data=myComp NOPRINT;
OUTPUT OUT=myOutput_by sum= /autoname;
by gvkey; /* requires a sort */
var sale;
run;

/* label for sale_sum will still be sales/revenue, which we don't like */
data myOutput_by;
set myOutput_by;
label sale_sum ="banana";
run;

data myComp2;
set myComp;
... do something;
run;

data myComp3;
set myComp2;
... do something else;
run;

/* delete datasets */
proc datasets;
	delete myOutput_by myOutput_class;
quit;

data largesich (keep = gvkey fyear sale sich);
set myComp;
if sich ne .;
run;

proc sort data=largesich; by sich; run;

data largesichcl (keep = sich keepVar);
set largesich;
by sich;
if first.sich then counter = 0;
counter+1;
if counter >=20 then keepVar=1;
if last.sich then output;
run;

/*now we have a table with sich's where keepVar is 1 if there are enough firms */
/* the problem is that we still need to sum firm sales in these industries
	an alternative is to use proc means on the full sample, by sich, and use _FREQ_
	_FREQ_ will be the number of firms in that industry*/

/* sort by industry-gvkey -> computed the sum of sales for each gvkey for each industry they were in*/
proc sort data=myComp; by sich gvkey;run;
proc means data=myComp NOPRINT;
OUTPUT OUT=means1 sum= /autoname;
by sich gvkey; /* requires a sort */
var sale;
run;

/* sum by industry */
proc sort data=means1; by sich;run;
proc means data=means1 NOPRINT;
OUTPUT OUT=means2 sum= /autoname;
by sich ; 
var sale_sum;
run;

/* industries with >= 20 gvkeys */
data means2;
set means2;
if _FREQ_ >=20;run;

/* intuitive but 'wrong' approach --- here freq will have firm-years (not firms)*/
proc means data=myComp NOPRINT;
OUTPUT OUT=meanswrong sum= /autoname;
class sich ; 
var sale;
run;

/* create a dataset that counts the missing sich for each gvkey */
proc sql;
	create table myMissings as
			select gvkey, sum(miss) as missTotal, count(*) as numobs
			from
				( select gvkey, missing(sich) as miss from mycomp)		
			group by gvkey
			having missTotal > 6;
quit;



data something (keep = gvkey fyear sich sich_prev);
set mycomp;
if gvkey IN ("002620", "006310", "011787");
run;
/* forward fill */
proc sort data=mycomp; by gvkey fyear;
data something2 (drop = sich_prev);
set something;
retain sich_prev;
/* some obs with several missing industry */
if first.gvkey then sich_prev = .;
if sich eq . then sich = sich_prev ;
sich_prev = sich;
by gvkey;
run;
/* backfill */
proc sort data=something2; by gvkey descending fyear;
data something3 (drop = sich_prev2);
set something2;
retain sich_prev2;
if first.gvkey then sich_prev2 = .;
if sich eq . then sich = sich_prev2 ;
sich_prev2 = sich;
by gvkey;
run;

/* without by  -- guard with lag(gkvey) eq gvkey*/
data something3 (drop = sich_prev2);
set something2;
retain sich_prev2;
if sich eq . and lag(gvkey) eq gvkey then sich = sich_prev2 ;
sich_prev2 = sich;
run;
