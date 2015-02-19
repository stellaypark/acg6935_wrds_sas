<?php header("Content-Type: text/plain"); 
	
	$funda 		= $_POST["funda"];
	$year1 		= isset($_POST["year1"]) ? $_POST["year1"] : 2000;
	$year2 		= isset($_POST["year2"]) ? $_POST["year2"] : 2014;
	$fundq 		= ($_POST["fundq"] =="") ? null : $_POST["fundq"] . " fyearq datadate fqtr" ; // add 'fyearq datadate fqtr' to fundq variables
	
	if ($fundq) {
		$fundqvars 	= explode(" ", $fundq);
		$fundqvars  = array_unique($fundqvars, SORT_REGULAR);
	}
	$dsout 		= $_POST["dsout"] ?: 'a_funda';
	$permno 	= ($_POST["permno"] === "true") ? 1 : 0;
	$cusip 		= ($_POST["cusip"] === "true") ? 1 : 0;
	$ibesticker = ($_POST["ibesticker"] === "true") ? 1 : 0;
	$rsubmit 	= ($_POST["rsubmit"] === "true") ? 1 : 0;
	
	//print_r($_POST);
	
?>
<?php if($rsubmit) : ?>
/* sign on to wrds */
%let wrds = wrds.wharton.upenn.edu 4016;options comamid = TCP remote=WRDS;
signon username=_prompt_;
rsubmit;

<?php endif; ?>
<?php $dset = 1; ?>
/* get funda variables */
data _ds1 <?php if ($fundq) echo '(rename=(datadate=datadate_funda)' ?> keep = gvkey fyear datadate <?php echo $funda; ?>);
set comp.funda;
where <?php echo $year1; ?> <= fyear <= <?php echo $year2; ?>;
if indfmt='INDL' and datafmt='STD' and popsrc='D' and consol='C' ;
run;
<?php if($fundq) : ?>

/* match with comp.fundq */
proc sql;
	create table _ds<?php echo $dset+1; ?> as 
	select a.*, <?php
	// loop through variables in fundq
	foreach ($fundqvars as $key => $value) { 
		echo "b.$value";
		/* comma between elements, not after last element */
    	if ($key !== count($fundqvars)-1) echo ', ';    	
	}
	?> 
	from _ds1 a, comp.fundq b
	where b.indfmt='INDL' and b.datafmt='STD' and b.popsrc='D' and b.consol='C' and
	a.gvkey = b.gvkey and a.fyear = b.fyearq;
quit;
<?php $dset++ ; ?>
<?php endif; ?>
<?php if($permno || $cusip ) : ?>

/* Permno as of datadate*/
proc sql; 
  create table _ds<?php echo $dset+1; ?> as 
  select a.*, b.lpermno as permno
  from _ds<?php echo $dset; ?> a left join crsp.ccmxpf_linktable b 
    on a.gvkey eq b.gvkey 
    and b.lpermno ne . 
    and b.linktype in ("LC" "LN" "LU" "LX" "LD" "LS") 
    and b.linkprim IN ("C", "P")  
    and ((a.datadate >= b.LINKDT) or b.LINKDT eq .B) and  
       ((a.datadate <= b.LINKENDDT) or b.LINKENDDT eq .E)   ; 
quit; 
<?php $dset++ ; ?>
<?php endif; ?>
<?php if($cusip) : ?>

/* retrieve historic cusip */
proc sql;
  create table _ds<?php echo $dset+1; ?> as
  select a.*, b.ncusip
  from _ds<?php echo $dset; ?> a, crsp.dsenames b
  where 
        a.permno = b.PERMNO
    and b.namedt <= a.datadate <= b.nameendt
    and b.ncusip ne "";
  quit;
<?php $dset++; ?>
<?php endif; ?>
<?php if($ibesticker ) : ?>

/* get ibes ticker */
proc sql;
  create table _ds<?php echo $dset+1; ?> as
  select distinct a.*, b.ticker as ibes_ticker
  from <?php echo $dset; ?> a left join ibes.idsum b
  on 
        a.NCUSIP = b.CUSIP
    and a.datadate > b.SDATES ;
quit;
<?php $dset++; ?>
<?php endif; ?>

/* force unique records */
<?php if ($fundq) : ?>
proc sort data=_ds<?php echo $dset; ?> out=<?php echo $dsout; ?> nodupkey; by gvkey fyearq fqtr;run;
<?php else : ?>
proc sort data=_ds<?php echo $dset; ?> out=<?php echo $dsout; ?> nodupkey; by gvkey fyear;run;
<?php endif; ?>

<?php if($rsubmit ) : ?>
/* download result */
proc download data=_ds<?php echo $dset; ?> out=<?php echo $dsout; ?>;run;

<?php endif; ?>
/* clean up */
proc datasets; delete _ds1-_ds<?php echo $dset; ?>; quit;

<?php if($rsubmit ) : ?>
endrsubmit;
<?php endif; ?>