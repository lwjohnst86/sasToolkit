/*

    In-complete/working macros or ideas

    * @author Luke W. Johnston
    * @created 2014-11-21 (development)

    */

/* nth_ds --- Output every nth observation/row in a ds 
%macro nth_ds (nth_row=, ds=); * nth_row = The row number that you want output, ie: every 3rd row, nth_row=3;
    %let n = &nth_row;
    data &ds;
        set &ds;
        if mod(_n_, &n) eq 0 then output;
    run;
    %mend nth_ds;


