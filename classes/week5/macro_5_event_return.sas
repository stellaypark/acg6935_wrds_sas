/*
	dsin: input dataset with key permno beta &eventdate
	dsout: dataset to create
	eventdate: variable that holds eventdate (e.g. ann_date)
	start: window start relative to event date
	end: window end relative to event date
	varname: variable name for abnormal return to create 
		computed as: sum of abnormal returns, computed as firm return - beta x market return
	
	example invoke:
	%eventReturn(dsin=d_beta, dsout=e_ret, eventdate=ann_dt, start=-1, end=2, varname=abnret);
*/

%macro eventReturn(dsin=, dsout=, eventdate=, start=0, end=1, varname=);

data er_1 (keep = key permno beta &eventdate);
set &dsin;
if &eventdate ne .;
if beta ne .;
run;

/* measure the window using trading days*/
proc sql; create table er_2 as select distinct date from crsp.dsf;quit;

/* create counter */
data er_2; set er_2; count = _N_;run;

/* window size in trading days */
%let windowSize = %eval(&end - &start); 

/* get the closest event window returns, using trading days */
proc sql;
	create table er_3 as 
	select a.*, b.date, b.count
	from er_1 a, er_2 b	
	/* enforce 'lower' end of window: trading day must be on/after event (not before)
		using +10 to give some slack at the upper end */
	where b.date >= (a.&eventdate + &start) and b.date <=(a.&eventdate + &end + 10)
	group by key
	/* enforce 'upper' end of window: minimum count + windowsize must equal maximum count */
	having min (b.count) + &windowSize <= b.count;
quit;


/* determine the start trading day of return window */
proc sql;
	create table er_3 as 
	select a.*, b.count as wS
	from er_1 a, er_2 b	
	where b.date >= (a.&eventdate + &start) 
	group by key
	having min (b.count) = b.count ;
quit;
/* pull in trading days for event window */
proc sql;
	create table er_4 as 
	select a.*, b.date
	from er_3 a, er_2 b	
	where a.ws <= b.count <= a.ws + &windowSize;
quit;
proc sort data=er_4; by key date;run;

/* append firm return and index return */
proc sql;
	create table er_5 as
	select a.*, b.ret, c.vwretd, b.ret - a.beta * c.vwretd as abnret
	from er_4 a, crsp.dsf b, crsp.dsix c
	where a.permno = b.permno
	and a.date = b.date
	and b.date = c.caldt
	and missing(b.ret) ne 1; 
quit;

/* sum abnret - thanks Lin */
proc sql;
	create table er_6 as 
	select key, exp(sum(log(1+abnret)))-1 as abnret
	from er_5 group by key;
quit;

/* create output dataset */
proc sql;
	create table &dsout as
	select a.*, b.abnret as &varname
	from &dsin a left join er_6 b
	on a.key = b.key;
quit;
%mend;
