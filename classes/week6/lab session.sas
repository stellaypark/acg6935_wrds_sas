data a_input1 (keep = gvkey fyear sich datadate );
set comp.funda;
where fyear > 2012;
if indfmt='INDL' and datafmt='STD' and popsrc='D' and consol='C' ;
if fyr eq 12; /* only obs with end of year in december */
run;

/* match with comp.fundq */
proc sql;
	create table a_input2 as 
	select a.*, b.atq, b.niq,/* pull some variables -not needed */ b.fqtr
	from a_input1 a, comp.fundq b
	where  b.indfmt='INDL' and b.datafmt='STD' and b.popsrc='D' and b.consol='C' and
	a.gvkey = b.gvkey and a.fyear = b.fyearq;
quit;

data a_input2;
set a_input2;
firmQtr = fyear || fqtr; /* key at yr-qtr level*/
sichYrQtr = sich || fyear || fqtr; /* key at industry-year-quarter level*/
run;

/* input: dataset with sich, and year_qtr key (e.g. "2001 q1", "2001 q2") 
	want to have only obs with sich -year-qtr combinations that exceed 10
*/
/* firm data that satisfy >= 10 firmquarters in each industry*/
proc sql;
	create table a_input3 as 
	select a.* from 
		a_input2 a ,
		(select sich, firmQtr, count(*) as numFirms from a_input2 group by sich, firmQtr having numFirms >= 10 ) as b
	where a.sich eq b.sich and a.firmQtr = b.firmQtr
;
quit;

/* using sichYrQtr */
proc sql;
	create table a_input4 as 
	select a.* from 
		a_input2 a ,
		(select sichYrQtr, count(*) as numFirms from a_input2 group by sichYrQtr having numFirms >= 10 ) as b
	where a.sichYrQtr = b.sichYrQtr;
quit;

/* test: which sich - firmQtr obs are no longer in the dataset? */
proc sql;
	create table b_debug as select a.* from a_input2 a 
	where a.sichYrQtr not in (select distinct sichYrQtr from a_input4);
quit;

