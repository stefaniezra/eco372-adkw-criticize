*==============================================================
* 05_donut.do : the donut test of Barreca et al. (2011, Table I)
*
* If the drop in deaths comes from extra care, removing a few
* births right at the cutoff should barely change it. We drop the
* births at exactly 1,500 g, then those within 1, 2 and 3 g of it,
* and rerun ADKW's all controls regression on what is left.
* The 3 g hole (1,497 to 1,503 g) also removes the 53 ounce heap
* at 1,503 g, about 11% of all births in the window.
*
* Then the cost per life saved, 3,795 dollars divided by each estimate.
*
* Output: output/tables/table4_donut.csv and .md
*         output/tables/table5_cost_per_life.csv and .md
*         output/figures/fig4_donut.png
*==============================================================
version 15

use "data/derived/analysis.dta", clear
keep if in85
quietly count
local N0 = r(N)

local cond1 ""
local cond2 "if grams != 1500"
local cond3 "if abs(dist) > 1"
local cond4 "if abs(dist) > 2"
local cond5 "if abs(dist) > 3"
local hole1 "Nothing"
local hole2 "Exactly 1,500 g"
local hole3 "1,499 to 1,501 g"
local hole4 "1,498 to 1,502 g"
local hole5 "1,497 to 1,503 g"

tempname h
tempfile res
postfile `h' byte out_id byte hole_id str16 hole str12 outcome ///
    double b double se_r double se_g double df_r double df_g long N ///
    using `res', replace

local o = 0
foreach y in death_1yr death_28d death_7d death_24h {
    local ++o
    forvalues k = 1/5 {
        di as text "  Donut: `y', removing `hole`k''"
        rdfit `y' `cond`k'', controls($CONTROLS)
        post `h' (`o') (`k') ("`hole`k''") ("`y'") ///
            (r(b)) (r(se_r)) (r(se_g)) (r(df_r)) (r(df_g)) (r(N))
    }
}
postclose `h'

use `res', clear

*--------------------------------------------------------------
* Published values, Barreca et al. (2011) Table I, Panels A to E
* (standard errors clustered by gram)
*--------------------------------------------------------------
local pb1 -0.0071 -0.0033 -0.0035 -0.0027 -0.0018
local pb2 -0.0071 -0.0042 -0.0043 -0.0037 -0.0026
local pb3 -0.0046 -0.0023 -0.0024 -0.0019 -0.0018
local pb4 -0.0033 -0.0018 -0.0018 -0.0013 -0.0011
local pg1  0.0041  0.0014  0.0014  0.0014  0.0019
local pg2  0.0032  0.0013  0.0012  0.0012  0.0015
local pg3  0.0028  0.0013  0.0013  0.0012  0.0015
local pg4  0.0020  0.0010  0.0010  0.0009  0.0014

gen double pub_b    = .
gen double pub_se_g = .
forvalues o = 1/4 {
    forvalues k = 1/5 {
        local vb : word `k' of `pb`o''
        local vg : word `k' of `pg`o''
        quietly replace pub_b    = `vb' if out_id == `o' & hole_id == `k'
        quietly replace pub_se_g = `vg' if out_id == `o' & hole_id == `k'
    }
}

gen str12 outcome_lab = ""
replace outcome_lab = "One year" if out_id == 1
replace outcome_lab = "28 days"  if out_id == 2
replace outcome_lab = "7 days"   if out_id == 3
replace outcome_lab = "24 hours" if out_id == 4

gen long   removed = `N0' - N
gen double pct_removed = 100*removed/`N0'
gen double per100 = -100*b
gen double t_g    = b/se_g
gen double p_g    = 2*ttail(df_g, abs(t_g))
gen str16 by_gram = cond(p_g < 0.05, "significant", "could be chance")
bysort out_id (hole_id): gen double pct_of_full = 100*b/b[1]

format b pub_b se_g pub_se_g se_r %8.4f
format per100 t_g %6.2f
format p_g %5.3f
format pct_removed pct_of_full %5.1f
format N removed %9.0fc

label var outcome_lab "Outcome"
label var hole        "Births removed"
label var b           "Ours"
label var pub_b       "Barreca et al."
label var se_g        "By gram SE, ours"
label var pub_se_g    "By gram SE, Barreca et al."
label var per100      "Fewer deaths per 100"
label var pct_of_full "Share of full estimate (%)"
label var pct_removed "Births removed (%)"
label var p_g         "p, by gram"
label var by_gram     "By gram verdict"
label var N           "Births"

sort out_id hole_id
list outcome_lab hole b pub_b se_g pub_se_g pct_of_full N, sepby(out_id) noobs abbreviate(12)

savetab outcome_lab hole b pub_b se_g pub_se_g per100 pct_of_full pct_removed p_g by_gram N, ///
    name(table4_donut) ///
    title("Table 4. The donut test: remove births at the cutoff and the effect shrinks") ///
    note("ADKW's all controls regression, births within 85 g, after removing the births listed. Barreca et al. (2011), Table I, report the same regressions; our sample has the same number of births in every row. By gram: standard errors clustered by recorded gram.")

save "data/derived/results_donut.dta", replace

*--------------------------------------------------------------
* Figure 4: one year estimate as the hole grows, 95% ranges by gram
*--------------------------------------------------------------
preserve
keep if out_id == 1
gen double tcrit = invttail(df_g, 0.025)
gen double lo = per100 - 100*tcrit*se_g
gen double hi = per100 + 100*tcrit*se_g
gen byte ypos = 6 - hole_id
label define holes 5 "Nothing removed" 4 "Exactly 1,500 g" 3 "1,499 to 1,501 g" ///
                   2 "1,498 to 1,502 g" 1 "1,497 to 1,503 g"
label values ypos holes
gen lab = string(per100, "%4.2f")

twoway (rcap lo hi ypos, horizontal lcolor("$GREY") lwidth(medthick))                 ///
       (scatter ypos per100, msymbol(O) msize(large) mcolor("$NAVY")                   ///
            mlabel(lab) mlabposition(12) mlabcolor(black) mlabsize(small)),            ///
    title("Remove a few grams at the cutoff and most of the effect goes", color("$NAVY") size(medlarge)) ///
    subtitle("Fewer deaths per 100 babies just below 1,500 g, one year, all controls")  ///
    xtitle("Fewer deaths per 100 babies (dot) and 95% range clustered by gram (line)") ///
    ytitle("Births removed") ylabel(1(1)5, valuelabel angle(0) noticks)                 ///
    yscale(range(0.5 5.7)) xline(0, lpattern(dash) lcolor("$DARK"))                    ///
    legend(off)                                                                        ///
    note("Same regression and sample as Barreca et al. (2011), Table I.")              ///
    graphregion(color(white)) plotregion(color(white)) scheme(s1color)
graph export "output/figures/fig4_donut.png", replace width(2000)
restore

*--------------------------------------------------------------
* Table 5: cost per life saved = extra cost per baby / fewer deaths
* per baby, holding ADKW's 3,795 dollar cost jump fixed
*--------------------------------------------------------------
keep if out_id == 1
gen double tcrit = invttail(df_g, 0.025)
gen double b_most  = b - tcrit*se_g      // most lives saved in the 95% range
gen double b_least = b + tcrit*se_g      // fewest lives saved in the 95% range
gen double cost      = $COST/(-b)
gen double cost_low  = $COST/(-b_most)
gen str24  cost_high = cond(b_least < 0, strtrim(string($COST/(-b_least), "%14.0fc")), "no upper limit")
gen double ratio_vsl = cost/$VSL

format cost cost_low %12.0fc
format ratio_vsl %5.2f
label var cost      "Cost per life saved"
label var cost_low  "Lowest in 95% range"
label var cost_high "Highest in 95% range"
label var ratio_vsl "Share of the 2.7 million value of a life"

list hole per100 cost cost_low cost_high, noobs abbreviate(12)
savetab hole per100 cost cost_low cost_high ratio_vsl, name(table5_cost_per_life) ///
    title("Table 5. The cost per life saved depends on which births are kept") ///
    note("2006 US dollars. Cost per life = 3,795 dollars of extra hospital cost per baby (ADKW Section VIII.B) divided by the drop in one year deaths per baby. The 95% range uses standard errors clustered by gram; when it includes zero, the cost per life has no upper limit. The cost jump is held fixed because the hospital cost data are not public.")

di as text "05_donut.do complete."
