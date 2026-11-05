# Raw data

You only need these files to rebuild `data/derived` from scratch (`global REBUILD 1` in `master.do`). The normal run uses the samples already in `data/derived`.

**Source.** NBER, Linked Birth/Infant Death Cohort Data: https://www.nber.org/research/data/linked-birthinfant-death-cohort-data

**What to download.** The Stata version of two files for each of 17 years, 34 files in all:

| Years | Births file (denominator) | Deaths file (numerator) |
|---|---|---|
| 1983 to 1991 | `linkcoYYYYus_den.dta` | `linkcoYYYYus_num.dta` |
| 1995 to 2002 | `linkcoYYYYus_den.dta` | `linkcoYYYYus_num.dta` |

NCHS made no linked cohort files for 1992 to 1994, so those years are missing in ADKW too.

**Steps.**

1. On the NBER page, open each year and download the Stata (.dta) births and deaths files.
2. The births files arrive zipped (`linkcoYYYYus_den_dta.zip`). Unzip each one so the `.dta` sits directly in this folder.
3. Keep the NBER file names exactly, for example `linkco1995us_den.dta` and `linkco1995us_num.dta`.
4. If a year is offered only as CSV, open it in Stata with `import delimited`, then `save` it here under the same name with a `.dta` ending.

The unzipped births files are large (about 250 MB a year before 1995 and about 700 MB a year after), so they are kept out of the repository by `.gitignore`. `01_build.do` reads only the variables it needs and stops with a message naming any missing file.
