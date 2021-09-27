cd "D:\Dropbox\Gambia\Gambia Forest Project\Draft\replication\Replication Files"
clear
do "rerandomize.ado"
do "rerandomize_spillovers_full.ado"
version 13

set matsize 4000
use "Village Panel.dta", clear


est clear


foreach depvar in l_ll01_1KM l_ll01_5KM l_ll01_poly { 
	pdslasso `depvar' c.post_11_18#c.treatment c.post_08_10#c.treatment (i.ward_2003#i.year treatment i.ward_2003##c.(post_11_18 post_08_10)) if high_forest==1 & eligible==1, cluster(village) partial(treatment i.ward_2003##c.(post_11_18 post_08_10))

	//to compute the fraction of forest loss that is due to the CDD in this model:
	estadd local cmd "pdlasso", replace //fix because there is a typo in predict for pdslasso
	predict error_`depvar' if high_forest==1 & eligible==1, resid
	predict yhat_program_`depvar' if high_forest==1 & eligible==1, xb
	
	tempvar notreatment
	cap gen `notreatment' = 0
	rename (`notreatment' treatment) (treatment `notreatment')
	predict yhat_nrp_`depvar' if high_forest==1 & eligible==1, xb
	rename (`notreatment' treatment) (treatment `notreatment')
	
	eststo, prefix(doublelasso)
	//bootstrap computation of total loss
	tempfile bsres

	preserve
		keep if e(sample)
		
		//create running ids for villages and years
		sort village year, stable
		egen bs_vid = group(village)
		by village: gen bs_year = _n

		qui sum bs_vid
		local maxvid `r(max)'
		qui sum bs_year
		local maxyear `r(max)'
		
		expand 500 //prepare to draw 500 bootstrap samples
		sort village year, stable
		by village year: gen bs_b=_n //number the draws
		sort village bs_b year, stable
		//randomly select which village to take the draw from
		set seed 2020
		by village bs_b: gen bs_draw = ceil(runiform()*`maxvid') if _n==1 
		

		by village bs_b: replace bs_draw = bs_draw[_n-1] if missing(bs_draw)
		//bs_vy should contain for each village the row from which the draw is to be taken
		gen bs_vy = (bs_draw-1)*(500*`maxyear')+bs_year
		
		
		//copy the draw
		sort village bs_b year, stable
		gen bs_error = error_`depvar'[bs_vy]
		
		//compute predicted hectares based on draw from the mode and invese tranformation of the dep. var.
		gen bs_yhatT_nrp_`depvar' = exp(yhat_nrp_`depvar' + bs_error)-0.0755307
		gen bs_yhatT_program_`depvar' = exp(yhat_program_`depvar'+ bs_error)-0.0755307
		
		//average over all 500 draws from the same village
		collapse (mean) bs_yhatT_nrp_`depvar' bs_yhatT_program_`depvar', by(village year)
		save `bsres', replace
	restore
	merge 1:1 village year using `bsres' , nogen
	sum bs_yhatT_nrp_`depvar' if high_forest==1 & post_11_18==1 & eligible==1
	local bs_loss_noprogram = r(sum)
	sum bs_yhatT_program_`depvar' if high_forest==1 & post_11_18==1 & eligible==1
	local bs_loss_program = r(sum)

	di `bs_loss_program'-`bs_loss_noprogram'
	pause
	
	//point estimation for spillover specs
	eststo, prefix(spill): reghdfe	`depvar' ///
					c.post_08_10#c.treat_eligible									c.post_11_18#c.treat_eligible ///
					c.post_08_10#c.treatment_2		c.post_08_10#c.treatment_2t5 	c.post_11_18#c.treatment_2	 c.post_11_18#c.treatment_2t5 ///
					c.post_08_10#c.eligible 										c.post_11_18#c.eligible ///
					c.post_08_10#c.e_2				c.post_08_10#c.e_2t5			c.post_11_18#c.e_2			 c.post_11_18#c.e_2t5  ///
			if high_forest==1 , resid a(village ward_2003#year, savefe) cluster(village) 
	
	
	
	predict error_s_`depvar' if high_forest==1  , resid

	predict yhat_program_s_`depvar' if e(sample), xb
	predict FE_s_`depvar' if e(sample), d

	tempvar notreatment notreatment_2 notreatment_2t5
	cap gen `notreatment' = 0
	cap gen `notreatment_2' = 0
	cap gen `notreatment_2t5' = 0
	rename (`notreatment' `notreatment_2' `notreatment_2t5' treat_eligible  treatment_2 treatment_2t5) (treat_eligible  treatment_2 treatment_2t5 `notreatment' `notreatment_2' `notreatment_2t5')
	predict yhat_nrp_s_`depvar' if e(sample), xb
	rename (`notreatment' `notreatment_2' `notreatment_2t5' treat_eligible  treatment_2 treatment_2t5) (treat_eligible  treatment_2 treatment_2t5 `notreatment' `notreatment_2' `notreatment_2t5')

	
	replace yhat_nrp_s_`depvar' = yhat_nrp_s_`depvar'         + FE_s_`depvar'
	replace yhat_program_s_`depvar' = yhat_program_s_`depvar' + FE_s_`depvar'
	
	//bootstrap computation of total loss
	tempfile bsres
	preserve
		keep if e(sample)
		
		//create running ids for villages and years
		sort village year, stable
		egen bs_vid = group(village)
		by village: gen bs_year = _n

		qui sum bs_vid
		local maxvid `r(max)'
		qui sum bs_year
		local maxyear `r(max)'
		
		expand 500 //prepare to draw 500 bootstrap samples
		sort village year
		by village year: gen bs_b=_n //number the draws
							
		set seed 2020
		//randomly select which village to take the draw from
		sort village bs_b year, stable
		by village bs_b: gen bs_draw = ceil(runiform()*`maxvid') if _n==1 
		by village bs_b: replace bs_draw = bs_draw[_n-1] if missing(bs_draw)
		//bs_vy should contain for each village the row from which the draw is to be taken
		gen bs_vy = (bs_draw-1)*(500*`maxyear')+bs_year
		//copy the draw
		sort village bs_b year, stable
		gen bs_error = error_s_`depvar'[bs_vy]
		
		//compute predicted hectares based on draw from the mode and invese tranformation of the dep. var.
		gen bs_yhatT_nrp_s_`depvar' = exp(yhat_nrp_s_`depvar' + bs_error)-0.0755307
		gen bs_yhatT_program_s_`depvar' = exp(yhat_program_s_`depvar'+ bs_error)-0.0755307
		
		//average over all 500 draws from the same village
		collapse (mean) bs_yhatT_nrp_s_`depvar' bs_yhatT_program_s_`depvar', by(village year)
		save `bsres', replace
	restore
	merge 1:1 village year using `bsres' , nogen
	sum bs_yhatT_nrp_s_`depvar' if high_forest==1 & post_11_18==1  
	local bs_loss_noprogram = r(sum)
	sum bs_yhatT_program_s_`depvar' if high_forest==1 & post_11_18==1 
	local bs_loss_program = r(sum)

	di `bs_loss_program'-`bs_loss_noprogram'
	pause
	//454.20726
	
	
	
	
	//randomization inference for spillover specs
				
	/* the following code requires village-level longitude and latitude data, please contact the authors if you require these data.
	ritest treat_eligible _b[c.post_11_18#c.treat_eligible] _b[c.post_11_18#c.treatment_2] _b[c.post_11_18#c.treatment_2t5],  ///	
		r(2) seed(2020) samplingprogram(rerandomize_spillovers_full) samplingprogramoptions("stratvar(ward_2003) clustvar(village)"): ///
		`e(cmdline)'
		
	//conley inference for spillover specs
	cap xi 			i.post_08_10*treat_eligible									i.post_11_18*treat_eligible ///
					i.post_08_10*treatment_2		i.post_08_10*treatment_2t5 	i.post_11_18*treatment_2	 i.post_11_18*treatment_2t5 ///
					i.post_08_10*eligible 										i.post_11_18*eligible ///
					i.post_08_10*e_2				i.post_08_10*e_2t5			i.post_11_18*e_2			 i.post_11_18*e_2t5  ,prefix(_Sp_)
	eststo, prefix(spillconley): acreg `depvar'  _Sp_* ///
			if high_forest==1 ,  pfe1(village) pfe2(fwx) time(year) id(village) spatial latitude(POINT_XY_lat) longitude(POINT_XY_lon) dist(10) lagcutoff(18) hac
	*/
	//Table 2 and Tables A9, A10
	foreach var of varlist pvillh_droad2 pvillh_popu pvillh_pover pvillh_elf {
		eststo, prefix(hetero): reghdfe `depvar' c.post_11_18#c.treatment#i.`var' c.post_08_10#c.treatment#i.`var'  c.post_11_18#c.`var' c.post_08_10#c.`var' if high_forest==1 & eligible==1, cluster(village) a(village ward_2003#year)
	}

						
	//Table A.1
	eststo, prefix(TableA1_): reghdfe `depvar'  c.post_11_18#c.treatment c.post_08_10#c.treatment if high_forest==1 & eligible==1 ///
						, cluster(village) a(village ward_2003#year) 
						
	//Table A.2
	eststo, prefix(TableA2): reghdfe `depvar'  c.post_11_18#c.treatment c.post_08_10#c.treatment if muc_forest==1 & eligible==1 ///
						, cluster(village) a(village ward_2003#year) 
						
	//Table A.3
	eststo, prefix(TableA3): reghdfe `depvar'  c.post_11_18#c.treatment c.post_08_10#c.treatment if smw_forest==1 & eligible==1 ///
						, cluster(village) a(village ward_2003#year) 
						
	//Table A.4
	eststo, prefix(TableA4): reghdfe `depvar'  c.post_11_18#c.treatment c.post_08_10#c.treatment if eligible==1 ///
						, cluster(village) a(village ward_2003#year) 
						
	//Table A.5
	eststo, prefix(TableA5): reghdfe `=subinstr("`depvar'","ll01","ihs01",.)'  c.post_11_18#c.treatment c.post_08_10#c.treatment if high_forest==1 & eligible==1 ///
						, cluster(village) a(village ward_2003#year) 
						
	//Table A.6
	eststo, prefix(TableA6): reghdfe `=subinstr("`depvar'","ll01","l01",.)'  c.post_11_18#c.treatment c.post_08_10#c.treatment if high_forest==1 & eligible==1 ///
						, cluster(village) a(village ward_2003#year) 		
	
	
	preserve
		keep if high_forest==1 & eligible==1
		xtset, clear

		//Table A.7
		eststo, prefix(TableA7a): reghdfe `depvar'  c.post_11_18#c.treatment c.post_08_10#c.treatment  ///
							, cluster(village) a(village ward_2003#year) 
							
		//Table A.7
		eststo, prefix(TableA7b): reghdfe `depvar'  c.post_11_18#c.treatment c.post_08_10#c.treatment   ///
							, cluster(ward_2003) a(village ward_2003#year) 
		ritest treatment _b[c.post_11_18#c.treatment] _b[c.post_08_10#c.treatment], r(5000) lessdots samplingprogram(rerandomize) randomizationprogramoptions("stratvar(ward_2003) clustvar(village)"): `e(cmdline)'
		eststo, prefix(TableA7c)
		estadd matrix p_ritest_c = r(p)
		
		/* This part is commented out, because it requieres the longitude and latitude, which are not part of the public dataset
		//acreg does not like interactions:
		cap gen tpost_08_10=post_08_10*treatment
		cap gen tpost_11_18=post_11_18*treatment
		cap gen fwx = ward_2003*10000+year
		eststo, prefix(TableA7d): acreg `depvar' tpost_08_10 tpost_11_18, pfe1(village) pfe2(fwx) time(year) id(village) spatial latitude(POINT_XY_lat) longitude(POINT_XY_lon) dist(10) lagcutoff(18) hac
		*/
		eststo, prefix(TableA7e): bootstrap, nodots strata(ward_2003) seed(2020) r(500) idcluster(nv) cluster(village) : reghdfe `depvar' c.treatment#c.post_08_10 c.treatment#c.post_11_18, a(nv ward_2003#year) 		
		eststo, prefix(TableA7f): bootstrap, nodots cluster(ward_2003) seed(2020) r(500) idcluster(nw) : reghdfe `depvar' c.treatment#c.post_08_10 c.treatment#c.post_11_18, a(nw#village nw#year)

		
		//cgmwildboot does not like interactions and needs partialled out fixed effects. so we create them.
		qui foreach var of varlist `depvar' tpost_08_10 tpost_11_18 {
			cap reghdfe `var', a(village ward_2003#year) resid(`var'_pfe)
		}
						
		eststo, prefix(TableA7g): cgmwildboot `depvar' tpost_08_10_pfe tpost_11_18_pfe, seed(2020) cluster(ward_2003) bootcluster(ward_2003) null(. .) reps(500)
	restore
	
	//Table A.8 - Here with cluster robust inference, the paper also shows results for Conley/RI, which require village coordinates (see comment above)
	eststo, prefix(TableA8): reghdfe	`depvar' /// 
									c.post_08_10#c.treat_eligible									c.post_11_18#c.treat_eligible ///
									c.post_08_10#c.treatment_2		c.post_08_10#c.treatment_2t5 	c.post_11_18#c.treatment_2	 c.post_11_18#c.treatment_2t5 ///
									c.post_08_10#c.eligible 										c.post_11_18#c.eligible ///
									c.post_08_10#c.e_2				c.post_08_10#c.e_2t5			c.post_11_18#c.e_2			 c.post_11_18#c.e_2t5  ///
			if high_forest==1 & eligible==1 ///
			, cluster(village) a(village ward_2003#year) 
			
			
			
	//Table A.11
	eststo, prefix(TableA11): reghdfe	`depvar' /// 
								c.post_08_10#c.treatment 		c.post_11_18#c.treatment ///
								c.post_08_10#c.treatment#c.pvillh_droad2 c.pvillh_droad2#c.post_08_10 ///
								c.post_11_18#c.treatment#c.pvillh_droad2 c.pvillh_droad2#c.post_11_18 ///
								c.post_08_10#c.treatment#c.pvillh_popu c.pvillh_popu#c.post_08_10 ///
								c.post_11_18#c.treatment#c.pvillh_popu c.pvillh_popu#c.post_11_18 ///
								c.post_08_10#c.treatment#c.pvillh_elf c.pvillh_elf#c.post_08_10 ///
								c.post_11_18#c.treatment#c.pvillh_elf c.pvillh_elf#c.post_11_18 ///
									if high_forest==1 & eligible==1 ///
			, cluster(village) a(village ward_2003#year) 
											
	//Table A.12
	eststo, prefix(TableA12): reghdfe	`depvar' /// 
								c.post_08_10#c.(cddpshare_2_nonagric cddpshare_2_agric cddpshare_2_unmatched) c.post_11_18#c.(cddpshare_2_nonagric cddpshare_2_agric cddpshare_2_unmatched) ///
									if high_forest==1 & eligible==1	 ///
			, cluster(village) a(village ward_2003#year) 
		
	
	//trends test
	eststo, prefix(TableA15): reghdfe `depvar'   c.treatment#c.year  if high_forest==1 & eligible==1 & year<2008 ///
						, cluster(village) a(village ward_2003#year) 
}

//Table 1
esttab doublelasso* spill*,keep(*#*treat*) p(3) b(3) //Cluster-robust inference yields marginally different results than Conley/RI, which rely on the village coordinates. 
//Tables 2 and A9 A10
esttab hetero*, p(2) keep(*treat*) b(3) compress
//Appendix Tables
esttab TableA1_*, keep(*treat*) p(2) b(3)
esttab TableA2*, keep(*treat*) p(2) b(3)
esttab TableA3*, keep(*treat*) p(2) b(3)
esttab TableA4*, keep(*treat*) p(2) b(3)
esttab TableA5*, keep(*treat*) p(2) b(3)
esttab TableA6*, keep(*treat*) p(2) b(3)
esttab TableA7*, keep(*treat* tpost*) p(2) b(3)
esttab TableA8*, keep(*treat*) p(2) b(3) //Cluster-robust inference yields marginally different results than Conley/RI, which rely on the village coordinates. 
esttab TableA11*, keep(*treat*) p(2) b(3)
esttab TableA12*, keep(*2*) p(2) b(3)
esttab TableA15*, keep(*treat*) p(2) b(3)
