cap program drop rerandomize_spillovers_full
program rerandomize_spillovers_full
        syntax , ///
        resampvar(varname) ///<- name of the resampling variable
        stratvar(varname) ///<- name of the strata variable
        clustvar(varname) ///<- name of the cluster variable
        * //<- ritest also passes other things to the permutation procedure
		
		rerandomize, resampvar(`resampvar') stratvar(`stratvar') clustvar(`clustvar')	

		
		//spilloverstuff:
		replace treat_eligible =`resampvar'
		replace treat_eligible =0 if !eligible
		
		compute_ringcounts if year==2001, treatupdate
		qui {
		sort `clustvar' year, stable
		by `clustvar' : replace treatment_2   = treatment_2[_n-1]  if missing(treatment_2)
		by `clustvar' : replace treatment_2t5 = treatment_2t5[_n-1]  if missing(treatment_2t5)
		
		}
		
		
end

cap program drop compute_ringcounts
program compute_ringcounts
	syntax [if], [treatupdate]
	marksample touse 
	tempvar sortorder 
	
	if ("`treatupdate'"=="") {
		gen `sortorder' = 1-`touse'
	}
	else {
		gen `sortorder' = 1-`touse'
		replace `sortorder'=1 if missing(treatment) //i don't need to loop if ineligible villages if i'm only updating the t-count
	}
	sort `sortorder', stable

	if ("`treatupdate'"=="") {
		cap drop vills_1
		cap drop vills_2
		cap drop vills_5
		cap drop vills_2t5 
		
		cap drop e_2
		cap drop e_1
		cap drop e_5	
		cap drop e_2t5
	}
	cap drop control_1
	cap drop control_2
	cap drop control_5
	cap drop control_2t5

	cap drop treatment_1
	cap drop treatment_2
	cap drop treatment_5
	cap drop treatment_2t5
	
	if ("`treatupdate'"=="") {
		gen vills_1 = 0 if `touse'
		gen vills_2 = 0 if `touse'
		gen vills_5 = 0 if `touse'
	}
	gen control_1 = 0 if `touse'
	gen control_2 = 0 if `touse'
	gen control_5 = 0 if `touse'
	gen treatment_1 = 0 if `touse'
	gen treatment_2 = 0 if `touse'
	gen treatment_5 = 0 if `touse'

	qui sum `touse' if `sortorder'==0 //
	di r(N)
	forval i = 1/`: di r(N)' { //remember that the obs are sorted
			local fixlat = POINT_XY_lat[`i']
			local fixlon = POINT_XY_lon[`i']
			local fixtreat = treatment[`i']
			tempvar dist
			geodist POINT_XY_lat POINT_XY_lon `fixlat' `fixlon'  if `touse', gen(`dist') sphere 
			qui {
				if ("`treatupdate'"=="") {
					replace vills_1   = vills_1   + (`dist'<=1 )  if `touse'
					replace vills_2   = vills_2   + (`dist'<=2 )  if `touse'
					replace vills_5   = vills_5   + (`dist'<=5 )  if `touse'
				}
				if (`fixtreat'==1) {
					replace treatment_1   = treatment_1   + (`dist'<=1 & `fixtreat'==1)  if `touse'
					replace treatment_2   = treatment_2   + (`dist'<=2 & `fixtreat'==1)  if `touse'
					replace treatment_5   = treatment_5   + (`dist'<=5 & `fixtreat'==1)  if `touse'
				}
				else if (`fixtreat'==0) {
					replace control_1   = control_1   + (`dist'<=1 & `fixtreat'==0)  if `touse'
					replace control_2   = control_2   + (`dist'<=2 & `fixtreat'==0)  if `touse'
					replace control_5   = control_5   + (`dist'<=5 & `fixtreat'==0)  if `touse'
				}
				drop `dist' //to clear memory
				
			}
	}
	replace treatment_1 = treatment_1 - 1 if treatment==1
	replace treatment_2 = treatment_2 - 1 if treatment==1
	replace treatment_5 = treatment_5 - 1 if treatment==1
	gen treatment_2t5 = treatment_5 - treatment_2
	
	replace control_1 = control_1 - 1 if treatment==0
	replace control_2 = control_2 - 1 if treatment==0
	replace control_5 = control_5 - 1 if treatment==0
	gen control_2t5 = control_5 - control_2

	if ("`treatupdate'"=="") {
		replace vills_1 = vills_1 - 1
		replace vills_2 = vills_2 - 1
		replace vills_5 = vills_5 - 1
		gen vills_2t5 = vills_5 - vills_2
		
		gen e_1 = treatment_1 + control_1
		gen e_2 = treatment_2 + control_2
		gen e_5 = treatment_5 + control_5
		gen e_2t5 = treatment_2t5 + control_2t5
	}
end
