/* import macros used in week 5*/

%let myFolder = E:\teaching\2017_wrds\assignment solutions\assignment 5;
                
%include "&myFolder\macro_1_getfunda.sas";

%include "&myFolder\macro_winsor.sas";

/* macros for q1-q4 */
%include "&myFolder\macro_q1_getFirmYears.sas";

/* load Clay's array and do_over and runquit */
filename m1 url 'http://www.wrds.us/macros/array_functions.sas'; %include m1;
filename m2 url 'http://www.wrds.us/macros/runquit.sas'; %include m2;
/* create dataset */

/* get firm-quarter data and permno */
%getFirmYears(dsout=a_fundq, vars=niq atq saleq prccq, laggedvars=atq saleq, year1=2011, year2=2013);

data b_enddate (keep = permno datadate startDate endDate);
set a_fundq;
startDate = intnx('month',datadate, -3, 'B');
endDate = datadate;
format startDate endDate date9.;
run;

/* append daily stock return and index return*/
proc sql;
	create table c_msf as
	select a.*, b.ret, b.date
	from b_enddate a, crsp.dsf b
	where a.permno = b.permno
	and a.startDate <= b.date <= a.endDate 
	and missing(b.ret) ne 1 ; 
quit;

/* chop up the data by quarter -- here year 2011 -- need to make sure days with no trading have a missing value */

data c_msf2 (keep = permno date ret);
set c_msf;
if "01jan2011"d <= date <= "20jan2011"d; /* some dates */
if permno in (10001, 10002, 10116, 10138); /* some firms */ 

run;

/* transpose 'by' requires sort */
proc sort data = c_msf2; by date;run;

/* transpose -> each permno in a column, #rows is #days */
proc transpose data=c_msf2 out=d_msfwide prefix=p;
id permno;
    by date ;    
    var ret;
run;

/* correlations */
proc corr data=d_msfwide;run;
