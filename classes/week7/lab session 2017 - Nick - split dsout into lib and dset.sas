
data test;
text = "c1.funda";
delims = ' ,.!';                 /* delimiters: space, comma, period, ... */
numWords = countw(text, delims);  /* for each line of text, how many words? */
do i = 1 to numWords;            /* split text into words */
   word = scan(text, i, delims);
   output;
end;
run;

data test;
text = "c1.funda";
libname = scan(text, 1, '.');
dset = scan(text, 2, '.');
run;

%let dsout = c1.funda;
%let libname = %scan(&dsout, 1, ".");
%let dsname = %scan(&dsout, 2, ".");
%put the library is &libname and the dataset is &dsname;
libname &libname "~";

