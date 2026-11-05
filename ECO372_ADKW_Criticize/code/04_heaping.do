*==============================================================
* 04_heaping.do : the heap of births at exactly 1,500 g
*
* The critique of Barreca et al. (2011): many weights are rounded,
* births pile up ("heap") at round numbers, and the babies recorded
* at exactly 1,500 g are sicker than their neighbours. VLBW means
* strictly below 1,500 g, so all of them count as untreated.
*
* Output: output/tables/table2_heap_facts      who is in the heap
*         output/tables/table3_round_heaps     1,400 vs 1,500 vs 1,600 g
*         output/figures/fig1_heaping.png      births per gram
*         output/figures/fig2_deaths_by_gram.png
*         output/figures/fig3_rd_plot.png      ADKW Figure II, rebuilt
*==============================================================
version 15

use "data/derived/analysis.dta", clear

*--------------------------------------------------------------
* Table 2: babies at exactly 1,500 g against their neighbours
*--------------------------------------------------------------
gen byte group = .
replace group = 1 if inrange(grams, 1490, 1499)
replace group = 2 if grams == 1500
replace group = 3 if inrange(grams, 1501, 1510)

gen byte white  = race3 == 1
gen byte black  = race3 == 2
gen byte lesshs = meduc4 == 1 if meduc4 != 99     // known education only
gen gestw       = gestat if gestat != 99

local lab1 "1,490 to 1,499 g (below the line)"
local lab2 "Exactly 1,500 g"
local lab3 "1,501 to 1,510 g (above the line)"

tempname h
tempfile res
postfile `h' byte g_id str36 group_lab long births double d1yr double d28 ///
    double pwhite double pblack double plesshs double gest using `res', replace
forvalues g = 1/3 {
    quietly count if group == `g'
    local n = r(N)
    foreach v in death_1yr death_28d white black lesshs {
        quietly summarize `v' if group == `g'
        local m_`v' = 100*r(mean)
    }
    quietly summarize gestw if group == `g'
    local m_gest = r(mean)
    post `h' (`g') ("`lab`g''") (`n') (`m_death_1yr') (`m_death_28d') ///
        (`m_white') (`m_black') (`m_lesshs') (`m_gest')
}
postclose `h'

preserve
use `res', clear
format births %9.0fc
format d1yr d28 pwhite pblack plesshs %5.1f
format gest %5.1f
label var group_lab "Recorded weight"
label var births    "Births"
label var d1yr      "Died within a year (%)"
label var d28       "Died within 28 days (%)"
label var pwhite    "White mother (%)"
label var pblack    "Black mother (%)"
label var plesshs   "Mother without high school (%)"
label var gest      "Weeks of gestation"
list group_lab births d1yr d28 pwhite plesshs, noobs abbreviate(12)
savetab group_lab births d1yr d28 pwhite pblack plesshs gest, ///
    name(table2_heap_facts) ///
    title("Table 2. Babies recorded at exactly 1,500 g are different") ///
    note("US births 1983 to 1991 and 1995 to 2002. Mother without high school: share of mothers with known education. VLBW means strictly below 1,500 g, so every baby at exactly 1,500 g counts as untreated.")
restore

*--------------------------------------------------------------
* Table 3: the 1,500 g heap against the 1,400 g and 1,600 g heaps
* (each heap against births within 10 g of it)
*--------------------------------------------------------------
tempname h3
tempfile res3
postfile `h3' int heap long births double d_heap double d_near double excess ///
    using `res3', replace
foreach c in 1400 1500 1600 {
    quietly count if grams == `c'
    local n = r(N)
    quietly summarize death_1yr if grams == `c'
    local dh = 100*r(mean)
    quietly summarize death_1yr if inrange(grams, `c' - 10, `c' + 10) & grams != `c'
    local dn = 100*r(mean)
    post `h3' (`c') (`n') (`dh') (`dn') (`dh' - `dn')
}
postclose `h3'

preserve
use `res3', clear
format heap %5.0fc
format births %9.0fc
format d_heap d_near excess %5.1f
label var heap   "Heap (g)"
label var births "Births at the heap"
label var d_heap "Deaths per 100 at the heap"
label var d_near "Deaths per 100 within 10 g"
label var excess "Extra deaths per 100"
list, noobs abbreviate(12)
savetab heap births d_heap d_near excess, name(table3_round_heaps) ///
    title("Table 3. Every round number heap holds sicker babies, and 1,500 g most of all") ///
    note("Deaths within one year. Within 10 g: births 10 g either side of the heap, the heap itself excluded.")
restore

*--------------------------------------------------------------
* Figure 1: births per recorded gram
*--------------------------------------------------------------
preserve
keep if inrange(grams, 1415, 1585)
contract grams, freq(births)
gen byte type = 3
replace type = 2 if inlist(grams, $OUNCE_HEAPS)
replace type = 1 if grams == $CUTOFF
quietly summarize births if type == 3, detail
local typical = round(r(p50), 10)
quietly summarize births if grams == 1500
local n1500 = strtrim(string(r(mean), "%9.0fc"))
quietly summarize births if grams == 1503
local n1503 = strtrim(string(r(mean), "%9.0fc"))

twoway (bar births grams if type == 3, barwidth(0.8) color("$GREY"))   ///
       (bar births grams if type == 2, barwidth(0.8) color("$BLUE"))   ///
       (bar births grams if type == 1, barwidth(0.8) color("$ORANGE")), ///
    title("Birth weights pile up on round numbers", color("$NAVY") size(medlarge)) ///
    subtitle("Births per recorded gram, 1,415 to 1,585 g, US births 1983 to 2002") ///
    xtitle("Recorded birth weight (g)") ytitle("Births")                          ///
    xlabel(1420(20)1580) ylabel(0(5000)25000, format(%9.0fc) angle(0))          ///
    yscale(range(0 29000))                                                       ///
    xline(1500, lpattern(dash) lcolor("$DARK"))                                  ///
    text(27500 1497 "Exactly 1,500 g: `n1500' births", place(w) size(vsmall))   ///
    text(27500 1506 "1,503 g (53 oz): `n1503' births", place(e) size(vsmall))   ///
    legend(order(3 "Exactly 1,500 g" 2 "Whole ounces" 1 "Other grams") rows(1) position(6)) ///
    note("Most other grams hold about `typical' births each. Source: our tabulation of the NCHS linked birth and infant death files.") ///
    graphregion(color(white)) plotregion(color(white)) scheme(s1color)
graph export "output/figures/fig1_heaping.png", replace width(2000)
restore

*--------------------------------------------------------------
* Figure 2: deaths per 100 at each recorded gram
*--------------------------------------------------------------
preserve
keep if inrange(grams, 1415, 1585)
collapse (mean) rate = death_1yr (count) births = death_1yr, by(grams)
replace rate = 100*rate
gen byte type = 3
replace type = 2 if inlist(grams, $OUNCE_HEAPS)
replace type = 1 if grams == $CUTOFF

twoway (scatter rate grams if type == 3 [aweight = births], msymbol(O) mcolor("$GREY") mlcolor(white)) ///
       (scatter rate grams if type == 2 [aweight = births], msymbol(O) mcolor("$BLUE") mlcolor(white)) ///
       (scatter rate grams if type == 1 [aweight = births], msymbol(O) mcolor("$ORANGE") mlcolor(white)), ///
    title("Babies recorded at exactly 1,500 g die at higher rates", color("$NAVY") size(medlarge)) ///
    subtitle("Deaths within one year at each recorded gram; marker size shows births") ///
    xtitle("Recorded birth weight (g)") ytitle("Deaths per 100 babies")          ///
    xlabel(1420(20)1580) ylabel(, angle(0))                                       ///
    xline(1500, lpattern(dash) lcolor("$DARK"))                                  ///
    legend(order(3 "Exactly 1,500 g" 2 "Whole ounces" 1 "Other grams") rows(1) position(6)) ///
    note("Source: our calculation from the NCHS linked birth and infant death files.") ///
    graphregion(color(white)) plotregion(color(white)) scheme(s1color)
graph export "output/figures/fig2_deaths_by_gram.png", replace width(2000)
restore

*--------------------------------------------------------------
* Figure 3: ADKW Figure II rebuilt: one ounce bins, fitted lines
*--------------------------------------------------------------
quietly regress death_1yr vlbw x_below x_above if in85
local b0 = _b[_cons]
local b1 = _b[vlbw]
local b2 = _b[x_below]
local b3 = _b[x_above]
local gap : display %4.2f -100*`b1'

preserve
keep if inrange(grams, 1350, 1649)
gen bin = floor((grams - $CUTOFF)/$OUNCE)
keep if inrange(bin, -5, 4)                  // bins that lie fully in the data
collapse (mean) rate = death_1yr, by(bin)
gen mid = $CUTOFF + (bin + 0.5)*$OUNCE
replace rate = 100*rate
list bin mid rate, noobs                    // ADKW Figure II: 5.69 just below, 6.15 just above

twoway (scatter rate mid if mid < $CUTOFF, msymbol(O) msize(large) mcolor("$BLUE"))  ///
       (scatter rate mid if mid > $CUTOFF, msymbol(O) msize(large) mcolor("$GREY"))  ///
       (function y = 100*(`b0' + `b1' + `b2'*(x - $CUTOFF)/100), range(1415 1500)    ///
            lcolor("$BLUE") lwidth(thick))                                          ///
       (function y = 100*(`b0' + `b3'*(x - $CUTOFF)/100), range(1500 1585)           ///
            lcolor("$GREY") lwidth(thick)),                                         ///
    title("Fewer babies die just below the 1,500 g line", color("$NAVY") size(medlarge)) ///
    subtitle("Deaths within one year by birth weight, one ounce bins")           ///
    xtitle("Recorded birth weight (g)") ytitle("Deaths per 100 babies")          ///
    xlabel(1350(50)1650) ylabel(4(1)8, angle(0)) yscale(range(4 8))              ///
    xline(1500, lpattern(dash) lcolor("$DARK"))                                  ///
    text(4.8 1495 "Gap at the line:" "`gap' fewer deaths per 100", place(w) size(small)) ///
    legend(order(1 "Below 1,500 g: labelled very low birth weight" 2 "1,500 g and above") rows(1) position(6)) ///
    note("Lines: OLS on births within 85 g, no controls. Compare ADKW (2010), Figure II.") ///
    graphregion(color(white)) plotregion(color(white)) scheme(s1color)
graph export "output/figures/fig3_rd_plot.png", replace width(2000)
restore

di as text "04_heaping.do complete."
