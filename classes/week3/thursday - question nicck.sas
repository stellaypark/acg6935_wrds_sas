/*
	nicck: check this code -- use of having with max to get to a stock price about 1 year earlier
*/

/* starting point: funda */
%let wrds = wrds.wharton.upenn.edu 4016;options comamid = TCP remote=WRDS;
signon username=_prompt_;

rsubmit;
data nicck (keep = gvkey fyear datadate );
set comp.funda;
if fyear > 2012; /* filter some */
if at > 0 and sale > 0;
/* prevent double records */
if indfmt='INDL' and datafmt='STD' and popsrc='D' and consol='C' ;
run;

/* merge to get permno */
PROC SQL; 
  create table nicck2 as 
  select a.*, b.lpermno as permno
  from nicck a left join crsp.ccmxpf_linktable b 
    on a.gvkey eq b.gvkey 
    and b.lpermno ne . 
    and b.linktype in ("LC" "LN" "LU" "LX" "LD" "LS") 
    and b.linkprim IN ("C", "P")  
    and ((a.datadate >= b.LINKDT) or b.LINKDT eq .B) and  
       ((a.datadate <= b.LINKENDDT) or b.LINKENDDT eq .E)   ; 
  quit; 

/* append prc about 365 before */
Proc sql;
	create table nicck3 as select a.*, b.prc 
	from nicck2 a, crsp.dsf b
	where 
			a.permno = b.permno 
		and a.datadate-372 < b.date < a.datadate-365
		and missing(prc) ne 1
	group by gvkey, datadate 
	having max(b.date) eq b.date;
quit;	

/* download */
proc download data=nicck3 out = nicck3;run;
endrsubmit; 