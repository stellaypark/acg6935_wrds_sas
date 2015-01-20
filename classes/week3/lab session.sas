

/* read macro pdf and little SAS book ch7 */

/* see if deleting pops up a window */
proc datasets;
	delete _out_pe;
quit;

/* storing files on wrds home folder */

rsubmit;

/* for antti only, this */
libname myfiles "~"; /* reference to /home/ufl/antti81 */
/* is the same as */
libname myfiles "/home/ufl/antti81"; /* reference to /home/ufl/antti81 */
/* for me it would be */
libname myfiles "/home/ufl/imp"; 



data work.something;
set comp.funda;
if fyear eq 2013;
*etc;
run;
* refer to myfiles. ...;

endrsubmit;


/* using sql to get a percentage
	
	assuming you have a dset with month and numobs 
	how to add the percentage (i.e. numobs / sum of numobs)
	
	one way is to use a data step with 'retain', 
	then sort descending
	on the sum
*/
proc sql;
	create table result as select month, numobs/sum(numobs) as perc from input;
quit;

* using library locally ;
* in windows, you navigate to your stick, and create a directory ;
* in SAS, make a libname statemen, to this directory ;
* after that, in your proc download in rsubmit block you can refer
to the stick using the libname ;
libname stick "F:myprojects";

rsubmit;
libname myfiles "~";
proc download data  = myfiles.a_funda out = stick.a_funda; run;
proc download data  = myfiles.quarterly out = stick.quarterly; run;
endrsubmit;
