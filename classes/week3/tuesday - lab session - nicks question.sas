Nick's question on merging compustat - crsp

rsubmit;
proc sql;
    create table mp as
    select gvkey, conm, datadate, fyear, csho, gp, at, prcc_f, gp/at as GPtoAssets, ACT,
    CHECH, LCT, TXP, DP, csho*prcc_f as MVE, CEQ, DLC, floor(sich/1000) as onedig_ind
    from comp.funda
    where 1989 le fyear le 2015 and not missing(gvkey)
    and indfmt='INDL' and datafmt='STD' and popsrc='D' and consol='C' ;
quit;
proc download data=mp out=m.Data;run;
endrsubmit; *305,609 obs;

data m.Data;
    set m.Data;
    if onedig_ind=6 then delete;
run; *269,615 obs;

proc sql;
    create table m.Data1 as
    select a.*, b.lpermno
    from m.data as a left join test.crsp_compLink as b
    on a.gvkey=b.gvkey and b.linkdt le a.datadate le b.linkenddt;
quit; *271,294 obs;

data m.data2;
    set m.data1;
    if missing(lpermno) then delete;
run; *167,768 obs;


rsubmit;
proc sql;
    create table ba as
    select gvkey, conm, datadate, fyear, csho, gp, at, prcc_f, gp/at as GPtoAssets, ACT,
    CHECH, LCT, TXP, DP, csho*prcc_f as MVE, CEQ, DLC, floor(sich/1000) as onedig_ind
    from comp.funda
    where 1989 le fyear le 2015 and not missing(gvkey)
    and indfmt='INDL' and datafmt='STD' and popsrc='D' and consol='C' 
	having onedig_ind ne 6;
quit;

PROC SQL; 
  create table ba2 as 
  select a.*, b.lpermno as permno
  from ba a left join crsp.ccmxpf_linktable b 
    on a.gvkey eq b.gvkey 
    and b.lpermno ne . 
    and b.linktype in ("LC" "LN" "LU" "LX" "LD" "LS") 
    and b.linkprim IN ("C", "P")  
    and ((a.datadate >= b.LINKDT) or b.LINKDT eq .B) and  
       ((a.datadate <= b.LINKENDDT) or b.LINKENDDT eq .E)   ; 
  quit; 
endrsubmit; 
