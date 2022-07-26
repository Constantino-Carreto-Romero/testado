
**** crear muestra
clear all
set obs 30
gen id = 1
replace id = 2 if _n >10 & _n<=20
replace id = 3 if _n >20 
bys id: gen t = _n
gen price = runiform(5,6)
*variable de política 
gen z=(t>=5)
replace z=1 if t==4 & id==1

**** estimación
xtset id t
*variable de política en tipo string
tostring z, replace

xtevent price, policy(z) panel(id) t(t) window(2) //type mistmatch error
xteventplot

*variable de política tipo numérica 
destring z, replace
*crear una variable tipo string y compararla con un valor numérico
gen w=runiform()
xtevent price if w=="3", policy(z) panel(id) t(t) window(2) 
