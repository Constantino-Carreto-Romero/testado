/*===========================================================================
project:      Salarios de reserva
Author:       Francisco Zazueta, Jorge Pérez Pérez
Program Name: est_heckman_v06_20230512.do
Dependencies: Banxico
---------------------------------------------------------------------------
Creation Date:      
Modification Date:  2023/12/05 (Jorge)
version: 06             
References:           
Output:             

---------------------------------------------------------------------------

Estima salarios de reserva con modelo de selección usando datos de la ENOE

---------------------------------------------------------------------------

Change log:

2023/12/05	Jorge revisa y organiza

===========================================================================*/

* Loop sobre archivos de la ENOE

foreach z of numlist 2006 2012 2018 {
*foreach z of numlist 2022{
	*loc z = 2022

	/*=========================================================================
							1: Importar datos
	===========================================================================*/

	clear
	cd "\\Bmdgiesan\dgiesan\PROYECTOS\DASPERI\Salarios de Reserva\Data\Clean"
	use enoe_seleccion_year_menores_var_t.dta if year==`z', clear
	
	
	* Reclasificar algunas localidades como urbanas (Solo para 2022)
	
	destring T_LOC_TRI PAR_C, replace
	
	replace urb=1 if T_LOC_TRI<4 & T_LOC_TRI!=.
	order CD_A ent con V_SEL N_HOG H_MUD N_REN
	
	* Generar indicadores encadenados
	tostring CD_A ent con V_SEL N_HOG H_MUD N_REN,replace
	gen folio_id_1= CD_A+ent+con+V_SEL+N_HOG+H_MUD
	gen folio_id_2= CD_A+ent+con+V_SEL+N_HOG+H_MUD+N_REN
	
	* Volver entidad numérica de nuevo
	
	destring ent, replace
	
	* Generar número de hijos, copiar número de hios a otros miembros del hogar
	
	replace N_HIJ =. if N_HIJ == 99
	
	** ¿Quizás queremos discretizar esto, generar categóricas?
	
	gen N_HIJ_1= N_HIJ
	
	** ¿Si está missing queremos que sea cero?

	order folio_id_1  folio_id_2 sex  PAR_C N_HIJ N_HIJ_1 n_per eda EDA19C


	sort folio_id_1  PAR_C sex


	order folio_id_1  folio_id_2 sex  PAR_C N_HIJ N_HIJ_1  
	
	* Dentro del hogar (folio_id_1), si el hombre jefe tiene missing en hijos, reemplazar con los hios de la siguiente persona en orden de parentesco
	* Se reemplaza así porque generalmente los hijos están asignados a la mujer jefe - esposa
	
	* Códigos version 2019
	* 101 Jefe(a)
	* 201 Esposo(a)
	* 202 Concubina(o) o unión libre
	* 203 Amante o querida(o)
	
	*En 2010 además hay separación:
	
	* 203 Amasio(a)
	* 204 Querido(a)
	
	by folio_id_1: replace N_HIJ_1 = N_HIJ_1[_n+1] if missing(N_HIJ_1) & sex==1 & PAR_C==101 

	by folio_id_1: replace N_HIJ_1 = N_HIJ_1[_n-1] if missing(N_HIJ_1) & sex==1 & PAR_C==201

	by folio_id_1: replace N_HIJ_1 = N_HIJ_1[_n-1] if missing(N_HIJ_1) & sex==1 & PAR_C==202

	by folio_id_1: replace N_HIJ_1 = N_HIJ_1[_n-1] if missing(N_HIJ_1) & sex==1 & PAR_C==203
	
	by folio_id_1: replace N_HIJ_1 = N_HIJ_1[_n-1] if missing(N_HIJ_1) & sex==1 & PAR_C==204

	* Dummy de hijos
	
	
	* Edad de los hijos y menores
	
	by folio_id_1: egen eda_hijos_min= min(cond((PAR_C>=301 & PAR_C<=304),eda,.)) 
	by folio_id_1: egen eda_hijos_mean= mean(cond((PAR_C>=301 & PAR_C<=304),eda,.)) 

	*padres o jefes del hogar
	replace eda_hijos_min=   cond(PAR_C==101 | PAR_C==201 | PAR_C==202 | PAR_C==204, eda_hijos_min, .) 

	*padres o jefes del hogar
	replace eda_hijos_mean=   cond(PAR_C==101 | PAR_C==201 | PAR_C==202 | PAR_C==204, eda_hijos_mean, .) 


	gen eda_hijos = .
	replace eda_hijos = 4 if eda_hijos_min>=15 & eda_hijos_min<=18
	replace eda_hijos = 3 if eda_hijos_min>=11 & eda_hijos_min<15
	replace eda_hijos = 2 if eda_hijos_min>=5 & eda_hijos_min<11
	replace eda_hijos = 1 if eda_hijos_min<5
	
	order folio_id_1  folio_id_2 sex  PAR_C N_HIJ N_HIJ_1 n_per eda EDA19C eda_hijos_min eda_hijos_mean  eda_hijos
	
	replace N_HIJ = 0 if missing(eda_hijos_min)
	replace N_HIJ_1 = . if missing(eda_hijos_min)
	
	gen d_hij= 1 if eda_hijos_min>=0 & !missing(eda_hijos_min)
	replace d_hij=0 if missing(d_hij)
	*gen d_hij= 1 if eda_hijos_min>=1 & !missing(eda_hijos_min)

	gen hij_menor_12 = 1 if eda_hijos_min<13
	replace hij_menor_12 = 0 if missing(hij_menor_12)

	gen hij_menor_5 =1 if eda_hijos_min<5
	replace hij_menor_5 = 0 if missing(hij_menor_5)
	
	* Experiencia
	
	replace exp = 0 if exp<0
	cap drop exp2
	gen exp2 = exp*exp
	gen exp3 = exp2*exp
	gen exp4 = exp2*exp2
	
	* Limpiar años de educación 
	
	replace ANIOS_ESC = . if ANIOS_ESC == 99
	gen esc2 = ANIOS_ESC*ANIOS_ESC
	
	
	
	/*=========================================================================
							2: Estimar modelo de selección
	===========================================================================*/
	
	** lnwrimputado ya tiene imputación de missing values
	* Salario mensual
	
	* Quitar 1% de colas
	su lnwrimputado, d
	drop if (lnwrimputado<r(p1) | lnwrimputado>r(p99)) & (lnwrimputado!=.)
	
	gen d_ing_imputado= .
	replace d_ing_imputado=1  if aux_inc7c > 0 & !missing(aux_inc7c)
	
	* Restringir horas trabajadas
	gen emp = (lnwrimputado !=.)
	drop if emp & !inrange(hrsocup,30,60) 
	
	
	
	
	* restricción adicional: no incluir a los imputados 
	
	drop if d_ing_imputado==1
	
	*restringir edad
	drop if EDA12C==0 | EDA12C==12
			
	* Instrumento: hijos menores interactuado con jefe
	
	glo xr "i.jefe##i.(hij_menor_12 hij_menor_5)"	
	
	*glo xor "exp exp2 exp3 exp4 ANIOS_ESC esc2 i.parent_educa i.jefe i.ent i.urb i.EDA12C#c.(ANIOS_ESC esc2)"
	
	*prueba 
	*xi i.EDA12C|ANIOS_ESC, prefix(_ea)
	*xi i.EDA12C|esc2, prefix(_ee)
	
	*ultima prueba
	*glo xor "exp exp2 exp3 exp4 ANIOS_ESC esc2 i.parent_educa i.jefe i.ent i.urb _eaEDAX* _eeEDAX*"
	
	gen edadrange = .
	replace edadrange = 1 if inrange(eda,15,19)
	replace edadrange = 2 if inrange(eda,20,24)
	replace edadrange = 3 if inrange(eda,25,29)
	replace edadrange = 4 if inrange(eda,25,29)
	replace edadrange = 5 if inrange(eda,30,34)
	replace edadrange = 6 if inrange(eda,35,39)
	replace edadrange = 7 if inrange(eda,40,44)
	replace edadrange = 8 if inrange(eda,45,49)
	replace edadrange = 9 if inrange(eda,50,54)
	replace edadrange = 10 if inrange(eda,55,59)
	replace edadrange = 11 if inrange(eda,60,64)
	
	*glo xor "exp exp2 exp3 exp4 ANIOS_ESC esc2 i.parent_educa i.jefe i.ent i.urb i.edadrange#c.(ANIOS_ESC esc2)"
	
	*cambios:
	* 1 quitamos parent_educa porque no refleja educación del padre  
	glo xor "exp exp2 exp3 exp4 ANIOS_ESC esc2 i.jefe i.ent i.urb i.edadrange#c.(ANIOS_ESC esc2)"
	
	*glo xr "i.jefe##i.(hij_menor_12 hij_menor_5)"	
	*glo xor2 "exp exp2 exp3 exp4 ANIOS_ESC esc2 i.parent_educa i.jefe i.ent i.urb"
	
	
	* Sospechas de errores
	
	gen shouldbeins = (between15_and_64==1 & sex==2)
	tab exp if shouldbeins, m
	*muted by Constantino to not to interrump flow 
	br eda ANIOS if shouldbeins & exp == .
	*muted by Constantino because s in not defined yet
	*tab ANIOS if s
	tab parent_educa if shouldbeins, m
	
	
	
		
	*original
	heckman lnwrimputado $xor $xo if between15_and_64==1 & sex==2 [fw=fac], select($xr $xor) vce(robust)
	
	*última prueba
	*heckman lnwrimputado $xor $xo if between15_and_64==1 & sex==2 [fw=fac], select($xr $xor) vce(robust) diff 
	
	*heckman lnwrimputado $xor2 $xo if between15_and_64==1 & sex==2 [fw=fac], select(i.jefe##i.(hij_menor_12 hij_menor_5) $xor2) vce(robust)

	
	
	est store heckman
	di e(sigma)
	gen s = e(sample)
	*muted by Constantino
	*loc z = 2006	
	
	est save "\\Bmdgiesan\dgiesan\PROYECTOS\DASPERI\Salarios de Reserva\Ster\Heckman y Frontera\heckman_women_ivhijosmenores_`z'.ster", replace
	
	**************** Predecir los salarios para el "structural probit" de la segunda etapa
		
	est restore heckman
	
	predict what
	predict whatcond, ycond
	
	* Fijar f
	
	glo f = 0.94	
	
	* Kiefer and Neumann estimate
	
	* glo f = 0.946
	
	***** Probit para obtener sigma
	
	
	*WARNING: en lugar del probit para 2022, se 
	*1.- usa coeficiente del probit 2018
	*2.- media geométrica de los coeficientes de 2006, 2012, 2018
	
	*original
	probit emp what $xr $xor if between15_and_64==1 & sex==2 [fw=fac]
		
	*probit emp what $xr $xor if between15_and_64==1 & sex==2 [fw=fac], diff tech(nr 10 bfgs 10)
	
	*ultima prueba
	*probit emp what $xr exp exp2 exp3 exp4 ANIOS_ESC esc2 i.parent_educa i.jefe i.ent i.urb _eeEDAXesc2_1-_eeEDAXesc2_11 _eaEDAXANIO_1-_eaEDAXANIO_11 if between15_and_64==1 & sex==2 [fw=fac]
	est sto probit
	
	*muted by Constantino
	*loc z = 2006	
	est save "\\Bmdgiesan\dgiesan\PROYECTOS\DASPERI\Salarios de Reserva\Ster\Heckman y Frontera\probit2nd_women_ivhijosmenores_`z'.ster", replace
	
	*original 
	glo sigmahat = (1-$f)/_b[what]
	di $sigmahat
	
	
	***************** Estimación de salario de reserva
	
	* Esta usa los del probit de la segunda etapa - no estoy sacando se porque salen de dos ecuaciones
	
	gen bor_times_xor = 0
	gen wbor_times_xor = 0
	
	fvexpand $xor if between15_and_64==1 & sex==2
	glo xorexp = r(varlist)	

		
	foreach x in $xorexp {
		qui {
			est restore probit
			replace bor_times_xor = bor_times_xor-_b[`x']*`x'
			est restore heckman
			replace wbor_times_xor = wbor_times_xor + [lnwrimputado]_b[`x']*`x'
		}
	}
		
	fvexpand ${xr} if between15_and_64==1 & sex==2
	glo xrexp = r(varlist)
		
	est restore probit
	gen br_times_xr = 0 
	foreach x in $xrexp {
		replace br_times_xr = br_times_xr-_b[`x']*`x'
	}
		
	est restore probit
	gen selectcons = _b[_cons]
		
	est restore heckman
	gen heckmancons = [lnwrimputado]_b[_cons]
		
	gen wrhat = br_times_xr*${sigmahat`i'} + bor_times_xor*${sigmahat`i'} + wbor_times_xor*$f - selectcons*${sigmahat`i'} + heckmancons*$f if between15_and_64==1 & sex==2
		
	drop bor_times_xor wbor_times_xor br_times_xr selectcons heckmancons		
		
	
	
	su lnwrimputado if s [fw=fac]
	
	
	su what if s [fw=fac]
	su what if emp & s [fw=fac]
	su what if !emp & s [fw=fac]
	su whatcond if s [fw=fac]
	su whatcond if emp & s [fw=fac]
	su whatcond if !emp & s [fw=fac]
	
	su wrhat if s [fw=fac]
	su wrhat if emp & s [fw=fac]
	su wrhat if !emp & s [fw=fac]
	
	gen part= (what>wrhat)
	
	tab part if emp & s [fw=fac]
	
	tab part if !emp &s [fw=fac]
	
	gen miss = (wrhat>lnwrimputado)
	
	tab miss if emp & s [fw=fac]
	
	
	***added by Constantino 
	*guardar solo observaciones de la muestra de estimación 
	keep if s 
	*guardar variables de interes
	*keep folio_id_1 folio_id_2 emp g_estudios lnwrimputado what whatcond wrhat fac EDA12C
	
	keep folio_id_1 folio_id_2 emp g_estudios lnwrimputado what whatcond wrhat fac EDA12C N_HIJ eda EDA19C g_estudios a_escolaridad salario ANIOS_ESC urb jefe casado exp edadrange s
	lab var emp "empleado"
	lab var g_estudios "grado de estudios"
	lab define g_est 0 "Ninguno" 1 "Preescolar" 2 "Primaria" 3 "Secundaria" 4 "Preparatoria" 5 "Normal" 6 "carrera técnica" 7 "Profesional" 8 "Maestría" 9 "Doctorado" 99 "No sabe"
	lab values g_estudios g_est
	tab g_est, miss
	*muted by constantino
	save "\\Bmdgiesan\dgiesan\PROYECTOS\DASPERI\Salarios de Reserva\Data\Clean\base_sal_reserva_`z'.dta", replace 
	
	
 }
	
	
	
	
	
	
	glo bw = 0.1
 
	kdensity lnwrimputado if s [fw=fac], gen(w_d_x w_d_y) bw($bw)
	kdensity what if s [fw=fac], gen(what1_d_x what1_d_y) bw($bw)
	kdensity what if s & !emp [fw=fac], gen(what_noemp_d_x what_noemp_d_y) bw($bw)
	kdensity wrhat if s & emp [fw=fac], gen(wrhat_emp_d_x wrhat_emp_d_y) bw($bw)
	kdensity wrhat if s & !emp [fw=fac], gen(wrhat_noemp_d_x wrhat_noemp_d_y) bw($bw)
	kdensity whatcond if s [fw=fac], gen(whatcond_d_x whatcond_d_y) bw($bw)
	kdensity whatcond if s & !emp [fw=fac], gen(whatcond_noemp_d_x whatcond_noemp_d_y) bw($bw)
	
	tw (line w_d_y w_d_x) (line wrhat1_emp_d_y wrhat1_emp_d_x), legend(label(1 "Reserva empleados") label(2 "Observado"))
	tw (line wrhat_emp_d_y wrhat_emp_d_x) (line wrhat_noemp_d_y wrhat_noemp_d_x), legend(label(1 "Reserva empleados") label(2 "Reserva no empleados"))
	tw (line what_noemp_d_y what_noemp_d_x) (line wrhat_noemp_d_y wrhat_noemp_d_x) , legend(label(1 "Predicho") label(2 "Reserva no empleados"))

	tw (line whatcond_noemp_d_y whatcond_noemp_d_x) (line wrhat_noemp_d_y wrhat_noemp_d_x) , legend(label(1 "Predicho") label(2 "Reserva no empleados"))
	
	
 * }
