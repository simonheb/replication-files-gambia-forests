/*******************************************************************************
Replication do-file for:    Appendix Table C.14
Paper:                      Heß, Schündeln, Jaimovich: "Environmental effects of
                            development programs: Experimental evidence from
                            West African dryland forests."
Journal:                    Journal of Development Economics
Contact:                    Simon Heß (hess@econ.uni-frankfurt.de)
Required packages:          estout
Date:                       2021-09-27
Comments:                   This do-file replicates results from the summary
							Table C.14, including balance tests.
 *******************************************************************************/

use "Village Panel.dta", clear
keep if year==2001 & kombo==0 & high_forest==1 & eligible==1
		
		
foreach var of varlist ///
lbs_1KM lbs_5KM lbs_poly suml_ll01_1KM suml_ll01_5KM suml_ll01_poly ///
pvillh_droad2 pvillh_popu pvillh_pover pvillh_elf ///
dist_river totalcount1km e_1 total5km e_5 area_2010ha ///
popu pover elf ethprop_0 ethprop_1 ethprop_2 ethprop_3 share_migrant ///
{
	eststo,prefix(bal): areg `var' treatment, cluster(village) a(ward_2003)
}

esttab bal* using balance.csv, p
