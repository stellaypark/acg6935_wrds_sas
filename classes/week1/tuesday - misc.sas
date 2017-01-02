
/* using output to create observations */
data mytest;
do x = 0 to 2000;
	y = x;
	output;
end;

format x date9.;run;


/* approximate randomization - pseudo test*/

/* generate N samples with random event dates */
data mydata (drop = i);
/* repeat times */
do sample = 1 to 10 ;
	/* generage event dates */
	do i = 1 to 5 ;			
		/* generate a random date between 1/1/2000 and 31/12/2010 
			- floor rounds a number down (dates are integers)
			- ranuni generates random number, 6675309 is a random seed (can be any other number)
			- difference in dates (1/1/2010 vs 1/1/2000) is #days in 10-year period
		*/
	   	eventdate = '01jan2000'd + floor(ranuni(8675309)*( '01jan2010'd - '01jan2000'd ) );
		output;
	end;
end; 
format eventdate date9.;
run;


