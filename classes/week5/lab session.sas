/* lab session week 5

*/



/*

%array function: the idea is that you want 'something' loaded into an array

array name: 'animals', we have 3 animals: cow, bird, kangaroo

we want to create: 
animal1 = "cow"
animal2 = "bird"
animal3 = "kangaroo"
animalN = 3

%array can be used in 2 ways:

1. 'directly'

%array(animal, values =cow bird kangaroo);

2. take the variables from a dataset, assume there is a dataset work.inputs, that has variable 'myanimal', and
there are 3 records, cow, bid, etc

%array(animal, data=work.inputs, var=myanimal);
%array(array=animal, data=work.inputs, var=myanimal);

*/

%macro myMacro(var);
%put macro argument: &var;
%mend;
/* invoke */
%myMacro(hi animal lovers);

%macro myMacro(var=);
%put macro argument: &var;
%mend;

/* invoke */
%myMacro(var=hi animal lovers);

%macro myMacroTwo(x=, y=);
%put macro argument: &x and &y;
%mend;
/* this is identical */
%myMacroTwo(x=5, y=7);
%myMacroTwo(y=7, x=5);

%macro myMacroTwo(x, y);
%put macro argument: &x and &y;
%mend;

%myMacroTwo(5, 7);
/* not identical */
%myMacroTwo(7, 5);
					
 /* q2 */

proc datasets lib = comp; contents data=funda; quit;run; 

/* Retrieve variables in Funda using rsubmit*/
rsubmit;endrsubmit;
%let wrds = wrds.wharton.upenn.edu 4016;options comamid = TCP remote=WRDS;
signon username=_prompt_;

rsubmit;
ods listing close; 
ods output variables  = varsFunda; 
proc datasets lib = comp; contents data=funda; quit;run; 
ods output close; 
ods listing; 

/* keep relevant variables (excluding firm name, gvkey, fyear, etc)*/
data varsFunda_short ;
set  varsFunda;
if 37 <= Num <= 937;
run;

proc download  data=varsFunda out=varsFunda;run;
proc download  data=varsFunda_short out=varsFunda_short;run;
endrsubmit;

proc sort data=varsFunda ; by num;run;

/* how to figure out which 'elements' y (y could be a name, or id) are in both dataset A and B 
	y - firm || analyst
	B: firm_analyst for previous period
	A: firm_analyst for next period

*/

/* using 'forbidden' procedure, proc sql ('never use proc sql' - Andre D'Souza) */

proc sql;
	create table X as select a.* from A where a.y IN (select y from B);
quit;

/* q1 - how would you write specific code without a macro/do_over */

* assume you have a dataset work.mydata that has at, sale, ceq and you want to keep the variable that 
has the largest value;
data mydata;
set mydata;
/* how can you create a variable that holds the largest value in: at, sale, ceq */
maxvar = -1000000 ;
/* assuming at is the largest variable */
if at > maxvar then maxvar = at; /* then this will be true, and maxvar will be set to at */
if sale > maxvar then maxvar = sale; /* then this will be false */
if ceq > maxvar then maxvar = ceq; /* then this will be false */
/* in a do_over phrase, I am repeating "if ? > maxvar then maxvar = ? ;" */
run;


data mydata;
set mydata;
/* how can you create a variable that holds the largest value in: at, sale, ceq */
maxvar = -1000000 ;
/* assuming at is the largest variable */
/* in a do_over phrase, I am repeating "if ? > maxvar then maxvar = ? ;" */
%do_over(values=at sale ceq, phrase= if ? > maxvar then maxvar = ? ;);
run;

%macro myMacro(dsin=, dsout=, vars=, maxvar=);
data &dsout (keep = &vars. &maxvar. &maxvar.name);
set &dsin.;
/* how can you create a variable that holds the largest value in: at, sale, ceq */
&maxvar = -1000000 ;
/* assuming at is the largest variable */
/* in a do_over phrase, I am repeating "if ? > maxvar then maxvar = ? ;" */
/*%do_over(values=&vars, phrase= if ? > &maxvar then &maxvar = "?" ;);*/
%do_over(values=&vars., phrase= if ? > &maxvar. then do; &maxvar. = ?; &maxvar.name = "?"; end ;)
run;
%mend;

filename mprint 'c:\temp\sas_macrocode.funky';
options mfile mprint;

/*invoke */
%myMacro(dsin=a_funda1, dsout=z_max, vars=ceq at sale, maxvar=mymax);


data z_max;
set a_funda1;
mymax = -1000000 ;
if ceq > mymax then do;
mymax = ceq;
mymaxname = "ceq";
end ;
if at > mymax then do;
mymax = at;
mymaxname = "at";
end ;
if sale > mymax then do;
mymax = sale;
mymaxname = "sale";
end ;
;
run;
