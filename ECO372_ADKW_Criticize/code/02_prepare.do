*==============================================================
* 02_prepare.do : analysis variables
*
* Input : data/derived/vlbw_sample.dta  (births 1,350 to 1,650 g)
* Output: data/derived/analysis.dta     (same births, plus the
*         regression variables; not tracked, rebuilt each run)
*==============================================================
version 15

use "data/derived/vlbw_sample.dta", clear
assert inrange(grams, 1350, 1650)
assert vlbw == (grams < $CUTOFF)

* Trends in hundreds of grams, a separate slope on each side
* of the cutoff (ADKW equation 1)
gen double x       = dist/100
gen double x_below = vlbw*x
gen double x_above = (1 - vlbw)*x

* An unknown control value is its own category
foreach v of varlist year mpcb mage5 meduc4 fage5 csex gestat race3 plural border {
    quietly replace `v' = 99 if missing(`v')
}

* The paper's window: within 85 g (3 ounces) of 1,500 g
gen byte in85 = abs(dist) <= $WINDOW

* Rounded ("heaped") recorded weights
gen byte h1500  = grams == $CUTOFF
gen byte hoz    = inlist(grams, $OUNCE_HEAPS)
gen byte h10    = mod(grams, 10) == 0 & grams != $CUTOFF
gen byte heaped = h1500 == 1 | hoz == 1 | h10 == 1

label var x       "Grams from 1,500, in hundreds"
label var x_below "x if below 1,500 g"
label var x_above "x if 1,500 g or above"
label var in85    "Within 85 g of 1,500 g"
label var h1500   "Recorded at exactly 1,500 g"
label var hoz     "Recorded at a whole ounce"
label var h10     "Recorded at another multiple of 10 g"
label var heaped  "Recorded at any rounded weight"

compress
save "data/derived/analysis.dta", replace

*--------------------------------------------------------------
* Checks against the papers
*--------------------------------------------------------------
quietly count if in85
local n85 = r(N)
quietly count if in85 & h1500
local nheap = r(N)
quietly summarize death_1yr if in85 & dist >= 0
local mabove = 100*r(mean)

di _n as result "Sample checks"
di as text "  Births within 85 g:        " as result %9.0fc `n85'   as text "   (ADKW 202,071; Barreca et al. 202,078)"
di as text "  Births at exactly 1,500 g: " as result %9.0fc `nheap' as text "   (Barreca et al. 3,544)"
di as text "  Deaths per 100 just above: " as result %9.2f `mabove' as text "   (ADKW Table I: 5.53)"
