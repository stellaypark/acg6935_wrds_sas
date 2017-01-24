/* 	macro that creates a starting dataset based on Funda 

	Variables 
	dsout: name of dataset to create
	varsFunda: names of variables to get from funda
	startYear: start fiscal year
	endYear: end fiscal year

	Example:	
	%getCompustat(dsout=d1.a_funda, varsFunda=ceq sale at ni sich, startYear=2000, endYear=2015);
*/

%macro getCompustatFunda(dsout=, varsFunda=, startYear=, endYear=);

	/* push macro variables to wrds */
	%SYSLPUT dsout=&dsout;
	%SYSLPUT varsFunda=&varsFunda;
	%SYSLPUT startYear=&startYear;
	%SYSLPUT endYear=&endYear;

	rsubmit;

	data myComp (keep = gvkey fyear datadate &varsFunda );
	set comp.funda;
	/* require fyear to be within 2001-2015 */
	if &startYear <=fyear <= &endYear;
	/* prevent double records */
	if indfmt='INDL' and datafmt='STD' and popsrc='D' and consol='C' ;
	run;

	/* let's append permno */

	proc sql;
	  create table myComp2 as 
	  select a.*, b.lpermno as permno
	  from myComp a left join crsp.ccmxpf_linktable b 
	    on a.gvkey eq b.gvkey 
	    and b.lpermno ne . 
	    and b.linktype in ("LC" "LN" "LU" "LX" "LD" "LS") 
	    and b.linkprim IN ("C", "P")  
	    and ((a.datadate >= b.LINKDT) or b.LINKDT eq .B) and  
	       ((a.datadate <= b.LINKENDDT) or b.LINKENDDT eq .E)   ; 
	quit; 

	/* download as &dsout */
	proc download data=myComp2 out=&dsout;run;

	endrsubmit;

%mend;

