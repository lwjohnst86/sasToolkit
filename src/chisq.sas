/*!

    Chi-Square Statistical Analysis.
    
    * @author Luke Johnston
    * @created 2014-09-29

    */

/**
    
    Runs a Chi-Square analysis.
    <p>

    Chi square is a simple statistical test to calculate differences
    between proportions in a 2x2 and other contingency/frequency
    tables.  This macro simply runs a chi-square test and outputs the
    frequency and probability of difference between groups.
    <p>

    <b>Examples:</b> <br>
    <code> ** Using the SAS bone marrow transplant dataset; <br>
    %chisq(Group*Status, sashelp.bmt, where=T lt 2000, tests=chisq or, <br>
    testOpt=relrisk, outChi=chi); </code>
    
    * @param vars Contains the variables to be analyzed. The argument
    is positional --- the variables must be specified first before other
    arguments

    * @param dsn Dataset name which contains the variables. The
    argument is positional --- the variable must be specified second
    
    * @param tests Specify which tests to run

    * @param outFreq Output dataset which contains the frequencies
    
    * @param outChi Output dataset which contains the chi-square
    statistics
    
    * @param order The order in which to display the variables in the
    <code>outFreq</code> dataset
    
    * @param testOpt Options to pass to the tables <code>chisq</code> command
    
    * @param where To subset the data before analyzing the variables

    * @param by To run the analysis separately by categories of the by
    variable
    
    * @return Prints the frequencies and chi-square statistic results
    by default. Will output datasets if specified.
    
    */
%macro chisq(vars, dsn, tests=chisq, outFreq=NULL, outChi=tmp,
    order=freq, testOpt=, where=, by=);

    * Close output to listing file/log;
    ods listing close;
    proc freq data=&dsn order=&order;
        tables &vars / chisq &testOpt;
        exact &tests ;
        where &where;
        by &by;
        * Output results into a dataset;
        ods output CrossTabFreqs=&outFreq ChiSq=&outChi;
    run;
    ods listing;

    * Remove some extraneous variables;
    data &outFreq;
        set &outFreq (drop=_TYPE_ _TABLE_);
    run;

    * Print the results;
    proc print data=&outFreq;
    run;
    proc print data=&outChi;
    run;
    %mend chisq;
