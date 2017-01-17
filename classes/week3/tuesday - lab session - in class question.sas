in class question 1


/*
	Use proc sql to write query to find firms that change fiscal year end; for these firm-years 
	compute the median market to book ratio 
	for year of end of year change as well as the previous year.
*/

%let wrds = wrds.wharton.upenn.edu 4016;options comamid = TCP remote=WRDS;
signon username=_prompt_;

rsubmit;
data myComp (keep = gvkey fyear datadate at sale ceq prcc_f csho mtb fyr);
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
	create table fyrchange as 
		select a.gvkey, a.fyear, a.fyr, a.mtb, b.fyear as fyear_prev, b.fyr as fyr_prev, b.mtb as mtb_prev
		from mycomp a, mycomp b
		where a.gvkey = b.gvkey and a.fyear-1=b.fyear 
			/* require that fyr changes */
			and a.fyr ne b.fyr
			;
quit;


proc sql;
	create table fyrchange as 	
		select median (mtb) as mtb_m, median (mtb_prev) as mtb_m_prev
		from (
			select a.gvkey, a.fyear, a.fyr, a.mtb, b.fyear as fyear_prev, b.fyr as fyr_prev, b.mtb as mtb_prev
			from mycomp a, mycomp b
			where a.gvkey = b.gvkey and a.fyear-1=b.fyear 
				/* require that fyr changes */
				and a.fyr ne b.fyr
		);
quit;
