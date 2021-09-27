/*******************************************************************************
Replication do-file for:    Appendix Table C.16
Paper:                      Heß, Schündeln, Jaimovich: "Environmental effects of
                            development programs: Experimental evidence from
                            West African dryland forests."
Journal:                    Journal of Development Economics
Contact:                    Simon Heß (hess@econ.uni-frankfurt.de)
Required packages:          estout, ritest 
Date:                       2021-09-27
Comments:                   This do-file replicates results Appendix Table C.16
							and Appendix Table C.17
 *******************************************************************************/
 
version 13
set matsize 4000
do "rerandomize.ado"

use "IHS.dta", clear

foreach var of varlist pca_assets-buffer {
	areg  `var' treatment pop_new PovertyIndex [pweight= pw ] if high_forest==1, a(ward_2003) cluster(village)
	ritest treatment _b[treatment], lessdots seed(2021) randomizationprogram(rerandomize) randomizationprogramoptions("stratvar(ward_2003) clustvar(village)") rep(5000) force: ///
		areg  `var' treatment pop_new PovertyIndex [pweight= pw ] if high_forest==1, a(ward_2003) cluster(village)
	eststo te`var'
	mat RI_p = r(p)
	estadd scalar rip = RI_p[1,1]
}


foreach hyp of varlist h*_vcv_ind_s {
	eststo, prefix(all): areg  `hyp' treatment pop_new PovertyIndex [pweight= pw ], ///
				cluster(village ) a(ward_2003) 
	eststo, prefix(highforest): areg  `hyp'2  treatment pop_new PovertyIndex  [pweight= pw ] if high_forest==1, ///
				cluster(village ) a(ward_2003) 
}

esttab te* using indiv.csv, drop(pop_new PovertyIndex) stats(rip) p replace
esttab highforest* using ihs.csv, drop(pop_new PovertyIndex) p replace
esttab all* using ihs.csv, drop(pop_new PovertyIndex) p append
