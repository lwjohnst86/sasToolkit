/*!

    Generalized Estimating Equations Analysis

    * @author Luke W. Johnston
    * @created 2014-09-20

    */

/**

    Generalized estimating equation (GEE) loop for exposures and
    outcomes.
    <p>

    This macro runs a longitudinal statistical test known as
    <b>generalized estimating equations</b>.  As with my other macros (for
    example <code>beta_glm</code>), this macro has two loops: one loops through all
    of the exposure or <code>x</code> variables and another that will loop through
    all the outcome or <code>y</code> variables.
    <p>

    By default, the macro prints the main findings from the GEE
    analysis.  However, output datasets can be specified (for instance,
    <code>outCore</code>), which can than be "massaged" and/or output into a
    <code>.csv</code> file.  Many of the macro variables can have multiple
    variables specified, but each additional variable must be separated by
    a space <b>not a comma</b>.
    <p>

    While GEE in SAS has to have the distribution, link, and working
    correlation matrix specified, GEE is very robust (aka consistent,
    reliable) to misspecified assumptions.
    <p>

    <b>Examples:</b><br>

    * @param dsn Dataset that contains the variables of interest. This
    is a positional variable and must be declared first
    
    * @param x The independent or exposure variables.  If more than
    one <code>x</code> is provided, the macro will loop through each <code>x</code> and run
    the GEE on each

    * @param y The dependent or outcome variables.  As with the <code>x</code>
    variable, more than one outcome variable will be looped through the
    GEE
    
    * @param time The variable used to indicate time, for example
    <code>VisitNumber</code> or <code>Age</code>
    
    * @param subject The variable that specifies the identifier for
    the subject/participant, for example <code>SID</code> or <code>ID</code>
    
    * @param ccovar The continuous covariates or confounders
    
    * @param dcovar The discrete/categorical covariates or confounders
    
    * @param dist The distribution assumption, which is dependent on
    the type of data the <code>x</code> or the <code>y</code> is (for example, continuous or
    discrete).  Other distributions include Normal, Poisson, Binomial,
    Multinomial, etc.
    
    * @param link The link function to be used in conjunction with the
    <code>dist</code> variable.  For example, when <code>dist=poisson</code>, the default
    link is <code>log</code>.  Other links include Logit, Identity, Inverse, etc.

    * @param wcorr The specified GEE working correlation matrix.  The
    standard and commonly used is the Exchangeable (or <code>exch</code>), but
    others include Autoregressive and Independent.  GEE is very robust
    (aka reliable/consistent) to a misspecified working correlation matrix
    
    * @param sigDigits Significant digits to round the output results to
    
    * @param outAll The name of the results dataset that contains all
    of the parameter estimates (that is, including the covariates)
    
    * @param outCore The name of the results dataset that contains the
    parameter estimates of <b>only</b> the <code>x</code> and <code>y</code> variables
    
    * @param outObs The output results dataset that contains the
    observations used in the analysis
    
    * @return Prints GEE model info, working correlations, and the
    parameter estimates.  By default, no result datasets are
    output.  However, datasets can be output to be massaged or output into
    a file.

    */
%macro gee(dsn, x=, y=, time=, subject=, ccovar=, dcovar=,
    dist=normal, link=identity, wcorr=exch, sigDigits=0.001,
    outAll=_NULL_, outCore=tmp, outObs=tmp);

    * Keep these variables inside the macro;
    %local i j count;

    * Put information on macro arguments into the log;
    %put ;
    %put # Generalized estimating equation analysis: ;
    %put GEE is running with a &dist distribution assumption, ;
    %put %str(     )an &link link, and using the &wcorr working correlation ;
    %put %str(     )matrix.  The cluster, subject, or case is the &subject ;
    %put %str(     )variable.  The time variable used is &time.;
    %put ;
    %put The GEE is conditioned on/adjusted for &ccovar (continuous) ;
    %put %str(     )and &dcovar (discrete);

    * Start the counter, which will be used to merge all the ;
    * looped datasets;
    %let count = 0;
    %do i = 1 %to %sysfunc(countw(&y));
        * Extract one y from the list of y variables given;
        %let yvar = %scan(&y, &i);
        %do j = 1 %to %sysfunc(countw(&x));
            * Add to the counter variable;
            %let count = %eval(&count + 1);
            * Extract one x from the list of x variables given;
            %let xvar = %scan(&x, &j);

            * Put information out into the log;
            %put %str(*) Running GEE on &yvar and &xvar;

            * Suppress output to the lst file/output log;
            ods listing close;

            * Start the GEE proc;
            proc genmod data=&dsn;
                class &subject &dcovar;
                model &yvar = &xvar &time &ccovar &dcovar /
                    dist=&dist link=&link;
                * It is the repeated statement here that allows for GEE;
                * Type is the working correlation matrix to use;
                repeated subject = &subject / type = &wcorr covb corrw;
                ods output GEEModInfo = info GEERCov = covMat
                    ConvergenceStatus = converge GEEEmpPEst = est&count
                    NObs = obs&count;
                * I currently only will output the exchangeable working;
                * correlation matrix, tho this may change later on;
                %if &wcorr = exch %then %do;
                    ods output GEEExchCorr = exchCorr;
                    %end;
            run;

            * Output to the lst file/output log;
            ods listing;
            
            * Print relevant information on the GEE analysis;
            title1 "## Running GEE: ##";
            title2 "Y = &yvar, x = &xvar, covariates = &dcovar &ccovar";
            title3 "Time = &time";
            proc print data=info;
            proc print data=converge;
            proc print data=covMat;
            run;

            * Again, this only will print the exchangeable corr;
            %if &wcorr = exch %then %do;
                proc print data=exchCorr;
                    var Label1 cValue1;
                run;
                %end;

            * Massage the output results into a prettier format;
            data est&count;
                length Independent $ 45. Dependent $ 45.;
                length estSE $ 43. estCL $ 45. Parm $ 45.;
                set est&count;
                format ProbZ pvalue8.3;
                * Input the y and x into the dataset for documenting;
                Independent = "&xvar";
                Dependent = "&yvar";
                * Create a single variable for the estimate and SE;
                estSE = trim(round(Estimate, &sigDigits.))||' ('||
                    strip(round(StdErr, &sigDigits.))||')';
                estSE = right(estSE);
                * Create a single variable for the estimate and 95 CI;
                estCL = trim(round(Estimate, &sigDigits.))||' ('||
                    strip(round(LowerCL, &sigDigits.))||' to '||
                    strip(round(UpperCL, &sigDigits.))||')';
                estCL = right(estCL);
                rename ProbZ = p;
            run;

            * Subset the estimate dataset to contain only the variables;
            * of interest;
            data estCore&count (drop=Parm);
                set est&count;
                if Parm = "&xvar" then output;
                else delete;
            run;

            * Massage the observation output data to a simpler format;
            data obs&count;
                length Independent $ 45. Dependent $ 45.;
                set obs&count (keep=NObsRead NObsUsed NMiss);
                * Keep only the first line;
                by NObsRead;
                Independent = "&xvar";
                Dependent = "&yvar";
                if first.NObsRead then output;
                else delete;
            run;
            %end;
        %end;

    * Create combined datasets for all of the looped ;
    * datasets;
    data &outAll;
        set est1-est&count;
    data &outCore;
        set estCore1-estCore&count;
    run;
    proc print data=&outCore;
    run;

    data &outObs;
        set obs1-obs&count;
    run;
    proc print data=&outObs;
    run;

    * Put an extra end space for the next macro;
    %put ;
    title3 '';
    %mend gee;
