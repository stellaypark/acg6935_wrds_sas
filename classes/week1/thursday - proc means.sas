
/* sort required */
proc sort data=roaInputs nodupkey; by gvkey fyear ;run;

proc means data=roaInputs NOPRINT; /* suppress output to screen */
  /* but, do output to dataset */
  OUTPUT OUT=roaOutput n= mean= max= median= stddev= /autoname;
  var roa;
  by gvkey; /* without gvkey would give full sample statistics */
run;



/* there are some missing values for roa (missing net income or missing assets) 
	we could drop these observations, but what if we want to keep our sample 'whole'?
	-> add a 'where' clause to the data set being input
*/

proc means data=roaInputs (where= (roa ne .) ) NOPRINT; /* suppress output to screen */
  /* but, do output to dataset */
  OUTPUT OUT=roaOutput n= mean= max= median= stddev= /autoname;
  var roa;
  by gvkey; /* without gvkey would give full sample statistics */
run;
