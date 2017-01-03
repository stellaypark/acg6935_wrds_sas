
/* using output to create observations */
data mytest;
do x = 0 to 2000;
	y = x;
	output;
end;

format x date9.;run;


/* approximate randomization - pseudo test*/

/* generate N samples with random event dates */
data mydata (drop = i);
/* repeat times */
do sample = 1 to 10 ;
	/* generage event dates */
	do i = 1 to 5 ;			
		/* generate a random date between 1/1/2000 and 31/12/2010 
			- floor rounds a number down (dates are integers)
			- ranuni generates random number, 6675309 is a random seed (can be any other number)
			- difference in dates (1/1/2010 vs 1/1/2000) is #days in 10-year period
		*/
	   	eventdate = '01jan2000'd + floor(ranuni(8675309)*( '01jan2010'd - '01jan2000'd ) );
		output;
	end;
end; 
format eventdate date9.;
run;




/* if the following 3 data steps are executed together, SAS will not stop when the error is encounterd */
/* create valid dataset */
data good;
x = 1;
run;

/* data step with an error */
data good;
set good;
this will surely break sas;
x = 0;
run;

/* datastep attempting to make a change to dataset good*/
data something;
set good;
y= x +1;
run;


/* macro that will abort sas when error encountered */
%macro runquit;
     ; run; quit; 
     %if &syserr. ne 0 %then %do;
        %abort cancel;
     %end;
%mend runquit;

/* with runquit sas will now stop */
data good;
set good;
this will surely break sas;
x=0;
%runquit;
data something;
set good;
y= x +1;
%runquit;



/* if you have a 'by' with 2 variables, you can still use first with the second variable */

data oneversion;
set myCompTable;
if _N_ <=30;
run;

/* make a version with duplicate firm-years */
data doubleversion;
set oneversion oneversion;run;

proc sort data=doubleversion; by gvkey fyear;run;


data test (keep = gvkey fyear flag fordiana);
set doubleversion;
by gvkey fyear;
if first.fyear then flag = 1;
if last.fyear then flag2 = 1;
run;