
/*
comments from word doc

Compute industry-year sales, so for each unique year-industry you want to know the sum of sales (several firms in each industry – so, it will add those firms’ sales)
Data a_start;
Set a_start;
Indyear = SIC || “_” || fyear; * concatenate industry and year ;
Run;
Data b_ind (keep = indyear indsales sic fyear);
Set a_start;
By indyear;
Retain indsales 0;
Indsales = indsales + sale; 
If last.indyear then output;
run;

*/
rsubmit;

data myTable (keep = gvkey fyear datadate sale sich);
set comp.funda;
/* require fyear to be within 2010-2013 */
if 2010 <=fyear <= 2013;
/* prevent double records */
if indfmt='INDL' and datafmt='STD' and popsrc='D' and consol='C' ;
run;
proc download data=myTable out=myCompTable;run;
endrsubmit;

data myCompTable;
set myCompTable;
indyear = sich || "_" || fyear;run;

proc sort data = myCompTable; by indyear;run;

/* compute industry-year sales */
data b_indsales;
set myCompTable;
retain indsales ;
by indyear;
if first.indyear then indsales = 0; /* set for each new ind-year to 0*/
if sale ne .;
if sich ne .;
indsales = indsales + sale;
* if last.indyear then output;
run;

/* get indsales total in each of the other ones */

/* dirty way 
	descending sort on indsales for each industry - so that total industry
sales is in the first record -- we will use 'retain' to get it to the other rows

*/
proc sort data = b_indsales; by indyear descending indsales;run;

data c_indtotal;
set b_indsales;
retain mytotal;
by indyear;
if first.indyear then mytotal = indsales;
run;

/* more beautiful way: compute industry sales seperately and append it */

/* compute industry-year sales */
data d_indsales (keep = indyear indsales sich fyear);
set myCompTable;
retain indsales ;
by indyear;
if first.indyear then indsales = 0; /* set for each new ind-year to 0*/
if sale ne .;
if sich ne .;
indsales = indsales + sale;
if last.indyear then output;
run;
proc sort data = d_indsales;run;

/* in summary:

	we have: myCompTable with gvkey, fyear, sich, indyear (=sich + fyear)

	we have: d_indsales with indyear and indsales

	we want: myCompTable with indsales added

*/
proc sql;

	create table e_firmInd as
		select a.*, b.indsales
		from
			myCompTable a, d_indsales b
		where
			a.indyear = b.indyear;

quit;
