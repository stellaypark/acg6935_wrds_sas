/*
	binning => terciles, quartiles, quintiles, etc
*/

/* using proc rank, groups = 10 will create 11 groups! (one group with missing and groups 0-9) */

proc rank data = myComp out=myComp2 groups = 10;
var roa size ; 		
ranks roa_d size_d ; 
run;

/* are the bins of equal size? */
proc freq data=myComp2;
tables roa_d;
run;

/* 	What if we want to include the vars with missing roa in the first decile and we want the first 9 deciles to have the same #obs?
	=> Create our own binning procedure */

/* get number of observations -- yes, this looks like a hack */
data _NULL_;
	if 0 then set myComp2 nobs=n;
	call symputx('numObs',n);
	stop;
run;

%let nrBins = 10; 
/* the binsize (#obs in each bin) is the #obs divided by #bins (needs rounding down)  */
%let binSize = %sysfunc(floor( %eval(&numObs/&nrBins) ));
%put Binsize: &binSize;

/* Just in case we use the rank procedure twice on variables that are correlated we add and sort on a random variable */
data myComp3;
set myComp2;
myRandom = ranuni(123); /* 123 is the seed for the random number generator */
run;

/* sort on the binning variable (and the random variable) */
proc sort data = myComp3; by roa myRandom;run;

/* If we want to create a ranked variable by year, we would repeat the whole procedure by each year -- remind me when we have covered Clay macro's %array and %do_over*/

/* Create decile for binning variable */
data myComp3;
set myComp3;
bin = floor( ( _N_ - 1 ) / &binSize);
run;

/* are the bins of equal size? */
proc freq data=myComp3;
tables bin;
run;


/* we will conver macros later (week 3/4) -- here is an example though

/*
	myBin macro arguments:
	data: dataset 
	var: variable to bin
	rankname: ranked variable will be named &var_&rankname, e.d. sale_d if var is 'sale' and rankname is '_d', default if not passed is '_rank'
	groups: number of bins (default if not passed: 10)
	
	sample usage, creates deciles in sale_d: %myBind(data=myData, var=sale); 
*/

%macro myBin(data=, var=, rankname=_rank, groups=10);

/* create random variable */
data myBin1;
set &data;
myBinRandom = ranuni(8675309);
run;

/* get number of observations */
data _NULL_;
	if 0 then set myBin1 nobs=n;
	call symputx('numObs',n);
	stop;
run;

/* the binsize (#obs in each bin) is the #obs divided by #groups (needs rounding down)  */
%let binSize = %sysfunc(floor( %eval(&numObs/&groups) ));

/* sort on the binning variable (and the random variable) */
proc sort data=myBin1; by &var myBinRandom;run;

/* Create decile for binning variable */
data &data (drop = myBinRandom);
set myBin1;
&var.&rankname = floor( (_N_ - 1) / &binSize);
run;

%mend;

/* usage */
%myBin(data=myComp2, var=sale); /* appends sale_rank */
%myBin(data=myComp2, var=sale, groups=2, rankname=_m); /* appends sale_m, median split: small vs large */
