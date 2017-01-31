filename m1 url 'http://www.wrds.us/macros/array_functions.sas';
%include m1;

/*	Include runquit macro */

filename m2 url 'http://www.wrds.us/macros/runquit.sas';
%include m2;

%macro combineMatrices(lowerleft=, upperright=, dsout=);

	/*	This macro takes the lowerleft and upperright of two matrices
		and combines these into the dsout matrix */


	/* 	Lower left Pearson: Set to zero when above diagonal */

	data corr_temp1 (drop = i);
	set &lowerleft;
	array corrMatrix {&variablesN} %DO_OVER(variables, PHRASE=? );

	do i=1 to &variablesN;
		if i > _N_ then corrMatrix{i} = 0;
	end;
	row = _N_;
	%runquit;

	/* 	Upper right Spearman: Set to zero when below diagonal */

	data corr_temp2 (drop = i);
	set &upperright;
	array corrMatrix {&variablesN} %DO_OVER(variables, PHRASE=? );

	do i=1 to &variablesN;
		if i<= _N_ then corrMatrix{i} = 0;
	end;
	row = _N_;
	%runquit;

	/*	Add the two matrics */

	proc sql;

		create table &dsout as

			select a._NAME_, 
			%DO_OVER(variables, PHRASE=a.? + b.? as ?, BETWEEN=COMMA)
			from
				corr_temp1 a, corr_temp2 b
			where
				a.row = b.row;
	%runquit;

	proc datasets library=work;    
		delete corr_temp1 - corr_temp2;    
	%runquit;

%mend;


/*	Helper macro for p-values: this will set the pvalue for the right variable */

%macro replaceValues (var);
	if updateThis eq "&var" then &var = pValue ;
%mend;

%macro probCorr(dsin=, dsout=, fisher=);

	/*	This macro creates a matrix with p-values */

	/*	Set all values to zero */

	data corr_sign1 (drop = i);
	set &dsin;
	array corrMatrix {&variablesN} %DO_OVER(variables, PHRASE=? );

	do i=1 to &variablesN;
		corrMatrix{i} = 0;
	end;
	row = _N_;
	%runquit;

	proc sql;

		create table corr_sign2 as 
			select a.*, b.var, b.withVar, b.pValue 
			from
				corr_sign1 a, &fisher b
			where 
				a._NAME_ = b.var
			or a._NAME_ = b.WithVar;

	%runquit;

	proc sort data=corr_sign2 ; by row;%runquit;

	data corr_sign3;
	set corr_sign2;

	/*	Which p-value are we going to set */

	if _NAME_ eq Var 	 then updateThis = WithVar;
	if _NAME_ eq WithVar then updateThis = Var;

	/* Select the correct cell and set the p-value */

	%DO_OVER(variables, MACRO=replaceValues);
	%runquit;

	/*	Sort by row for the correct order (and drop row afterwards) */
	proc sql;
		create table &dsout (drop = row) as
		select distinct _NAME_, row, 
		%DO_OVER(variables, PHRASE=sum(?) as ?,  BETWEEN=COMMA)
		from
			corr_sign3
		group by _NAME_
		order by row;
	%runquit;

	/*  Clean up */    

	proc datasets library=work;    
		delete corr_sign1 - corr_sign3;    
	%runquit;

%mend;

%macro correlationMatrix(dsin=, vars=, mCoeff=, mPValues=);

	%ARRAY (variables, VALUES=&vars);

	/* 	coefficients  */

	PROC CORR data=&dsin outp = corr_p outs = corr_s fisher;
	      VAR %DO_OVER(variables);
		   ods output 	
			FisherPearsonCorr   = fisher_p  		
			FisherSpearmanCorr  = fisher_s  ;
	run;

	/*	Keep correlations only, not mean, std and N */

	data corr_p; set corr_p; if _TYPE_ eq "CORR";run;
	data corr_s; set corr_s; if _TYPE_ eq "CORR";run;

	%combineMatrices(lowerleft=corr_p, upperright=corr_s, dsout=&mCoeff);

	/* 	p-values  */

	/*	Construct matrices with p-values */

	%probCorr(dsin=corr_p, dsout=prob_pearson, fisher=fisher_p);
	%probCorr(dsin=corr_p, dsout=prob_spearman, fisher=fisher_s);

	/*	Add matrices */

	%combineMatrices(lowerleft=prob_pearson, upperright=prob_spearman, dsout=&mPValues);

	/*  Clean up */    

	proc datasets library=work;    
		delete corr_p corr_s prob_pearson prob_spearman fisher_p fisher_s;    
	%runquit;
%mend;



/* usage */

/*  Sample set Funda */ 


%let wrds = wrds.wharton.upenn.edu 4016;options comamid = TCP remote=WRDS;
signon username=_prompt_;

rsubmit;
data work.mydata (keep = gvkey fyear roa act_at fincf_at gdwil_at asset_turn);
set comp.funda;
if indfmt='INDL' and datafmt='STD' and popsrc='D' and consol='C' ;
if at > 0;
roa = ni / at;
act_at = act / at;	* current assets scaled by total assets;
fincf_at = fincf / at;	* finance cash flows scaled by total assets;
gdwil_at = GDWL / at;	*goodwill scaled by total assets;
asset_turn = sale/at;
if fyear > 2009; * restrict sample size;
run; 
proc download data=mydata out=sample;run;
endrsubmit;

data sample;
set sample;
if _N_ <= 500;	* 500 obs;
run;

/*  Invoke macro */ 

%correlationMatrix(dsin=work.sample, vars=roa act_at fincf_at gdwil_at asset_turn, mCoeff=corrCoeff, mPValues=corrProb);

