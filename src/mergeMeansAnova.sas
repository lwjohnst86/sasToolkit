/*!

    Merge means and ANOVA output datasets

    * @author Luke W. Johnston
    * @created 2014-11-21 (updated)

    */

/**

    Merge the output datasets generated from the means and anova
    macros.
    <p>

    This macro merges the results of the <code>means</code> and <code>anova</code> macro, which
    are datasets, into one dataset with the p-value included for
    difference between groups.  The output for the means needs to have had
    an argument for the by variable (<code>by=</code>), so that the means dataset can
    be transformed from long to wide.  The variables from both the <code>means</code>
    and the <code>anova</code> macro need to be in the same order/sequence.
    <p>

    <b>Examples:</b><br>

    * @param meansds Output dataset from the <code>means</code> macro, needs to be
    the first argument

    * @param anovads Output dataset from the <code>anova</code> macro, has to be
    the second argument
    
    * @param byVar The categorical (or discrete/binary number, such as
    for an order) variable that was used to group both the anova and the
    means datasets

    * @param byVarNumLevels The levels of the discrete/binary number
    <code>byVar</code>, such as 0 1, 0 1 2 3, etc

    * @param byVarCatLevels The levels of the categorical <code>byVar</code> such
    as Yes No or Female Male

    * @param outds Optional as the output dataset will be named after
    the <code>means</code> dataset

    * @return Outputs a dataset with the merged means and p-values for
    differences between groups

    */
%macro mergeMeansAnova (
    meansds,
    anovads,
    byVar,
    byVarNumLevels=_NULL_,
    byVarCatLevels=_NULL_,
    outds=_NULL_
    );

    * If no outds name is provided, use the name of the means dataset;
    %if &outds = _NULL_ %then %let outds = &meansds;

    * If neither of the levels variables are used, put a warning and stop the macro;
    %if &byVarNumLevels = _NULL_ and &byVarCatLevels = _NULL_ %then %do;
        %put WARNING: Please specify whether the byVar has number or categorical levels.lab;
        %put Use the byVarCatLevels or byVarNumLevels arguments in the mergeMeansAnova macro.;
        %return;
        %end;
    * add condition if both are ne _NULL_;

    * Set the levels variable for inclusion into the datastep;
    %if &byVarCatLevels ne _NULL_ %then %do;
        %let levels = &byVarCatLevels;
        %put The levels for the by variable are: &byVarCatLevels;
        %end;
    %else %if &byVarNumLevels ne _NULL_ %then %do;
        %let levels = &byVarNumLevels;
        %put The levels for the by variable are: &byVarNumLevels;
        %end;
    
    data &outds;
        retain ;
        * Add quotes around the &i variable if the CatLevels is used;
        %if &byVarCatLevels ne _NULL_ %then %do;
            %for(i, in=(&levels), do=%nrstr(
                set &meansds (where=(&byVar = "&i")
                rename=(MeanSD = MeanSD&i MedianIQR = MedianIR&i N = N&i)
                );
            drop Min Max &byVar;
            ));
            %end;

        * Otherwise, do not use quotes around the &i if the NumLevel is used;
        %if &byVarNumLevels ne _NULL_ %then %do;
            %for(i, in=(&levels), do=%nrstr(
                set &meansds (where=(&byVar = &i.)
                rename=(MeanSD = MeanSD&i MedianIQR = MedianIR&i N = N&i)
                );
            drop Min Max &byVar;
            ));
            %end;

        set &anovads (keep=ProbF Dependent rename=(ProbF = P));

        * Check to make sure that the Variables from both anova and means dataset ;
        * are the same. If not, output a warning to the log file;
        if Dependent = Variable then;
        else if Dependent ne Variable then do;
            put "WARNING: Check the sequence of your variables in both the anova and means macros";
            put "Make sure both anova and means macro number/continuous variables are in the same order";
            end;

        format P pvalue8.2;
        drop Dependent;
    run;
    %mend mergeMeansAnova;
