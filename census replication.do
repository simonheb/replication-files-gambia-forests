version 13
set matsize 4000
cd "D:\Dropbox\Gambia\Gambia Forest Project\Draft\replication\Replication Files"
do "rerandomize.ado"

use "census2013.dta", clear

eststo, prefix(hf):	areg  zscore_assets_hf 	treatment pop_new PovertyIndex if high_forest==1 	[pweight=vweight_hf]	, cluster(village) absorb(ward_2003)
eststo, prefix(hf): areg  zscore_animals_hf treatment pop_new PovertyIndex if high_forest==1 	[pweight=vweight_hf]	, cluster(village) absorb(ward_2003)
eststo, prefix(hf): areg  firewood 			treatment pop_new PovertyIndex if high_forest==1 	[pweight=vweight_hf]	, cluster(village) absorb(ward_2003)
eststo, prefix(hf): areg  novillage_share 	treatment pop_new PovertyIndex if high_forest==1 	[pweight=vweight_hf]	, cluster(village) absorb(ward_2003)
eststo, prefix(hf): areg  child 			treatment pop_new PovertyIndex if high_forest==1 	[pweight=vweight_hf]	, cluster(village) absorb(ward_2003)
eststo, prefix(hf): areg  vsize 			treatment pop_new PovertyIndex if high_forest==1							, cluster(village) absorb(ward_2003)
eststo, prefix(all): areg zscore_assets 	treatment pop_new PovertyIndex 						[pweight=vweight_all]	, cluster(village) absorb(ward_2003)
eststo, prefix(all): areg zscore_animals 	treatment pop_new PovertyIndex 						[pweight=vweight_all]	, cluster(village) absorb(ward_2003)
eststo, prefix(all): areg firewood 			treatment pop_new PovertyIndex 						[pweight=vweight_all]	, cluster(village) absorb(ward_2003)
eststo, prefix(all): areg novillage_share 	treatment pop_new PovertyIndex 						[pweight=vweight_all]	, cluster(village) absorb(ward_2003)
eststo, prefix(all): areg child 			treatment pop_new PovertyIndex 						[pweight=vweight_all]	, cluster(village) absorb(ward_2003)
eststo, prefix(all): areg vsize 			treatment pop_new PovertyIndex												, cluster(village) absorb(ward_2003)


esttab hf* using census.csv, drop(pop_new PovertyIndex) p replace
esttab all* using census.csv, drop(pop_new PovertyIndex) p append
