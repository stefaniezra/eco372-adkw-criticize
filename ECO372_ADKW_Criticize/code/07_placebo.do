*==============================================================
* 07_placebo.do : placebo cutoffs from 1,000 to 3,000 g
*
* Run the same regression discontinuity at 41 cutoffs, every 50 g
* from 1,000 to 3,000 g. Apart from 1,500 g (and the 1,000 g and
* 2,500 g definitions of extremely low and low birth weight), no
* rule changes care at these lines, so a sound design should find
* nothing there. Barreca et al. (2011, footnote 3) report lower
* mortality just below 37 of 41 such cutoffs.
*
* Method: deaths per baby at each recorded gram, regressed on
* "below the cutoff" and a trend on each side, within 85 g,
* weighting each gram by its births. This gives exactly the same
* coefficient as ADKW's OLS with no controls on the individual
* births (at 1,500 g: -0.0095, Table I column 2), and robust
* standard errors here are close to standard errors clustered by
* gram on the individual data.
*
* Input : data/derived/births_by_gram.dta
* Output: output/tables/table7_placebo.csv and .md
*         output/tables/table7b_placebo_summary.csv and .md
*         output/figures/fig6_placebo.png
*==============================================================
version 15

use "data/derived/births_by_gram.dta", clear
collapse (sum) births deaths, by(grams)
gen double rate = deaths/births

tempname h
tempfile res
postfile `h' int cutoff double b double se double df long births int ngrams ///
    using `res', replace

forvalues c = 1000(50)3000 {
    capture drop below xb xa
    gen byte   below = grams < `c'
    gen double xb    = below*(grams - `c')/100
    gen double xa    = (1 - below)*(grams - `c')/100
    quietly regress rate below xb xa if abs(grams - `c') <= $WINDOW [aweight = births], vce(robust)
    local b  = _b[below]
    local se = _se[below]
    local df = e(df_r)
    local ng = e(N)
    quietly summarize births if abs(grams - `c') <= $WINDOW
    post `h' (`c') (`b') (`se') (`df') (r(sum)) (`ng')
}
postclose `h'

use `res', clear
gen double per100 = -100*b
gen double t      = b/se
gen double p      = 2*ttail(df, abs(t))
gen byte   lower_below = b < 0
gen byte   round100    = mod(cutoff, 100) == 0
gen str32  kind = cond(cutoff == 1500, "VLBW cutoff (the paper)",        ///
                  cond(cutoff == 1000, "ELBW cutoff (real rule)",        ///
                  cond(cutoff == 2500, "LBW cutoff (real rule)",         ///
                  cond(round100, "Round 100 g, no rule", "50 g, no rule"))))

format cutoff %5.0fc
format per100 t %6.2f
format se %7.4f
format p %5.3f
format births %12.0fc
label var cutoff      "Cutoff (g)"
label var kind        "Cutoff type"
label var per100      "Fewer deaths per 100 just below"
label var se          "Robust SE"
label var p           "p"
label var lower_below "Lower just below"
label var births      "Births in window"

list cutoff kind per100 p, noobs abbreviate(12) sep(10)
savetab cutoff kind per100 se p births, name(table7_placebo) ///
    title("Table 7. Placebo cutoffs: the same design at 41 lines from 1,000 to 3,000 g") ///
    note("OLS with no controls on deaths per baby at each recorded gram within 85 g of the cutoff, weighted by births, separate slopes on each side. Positive values mean fewer deaths just below the cutoff. Robust standard errors. US births 1983 to 1991 and 1995 to 2002, imputed weights dropped.")

*--------------------------------------------------------------
* Summary: how often is mortality lower just below the line?
*--------------------------------------------------------------
tempname s
tempfile sum
postfile `s' str40 group int lower int total int signif using `sum', replace
quietly count if lower_below
local a = r(N)
quietly count
local t = r(N)
quietly count if lower_below & p < 0.05
post `s' ("All 41 cutoffs") (`a') (`t') (r(N))

quietly count if lower_below & round100
local a = r(N)
quietly count if round100
local t = r(N)
quietly count if lower_below & round100 & p < 0.05
post `s' ("Round 100 g cutoffs, 1,000 to 3,000 g") (`a') (`t') (r(N))

quietly count if lower_below & !round100
local a = r(N)
quietly count if !round100
local t = r(N)
quietly count if lower_below & !round100 & p < 0.05
post `s' ("Other 50 g cutoffs") (`a') (`t') (r(N))
postclose `s'

preserve
use `sum', clear
gen double share = 100*lower/total
format share %5.0f
label var group  "Cutoffs"
label var lower  "Lower just below"
label var total  "Cutoffs tested"
label var share  "Share (%)"
label var signif "Lower and significant at 5%"
list, noobs abbreviate(12)
savetab group lower total share signif, name(table7b_placebo_summary) ///
    title("Table 7b. Mortality is lower just below almost every round 100 g line") ///
    note("Heaps of rounded weights sit at round 100 g numbers, and the babies in them count as above the line. That makes being just below any round number look good, whether or not care changes there.")
restore

*--------------------------------------------------------------
* Figure 6: placebo estimates by cutoff
*--------------------------------------------------------------
gen double lo = per100 - 196*se
gen double hi = per100 + 196*se
twoway (rcap lo hi cutoff if !round100, lcolor("$GREY"))                            ///
       (rcap lo hi cutoff if round100, lcolor("$BLUE"))                             ///
       (scatter per100 cutoff if !round100, msymbol(O) mcolor("$GREY"))             ///
       (scatter per100 cutoff if round100 & cutoff != 1500, msymbol(O) mcolor("$BLUE")) ///
       (scatter per100 cutoff if cutoff == 1500, msymbol(O) msize(large) mcolor("$ORANGE")), ///
    title("Being just below a round 100 g line looks good almost everywhere", color("$NAVY") size(medlarge)) ///
    subtitle("Fewer deaths per 100 babies just below each cutoff, within 85 g, no controls") ///
    xtitle("Cutoff (g)") ytitle("Fewer deaths per 100 babies")                    ///
    xlabel(1000(250)3000, format(%9.0fc)) ylabel(, angle(0))                       ///
    yline(0, lpattern(dash) lcolor("$DARK"))                                      ///
    legend(order(5 "1,500 g, the paper's cutoff" 4 "Other round 100 g lines" 3 "50 g lines") rows(1) position(6)) ///
    note("Lines: 95% ranges, robust standard errors. Source: our calculation from the NCHS linked files.") ///
    graphregion(color(white)) plotregion(color(white)) scheme(s1color)
graph export "output/figures/fig6_placebo.png", replace width(2000)

di as text "07_placebo.do complete."
