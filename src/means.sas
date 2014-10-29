/*!

    Prints summary stats of continuous variables.

    * @author Luke W Johnston
    * @created 2014-10-14

    */

/**

    Prints summary statistics such as means and median for continuous
    variables.
    <p>

    This macro outputs summary statistics from continuous
    variables. Means and standard deviations are output as a single
    column, as well as the median and interquartile range, for ease in
    putting into tables. It can be univariate or divariate.
    <p>

    <b>Examples:</b><br>
    <code>%means(Height Weight Age, dsn=sashelp.class, where=Sex eq 'F');</code>

    * @param vars The continuous variables to summarize. It is a
    positional argument, and is placed first
    
    * @param dsn The dataset that contains the variables
    
    * @param by Summarizes the <code>vars</code> according to a discrete,
    <b>sorted</b>, variable
    
    * @param class Similar to <code>by</code>, except it does <b>not</b> need to be
    sorted

    * @param where A condition to subset the data by

    * @param outds The output dataset name

    * @return Prints the summary statistics.

    */
%macro means(vars, dsn=&ds, by=, class=, where=, outds=_NULL_);

    * Suppress output to lst file or Results tab;
    ods listing close;
    proc means data=&dsn stackods n mean 
        stddev min max median Q1 Q3 maxdec=3;
        var &vars;
        class &class;
        by &by;
        where &where;

        * Output the results;
        ods output summary=&outds;
    run;
    ods listing;

    data &outds (drop=Mean StdDev Median Q1 Q3);
        set &outds;

        * Create two new variables which concat. ;
        * together other variables.  The || means concatenate;
        MeanSD = round(Mean, 0.01)||' ('||
            strip(round(StdDev, 0.01))||')';

        MedianIQR = round(Median, 0.01)||' ('||
            strip(round(Q1, 0.01))||'-'||
            strip(round(Q3, 0.01))||')';
    run;

    proc print;
    run;
    %mend means;
