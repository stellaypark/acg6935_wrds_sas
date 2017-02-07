/* this is a macro that I want to upload to wrds 

	and I want to invoke it in an rsubmit block

	like:

	rsubmit;
		proc upload data=
		%doMyMacro(dsout=mytable) ;
	endrsubmit;
*/

 rsubmit;
 /* puts the macro on the disk */
 Proc Upload
  infile='E:\teaching\2017_wrds\acg6935_wrds_sas\classes\week6\lab_session_macros\myMacro.sas'
  outfile='~/my_sas_macro.sas' ;
 run;

 /* loads the macro */
 %include '~/my_sas_macro.sas';

 /* invoke */
 %doMyMacro(dsout=mySasFile);

 /* download */
 proc download data=mySasFile out=newfile;run;

endrsubmit;

 



