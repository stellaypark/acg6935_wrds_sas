data mycomp2;
set mycomp;
/* make a copy of sale and at */
zsale = sale;
zat = at;
run;
proc sort data=mycomp2; by fyear;run;
PROC STANDARD DATA=mycomp2 MEAN=0 /* STD=1 */ OUT=mycomp3;
  VAR zsale zat;
  by fyear;
RUN;

PROC MEANS DATA=mycomp3;
RUN;
