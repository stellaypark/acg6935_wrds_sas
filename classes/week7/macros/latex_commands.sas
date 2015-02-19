/******************************************************************  

	macros to create latex macro commands

	delT				delete file
	t					arguments: keyword,value,comment
	t1000				as t, but with thousand separator
	tNumber				keyword,value,comment,digits, as t, but specify #digits
	tPercentText1Digit	keyword,value,comment - adds 1 digit and percent sign
	tPercent1Digit		keyword,value,comment
	tC 					comment - add a comment
*/
%macro delT;
	SYSTASK COMMAND  "del &fileLatexCommands";
%mend;

%macro t (keyword,value,comment);
	data _null_;
    FILE  "&fileLatexCommands" DLM='\n' MOD ;   
	%if %length(&comment) > 0 %then %do;
		PUT "%%&comment";
	%end;
	PUT "\newcommand{\&keyword.}{&value.}";
	run ; 
%mend;

%macro t1000(keyword,value,comment);
	data _null_;
    FILE  "&fileLatexCommands" DLM='\n' MOD ;   
	%if %length(&comment) > 0 %then %do;
		PUT "%%&comment";
	%end;
	%let value2= %sysfunc(putn(&value,nlnumi32.0)  );
	PUT "\newcommand{\&keyword.}{&value2.}";
	run ; 
%mend;

%macro tNumber(keyword,value,comment,digits);
	data _null_;
    FILE  "&fileLatexCommands" DLM='\n' MOD ;   
	%if %length(&comment) > 0 %then %do;
		PUT "%%&comment";
	%end;
	%let value2= %sysfunc(putn(&value,8.&digits)  );
	PUT "\newcommand{\&keyword.}{&value2}";
	run ; 
%mend;

%macro tPercentText1Digit(keyword,value,comment);
	data _null_;
    FILE  "&fileLatexCommands" DLM='\n' MOD ;   
	%if %length(&comment) > 0 %then %do;
		PUT "%%&comment";
	%end;
	%let value2= %sysfunc(putn(100*&value,nlnumi32.1)  );
	PUT "\newcommand{\&keyword.}{&value2. percent}";
	run ; 
%mend;

%macro tPercent1Digit(keyword,value,comment);
	data _null_;
    FILE  "&fileLatexCommands" DLM='\n' MOD ;   
	%if %length(&comment) > 0 %then %do;
		PUT "%%&comment";
	%end;
	%let value2= %sysfunc(putn(100*&value,nlnumi32.1)  );
	PUT "\newcommand{\&keyword.}{&value2.\%}";
	run ; 
%mend;

%macro tC (comment);
	data _null_;
    FILE  "&fileLatexCommands" DLM='\n' MOD ;   
	%if %length(&comment) > 0 %then %do;
		PUT;
		PUT "%%&comment";
	%end;
	PUT;
	run ; 
%mend;
