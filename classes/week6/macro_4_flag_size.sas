/*
	macro to flag if firm's size is above/below industry-year median
	
	dsin = input dataset, should hold gvkey, fyear, industry variable, size variable
	filter = optional where= filter (creates varname for subset of input, but keeps all rows in input)
	dsout = dataset to create
	size = variable to compute median on (e.g. mcap, sale, etc)
	ind = industry variable (e.g. sich)
	varname = name of variable to create (e.g. largeFirm)
*/

%macro flagMedianSize(dsin=, filter=, dsout=, size=, ind=, varname=);

/* ff-12 industry median market cap */
data fl_1 (keep = indYear gvkey fyear &size);
%if "&filter" ne "" %then %do;
set &dsin (where=(&filter));
%end;
%else %do;
set &dsin ;
%end;
indYear = ff12_ || fyear;
run;
proc sort data=fl_1; by indYear;run;

/* compute industry-year median size */
proc means data=fl_1 noprint;
  output out=fl_2 median=  /autoname ;
  var &size;
  by indYear;
run;

/* append industry-median to input dataset */
proc sql;
	create table fl_3 as select a.*, b.&size._Median 
	from fl_1 a, fl_2 b where a.indYear = b.indYear;
quit;

/* flag */
data fl_3;
set fl_3;
&varname = ( &size > &size._Median);run;

/* create output dset */
proc sql;
	create table &dsout as select a.*, b.&varname. 
	from &dsin a left join fl_3 b 
	on a.gvkey = b.gvkey and a.fyear = b.fyear;
quit;

%mend;
