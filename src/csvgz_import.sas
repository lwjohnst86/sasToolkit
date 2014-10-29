/*!

    Import gzipped compressed <code>csv</code> into SAS

    * @author Luke W. Johnston
    * @created 2014-10-05

    */

/**

    Imports a gzipped (compressed) <code>csv</code> file into the SAS work space.
    <p>

    This macro is used to uncompress than read in a <code>csv.gz</code>
    (meaning gzipped) file.  SAS temporarily uncompresses the file, so
    that the original file remains intact.
    <p>

    <b>Requirements:</b> <code>%csvimport()</code> macro and a Unix/Linux operating
    system (OS).  I will need to make this macro more flexible for other
    OS.
    <p>

    <b>Examples:</b><br>
    <code>%csvgz_import(dataset=/home/username/data/projectData.csv.gz, outds=working,<br>
    dir=/home/username/projects/researchprojects/diabetesObesity/data);</code>

    * @param dataset The importing dataset, with the full path to the
    dataset to be imported

    * @param outds The output dataset

    * @param dir The directory where the data will temporarily
    created. The recommended directory is where the subsetted data will
    be saved to in the research project folder structure

    * @return Imports a compressed (<code>.csv.gz</code>) file to the specified
directory.

    */
%macro csvgz_import(dataset=, outds=&ds, dir=/tmp);

    * Check if dir exists, create if needed;
    x "if [ ! -d &dir ] ; then mkdir &dir; fi";

    * Uncompress the file ;
    x gunzip -c &dataset. > &dir./temp.csv;
    
    * Import using csvimport macro;
    %csvimport(dataset=temp, outds=&outds, dir=&dir);

    * Delete the temporary uncompressed file;
    x rm &dir./temp.csv;
    %mend csvgz_import;
