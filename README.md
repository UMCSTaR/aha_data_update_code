# AHA variable creation
creates/extracts variables each year from new aha file and merges with existing master aha file (file containing data for all years except for new year to be added).

# Excel map structure
The data folder contains an excel sheet that has the new variables mapped to the original variables. 
There are 3 sheets: master AHA data dictionary, 2018 aha data dictionary, map between master and 2018 variables.
    
The map sheet contains 4 columnn:
1. "REQUIRED VAR NAME" contains the variable name used in master aha file
2. "DESCRIPTION" contains the defition of each variable. These definitions can be directly picked from the source file or may be calculated using other variables in source file. The requirement for each variable is outlined in its description.
3. "VAR NAMES UPTO 2017" conatins all of the variables needed to be extracted from new aha file. Variable names often change across years and a combination of description and data dictionary is used to determine the correct source variablee.
4."FROM SAS"column contains the code for each variable written in sas. The full sas code is included in the repo called aha_hosp_attribute.sas. This file can be referred to in case of any confusion. 

# Code structure
The code.R file contains the entire code for creating each variable. current_year needs to be reset every year. Code might require modifications every year depending on data dictionary each year.

#How to use for adding new year
1. Create map in excel sheet for new year. Use previous years and exisiting sas code logic for each variable to create all variables.
2. Use excel map to modify code and then merge with master file.

#Note
Every year the format for aha file can change and many variables can be missing, in such a case those variables will remain empty for that year in master file too.



    

