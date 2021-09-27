
cap program drop rerandomize
program rerandomize
        syntax , ///
        resampvar(varname) ///<- name of the resampling variable
        stratvar(varname) ///<- name of the strata variable
        clustvar(varname) ///<- name of the cluster variable
        * //<- ritest also passes other things to the permutation procedure
		
		//also use eligibility for stratification (exclude missing treatments)
		tempvar truestrat inelig
		gen `inelig' = missing(`resampvar')
		egen `truestrat' = group(`stratvar' `inelig')

		
		tempvar mr r mr2
		sort  `truestrat' `clustvar'

        qui by `truestrat' `clustvar': gen `r'=rnormal() if _n==1 // draw one random variable per cluster

        qui by `truestrat': egen `mr' = median(`r') if !missing(`r') //compute median of these random variables within strata
		replace `resampvar' = cond(`r',(`r'>=`mr') ,.,.) // replace the permutation var with  the new randomization outcome, ties in favor of treatment

		by `truestrat' `clustvar': replace `resampvar' = `resampvar'[_n-1]  if missing(`resampvar')
		replace `resampvar'=. if `inelig'
end
