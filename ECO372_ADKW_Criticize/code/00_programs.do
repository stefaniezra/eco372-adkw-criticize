*==============================================================
* 00_programs.do : settings and helper programs
*
* Defines the paper's settings as globals and three programs:
*   rdfit     the paper's regression, with two standard errors
*   md_table  writes the data in memory as a Markdown table
*   savetab   saves a table as .csv and .md in output/tables
*==============================================================
version 15

*--------------------------------------------------------------
* Settings from the paper
*--------------------------------------------------------------
global CUTOFF 1500     // very low birth weight = strictly below 1,500 g (ADKW fn. 8)
global WINDOW 85       // ADKW's window: 3 ounces either side of the cutoff
global OUNCE  28.349523125
global COST   3795     // ADKW's extra hospital cost per VLBW baby, 2006 dollars (Sec. VIII.B)
global VSL    2700000  // value of a newborn life near 1,500 g (Cutler and Meara 2000, cited by ADKW)

* ADKW's controls (Table I note; Barreca et al. Table I note).
* Every control enters as a set of categories, and an unknown
* value (coded 99) is its own category, which does the job of
* the paper's missing value indicators.
global CONTROLS i.year i.mpcb i.mage5 i.meduc4 i.fage5 i.csex ///
                i.gestat i.race3 i.plural i.border

* Recorded weights that are whole ounces (50 to 55 oz) inside the window
global OUNCE_HEAPS 1417, 1418, 1446, 1474, 1503, 1531, 1559

* Figure colours (RGB)
global NAVY   "24 72 160"
global BLUE   "30 82 180"
global ORANGE "214 119 48"
global GREY   "163 168 176"
global DARK   "91 98 112"

*--------------------------------------------------------------
* rdfit: ADKW's regression (equation 1)
*
*   outcome = a + b*vlbw + c1*vlbw*x + c2*(1 - vlbw)*x + controls + e
*
* where x is grams from 1,500 in hundreds, so each side of the
* cutoff has its own slope. b is the jump at the cutoff.
* Reports b with two standard errors:
*   se_r  heteroskedasticity robust (the paper's round brackets)
*   se_g  clustered by recorded gram (the paper's square brackets,
*         and the only kind Barreca et al. report)
*
* Usage:  rdfit outcome [if] [aweight], [controls(...) extra(...)]
*--------------------------------------------------------------
capture program drop rdfit
program define rdfit, rclass
    version 15
    syntax varname(numeric) [if] [aweight] [, CONTROLS(string) EXTRA(string)]
    local wgt ""
    if "`weight'" != "" local wgt "[`weight'`exp']"

    quietly regress `varlist' vlbw x_below x_above `extra' `controls' `if' `wgt', vce(robust)
    return scalar b    = _b[vlbw]
    return scalar se_r = _se[vlbw]
    return scalar df_r = e(df_r)
    return scalar N    = e(N)

    quietly regress `varlist' vlbw x_below x_above `extra' `controls' `if' `wgt', vce(cluster grams)
    return scalar se_g = _se[vlbw]
    return scalar df_g = e(df_r)
    return scalar G    = e(N_clust)
end

*--------------------------------------------------------------
* md_table: write variables in memory as a Markdown table.
* Uses each variable's label as its column name and each numeric
* variable's display format for its cells.
*--------------------------------------------------------------
capture program drop md_table
program define md_table
    version 15
    syntax varlist using/ [, TITLE(string) NOTE(string)]
    tempname f
    file open `f' using `"`using'"', write replace text
    if `"`title'"' != "" {
        file write `f' `"## `title'"' _n _n
    }
    local head "|"
    local rule "|"
    foreach v of local varlist {
        local lab : variable label `v'
        if `"`lab'"' == "" local lab "`v'"
        local head `"`head' `lab' |"'
        local rule "`rule' --- |"
    }
    file write `f' `"`head'"' _n `"`rule'"' _n
    local n = _N
    forvalues i = 1/`n' {
        local row "|"
        foreach v of local varlist {
            capture confirm string variable `v'
            if _rc == 0 {
                local cell = `v'[`i']
            }
            else if missing(`v'[`i']) {
                local cell ""
            }
            else {
                local fmt : format `v'
                local cell : display `fmt' `v'[`i']
                local cell = strtrim(`"`cell'"')
            }
            local row `"`row' `cell' |"'
        }
        file write `f' `"`row'"' _n
    }
    if `"`note'"' != "" {
        file write `f' _n `"`note'"' _n
    }
    file close `f'
end

*--------------------------------------------------------------
* savetab: save chosen variables as output/tables/NAME.csv and .md
*--------------------------------------------------------------
capture program drop savetab
program define savetab
    version 15
    syntax varlist, NAME(string) [TITLE(string) NOTE(string)]
    export delimited `varlist' using "output/tables/`name'.csv", replace
    md_table `varlist' using "output/tables/`name'.md", title(`"`title'"') note(`"`note'"')
    di as text "  saved output/tables/`name'.csv and output/tables/`name'.md"
end

di as text "00_programs.do: settings and programs loaded."
