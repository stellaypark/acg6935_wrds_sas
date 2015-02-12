/* 
  macro that appends fiscal year raw return 

	dsin, required:
		key, permno, datadate
	dsout: dataset to be created
*/

%macro getReturn(dsin=, dsout=);

/* create return window dates: mStart - mEnd */
data getr_1 (keep = key permno mStart mEnd);
set &dsin; 
/* drop obs with missing estimation date */
mStart=INTNX('Month',datadate, -11, 'E'); 
mEnd=datadate;
if permno ne .;  
format mStart mEnd date.;
%runquit;
  
/* get stock return */
proc sql;
  create table getr_2
    (keep = key permno mStart mEnd date ret) as
  select a.*, b.date, b.ret
  from   getr_1 a, crsp.msf b
  where a.mStart <= b.date <= a.mEnd 
  and a.permno = b.permno
  and missing(b.ret) ne 1
%runquit;

/* force unique obs */  
proc sort data = getr_2 nodup;by key date;%runquit;

/* sum ret - thanks again, Lin */
proc sql;
	create table getr_3 as 
	select key, exp(sum(log(1+ret)))-1 as ret
	from getr_2 group by key;
%runquit;

/* create output dataset */
proc sql;
  create table &dsout as 
	select a.*, b.ret
	from &dsin a left join getr_3 b on a.key=b.key;
%runquit;

%mend;
