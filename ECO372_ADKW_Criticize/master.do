*==============================================================
* ECO372H5F  Week 8  Criticizing side
* Almond, Doyle, Kowalski & Williams (2010, QJE)
* "Estimating Marginal Returns to Medical Care:
*  Evidence from At-Risk Newborns"
* Reply paper: Barreca, Guldi, Lindo & Waddell (2011, QJE)
*
* master.do : runs the whole project, start to finish
*
* How to run
*   1. Set Stata's working directory to this folder
*      (File > Change Working Directory, or double click master.do).
*   2. Type:  do master.do
*
* The built samples are included in data/derived, so no download
* is needed. To rebuild them from the 34 raw NBER files instead,
* put the files in data/raw (see data/raw/README.md) and set
* REBUILD to 1 below.
*
* Requires Stata 15 or newer. No user written packages.
* Runtime: about 5 minutes (longer with REBUILD = 1).
*==============================================================
clear all
set more off
version 15
set varabbrev off

global REBUILD 0      // 1 = rebuild data/derived from the raw NBER files

*--------------------------------------------------------------
* Check we are in the project folder
*--------------------------------------------------------------
capture confirm file "master.do"
if _rc {
    di as error "Set Stata's working directory to the project folder"
    di as error "(the folder that holds master.do), then run it again."
    exit 601
}

foreach d in output output/tables output/figures output/logs data/derived {
    capture mkdir "`d'"
}

capture log close master
log using "output/logs/master_log.txt", text replace name(master)

di as result "ECO372 Week 8, criticizing side: run started $S_DATE $S_TIME"
di as text "Stata version: " c(stata_version)

*--------------------------------------------------------------
* Settings, helper programs
*--------------------------------------------------------------
do "code/00_programs.do"

*--------------------------------------------------------------
* 1. Data: build from raw files only if asked or if missing
*--------------------------------------------------------------
capture confirm file "data/derived/vlbw_sample.dta"
local have1 = (_rc == 0)
capture confirm file "data/derived/births_by_gram.dta"
local have2 = (_rc == 0)

if $REBUILD == 1 | `have1' == 0 | `have2' == 0 {
    do "code/01_build.do"
}
else {
    di as text _n "Using the included samples in data/derived (REBUILD = 0)."
}

*--------------------------------------------------------------
* 2. Analysis
*--------------------------------------------------------------
do "code/02_prepare.do"        // analysis variables
do "code/03_table1.do"         // reproduce ADKW Table I
do "code/04_heaping.do"        // the heap at exactly 1,500 g
do "code/05_donut.do"          // donut RD and cost per life
do "code/06_bandwidth.do"      // bandwidth sensitivity (ADKW Table A3)
do "code/07_placebo.do"        // placebo cutoffs, 1,000 to 3,000 g
do "code/08_defence_checks.do" // how the result responds to the defence's fixes

di as result _n "Run finished $S_DATE $S_TIME"
di as text "Tables:  output/tables   Figures:  output/figures   Log:  output/logs/master_log.txt"
log close master
