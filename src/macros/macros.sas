*****************************************************;
/** This file was created in early 2013.  It has been updated in
    2014-01-21.  It contains macros to make running analyses easier,
    simpler, and more efficiently. **/

********************************************************;
/** IMPORTING DATA INTO SAS **/
/* csvgz_import --- Import a compress csv file into sas */
%macro csvgz_import(dataset=, outds=&dataset, dir=../dataset);
    * Uncompress the file ;
    x gunzip -c &dir./&dataset..csv.gz > &dir./&dataset..csv;
    
    * Import using csvimport macro;
    %csvimport(dataset=&dataset, outds=&outds);

    * Delete the temporary uncompressed file;
    x rm &dir./&dataset..csv;
    %mend csvgz_import;

/* csvimport -- import csv into sas */
%macro csvimport(dataset=, outds=&dataset, dir=../dataset);
    proc import datafile="&dir./&dataset..csv"
        out=&outds
        dbms=csv
        replace;
    run;
    %mend csvimport;

/* contents -- view contents of all ds in parmbuffer. Default lib is work */
%macro contents(dataset=, lib=work);
    %do i = 1 %to %sysfunc(countw(&dataset));
        %let dsn = %scan(&dataset, &i);
        ods output Variables=vars (keep=Num Variable Type Format);
        ods listing close;
        proc contents order=casecollate data=&lib..&dsn;
        run;
        ods listing;
        ods output close;
        proc print data=vars;
        run;
        %end;
    %mend contents;

/* output_data --- Macro that outputs data to csv file and
   suppresses double quotes */
%macro output_data(dataset= , dir=../output);
    ods csv file=temp;
    ods listing close;
    proc print data=&dataset;
    run;
    ods listing;
    ods csv close;
    data _null_;
        infile temp;
        file "&dir./&dataset..csv";
        input;
        _infile_ = compress(_infile_,'"');
        put _infile_;
    run;
    %mend output_data;


************************************************************;
/** (QUASI) BIVARIATE ANALYSIS MACRO SECTION **/ 
/* means --- Computing means and concatenating the output
    into a dataset */
%macro means(vars=, by=, class=, outds=_NULL_, dsn=&ds);
    proc means data=&dsn stackods n mean 
                    stddev min max median Q1 Q3 maxdec=3;
        var &vars;
        class &class;
        by &by; * Untested in ods output for this macro;
        ods output summary=&outds;
    run;

    data &outds (drop=Mean StdDev Median Q1 Q3);
        set &outds;
        * Create two new variables which concat. ;
        * together other variables;
        MeanSD = round(Mean, 0.01)||' ('||
            strip(round(StdDev, 0.01))||')';
        MedianIQR = round(Median, 0.01)||' ('||
            strip(round(Q1, 0.01))||'-'||
            strip(round(Q3, 0.01))||')';
    proc print;
    run;
    %mend means;

/**

    Macro for frequencies of categorical/discrete variables.  Only
    does univariate frequencies.

    * @param	vars	Discrete variables to analyze

    * @param	dsn	Name of dataset to analyze
    * @param	outds	Results dataset to output
    * @return	Only prints the results by default, but does output a dataset if specified

*/
%macro freq(vars=, dsn=&ds, outds=_NULL_);
    proc freq data=&dsn;
        tables &vars / list;
        ods output OneWayFreqs = &outds;
    run;
    %mend freq;



/* correlations --- Macro to compute Pearson or Spearman
    correlations, either Partial or unadjusted, to an output
    dataset */
%macro correlation(rowvar=, colvar=, covar=, 
    outds=, coeff_test=Spearman, dsn=&ds);
    %if &covar = %then %let partial = ;
    %else %let partial = Partial;
    ods listing close;
    proc corr data=&dsn &coeff_test;
        * indicate coefficient test to use (default;
        * is Spearman rank correlation);
        partial &covar; * variables to adjust for;
        var &rowvar; * variables in the header row;
        with &colvar; * variables on the side of the output, ;
            * the column;
        ods output &partial.&coeff_test.Corr = &outds;
    run;
    ods listing;
    data &outds;
        set &outds;
        %for(i, in=(&rowvar), do=%nrstr(
            length t&i. $ 45;
        &i. = round(&i, 0.01);
        if &i. = 1 then;
        else if P&i. < 0.001 then t&i = &i.||' ***'; 
        else if P&i. < 0.01 then t&i = &i.||' **';
        else if P&i. < 0.05 then t&i = &i.||' *';
        else t&i. = &i.;
        drop &i. P&i.;
        ));
    run;
    %mend correlation;

/* Macro for PCA --- update this macro */
%macro pca (riskfact=, n=, opt_rotate=none, varname=, varlabel=, byvar=);
    proc factor data=&ds
        simple method=prin priors=one nfact=&n
        rotate=&opt_rotate out=&ds;
        var &riskfact;
        by VN &byvar;
    run;
    %if &n = 1 %then %do;
        data &ds;
            set &ds;
            rename Factor1 = &varname;
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

    Runs an ANOVA and outputs the results into a nice format that can
    easily be pushed to LaTeX/pgfplotstable to be generated into tables in
    reports or presentations.

    <p>

    There are loops in this macro, such that the variables on the side
    of the output ("category") are looped by the header variable (top of
    the output, "numerical").  For example, I want an output to eventually
    use as a table, with BMI and waist as the columns and sex and
    ethnicity on the side as rows.  Sex and ethnicity get looped by BMI
    first, then sex and ethnicity get looped by waist next.  This way, BMI
    will be the first column of results and waist will be the next column
    of results.

    <p>

    In addition, the output are formatted in a way to not
    need to manipulate the results in any way to fit as a table in a
    manuscript or presentations. For instance, means and standard
    deviations are output as a single column (as "mean (SD)"), when before
    they were two columns.
    
    * @param	category	Discrete variable (e.g. Sex) on the side of the table.
    * @param	numerical	Continuous variable (e.g. BMI) at the top of table.
    * @param	dsn		Dataset to be used (&ds variable is default).
    * @param	adjust		Adjustment made for post-hoc test.
    * @param	outds		Main output that is the purpose for this macro.
    * @param	outpdiff	Name of output for the between group p-values.
    * @param	dcovar		If ANCOVA is needed, this is the discrete covariate(s) to adjust for.
    * @param	ccovar		If ANCOVA is needed, this is the continuous covariate(s) to adjust for.
    * @return	The main output are proc prints of the output datasets outds and outpdiff, though these datasets are by default not output into the SAS workspace.

    */
%macro anova(category=, numerical=, dsn=&ds,
    adjust=tukey, outds=_NULL_, outpdiff=_NULL_,
    dcovar=, ccovar=);

    %local i j count numvarCount;
    %let count = 0;
    %let numvarCount = 0;

    %do i = 1 %to %sysfunc(countw(&numerical));
        %let numvar = %scan(&numerical, &i);
        %let startNum = %eval(&count + 1);
        %let numvarCount = %eval(&numvarCount + 1);
        %do j = 1 %to %sysfunc(countw(&category));
            %let categ = %scan(&category, &j);
            %let count = %eval(&count + 1);

            ods listing close;
            %means(vars=&numvar, class=&categ, outds=mean&count);

            proc glm data=&dsn;
                class &categ &dcovar;
                model &numvar = &categ &ccovar / ss3;
                lsmeans &categ / adjust=&adjust pdiff;
                ods output Diff=diff&count ModelANOVA=model&count;
            run;
            ods listing;

            data anova&count;
                length Variable $ 45.;
                Variable = "&categ";
                set mean&count (drop=Variable);
                if _n_ = 1 then do;
                    set model&count (keep=ProbF);
                    end;

            data anova&count;
                length Categories $ 45.;
                set anova&count;
                by ProbF;
                if first.ProbF then ProbF = ProbF;
                else ProbF = .;
                if first.ProbF then Variable = Variable;
                else Variable = "";
                Categories = &categ;
                drop &categ;
            run;
            %end;

        data anovaCombined&numvarCount;
            set anova&startNum.-anova&count;
            Header = "&numvar";
            drop _control_ NObs;
        run;
        %end;

    data &outds;
        retain ;
        %for(i, in=1:%sysfunc(countw(&numerical)), do=%nrstr(
            %let head = %scan(&numerical, &i);
        set anovaCombined&i. (where=(Header="&head")
            rename=(N=N_&head Min=Min_&head Max=Max_&head
            MeanSD=MeanSD_&head MedianIQR=MedianIGR_&head
            ProbF=ProbF_&head)
            );
        ));
        drop Header;
    proc print;

    data &outpdiff;
        set diff1-diff&count;
    proc print;
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
    * @param	dsn		Name of the dataset to analyze
    * @param	outall		Dataset with all the betas, SE of each variable in the model
    * @param	outcore	Dataset with only the betas, SE for the `x` variables
    * @param	outObs		Dataset with the sample size used in each model
    * @param	outRSq		Dataset with the $R^2$ for the model
    * @return	The results of `outcore`, `outObs`, and `outRSq` are printed, but by default no datasets are output, unless specified.

    */
%macro beta_glm(y=&dep, x=&indep,
    dcovar=, ccovar=,
    dsn=&ds, outall=_NULL_,
    outcore=_NULL_, outObs=_NULL_,
    outRSq=_NULL_);
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
                class &dcovar;
                model &yvar = &xvar &dcovar &ccovar / solution;
                ods output ParameterEstimates=beta&count
                    FitStatistics=fit&count NObs=obs&count;
                * Include an ods output dataset for residuals;
            run;
            ods listing;
            
            data beta&count (drop=Biased tValue);
                length Independent $ 45. Dependent $ 45. betaSE $ 32.;
                set beta&count;
                format Probt pvalue8.4;
                * Include?: format Estimate 8.3 StdErr 8.3;
                Independent = "&xvar";
                Dependent = "&yvar";
                betaSE = trim(round(Estimate, 0.001))||' ('||
                    strip(round(StdErr, 0.001))||')';
                betaSE = right(betaSE);
                if Probt > 0.01 then Probt = round(Probt, 0.01);
                rename Probt = p;
                
            data betaCore&count (drop=Parameter);
                set beta&count;
                if Parameter = "&xvar" then output;
                else delete;

            data fit&count (keep=Dependent Independent RSquare);
                length Independent $ 45. Dependent $ 45.;
                set fit&count;
                Independent = "&xvar";
                RSquare = round(RSquare, 0.001);
                
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
