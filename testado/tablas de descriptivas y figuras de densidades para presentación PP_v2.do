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


******************************************************************************************
************* Preparar datos para tablas y gráficas  ********************************************
******************************************************************************************

use "\\Bmdgiesan\dgiesan\PROYECTOS\DASPERI\Salarios de Reserva\Data\Clean\base_sal_reserva_real_what2018.dta", clear

*crear dummies para niveles edcativos
cap drop _ge*
xi i.g_estudios2, prefix(_ge_) noomit
renvars _ge_g_estud_11 _ge_g_estud_12 _ge_g_estud_13 _ge_g_estud_14 _ge_g_estud_15 \ m_prepa prepa normal licen posgrado
lab var m_prepa "menor a preparatoria"
lab var prepa "preparatoria"
lab var normal "normal o carrera técnica"
lab var licen "licenciatura"
la var posgrado "maestría o doctorado"

lab var lnwrimputado_exp "salario nominal en pesos"
lab var lnwrimputado_real "salario real en pesos"

drop if g_estudios==99 

*Menor a Licenciatura
gen estudios =1 if g_estudios<7
*Mayor a Licenciatura
replace estudios =2 if g_estudios>=7
xi i.estudios, prefix(_g_f) noomit

*bandwith para gráficas de densidades
glo bw = 0.1



******************************************************************************************
************* Tablas  ********************************************
******************************************************************************************

************* tabla: estadisticas de variables continuas y discretas. Pool de años y por año *********************

*variables continuas
tabstat eda a_escolaridad exp [aw=fac], by(año) stat(mean sd p25 p50 p75) save
putexcel set "\\Bmdgiesan\dgiesan\PROYECTOS\DASPERI\Salarios de Reserva\Tables\Heckman\estadisticas_vars_continuas.xlsx", replace
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

* Ajuste Francisco Zazueta Borboa
*variables discretas 

tabstat _g_festudio_1 _g_festudio_2 jefe urb [aw=fac], by(año) stat(mean) save 
putexcel set "\\Bmdgiesan\dgiesan\PROYECTOS\DASPERI\Salarios de Reserva\Tables\Heckman\estadisticas_vars_discretas_fzb.xlsx", replace
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


************* tabla: estadisticas de salario nominal y salario real por año *********************

tabstat lnwrimputado_exp lnwrimputado_real [aw=fac], by(año) stat(mean sd p25 p50 p75) save 
putexcel set "\\Bmdgiesan\dgiesan\PROYECTOS\DASPERI\Salarios de Reserva\Tables\Heckman\estadisticas_salario_nominal_real.xlsx", replace
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

*salario nominal
cap drop wrhat_exp_emp wrhat_exp_desemp
gen wrhat_exp_emp=wrhat_exp if emp==1
lab var wrhat_exp_emp "salario de reserva nominal en pesos para empleados"
gen wrhat_exp_desemp=wrhat_exp if emp==0
lab var wrhat_exp_desemp "salario de reserva nominal en pesos para desempleados"

tabstat lnwrimputado_exp wrhat_exp_emp wrhat_exp_desemp [aw=fac], by(año) stat(mean sd p25 p50 p75) save 

*salario real
cap drop wrhat_exp_emp wrhat_exp_desemp
gen wrhat_exp_emp=wrhat_exp if emp==1
lab var wrhat_exp_emp "salario de reserva nominal en pesos para empleados"
gen wrhat_exp_desemp=wrhat_exp if emp==0
lab var wrhat_exp_desemp "salario de reserva nominal en pesos para desempleados"

tabstat lnwrimputado_exp wrhat_exp_emp wrhat_exp_desemp [aw=fac], by(año) stat(mean sd p25 p50 p75) save 




tabstat lnwrimputado_exp lnwrimputado_real [aw=fac], by(año) stat(mean sd p25 p50 p75) save 


******************************************************************************************
************* Gráficas  ********************************************
******************************************************************************************




tabstat eda a_escolaridad exp, by(foreign) stat(mean sd p25 p50 p75)


collapse (mean) , 