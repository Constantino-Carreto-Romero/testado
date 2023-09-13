cap program drop clean_enoe_single
program define clean_enoe_single

    args year trim

    use folio_id CD_A ent con V_SEL N_HOG H_MUD N_REN POS_OCU lnwrimputado year sex between15_and_64 EDA12C aux_in trim PAR_C exp ANIOS_ESC ent urb fac eda g_estudios a_escolaridad rama region DUR_DES hrsocup P10_4 P10_1 P10_3 P10_2 if year==`year' & trim == "`trim'" using C:\Users\B16728\Desktop\enoe_2005_2022_comp.dta,clear

    ** Generar indicadores encadenados
    tostring CD_A ent con V_SEL N_HOG H_MUD N_REN,replace
    gen folio_id_1= CD_A+ent+con+V_SEL+N_HOG+H_MUD
    gen folio_id_2= CD_A+ent+con+V_SEL+N_HOG+H_MUD+N_REN

    ** Jefe del hogar
    gen jefe=1 if PAR_C==101
    replace jefe=0 if jefe==.

    ** Rangos de edad
    gen edadrange = .
    replace edadrange = 1 if inrange(eda,15,19)
    replace edadrange = 2 if inrange(eda,20,24)
    replace edadrange = 3 if inrange(eda,25,29)
    replace edadrange = 4 if inrange(eda,30,34)
    replace edadrange = 5 if inrange(eda,35,39)
    replace edadrange = 6 if inrange(eda,40,44)
    replace edadrange = 7 if inrange(eda,45,49)
    replace edadrange = 8 if inrange(eda,50,54)
    replace edadrange = 9 if inrange(eda,55,59)
    replace edadrange = 10 if inrange(eda,60,64)

    ** Edad de hijos y menores
    * Edad de los hijos y menores
    bys folio_id_1: egen eda_hijos_min= min(cond((PAR_C>=301 & PAR_C<=304),eda,.)) 
    bys folio_id_1: egen eda_hijos_mean= mean(cond((PAR_C>=301 & PAR_C<=304),eda,.)) 

    *padres o jefes del hogar
    replace eda_hijos_min=   cond(PAR_C==101 | PAR_C==201 | PAR_C==202 | PAR_C==204, eda_hijos_min, .) 
    *padres o jefes del hogar
    replace eda_hijos_mean=   cond(PAR_C==101 | PAR_C==201 | PAR_C==202 | PAR_C==204, eda_hijos_mean, .) 


    gen eda_hijos = .
    replace eda_hijos = 4 if eda_hijos_min>=15 & eda_hijos_min<=18
    replace eda_hijos = 3 if eda_hijos_min>=11 & eda_hijos_min<15
    replace eda_hijos = 2 if eda_hijos_min>=5 & eda_hijos_min<11
    replace eda_hijos = 1 if eda_hijos_min<5

    ** Variable de hijos
    gen hij_menor_12 = 1 if eda_hijos_min<13
    replace hij_menor_12 = 0 if missing(hij_menor_12)

    gen hij_menor_5 =1 if eda_hijos_min<5
    replace hij_menor_5 = 0 if missing(hij_menor_5)

    ** Restringir edad
    keep if between15_and_64 == 1
    drop if EDA12C==0 | EDA12C==12

    ** Solamente asalariados ( y desempleados)
    keep if POS_OCU == 0 | POS_OCU == 1 | POS_OCU == .

    ** Restringir horas trabajadas

    drop if (lnwrimputado !=.) & !inrange(hrsocup,30,60) 

    ** Mujeres
    keep if sex == 1

    ** Quitar 1% de colas de distribución de salarios
    su lnwrimputado, d
    drop if (lnwrimputado<r(p1) | lnwrimputado>r(p99)) & (lnwrimputado!=.)

    ** Experiencia y potencias de experiencia
    replace exp = 0 if exp<0
    cap drop exp2
    gen exp2 = exp*exp
    gen exp3 = exp2*exp
    gen exp4 = exp2*exp2	

    ** Limpiar años de educación y generar educación al cuadrado
    replace ANIOS_ESC = . if ANIOS_ESC == 99
    gen esc2 = ANIOS_ESC*ANIOS_ESC

    ** Entidad numérica
    destring ent, replace

    ** Region numérica
    gen regionnum = .
    replace regionnum = 1 if region == "Norte"
    replace regionnum = 2 if region == "Centro Norte" | region == "Centro norte"
    replace regionnum = 3 if region == "Centro"
    replace regionnum = 4 if region == "Sur"

    labmask regionnum, values(region)

    drop region
    ren regionnum region            

    ** Marcar observaciones de salario imputado y quedarse solo con los no imputados
    * TODO: Revisar el efecto de la imputación nuevamente sobre la muestra de asalariados y todas las restricciones
    gen d_ing_imputado= .
    replace d_ing_imputado=1  if aux_inc7c > 0 & !missing(aux_inc7c)
    drop if d_ing_imputado==1
    drop d_ing_imputado

    compress

    save "\\Bmdgiesan\DGIESAN\PROYECTOS\DASPERI\Salarios de Reserva\Data\Clean\ENOE_yeartrim\enoe_`year'_`trim'_hombres.dta", replace

end



   