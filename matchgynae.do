foreach i in case ctrl {
	use `i'dat, clear
	drop if `i'_mdt != "Gynaecological"
	gen `i'_numid=_n
	save gynae`i'dat, replace
}

* Stage 1: Subsetting
forvalues i = 0/32 {
	use gynaectrldat, clear
	keep if ctrl_numid >= (`i' * 250)
	keep if ctrl_numid < ((`i'+1)*250)
	save ggynae`i', replace
}

* Stage 2: Joining
foreach i of numlist 0/32 {
	use ggynae`i', clear
	cross using gynaecasedat
	save cgynae`i', replace
}

* Stage 3: Dropping
foreach i of numlist 0/32 {
	use cgynae`i', replace
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
	save mgynae`i', replace
}

* Stage 4: Random sampling
foreach i of numlist 0/32 {
	use mgynae`i', clear
	tempvar random mrank
		qui {
			gen `random' = rnormal()
			egen `mrank' = rank(`random'), by(ctrl_pid)
		}
	keep if `mrank'==1
	save rgynae`i', replace
}

* Stage 5: Appending
use rgynae0, clear
foreach i of numlist 1/32 {
	append using rgynae`i'
}

save "`c(pwd)'\out_data\matchedgynae.dta", replace

foreach i of numlist 0/32 {
	rm ggynae`i'.dta
	rm cgynae`i'.dta
	rm mgynae`i'.dta
	rm rgynae`i'.dta
}
