use "E:\teaching\2017_wrds\acg6935_wrds_sas\classes\week7\sas_export\myFunda.dta", clear

eststo: logit loss sale mtb
eststo: logit loss sale mtb ceq
esttab using "E:\teaching\2017_wrds\acg6935_wrds_sas\classes\week7\stata_out.csv" , replace label 
