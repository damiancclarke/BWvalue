/* dceAnalysis.do v0.00          damiancclarke             yyyy-mm-dd:2016-12-15
----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8

The script below is split into two parts.  The first is for the birthweight grou
p and the second is for the day of birth group.  The two parts are denoted using
B (birthweight) and D (day of birth)
*/

vers 11
clear all
set more off
cap log close

*-------------------------------------------------------------------------------
*--- (0) Globals
*-------------------------------------------------------------------------------
global DAT "~/investigacion/2017/BWvalue/data/survey"
global LOG "~/investigacion/2017/BWvalue/log"
global OUT "~/investigacion/2017/BWvalue/results/DCE"
global GEO "~/investigacion/2017/BWvalue/data/geography"


log using "$LOG/dceAnalysis.txt", text replace

*-------------------------------------------------------------------------------
*--- (1) Open data
*-------------------------------------------------------------------------------
use "$DAT/conjointBWgroup"
bys ID: gen N=_n
keep if N==1
drop N

keep if _mergeMTQT==3
keep if RespEduc==RespEducCheck
keep if notUSA==0
keep if surveyTime>=2

gen parent     = RespNumKids !="0" 
gen planning   = RespPlansKids=="Yes"
gen childBYear = RespKidBYear if parent==1
destring childBYear, replace
gen age        = 2016-RespYOB
*replace age    = childBYear-RespYOB if parent==1
gen age2       = age^2
gen white      = RespRace=="White"
gen married    = RespMarital=="Married"
gen teacher    = RespOccupation=="Education, Training, Library"
gen certainty     = "1"  if RespSure=="1 (not sure at all)"
replace certainty = "10" if RespSure=="10 (definitely sure)"
replace certainty = RespSure if certainty==""
destring certainty, replace
save "$DAT/combined", replace

*-------------------------------------------------------------------------------
*--- (1a) Summary Statistics
*-------------------------------------------------------------------------------
gen sex = RespSex=="Female"
gen birthyr = RespYOB
gen educY     = 8 if RespEduc=="Eighth Grade or Less"
replace educY = 10 if RespEduc=="Some High School"
replace educY = 12 if RespEduc=="High School Degree/GED"
replace educY = 13 if RespEduc=="Some College"
replace educY = 14 if RespEduc=="2-year College Degree"
replace educY = 16 if RespEduc=="4-year College Degree"
replace educY = 17 if RespEduc=="Master's Degree"
replace educY = 17 if RespEduc=="Doctoral Degree"
replace educY = 17 if RespEduc=="Professional Degree (JD,MD,MBA)"
gen pregnant1 = RespPregnant=="Yes"
gen black     = RespRace=="Black or African American"
gen otherRace = white==0&black==0
gen hispanic  = RespHisp=="Yes"
gen employed  = RespEmploymen=="Employed"
gen unemployed= RespEmploymen=="Unemployed"
gen highEduc  = educY>=13
gen nchild    = RespNumKids if RespNumKids!="6 or more"
destring nchild, replace
replace nchild=6 if nchild==.
generat ftotinc = 5000   if RespSalary=="Less than $10,000"
replace ftotinc = 15000  if RespSalary=="$10,000 - $19,999"
replace ftotinc = 25000  if RespSalary=="$20,000 - $29,999"
replace ftotinc = 35000  if RespSalary=="$30,000 - $39,999"
replace ftotinc = 45000  if RespSalary=="$40,000 - $49,999"
replace ftotinc = 55000  if RespSalary=="$50,000 - $59,999"
replace ftotinc = 65000  if RespSalary=="$60,000 - $69,999"
replace ftotinc = 75000  if RespSalary=="$70,000 - $79,999"
replace ftotinc = 85000  if RespSalary=="$80,000 - $89,999"
replace ftotinc = 95000  if RespSalary=="$90,000 - $99,999"
replace ftotinc = 125000 if RespSalary=="$100,000 - $149,999"
replace ftotinc = 175000 if RespSalary=="$150,000 or more"
replace ftotinc = ftotinc/1000
gen mturkSal = 1.5 if RespMTurkSalary=="Less than $2"
replace mturkSal = 2.5 if RespMTurkSalary=="$2-$2.99"
replace mturkSal = 3.5 if RespMTurkSalary=="$3-$3.99"
replace mturkSal = 4.5 if RespMTurkSalary=="$4-$4.99"
replace mturkSal = 5.5 if RespMTurkSalary=="$5-$5.99"
replace mturkSal = 6.5 if RespMTurkSalary=="$6-$6.99"
replace mturkSal = 7.5 if RespMTurkSalary=="$7-$7.99"
replace mturkSal = 8.5 if RespMTurkSalary=="$8-$8.99"
replace mturkSal = 9.5 if RespMTurkSalary=="$9-$9.99"
replace mturkSal = 10.5 if RespMTurkSalary=="$10-$10.99"
replace mturkSal = 11.5 if RespMTurkSalary=="$11 or more"

lab var sex       "Female"
lab var birthyr   "Year of Birth"
lab var age       "Age"
lab var educY     "Years of Education"
lab var nchild    "Number of Children"
lab var pregnant1 "Currently Pregnant"
lab var married   "Married"
lab var hispanic  "Hispanic"
lab var black     "Black"
lab var white     "White"
lab var otherRac  "Other Race"
lab var employed  "Employed"
lab var unemploy  "Unemployed"
lab var highEduc  "Some College +"
lab var parent    "Parent"
lab var ftotinc   "Total Family Income (1000s)"
lab var mturkSal  "Hourly earnings on MTurk"


#delimit ;
estpost sum sex age hispanic black white hispanic married highEduc educY
employed ftotinc parent nchild mturkSal;
estout using "$OUT/Summary/MTurkSum.tex", replace label style(tex)
cells("count(label(N)) mean(fmt(2) label(Mean)) sd(fmt(2) label(Std.\ Dev.))
min(fmt(2) label(Min)) max(fmt(2) label(Max))");
#delimit cr


*-------------------------------------------------------------------------------
*--- (1b) Geographical coverage
*-------------------------------------------------------------------------------
gen statename=RespState
count
bys statename: gen stateProportion = _N/r(N)

preserve
collapse stateProportion, by(statename)
rename statename NAME

merge 1:1 NAME using "$GEO/US_db"
format stateProportion %5.2f
#delimit ;
spmap stateProportion if NAME!="Alaska"&NAME!="Hawaii"&NAME!="Puerto Rico"
using "$GEO/US_coord_mercator",
point(data($DAT/combined) xcoord(long3) ycoord(lat3)
      select(drop if (latitude<24.39|latitude>49.38)|(longitude<-124.84|longitude>-66.9))
      size(*0.5) fcolor(red))
id(_ID) osize(thin) legtitle("Proportion of Respondents") legstyle(2) fcolor(Greens)
legend(symy(*1.2) symx(*1.2) size(*1.4) rowgap(1));
graph export "$OUT/Summary/surveyCoverage.eps", as(eps) replace;
#delimit cr
restore

*-------------------------------------------------------------------------------
*--- (2) Conjoint Analysis 
*-------------------------------------------------------------------------------
use "$DAT/conjointBWgroup", clear
gen mainSample = 1
replace mainSample = 0 if RespEduc!=RespEducCheck|notUSA==1|surveyTime<2

gen parent     = RespNumKids !="0" 
gen planning   = RespPlansKids=="Yes"
gen white      = RespRace=="White"
gen married    = RespMarital=="Married"
gen teacher    = RespOccupation=="Education, Training, Library"
gen childBYear = RespKidBYear if parent==1
destring childBYear, replace
gen age        = 2016-RespYOB
replace age    = childBYear-RespYOB if parent==1
gen age2       = age^2
gen someCollege = RespEduc!="Eighth Grade or Less"&/*
*/ RespEduc!="High School Degree/GED"&RespEduc!="Some High School"
gen hispanic = RespHisp=="Yes"
gen certainty     = "1"  if RespSure=="1 (not sure at all)"
replace certainty = "10" if RespSure=="10 (definitely sure)"
replace certainty = RespSure if certainty==""
destring certainty, replace

tab gender     , gen(_gend)
tab cost       , gen(_cost)
tab birthweight, gen(_bwt)
tab sob        , gen(_sob)


drop _gend1 _cost5 _bwt2 _sob4
rename _cost1 _costx
rename _cost4 _cost1
rename _cost3 _cost4
rename _costx _cost3
rename _cost2 _cost11
rename _cost10 _cost2
rename _cost11 _cost10
rename _bwt1 _bwt2
rename _bwt4 _bwtx
rename _bwt5 _bwt4
rename _bwt3 _bwt5
rename _bwtx _bwt3
rename _bwt6 _bwtx
rename _bwt7 _bwt6
rename _bwt8 _bwt7
rename _bwtx _bwt8
rename _bwt9 _bwtx
rename _bwt10 _bwt9
rename _bwt11 _bwt10
rename _bwtx _bwt11
rename _sob1 _sob4
gen goodSeason=_sob2==1|_sob3==1
gen     costNumerical = subinstr(cost,"$","",1)
replace costNumerical = subinstr(costNumerical,",","",1)
destring costNumerical, replace
replace costNumerical = costNumerical/1000
gen spring = _sob2
gen summer = _sob3
gen all = 1
gen TPG = teacher*parent*goodSeason
gen TP = teacher*parent
gen TG = teacher*goodSeason
gen PG = parent*goodSeason
lab var age "Age"
lab var age2 "Age Squared"
lab var someCollege "Some College +"
lab var hispanic "Hispanic"
lab var teacher "Teacher"
lab var parent  "Parent"
lab var TPG "Teacher $\times$ Parent $\times$ Good Season"
lab var TP "Teacher $\times$ Parent"
lab var TG "Teacher $\times$ Good Season"
lab var PG "Parent $\times$ Good Season"
lab var _bwt2  "5lbs, 13oz"
lab var _bwt3  "6lbs, 3oz"
lab var _bwt4  "6lbs, 8oz"
lab var _bwt5  "6lbs, 13oz"
lab var _bwt6  "7lbs, 3oz"
lab var _bwt7  "7lbs, 8oz"
lab var _bwt8  "7lbs, 13oz"
lab var _bwt9  "8lbs, 3oz"
lab var _bwt10 "8lbs, 8oz"
lab var _bwt11 "8lbs, 13oz"
lab var _gend2 "Girl"
lab var _bwt2  "5lbs, 13oz"
lab var _bwt3  "6lbs, 3oz"
lab var _bwt4  "6lbs, 8oz"
lab var _bwt5  "6lbs, 13oz"
lab var _bwt6  "7lbs, 3oz"
lab var _bwt7  "7lbs, 8oz"
lab var _bwt8  "7lbs, 13oz"
lab var _bwt9  "8lbs, 3oz"
lab var _bwt10 "8lbs, 8oz"
lab var _bwt11 "8lbs, 13oz"
sort _bwt2 _bwt3 _bwt4 _bwt5 _bwt6 _bwt7 _bwt8 _bwt9 _bwt10 _bwt11
*-------------------------------------------------------------------------------
*--- (3) Estimate
*-------------------------------------------------------------------------------
local oFEs i.round i.option
local qFEs i.cost_position i.birthweight_position i.gender_p i.sob_p 
local eFEs i.n1 i.n2 i.n3 i.n4
local base age>=25&age<=45&married==1&white==1

bys ID: gen N=_n

#delimit ;
local conds all==1 mainSample==1;
local names All Sample;
tokenize `names';
lab def names -1 "Birth Weight" -2 "5lbs, 8oz" -3 "5lbs, 13oz" -4 "6lbs, 3oz"
              -5 "6lbs, 8oz" -6 "6lbs, 13oz" -7 "7lbs, 3oz" -8 "7lbs, 8oz"
              -9 "7lbs, 13oz" -10 "8lbs, 3oz" -11 "8lbs, 8oz" -12 "8lbs, 13oz"
              -13 " " -14 "Season of Birth" -15 "Winter" -16 "Spring"
              -17 "Summer" -18 "Fall" -19 " " -20 "Cost" -21 "250" -22 "750" 
              -23 "1000" -24 "2000" -25 "3000" -26 "4000" -27 "5000" -28 "6000"
              -29 "7500" -30 "10000" -31 " " -32 "Gender" -33 "Boy" -34 "Girl"
              -35 " ";
lab def namesT -1 "Birth Weight" -2 "5lbs, 8oz" -3 "5lbs, 13oz"
               -4 "6lbs, 3oz" -5 "6lbs, 8oz" -6 "6lbs, 13oz" -7 "7lbs, 3oz"
               -8 "7lbs, 8oz" -9 "7lbs, 13oz" -10 "8lbs, 3oz" 
               -11 "8lbs, 8oz" -12 "8lbs, 13oz"  -13 " " 
               -14 "Season of Birth" -15 "Winter" -16 "Spring" -17 "Summer"
               -18 "Fall" -19 " " -20 "Cost" -21 "1000s of USD" -22 " " 
               -23 "Gender" -24 "Boy" -25 "Girl" -26 " ";
#delimit cr

local tvL = 1.96
local ll=1
foreach c of local conds {
    reg chosen `oFEs' _sob* _cost* _gend* _bwt* if `c', cluster(ID)
    local Nobs = e(N)

    gen Est = .
    gen UB  = .
    gen LB  = .
    gen Y   = .
    local i = 1
    local vars BIRTH-WEIGHT _bwt1 _bwt2 _bwt3 _bwt4 _bwt5 _bwt6 _bwt7 _bwt8  /*
    */ _bwt9 _bwt10 _bwt11 s SEASON-OF_BIRTH _sob1 _sob2 _sob3 _sob4 s COST  /*
    */_cost1 _cost2 _cost3 _cost4 _cost5 _cost6 _cost7 _cost8 _cost9 _cost10 /*
    */ s GENDER _gend1 _gend2 s 

    foreach var of local vars {
        qui replace Y = `i' in `i'
        if `i'==1|`i'==14|`i'==20|`i'==32 {
            dis "`var'"
        }
        else if `i'==13|`i'==19|`i'==31|`i'==35 {
        }
        else if `i'==2|`i'==15|`i'==25|`i'==33 {
            qui replace Est = 0 in `i'
            qui replace UB  = 0 in `i'
            qui replace LB  = 0 in `i'
        }
        else {
            qui replace Est = _b[`var'] in `i'
            qui replace UB  = _b[`var']+1.96*_se[`var'] in `i'
            qui replace LB  = _b[`var']-1.96*_se[`var'] in `i'
        }
        local ++i
    }

    replace Y = -Y
    lab val Y names

    *---------------------------------------------------------------------------
    *--- (4) Graph
    *---------------------------------------------------------------------------
    #delimit ;
    twoway rcap  LB UB Y in 1/35, horizontal scheme(s1mono) lcolor(black) ||
    scatter Y Est in 1/35, mcolor(black) msymbol(oh) mlwidth(thin)
    xline(0, lpattern(dash) lcolor(gs7)) ylabel(-1 -14 -20 -32, valuelabel angle(0))
    ymlabel(-2(-1)-12 -15(-1)-18 -21(-1)-30 -33(-1)-34, valuelabel angle(0))
    ytitle("") xtitle("Effect Size (Probability)") legend(off) ysize(8)
    note(Total respondents = `=`Nobs'/14'.  Total profiles = `Nobs'.);
    *legend(lab(1 "95% CI") lab(2 "Point Estimate"));
    #delimit cr
    graph export "$OUT/Figures/Conjoint_`1'.eps", replace
    drop Est UB LB Y

    *-----------------------------------------------------------------------
    *--- (5) Continuous cost graph
    *-----------------------------------------------------------------------
    reg chosen `oFEs' _sob* costNumerical _gend* _bwt* if `c', cluster(ID)
    local Nobs = e(N)
    gen Est = .
    gen UB  = .
    gen LB  = .
    gen Y   = .
    local i = 1
    local vars BIRTH-WEIGHT _bwt1 _bwt2 _bwt3 _bwt4 _bwt5 _bwt6 _bwt7 _bwt8 /*
    */_bwt9 _bwt10 _bwt11 s SEASON-OF_BIRTH _sob1 _sob2 _sob3 _sob4 s COST  /*
    */ costNumerical s GENDER _gend1 _gend2 s 

    foreach var of local vars {
        qui replace Y = `i' in `i'
        if `i'==1|`i'==14|`i'==20|`i'==23 {
            dis "`var'"
        }
        else if `i'==13|`i'==19|`i'==22|`i'==26 {
        }
        else if `i'==2|`i'==15|`i'==24 {
            qui replace Est = 0 in `i'
            qui replace UB  = 0 in `i'
            qui replace LB  = 0 in `i'
        }
        else {
            qui replace Est = _b[`var'] in `i'
            qui replace UB  = _b[`var']+1.96*_se[`var'] in `i'
            qui replace LB  = _b[`var']-1.96*_se[`var'] in `i'
        }
        local ++i
    }

    replace Y = -Y
    lab val Y namesT

    #delimit ;
    twoway rcap  LB UB Y in 1/26, horizontal scheme(s1mono) lcolor(black) ||
    scatter Y Est in 1/26, mcolor(black) msymbol(oh) mlwidth(thin)
    xline(0, lpattern(dash) lcolor(gs7))
    ylabel(-1 -14 -20 -23, valuelabel angle(0))
    ymlabel(-2(-1)-12 -15(-1)-18 -21 -24 -25, valuelabel angle(0))
    ytitle("") xtitle("Effect Size (Probability)") legend(off) ysize(7)
    note(Total respondents = `=`Nobs'/14'.  Total profiles = `Nobs'.);
    *legend(lab(1 "95% CI") lab(2 "Point Estimate"));
    #delimit cr
    graph export "$OUT/Figures/Conjoint_`1'_continuous.eps", replace
    drop Est UB LB Y

    macro shift
    local ++ll
}

*-------------------------------------------------------------------------------
*--- (5) Regressions and willingness to pay
*-------------------------------------------------------------------------------
gen bwtGrams = 2500 if birthweight=="5 pounds 8 ounces"
replace bwtGrams = 2637 if birthweight=="5 pounds 13 ounces"
replace bwtGrams = 2807 if birthweight=="6 pounds 3 ounces"
replace bwtGrams = 2948 if birthweight=="6 pounds 8 ounces"
replace bwtGrams = 3090 if birthweight=="6 pounds 13 ounces"
replace bwtGrams = 3260 if birthweight=="7 pounds 3 ounces"
replace bwtGrams = 3402 if birthweight=="7 pounds 8 ounces"
replace bwtGrams = 3544 if birthweight=="7 pounds 13 ounces"
replace bwtGrams = 3714 if birthweight=="8 pounds 3 ounces"
replace bwtGrams = 3856 if birthweight=="8 pounds 8 ounces"
replace bwtGrams = 4000 if birthweight=="8 pounds 13 ounces"
replace bwtGrams = bwtGrams/1000

local ctrl `oFEs' _gend* _sob*
local bwts _bwt2 _bwt3 _bwt4 _bwt5 _bwt6 _bwt7 _bwt8 _bwt9 _bwt10 _bwt11
eststo: logit chosen bwtGrams costNumerical `ctrl' if mainSample==1, cluster(ID)
margins, dydx(bwtGrams costNumerical _sob2 _sob3 _sob4 _gend2) post
est store m1

estadd scalar wtp = -1000*(_b[bwtGrams]/_b[costNumerical])
nlcom ratio:_b[bwtGrams]/_b[costNumerical], post
local lb = string(-1000*(_b[ratio]-1.96*_se[ratio]), "%5.1f")
local ub = string(-1000*(_b[ratio]+1.96*_se[ratio]), "%5.1f")
estadd local conf95 "[`ub';`lb']": m1

eststo: logit chosen `bwts' costNumerical `ctrl' if mainSample==1, cluster(ID)
margins, dydx(costNumerical `bwts' _gend2 _sob2 _sob3 _sob4) post
est store m2
*estadd scalar wtpSp = -1000*_b[spring]/_b[costNumerical]
*nlcom ratio:_b[spring]/_b[costNumerical], post
*local lb = string(-1000*(_b[ratio]-`tvL'*_se[ratio]), "%5.1f")
*local ub = string(-1000*(_b[ratio]+`tvL'*_se[ratio]), "%5.1f")
*estadd local conf95sp "[`ub';`lb']": m2
*est restore m2


lab var _sob4 "Fall"
lab var _sob2 "Spring"
lab var _sob3 "Summer"
lab var costNumerical "Cost (in 1000s of dollars)"
lab var bwtGrams      "Birthweight (in 1000s of grams)"

#delimit ;
esttab m1 m2 using "$OUT/Regressions/conjointWTP.tex", replace
cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats
(wtp conf95 N, fmt(%5.1f %5.1f %9.0g) label("WTP for Birthweight (1000 grams)" "95\% CI"
                                            Observations))
starlevels(* 0.05 ** 0.01 *** 0.001) collabels(,none)
mlabels("Continuous" "Categorical") booktabs label
title("Birth Characteristics and Willingness to Pay for Birthweight"\label{WTPreg}) 
keep(bwtGrams costNumerical _gend2 _sob2 _sob3 _sob4 `bwts') style(tex) 
postfoot("\bottomrule           "
         "\multicolumn{3}{p{11.2cm}}{\begin{footnotesize} Average marginal   "
         "effects from a logit regression are displayed. All columns include "
         "option order fixed effects and round fixed effects. Standard       "
         "errors are clustered by respondent. Willingness to pay and its     "
         "95\% confidence interval is estimated based on the ratio of costs  "
         "to the probability of choosing a particular birthweight. The 95\%  "
         "confidence interval is calculated using the delta method for the   "
         "ratio, with confidence levels based on Leamer values. "
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr




