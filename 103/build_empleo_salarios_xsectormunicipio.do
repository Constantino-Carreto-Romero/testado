/*==================================================
project:       Generar % de Vinculación
Author:        DASPERI 
E-email:       
url:           
Dependencies:  Banco de México
----------------------------------------------------
Creation Date:    27 Jan 2020 - 16:53:45
Modification Date:   
Do-file version:    01
References:          
Output:             
==================================================*/

/*==================================================
              0: Program set up
==================================================*/
version 15.1
drop _all

glo carpeta 	"T:\Recuadro SM-Inflacion\Proyecto\"
glo codigo 		"$carpeta/Codigo"
glo data		"$carpeta/Datos"
glo figuras 	"$carpeta/Figuras"
glo ster 		"$carpeta/Ster"
glo tablas 		"$carpeta/Tablas"
glo imss		"\\Bmdgiesan\dgiesan\BD\PRIVADAS\IMSS\Formato_Nuevo\stata"
*glo imss 		"J:\stata"

cap project, doinfo
if _rc {
	capture log close
	log using "$codigo/build_Empleo_Salarios_xSectorMunicipio.txt", replace text
	loc pr=0
}
else {
	loc pr=1
	forvalues yyyy = 2017/2019{
		foreach mm in 01 02 03 04 05 06 07 08 09 10 11 12{
		    project, original("$imss/`yyyy'/imss_`mm'`yyyy'.dta") 
		}
	}
	
	project, original("$data/MunicipiosFronteraNorteSur.dta")
	project, original("$data/INPC.xlsx")
	project, uses("$data/clean_IMSSxSCIAN2021.dta")
	project, uses("$data/GenericoSCIAN_clean.dta")
	project, original("${data}/Catalogos.xlsx")
}
/*==================================================
              1: Vinculados
==================================================*/
use "$data/GenericoSCIAN_clean.dta" , clear
collapse (mean) iva, by(scian)
gen coniva = (iva  == 1)
gen siniva = (iva == 0)
gen mixto = (iva != 0 & iva != 1)
tempfile clas
save `clas'

use "$imss/2018/imss_122018" , clear

rename *, lower
drop   llave_tiempo llave_modalidad llave_sexo tipo_trabajador    

rename llave_municipio   municipio
rename llave_actividad   CLAVE_CATALOGO
rename llave_entidad     entidad
rename salariof          sbc
rename llave_empleado    nss
rename llave_empresa     registro

sort registro nss 

drop if sbc==. | sbc==0 

//tratamiento de registros duplicados al nivel de trabajador y empresa: quedarse con el de ingreso más alto (en muchos casos el sbc es el mismo).
bysort registro nss: egen double maxsbc=max(sbc)
keep if sbc==maxsbc
drop maxsbc
duplicates drop registro nss, force

//Traer clasificación Frontera/No Frontera	
merge m:1 municipio using "$data/MunicipiosFronteraNorteSur.dta"
keep if _merge==3
drop _merge
drop ciudad municipio_inpc inconsistenciasIMSSINEGI_municip

//Traer clasificación SCIAN
merge m:1 CLAVE_CATALOGO using "$data/clean_IMSSxSCIAN2021.dta", keepusing(SCIAN3D DESCRIPCION_SCIAN_3D)
keep if _merge==3
drop _merge

sum sbc if frontera_norte == 1 , d

gen l_vinc = 0
replace l_vinc = 1 if round(sbc,0.01)<=round(102.68,0.01)
replace l_vinc = 1 if round(sbc,0.01)<=round(176.72,0.01) & frontera_norte == 1
gen l_total = 1

gen l_novinc_bajo = 0
replace l_novinc_bajo = 1 if round(sbc,0.01)<=round(236.82,0.01) & l_vinc == 0
replace l_novinc_bajo = 1 if round(sbc,0.01)<=round(236.82,0.01) & l_vinc == 0 & frontera_norte == 1 

gen l_novinc_alto = 0
replace l_novinc_alto = 1 if round(sbc,0.01)>round(236.82,0.01) & l_vinc == 0
replace l_novinc_alto = 1 if round(sbc,0.01)>=round(236.82,0.01) & l_vinc == 0 & frontera_norte == 1 


sort nss l_vinc
by nss: keep if _n == _N
preserve
	keep if l_vinc == 1
	keep nss
	tempfile panelvinc
	save `panelvinc'
restore

preserve
	keep if l_novinc_alto == 1
	keep nss
	tempfile panelvinc_alto
	save `panelvinc_alto'
restore

preserve
	keep if l_novinc_bajo == 1
	keep nss
	tempfile panelvinc_bajo
	save `panelvinc_bajo'
restore


preserve
	keep if l_vinc == 1
	keep nss
	tempfile panelvinc
	save `panelvinc'
restore

preserve
	keep if l_vinc == 0
	keep nss
	tempfile panelnovinc
	save `panelnovinc'
restore

use "$imss/2019/imss_012019" , clear
rename *, lower
drop   llave_tiempo llave_modalidad llave_sexo tipo_trabajador    

rename llave_municipio   municipio
rename llave_actividad   CLAVE_CATALOGO
rename llave_entidad     entidad
rename salariof          sbc
rename llave_empleado    nss
rename llave_empresa     registro

sort registro nss 

drop if sbc==. | sbc==0 

//tratamiento de registros duplicados al nivel de trabajador y empresa: quedarse con el de ingreso más alto (en muchos casos el sbc es el mismo).
bysort registro nss: egen double maxsbc=max(sbc)
keep if sbc==maxsbc
drop maxsbc
duplicates drop registro nss, force

merge m:1 nss using `panelvinc'
gen vinc = (_merge == 3)
drop if _merge == 2
drop _merge

merge m:1 nss using `panelvinc_alto'
gen vinc_alto = (_merge == 3)
drop if _merge == 2
drop _merge

merge m:1 nss using `panelvinc_bajo'
gen vinc_bajo = (_merge == 3)
drop if _merge == 2
drop _merge

merge m:1 nss using `panelnovinc'
gen novinc = (_merge == 3)
drop if _merge == 2
drop _merge

//Traer clasificación Frontera/No Frontera	
merge m:1 municipio using "$data/MunicipiosFronteraNorteSur.dta"
keep if _merge==3
drop _merge
drop ciudad municipio_inpc inconsistenciasIMSSINEGI_municip

//Traer clasificación SCIAN
merge m:1 CLAVE_CATALOGO using "$data/clean_IMSSxSCIAN2021.dta", keepusing(SCIAN3D DESCRIPCION_SCIAN_3D)
keep if _merge==3
drop _merge

rename SCIAN3D scian

merge m:1 scian using `clas'
drop if _merge == 2
drop _merge

quietly foreach type in vinc novinc vinc_alto vinc_bajo{
    foreach x in coniva siniva mixto{
		sum sbc if `type' == 1 & `x' == 1 & frontera_norte == 1 , d
		loc k = r(p95)
		noi di "`type' `x' : `k'"  
	}
}

quietly foreach type in vinc novinc vinc_alto vinc_bajo{
		sum sbc if `type' == 1 & frontera_norte == 1   , d
		loc k = r(p95)
		noi di "`type'  : `k'" 
}

/*==================================================
              2: Bases IMSS
==================================================*/
import excel "${data}/Catalogos.xlsx" , clear first sheet("Municipios_INEGI_IMSS")
* import excel J:\catalogos\Catalogos.xlsx, clear first sheet("Municipios_INEGI_IMSS")
rename LLAVE_MUN municipio
rename LLAVE_ENTIDAD ent
rename CLAVE_MUNICIPIO_INEGI mun
keep municipio ent mun
tempfile nn
save `nn'

import excel "$data/INPC.xlsx", clear first
gen t = mofd(Fecha)
format t %tm
sum INPC  if t == tm(2019m1)
replace INPC = INPC/r(mean)*100
keep t INPC
tempfile precios
save `precios'

* tempfile panel panel2 panel3
tempfile panel 
* forvalues yyyy = 2019/2019{
*  foreach mm in 01 {
forvalues yyyy = 2017/2019{
  foreach mm in 01 02 03 04 05 06 07 08 09 10 11 12{
	    use llave_municipio llave_actividad llave_entidad salariof llave_empleado llave_empresa using "$imss/`yyyy'/imss_`mm'`yyyy'" , clear
		rename *, lower
		* drop   llave_tiempo llave_modalidad llave_sexo tipo_trabajador    

		rename llave_municipio   municipio
		rename llave_actividad   CLAVE_CATALOGO 
		rename llave_entidad     entidad
		rename salariof          sbc
		rename llave_empleado    nss
		rename llave_empresa     registro

		sort registro nss 

		drop if sbc==. | sbc==0 

		//tratamiento de registros duplicados al nivel de trabajador y empresa: quedarse con el de ingreso más alto (en muchos casos el sbc es el mismo).
		bysort registro nss: egen double maxsbc=max(sbc)
		keep if sbc==maxsbc
		drop maxsbc
		duplicates drop registro nss, force
		
		gen nivel_empleo = 1
		
		gen t = ym(`yyyy',`mm')
		
		gen sbc_nom = sbc
		
		merge m:1 t using `precios' , nogen keep(3)
		replace sbc = sbc/INPC * 100
		
		//Traer clasificación SCIAN
		merge m:1 CLAVE_CATALOGO  using "$data/clean_IMSSxSCIAN2021.dta", keepusing(SCIAN3D DESCRIPCION_SCIAN_3D)
		keep if _merge==3
		drop _merge
		
		merge m:1 municipio using `nn'
		keep if _merge == 3
		drop _merge
		
		
		* Clasificar "vinculados" y "no vinculados"
		if `yyyy'<=2018 gen vinc = (sbc<=176.72)
		else gen vinc = (sbc<=230)
		
		* Colapsar empleo y salarios
		
		fcollapse (sum) nivel_empleo (mean) sbc_nom mean_sbc = sbc (firstnm) municipio, by(ent mun SCIAN3D vinc)
		gen año = `yyyy'
		gen mes = `mm'
		cap append using `panel'
		save `panel' , replace 		
		
		
	
		/*
		preserve
			collapse (sum) nivel_empleo (mean) sbc_nom mean_sbc = sbc (firstnm) municipio, by(ent mun SCIAN3D)
			gen año = `yyyy'
			gen mes = `mm'
			cap append using `panel'
			save `panel' , replace 
		restore
		
		
		preserve
			merge m:1 nss using `panelvinc' , nogen keep(3)
			collapse (sum) nivel_empleo_vinc=nivel_empleo (mean) sbc_nom_vinc = sbc_nom mean_sbc_vinc = sbc (firstnm) municipio, by(ent mun SCIAN3D)
			gen año = `yyyy'
			gen mes = `mm'
			cap append using `panel2'
			save `panel2' , replace 
		restore
		
		preserve
			merge m:1 nss using `panelnovinc' , nogen keep(3)
			collapse (sum) nivel_empleo_novinc=nivel_empleo (mean) sbc_nom_novinc = sbc_nom mean_sbc_novinc = sbc (firstnm) municipio, by(ent mun SCIAN3D)
			gen año = `yyyy'
			gen mes = `mm'
			cap append using `panel3'
			save `panel3' , replace 
		restore
		*/
	
		
	}
}

use `panel' , clear

/*
merge 1:1 ent mun SCIAN3D año mes using `panel2' , nogen
merge 1:1 ent mun SCIAN3D año mes using `panel3' , nogen
*/

//Traer clasificación Frontera/No Frontera	
merge m:1 municipio using "$data/MunicipiosFronteraNorteSur.dta"
keep if _merge==3
drop _merge
drop municipio *_nombre incon
gen ZLFN = (frontera_norte==1)
bys ent mun: egen ZLFNmax = max(ZLFN)
replace ZLFN = ZLFNmax
drop ZLFNmax


reshape wide nivel_empleo sbc_nom mean_sbc, i(ent mun SCIAN año mes) j(vinc)

egen nivel_empleo = rowtotal(nivel_empleo0 nivel_empleo1)
gen wsbc_nom0 = nivel_empleo0 * sbc_nom0
gen wsbc_nom1 = nivel_empleo1 * sbc_nom1
egen sbc_nom = rowtotal(wsbc_nom0 wsbc_nom1)
replace sbc_nom = sbc_nom/nivel_empleo
drop wsbc*

gen wmean_sbc0 = nivel_empleo0 * mean_sbc0
gen wmean_sbc1 = nivel_empleo1 * mean_sbc1
egen mean_sbc = rowtotal(wmean_sbc0 wmean_sbc1)
replace mean_sbc = mean_sbc/nivel_empleo
drop wmean_sbc*

foreach var in nivel_empleo sbc_nom mean_sbc {
    ren `var'0 `var'_novinc
	ren `var'1 `var'_vinc	
}


save "$data/EmpleoSalariosxSectorMunicipio.dta" , replace


/*==================================================
              3: Collapse SCIAN
==================================================*/


/*==================================================
              4: Variables Relevantes
==================================================*/

/*==================================================
              5: Base final
==================================================*/

if `pr' project, creates("$data/EmpleoSalariosxSectorMunicipio.dta")



cap log close
exit
/* End of do-file */

><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><

Notes:
1.
2.
3.


Version Control:


