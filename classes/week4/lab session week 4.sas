
/*
	Macro arguments passed to your macro are available
	within your macro; e.g. %macro mymacro(myvar=);
	&myvar is substituted for the argument passed to the macro

	what if your macro has an rsubmit block, that needs that variable?
	in other words, how can we make macro variables available to WRDS?
*/
filename mprint 'c:\temp\sas_macrocode.txt';
options mfile mprint;

/* syslput */

%let wrds = wrds.wharton.upenn.edu 4016;options comamid = TCP remote=WRDS;
signon username=_prompt_;

/* this macro retrieves compustat Funda variables from year1 to year2 */

%macro getFunda(dsout=, year1=2010, year2=2013, vars=);

/* this will work */
%put Year1 value: &year1 - year2 value: &year2;
%put Collect variables &vars and create &dsout;

/* syslput pushes macro variables to the remote connection */

%syslput dsout = &dsout;
%syslput year1 = &year1;
%syslput year2 = &year2;
%syslput vars = &vars;

rsubmit;

%put Year1 value: &year1 - year2 value: &year2;
%put Collect variables &vars and create &dsout;

data a_funda (keep = gvkey fyear &vars);
set comp.funda;
if &year1 <= fyear <= &year2;
if indfmt='INDL' and datafmt='STD' and popsrc='D' and consol='C' ;
run;
proc download data=a_funda out=&dsout;
endrsubmit;

%mend;

/* invoke */
%getFunda(dsout=a_funda1, vars=at sale ceq);


/* getting monthly returns 
*/
proc upload data= ... out = myFunda;


proc sql;
	create table mycrsp as select a.*, b.date, b.ret from myFunda a, crsp.msf b
	where a.permno = b.permno and a.datadate - 360 <= b.date <= a.datadate and b.ret ne .;
quit;

* datadate - 360 days should be in first month of the fiscal year;

* compounding returns ( cumret = cumret * (1+ret) ) is cleaner than adding them;


/* using daily returns 
*/
proc upload data= ... out = myFunda;

data z (keep = gvkey fyear datadate boy);
set h2.a_funda;
/* this will set boy to 12 months before datadate */
boy = intnx('month', datadate,-11, 'b');
format boy date9.;
run;

proc sql;
	create table mycrsp as select a.*, b.date, b.ret from myFunda a, crsp.msf b
	where a.permno = b.permno and a.datadate - 360 <= b.date <= a.datadate and b.ret ne .;
quit;

/* firm indentifiers/keys 

	compustat: gvkey
	crsp: permno
	ibes: ibes ticker
	
	matching: 
	- I use crsp.ccm_linktable to get permno (using gvkey)
	- and I use crsp.dsenames to get cusip (historic)
	Funda holds cusip, but it is header cusip; if cusip changes in 2012, then cusip from 1950-2012 gets wiped out 
	and replaced with the 2012 cusip	
*/

