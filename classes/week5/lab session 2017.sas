
/* relevant data for reported earnings
	- earnings announcement date
	- actual earnings

	Compustat Fundq holds 'rdq' (reporting date), 
	cshoq (#shares oustanding), and net income (niq)

	Nevertheless, IBES data is preferred:
	- Actual earnings are 'street' earnings, more in line with how
	analyst forecast earnings
	- Announcement date in IBES has less error
	- There is also announcement time
		- some papers add 1 day if earnings are announced after hours 

	Another data source: wallstreet horizon, see footnote 12 of deHaan et al 
	(http://www.wallstreethorizon.com/upload/DST_a2014.10.21.pdf)
*/

/* take a look at actuals for DELL: ACTU_EPSUS */
proc sql;
  create table g_actuals as
  select *
  from ibes.ACTU_EPSUS  b
  where ticker eq "DELL" and year(PENDS) >= 2010;
quit;

 
/* analyst detail: DETU_EPSUS */

proc sql;
  create table h_details as
  select *
  from ibes.DETU_EPSUS  b
  where ticker eq "DELL" and year(FPEDATS) eq 2010;
quit;

proc sort data=h_details; by ANALYS FPEDATS ANNDATS ;run;

data i_021096;
set h_details;
if analys eq "021096";
run;

/* notice how FPI 'counts' down from 3, 2, 1 for annual forcasts and
   from O, N, 9, ... to 6 for quarterly forecasts */

data j_021096_ann (keep = oftic estimator analys fpi measure value fpedats revdats anndats);
set h_details;
if FPI IN ("3", "2", "1");
if estimator eq 11;
run;


/*
	Some comments made by Marcus on IBES

•         The estimator is meant to represent a brokerage firm.
•         Yes, the ACTDATS is the time that it’s meant to be “good” from. It’s there for every forecast – ACTTIMS is more sparse. I’ve never used ACTTIMS as I haven’t tried to go interday.
•         I haven’t really used the REVDATS variable (especially in the EPS file, sometimes in the Recommendations file I’ve seen it potentially used as the assumption is a recommendation is “good” for 6/9/12 months after a certain date). It’s a “review” date instead of “revision” date so conceptually is more-or-less when IBES or the analysts “reviewed” and confirmed the existing forecast (although this might be different from an external “confirming” forecast being issued by the analyst). Recommendations rarely change so maybe IBES or the analyst checked in at that time to make sure the initial rec is still valid. EPS change so much though that the analyst usually just issues a new one (or some filter is used based on ACTDATS & ANNDATS to exclude “stale” forecasts). A filter that ACTDATS<ANNDATS is usually used to make sure the forecast isn’t issued on the same day or after the announcement date (sometimes people will use 1-3 days before).
•         A confirming forecast would be a value that doesn’t change for a ticker-analyst-estimator-fpedats-fpi (within the unadjusted file – adjusted it might change because of a split). But IBES does a better job of picking up “changes” than confirmations. I know if the recommendation file with the paid-for research paper (albeit for smaller firms), I had many more reiterations of recommendations from actual analyst reports than IBES had in their file. 
•         You’d need the files that David mentioned (stopped, excluded) and that will get you close. Really, replicating the monthly summary file from the details exactly is probably not worth the effort or hassle. If you want an easy summary, use the summary file. If you want a little more control, use the details file (control by filter on only using those issued within 90/180/365 days of the anndats). The reason it’s not worth the hassle is that everything is just a “proxy” for investor expectations. IBES is missing some big brokerages that don’t allow them but these would be in the “true” public consensus, all those filters for “stale” forecasts (e.g. 90/180/365) will all slightly change the consensus, using the mean/median forecast will change the consensus. The differences across these design choices are all much bigger than any “error” from trying to replicate the summary file from the details. 
•         One thing to consider when using the “unadjusted” files is that you have to “adjust” them to all be consistent based on the forecast period under consideration – e.g. imagine 20 forecasts throughout the year at different dates but for the same Dec.31 earnings, they’ll be 20 actdats, 1 fpedats, and 1 anndats all different. If there is no split in here then that’s ok, but if a split happens somewhere between the first actdats and the anndats, then these “unadjusted” estimates will be messed up as they won’t align with the actual value at the anndats. So you have to “adjust” the unadjusted to be consistent within each ticker-fpedats combo. Then depending on the variables, you have to make sure the price deflator you might use if also consistent with however you adjusted these unadjusted (e.g. often accuracy is deflated by beginning of the period price but that may not be ok if a split happened between the beginning of the period and reported earnings. 


*/


/* macro arguments */

%macro myMacroTwo(x=, y=);
%put macro argument: &x and &y;
%mend;
/* this is identical */
%myMacroTwo(x=5, y=7);
%myMacroTwo(y=7, x=5);

%macro myMacroTwo(x, y);
%put macro argument: &x and &y;
%mend;

%myMacroTwo(5, 7);
/* not identical */
%myMacroTwo(x=7, y=5);
%myMacroTwo(7, 5);

/* this actually works (y is set to 5, x to 7) */
%myMacroTwo(y=5, x=7);


/* a little help on q1 - how would you write specific code without a macro/do_over */


%let wrds = wrds.wharton.upenn.edu 4016;options comamid = TCP remote=WRDS;
signon username=_prompt_;

rsubmit;
data myComp (keep = gvkey fyear datadate sich at sale ceq );
set comp.funda;
/* require fyear to be within 2001-2015 */
if 2014 <=fyear <= 2015;
/* prevent double records */
if indfmt='INDL' and datafmt='STD' and popsrc='D' and consol='C' ;
run;
proc download data=myComp out=mydata;run;
endrsubmit;

* assume you have a dataset work.mydata that has at, sale, ceq and you want to keep the variable that 
has the largest value;
data mydata;
set mydata;
/* how can you create a variable that holds the largest value in: at, sale, ceq */
maxvar = -1000000 ;
/* assuming at is the largest variable */
if at > maxvar then do (maxvar = at; maxvarname="at"; end;/* then this will be true, and maxvar will be set to at */
if sale > maxvar then maxvar = sale; /* then this will be false */
if ceq > maxvar then maxvar = ceq; /* then this will be false */
/* in a do_over phrase, I am repeating "if ? > maxvar then maxvar = ? ;" */

/* we also want to set maxvarname = "at", "sale", etc */
/* remember cmiss */
missings = cmiss (of at sale ceq); /* missings will be 0, 1, 2, etc depending on how many are missing */
/* cheating (but not really)*/
maxvar = max (of at sale ceq);
run;


filename m1 url 'http://www.wrds.us/macros/array_functions.sas';
%include m1;

/* turn on macro debugging */
filename mprint 'C:\temp\tempSAScode.SAS';
options mprint mfile;

/* do over version */
data mydata2;
set mydata;
length maxvarname $ 4;
maxvar = -1000000 ;
%do_over(values=at sale ceq, phrase=if ? > maxvar then do; maxvar = ? ; maxvarname="?"; end;);
run;


 /* a little help on q2 */

proc datasets lib = comp; contents data=funda; quit;run; 

/* Retrieve variables in Funda using rsubmit*/
rsubmit;endrsubmit;
%let wrds = wrds.wharton.upenn.edu 4016;options comamid = TCP remote=WRDS;
signon username=_prompt_;

rsubmit;
ods listing close; 
ods output variables  = varsFunda; 
proc datasets lib = comp; contents data=funda; quit;run; 
ods output close; 
ods listing; 

/* keep relevant variables (excluding firm name, gvkey, fyear, etc)*/
data varsFunda_short ;
set  varsFunda;
if 37 <= Num <= 937;
run;

proc download  data=varsFunda out=varsFunda;run;
proc download  data=varsFunda_short out=varsFunda_short;run;
endrsubmit;

proc sort data=varsFunda ; by num;run;

