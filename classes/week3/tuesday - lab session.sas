

/* read macro pdf and little SAS book ch7 */

%let wrds = wrds.wharton.upenn.edu 4016;options comamid = TCP remote=WRDS;
signon username=_prompt_;

rsubmit;
data myComp (keep = gvkey fyear datadate ni at sale sich );
set comp.funda;
/* require fyear to be within 2001-2015 */
if 2010 <=fyear <= 2015;
/* require assets, etc to be non-missing */
if cmiss (of at sale ceq ni) eq 0;
/* prevent double records */
if indfmt='INDL' and datafmt='STD' and popsrc='D' and consol='C' ;
run;

proc download data=myComp out=mycomp;run;

/* join with fundq */
proc sql;
	create table mycomp2 as
	select a.* , b.datadate as datadate_fundq, b.fqtr
	from myComp a left join comp.fundq b
	on a.gvkey = b.gvkey and a.fyear = b.fyearq;
quit;


proc download data=mycomp2 out=mycomp2;run;
endrsubmit;

/* longer way: first make a dataset with industry code, month (data step)
	and then, do a proc means where you count the months for each industry
*/

/* create my 2-digit industry code, and the month of the datadate_fundq */
proc sql;
	create table monthCount as
		select industry, mo, count(*) as numObs 
		from (
			select floor(sich/100) as industry, month(datadate_fundq) as mo from mycomp2
		)
		group by industry, mo;
quit;

/* know thich industry has the highest % of observations in 1,2,4,5,7,8,10,11 */

proc sql;
	create table monthCount as
		select distinct industry, count(*) as numObs,
			/* odd part: create an indicator if it is in a unusual month*/
			( mo IN (1,2,4,5,7,8,10,11)   ) as oddMonth, sum(calculated oddMonth) / calculated numObs as fraction
		from (
			select floor(sich/100) as industry, month(datadate_fundq) as mo from mycomp2
		)
		group by industry ;
quit;



proc sql;
	create table monthCount as
		select distinct industry, count(*) as numObs,
			/* odd part: create an indicator if it is in a unusual month*/
			 sum( mo NOT IN (3, 6, 9, 12)  ) / calculated numObs as fraction
		from (
			select floor(sich/100) as industry, month(datadate_fundq) as mo from mycomp2
		)
		
		group by industry order by calculated fraction;
quit;

/* q4 */

proc sql; 
    create table q4_2herf as 
    select sich, fyear, sum((sale/sum(sale))**2) as herf label="Herfindahl index",
    count(*) as num_firm label="Number of Firms in Industry" 
    from q4_1firmdata
    where count(*) > 19
    group by sich, fyear;
quit;

proc sql; 
    create table q4_2herf as 
    select sich, fyear, count(*) as numObs,
		sum((sale/sum(sale))**2) as herf label="Herfindahl index"
    from mycomp
    group by sich, fyear
	having numObs > 19
;
quit;

data mycomp;
set mycomp;
indyear = sich || fyear;
run;

proc sql; 
    create table q4_2herf as 
    select a.sich, a.fyear, count(*) as numObs,
		sum((a.sale/b.ind_total)**2) as herf label="Herfindahl index"
    from mycomp a, ( select sich, fyear, sum(sale) as ind_total from mycomp group by sich, fyear ) as b
	where a.sich = b.sich and a.fyear = b.fyear
    group by a.sich, a.fyear
	having count(*) > 19
;
quit;
data mycomp;
set mycomp;
indyear = sich || fyear;
run;
proc sql; 
    create table q4_2herf as 
    select a.indyear, count(*) as numObs,
		sum((a.sale/b.ind_total)**2) as herf label="Herfindahl index"
    from mycomp a, ( select indyear, sum(sale) as ind_total from mycomp group by indyear ) as b
	where a.indyear = b.indyear
    group by a.indyear
	having count(*) > 19;
quit;