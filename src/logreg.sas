/*!

    Logistic regression -- in development

    * @author Luke W. Johnston
    * @created 2014-11-21 (developing)

    */

/**

    Logistic regression in development
    <p>

    <b>Examples:</b><br>

    * @param y Dependent variable
    
    * @return In progress

    */
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

/*
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
*/
