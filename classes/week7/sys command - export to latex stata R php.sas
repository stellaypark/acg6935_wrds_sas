/* X command and system command: commands issued as if on the 'command line' */

%let moYear =2017_Feb;
%let topDir =C:\temp\someproject\; 

/* create directory */
%put creating directory: &topDir.&moYear. ;
systask command "mkdir &topDir.&moYear." ;

/* library assignment */
libname newLib "&topDir.&moYear";

/* export to directory relative to file that is currently loaded 
	details, see http://www2.sas.com/proceedings/forum2008/023-2008.pdf 
*/

%macro grabpathname;
 %sysget(SAS_EXECFILEPATH)
%mend grabpathname;
%macro grabpath;
 %qsubstr(%sysget(SAS_EXECFILEPATH), 1, %length(%sysget(SAS_EXECFILEPATH))-%length(%sysget(SAS_EXECFILEname))  )
%mend grabpath;

%let myDir = %grabpath;
%let exportDir = &myDir.sas_export;
%put file: %grabpathname;
%put directory: %grabpath;

/* create sas_export directory */
systask command "mkdir &exportDir" ;

/* create some dataset */
data a_funda (keep = gvkey fyear datadate key sich ceq loss mtb roa sale);
set comp.funda;
where fyear > 2010;
if indfmt='INDL' and datafmt='STD' and popsrc='D' and consol='C' ;
key = gvkey || fyear;
/* drop missings */
if cmiss (of ceq ni at prcc_f csho sale) eq 0;
/* positive equity firms only*/
if ceq > 0;
loss = (ni < 0);
mtb = (prcc_f * csho) / ceq;
roa = ni /at;
run;

/* export in stat format to exportdir */
proc export data=a_funda outfile="&exportDir.\myFunda.dta" replace; run;

/* change current directory to working directory (this is where stata will push log)*/
X CD &myDir; 

/* tell stata to run do file 
	note: stata do file uses 'eststo' and 'esttab' which may not be installed by default
*/
systask command "'C:\Program Files (x86)\Stata13\Stata-64.exe' -e do &myDir.\example_do_file.do" ;


/* option -b will pop up window with location log file
http://www.stata.com/support/faqs/mac/advanced-topics/
*/
systask command "'C:\Program Files (x86)\Stata13\Stata-64.exe' -b do &myDir.\example_do_file.do" ;

/* create latex macros for the number of obs and unique firms

	In latex you define constants as follows:

	\newcommand{\dNumFirmYears}{40,706}
	\newcommand{\dUniqueFirms}{6,164}
	\newcommand{\dSampleStart}{2000}
	\newcommand{\dSampleEnd}{2013}

	Which you can then refer to in the text.

	for example
	"Our sample consists of \dNumFirmYears{} for 
	\dUniqueFirms{} unique firms over the period \dSampleStart{}-\dSampleEnd{}."

	compiles as
	"Our sample consists of 40,706 for 6,164 unique firms over the period 2000-2013."

	Latex can include external files that define latex macro variables; 
	so, after generating/updating our sample in SAS, we can write such a file.
*/

%let baseDataset = a_funda;
%let fileLatexCommands = &myDir.latex_commands.tex;

/* include helper macros */
%include "&myDir.macros/latex_commands.sas";

/****************************************************************** create Latex commands */

/* delete old command file; (in case it exists)*/
%delt;

/* write some comment to the file */
%tC(Info on firms in baseDataset &baseDataset);
/* number of observations */
%tC(Number of observations in sample);
proc sql; select distinct count(*) as numObs into :numObs1 from (select distinct key from &baseDataset); quit;
/* invoke t1000 as follows: %t1000(keyword,value,comment)*/
%t1000(dNumFirmYears,&numObs1,Number of firmyears);

/* unique firms */
%tC(Unique firms);
proc sql; select distinct count(*) as numFirms into :numFirms  from (select distinct gvkey from &baseDataset ); quit;
%t1000(dUniqueFirms,&numFirms,Number of firms);

/* sample period */
%tC(Sample period);
proc sql; select min(fyear), max(fyear) into :minYr, :maxYr  from &baseDataset ; quit;
/* invoke as: %tNumber(keyword,value,comment,digits) */
%tNumber(dSampleStart,&minYr,Year sample period start,0);
%tNumber(dSampleEnd,&maxYr,Year sample period end,0);
