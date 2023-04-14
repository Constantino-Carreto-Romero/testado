/*===========================================================================
project:      Select lag order in equation 10 of Morales & Lobo 2021
Author:       Constantino Carreto Romero 
Program Name: seleccion de rezagos
Dependencies:  
---------------------------------------------------------------------------
Creation Date:      Jan 19, 2023 
Modification Date:    April 13, 2023
version:              
References:           
Output:             seleccion de rezagos.do
===========================================================================*/

/*=========================================================================
                         0: Program Setup
===========================================================================*/
* Program Setup
version 12.1
drop _all

*project folder
glo vacantes "\\Bmdgiesan\DGIESAN\PROYECTOS\DASPERI\Vacantes"

*data folder 
glo data "$vacantes\Data"
*tables
glo tables "$vacantes\Tables"
*Logfiles
glo log "$vacantes\Logfiles"
*figures
glo figures "$vacantes\Figures"



*directorio propio
glo vacantes "S:\vacantes"
*data folder 
glo data "$vacantes\data"
*tables
glo tables "$vacantes\tables"
*Logfiles
glo log "$vacantes\log"
*figures
glo figures "$vacantes\figures"


*programs
*para estilo de las gráficas 
cap ssc install schemepack, replace

capture log close
log using "$log/seleccion de rezago con restriccion de desigualdad _sin_outsourcing v4.txt", replace text


/*=========================================================================
        1: Parametros preliminares 
===========================================================================*/
/*dataset must contain these variables:
T : time variable with format Month-Year
eo : Number of employees
h: hirings
s: separations
idN: firm id
*/

/*
*example dataset provided by Morales & Lobo
use "$data/fakedata.dta", clear
*/
**************** base de datos *************

*cargar base de datos y renombrar variables
use "$data/panel_registros_sin_outsourcing.dta", clear
renvars fecha llave_empresa contrat separac trabjd_t1 \ T idN h s eo
lab var idN "firm id"
lab var h "hirings"
lab var s "separations"
lab var eo "employment"
tempname panel
save `panel', replace 

******************** parametros preliminares 
****** maximum number of lags to check
glo lo =15
****** specify significance criteria
loc sign 0.05


**********************************************************************************
* 2. Estimar usando diferentes periodos 
*Cargar base a usar y restringir al periodo a usar. Definir matrices a llenar con valores de interés 
********************************************************************************	

*to mark the sample to use throught 
tempvar touse	

*para analizar diferentes periodos, indicar inicio y final de cada periodo a analizar
*inicio de periodos
local inip "2017 2017 2017 2017 2018"
*final del periodo 
local finp "2019 2020 2021 2022 2022"

local n : word count `inip'
forvalues i=1/`n'{
		local a : word `i' of `inip'
		local b : word `i' of `finp'
  
	
		di in red "****************************************"
		di in red  "***** periodo de `a' a `b' *******"
		di in red "*****************************************"
		
		*load IMSS dataset 
		use `panel', clear
		
		*restringir muestra al intervalo de años indicado 
		keep if T>=ym(`a',1) & T<=ym(`b',12)

		*specify panel and time variables
		xtset, clear
		xtset idN T
		xtset 
		sort idN T

		*matriz para llenar con: AIC, BIC, suma de thetas e indicador de si no se pudo checar significancia de algún rezago 
		matrix mat_ic = J($lo,7,.)
		mat colnames mat_ic = max_lag AIC BIC sum_thetas sum_se sum_p no_check 

		*id of models with best AIC & BIC
		*iniciarlos igual a cero 
		loc aic_start=0
		loc bic_start=0


		************************************************************************
		*			3: start the iteration
		************************************************************************

		*********** iterate with different lag order 
		forv l=1/$lo{
			di "**************************************"
			display as text "last lag order is = " as result "`l'"
			di "**************************************"
			
			****** first estimate with reghdfe to obtain right degrees of freedom and mark the sample for demeaning 
			sort idN T
			qui eststo reghdfe1: reghdfe h cL(0/`l').s, absorb(idN T) nocons
			loc df=e(df_r)
			cap drop `touse'
			mark `touse' if _est_reghdfe1==1  
			loc variables ""	
				
				
			*demean h and s
			local vars "h s"
			foreach x of local vars{
				tempvar  `x'fm `x'ym `x'd
				qui bys idN: egen ``x'fm'=mean(`x') if `touse'
				qui bys T: egen ``x'ym'=mean(`x') if `touse'
				qui gen ``x'd'=`x'-``x'fm'-``x'ym'
				loc variables `variables' ``x'd'
			}
			
			*demean lags de s y contruir elementos de la ecuacion de regresion no lineal 
			loc restrict ""
			loc restrict_coefs ""
			forvalues k=1/`l'{
				tempvar L`k's  L`k'sfm L`k'sym L`k'sd
				sort idN T
				qui gen `L`k's'=L`k'.s
				qui bysort idN: egen `L`k'sfm'=mean(`L`k's') if `touse'
				sort T
				qui bysort T: egen `L`k'sym'=mean(`L`k's') if `touse'
				qui gen `L`k'sd'=`L`k's'-`L`k'sfm'-`L`k'sym'
				loc variables `variables' `L`k'sd'
				loc restrict `restrict' -invlogit({l`k'})
				loc restrict_coefs  `restrict_coefs' +invlogit({l`k'})*`L`k'sd'
			}
			
			*variables para la regresión
			*di "variables: `variables'"
			
			*definir ecuacion de la regresión no lineal 
			loc nlreg ""
			loc nlreg "`hd' = (invlogit({suma}) `restrict')*`sd' `restrict_coefs'"
			*di "`nlreg'"



			**** estimate equation 10: regress hirings on lags of separations
			*regresión con variables demeaned 
			di in red "regresión con lag order `l'"
			nl (`nlreg'), nolog  nocons cluster(idN)
			estimates store r`l'
			*to-do: if some standard error is not reported, should use bootstrap to compute it. but it increases estimation time. This seems to happen when using high lag orders:
			*nl (`nlreg'), nolog nocons vce(boot)
			*see: https://www.stata.com/statalist/archive/2006-03/msg01048.html
		
			
			***** check if all coefficients are signficant
			loc all_sign=1
			loc no_check=0
			loc thetas=0
			loc thetas_resta ""
			loc coef_indiv ""
			*check significance of each coefficient
			forv c=1/`l'{
				estimates restore r`l'
				
				loc coef_indiv `coef_indiv' (l`c':invlogit(_b[l`c':_cons]))
				
				di "checking significance of lag l`c'"
				*quitar transformacion al coeficiente y usar grados de libertad correctos
				cap noisily nlcom (l`c':invlogit(_b[l`c':_cons])), df(`df')
				if _rc {
					loc no_check=1
					continue
				}
				
				*construir local con nombres de thetas a restar de la suma de thetas para conocer el coeficiente contemporaneo
				loc thetas_resta `thetas_resta' - invlogit(_b[l`c':_cons])
				
				*calcular p-value y checar significancia 
				matrix b =r(b)
				matrix V =r(V)
				loc std_err = sqrt(V[1,1])
				loc  z = b[1,1]/`std_err'
				loc lag_p=2*normal(-abs(`z'))
				if (!missing(`lag_p') & (`lag_p'>`sign')) loc all_sign=0
				
				*agregar coeficiente a la suma de coeficientes 
				loc theta = b[1,1]
				loc thetas=`thetas'+`theta'
			}
			if `all_sign'==0 di "Some Lag's coefficient is not signficant"
			
			** obtener coeficiente contemporaneo 
			estimates restore r`l'
			cap noisily nlcom (l0:invlogit(_b[suma:_cons]) `thetas_resta'), df(`df')
			if !_rc {
				matrix b =r(b)
				loc theta = b[1,1]
				loc thetas=`thetas'+`theta'
			}
			else{
				loc no_check=1
			}
			
			*conocer error estandar de pi = suma the thetas (comtemporaneo + rezagos)  
			estimates restore r`l'
			cap noisily nlcom (l0:invlogit(_b[suma:_cons])), df(`df')
			matrix sum_b=r(b)
			matrix sum_se=r(V)
			loc sum_se=sqrt(sum_se[1,1])
			loc  sum_z = sum_b[1,1]/`sum_se'
			loc sum_p=2*normal(-abs(`z'))
			
			
			*agregar suma de thetas a la matriz de resultados
			mat mat_ic[`l',4]=`thetas'
			
			*agregar error estandar y p-value de suma de thetas 
			mat mat_ic[`l',5]=`sum_se'
			mat mat_ic[`l',6]=`sum_p'
			
			*indicar si no se pudo checar significancia para algún coeficiente 
			mat mat_ic[`l',7]=`no_check'
			
			*mostrar todos los coeficientes
			di "regresion sin transformacion"
			eststo rst`l': cap noisily nlcom (l0:invlogit(_b[suma:_cons]) `thetas_resta') `coef_indiv', df(`df') post
			
			**** stop iteration if the last coefficient is not significant 
			loc lastl_p=`lag_p'
			if (!missing(`lastl_p') & (`lastl_p'>`sign')) {
				loc last_lag_o= `l'-1
				di "when iterating with lag order `l', the last lag coefficient is not significant."	
				continue, break
			}

			
			****** compute AIC & BIC if all coeficients were significant. Save IC
			if `all_sign'==1 & `no_check'==0 {
				estimates restore r`l'
				estat ic 

				mat A=r(S)
				loc AIC=A[1,5]
				loc BIC=A[1,6]
				mat mat_ic[`l',1]=`l'
				mat mat_ic[`l',2]=round(`AIC')
				mat mat_ic[`l',3]=round(`BIC')
			}
		}

		*show matrix with AIC & BIC 
		mat li mat_ic

		***** Say which model has the best AIC & BIC
		cap drop max_lag AIC BIC sum_thetas sum_se sum_p no_check 
		svmat double mat_ic, names(col)

		tempvar min_AIC min_BIC best_lag_aic best_lag_bic
		egen double `min_AIC'=min(AIC)
		egen double `min_BIC'=min(BIC)

		gen `best_lag_aic' = max_lag if `min_AIC'==AIC
		gen `best_lag_bic' = max_lag if `min_BIC'==BIC

		egen  best_lag_aic =max(`best_lag_aic') if !missing(max_lag)
		egen  best_lag_bic =max(`best_lag_bic') if !missing(max_lag)




		preserve 
		keep max_lag AIC BIC best_lag_aic best_lag_bic sum_thetas sum_se sum_p no_check 
		order max_lag AIC BIC best_lag_aic best_lag_bic sum_thetas sum_se sum_p no_check
		keep if !missing(max_lag)
		list
		export delimited using "$tables/seleccion_de_rezago_con_restriccion_de_desigualdad_periodo_`a'_`b'_sin_outsourcing.csv", replace 
		
		*guardar en excel regresion del mejor rezago 
		sum best_lag_bic
		loc bestl=r(mean)
		estimates restore rst`bestl'
		cd $tables
		cap erase regresion_del_rezago_optimo_`a'_`b'_sin_outsourcing_v4.csv
		esttab rst`bestl' using regresion_del_rezago_optimo_`a'_`b'_sin_outsourcing_v4.csv, replace ar2 p label
		
		
		
		restore
		

}



log close 






*------------------------ 1.1: <Describe> ----------------------------------

*------------------------ 1.2: <Describe> ----------------------------------


/*=========================================================================
                         2: <Describe>
===========================================================================*/

*------------------------ 2.1: <Describe> ----------------------------------

*------------------------ 2.2: <Describe> ----------------------------------

