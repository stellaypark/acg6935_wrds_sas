rsubmit;endrsubmit;
%let wrds = wrds.wharton.upenn.edu 4016;options comamid = TCP remote=WRDS;
signon username=_prompt_;

filename m1 url 'http://www.wrds.us/macros/array_functions.sas';
%include m1;

filename mprint 'c:\temp\sas_macrocode.txt';
options mfile mprint;



%macro mMacroVars(vars=);

%syslput vars = &vars;
rsubmit;

filename m1 url 'http://www.wrds.us/macros/array_functions.sas';
%include m1;

%put %do_over(values=&vars, phrase=variable passed: ?);

endrsubmit;
%mend;

%mMacroVars(vars=fyr=12 fqtr=3);

/* what if we locally define an array, that we want to use on WRDS?
	=> each of the array elements and the arraynameN element need to be pushed to 
	wrds with syslput */

/* define local array */
%array(myArr, values=cat dog mouse);

/* local test */
%put Dogs drool but &myArr1.s rule;
%put Number of elements: &myArrN ;



/* push to remote server 
	%syslput myArr1 = &myArr1;
	%syslput myArr2 = &myArr2;
	%syslput myArr3 = &myArr3;
	%syslput myArrN = &myArrN;
*/

/* problem: how to generate this code so that any array can be pushed into wrds?
	=> SAS does not like %... being generated in do_over loop
*/
