/*!

    Correlation coefficient statistics.

    * @author Luke W. Johnston
    * @created 2014-10-26

    */

/**

    Compute correlation coefficients.
    <p>

    Runs any type of correlation coefficients on either continuous or
    discrete variables.  You can specify to use either Spearman, Pearson,
    Tau, and others for calculating the coefficients.  Partial
    correlations, which are adjusted for other variables, can also be
    computed.
    <p>

    <b>Examples:</b><br>
    <code>%correlation(dsn=sashelp.class, topvar=Height, sidevar=Weight,
    coeff_test=Pearson);</code>

    * @param dsn The dataset with the variables.  The macro argument
    is positional and needs to be specified first
    
    * @param topvar The variables on the top of the output (the header
    row; those that make up the <b>columns</b>).  This macro argument is
    positional and needs to be specified second.

    * @param sidevar The variables on the side of the output
    (generally the first column; those that make up the <b>rows</b>).  This
    variable is optional.  If not specified, the correlations form a
    matrix.

    * @param covar Variables to adjust for

    * @param where A condition to subset the analysis by (for example,
    <code>where=Sex eq 'F'</code>)

    * @param outds The output dataset

    * @param coeff_test The correlation statistical test to run
    (<code>Spearman</code>, <code>Pearson</code>, <code>Tau</code>, etc.)

    * @return Prints the correlation coefficients.  The results are
    not sent to the output dataset by default.

    */
%macro correlation(dsn, topvar, sidevar=, covar=, where=,
        outds=_NULL_, coeff_test=Spearman);

    * Change the partial variable so that the proper dataset is output;
    %if &covar = %then %let partial = ;
    %else %let partial = Partial;

    * Close output to the listings;
    ods listing close;
    proc corr data=&dsn &coeff_test;
        * indicate coefficient test to use (default;
        * is Spearman rank correlation);
        partial &covar; * variables to adjust for;

        * variables in the header row;
        var &topvar; 

        * variables on the side of the output, ie the column;
        with &sidevar; 

        where &where;
        ods output &partial.&coeff_test.Corr = &outds;
    run;

    * Open to listings;
    ods listing;

    * Combine columns so that significance is included as an ;
    * asterisk;
    data &outds;
        set &outds;
        %for(i, in=(&topvar), do=%nrstr(
            length t&i. $ 22;
        &i. = round(&i, 0.01);
        if &i. = 1 then;
        else if P&i. < 0.001 then t&i = &i.||' ***'; 
        else if P&i. < 0.01 then t&i = &i.||' **';
        else if P&i. < 0.05 then t&i = &i.||' *';
        else t&i. = &i.;
        drop &i. P&i.;
        ));
    run;

    * Print the results;
    proc print data=&outds;
    run;

    %mend correlation;
