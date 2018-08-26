foreach i in case ctrl {
	use `i'dat, clear
	drop if `i'_mdt != "Breast"
	gen `i'_numid=_n
	save breast`i'dat, replace
}

* Stage 1: Subsetting
forvalues i = 0/64 {
	use breastctrldat, clear
	keep if ctrl_numid >= (`i' * 250)
	keep if ctrl_numid < ((`i'+1)*250)
	save gbreast`i', replace
}

* Stage 2: Joining
foreach i of numlist 0/64 {
	use gbreast`i', clear
	cross using breastcasedat
	save cbreast`i', replace
}

* Stage 3: Dropping
foreach i of numlist 0/64 {
	use cbreast`i', replace
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
	save mbreast`i', replace
}

* Stage 4: Random sampling
foreach i of numlist 0/64 {
	use mbreast`i', clear
	tempvar random mrank
		qui {
			gen `random' = rnormal()
			egen `mrank' = rank(`random'), by(ctrl_pid)
		}
	keep if `mrank'==1
	save rbreast`i', replace
}

* Stage 5: Appending
use rbreast0, clear
foreach i of numlist 1/64 {
	append using rbreast`i'
}

save "`c(pwd)'\out_data\matchedbreast.dta", replace

foreach i of numlist 0/64 {
	rm gbreast`i'.dta
	rm cbreast`i'.dta
	rm mbreast`i'.dta
	rm rbreast`i'.dta
}
