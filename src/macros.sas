/*!

    Contains macros that are used to make statistical analysis more or
    less easier, more manageable, and the code in the main script to be
    cleaner.

    * @author Luke Johnston
    * @created Early 2013

    */

/****************************************************************/

/**

    Import csv dataset

    <p>

    Imports a non-compressed csv (comma separated values) dataset and
    puts it in the SAS workspace (outds).

    * @param dataset Input dataset
    * @param outds Output dataset
    * @param dir Directory where the input dataset is located
    * @return Outputs the csv dataset into the SAS workspace

    */
%macro csvimport(dataset=, outds=&dataset, dir=../dataset);
    proc import datafile="&dir./&dataset..csv"
        out=&outds
        dbms=csv
        replace;
    run;
    %mend csvimport;

/**

    Macro for frequencies of categorical/discrete variables.  Only
    does univariate frequencies.

    * @param	vars	Discrete variables to analyze
    * @param	by	Variable to group by
    * @param	dsn	Name of dataset to analyze
    * @param	outds	Results dataset to output
    * @return	Only prints the results by default, but does output a dataset if specified

    */
%macro freq(vars, by=, where=, dsn=&ds, outds=_NULL_);

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
        
    data &outds (rename=(Table = Variable));
        length Categories $ 45.;
        set &outds;
        by Table;
        
        nPerc = trim(Frequency)||' ('||
            strip(round(Percent, 0.1))||')';
        %for(i, in=(&vars), do=%nrstr(
            if &i. ne '' then Categories = &i.;
        ));
        %if &by = %then %do;
            keep Table Categories nPerc CumFrequency;
            %end;
        %else %if &by ne %then %do;
            keep &by Table Categories nPerc CumFrequency;
            %end;
    proc print;
    run;

    %mend freq;



/**

    Correlation coefficient test

    <p>
    
    Computes correlation coefficients and outputs a csv file with
    asterisks as significance values.
    
    <p>
    
    You can specify which type of test you compute, such as Spearman
    or Pearson. You can also run partial correlations (adjusting for
    covariates).
    
    <p>
    <b>Examples:</b>
    <p>
    <code>
    %let continuous = Weight Height Age;
    %let exposure = CarbIntake ProteinIntake;
    %correlation(topvar=&exposure, sidevar=&continuous, dsn=dataset,
        outds=corr, where=Sex eq "Male", coeff_test=Pearson);
    proc print data=corr;
    run;
    <\code>
    
    * @param sidevar Variables that will be on the side of the output,
    i.e. those that make up the <b>rows</b>
    * @param topvar Variables that will be on the top of the output,
    i.e. those that make up the <b>columns</b>
    * @param covar Variables to adjust for the correlation (ie. confounder)
    * @param where Variable to subset by (ie. where sex = "male")
    * @param outds Output dataset
    * @param coeff_test The correlation coefficient test to use
    * @param dsn Dataset that contains the variables that will be analyzed
        by the correlation test
    * @return By default the results are printed, but no dataset is output.
        An output dataset can be specified by providing a name for the variable
        <code>outds</code>

    */
%macro correlation(topvar=, sidevar=, covar=, where=,
        outds=_NULL_, coeff_test=Spearman, dsn=&ds);
    %if &covar = %then %let partial = ;
    %else %let partial = Partial;
    ods listing close;
    proc corr data=&dsn &coeff_test;
        * indicate coefficient test to use (default;
        * is Spearman rank correlation);
        partial &covar; * variables to adjust for;
        var &topvar; * variables in the header row;
        with &sidevar; * variables on the side of the output, ;
            * the column;
        where &where;
        ods output &partial.&coeff_test.Corr = &outds;
    run;
    ods listing;
    data &outds;
        set &outds;
        %for(i, in=(&topvar), do=%nrstr(
            length t&i. $ 45;
        &i. = round(&i, 0.01);
        if P&i. < 0.001 then t&i = &i.||' ***'; 
        else if P&i. < 0.01 then t&i = &i.||' **';
        else if P&i. < 0.05 then t&i = &i.||' *';
        else t&i. = &i.;
        drop &i. P&i.;
        ));
    run;
    proc print data=&outds;
    run;
    %mend correlation;

/* Macro for PCA --- update this macro */
%macro pca (vars=, dsn= &ds, n=, opt_rotate=none, pcname=, varlabel=,
    outeig= _NULL_, outpattern= _NULL_, outrotpat= _NULL_,
    outvariance= _NULL_);
    proc factor data=&dsn
        simple method=prin priors=one nfact=&n
        rotate=&opt_rotate out=&dsn;
        var &vars;
        ods output Eigenvalues = &outeig FactorPattern = &outpattern
            VarExplain = &outvariance;
        %if &opt_rotate = varimax %then %do;
            ods output OrthRotFactPat = &outrotpat;
            %end;
    run;
    %if &n = 1 %then %do;
        data &dsn;
            set &dsn;
            rename Factor1 = &pcname;
            label Factor1 = "&varlabel";
        run;
        %end;
    %mend pca;

/* Update this macro. Macro for stature means by discrete variable */
%macro discr_means(discrete) / parmbuff;
    %local i;
    %let i = 1;
    %let discrete = %scan(&syspbuff, &i);
    %do %while(&discrete ne);
        proc means data=&ds n mean stddev median;
            var &continuous; * Define continuous before macro execution;
            class &discrete;
        run;
        %let i = %eval(&i + 1);
        %let discrete = %scan(&syspbuff, &i);
        %end;
    %mend discr_means;


/**

    ANOVA loop

    Runs an ANOVA and outputs the results into a dataset that can be
    converted into a nice format that can easily be pushed to
    LaTeX/pgfplotstable to generate tables in reports or presentations.

    <p>

    An ANCOVA can be run if ccovar or dcovar variables are used
    (ie. adjusting for confounders).  The output of this macro can be used
    in conjunction with the %means macro to make into a nice table format
    with means and SD, etc.
    
    * @param	category	Discrete variable (e.g. Sex) on the side of the table.
    * @param	numerical	Continuous variable (e.g. BMI) at the top of table.
    * @param	dsn		Dataset to be used (&ds variable is default).
    * @param	adjust		Adjustment made for post-hoc test.
    * @param	outds		Main output that is the purpose for this macro.
    * @param	outpdiff	Name of output for the between group p-values.
    * @param	dcovar		If ANCOVA is needed, this is the discrete covariate(s) to adjust for.
    * @param	ccovar		If ANCOVA is needed, this is the continuous covariate(s) to adjust for.
    * @param where Subset the data by the where variable
    * @param by Split the analysis up by a categorical variable
    * @return	The main output are proc prints of the output datasets outds and outpdiff, though these datasets are by default not output into the SAS workspace.

    */
%macro anova(category=, numerical=, dsn=&ds, adjust=tukey, by=,
    where=, outds=_NULL_, outpdiff=_NULL_, dcovar=, ccovar=);

    %local i j count;
    %let count = 0;

    %do i = 1 %to %sysfunc(countw(&numerical));
        %let numvar = %scan(&numerical, &i);
        %do j = 1 %to %sysfunc(countw(&category));
            %let categ = %scan(&category, &j);
            %let count = %eval(&count + 1);

            ods listing close;
            proc glm data=&dsn;
                class &categ &dcovar;
                model &numvar = &categ &ccovar / ss3;
                lsmeans &categ / adjust=&adjust pdiff;
                where &where;
                by &by;
                ods output Diff=diff&count ModelANOVA=model&count;
            run;
            ods listing;

            %end; 
        %end;

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

    proc print; 
    run;

    data &outpdiff; 
        length Dependent $ 35.;
        set diff1-diff&count; 
    run;
    proc print;
    run;
    %mend anova;


**********************************************************;
/** LOGISTIC REGRESSION MACROS SECTION **/
/* oddsratio --- Macro to use proc logistic for OR */
* This macro will run a logistic regression on each of the *;
* y and x given in a combinatory way (e.g. there are 2 *;
* y and 2 x, the analysis will run y1 with x1, then y1 with *;
* x2, then y2 with x2, etc.) *;
%macro oddsratio(y=&dep, x=&indep, dcovar=, ccovar=, dsn=&ds,
    outall=_NULL_, outcore=_NULL_, outobs=_NULL_);
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
            proc logistic data=&dsn. descending;
                units &xvar = SD / default=1;
                class &yvar &dcovar;
                model &yvar = &xvar &dcovar &ccovar / clodds=wald;
                oddsratio &xvar / cl=wald;
                ods output OddsRatiosWald=core&count CLOddsWald=all&count
                    NObs=obsOR&count;
            run;
            ods listing;

            data all&count (drop=OddsRatioEst LowerCL UpperCL);
                length Independent $ 45. Dependent $ 45. OR95CI $ 32.;
                set all&count;
                Independent = "&xvar";
                Dependent = "&yvar";
                OR95CI = round(OddsRatioEst, 0.01)||' ('||
                    strip(round(LowerCL, 0.01))||'-'||
                    strip(round(UpperCL, 0.01))||')';
                OR95CI = right(OR95CI);

            data core&count (drop=OddsRatioEst LowerCL UpperCL);
                length Independent $ 45. Dependent $ 45.;
                set core&count (drop=Effect);
                Independent = "&xvar";
                Dependent = "&yvar";
                OR95CI = round(OddsRatioEst, 0.01)||' ('||
                    strip(round(LowerCL, 0.01))||'-'||
                    strip(round(UpperCL, 0.01))||')';
                OR95CI = right(OR95CI);

            data obsOR&count;
                length Independent $ 45. Dependent $ 45.;
                set obsOR&count (keep=NObsUsed NObsRead);
                Independent = "&xvar";
                Dependent = "&yvar";
                %end;
            %end;
        
    data &outall;
        set all1-all&count;
    data &outcore;
        set core1-core&count;
    data &outobs;
        set obsOR1-obsOR&count;
    %mend oddsratio;

/* aroc --- Compute and output an AROC from logistic
    regression.  Works in a similar way to the "oddsratio"
    macro above (i.e. loop through each combination of outcome
    and exposure variables).  An output dataset will be produced. */
%macro aroc(y=&dep, x=&indep, ccovar=, dcovar=, dsn=&ds, outds=);
    %local i j count;
    %let count = 0;
    %do i = 1 %to %sysfunc(countw(&y));
        %let yvar = %scan(&y, &i);
        %do j = 1 %to %sysfunc(countw(&x));
            %let xvar = %scan(&x, &j);
            %let count = %eval(&count + 1);
            ods listing close;
            proc logistic data=&dsn. descending;
                class &yvar &dcovar;
                model &yvar = &xvar &dcovar &ccovar;
                roc;
                ods output ROCassociation=out&count;
            run;
            ods listing;
            data out&count;
                length ROCModel $ 30. Independent $ 30.;
                set out&count (drop=SomersD Gamma TauA);
                if ROCModel = 'ROC1' then delete;
                if ROCModel = 'Model' then ROCModel = "&yvar";
                Independent = "&xvar";
                rename ROCModel=Dependent;
            run;
            %end;
        %end;
    data &outds;
        set out1-out&count;
    run;
    proc print data=&outds;
    run;
    %mend aroc;

/* compareROC --- Statistically compare two AROC.  Use the
    output datasets from the "aroc" macro" above. */
%macro compareROC(subset=,indep1=,indep2=,dsn=,outds=);
    data aroc1 (drop=Independent);
        set &dsn;
        where Dependent="&subset";
        if Independent = "&indep1" then output;
    data aroc2 (drop=Independent);
        set &dsn;
        where Dependent="&subset";
        if Independent = "&indep2" then output;
    data &outds (drop=Area StdErr LowerArea UpperArea s1 s2);
        set aroc1;
        &indep1._AUC1=area; s1=stderr;
        Indep1 = "&indep1";
        set aroc2;
        &indep2._AUC2=area; s2=stderr;
        Indep2 = "&indep2";
        Chisq=(&indep1._AUC1 - &indep2._AUC2)**2/(s1**2 + s2**2);
        Prob=1-probchi(Chisq,1); 
        format Prob pvalue6.; 
        Test="AUC1 - AUC2 = 0";
        output;
        stop;
    run;
    proc print noobs;
        var Dependent Indep1 Indep2 &indep1._AUC1 &indep2._AUC2 Test Chisq Prob;
    run;
    %mend compareROC;



/**

    Runs linear regression, sending the results into output datasets
    that can be used in LaTeX as tables.  In this macro, there are two
    loops going on.  This allows any number of exposures and outcomes to
    be specified in the macro, running regressions on each outcome with
    each exposure.  This is allows the code to be cleaner, leaner, more
    efficient, and more maintainable.

    <p>
    
    The loops work in a combinatoric fashion, starting with the `y`,
    or dependent variable, then going through each of the `x`
    variables.  For instance, I want to run a regression on BMI and
    dietary fat with insulin resistance and blood lipids.  The `y`
    variable would have insulin resistance and blood lipids, while the `x`
    would have BMI and dietary fat.  The macro would run insulin
    resistance with BMI, then insulin resistance with dietary fat, then
    blood lipids and BMI and so on.

    <p>

    All output datasets are optional as each of the dataset variables
    are set to _NULL_.  The results datasets that can be output are the
    beta and standard error (plus p-value), the $R^2$, and the sample
    size.

    <p>

    Each variable, except for the dataset variables, can have multiple
    variables included, each separated by a space, *not* a comma.

    <p>

    As a reminder (for using the below variables), the linear
    regression equation is: y = B_0 + B_1 x_1 + ... + B_n x_n + e
    
    * @param	y		Dependent, or outcome, variable
    * @param	x		Independent, or exposure, variable
    * @param	dcovar		Discrete covariates included in the model (i.e. Sex)
    * @param	ccovar		Continuous covariates in the model (i.e. Age)
    * @param	interactvar	The <b>discrete</b> interaction term (i.e. Sex)
    * @param	dsn		Name of the dataset to analyze
    * @param	outall		Dataset with all the betas, SE of each variable in the model
    * @param	outcore	Dataset with only the betas, SE for the `x` variables
    * @param	outObs		Dataset with the sample size used in each model
    * @param	outRSq		Dataset with the $R^2$ for the model
    * @param	outResid	Dataset that contains the raw and studentized residuals
    * @return	The results of `outcore`, `outObs`, and `outRSq` are printed, but by default no datasets are output, unless specified.

    */
%macro beta_glm(y  =  &dep, x = &indep,
    dcovar = , ccovar = , interactvar = ,
    dsn = &ds, outall = _NULL_,
    outcore = _NULL_, outObs = _NULL_,
    outRSq = _NULL_, outResid = tmp, sigDigits = 0.01);
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



/* Include: Macro for Type3 (type3 wald chi sq) from Log Reg */

/* Include: Macro for interaction GLM and for logistic
    (i.e. &x.*&interactionterm) */

/* Useful potential bits: */
/* nth_ds --- Output every nth observation/row in a ds */
%macro nth_ds (nth_row=, ds=); * nth_row = The row number that you want output, ie: every 3rd row, nth_row=3;
    %let n = &nth_row;
    data &ds;
        set &ds;
        if mod(_n_, &n) eq 0 then output;
    run;
    %mend nth_ds;


/**

    Merge output datasets from the means and anova macros


    This macro merges the results of the ``means`' and ``anova`' macro, which
    are datasets, into one dataset with the p-value included for
    difference between groups.  The output for the means needs to have had
    an argument for the by variable (``by=`'), so that the means dataset can
    be transformed from long to wide.  The variables from both the ``means`'
    and the ``anova`' macro need to be in the same order/sequence.

    
    * @param meansds Output dataset from the ``means`' macro, needs to be
    the first argument

    * @param anovads Output dataset from the ``anova`' macro, has to be
    the second argument
    
    * @param byVar The categorical (or discrete/binary number, such as
    for an order) variable that was used to group both the anova and the
    means datasets

    * @param byVarNumLevels The levels of the discrete/binary number
    ``byVar`', such as 0 1, 0 1 2 3, etc

    * @param byVarCatLevels The levels of the categorical ``byVar`', such
    as Yes No or Female Male

    * @param outds Optional as the output dataset will be named after
    the ``means`' dataset

    * @author Luke Johnston

    * @return Outputs a dataset with the merged means and p-values for
    differences between groups
    
    */
%macro mergeMeansAnova (meansds, anovads, byVar, byVarNumLevels=_NULL_,
    byVarCatLevels=_NULL_, outds=_NULL_);

    * If no outds name is provided, use the name of the means dataset;
    %if &outds = _NULL_ %then %let outds = &meansds;

    * If neither of the levels variables are used, put a warning and stop the macro;
    %if &byVarNumLevels = _NULL_ and &byVarCatLevels = _NULL_ %then %do;
        %put WARNING: Please specify whether the byVar has number or categorical levels.lab;
        %put Use the byVarCatLevels or byVarNumLevels arguments in the mergeMeansAnova macro.;
        %return;
        %end;

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

