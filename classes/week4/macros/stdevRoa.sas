/* 
  compute standard deviation of ROA 
  
  	dsin: dataset with gvkey, fyear, datadate_fundq, niq, atq
  	dsout: dataset generated: dsin with roa_stddev appended 
	nrYears: number of years to use (multiplied by 4 to get to #quarters)
	minnrquarters: minimum number of quarters
	varname: name of variable that is created

	the date range for the quarters starts #nrQuarters before the current quarter,
	and ends with the current (easy to adapt to exclude the current quarter -- 
	startDate would -nrQuarters before and endDate would be -1 quarter before)
  */

%macro stdevRoa(dsin=, dsout=, nrQuarters=20, minnrquarters=12, varname=stdRoa);


	/* starting point (only necessary data) */
	data std1 (keep = gvkey fyear roa datadate_fundq startDate endDate);
	set &dsin;	
	/* drop missing net income and assets */
	if cmiss (of niq atq) eq 0;
	roa = niq / atq;
	/* date range starts #nrQuarters before datadate_fundq */
	startDate = intnx('quarter', datadate_fundq, - %eval( &nrQuarters - 1 ), 'e');
	endDate =  intnx('quarter', datadate_fundq, 0, 'e');;
	format startDate endDate  date9.;
	run;

	/* self join to get previous quarters */

	proc sql;
	  create table std2 as 
	  select a.gvkey, a.datadate_fundq, b.roa
	  from
	    std1 a, std1 b
	  where
	    a.gvkey = b.gvkey
	    and a.startDate <= b.datadate_fundq <= a.endDate; /* this year and 4 years before */
	quit;

	proc sort data = std2; by gvkey datadate_fundq;run;

	/* compute stddev */
	proc means data=std2  NOPRINT;
	OUTPUT OUT=std3 STD=/autoname;
	var roa;
	by gvkey datadate_fundq ;
	run;

	/* dataset with standard deviation of ROA:
	  firmyear, ROA_StdDev 
	  require at least 3 obs
	*/
	data std3;
	set std3;
	if _FREQ_ >= &minnrquarters;
	run;

	/* drop doubles (4 quarters in each year) */
	proc sort data=std3 nodupkey; by gvkey datadate_fundq;run;

	/* create output dataset */
	proc sql;
	  create table &dsout as 
	  select a.*, b.roa_StdDev as &varname from &dsin a left join std3 b on a.gvkey = b.gvkey and a.datadate_fundq = b.datadate_fundq; 
	quit;

%mend;
