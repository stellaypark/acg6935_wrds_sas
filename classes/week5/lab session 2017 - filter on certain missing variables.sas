
data b_msf;
set crsp.msf;
if missing(ret);
run;

data b_msf2 (keep = permno ret newvar);
set b_msf;
/* convert missing variable ret to a string of length 1 */
newvar = put(ret, $1.);
/* keep all missings of type 'C' */
if newvar eq "C";
run;
