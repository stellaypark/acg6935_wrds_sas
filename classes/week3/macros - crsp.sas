/*

topics

Macros: Simple text replacement
Macros: Conditional code
Macros: from SQL into macro variable
CRSP Daily stock file (DSF)
CRSP Monthly stock file (MSF)
CRSP Indices (DSIX, MSIX)
Matching Compustat and CRSP (CCM)

*/

/* turn on macro debugging */
filename mprint 'C:\temp\tempSAScode.SAS';
options mprint mfile;

/* our first macro - one that doesn't do much */

%macro myFirst(); /* define a new macro with the name 'myFirst' */

/* construct size */
data example.c_mainvars3;
set example.c_mainvars2;
size = log(at);
run;
%mend; /* mend=macro end */

/* invoke (run) the macro and inspect generated text file with code generated */
%myFirst();



/* import statement */



