/*!

    Analysis of Variance (ANOVA)

    * @author Luke W. Johnston
    * @created 2014-10-28

    */

/**

    Analysis of Variance (ANOVA) loop
    <p>

    Runs an ANOVA, using a loop for multiple variables, and prints out
    the pertinent information. An Analysis of Covariance (ANCOVA) can also
    be run if the <code>dcovar</code> or <code>ccovar</code> arguments are specified.
    <p>

    <b>Examples:</b><br>

    * @param dsn The dataset that contains the variables. This
    argument is positional and needs to be the first argument

    * @param category The discrete/categorical variable (for example,
    Sex - "M"/"F"

    * @param numerical The continuous variable (for example, weight)

    * @param adjust Post-hoc test (including <code>tukey</code>, <code>bon</code>)

    * @param by The by variable to split the analysis based on the
    <code>by</code> argument variable

    * @param where Argument to subset the dataset by before the
    analysis

    * @param outds The main output dataset, if specified

    * @param outpdiff The output dataset that contains the post-hoc
    p-values between the categories of the discrete variable (<code>category</code>
    argument)

    * @param dcovar The discrete covariate to adjust for

    * @param ccovar The continuous covariate to adjust for

    * @return Prints the results of the analysis, including the post-hoc test.

    */
%macro anova(dsn, category=, numerical=, adjust=tukey, by=,
    where=, outds=_NULL_, outpdiff=_NULL_, dcovar=, ccovar=);

    * Restrict these variables to within the macro environment;
    %local i j count;

    * Set the counter to zero. The counter allows the right number ;
    * of dataset to be produced through each loop.;
    %let count = 0;

    * Start the loop;
    %do i = 1 %to %sysfunc(countw(&numerical));

        * Read the i-th numerical variable and insert into the loop;
        %let numvar = %scan(&numerical, &i);

        * Start the next loop for the categorical variable;
        %do j = 1 %to %sysfunc(countw(&category));

            * Read the j-th category variable and put it into the loop;
            %let categ = %scan(&category, &j);

            %let count = %eval(&count + 1);

            * Suppress output to the listings;
            ods listing close;

            proc glm data=&dsn;
                class &categ &dcovar;
                model &numvar = &categ &ccovar / ss3;
                lsmeans &categ / adjust=&adjust pdiff;
                where &where;
                by &by;

                * Output the results;
                ods output Diff=diff&count ModelANOVA=model&count;
            run;

            * Open the listings again;
            ods listing;

            %end; 
        %end;

    * Merge each of the generated results datasets into one;
    data &outds;
        length Dependent $ 35.;
        set model1-model&count;
    run;

    * Sort the data by the by variable to be consistent with my ;
    * other macros (e.g. the means macro);
    %if &by ne %then %do;
        proc sort data=&outds;
            by &by;
        run;
        %end;

    proc print data=&outds; 
    run;

    * Merege each of the generated results datasets into one;
    data &outpdiff; 
        length Dependent $ 35.;
        set diff1-diff&count; 
    run;

    proc print data=&outpdiff;
    run;

    %mend anova;
