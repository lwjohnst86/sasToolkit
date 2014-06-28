# Purpose #

I developed this toolkit to consolidate macros that I use in my research and also to share my efforts with anyone interested, but in particular to share with my fellow labmates.  As a disclaimer, not all macros are finished and some are very specific and situational, so I encourage anyone to update the files for readability, user-friendliness, flexibility, and parsimony.

# Contents #

There are two folders in this toolkit.  

## `doc` folder: ##

The `doc` folder contains the documemtation for the macros.  So far, I haven't found many documentation generators for SAS, one of which is called DocItOut that is pretty good at generating html pages for looking at the comments and parameters of the custom macros.  Open the `index.html` file in a web browser (i.e. Firefox) to view the documentation.

I will likely be making some type of parser to generate a pdf of the code documentation for those who would prefer viewing a pdf doc.

## `src` folder: ##

This folder contains two other folders, the `formats` folder and the `macros` folder.  I may be deleting the `formats` folder, as it doesn't really provide mich usw for those outside of my own research (of which, I barely use it).

The format to how the comments are structured are important and need to be consistently adhered to in order for DocItOut to work.  Please, if you plan to add to the macros and submit a pull request, be consistent with the way the code is structured.