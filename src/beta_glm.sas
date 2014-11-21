/*!

    Simple or multiple linear regression

    * @author Luke W. Johnston
    * @created 2014-11-04

    */

/**

    Multiple (or simple) linear regression for predicting the outcome
    based on the exposures.
    <p>

    Runs linear regression, sending the results into output datasets
    that can be used in LaTeX as tables.  In this macro, there are two
    loops going on.  This allows any number of exposures and outcomes to
    be specified in the macro, running regressions on each outcome with
    each exposure.  This is allows the code to be cleaner, leaner, more
    efficient, and more maintainable.
    <p>
    
    The loops work in a combinatoric fashion, starting with the <code>y</code>,
    or dependent variable, then going through each of the <code>x</code>
    variables.  For instance, I want to run a regression on BMI and
    dietary fat with insulin resistance and blood lipids.  The <code>y</code>
    variable would have insulin resistance and blood lipids, while the <code>x</code>
    would have BMI and dietary fat.  The macro would run insulin
    resistance with BMI, then insulin resistance with dietary fat, then
    blood lipids and BMI and so on.
    <p>

    All output datasets are optional as each of the dataset variables
    are set to _NULL_.  The results datasets that can be output are the
    beta and standard error (plus p-value), the <code>$R^2$</code>, and the sample
    size.
    <p>

    Each variable, except for the dataset variables, can have multiple
    variables included, each separated by a space, <b>not</b> a comma.
    <p>

    As a reminder (for using the below variables), the linear
    regression equation is: $$y = B_0 + B_1 x_1 + ... + B_n x_n + e$$
    <p>

    <b>Examples:</b>
    <p>

    <pre><code>
        %beta_glm(sashelp.fish, y = Weight, x = Length1 Width,
        dcovar = Species, outcore = regressionResults);
        proc print data=regressionResults;
        run;
    </code></pre>


    * @param dsn The dataset that contains the variables.  This arg is
    positional and so needs to come first

    * @param y The outcome or dependent variable; this arg is
    positional and comes second.  If more than one variable is included,
    the macro will loop through each variable

    * @param x The exposure or independent variable; this arg is
    positional and comes third.  If more than one variable is included,
    the macro will loop through each variable

    * @param dcovar The discrete covariates

    * @param ccovar The continuous covariates

    * @param interactvar The interaction variable (if of interest)

    * @param outall Outputs the beta estimates for all the variables
    in the linear regression model, including the covariates

    * @param outcore Outputs only the beta estimates 

    * @param outObs Outputs the observations read and used

    * @param outRSq Outputs the R-squared

    * @param outResid Outputs the regression residuals

    * @param sigDigits Specify the number of significant digits for
    the output datasets

    * @param by Variable to run the analysis on individually (for
    example, to run a regression on each Sex)

    * @return Prints the regression model beta estimates, the
    observations used, as well as the R-squared

    */
%macro beta_glm(dsn, y, x, 
    dcovar = ,
    ccovar = ,
    interactvar = ,
    outall = _NULL_,
    outcore = _NULL_,
    outObs = _NULL_,
    outRSq = _NULL_,
    outResid = tmp,
    sigDigits = 0.01,
    by=);

    %local i j count;
    %let count = 0;
    %do i = 1 %to %sysfunc(countw(&y));
        * This will scan the outcome variables and run the;
        * analysis on each of the given variables;
        %let yvar = %scan(&y, &i);
        %do j = 1 %to %sysfunc(countw(&x));
            * This will scan the exposure variables and run;
            * the analyses on each of the given variables;
            %let count = %eval(&count + 1);
            %let xvar = %scan(&x, &j);
            ods listing close;
                * listing close prevents output to the lst file;
            proc glm data=&dsn;
                %if %length(&interactvar) ne 0 %then %do;
                    class &dcovar &interactvar;
                    model &yvar = &xvar &dcovar &ccovar
                        &xvar * &interactvar / solution;
                    %end;
                %else %do;
                    class &dcovar;
                    model &yvar = &xvar &dcovar &ccovar / solution;
                    %end;
                ods output ParameterEstimates = beta&count
                    FitStatistics = fit&count NObs = obs&count;
                output out = &outResid student = rstud_&yvar r = r_&yvar;
                by &by;
            run;
            ods listing;
            
            data beta&count (drop=Biased tValue);
                length Independent $ 45. Dependent $ 45. betaSE $ 32.;
                set beta&count;
                format Probt pvalue8.3;
                * Include?: format Estimate 8.3 StdErr 8.3;
                Independent = "&xvar";
                Dependent = "&yvar";
                betaSE = trim(round(Estimate, &sigDigits.))||' ('||
                    strip(round(StdErr, &sigDigits.))||')';
                betaSE = right(betaSE);
                *include this?: if Probt > 0.01 then Probt = round(Probt, 0.01);
                rename Probt = p;
                
            data betaCore&count (drop=Parameter);
                set beta&count;
                if Parameter = "&xvar" then output;
                else delete;

            data fit&count (keep=Dependent Independent RSquare);
                length Independent $ 45. Dependent $ 45.;
                set fit&count;
                Independent = "&xvar";
                RSquare = round(RSquare, &sigDigits.);
                
            data obs&count;
                length Independent $ 45. Dependent $ 45.;
                set obs&count (keep=NObsUsed NObsRead);
                Independent = "&xvar";
                Dependent = "&yvar";
                %end;
            %end;

    data &outall;
        set beta1-beta&count;
    data &outcore;
        set betaCore1-betaCore&count;
    proc print;
    data &outObs;
        set obs1-obs&count;
    proc print;
    data &outRSq;
        set fit1-fit&count;
    proc print;
    run;

    %mend beta_glm;
