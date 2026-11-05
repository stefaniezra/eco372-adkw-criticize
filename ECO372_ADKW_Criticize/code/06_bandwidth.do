*==============================================================
* 06_bandwidth.do : bandwidth sensitivity (ADKW Online Appendix Table A3)
*
* ADKW's local linear estimate at windows of 30 to 150 g either
* side of the cutoff. The paper reads the falling estimate as a
* sign that its 85 g window is conservative. Our reading: the
* estimate is largest in the narrowest window, where the heaps at
* the cutoff weigh most, and it more than triples from 150 g to 30 g.
*
* Output: output/tables/table6_bandwidth.csv and .md
*         output/figures/fig5_bandwidth.png
*==============================================================
version 15

use "data/derived/analysis.dta", clear   // all births 1,350 to 1,650 g

tempname h
tempfile res
postfile `h' byte out_id int bw str12 outcome ///
    double b double se_r double se_g double df_r double df_g long N ///
    using `res', replace

local o = 0
foreach y in death_1yr death_28d {
    local ++o
    foreach bw in 30 60 85 90 120 150 {
        di as text "  Bandwidth `bw' g: `y'"
        capture drop tri_bw
        gen double tri_bw = 1 - abs(dist)/`bw' if abs(dist) <= `bw'
        rdfit `y' if abs(dist) <= `bw' [aweight = tri_bw]
        post `h' (`o') (`bw') ("`y'") ///
            (r(b)) (r(se_r)) (r(se_g)) (r(df_r)) (r(df_g)) (r(N))
    }
}
postclose `h'

use `res', clear

* Published, ADKW Online Appendix Table A3 (fewer deaths per 100);
* 85 g is the paper's main window, from Table I
gen double pub_per100 = .
local p1 2.67 1.62 1.21 1.14 0.91 0.87
local p2 2.28 1.46 1.07 1.01 0.83 0.77
local bws 30 60 85 90 120 150
forvalues o = 1/2 {
    forvalues j = 1/6 {
        local bw : word `j' of `bws'
        local v  : word `j' of `p`o''
        quietly replace pub_per100 = `v' if out_id == `o' & bw == `bw'
    }
}

gen str12 outcome_lab = cond(out_id == 1, "One year", "28 days")
gen double per100 = -100*b
gen double p_r    = 2*ttail(df_r, abs(b/se_r))
gen double p_g    = 2*ttail(df_g, abs(b/se_g))
bysort out_id (bw): gen double rel_150 = per100/per100[_N]

format per100 pub_per100 %5.2f
format se_r se_g %7.4f
format p_r p_g %5.3f
format rel_150 %4.1f
format N %9.0fc
label var outcome_lab "Outcome"
label var bw          "Window (g either side)"
label var per100      "Fewer deaths per 100, ours"
label var pub_per100  "Published"
label var se_r        "Robust SE"
label var se_g        "By gram SE"
label var p_r         "p, robust"
label var p_g         "p, by gram"
label var rel_150     "Times the 150 g estimate"
label var N           "Births"

sort out_id bw
list outcome_lab bw per100 pub_per100 rel_150 p_g, sepby(out_id) noobs abbreviate(12)

savetab outcome_lab bw per100 pub_per100 rel_150 se_r p_r se_g p_g N, ///
    name(table6_bandwidth) ///
    title("Table 6. The estimate triples as the window narrows onto the heaps") ///
    note("Local linear regression, triangle kernel, no controls, as in ADKW Online Appendix Table A3; the 85 g row is ADKW Table I, column 1. Negative coefficients are shown as fewer deaths per 100 babies just below 1,500 g.")

*--------------------------------------------------------------
* Figure 5: one year estimate by window
*--------------------------------------------------------------
keep if out_id == 1 & bw != 85             // 85 g sits next to 90 g; it is in the table
gen double tcrit = invttail(df_g, 0.025)
gen double lo = per100 - 100*tcrit*se_g
gen double hi = per100 + 100*tcrit*se_g
gen lab = string(per100, "%4.2f")

twoway (rcap lo hi bw, lcolor("$GREY") lwidth(medthick))                              ///
       (scatter per100 bw, msymbol(O) msize(large) mcolor("$NAVY")                    ///
            mlabel(lab) mlabposition(3) mlabcolor(black) mlabsize(small))             ///
       (scatter pub_per100 bw, msymbol(Dh) msize(medlarge) mcolor("$ORANGE")),        ///
    title("The narrower the window, the bigger the effect", color("$NAVY") size(medlarge)) ///
    subtitle("Fewer deaths per 100 babies within one year, local linear, no controls")     ///
    xtitle("Window: grams either side of 1,500 g") ytitle("Fewer deaths per 100 babies") ///
    xlabel(30 60 90 120 150) ylabel(, angle(0)) yline(0, lpattern(dash) lcolor("$DARK")) ///
    legend(order(2 "Our estimate" 3 "ADKW Online Appendix Table A3" 1 "95% range, by gram") rows(1) position(6)) ///
    note("Source: our reproduction from the NCHS linked birth and infant death files.")     ///
    graphregion(color(white)) plotregion(color(white)) scheme(s1color)
graph export "output/figures/fig5_bandwidth.png", replace width(2000)

di as text "06_bandwidth.do complete."
