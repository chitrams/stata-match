foreach i in case ctrl {
	use `i'dat, clear
	drop if `i'_mdt != "Lung"
	gen `i'_numid=_n
	save lung`i'dat, replace
}

* Stage 1: Subsetting
forvalues i = 0/38 {
	use lungctrldat, clear
	keep if ctrl_numid >= (`i' * 250)
	keep if ctrl_numid < ((`i'+1)*250)
	save glung`i', replace
}

* Stage 2: Joining
foreach i of numlist 0/38 {
	use glung`i', clear
	cross using lungcasedat
	save clung`i', replace
}

* Stage 3: Dropping
foreach i of numlist 0/38 {
	use clung`i', replace
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
	save mlung`i', replace
}

* Stage 4: Random sampling
foreach i of numlist 0/38 {
	use mlung`i', clear
	tempvar random mrank
		qui {
			gen `random' = rnormal()
			egen `mrank' = rank(`random'), by(ctrl_pid)
		}
	keep if `mrank'==1
	save rlung`i', replace
}

* Stage 5: Appending
use rlung0, clear
foreach i of numlist 1/38 {
	append using rlung`i'
}

save "`c(pwd)'\out_data\matchedlung.dta", replace

foreach i of numlist 0/38 {
	rm glung`i'.dta
	rm clung`i'.dta
	rm mlung`i'.dta
	rm rlung`i'.dta
}
