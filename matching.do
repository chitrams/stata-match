*** ---------------------------------
*** Automating matching processes
***
*** Ver 25 Aug 2018
*** Chitra's summer project
*** ---------------------------------

* Set-up for all cancers
cd "\\tsclient\Chitra\statamatchatC"

use "`c(pwd)'\in_data\casedat.dta", clear
rename mdt case_mdt
save casedat, replace

use "`c(pwd)'\in_data\ctrldat.dta", clear
foreach x of var * {
	rename `x' ctrl_`x'
}
save ctrldat, replace

di _N / 250
/* # of groups for each cancer type

Important for numlist in code. Used R as it's quicker. Results:
"Breast" "Genito-urinary" "Gynaecological" "Lower GI" "Lung"
64 15 32 26 38 groups */

* Subset by HADS count /*

use ctrldat, clear
drop if hads_count == 1
save ctrldatone, replace

use ctrldat, clear
keep if hads_count > 1
save ctrldat, replace */

* Run matching process
* Matched data named as matched`cancer'.dta
do "`c(pwd)'\scripts\matchGU.do"
do "`c(pwd)'\scripts\matchbreast.do"
do "`c(pwd)'\scripts\matchlung.do"
do "`c(pwd)'\scripts\matchgynae.do"
do "`c(pwd)'\scripts\matchlowerGI.do"

* Check matched data
use "`c(pwd)'\out_data\matchedGU.dta", clear
bro

************************
*** Matching process ***
************************

/* File names
`cancer'ctrldat: Data of that cancer type for all observations
`cancer'casedat: Data of that cancer type for cases
matched`cancer': Complete matched data for that cancer type

By subset number `i':
g`cancer'`i' : Grouped dataset of that cancer type
c`cancer'`i' : Crossed dataset of that cancer type
m`cancer'`i' : Matched dataset of that cancer type
r`cancer'`i' : Randomly sampled data of that cancer type

Splitting and re-appending merged dataset done in R for speed
*/

*****************************
******** Run example ********
*** Genito-urinary cancer ***
********* 3 subsets *********
*****************************

foreach i in case ctrl {
	use `i'dat, clear
	drop if `i'_mdt != "Genito-urinary"
	gen `i'_numid=_n
	save GU`i'dat, replace
}

* Stage 1: Subsetting
* Subset for each 250 obs (memory issues)
* This subset continues untill append stage.
forvalues i = 0/3 {
	use GUctrldat, clear
	keep if ctrl_numid >= (`i' * 250)
	keep if ctrl_numid < ((`i'+1)*250)
	save gGU`i', replace
}

* Stage 2: Joining
* Full join of cases to controls
* This part is the most time consuming bit
foreach i of numlist 0/3 {
	use gGU`i', clear
	cross using GUcasedat
	save cGU`i', replace
}

* Stage 3: Dropping
* Change conditions and calipers here.
foreach i of numlist 0/3 {
	use cGU`i', replace
******************************* ------------------------------------------------
*** Edits for matching here *** ------------------------------------------------
******************************* ------------------------------------------------

	drop if pid == ctrl_pid
	drop if sex != ctrl_sex
	drop if obj != ctrl_obj
	*drop if urbrur != ctrl_urbrur
	*drop if marital != ctrl_marital

	drop if abs(age-ctrl_age) > 5 				/* Boundary for age in yrs */
	drop if abs(t1-ctrl_t1) > 400 				/* Boundary for t1 in days */
	drop if abs(t2-ctrl_t2) > 365				/* Boundary for t2 in days */
	drop if abs(t3-ctrl_t3) > 100				/* Boundary for t3 in days */

/* Info on calipers:
t1: Duration between inclusion and death / eos
t2: Duration between final HADS obs and death / eos
t3: Duration between penultimate and final HADS obs
*/

******************************* ------------------------------------------------
*** Edits for matching ends *** ------------------------------------------------
******************************* ------------------------------------------------
	save mGU`i', replace
}

* Stage 4: Random sampling
foreach i of numlist 0/3 {
	use mGU`i', clear
	tempvar random mrank
		qui {
			gen `random' = rnormal()
			egen `mrank' = rank(`random'), by(ctrl_pid)
		}
	keep if `mrank'==1
	save rGU`i', replace
}

* Stage 5: Appending
use rGU0, clear
foreach i of numlist 0/3 {
	append using rGU`i'
}

save "`c(pwd)'\out_data\matchedGU.dta", replace

foreach i of numlist 0/3 {
	rm gGU`i'.dta
	rm cGU`i'.dta
	rm mGU`i'.dta
	rm rGU`i'.dta
}
