
/* turn on macro debugging */
filename mprint 'C:\temp\tempSAScode.SAS';
options mprint mfile;

%macro coffee;
	%put If this is tea, then I want coffee.;
%mend;

%macro tea;
	%put If this is coffee, I want tea.;
%mend;

/* notice the order of output -- %&mydrink and %&otherdrink are executed first */
%let mydrink = tea;
%let otherdrink = coffee;
%put Do you want tea or coffee? %&mydrink %&otherdrink;

%tea

rsubmit;
data MSIX (keep = date ret);
set CRSP.msf;
/* this won't work: if 20060131 <= caldt <= 20091231;*/
if '31jan2006'd <= date <= '31dec2009'd;
run;
proc download data=MSIX out=MSIX;run;
endrsubmit;

data msix2;
set msix;
copycaldt = caldt;
/* the last day of the previous month */
prevmonth = intnx('month', caldt, -1, 'e'); 
format copycaldt monyy.;
format prevmonth date9.;
run;

proc sql;
	merging 2 tables, and the date of a.somedate and b.otherdate need to be in the same mont (and same year)

	from table1 a, table2 b
	where year(a.somedate) eq year(b.otherdate) and month(a.somedate) eq month (b.otherdate);

quit;


