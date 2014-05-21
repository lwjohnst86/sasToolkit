libname myfmtlib '~/SAS/formats';

proc format library = myfmtlib;
    value SleepQltyf 
        0='Restless' 
        1='Restful';
    
    value tWaistf 
        0='1st Tertile' 
        1='2nd Tertile'
        2='3rd Tertile';
    
    value dLegf 
        0='Below median' 
        1='Above median';
    
    value qAnthrof 
        0='1st Quartile' 
        1='2nd Quartile'
        2='3rd Quartile' 
        3='4th Quartile';
    
    value dWgtf
        0='Below median' 
        1='Above median';
    
    value dWaistf 
        1='Smaller waist' 
        2='Larger waist';
    
    value rSESf 
        1='Group 1' 
        2='Group 2' 
        3='Group 3'
        4='Group 4';
    
    value SESf 
        1='Group 1' 
        2='Group 2' 
        3='Group 3'
        4='Group 4';
    
    value Sexf 
        1='Female' 
        2='Male';
    
    value Ethnicityf 
        1='Caucasian' 
        2='Hispanic' 
        3='South Asian' 
        4='Other';
    
    value BirthWtf 
        1='<2500g' 
        2='2500-4540g'
        3='>4540g' 
        4='Unknown';
    
    value rBirthWtf 
        1='<2500g' 
        2='2500-4540g'
        3='>4540g';
                *1='<5.5lb (<2500g)' 
                2='5.5-10lb (2500-4540g)'
                3='>10lb (>4540g)' 
                4='Unknown';
    
    value Prematuref 
        0='No' 
        1='Yes' 
        .A='Unknown';
    
        *value LifeOccupf
                1='Professional' 
                2='Skilled (non-manual)' 
                3='Semi-skilled manual' 
                4='Intermediate' 
                5='Skilled manual' 
                6='Unskilled manual';
    
    value LifeOccupf 
        5='Professional' 
        3='Skilled (non-manual)' 
        1='Semi-skilled manual' 
        4='Intermediate' 
        2='Skilled manual' 
        0='Unskilled manual';
    
    value Incomef 
        1='0-29000' 
        2='30-39000' 
        3='40-49000' 
        4='50-59000' 
        5='>60000' 
        6='Decline' 
        .='.';
    
    value rIncomef 
        0='0-29000' 
        1='30-39000' 
        2='40-49000' 
        3='50-59000' 
        4='>60000' 
        .='.';
    
    value Eduf 
        1='None' 
        2='1-8yrs' 
        3='9-12yrs' 
        4='Trade'
        5='College/Univ' 
        6='Unknown';
    
    value rEduf 
        0='None' 
        1='1-8yrs' 
        2='9-12yrs' 
        3='Trade'
        4='College/Univ';
    
    value rParEduf 
        0='0-8yrs' 
        1='9-12yrs' 
        2='Trade'
        3='College/Univ';
    
    value LifeEventsf 
        0='No stressful event over yr' 
        1='Stressful event over yr';
    
    value Tobaccof 
        1='Never' 
        2='Currently' 
        3='Previously';
    
    value Alcohf 
        1='None' 
        2='<1 dr/wk' 
        3='1-3 dr/wk' 
        4='4-6 dr/wk' 
        5='7-9 dr/wk' 
        6='10-14 dr/wk' 
        7='>15 dr/wk';
    
    value rAlcohf 
        1='None' 
        2='<1 dr/wk' 
        3='1-3 dr/wk' 
        4='4-6 dr/wk' 
        5='>7 dr/wk';
    
    value noyesf 
        0='No' 
        1='Yes';
    
run;
