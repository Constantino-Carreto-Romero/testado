capture log close
log using "auto", smcl replace
//_1
sysuse auto, clear                                          
//_2
gen gphm = 100/mpg                                          
//_3
twoway (scatter gphm weight) (lfit gphm weight),  ///         
    ytitle(Gallons per 100 Miles) legend(off)                
graph export auto.png, width(500) replace                   
//_4
regress gphm weight                                         
//_^
log close
