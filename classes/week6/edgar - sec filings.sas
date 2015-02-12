
/*
		- edgar filings, matching
		- fixed effects
		- logistic regression
		- clustering
*/

/*
	Dataset with SEC filings, download link on: http://www.wrds.us/index.php/repository/view/25

	Based on quarterly archives on Edgar, for example: ftp://ftp.sec.gov/edgar/full-index/2014/QTR1/

*/

/* filings dataset, variables:
	coname: company name
	formtype: 10-K, etc
	cik: central index key
	filename: url, prepend with http:\\www.sec.gov\Archives\
	date: filing date
*/

/* get annual reports filed in 2006-*/
proc sql;
	create table annrep as
	select * from edgar.filings
	where formtype IN ("10-K", "10-K405", "10-KSB", "10-KT", "10KSB",  "10KSB40", "10KT405")
	and year(date) > 2005;
quit;

proc sql;
	create table annrep2 as select distinct year(date) as year, formtype, count(*) as numobs from annrep group by year(date), formtype;
quit;

/* inspect 10-K in browser, for example: 
http:\\www.sec.gov\Archives\edgar/data/1050122/0001104659-06-017311.txt

<ACCEPTANCE-DATETIME>20060316153446
ACCESSION NUMBER:		0001104659-06-017311
CONFORMED SUBMISSION TYPE:	10-K
PUBLIC DOCUMENT COUNT:		6
CONFORMED PERIOD OF REPORT:	20051231
FILED AS OF DATE:		20060316
DATE AS OF CHANGE:		20060316

FILER:

	COMPANY DATA:	
		COMPANY CONFORMED NAME:			1 800 CONTACTS INC
		CENTRAL INDEX KEY:			0001050122
		STANDARD INDUSTRIAL CLASSIFICATION:	RETAIL-CATALOG & MAIL-ORDER HOUSES [5961]
		IRS NUMBER:				870571643
		STATE OF INCORPORATION:			DE
		FISCAL YEAR END:			1231

*/

/* key used by edgar is cik (central index key), the archives hold the historic key (not changed if firm changes cik)

*/

/* matching attempt: count #filings for each cik in Funda for the year 2000 */

%let myYear = 2000;

proc sql; create table cik1 as select distinct gvkey, cik from comp.funda where fyear eq &myYear and missing(cik) ne 1; quit;
data cik2; set cik1; cik_num = 1 *cik; run;

proc sql;
	create table cik3 as
	select a.gvkey, a.cik, count(b.date) as numObs 
	from cik2 a left join edgar.filings b
	on a.cik_num eq b.cik and year(b.date) eq &myYear
	group by a.gvkey, a.cik;
quit;

proc freq data=cik3; tables numObs;run;

/*                                                  Cumulative    Cumulative
                   numObs    Frequency     Percent     Frequency      Percent
                        0        1740       15.57          1740        15.57
                        1         173        1.55          1913        17.11
                        2         108        0.97          2021        18.08
                        3          95        0.85          2116        18.93
                        4         325        2.91          2441        21.84
                        5         566        5.06          3007        26.90
                        6         548        4.90          3555        31.80
*/

/* same for 2013 */

%let myYear = 2013;

/* rerun code */

/*
                                                      Cumulative    Cumulative
                   numObs    Frequency     Percent     Frequency      Percent
 
                        0         757        9.67           757         9.67
                        1         159        2.03           916        11.70
                        2          61        0.78           977        12.48
                        3          34        0.43          1011        12.92
                        4          54        0.69          1065        13.61
                        5          56        0.72          1121        14.32
                        6          51        0.65          1172        14.97
*/

/* does cik change in funda? */

proc sql;
	create table cik4 as select fyear, gvkey, count(*) as numCiks 
	from  ( select distinct gvkey, fyear, cik from comp.funda where fyear > 1999)
	group by fyear, gvkey;
quit;
proc freq data=cik4; tables numCiks;run;


/* WRDS SEC Analytics Suite: wcilink_gvkey table, provides gvkey => cik link 
http://wrds-web.wharton.upenn.edu/wrds/tools/variable.cfm?library_id=124
*/
rsubmit;endrsubmit;
%let wrds = wrds.wharton.upenn.edu 4016;options comamid = TCP remote=WRDS;
signon username=_prompt_;
rsubmit;
libname secsuite "/wrds/sec/sasdata";
proc download data=secsuite.wciklink_gvkey out=wciklink_gvkey; run; 
endrsubmit;

/* I usually first try to get a match with the historic cik, and if there is no
match, try the ones provided in the linktable */
