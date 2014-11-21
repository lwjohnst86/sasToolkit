/*!

    Import csv data files

    * @author Luke W. Johnston
    * @created 2014-11-21 (updated)

    */

/**

    Import comma separated value files into the SAS workspace.
    <p>

    Imports a non-compressed csv (comma separated values) dataset and
    puts it in the SAS workspace (outds).
    <p>

    <b>Examples:</b><br>
    <code>
    %csvimport(testdata, outds=working, dir=./data);
    </code>

    * @param dataset The name of the dataset file to import, <b>WITHOUT</b>
    the file extension (csv; for example a file called testdata.csv, the
    dataset name would be testdata). Is a positional argument and must
    come first
    
    * @param outds The name of the output dataset as it will be
    referenced by SAS in <code>proc</code> or <code>data</code> statements
    
    * @param dir The location (file path) of the input dataset, for
    example ./data or /home/users/research/data
    
    * @return Imports a SAS work dataset into the workspace.

    */
%macro csvimport(dataset, outds=&dataset, dir=../data);

    %put Loading in &dataset from &dir. ;
    
    proc import datafile="&dir./&dataset..csv"
        out=&outds
        dbms=csv
        replace;
    run;
    %mend csvimport;
