*==============================================================
* 08_defence_checks.do : how the result responds to the defence
*
* The defenders' best replies to the heap critique, tested so our
* report can answer them:
*   drop only the 53 ounce heap at 1,503 g
*   drop both heaps, 1,500 g and 1,503 g
*   keep every birth but give rounded weights their own baseline
*     (indicators for 1,500 g, whole ounces and other round tens)
*   keep only births at exact weights, not at any round number
* All with ADKW's controls, one year and 28 day mortality.
*
* Output: output/tables/table8_defence_checks.csv and .md
*==============================================================
version 15

use "data/derived/analysis.dta", clear
keep if in85

local cond1 ""
local cond2 "if grams != 1500"
local cond3 "if abs(dist) > 3"
local cond4 "if grams != 1503"
local cond5 "if grams != 1500 & grams != 1503"
local cond6 ""
local cond7 "if heaped == 0"
local extra6 "h1500 hoz h10"
local test1 "All births (ADKW)"
local test2 "Without exactly 1,500 g"
local test3 "Without 1,497 to 1,503 g"
local test4 "Without 1,503 g only (53 oz)"
local test5 "Without 1,500 g and 1,503 g"
local test6 "All births, rounding indicators"
local test7 "Exact weights only"

tempname h
tempfile res
postfile `h' byte test_id str32 test str12 outcome ///
    double b double se_r double se_g double df_r double df_g long N ///
    using `res', replace

foreach y in death_1yr death_28d {
    forvalues k = 1/7 {
        di as text "  Defence check: `test`k'', `y'"
        local xopt ""
        if "`extra`k''" != "" local xopt "extra(`extra`k'')"
        rdfit `y' `cond`k'', controls($CONTROLS) `xopt'
        post `h' (`k') ("`test`k''") ("`y'") ///
            (r(b)) (r(se_r)) (r(se_g)) (r(df_r)) (r(df_g)) (r(N))
    }
}
postclose `h'

use `res', clear
gen str12 outcome_lab = cond(outcome == "death_1yr", "One year", "28 days")
gen double per100 = -100*b
gen double p_r    = 2*ttail(df_r, abs(b/se_r))
gen double p_g    = 2*ttail(df_g, abs(b/se_g))
gen double cost   = $COST/(-b) if b < 0

format per100 %5.2f
format se_r se_g %7.4f
format p_r p_g %5.3f
format cost %12.0fc
format N %9.0fc
label var outcome_lab "Outcome"
label var test        "Sample or model"
label var per100      "Fewer deaths per 100"
label var se_r        "Robust SE"
label var p_r         "p, robust"
label var se_g        "By gram SE"
label var p_g         "p, by gram"
label var cost        "Cost per life saved"
label var N           "Births"

sort outcome test_id
list outcome_lab test per100 p_r p_g cost N, sepby(outcome) noobs abbreviate(12)

savetab outcome_lab test per100 se_r p_r se_g p_g cost N, ///
    name(table8_defence_checks) ///
    title("Table 8. How the estimate responds to the defence's fixes for rounding") ///
    note("ADKW's all controls regression, births within 85 g. Rounding indicators: separate intercepts for births at exactly 1,500 g, at whole ounces and at other multiples of 10 g. Exact weights: births not recorded at any of those weights. Cost per life: 3,795 dollars divided by the drop in deaths per baby, 2006 US dollars.")

di as text "08_defence_checks.do complete."
