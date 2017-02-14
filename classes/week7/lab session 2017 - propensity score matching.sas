
%let wrds = wrds.wharton.upenn.edu 4016;options comamid = TCP remote=WRDS;
signon username=_prompt_;

rsubmit;
data myComp (keep = gvkey fyear datadate sich at sale ceq prcc_f csho mtb fyr ni loss conm);
set comp.funda;
/* require fyear to be within 2001-2015 */
if 2010 <=fyear <= 2012;
/* require assets, etc to be non-missing */
if cmiss (of at sale ceq ni) eq 0;
/* construct some variables */
mtb = csho * prcc_f / ceq;
/* loss indicator */
loss = ( ni < 0);
/* prevent double records */
if indfmt='INDL' and datafmt='STD' and popsrc='D' and consol='C' ;
run;
proc download data=myComp out=myComp;run;
endrsubmit;


data mycomp2;
set mycomp;
nameHigh = (conm > 'L'); /* A-L: 0, M-Z: 1 */
/* you can flip it around */
run;

/* logistic regression */

	proc logistic data=mycomp2 descending  ;
	  model loss = mtb sale / RSQUARE SCALE=none ;
	  /* not needed here, but out= captures fitted, errors, etc */
	  output out = my_compout  PREDICTED=predicted ;

	  	ods output	ParameterEstimates  = _outp1
					OddsRatios 			= _outp2
					Association 		= _outp3
					RSquare  			= _outp4
					ResponseProfile 	= _outp5
					GlobalTests   		= _outp6			
					NObs 				= _outp7 ;
	%runquit;

/* matched sample */
proc sql;
	create table matched as 
		select a.gvkey, a.fyear, a.loss, a.predicted, 
			b.gvkey as gvkey_m, b.loss as loss_m, b.predicted as predicted_m
		from my_compout a, my_compout b
		where
			a.fyear = b.fyear
		and a.nameHigh eq 0
		and b.nameHigh eq 1
		and a.predicted -0.01 <= b.predicted <= a.predicted + 0.01
		and not missing(a.predicted) 
		and not missing(b.predicted) 
		group by a.fyear, a.gvkey
		having min(abs(a.predicted - b.predicted)) eq abs(a.predicted - b.predicted);
quit;





