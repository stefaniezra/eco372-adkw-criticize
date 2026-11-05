# ECO372 Week 8: The Case Against ADKW (2010)

Group: Vania Widyadharma, Alisa Mirzaei, Stefanie E. Samosir

This repository reproduces the main mortality results of Almond, Doyle, Kowalski and Williams (2010, QJE), "Estimating Marginal Returns to Medical Care: Evidence from At-Risk Newborns", from the raw public birth and death records, and runs the tests behind our criticizing case. Everything runs in Stata from one file, `master.do`.

**Our case in one paragraph.** ADKW compare babies just below and just above 1,500 g, the line for "very low birth weight" (VLBW). That only works if babies on both sides are alike. They are not: many weights were rounded, 3,544 babies are recorded at exactly 1,500 g, and they die almost twice as often as their neighbours. VLBW means strictly below 1,500 g, so all of them count as untreated. Remove just those 2% of births and the estimated drop in deaths halves; remove births within 3 g of the line and three quarters of it is gone. The estimate also triples as the window narrows onto the heaps, and the same "effect" appears at 20 of the 21 round 100 g lines from 1,000 to 3,000 g, most of which change nothing about care. So the $550,000 cost per life is not reliable.

## Quick start

1. Download or clone this folder.
2. Open Stata 15 or newer. Set the working directory to this folder (File > Change Working Directory), or double click `master.do`.
3. Type `do master.do`.

That is all. The built samples are included in `data/derived`, so no download is needed, and no user written packages are used. The run takes about 5 minutes and writes every table to `output/tables`, every figure to `output/figures` and a full log to `output/logs/master_log.txt`.

To rebuild the samples from the 34 raw NBER files instead, put them in `data/raw` (see `data/raw/README.md`) and set `global REBUILD 1` at the top of `master.do`. The rebuild takes longer, mostly to read the large births files.

## Folder layout

```
ECO372_ADKW_Criticize/
    master.do                 runs everything in order
    README.md
    code/
        00_programs.do        settings and helper programs
        01_build.do           raw NCHS files to data/derived (only if REBUILD = 1)
        02_prepare.do         analysis variables
        03_table1.do          reproduce ADKW Table I
        04_heaping.do         the heap at exactly 1,500 g
        05_donut.do           donut test (Barreca et al. Table I) and cost per life
        06_bandwidth.do       bandwidth sensitivity (ADKW Online Appendix Table A3)
        07_placebo.do         placebo cutoffs from 1,000 to 3,000 g
        08_defence_checks.do  how the estimate responds to the defence's fixes
    data/
        raw/                  the 34 NBER files go here (not in the repository)
        derived/
            vlbw_sample.dta     births 1,350 to 1,650 g, one row per birth (376,408 rows)
            births_by_gram.dta  births and deaths by year and gram, 915 to 3,085 g
    output/
        tables/               .csv and .md for every table
        figures/              .png for every figure
        logs/                 master_log.txt
```

## Data

**Source.** National Center for Health Statistics (NCHS), Linked Birth/Infant Death cohort files, 1983 to 1991 and 1995 to 2002, Stata versions posted by NBER: https://www.nber.org/research/data/linked-birthinfant-death-cohort-data. NCHS made no linked files for 1992 to 1994. These are the same files ADKW use for mortality.

**How the raw files fit together.** Each year has a births file (`linkcoYYYYus_den`) and a deaths file (`linkcoYYYYus_num`). The births file flags babies who died in their first year (`matchs`), but only the deaths file says when they died (`ager5`). Before 1989 there is no ID to merge on, so `01_build.do` stacks the two: survivors from the births file, deaths from the deaths file. The `matchs` codes change over time (1983: 1 or 2 means died; 1995: 1 means died), so the build reads the codes that mean "died" from each year's deaths file.

**Sample rules, following ADKW Section III.B.** Drop imputed birth weights (`bwif == 1`, recorded from 1995). Drop deaths with no age at death (footnote 20). Keep births within 85 g (3 ounces) of 1,500 g for the main analysis.

**What is included.** `vlbw_sample.dta` keeps births from 1,350 to 1,650 g so the bandwidth tests can widen the window to 150 g. `births_by_gram.dta` holds counts only, for the placebo cutoffs. Both are built by `01_build.do` from the raw files and are small enough for GitHub (8 MB and 0.4 MB).

**What cannot be reproduced.** ADKW's hospital cost results (their Tables II and III, and the $3,795 cost jump) use HCUP State Inpatient Databases and California discharge records, which are licensed and not public. Our cost per life calculations therefore take the $3,795 from the paper.

## What each file produces

| File | Output | What it shows |
|---|---|---|
| `03_table1.do` | `table1_adkw` | ADKW Table I rebuilt: 4 outcomes, 4 specifications, both kinds of standard error, next to the published values |
| `04_heaping.do` | `table2_heap_facts`, `table3_round_heaps`, `fig1_heaping`, `fig2_deaths_by_gram`, `fig3_rd_plot` | Births pile up at round numbers; babies at exactly 1,500 g die far more often; ADKW Figure II rebuilt |
| `05_donut.do` | `table4_donut`, `table5_cost_per_life`, `fig4_donut` | Removing births at the cutoff shrinks the effect; what that does to the cost per life |
| `06_bandwidth.do` | `table6_bandwidth`, `fig5_bandwidth` | The estimate triples as the window narrows from 150 g to 30 g |
| `07_placebo.do` | `table7_placebo`, `table7b_placebo_summary`, `fig6_placebo` | Lower mortality just below 20 of 21 round 100 g lines, most of which change no care |
| `08_defence_checks.do` | `table8_defence_checks` | The defence's best fixes for rounding, tested |

## Expected results

These are the values the run should print. They come from the same data and were checked against both published papers. Standard errors can differ from the published ones in the last digit.

**Sample.** 202,078 births within 85 g (ADKW report 202,071; Barreca et al. 202,078). 3,544 births at exactly 1,500 g. 5.54 deaths per 100 just above the line (ADKW: 5.53).

**Table 1, ADKW Table I** (coefficient on "below 1,500 g"; published value in brackets)

| Outcome | Local linear | OLS, no controls | OLS, year controls | OLS, all controls |
|---|---|---|---|---|
| One year | −0.0121 [−0.0121] | −0.0095 [−0.0095] | −0.0076 [−0.0067 *] | −0.0072 [−0.0072] |
| 28 days | −0.0106 [−0.0107] | −0.0088 [−0.0088] | −0.0073 [−0.0074] | −0.0071 [−0.0073] |
| 7 days | −0.0067 [−0.0068] | −0.0060 [−0.0060] | −0.0048 [−0.0049] | −0.0045 [−0.0047] |
| 24 hours | −0.0050 [−0.0068 †] | −0.0042 [−0.0043] | −0.0035 [0.0036 †] | −0.0033 [−0.0035] |

\* Table I prints −0.0067; the paper's text (p. 610) says −0.0076, which is what we get. † The published 24 hour local linear entry repeats the 7 day one, and the year controls entry has lost its minus sign. One year, all controls: robust SE 0.0022 (published 0.0022), by gram SE 0.0039 (published 0.0040).

**Table 2, the heap**

| Recorded weight | Births | Died within a year | White mother | Mother without high school |
|---|---|---|---|---|
| 1,490 to 1,499 g | 3,439 | 5.2% | 65.7% | 28.8% |
| Exactly 1,500 g | 3,544 | 10.1% | 62.3% | 31.1% |
| 1,501 to 1,510 g | 26,251 | 6.0% | 66.5% | 27.6% |

**Table 3, round number heaps.** Extra deaths per 100 against births within 10 g: 1,400 g +2.3, 1,500 g +4.2, 1,600 g +3.1.

**Table 4, donut test** (one year, all controls; Barreca et al. Table I in brackets)

| Births removed | Coefficient | By gram SE | Births | Share of full estimate |
|---|---|---|---|---|
| Nothing | −0.0072 [−0.0071] | 0.0039 [0.0041] | 202,078 | 100% |
| Exactly 1,500 g | −0.0036 [−0.0033] | 0.0014 [0.0014] | 198,534 | 50% |
| 1,499 to 1,501 g | −0.0038 [−0.0035] | 0.0013 [0.0014] | 198,334 | 52% |
| 1,498 to 1,502 g | −0.0032 [−0.0027] | 0.0014 [0.0014] | 197,135 | 45% |
| 1,497 to 1,503 g | −0.0018 [−0.0018] | 0.0018 [0.0019] | 175,108 | 26% |

**Table 5, cost per life saved** (holding ADKW's $3,795 fixed): $528,740 for the full sample, $1.05 million without the 1,500 g heap, $2.06 million with the 3 g hole. Using the by gram standard error, the 95% range has no upper limit for the full sample and for the 3 g hole, because both ranges include zero.

**Table 6, bandwidth** (fewer deaths per 100, one year; ADKW Table A3 in brackets): 30 g 2.63 [2.67], 60 g 1.61 [1.62], 85 g 1.21 [1.21], 90 g 1.14 [1.14], 120 g 0.91 [0.91], 150 g 0.86 [0.87]. The 30 g estimate is 3.1 times the 150 g estimate.

**Table 7, placebo cutoffs.** Mortality is lower just below 26 of 41 cutoffs; 20 of the 21 round 100 g cutoffs (all but 1,400 g), against 6 of the 20 cutoffs that fall halfway between. At 1,500 g the estimate is 0.95 per 100, the same as ADKW Table I column 2.

**Table 8, defence checks** (one year, all controls, fewer deaths per 100): without the 1,503 g heap only 1.08; without both heaps 0.28; all births with rounding indicators 0.37; exact weights only (32,170 births) 0.72, which could be chance by either standard error.

## Choices worth knowing

* **Regression.** ADKW equation 1: death on an indicator for below 1,500 g and a linear trend in grams on each side of the cutoff, within 85 g. The local linear version uses triangle kernel weights. Births at exactly 85 g get a weight of zero in the local linear regression, so Stata may report a slightly smaller N there; the coefficient is unaffected.
* **Controls.** Year, month prenatal care began, mother's age (5 year bins), mother's education (4 groups), father's age (5 year bins), sex, weeks of gestation, mother's race (white, black, other), plurality and birth order. Each enters as categories, and an unknown value is its own category, which does the job of the paper's missing value indicators.
* **Standard errors.** Every table reports the robust standard error (ADKW's round brackets) and the standard error clustered by recorded gram (ADKW's square brackets, and the only kind Barreca et al. report). Kolesár and Rothe (2018) question clustering by a discrete running variable, so we show both and our key results do not rely on either: the donut and bandwidth results are about the size of the estimate itself.
* **Placebo cutoffs.** Estimated on births and deaths by gram, weighted by births, with no controls. This gives exactly the coefficient of the individual level regression with no controls. Barreca et al. (2011, footnote 3) report lower mortality below 37 of 41 cutoffs with their own specification; our simpler version finds 26 of 41, concentrated at round 100 g lines, which is where the heaps are.

## Use of AI tools

[Edit before submitting.] We used Claude (Anthropic) to help write and check the Stata code and to organise the analysis. We ran the code ourselves, compared every result with the published tables, and are responsible for everything in this repository.

## References

* Almond, D., J. Doyle, A. Kowalski and H. Williams (2010). Estimating Marginal Returns to Medical Care: Evidence from At-Risk Newborns. *Quarterly Journal of Economics* 125(2): 591 to 634.
* Almond, D., J. Doyle, A. Kowalski and H. Williams (2011). The Role of Hospital Heterogeneity in Measuring Marginal Returns to Medical Care: A Reply to Barreca, Guldi, Lindo, and Waddell. *Quarterly Journal of Economics* 126(4): 2125 to 2131.
* Barreca, A., M. Guldi, J. Lindo and G. Waddell (2011). Saving Babies? Revisiting the Effect of Very Low Birth Weight Classification. *Quarterly Journal of Economics* 126(4): 2117 to 2123.
* Barreca, A., J. Lindo and G. Waddell (2016). Heaping-Induced Bias in Regression-Discontinuity Designs. *Economic Inquiry* 54(1): 268 to 293.
* Kolesár, M. and C. Rothe (2018). Inference in Regression Discontinuity Designs with a Discrete Running Variable. *American Economic Review* 108(8): 2277 to 2304.
* National Center for Health Statistics. Linked Birth/Infant Death cohort files, 1983 to 1991 and 1995 to 2002, via NBER.
