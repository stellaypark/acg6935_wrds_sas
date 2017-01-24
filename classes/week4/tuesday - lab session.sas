/* lab session week 4

	topics: 
		importing macros (in separate file)		
		accessing macro variables in rsubmit block
*/

/* including a file */
%include "E:\teaching\2017_wrds\acg6935_wrds_sas\classes\week3\general macros\runquit.sas";

/* include from web --- note: this is a security risk */ 
/* note -- the file extension is .txt, it contains sas code and it runs */
filename m1 url 'http://bear.warrington.ufl.edu/joost/sas_macros/runquit.txt';
%include m1;

/* it doesn't have to be a macro */
filename m1 url 'http://bear.warrington.ufl.edu/joost/sas_macros/test.txt';
%include m1;

/*  import all files in a folder */
filename mymacros "E:\teaching\2017_wrds\acg6935_wrds_sas\classes\week3\general macros\";
%include mymacros('*.sas');


/* accessing macro variables on wrds in rsubmit */
%let myVariables = at ceq sale;

%put I like to think about &myVariables; 

%let wrds = wrds.wharton.upenn.edu 4016;options comamid = TCP remote=WRDS;
signon username=_prompt_;

rsubmit;
	%put On WRDS I like to think about &myVariables; 
endrsubmit;


/* we need to push the macro variable to the remote connection */

%SYSLPUT myVarWRDS=&myVariables;
rsubmit;
	%put On WRDS I like to think about &myVarWRDS; 
endrsubmit;



/* 	Workflow using macros 
	--------------------
*/

/* folder with macros */
%let macroFolder = E:\teaching\2017_wrds\acg6935_wrds_sas\classes\week4\macros\;

/* folder with sas datasets, make subfolders like data1, data2 */
%let datasetsFolder = E:\sas_libs\temp\;

/* assign libraries */
libname d1 "&datasetsFolder.data1";
libname d2 "&datasetsFolder.data2";

/* load macro files */
%include "&macroFolder\getCompustatFunda.sas";
%include "&macroFolder\addFundQ.sas";
%include "&macroFolder\stdevRoa.sas";


/* having the login twice with emptry rsubmit block forces correct login */
%let wrds = wrds.wharton.upenn.edu 4016;options comamid = TCP remote=WRDS;signon username=_prompt_;
rsubmit;endrsubmit;
%let wrds = wrds.wharton.upenn.edu 4016;options comamid = TCP remote=WRDS;signon username=_prompt_;

/*  main part 
	---------
*/

/* Starting point: Compustat Annual
	Note that we should probably get more years for the standard deviation to be meaningful
*/
%getCompustatFunda(dsout=d1.a_funda, varsFunda=ceq sale at ni sich, startYear=2012, endYear=2015);

/* Add quarterly data */
%addFundQ(dsin=d1.a_funda, dsout=d1.b_withfundq, varsFundq=atq saleq niq);

/* Standard deviation of roa, add two variants */
%stdevRoa(dsin=d1.b_withfundq, dsout=d1.c_stdevroa, nrQuarters=12, minnrquarters=12, varname=stdRoa);
%stdevRoa(dsin=d1.c_stdevroa, dsout=d1.c_stdevroa2, nrQuarters=20, minnrquarters=8, varname=stdRoa_alt);



