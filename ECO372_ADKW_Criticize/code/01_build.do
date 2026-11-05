*==============================================================
* 01_build.do : build both samples from the raw NCHS files
*
* Runs only if REBUILD = 1 in master.do (or a sample is missing).
*
* Input : data/raw/linkcoYYYYus_den.dta   all births in year YYYY
*         data/raw/linkcoYYYYus_num.dta   infant deaths linked to them
*         NBER Stata versions, 1983 to 1991 and 1995 to 2002
*         (NCHS made no linked files for 1992 to 1994). 34 files.
*
* Output: data/derived/vlbw_sample.dta
*           one row per birth weighing 1,350 to 1,650 g, with the
*           mortality outcomes and controls used in the paper
*         data/derived/births_by_gram.dta
*           births and one year deaths by year and recorded gram,
*           915 to 3,085 g, for the placebo cutoffs in 07_placebo.do
*
* How the raw files fit together
*   The births file flags babies who died in their first year
*   (variable matchs), but only the deaths file says WHEN they died
*   (ager5). Before 1989 there is no ID to merge on, so we stack:
*   survivors come from the births file, deaths from the deaths file.
*   The matchs codes change over time (1983: 1 or 2 = died,
*   3 = survived; 1995: 1 = died, 2 = survived), so each year we
*   read the "died" codes from that year's deaths file.
*
* Sample rules (ADKW Section III.B and footnote 20)
*   drop imputed birth weights (bwif == 1, recorded from 1995)
*   drop deaths with no age at death
*==============================================================
version 15

local years 1983 1984 1985 1986 1987 1988 1989 1990 1991 ///
            1995 1996 1997 1998 1999 2000 2001 2002

* Every variable we need. 1983 to 1988 call gestation dgestat;
* later years call it gestat. bwif exists from 1995 and ager5
* is missing from the 1983 to 1988 births files.
local wanted matchs dbirwt bwif dgestat gestat csex dplural mrace ///
             dmage dfage dmeduc mpcb dtotord ager5

capture program drop harmonize
program define harmonize
    capture rename dgestat gestat
    foreach v of varlist _all {
        capture confirm string variable `v'
        if _rc == 0 {
            quietly destring `v', replace force
        }
    }
    foreach v in bwif ager5 {
        capture confirm variable `v'
        if _rc {
            quietly gen byte `v' = .
        }
    }
end

tempfile deaths dead_counts stack wide
local first 1

foreach y of local years {
    di _n as result "==================== `y' ===================="
    local den "data/raw/linkco`y'us_den.dta"
    local num "data/raw/linkco`y'us_num.dta"
    foreach f in den num {
        capture confirm file "``f''"
        if _rc {
            di as error "Missing ``f''. See data/raw/README.md for the 34 files to download."
            exit 601
        }
    }

    *----------------------------------------------------------
    * 1. Deaths file (small): the codes that mean "died", then
    *    deaths by gram for the placebo sample, then deaths in
    *    the main window
    *----------------------------------------------------------
    quietly describe using "`num'", varlist
    local have `r(varlist)'
    local keep : list wanted & have
    use `keep' using "`num'", clear
    harmonize
    quietly levelsof matchs, local(deadcodes)
    di as text "  matchs codes that mean died: `deadcodes'"

    drop if bwif == 1
    drop if missing(ager5)

    preserve
    keep if inrange(dbirwt, 915, 3085)
    contract dbirwt, freq(deaths)
    save `dead_counts', replace
    restore

    keep if inrange(dbirwt, 1350, 1650)
    gen byte died = 1
    local n_dead = _N
    save `deaths', replace

    *----------------------------------------------------------
    * 2. Births file: drop the babies flagged as deaths (they are
    *    already in the deaths file), keep survivors
    *----------------------------------------------------------
    quietly describe using "`den'", varlist
    local have `r(varlist)'
    local keep : list wanted & have
    use `keep' if inrange(dbirwt, 915, 3085) using "`den'", clear
    harmonize

    gen byte linked = 0
    foreach c of local deadcodes {
        quietly replace linked = 1 if matchs == `c'
    }
    quietly count if linked == 1 & inrange(dbirwt, 1350, 1650)
    di as text "  deaths 1,350 to 1,650 g: flagged in births file " as result r(N) ///
       as text ", in deaths file " as result `n_dead'
    drop if linked == 1
    drop linked
    drop if bwif == 1
    quietly replace ager5 = .

    *----------------------------------------------------------
    * 3. Placebo sample: births and deaths by gram, 915 to 3,085 g
    *----------------------------------------------------------
    preserve
    contract dbirwt, freq(survivors)
    merge 1:1 dbirwt using `dead_counts', nogenerate
    quietly replace survivors = 0 if missing(survivors)
    quietly replace deaths    = 0 if missing(deaths)
    gen long births = survivors + deaths
    gen int year = `y'
    keep year dbirwt births deaths
    if `first' == 0 {
        append using `wide'
    }
    save `wide', replace
    restore

    *----------------------------------------------------------
    * 4. Main sample: survivors and deaths, 1,350 to 1,650 g
    *----------------------------------------------------------
    keep if inrange(dbirwt, 1350, 1650)
    gen byte died = 0
    append using `deaths'
    gen int year = `y'
    di as text "  births 1,350 to 1,650 g: " as result _N
    if `first' == 0 {
        append using `stack'
    }
    save `stack', replace
    local first 0
}

*==============================================================
* Main sample: variables
*==============================================================
use `stack', clear

gen int  grams = dbirwt
gen int  dist  = dbirwt - $CUTOFF       // grams from the cutoff
gen byte vlbw  = dbirwt < $CUTOFF       // VLBW = strictly below 1,500 g (ADKW fn. 8)

* Outcomes. ager5: 1 under 1 hour, 2 = 1 to 23 hours,
* 3 = 1 to 6 days, 4 = 7 to 27 days, 5 = 28 days to 1 year
gen byte death_1yr = died
gen byte death_28d = died == 1 & ager5 <= 4
gen byte death_7d  = died == 1 & ager5 <= 3
gen byte death_24h = died == 1 & ager5 <= 2

* Controls as categories; 99 = unknown, its own category
gen byte mage5  = cond(missing(dmage), 99, floor(dmage/5))     // mother's age, 5 year bins
gen byte fage5  = cond(dfage == 99 | missing(dfage), 99, floor(dfage/5))
gen byte meduc4 = cond(dmeduc == 99 | missing(dmeduc), 99,     ///
                  cond(dmeduc < 12, 1, cond(dmeduc == 12, 2,   ///
                  cond(dmeduc <= 15, 3, 4))))                  // <12, 12, 13 to 15, 16+
gen byte race3  = cond(mrace == 1, 1, cond(mrace == 2, 2, 3))  // white, black, other
gen byte plural = cond(missing(dplural), 99, min(dplural, 3))  // single, twin, 3+
gen byte border = cond(dtotord == 99 | missing(dtotord), 99, min(dtotord, 5))
quietly replace gestat = 99 if missing(gestat)                 // weeks of gestation
quietly replace mpcb   = 99 if missing(mpcb)                   // month prenatal care began
quietly replace csex   = 99 if missing(csex)

keep year grams dist vlbw died death_1yr death_28d death_7d death_24h ///
     gestat csex plural race3 mage5 fage5 meduc4 mpcb border
order year grams dist vlbw died death_1yr death_28d death_7d death_24h
compress
label data "ADKW (2010) sample: births 1,350 to 1,650 g, NCHS linked files"
save "data/derived/vlbw_sample.dta", replace

count if abs(dist) <= $WINDOW
di as text "Births within 85 g of 1,500 g: " as result %9.0fc r(N) ///
   as text "   (ADKW Table I: 202,071; Barreca et al.: 202,078)"

*==============================================================
* Placebo sample
*==============================================================
use `wide', clear
rename dbirwt grams
order year grams births deaths
sort year grams
label var year   "Birth year"
label var grams  "Recorded birth weight (g)"
label var births "Births (imputed weights dropped)"
label var deaths "Deaths within one year"
compress
label data "Births and infant deaths by recorded gram, 915 to 3,085 g"
save "data/derived/births_by_gram.dta", replace

quietly summarize births
di as text "Placebo sample: " as result %12.0fc r(sum) as text " births (expected 18,565,596)"

di _n as result "01_build.do complete."
