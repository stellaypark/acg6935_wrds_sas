/*
	t1_ttest and tableByGroup create a table with descriptive stats
	for each group and statistical tests for difference in means/medians

	expects &exportDir to be set and uses %myExport
*/

%macro t1_ttest(dset=, outp=, vars=, by=);

* by: class variable (indicator);
	ods exclude all;
PROC TTEST H0=0 DATA=&dset ;
   CLASS  &by ;
   VAR &vars;
   ods output TTests =work.t1_ttest_ttests Statistics =work.t1_ttest_stats  ;
RUN;

* create table with Variable, mean, Probt, tValue;
proc sql;
	create table &outp as
	select a.Variable, a.tValue * -1 as tValue, a.Probt, b.Mean * -1 as Mean
	from
		work.t1_ttest_ttests a,
		work.t1_ttest_stats b
	where
		a.Variable = b.Variable
	and a.Method = "Satterthwaite"
	and b.class = "Diff (1-2)"	;
quit;

* clean up;
proc datasets library=work;
   delete t1_ttest_ttests t1_ttest_stats;
run;
 	ods exclude none;
%mend;

%macro tableByGroup(dsin=, vars=, byvar=, export=);

	proc sort data =&dsin; by &byvar;%runquit;

	proc means data=&dsin noprint;
	OUTPUT OUT=_table3 mean= median= STDDEV= N=/autoname;
	var &vars;
	by &byvar ;
	%runquit;

	/*	Difference in means */

	%t1_ttest(dset=&dsin, outp=_table3_test1, vars=&vars, by=&byvar );

	data _table3_test1;
	set _table3_test1;
	format tValue 8.2;
	format Probt 8.3;
	format Mean 8.3;
	%runquit;

	/*	Difference in medians: Wilcoxon-Mann-Whitney test */
	ods exclude all;
	proc npar1way data = &dsin wilcoxon;
	  class &byvar;
	  var &vars;
	  ods output WilcoxonTest = _table3_test2  ;
	%runquit;

	data _table3_test2 (keep = Variable pVal);
	set _table3_test2;
	if Name1 eq "P2_WIL";	/* 2-sided p-value;*/
	pVal = nValue1;
	format pVal 8.3;
	%runquit;
 	ods exclude none;	

	%myExport(dset=_table3, file=&exportDir\&export._means.csv);
	%myExport(dset=_table3_test1, file=&exportDir\&export._test1.csv);
	%myExport(dset=_table3_test2, file=&exportDir\&export._test2.csv);

%mend;


