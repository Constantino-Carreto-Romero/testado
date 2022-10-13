# modificar readme
`<span style="color:red">reghdfe</span>`

<span style="color:red">To produce equivalent results as with **xtevent 1.0.0**</span>, where the default was to impute the endpoints, <span style="color:red">the user should use **impute(stag)**</span>.

```html
<span style="color:red">To produce equivalent results as with xtevent 1.0.0, where the default was to impute the endpoints, the user should use impute(stag)</span>.
```

\textcolor{red}{red}

https://via.placeholder.com/728x90.png?text=Visit+WhoIsHostingThis.com+Buyers+Guide


 ![#f03c15](https://via.placeholder.com/15/f03c15/f03c15.png) `#f03c15`
 
  ![#f03c15](https://via.placeholder.com/15/f03c15/f03c15.png) `#f03c15`
  
  ![#f03c15](https://via.placeholder.com/15/f03c15/?text=hello.png) `#f03c15`

https://placehold.it/150/ffffff/ff0000?text=hello

```diff
- text in red
- To produce equivalent results as with xtevent 1.0.0, where the default was to impute the endpoints, the user should use impute(stag).
+ text in green
! text in orange
# text in gray
@@ text in purple (and bold)@@
```
```diff
- To produce equivalent results as with xtevent 1.0.0, where the default was to impute the endpoints, the user should use impute(stag).
```

```diff
- To produce equivalent results as with xtevent 1.0.0, where the default was to impute the endpoints, the user should use impute(stag).
```

```
. use "https://github.com/JMSLab/xtevent/blob/main/test/example31.dta?raw=true", clear
. xtset i t
       panel variable:  i (strongly balanced)
        time variable:  t, 1 to 20
                delta:  1 unit
```

```latex
. xtevent y x, panelvar(i) timevar(t) policyvar(z) window(3) impute(stag) 
{\smallskip}
No proxy or instruments provided. Implementing OLS estimator
{\smallskip}
Linear regression, absorbing indicators         Number of obs     =     20,000
Absorbed variable: {\bftt{i}}                            No. of categories =      1,000
                                                F(  28,  18972)   =    1221.97
                                                Prob > F          =     0.0000
                                                R-squared         =     0.7831
                                                Adj R-squared     =     0.7713
                                                Root MSE          =     1.0490
{\smallskip}
\HLI{13}{\TOPT}\HLI{64}
           y {\VBAR}      Coef.   Std. Err.      t    P>|t|     [95\% Conf. Interval]
\HLI{13}{\PLUS}\HLI{64}
    _k_eq_m4 {\VBAR}  -.4134686   .0652957    -6.33   0.000    -.5414539   -.2854833
    _k_eq_m3 {\VBAR}  -.0583756   .0842192    -0.69   0.488    -.2234527    .1067015
    _k_eq_m2 {\VBAR}  -.0563041   .0838411    -0.67   0.502    -.2206401    .1080319
    _k_eq_p0 {\VBAR}   1.280428   .0838822    15.26   0.000     1.116011    1.444844
    _k_eq_p1 {\VBAR}   1.206089   .0851807    14.16   0.000     1.039127    1.373051
    _k_eq_p2 {\VBAR}    1.32568   .0860638    15.40   0.000     1.156988    1.494373
    _k_eq_p3 {\VBAR}   1.336384   .0876951    15.24   0.000     1.164494    1.508274
    _k_eq_p4 {\VBAR}   1.399209   .0671338    20.84   0.000     1.267621    1.530798
           x {\VBAR}   .0978754   .0030018    32.61   0.000     .0919917    .1037591
             {\VBAR}
           t {\VBAR}
          2  {\VBAR}   .1268162   .0469168     2.70   0.007     .0348551    .2187773
          3  {\VBAR}   .3183101   .0469352     6.78   0.000     .2263128    .4103073
          4  {\VBAR}   .5085822   .0469588    10.83   0.000     .4165387    .6006256
          5  {\VBAR}   .7345745   .0470264    15.62   0.000     .6423987    .8267504
          6  {\VBAR}   .8812613   .0470671    18.72   0.000     .7890057    .9735169
          7  {\VBAR}   1.038901   .0471349    22.04   0.000     .9465122    1.131289
          8  {\VBAR}   1.305297   .0472154    27.65   0.000     1.212751    1.397844
          9  {\VBAR}   1.465773   .0472979    30.99   0.000     1.373065    1.558482
         10  {\VBAR}   1.698353   .0474276    35.81   0.000     1.605391    1.791316
         11  {\VBAR}   1.817264   .0475543    38.21   0.000     1.724053    1.910474
         12  {\VBAR}   1.978104   .0476956    41.47   0.000     1.884616    2.071592
         13  {\VBAR}   2.183417   .0478041    45.67   0.000     2.089717    2.277117
         14  {\VBAR}    2.33248   .0479999    48.59   0.000     2.238396    2.426564
         15  {\VBAR}   2.564906    .048164    53.25   0.000       2.4705    2.659311
         16  {\VBAR}   2.777207   .0483674    57.42   0.000     2.682403    2.872012
         17  {\VBAR}   2.963182    .048519    61.07   0.000     2.868081    3.058284
         18  {\VBAR}   3.124145   .0486294    64.24   0.000     3.028827    3.219462
         19  {\VBAR}   3.305189   .0486698    67.91   0.000     3.209792    3.400586
         20  {\VBAR}   3.518393   .0488488    72.03   0.000     3.422645    3.614141
             {\VBAR}
       _cons {\VBAR}   .6714865   .0731586     9.18   0.000     .5280891    .8148838
\HLI{13}{\BOTT}\HLI{64}
F test of absorbed indicators: F(999, 18972) = 20.923         Prob > F = 0.000
{\smallskip}

```
