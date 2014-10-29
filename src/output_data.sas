/*!

    Output a dataset to a <code>csv</code> file.

    * @author Luke W Johnston
    * @created 2014-10-11

    */

/**

    Output a dataset into a <code>csv</code> file into a directory.
    <p>

    This macro takes a dataset and converts it into a "comma separated
    value" (or <code>csv</code>) file.  The macro also removes double quotes from
    the output dataset.
    <p>

    <b>Examples:</b><br>
    <code>proc means data=sashelp.class;<br>
    ods output summary=meansData;<br>
    run;<br>
    %output_data(meansData, dir=./output);</code>

    * @param dataset The dataset to output to the <code>csv</code> file. It is
    a positional argument and so needs to be first

    * @param dir The directory/folder path that the <code>csv</code> output
    will be saved to

    * @return Outputs a <code>csv</code> file.

    */
%macro output_data(dataset, dir=tmp); 

    * Create a temporary filename, so no output is saved;
    filename temp temp;

    * Create the output directory if none exists;
    %put Checking if &dir needs to be created; 
    x "if [ ! -d &dir ] ; then mkdir &dir; fi";

    * Send the output of the proc print to csv;
    ods csv file=temp; 

    * Close output to the listings;
    ods listing close; 

    * Print the dataset;
    proc print data=&dataset; 
    run; 

    * Open the listings again and close the output to csv;
    ods listing; 
    ods csv close; 

    * Use this datastep to remove double quotes from the output;
    * dataset. I had a problem with the output not being read ;
    * properly in R, so I had to remove the quotes;
    %put Send &dataset. to &dir..;
    data _null_; 
        infile temp; 
        file "&dir./&dataset..csv"; 
        input; 
        _infile_ = compress(_infile_,'"'); 
        put _infile_; 
    run; 

    %mend output_data; 
