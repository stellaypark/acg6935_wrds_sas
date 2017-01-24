/* 	macro that creates a starting dataset based on Funda 

	Variables 
	dsin: name of dataset to start with, assumed to have gvkey, datadate, fyear
	dsout: name of dataset to create
	varsFundq: names of variables to get from fundq
	
	Example:	
	%addFundQ(dsin=d1.a_funda, dsout=d1.b_withfundq, varsFundq=atq saleq niq);


	note: varsFundq is a list of variables, like atq saleq niq -- and need commas between them

	I am using this code to replace the space with a comma

	 %let original= ceq at sale ;
     %let replaceWithThis= %str(,) ;
     %let findThis= %str( ) ;
     %let tranwrded= %sysfunc(tranwrd(&original, &findThis, &replaceWithThis)) ;
     %put Original: &original ***** TRANWRDed: &tranwrded ;

     This Thursday we will cover the Clay macros, which is much more elegant

*/

%macro addFundQ(dsin=, dsout=, varsFundq=);

	/* construct comma separated varlist */
	%let varList= %sysfunc(tranwrd(&varsFundq, %str( ) , %str(,) )) ;

	/* push macro variables to wrds */
	%SYSLPUT dsin=&dsin;
	%SYSLPUT dsout=&dsout;
	%SYSLPUT varsFundq=&varList;
	
	rsubmit;

	proc upload data=&dsin out = myComp3;run;

			%put varsFundq: &varsFundq;

	/* join with fundq */
	proc sql;
		create table myComp4 as
		select a.* , b.datadate as datadate_fundq, &varsFundq
		from myComp3 a left join comp.fundq b
		on a.gvkey = b.gvkey and a.fyear = b.fyearq;
	quit;

	/* download as &dsout */
	proc download data=myComp4 out=&dsout;run;

	endrsubmit;

%mend;

