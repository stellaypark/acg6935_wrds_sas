

*q4;

/* using surveyreg, which gives robust standard errors (preferred) */
proc surveyreg data=h_sample_wins;   
   	model  abnret = unex_p loss loss_unex_p;  
	ods output 	ParameterEstimates  = _surv_params 
	            FitStatistics 		= _surv_fit
				DataSummary 		= _surv_summ;
quit;

