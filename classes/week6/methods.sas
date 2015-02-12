/* import macros */

%let myFolder = E:\teaching\2015_wrds\acg6935_wrds_sas\classes\week6;
%let exportDir= &myFolder\sas_exports;

/* specific macros */
%include "&myFolder\macro_1_getfunda.sas";
%include "&myFolder\macro_2_get_return.sas";
%include "&myFolder\macro_3_beta.sas";
%include "&myFolder\macro_4_flag_size.sas";

/* general macros */
%include "&myFolder\macro_winsor.sas";
%include "&myFolder\macro_correlation_table.sas";
%include "&myFolder\macro_ind_ff12.sas";
%include "&myFolder\macro_two_groups_table.sas";
%include "&myFolder\macro_common_macros.sas";

filename mprint 'c:\temp\sas_macrocode.txt'; options mfile mprint;

/* create dataset */

/* use funda as starting point */
%getFunda(dsout=a_funda, vars=ni at sale ceq csho prcc_f, laggedvars=ceq at csho prcc_f, year1=2011, year2=2013);

/* important: define list of main variables, and refer to them by &myVars
	ensures consistency for winsorize, descriptive vars, treatment of missing vars, etc */

%let myVars = ret beta btm size roa loss beta_lag btm_lag size_lag;

/* some variable construction */
data b_vars;
set a_funda;
/* size: log of lagged market cap */
size = log(csho * prcc_f);
size_lag = log(csho_lag * prcc_f_lag);
/* btm: lagged equity / lagged market cap */
btm = ceq / (csho * prcc_f);
btm_lag = ceq_lag / (csho_lag * prcc_f_lag);
/* profitability */
roa = ni/at;
loss = (ni < 0);
/* beginning of year */
boy=INTNX('Month',datadate, -11, 'B'); 
format boy date9.;
%runquit;

/* get raw return */
%getReturn(dsin=b_vars, dsout=c_ret);

/* get beta */
%getBeta(dsin=c_ret, dsout=d_beta, nMonths=30, minMonths=12, estDate=boy, varname=beta_lag);
%getBeta(dsin=d_beta, dsout=d_beta2, nMonths=30, minMonths=12, estDate=datadate+1, varname=beta);

/* winsorize */
%winsor(dsetin=d_beta2,  byvar=fyear, dsetout=e_sample_wins, vars=&myVars , type=winsor, pctl=1 99);

/* indicators */
data f_year_ind;
set e_sample_wins;
%do_over(values=2004-2013, phrase=d? = (fyear eq ?););
/* indicator variable flags if any missings */
hasanymiss = ( cmiss (of &myVars) > 0 ); /* 1 if cmiss > 0 */
run;

/* fama french 12 industry indicator vars */
%ind_ff12 (dset=f_year_ind, outp=g_ff, sic=sich, bin_var=ff12_, ind_code=ff12_, ff12_name=ff12_name );

/* flag large firms, creates largeFirm (1 if size > industry-year median) 
	do this only for firms that have all variables (hasanymiss eq 0)
*/
%flagMedianSize(dsin=g_ff, filter=hasanymiss eq 0, dsout=h_large, size=size, ind=ff12_, varname=largeFirm);

/* using surveyreg, which gives robust standard errors (preferred) */
proc surveyreg data=g_ff;   
   	model  ret = beta size btm d2004-d2013 ff12_1-ff12_12;  
	ods output 	ParameterEstimates  = _surv_params 
	            FitStatistics 		= _surv_fit
				DataSummary 		= _surv_summ;
quit;

/* write as macro */
%macro regRobust(dsin=, dep=, model=, outp=);
proc surveyreg data=&dsin;   
   	model  &dep = &model d2004-d2013 ff12_1-ff12_12;  
	ods output 	ParameterEstimates  = &outp._params 
	            FitStatistics 		= &outp._fit
				DataSummary 		= &outp._summ;
quit;
%mend;

%regRobust(dsin=h_large (where=(hasanymiss eq 0)), dep=ret, model=beta size btm, outp=_reg1);
%regRobust(dsin=h_large (where=(hasanymiss eq 0)), dep=ret, model=beta_lag size_lag btm_lag, outp=_reg2);

/* descriptive statistics */
proc means data= h_large (where=(hasanymiss eq 0)) NOPRINT;
OUTPUT OUT=table_1 mean= median= std= min= max= p25= p75= N=/autoname;
var &myVars;
%runquit;

%myExport(dset=table_1, file=&exportDir\1_means.csv);

%correlationMatrix(dsin=h_large (where=(hasanymiss eq 0)), vars=&myVars, mCoeff=corrCoeff, mPValues=corrProb);

/* 'high'-'low' table: compare mean/medians for two groups 
	(grouping typically on variable used for testing hypotheses)
	excluding 'hasanymiss eq 0' obs (these have missing for largeFirm 
*/
%tableByGroup(dsin=h_large (where=(hasanymiss eq 0)), vars=&myVars, byvar=largeFirm, export=byLarge);

/* Jackknife: repeat regressions with excluding one firm/industry/group at the time */

%macro doJackknife(filter);
	/* run regression excluding ff12 industry &filter */
	%regRobust(dsin=h_large (where=(hasanymiss eq 0 and ff12_ ne &filter )), dep=ret, model=beta size btm, outp=_reg1);

	/* set filter variable on regression output (to identify results)*/
	data _reg1_params;
	set _reg1_params;
	filter= &filter;run;

	/* keep all results in a single dataset work.jackknife*/
	%if %sysfunc(exist(jackknife)) %then %do;
		/* Add new obs to original data set */
		proc append base=jackknife data=_reg1_params;
		run;
  	%end;
  	%else %do;
		/* first regression: set jackknife */
		data jackknife; set _reg1_params;run;
	%end;
%mend;

/* delete jackknife results (in case created again)*/
proc datasets; delete jackknife; quit;

/* repeat regression leaving out one industry at the time */
%do_over(values=1-12, macro=doJackknife);

/* is beta robust across jackknife groups? */
data jackknife_beta;
set jackknife;
if Parameter eq "beta";
run;

/* logistic regression: let's predict losses */

%macro doLogistic(dsin=, dep=, vars=);
	proc logistic data=&dsin descending  ;
	  model &dep = &vars  d2004-d2013 ff12_1-ff12_12 / RSQUARE SCALE=none ;
	  /* not needed here, but out= captures fitted, errors, etc */
	  output out = logistic_predicted  PREDICTED=predicted ;

	  	ods output	ParameterEstimates  = _outp1
					OddsRatios 			= _outp2
					Association 		= _outp3
					RSquare  			= _outp4
					ResponseProfile 	= _outp5
					GlobalTests   		= _outp6			
					NObs 				= _outp7 ;
	%runquit;
%mend;

/* helper macro to export the 7 tables for each logistic regression */
%macro exportLogit(j, k);
	%myExport(dset=_outp1, file=&exportDir\logistic_&j._&k._coef.csv);
	%myExport(dset=_outp2, file=&exportDir\logistic_&j._&k._odds.csv);
	%myExport(dset=_outp3, file=&exportDir\logistic_&j._&k._assoc.csv);
	%myExport(dset=_outp4, file=&exportDir\logistic_&j._&k._rsqr.csv);
	%myExport(dset=_outp5, file=&exportDir\logistic_&j._&k._response.csv);
	%myExport(dset=_outp6, file=&exportDir\logistic_&j._&k._globaltest.csv);
	%myExport(dset=_outp7, file=&exportDir\logistic_&j._&k._numobs.csv);
%mend;

/*	Do logistic regression */

/* model 1 */
%doLogistic(dsin=h_large (where=(hasanymiss eq 0)), dep=loss, vars=ret beta size btm );
%exportLogit(t1,col1);

/* model 2 */
%doLogistic(dsin=h_large (where=(hasanymiss eq 0)), dep=loss, vars=ret beta_lag size_lag btm_lag );
%exportLogit(t1,col2);

/* Fixed effects -- firm specific intercept 
	(could also be industry-specific, or firm-year specific, etc)
	
*/

/* requires sorting */
proc sort data = h_large; by gvkey;run;
 
/* glm */
proc glm data = h_large (where=(hasanymiss eq 0));
  /* absorb followed by group */
  absorb gvkey;
  ods output	ParameterEstimates  = FE_params 
	       	    FitStatistics 		= FE_fit
            	NObs 				= FE_obs;
  model ret = beta_lag size_lag btm_lag d2004-d2013 ff12_1-ff12_12  / solution ; 
quit; 

/* specification in case you want to have the firm-specific intercepts 
	Note: much slower
*/
proc glm data = h_large (where=(hasanymiss eq 0));
  class gvkey; /* instead of absorb */
  ods output	ParameterEstimates  = FE_params
	       		FitStatistics 		= FE_fit
            	NObs 				= FE_obs;
  /* adding gvkey gives coefficient for each gvkey*/
  model ret = beta_lag size_lag btm_lag d2004-d2013 ff12_1-ff12_12  gvkey / solution ; 
quit;
