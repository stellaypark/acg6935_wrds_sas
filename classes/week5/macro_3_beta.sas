/* 
  macro to compute beta 

	dsin, required:
		key, permno, &estDate (e.g. datadate)

  nMonths: #months to use
  minMonths: minimum #months
  estDate: estimation date (nMonths measured before this date)

*/

%macro getBeta(dsin=, dsout=, nMonths=, minMonths=12, estDate=);

/* create return window dates: mStart - mEnd */
data getb_1 (keep = key permno mStart mEnd);
set &dsin; 
/* drop obs with missing estimation date */
if &estDate ne .;
mStart=INTNX('Month',&estDate, -&nMonths, 'E'); 
mEnd=INTNX('Month',&estDate, -1, 'E'); 
if permno ne .;  
format mStart mEnd date.;
run;
  
/* get stock and market return */
proc sql;
  create table getb_2
    (keep = key permno mStart mEnd date ret vwretd) as
  select a.*, b.date, b.ret, c.vwretd
  from   getb_1 a, crsp.msf b, crsp.msix c
  where a.mStart <= b.date <= a.mEnd 
  and a.permno = b.permno
  and missing(b.ret) ne 1
  and b.date = c.caldt;
quit;

/* force unique obs */  
proc sort data = getb_2 nodup;by key date;run;

/* estimate beta for each key 
	EDF adds R-squared (_RSQ_), #degrees freedom (_EDF_) to regression output
*/
proc reg outest=getb_3 data=getb_2;
   id key;
   model  ret = vwretd  / noprint EDF ;
   by key;
run;

/* drop if fewer than &minMonths used*/
%let edf_min = %eval(&minMonths - 2);
%put Minimum number of degrees of freedom: &edf_min;

/* create output dataset */
proc sql;
  create table &dsout as 
	select a.*, b.vwretd as beta 
	from &dsin a left join getb_3 b on a.key=b.key and b._EDF_ > &edf_min;
quit;

%mend;
