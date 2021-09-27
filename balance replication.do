cd "D:\Dropbox\Gambia\Gambia Forest Project\Draft\replication\Replication Files"
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
