*************** Stata Journal paper: example section **********************
* examples using the data from FHPS 2021
*this code runs with xtevent 2.2.0

cap log close
clear all
set more off

*route where to find the EventStudyPackage repository's main tree
global locald "C:/Users/tino_/Dropbox/PC/Documents/xtevent/stata_paper/EventStudyPackage"

*where to save outputs
global dir_graph "$locald/output/analysis/plots"

*folder of the dataset
cd "$locald/source/raw/examples"

****************************** xtevent *************************************
*load dataset 
sjlog using "$dir_graph/fhps_load_data", replace 
use simulation_data_dynamic.dta, clear
xtset id t 
sjlog close, replace nologfile

*list some values
order id t z y_jump_m x_jump_m, first
sjlog using "$dir_graph/fhps_list_some_values", replace 
list id t z y_jump_m x_jump_m if id==2 & t<=10
sjlog close, replace nologfile

*default estimation
sjlog using "$dir_graph/fhps_default_estimation", replace 
xtevent y_jump_m x_jump_m, panelvar(id) timevar(t) policyvar(z) window(5) 
sjlog close, replace nologfile

*asymmetric window
sjlog using "$dir_graph/fhps_asymmetric", replace 
xtevent y_jump_m x_jump_m, panelvar(id) timevar(t) policyvar(z) window(-4 7) 
sjlog close, replace nologfile

*no time effects
sjlog using "$dir_graph/fhps_note", replace 
xtevent y_jump_m x_jump_m, panelvar(id) timevar(t) policyvar(z) window(5) note
sjlog close, replace nologfile

*generate event-time dummies without imputation
cap drop v*
replace z=0 if id==2 & t<3
sjlog using "$dir_graph/fhps_noestimate", replace 
replace z=. if id==2 & t<3
qui xtevent y_jump_m x_jump_m, panelvar(id) timevar(t) policyvar(z) ///
 window(5) savek(v, noestimate)
sjlog close, replace nologfile

*list event-time dummies
sjlog using "$dir_graph/fhps_list_et_dummies", replace 
list id t z v_eq_m6 -v_eq_m1 if inlist(id,1,2) & (t<=10 | t>=31), ///
separator(10) noobs
sjlog close, replace nologfile

*generate event-time dummies with imputation
cap drop z_imputed
sjlog using "$dir_graph/fhps_dummies_with_imputation", replace 
cap drop v*
qui xtevent y_jump_m x_jump_m, panelvar(id) timevar(t) policyvar(z) ///
window(5) savek(v, noestimate) impute(stag, saveimp) 
sjlog close, replace nologfile

*list event-time dummies with imputation
sjlog using "$dir_graph/fhps_list_et_dummies_imputation", replace 
list id t z z_imputed v_eq_m6 -v_eq_m1 if inlist(id,1,2) & (t<=10 | t>=31), ///
separator(10) noobs abbreviate(6)
sjlog close, replace nologfile

*estimation with reghdfe
cap drop eta_r2
sjlog using "$dir_graph/fhps_reghdfe", replace 
gen eta_r2=round((eta_r+1)*2)
xtevent y_jump_m x_jump_m, panelvar(id) timevar(t) policyvar(z) window(5) ///
reghdfe addabsorb(eta_r2)
sjlog close, replace nologfile

*trend 
sjlog using "$dir_graph/fhps_trend_estimation", replace 
xtevent y_jump_m x_jump_m, panelvar(id) timevar(t) policyvar(z) window(5) ///
trend(-3, method(gmm))
sjlog close, replace nologfile

*iv estimation 
sjlog using "$dir_graph/fhps_iv_estimation", replace 
xtevent y_jump_m, panelvar(id) timevar(t) policyvar(z) window(5) ///
proxy(x_jump_m) proxyiv(4)
sjlog close, replace nologfile

*Sun and Abraham
sjlog using "$dir_graph/fhps_SA_estimation", replace
gen timet=t if z==1
by id: egen time_of_treat=min(timet)
gen last_treat=time_of_treat==39
xtevent y_jump_m x_jump_m, panelvar(id) timevar(t) policyvar(z) window(5) ///
cohort(time_of_treat) control_cohort(last_treat)
sjlog close, replace nologfile

*repeated cross-sectional dataset 
sjlog using "$dir_graph/fhps_rcsection1_estimation", replace
gen state=eventtime
xtset, clear
get_unit_time_effects y_jump_m x_jump_m, panelvar(state) timevar(t) ///
saving("effect_file.dta", replace)
sjlog close, replace nologfile

sjlog using "$dir_graph/fhps_rcsection2_estimation", replace
qui bysort state t (z): keep if _n==1
keep state t z
qui merge m:1 state t using effect_file.dta, nogen
xtevent _unittimeeffects, panelvar(state) timevar(t) policyvar(z) window(5)
sjlog close, replace nologfile

********************************** xteventplot *****************************

*default xteventplot
sjlog using "$dir_graph/fhps_default_xteventplot", replace 
use simulation_data_dynamic.dta, clear
qui xtset id t 
qui xtevent y_jump_m x_jump_m, panelvar(id) timevar(t) policyvar(z) window(5) 
xteventplot, ytitle("Coefficient") xtitle("Event time")
sjlog close, replace nologfile
graph export "$dir_graph/fhps_default_xteventplot.eps", replace

*omit several default characteristics
sjlog using "$dir_graph/fhps_omit_default_characteristics", replace 
qui xtevent y_jump_m x_jump_m, panelvar(id) timevar(t) policyvar(z) window(5) 
xteventplot, ytitle("Coefficient") xtitle("Event time") nosupt ///
 nominus1label noprepval 

sjlog close, replace nologfile
graph export "$dir_graph/fhps_omit_default_characteristics.eps", replace

*customize characteristics
sjlog using "$dir_graph/fhps_customize_characteristics", replace 
qui xtevent y_jump_m x_jump_m, panelvar(id) timevar(t) policyvar(z) window(5) 
xteventplot, ytitle("Coefficient") xtitle("Event time") ///
scatterplotopts(mcolor(cranberry) msymbol(diamond)) ///
ciplotopts(lcolor(cranberry)) textboxoption(color(cranberry) size(medium)) ///
graphregion(fcolor(ltblue))
sjlog close, replace nologfile
graph export "$dir_graph/fhps_customize_characteristics.eps", replace

*smpath 
sjlog using "$dir_graph/fhps_smpath", replace 
qui xtevent y_jump_m x_jump_m, panelvar(id) timevar(t) policyvar(z) window(5) 
qui xteventplot, ytitle("Coefficient") xtitle("Event time") ///
smpath(line, postwindow(5) maxiter(90) maxorder(9) technique(nr)) 
sjlog close, replace nologfile
graph export "$dir_graph/fhps_smpath.eps", replace

*trend 
sjlog using "$dir_graph/fhps_trend_plot_overlay", replace 
qui xtevent y_jump_m x_jump_m, panelvar(id) timevar(t) policyvar(z) ///
   window(5) trend(-3, method(gmm) saveoverlay) 

xteventplot, ytitle("Coefficient") xtitle("Event time") overlay(trend)
sjlog close, replace nologfile
graph export "$dir_graph/fhps_trend_plot_overlay.eps", replace
sjlog using "$dir_graph/fhps_trend_plot", replace 
xteventplot, ytitle("Coefficient") xtitle("Event time") 
sjlog close, replace nologfile
graph export "$dir_graph/fhps_trend_plot.eps", replace

*IV
sjlog using "$dir_graph/fhps_iv_outcome_plot", replace 
qui xtevent y_jump_m, panelvar(id) timevar(t) policyvar(z) window(5)
xteventplot, ytitle("Coefficient") xtitle("Event time") 
sjlog close, replace nologfile
graph export "$dir_graph/fhps_iv_outcome_plot.eps", replace

sjlog using "$dir_graph/fhps_iv_proxy_plot", replace 
qui xtevent y_jump_m, panelvar(id) timevar(t) policyvar(z) window(5) ///
proxy(x_jump_m) proxyiv(4)
xteventplot, ytitle("Coefficient") xtitle("Event time") proxy
sjlog close, replace nologfile
graph export "$dir_graph/fhps_iv_proxy_plot.eps", replace

sjlog using "$dir_graph/fhps_iv_proxy_outcome_plot", replace 
xteventplot, ytitle("Coefficient") xtitle("Event time") overlay(iv)
sjlog close, replace nologfile
graph export "$dir_graph/fhps_iv_proxy_outcome_plot.eps", replace

sjlog using "$dir_graph/fhps_iv_subtraction_plot", replace 
xteventplot, ytitle("Coefficient") xtitle("Event time") 
sjlog close, replace nologfile
graph export "$dir_graph/fhps_iv_subtraction_plot.eps", replace

********************** xteventtest **********************************

sjlog using "$dir_graph/fhps_test_coefs", replace 
qui xtevent y_jump_m, panelvar(id) timevar(t) policyvar(z) window(5)
xteventtest, coefs(-3 -2) 
sjlog close, replace nologfile

sjlog using "$dir_graph/fhps_test_allpre", replace 
qui xtevent y_jump_m, panelvar(id) timevar(t) policyvar(z) window(5)
xteventtest, allpre cumul testopts(coef)
sjlog close, replace nologfile

sjlog using "$dir_graph/fhps_test_trend", replace 
qui xtevent y_jump_m, panelvar(id) timevar(t) policyvar(z) window(5)
xteventtest, trend(-3)
sjlog close, replace nologfile

sjlog using "$dir_graph/fhps_test_overidpost", replace 
qui xtevent y_jump_m, panelvar(id) timevar(t) policyvar(z) window(5)
xteventtest, overidpost(3)
sjlog close, replace nologfile
