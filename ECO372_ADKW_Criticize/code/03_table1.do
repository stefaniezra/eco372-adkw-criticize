*==============================================================
* 03_table1.do : reproduce ADKW (2010) Table I
*
* Four mortality outcomes, four specifications, births within 85 g:
*   1 local linear, triangle kernel, no controls
*   2 OLS, no controls
*   3 OLS, year controls
*   4 OLS, all controls (the estimate ADKW use for the cost per life)
* Each with the robust and the by gram standard error, next to the
* published numbers.
*
* Output: output/tables/table1_adkw.csv and .md
*==============================================================
version 15

use "data/derived/analysis.dta", clear
keep if in85
gen double tri = 1 - abs(dist)/$WINDOW     // triangle kernel weights

tempname h
tempfile res
postfile `h' byte out_id byte spec_id str26 spec str12 outcome ///
    double b double se_r double se_g double df_r double df_g long N ///
    using `res', replace

local o = 0
foreach y in death_1yr death_28d death_7d death_24h {
    local ++o
    di as text "  Table I: `y'"

    rdfit `y' [aweight = tri]
    post `h' (`o') (1) ("Local linear, no controls") ("`y'") ///
        (r(b)) (r(se_r)) (r(se_g)) (r(df_r)) (r(df_g)) (r(N))

    rdfit `y'
    post `h' (`o') (2) ("OLS, no controls") ("`y'") ///
        (r(b)) (r(se_r)) (r(se_g)) (r(df_r)) (r(df_g)) (r(N))

    rdfit `y', controls(i.year)
    post `h' (`o') (3) ("OLS, year controls") ("`y'") ///
        (r(b)) (r(se_r)) (r(se_g)) (r(df_r)) (r(df_g)) (r(N))

    rdfit `y', controls($CONTROLS)
    post `h' (`o') (4) ("OLS, all controls") ("`y'") ///
        (r(b)) (r(se_r)) (r(se_g)) (r(df_r)) (r(df_g)) (r(N))
}
postclose `h'

use `res', clear

*--------------------------------------------------------------
* Published values, ADKW (2010) Table I, in the order
* local linear, OLS, OLS + year, OLS + all controls.
* The local linear column reports no by gram error (".").
* Two cells look like typos in the published table:
*   one year, year controls: -0.0067 (the text, p. 610, says -0.0076)
*   24 hours: the local linear entry repeats the 7 day one, and the
*   year controls entry is printed without its minus sign
*--------------------------------------------------------------
local pb1 -0.0121 -0.0095 -0.0067 -0.0072
local pb2 -0.0107 -0.0088 -0.0074 -0.0073
local pb3 -0.0068 -0.0060 -0.0049 -0.0047
local pb4 -0.0068 -0.0043  0.0036 -0.0035
local pr1  0.0023  0.0022  0.0022  0.0022
local pr2  0.0019  0.0018  0.0018  0.0018
local pr3  0.0017  0.0016  0.0016  0.0016
local pr4  0.0017  0.0013  0.0013  0.0013
local pg1  .       0.0048  0.0040  0.0040
local pg2  .       0.0038  0.0031  0.0031
local pg3  .       0.0032  0.0027  0.0027
local pg4  .       0.0023  0.0020  0.0020

gen double pub_b    = .
gen double pub_se_r = .
gen double pub_se_g = .
forvalues o = 1/4 {
    forvalues s = 1/4 {
        local vb : word `s' of `pb`o''
        local vr : word `s' of `pr`o''
        local vg : word `s' of `pg`o''
        quietly replace pub_b    = `vb' if out_id == `o' & spec_id == `s'
        quietly replace pub_se_r = `vr' if out_id == `o' & spec_id == `s'
        quietly replace pub_se_g = `vg' if out_id == `o' & spec_id == `s'
    }
}

gen str12 outcome_lab = ""
replace outcome_lab = "One year" if out_id == 1
replace outcome_lab = "28 days"  if out_id == 2
replace outcome_lab = "7 days"   if out_id == 3
replace outcome_lab = "24 hours" if out_id == 4

gen double per100 = -100*b                  // fewer deaths per 100 babies
gen double t_r    = b/se_r
gen double t_g    = b/se_g
gen double p_r    = 2*ttail(df_r, abs(t_r))
gen double p_g    = 2*ttail(df_g, abs(t_g))
gen str16 by_gram = cond(p_g < 0.05, "significant", "could be chance")

format b pub_b se_r pub_se_r se_g pub_se_g %8.4f
format per100 t_r t_g %6.2f
format p_r p_g %5.3f
format N %9.0fc

label var outcome_lab "Outcome"
label var spec        "Specification"
label var b           "Ours"
label var pub_b       "Published"
label var se_r        "Robust SE, ours"
label var pub_se_r    "Robust SE, published"
label var se_g        "By gram SE, ours"
label var pub_se_g    "By gram SE, published"
label var per100      "Fewer deaths per 100"
label var p_g         "p, by gram"
label var by_gram     "By gram verdict"
label var N           "Births"

sort out_id spec_id
list outcome_lab spec b pub_b se_r pub_se_r se_g pub_se_g, sepby(out_id) noobs abbreviate(12)

savetab outcome_lab spec b pub_b se_r pub_se_r se_g pub_se_g per100 p_g by_gram N, ///
    name(table1_adkw) ///
    title("Table 1. Reproduction of ADKW (2010) Table I: mortality and very low birth weight") ///
    note("Coefficient on birth weight below 1,500 g; negative means fewer deaths below the line. Births within 85 g of 1,500 g, US births 1983 to 1991 and 1995 to 2002. Local linear: triangle kernel. All controls: year, month prenatal care began, mother's age, education and race, father's age, sex, weeks of gestation, plurality and birth order. Published Table I prints -0.0067 for one year with year controls; the paper's text and our estimate give -0.0076. By gram: standard errors clustered by recorded gram, as in Barreca et al. (2011).")

* Headline checks
quietly summarize b if out_id == 1 & spec_id == 1
di as text _n "Headline (local linear, one year): " as result %7.4f r(mean) as text "   published -0.0121"
quietly summarize b if out_id == 1 & spec_id == 4
di as text "Cost per life estimate (all controls, one year): " as result %7.4f r(mean) as text "   published -0.0072"

* keep the results for later files
save "data/derived/results_table1.dta", replace
