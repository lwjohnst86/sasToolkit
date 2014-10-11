/*!

    Print dataset variable contents.

    * @author Luke W Johnston
    * @created 2014-10-08

    */

/**

    Print the variable contents of one or more datasets.
    <p>

    This macro loops through multiple (or just one) dataset and prints
    off all the variable names (the header row) of each dataset.  It also
    prints what type the variable is, either a character or a numeric.
    <p>

    <b>Examples:</b><br>
    ** Two SAS help datasets;<br>
    %contents(datasets=class heart, lib=sashelp);<br>

    * @param datasets One or more datasets that you want to see the
    contents within.  It is a positional macro variable, so requires that
    the variable be given first

    * @param lib The libname.  The <code>work<code> libname is the default
    environment SAS uses.  Other examples may be <code>sashelp<code>; you can also
    create your own libname if you have a SAS dataset (which I don't
    recommend having)

    * @param outds Specify an output dataset name to output the
    results of the macro
    
    * @return Prints all the variables and their formats within the
    specified datasets.

    */
%macro contents(datasets, lib=work, outds=tmp);

    * Count the number of datasets provided and start the loop;
    %do i = 1 %to %sysfunc(countw(&datasets));

        * Extract the i-th dataset from the list;
        %let dsn = %scan(&datasets, &i);

        * Outputting to the log file;
        %put Checking contents of the dataset &i.;
        
        * Suppress printing to the listings;
        ods listing close;
        proc contents order=casecollate data=&lib..&dsn;

            * Output the dataset;
            ods output Variables=&outds (keep=Num Variable Type Format);
        run;
        ods listing;

        * Print the dataset;
        proc print data=&outds;
        run;
        %end;

    %mend contents;
