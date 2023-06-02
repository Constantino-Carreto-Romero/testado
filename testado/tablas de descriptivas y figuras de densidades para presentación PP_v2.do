/*===========================================================================
project:      Gráficas y descriptivas para presentación PP 
Author:       Francisco Zazueta, Constantino Carreto 
Program Name: 
Dependencies: Banxico
---------------------------------------------------------------------------
Creation Date:      
Modification Date:  2023/23/05 
version: 01            
References:           
Output:             

---------------------------------------------------------------------------

Gráficas y descriptivas para presentación PP del 23 de mayo
Para 2022, se usa versión que imputa sigma con el valor del 2018
---------------------------------------------------------------------------

Change log:



===========================================================================*/
* ssc install tabstat2excel , replace

version 16.0 //with version 14.0 putexcel genera un error "option names not allowed"

gl carpeta "\\Bmdgiesan\dgiesan\PROYECTOS\DASPERI\Salarios de Reserva"
gl codigo "$carpeta/Code"
gl datos "$carpeta/Data"
gl figuras "$carpeta/Fig"
gl tablas "$carpeta/Tables"

cap project, doinfo
if _rc {
	capture log close
	log using "$codigo/Est/Heckman y Frontera/tablas de descriptivas y figuras de densidades para presentación PP_v2.txt", replace text
	loc pr=0
}
else {
	loc pr=1
	project, uses("$datos\Clean\base_sal_reserva_real_what2018.dta")	
}




******************************************************************************************
************* Preparar datos para tablas y gráficas  ********************************************
******************************************************************************************

use "$datos\Clean\base_sal_reserva_real_what2018.dta", clear

*crear dummies para niveles edcativos
cap drop _ge*
xi i.g_estudios2, prefix(_ge_) noomit
renvars _ge_g_estud_11 _ge_g_estud_12 _ge_g_estud_13 _ge_g_estud_14 _ge_g_estud_15 \ m_prepa prepa normal licen posgrado
lab var m_prepa "menor a preparatoria"
lab var prepa "preparatoria"
lab var normal "normal o carrera técnica"
lab var licen "licenciatura"
la var posgrado "maestría o doctorado"

gen lic_o_mas=inlist(g_estudios2,14,15)
gen menor_lic=inlist(g_estudios2,11,12,13)


lab var lnwrimputado_exp "salario nominal en pesos"
lab var lnwrimputado_real "salario real en pesos"


*bandwith para gráficas de densidades
glo bw = 0.1


******************************************************************************************
************* Tablas  ********************************************
******************************************************************************************

************* tabla: estadisticas de variables continuas y discretas. Pool de años y por año *********************

*variables continuas
tabstat eda a_escolaridad exp [aw=fac], by(año) stat(mean sd p25 p50 p75) save
putexcel set "$tablas\Heckman\estadisticas_vars_continuas.xlsx", replace
matrix m2006 = r(Stat1)
matrix m2012 = r(Stat2)
matrix m2018 = r(Stat3)
matrix m2022 = r(Stat4)
matrix mtodos = r(StatTotal)
putexcel A1 = matrix(m2006), names
putexcel A7 = matrix(m2012), names
putexcel A13 = matrix(m2018), names
putexcel A19 = matrix(m2022), names
putexcel A25 = matrix(mtodos), names

/*
*variables discretas
tabstat m_prepa prepa normal licen posgrado jefe urb [aw=fac], by(año) stat(mean) save 
putexcel set "\\Bmdgiesan\dgiesan\PROYECTOS\DASPERI\Salarios de Reserva\Tables\Heckman\estadisticas_vars_discretas.xlsx", replace
matrix m2006 = r(Stat1)
matrix m2012 = r(Stat2)
matrix m2018 = r(Stat3)
matrix m2022 = r(Stat4)
matrix mtodos = r(StatTotal)
putexcel A1 = matrix(m2006), names
putexcel A3 = matrix(m2012), names
putexcel A5 = matrix(m2018), names
putexcel A7 = matrix(m2022), names
putexcel A9 = matrix(mtodos), names
*/

*variables discretas
tabstat menor_lic lic_o_mas jefe urb [aw=fac], by(año) stat(mean) save 
putexcel set "$tablas\Heckman\estadisticas_vars_discretas.xlsx", replace
matrix m2006 = r(Stat1)
matrix m2012 = r(Stat2)
matrix m2018 = r(Stat3)
matrix m2022 = r(Stat4)
matrix mtodos = r(StatTotal)
putexcel A1 = matrix(m2006), names
putexcel A3 = matrix(m2012), names
putexcel A5 = matrix(m2018), names
putexcel A7 = matrix(m2022), names
putexcel A9 = matrix(mtodos), names


************* tabla: estadisticas de salario nominal y salario real por año *********************

tabstat lnwrimputado_exp lnwrimputado_real [aw=fac], by(año) stat(mean sd p25 p50 p75) save 
putexcel set "$tablas\Heckman\estadisticas_salario_nominal_real.xlsx", replace
matrix m2006 = r(Stat1)
matrix m2012 = r(Stat2)
matrix m2018 = r(Stat3)
matrix m2022 = r(Stat4)
matrix mtodos = r(StatTotal)
putexcel A1 = matrix(m2006), names
putexcel A7 = matrix(m2012), names
putexcel A13 = matrix(m2018), names
putexcel A19 = matrix(m2022), names
putexcel A25 = matrix(mtodos), names

************* tabla: estadisticas de salario nominal y salario real por año *********************

*salario nominal vs salario de reserva (empleados-desempleados)
cap drop wrhat_exp_emp wrhat_exp_desemp
gen wrhat_exp_emp=wrhat_exp if emp==1
lab var wrhat_exp_emp "salario de reserva nominal en pesos para empleados"
gen wrhat_exp_desemp=wrhat_exp if emp==0
lab var wrhat_exp_desemp "salario de reserva nominal en pesos para desempleados"
tabstat wrhat_exp wrhat_exp_emp wrhat_exp_desemp [aw=fac], by(año) stat(mean sd p25 p50 p75) save 
putexcel set "$tablas\Heckman\estadisticas_salario_nominal_empleo.xlsx", replace
matrix m2006 = r(Stat1)
matrix m2012 = r(Stat2)
matrix m2018 = r(Stat3)
matrix m2022 = r(Stat4)
matrix mtodos = r(StatTotal)
putexcel A1 = matrix(m2006), names
putexcel A7 = matrix(m2012), names
putexcel A13 = matrix(m2018), names
putexcel A19 = matrix(m2022), names
putexcel A25 = matrix(mtodos), names


*salario real
cap drop wrhat_real_emp wrhat_real_desemp
gen wrhat_real_emp=wrhat_real if emp==1
lab var wrhat_real_emp "salario de reserva real en pesos para empleados"
gen wrhat_real_desemp=wrhat_real if emp==0
lab var wrhat_real_desemp "salario de reserva real en pesos para desempleados"
tabstat wrhat_real wrhat_real_emp wrhat_real_desemp [aw=fac], by(año) stat(mean sd p25 p50 p75) save 
putexcel set "$tablas\Heckman\estadisticas_salario_real_empleo.xlsx", replace
matrix m2006 = r(Stat1)
matrix m2012 = r(Stat2)
matrix m2018 = r(Stat3)
matrix m2022 = r(Stat4)
matrix mtodos = r(StatTotal)
putexcel A1 = matrix(m2006), names
putexcel A7 = matrix(m2012), names
putexcel A13 = matrix(m2018), names
putexcel A19 = matrix(m2022), names
putexcel A25 = matrix(mtodos), names

******************************************************************************************
************* Gráficas  ********************************************
******************************************************************************************

******************************************
* Figura 1                               *
******************************************
foreach z of numlist 2006 2012 2018 2022 {
	cd "$datos\Clean"
	use "base_sal_reserva_real_what2018.dta",clear
	keep if año==`z'
	gen uno = exp(lnwrimputado)
	gen uno_1 = exp(wrhat)
	kdensity lnwrimputado if s & lnwrimputado>=6 [fw=fac], gen(wd_x wd_y) bw($bw) ylab(,angle(0)) graphregion(color(white))   
	kdensity wrhat if s & wrhat>=6 [fw=fac], gen(wrhatd_x wrhatd_y) bw($bw) ylab(,angle(0)) graphregion(color(white))  
	tw (line wd_y wd_x) (line wrhatd_y wrhatd_x), legend(label(1 "Observado") label(2 "Reserva empleados")) title("Salario de reserva, `z'") ylab(,angle(0)) graphregion(color(white)) xlabels( 6 "400" 7 "1,000" 8 "3,000" 9 "8,000" 10 "22,000" 11 "60,000")  ytitle("Densidad") xtitle("Salario")
	cd "$figuras\Figuaras_Presentación_23mayo\Fig1_obs_reserva_nominal"
	graph export  "KD_Salario_de_reserva_y_observado_`z'_Heckman.png", replace  

}

******************************************
* Figura 2                               *
******************************************
clear
cd "$datos\Clean"

use "base_sal_reserva_real_what2018.dta",clear

cd "$figuras\Figuaras_Presentación_23mayo\Fig2_reserva_Heckman_Frontera"

glo bw = 0.1
kdensity wrhat if s & año==2006  & wrhat>=6 [fw=fac], gen(wd_x_06 wd_y_06) bw($bw) ylab(,angle(0)) graphregion(color(white)) 
kdensity wrhat if s & año==2012 & wrhat>=6 [fw=fac], gen(wd_x_12 wd_y_12) bw($bw) ylab(,angle(0)) graphregion(color(white)) 
kdensity wrhat if s & año==2018 & wrhat>=6 [fw=fac], gen(wd_x_18 wd_y_18) bw($bw) ylab(,angle(0)) graphregion(color(white)) 
kdensity wrhat if s & año==2022 & wrhat>=6 [fw=fac], gen(wd_x_22 wd_y_22) bw($bw) ylab(,angle(0)) graphregion(color(white)) 

tw (line wd_y_06 wd_x_06) (line  wd_y_12 wd_x_12) (line  wd_y_18 wd_x_18) (line  wd_y_22 wd_x_22), legend(label(1 "2006") label(2 "2012") label(3 "2018") label(4 "2022")) title("Salario de reserva por año") ylab(,angle(0)) graphregion(color(white)) xlabels( 6 "400" 7 "1,000" 8 "3,000" 9 "8,000" 10 "22,000" 11 "60,000") ytitle("Densidad") xtitle("Salario")
graph export  "KD_Salario_de_reserva_para_los_años_muestra_Heckman.png", replace

drop wd_*

******************************************
* Figura 3                               *
******************************************

clear
cd "$datos\Clean"

use "base_sal_reserva_real_what2018.dta",clear

cd "$figuras\Figuaras_Presentación_23mayo\Fig3_reserva_real"

glo bw = 0.1
kdensity wrhat_real_ln if  año==2006  & wrhat>=6 [fw=fac], gen(wd_x_06 wd_y_06) bw($bw) ylab(,angle(0)) graphregion(color(white)) 
kdensity wrhat_real_ln if  año==2012 & wrhat>=6 [fw=fac], gen(wd_x_12 wd_y_12) bw($bw) ylab(,angle(0)) graphregion(color(white)) 
kdensity wrhat_real_ln if  año==2018 & wrhat>=6 [fw=fac], gen(wd_x_18 wd_y_18) bw($bw) ylab(,angle(0)) graphregion(color(white)) 
kdensity wrhat_real_ln if  año==2022 & wrhat>=6 [fw=fac], gen(wd_x_22 wd_y_22) bw($bw) ylab(,angle(0)) graphregion(color(white)) 

tw (line wd_y_06 wd_x_06) (line  wd_y_12 wd_x_12) (line  wd_y_18 wd_x_18) (line  wd_y_22 wd_x_22), legend(label(1 "2006") label(2 "2012") label(3 "2018") label(4 "2022")) title("Salario de reserva por año") ylab(,angle(0)) graphregion(color(white)) ylab(,angle(0)) graphregion(color(white)) xlabels( 6 "400" 7 "1,000" 8 "3,000" 9 "8,000" 10 "22,000" 11 "60,000")  ytitle("Salarios de reserva") ytitle("Densidad") xtitle("Salario")
graph export  "KD_Salario_de_reserva_para_los_años_muestra_Heckman.png", replace


drop wd_*

******************************************
* Figura 4                               *
******************************************

clear
cd "$datos\Clean"

use "base_sal_reserva_real_what2018.dta",clear

cd "$figuras\Figuaras_Presentación_23mayo\Fig4_reserva_empleados"

glo bw = 0.1
kdensity wrhat_real_ln if s & año==2006  & emp & wrhat>=6 [fw=fac], gen(wd_x_06 wd_y_06) bw($bw) ylab(,angle(0)) graphregion(color(white)) 
kdensity wrhat_real_ln if s & año==2012 & emp & wrhat>=6 [fw=fac], gen(wd_x_12 wd_y_12) bw($bw) ylab(,angle(0)) graphregion(color(white)) 
kdensity wrhat_real_ln if s & año==2018 & emp & wrhat>=6 [fw=fac], gen(wd_x_18 wd_y_18) bw($bw) ylab(,angle(0)) graphregion(color(white)) 
kdensity wrhat_real_ln if s & año==2022 & emp & wrhat>=6 [fw=fac], gen(wd_x_22 wd_y_22) bw($bw) ylab(,angle(0)) graphregion(color(white)) 

tw (line wd_y_06 wd_x_06) (line  wd_y_12 wd_x_12) (line  wd_y_18 wd_x_18) (line  wd_y_22 wd_x_22), legend(label(1 "2006") label(2 "2012") label(3 "2018") label(4 "2022")) title("Salario de reserva por año") ylab(,angle(0)) graphregion(color(white)) ylab(,angle(0)) graphregion(color(white)) xlabels( 6 "400" 7 "1,000" 8 "3,000" 9 "8,000" 10 "22,000" 11 "60,000")  ytitle("Salarios de reserva") ytitle("Densidad") xtitle("Salario")
graph export  "KD_Salario_de_reserva_para_los_años_muestra_Heckman.png", replace


drop wd_*

******************************************
* Figura 5                              *
******************************************

clear
cd "$datos\Clean"

use "base_sal_reserva_real_what2018.dta",clear

cd "$figuras\Figuaras_Presentación_23mayo\Fig5_reserva_desempleados"

glo bw = 0.1
kdensity wrhat_real_ln if s & año==2006  & !emp & wrhat>=6 [fw=fac], gen(wd_x_06 wd_y_06) bw($bw) ylab(,angle(0)) graphregion(color(white)) 
kdensity wrhat_real_ln if s & año==2012 & !emp & wrhat>=6 [fw=fac], gen(wd_x_12 wd_y_12) bw($bw) ylab(,angle(0)) graphregion(color(white)) 
kdensity wrhat_real_ln if s & año==2018 & !emp & wrhat>=6 [fw=fac], gen(wd_x_18 wd_y_18) bw($bw) ylab(,angle(0)) graphregion(color(white)) 
kdensity wrhat_real_ln if s & año==2022 & !emp & wrhat>=6 [fw=fac], gen(wd_x_22 wd_y_22) bw($bw) ylab(,angle(0)) graphregion(color(white)) 

tw (line wd_y_06 wd_x_06) (line  wd_y_12 wd_x_12) (line  wd_y_18 wd_x_18) (line  wd_y_22 wd_x_22), legend(label(1 "2006") label(2 "2012") label(3 "2018") label(4 "2022")) title("Salario de reserva por año") ylab(,angle(0)) graphregion(color(white)) ylab(,angle(0)) graphregion(color(white)) xlabels( 6 "400" 7 "1,000" 8 "3,000" 9 "8,000" 10 "22,000" 11 "60,000")  ytitle("Salarios de reserva") ytitle("Densidad") xtitle("Salario")
graph export  "KD_Salario_de_reserva_para_los_años_muestra_Heckman.png", replace


drop wd_*


******************************************
* Figura 6                               *
******************************************
*************
* Kdensity  *
* Educación ajuste Miriam *
*************
cd "$datos\Clean"
use "base_sal_reserva_real_what2018.dta",clear
*Eliminar los que no saben
drop if g_estudios==99 

*Menor a Licenciatura
gen estudios =1 if g_estudios<7
*Mayor a Licenciatura
replace estudios =2 if g_estudios>=7


cd "$figuras\Figuaras_Presentación_23mayo\Fig6_educacion"
foreach z of numlist 1 2 {
		glo bw = 0.1
		kdensity wrhat_real_ln if s & año==2006 & estudios==`z' & wrhat_real_ln>6 [fw=fac], gen(wd_x_06 wd_y_06) bw($bw) 
		kdensity wrhat_real_ln if s & año==2012 & estudios==`z' & wrhat_real_ln>6 [fw=fac], gen(wd_x_12 wd_y_12) bw($bw) 
		kdensity wrhat_real_ln if s & año==2018 & estudios==`z' & wrhat_real_ln>6 [fw=fac], gen(wd_x_18 wd_y_18) bw($bw) 
		kdensity wrhat_real_ln if s & año==2022 & estudios==`z' & wrhat_real_ln>6 [fw=fac], gen(wd_x_22 wd_y_22) bw($bw)	
	if `z' ==1 {		
tw (line wd_y_06 wd_x_06) (line  wd_y_12 wd_x_12) (line  wd_y_18 wd_x_18) (line  wd_y_22 wd_x_22), legend(label(1 "2006") label(2 "2012") label(3 "2018") label(4 "2022")) title("Salario de reserva, menor a licenciatura por año") ylab(,angle(0)) graphregion(color(white)) xlabels( 6 "400" 7 "1,000" 8 "3,000" 9 "8,000" 10 "22,000" 11 "60,000") ytitle("Densidad") xtitle("Salario")
graph export  "KD_Salario_de_reserva_años_Menor_menor_lic_Heckman.png", replace
drop wd_*
	}
	else {
tw (line wd_y_06 wd_x_06) (line  wd_y_12 wd_x_12) (line  wd_y_18 wd_x_18) (line  wd_y_22 wd_x_22), legend(label(1 "2006") label(2 "2012") label(3 "2018") label(4 "2022")) title("Salario de reserva, mayor o igual licenciatura por año") ylab(,angle(0)) graphregion(color(white)) xlabels( 6 "400" 7 "1,000" 8 "3,000" 9 "8,000" 10 "22,000" 11 "60,000") 	ytitle("Densidad") xtitle("Salario")
graph export  "KD_Salario_de_reserva_años_mayor_lic_Heckman.png", replace
drop wd_*
		
	}
}

cap log close
exit 
