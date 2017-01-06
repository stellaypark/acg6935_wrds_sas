/*
	in class assignments


	1. 	Some variables in Funda are 'header' (that means, all firms' rows get updated if the value changes)
		Verify if variable 'CIK' (central index key) changes over time or not (if it doesn't change, it means it is a header variable)

	2. 	For each firm (with non-missing assets, sales and equity) count the number of years of data before prcc_f is non-missing
		(For example, if a firm is added to Funda in 2004, and prcc_f only is available for the first time in 2006, then there are 2 years of data for that firm)

*/

/* years in Funda before prcc_f is set */
data myCount (keep = gvkey counter);
set myComp;
retain counter flag;
by gvkey;
if first.gvkey then do;
	counter = 0;
	flag = 0;
end;
if flag eq 0 then do;
	/* as long as flag is zero prcc_f is missing */
	if missing(prcc_f) eq 0 then flag = 1; /* it is non-missing, set flag to 1 */
	else do;
		/* prcc_f is still missing, increase the counter */
		counter = counter + 1;
	end;
end;
if last.gvkey then output;
run;

