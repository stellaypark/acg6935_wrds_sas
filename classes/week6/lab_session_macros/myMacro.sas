
%macro doMyMacro(dsout=);

proc sql;
    create table q1_1data as
    select a.gvkey, a.datadate, a.fyearq, a.fqtr, a.fyr, a.saleq, a.rdq, b.sich
    from comp.fundq a left join comp.funda b
    on a.gvkey = b.gvkey and year(a.datadate)=year(b.datadate)
    having  a.fyr = 12
            and 2011 <= a.fyearq <= 2013
            and a.saleq ne .
            and b.sich ne . ;
    quit;
/* Delete dups before calculating median */
proc sort data =q1_1data nodupkey; by gvkey fyearq fqtr; run;

/* Calculate the Number of firms in industries and Ind. ratios */
proc sql;
    create table &dsout as
    select *,
    count(*) as Numfirm label = "Industry-Quarter Number of Firms",
    median(saleq) as MedInd label="Industry-Quarter Median Sales" format=comma12.2,
    case when saleq > calculated MedInd then "Above Median" else "Below Median" end as Flag
    from q1_1data
    group by sich, fyearq, fqtr
    having calculated numfirm > 10;
    quit;

%mend;
