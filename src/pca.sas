/*!

    Principal Component Analysis

    * @author Luke W. Johnston
    * @created 2014-10-22

    */

/**

    Run principal component analysis to reduce the number of dimensions.
    <p>

    This macro runs a principal component analysis (PCA) on the
    specified variables.  PCA is a dimensionality reduction statistical
    technique, used to take a large number of variables and output a
    smaller number of variables that explain a large amount of variance
    within the data matrix.  PCA is a subset of factor analysis, though it
    differs quite markedly from exploratory (EFA) or confirmatory factor
    analysis (CFA), among others.  There is no assumption of an underlying
    factor or factors for the variables of interest, while EFA and CFA do
    make that assumption.
    <p>

    <b>Examples:</b><br>
    <code>%pca(sashelp.fish, Weight Length1 Length2 Length3 Height Width, numPC=1,<br>
    opt_rotate=varimax);</code>

    * @param dsn The dataset that contains the variables.  Is a
    positional variable, so needs to be specified first

    * @param vars The variables that are used to generate the
    principal components.  It is a positional variable and needs to be
    specified second

    * @param numPC The number of principal components to output

    * @param opt_rotate The (optional) rotation applied to the PCA

    * @param outEig Output the eigenvalues from the PCA

    * @param outPattern Output the component patterns

    * @param outRotPat Output the rotated component patterns

    * @param outVariance Output the variance of the patterns

    * @return Prints the eigenvalues, explained variance, and
    component patterns by default

    */
%macro pca(dsn, vars, numPC=, opt_rotate=none,
    outEig= tmp, outPattern= tmp1, outRotPat= tmp2,
    outVariance= tmp3);

    * Close output to listings/output;
    ods listing close;

    * Need a prior of one to run a PCA;
    proc factor data=&dsn
        simple method=prin priors=one nfact=&numPC
        rotate=&opt_rotate out=&dsn;
        var &vars;
        ods output Eigenvalues = &outEig FactorPattern = &outPattern
            VarExplain = &outVariance;

        * If rotation is specified, output the data;
        * I only output varimax data so far;
        %if &opt_rotate = varimax %then %do;
            ods output OrthRotFactPat = &outRotPat;
            %end;
    run;
    ods listing;

    * Print the eigenvalues;
    proc print data=&outEig;
    proc print data=&outVariance;
    run;

    * Print off non-rotated patterns if no rotation is specified;
    %if &opt_rotate = none %then %do;
        proc print data=&outPattern;
        run;
        %end;
    
    * For now I only print off varimax rotations;
    %else %if &opt_rotate = varimax %then %do;
        proc print data=&outRotPat;
        run;
        %end;

    %mend pca;
