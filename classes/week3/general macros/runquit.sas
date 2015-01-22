%macro runquit;
; run; quit;
%if &syserr. ne 0 %then %do;
%abort cancel ;
%end;
%mend runquit;
