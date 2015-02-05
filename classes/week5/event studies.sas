/* import macros */

%let myFolder = E:\teaching\2015_wrds\acg6935_wrds_sas\classes\week5;

%include "&myFolder\macro_1_getfunda.sas";
%include "&myFolder\macro_2_earn_ann_date.sas";
%include "&myFolder\macro_3_beta.sas";
%include "&myFolder\macro_4_unexpected_earnings.sas";
%include "&myFolder\macro_5_event_return.sas";
%include "&myFolder\macro_winsor.sas";

filename mprint 'c:\temp\sas_macrocode.txt'; options mfile mprint;

/* Clay's array and do_over are also loaded */


/* create dataset */

/* use funda as starting point */
%getFunda(dsout=a_funda, vars=ni at sale ceq csho prcc_f, laggedvars=at sale csho prcc_f, year1=2010, year2=2013);

/* get earnings announcement date */
%earn_ann_date(dsin=a_funda, dsout=b_earn_ann, varname=ann_dt, source=IBES);
%earn_ann_date(dsin=b_earn_ann, dsout=b_earn_ann2, varname=ann_dt_fundq, source=fundq);

/* get earnings surprise */
%unex_earn(dsin=b_earn_ann2, dsout=c_unex);

/* get beta */
%getBeta(dsin=c_unex, dsout=d_beta, nMonths=30, minMonths=12, estDate=ann_dt);

/* get event stock return */
%eventReturn(dsin=d_beta, dsout=e_ret, eventdate=ann_dt, start=-1, end=2, varname=abnret);
%eventReturn(dsin=e_ret, dsout=e_ret2, eventdate=ann_dt, start=0, end=1, varname=abnret2);

/* some variable construction */
data f_sample;
set e_ret2;
unex_p = unex / prcc_f;
loss = (ni < 0);
loss_unex_p = loss * unex_p;
run;

/* winsorize */
%let myVars = loss loss_unex_p unex_p abnret abnret2;
%winsor(dsetin=f_sample,  byvar=fyear, dsetout=f_sample_wins, vars=&myVars , type=winsor, pctl=1 99);

/* do regression */
proc reg data=f_sample_wins;   
   model  abnret = unex_p loss loss_unex_p;  
quit;

/* using surveyreg, which gives robust standard errors (preferred) */
proc surveyreg data=f_sample_wins;   
   	model  abnret = unex_p loss loss_unex_p;  
	ods output 	ParameterEstimates  = _surv_params 
	            FitStatistics 		= _surv_fit
				DataSummary 		= _surv_summ;
quit;




%macro buildDataset(option=IBES, finalDset=);

/* use funda as starting point */
%getFunda(dsout=a_funda, vars=ni at sale ceq csho prcc_f, laggedvars=at sale csho prcc_f, year1=2010, year2=2013);

/* get earnings announcement date */
%if &option eq IBES %then %do;
  %earn_ann_date(dsin=a_funda, dsout=b_earn_ann, varname=ann_dt, source=IBES);
%end;
%else %do;
  %earn_ann_date(dsin=a_funda, dsout=b_earn_ann, varname=ann_dt, source=fundq);
%end;

/* get earnings surprise */
%unex_earn(dsin=b_earn_ann2, dsout=c_unex);

/* get beta */
%getBeta(dsin=c_unex, dsout=d_beta, nMonths=30, minMonths=12, estDate=ann_dt);

/* get event stock return */
%eventReturn(dsin=d_beta, dsout=e_ret, eventdate=ann_dt, start=-1, end=2, varname=abnret);
%eventReturn(dsin=e_ret, dsout=&finalDset, eventdate=ann_dt, start=0, end=1, varname=abnret2);
%mend;
%buildDataset(option=IBES, finalDset=mydatasetIBES);
%buildDataset(option=fundq, finalDset=mydatasetFundq);
