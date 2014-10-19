/*!

    Frequency of discrete variables.

    * @author Luke W. Johnston
    * @created 2014-10-19

    */

/**

    Compute the frequencies of discrete variables.
    \\

    Macro for determining the frequencies of categorical/discrete
    variables. Said another way, the macro determines the count of each
    category in a discrete variable (for example, the number of "Males" vs
    "Females").
    \\

    [Examples:] &
    %fre

    * @param vars Discrete variables to compute frequencies

    * @param dsn The (input) dataset containing the variables
    
    * @param by Variable to split the discrete variable up and then
    calculate the frequencies

    * @param where Expression that subsets the dataset before running
    the analysis
    
    * @param outds The output dataset
    
    * @return Prints the frequencies of the discrete variables.

    */
%macro freq(vars, dsn=&ds, by=, where=, outds=_NULL_);

    * Send comments to log;
    %put 
    %put Analyzing frequencies of &vars.. ;
    %put Variables come from the dataset &dsn.. ;

    * Suppress output to Listings;
    ods listing close;
    proc freq data=&dsn;
        table &vars / list;
        by &by;
        where &where;
        ods output OneWayFreqs = &outds;
    run;
    ods listing;
    
    proc sort data=&outds;
        by Table;
    run;

    data &outds (rename=(Table = Variable));
        length Categories $ 45.;
        set &outds;
        by Table;
        
        * Combine result columns for ease of inserting into tables;
        nPerc = trim(Frequency)||' ('||
            strip(round(Percent, 0.1))||')';
        %for(i, in=(&vars), do=%nrstr(
            if &i. ne '' then Categories = &i.;
        ));

        * If a by variable is not specified;
        %if &by = %then %do;
            keep Table Categories nPerc CumFrequency;
            %end;
        * If a by variable is included;
        %else %if &by ne %then %do;
            keep &by Table Categories nPerc CumFrequency;
            %end;
    run;


    * Send descriptive info to the Listings;
    title1 'Frequencies of the following variables from the &dsn dataset:';
    title2 '&vars';
    proc print;
    run;

    * Clear all titles from subsequent output;
    title;

    %mend freq;
