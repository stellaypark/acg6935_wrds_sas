/*

	macro that appends Q4 earnings annoucement date ('earn_ann_dt') to input dataset 
	Earnings announcement date can be taken from Fundq or IBES (depending on 'source' argument)

	dsin: dataset to get earnings announcement date from
		- holds: gvkey, fyear, datadate, ibes_ticker (if source is IBES)

	dsout: dataset to generate

	source: fundq (default) or ibes
		- fundq retrieves rdq from fundq
		- ibes retrieves date from ibes actu_epsus

	invoke as:
	%earn_ann_date(dsin=mydata, dsout=myresult, source=IBES);
*/

%macro earn_ann_date(dsin=, dsout=, varname=anndate, source=fundq);

%if &source eq fundq %then %do;

	proc sql;	
		create table &dsout as 
		select a.*, b.rdq as &varname format date9.
		from &dsin a left join comp.fundq b
		on a.gvkey eq b.gvkey 
		/* matching datadate will only be true for q4 */
		and a.datadate eq b.datadate;
	quit;

%end;

%else %do;
	proc sql;	
		create table &dsout as 
		select a.*, b.anndats as &varname format date9.
		from &dsin a left join ibes.actu_epsus b
		on a.ibes_ticker = b.ticker 
		and b.MEASURE="EPS"
    	and b.PDICITY="QTR"
		/* IBES period end date 'close to' end of fiscal year */		
		and a.datadate -5 <= b.PENDS <= a.datadate +5;
	quit;
%end;

/* force unique obs */
proc sort data = &dsout nodupkey; by gvkey fyear;run;
%mend;

