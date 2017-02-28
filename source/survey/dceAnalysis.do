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
/*
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

gen nonparentPlans = RespPlansKids=="Yes"|RespPregnant=="Yes" if parent!=1

sum ftotinc if parent==1
sum ftotinc if parent==0
sum ftotinc if nonparentPlans==1
sum ftotinc if nonparentPlans==0
*parent==0&RespPlansKids=="No"



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
lab var nonparentPlans "Non-Parent Planning Children"

#delimit ;
estpost sum sex age black white hispanic parent nonparentPlans nchild married
employed highEduc educY ftotinc mturkSal;
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
insheet using "$GEO/population2015.csv", delim(";") names clear
replace state=subinstr(state,".","",1)
rename state NAME
tempfile pop
save `pop'
restore

preserve
collapse stateProportion, by(statename)
rename statename NAME
merge 1:1 NAME using `pop'
replace stateProportion = 0 if stateProportion == .
replace stateProportion = stateProportion*100
replace proportion = proportion*100
format stateProportion %5.2f
format proportion %5.2f
gen diff = stateProportion - proportion
format diff %5.2f
#delimit ;
listtex NAME stateProp prop diff using "$OUT/Summary/GeographicCoverage.tex",
rstyle(tabular) replace;
#delimit cr
replace stateProportion = stateProportion/100
replace proportion = proportion/100
drop _merge

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
*/
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
gen nonparentPlans = RespPlansKids=="Yes"|RespPregnant=="Yes" if parent!=1

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

#delimit ;
local snames `" "Alabama" "Alaska" "Arizona" "Arkansas" "California"
"Colorado" "Connecticut" "Delaware" "District of Columbia" "Florida" "Georgia"
"Idaho" "Illinois" "Indiana" "Iowa" "Kansas" "Kentucky" "Louisiana" "Maine"
"Maryland" "Massachusetts" "Michigan" "Minnesota" "Mississippi" "Missouri"
"Montana" "Nebraska" "Nevada" "New Hampshire" "New Jersey" "New Mexico"
"New York" "North Carolina" "North Dakota" "Ohio" "Oklahoma" "Oregon"
"Pennsylvania" "Rhode Island" "South Carolina" "South Dakota" "Tennessee"
"Texas" "Utah" "Virginia" "Washington" "West Virginia" "Wisconsin" "Hawaii"
"Vermont" "Wyoming" "';
local sprop 151 23 212 93 1218 170 112 29 21 631 318 51 400 206 97 91 138 145
41 187 211 309 171 93 189 32 59 90 41 279 65 616 312 24 361 122 125 398 33 152
27 205 855 93 261 223 57 180 45 19 18;
#delimit cr

bys RespState: gen statePop = _N if mainSample==1
count if mainSample==1
gen surveyProportion = statePop/r(N)
gen censusProportion = .
tokenize `sprop'
local total = 0
foreach state of local snames {
    dis "State: `state', pop: `1'"
    qui replace censusProportion = `1' if RespState=="`state'"
    local total = `total'+`1'
    macro shift
}
dis `total'
replace censusProportion = censusProportion/10000
gen weight = surveyProportion/censusProportion
replace weight=1/weight


*-------------------------------------------------------------------------------
*--- (3) Estimate
*-------------------------------------------------------------------------------
local oFEs i.round i.option
local qFEs i.cost_position i.birthweight_position i.gender_p i.sob_p 
local eFEs i.n1 i.n2 i.n3 i.n4
local base age>=25&age<=45&married==1&white==1

bys ID: gen N=_n

#delimit ;
local conds all==1 mainSample==1 parent==1 parent==0 nonparentP==1 nonparentP==0;
local names All Sample parent nonparent nonparentPlan nonparentNotPlan;
tokenize `names';
lab def names -1 "Birth Weight" -2 "5lbs, 8oz" -3 "5lbs, 13oz" -4 "6lbs, 3oz"
              -5 "6lbs, 8oz" -6 "6lbs, 13oz" -7 "7lbs, 3oz" -8 "7lbs, 8oz"
              -9 "7lbs, 13oz" -10 "8lbs, 3oz" -11 "8lbs, 8oz" -12 "8lbs, 13oz"
              -13 " " -14 "Cost" -15 "250" -16 "750"  -17 "1000" -18 "2000"
              -19 "3000" -20 "4000" -21 "5000" -22 "6000" -23 "7500" -24 "10000"
              -25 " " -26 "Gender" -27 "Boy" -28 "Girl" -29 " " 
              -30 "Season of Birth" -31 "Winter" -32 "Spring" -33 "Summer"  
              -34 "Fall" -35 " ";
lab def namesT -1 "Birth Weight" -2 "5lbs, 8oz" -3 "5lbs, 13oz"
               -4 "6lbs, 3oz" -5 "6lbs, 8oz" -6 "6lbs, 13oz" -7 "7lbs, 3oz"
               -8 "7lbs, 8oz" -9 "7lbs, 13oz" -10 "8lbs, 3oz" -11 "8lbs, 8oz"
               -12 "8lbs, 13oz"  -13 " "  -14 "Cost" -15 "1000s of USD" -16 " " 
               -17 "Gender" -18 "Boy" -19 "Girl" -20 " " -21 "Season of Birth" 
               -22 "Winter" -23 "Spring" -24 "Summer" -25 "Fall" -26 " ";
#delimit cr

local tvL = 1.96
local ll=1
local jj=0
foreach c of local conds {
    local ++jj
    if `jj'==3 local title title("Parents", box bexpand size(medium))
    if `jj'==4 local title title("Non-Parents", box bexpand size(medium))
    if `jj'==5 local title title("Non-Parents Planning Kids", box bexpand size(medium))
    if `jj'==6 local title title("Non-Parents Not Planning", box bexpand size(medium))
    if `jj'>1 local c `c'&mainSample==1
    reg chosen `oFEs' _sob* _cost* _gend* _bwt* if `c', cluster(ID)
    local Nobs = e(N)

    gen Est = .
    gen UB  = .
    gen LB  = .
    gen Y   = .
    local i = 1
    local vars BIRTH-WEIGHT _bwt1 _bwt2 _bwt3 _bwt4 _bwt5 _bwt6 _bwt7 _bwt8  /*
    */ _bwt9 _bwt10 _bwt11 s COST _cost1 _cost2 _cost3 _cost4 _cost5 _cost6  /*
    */ _cost7 _cost8 _cost9 _cost10 s GENDER _gend1 _gend2 s SEASON-OF_BIRTH /*
    */ _sob1 _sob2 _sob3 _sob4 s  

    foreach var of local vars {
        qui replace Y = `i' in `i'
        if `i'==1|`i'==14|`i'==26|`i'==30 {
            dis "`var'"
        }
        else if `i'==13|`i'==25|`i'==29|`i'==35 {
        }
        else if `i'==2|`i'==19|`i'==27|`i'==31 {
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
    xline(0, lpattern(dash) lcolor(gs7)) ylabel(-1 -14 -26 -30, valuelabel angle(0))
    ymlabel(-2(-1)-12 -15(-1)-24 -27(-1)-28 -31(-1)-34, valuelabel angle(0))
    ytitle("") xtitle("Effect Size (Probability)") legend(off) ysize(8)
    note(Total respondents = `=`Nobs'/14'.  Total profiles = `Nobs'.)
    saving("$OUT/Figures/cg_`1'", replace) `title';
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
    */_bwt9 _bwt10 _bwt11 s COST costNumerical s GENDER _gend1 _gend2 s     /*
    */ SEASON-OF_BIRTH _sob1 _sob2 _sob3 _sob4 s

    foreach var of local vars {
        qui replace Y = `i' in `i'
        if `i'==1|`i'==14|`i'==17|`i'==21 {
            dis "`var'"
        }
        else if `i'==13|`i'==16|`i'==20|`i'==26 {
        }
        else if `i'==2|`i'==18|`i'==22 {
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
    ylabel(-1 -14 -17 -21, valuelabel angle(0)) xlabel(-0.1(0.1)0.3)
    ymlabel(-2(-1)-12 -15 -18 -19 -22(-1)-25, valuelabel angle(0))
    ytitle("") xtitle("Effect Size (Probability)") legend(off) ysize(7)
    note("Total respondents = `=`Nobs'/14'.  Total profiles = `Nobs'.")
    saving("$OUT/Figures/cg_`1'_cont", replace) `title';
    *legend(lab(1 "95% CI") lab(2 "Point Estimate"));
    #delimit cr
    graph export "$OUT/Figures/Conjoint_`1'_continuous.eps", replace
    drop Est UB LB Y

    macro shift
    local ++ll
}

#delimit ;
graph combine "$OUT/Figures/cg_parent_cont" "$OUT/Figures/cg_nonparent_cont"
"$OUT/Figures/cg_nonparentPlan_cont" "$OUT/Figures/cg_nonparentNotPlan_cont",
scheme(s1mono) rows(1) xcommon xsize(11);
graph export "$OUT/Figures/parentalSubsets.eps", replace;
#delimit cr
*/
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

gen wtp = bwtGrams/costNumerical
gen wtp2 = wtp^2

logit chosen wtp if mainSample==1, cluster(ID)
logit chosen wtp wtp2 if mainSample==1, cluster(ID)
logit chosen wtp `oFEs' _sob* _gend* if mainSample==1, cluster(ID)
logit chosen wtp wtp2 `oFEs' _sob* _gend* if mainSample==1, cluster(ID)
reg chosen wtp if mainSample==1, cluster(ID)
estat ovtest

/*
*-------------------------------------------------------------------------------
*--- (X) Adding heterogeneity using mixed logit
*--- argument against using log: we see bwt is negative at some points of dist
*-------------------------------------------------------------------------------
cap which mixlogit
if _rc!=0 ssc install mixlogit

gen price = costNumerical
gen group = 1000*ID+round
local bwts _bwt2 _bwt3 _bwt4 _bwt5 _bwt6 _bwt7 _bwt8 _bwt9 _bwt10 _bwt11

#delimit ;
local conds mainSample==1 mainSample==1&parent==1 mainSample==1&parent==0 
            mainSample==1&nonparentPlans==1 mainSample==1&nonparentPlans==0;
local titles all parents nonparents planners nonplanners;
tokenize `titles';
#delimit cr
local n=1



foreach c1 of local conds {
    #delimit ;
    mixlogit chosen price if `c1', id(ID) group(group) rand(bwtGrams) 
          ln(1) technique(dfp) difficult;
    nlcom (mean_price: exp([Mean]_b[bwtGrams]+0.5*[SD]_b[bwtGrams]^2))
          (med_price:  exp([Mean]_b[bwtGrams]))
          (sd_price:   exp([Mean]_b[bwtGrams]+0.5*[SD]_b[bwtGrams]^2)
                       *sqrt(exp([SD]_b[bwtGrams]^2)-1));
    mixlbeta bwtGrams if `c1', saving("$OUT/Regressions/mixparameters-``n''-L") replace;
    #delimit cr
    
    mixlogit chosen price if `c1', id(ID) group(group) rand(bwtGrams _sob* _gend*)
    local price = _b[price]
    mixlbeta bwtGrams  if `c1', saving("$OUT/Regressions/mixparameters-``n''") replace
    preserve
    use "$OUT/Regressions/mixparameters-``n''", clear
    gen wtp = -bwtGrams/`price'
    #delimit ;
    hist wtp, scheme(s1mono) xtitle("WTP per Gram of Birth Weight ($)")
    fcolor(gs10) lcolor(black) fintensity(25);
    #delimit cr
    graph export "$OUT/Figures/WTPdist-``n''.eps", replace
    restore
    estimates store g`n'
    *degree of heterogeneity
    estadd scalar pcb = 100*normal(_b[Mean:bwtGrams]/abs(_b[SD:bwtGrams]))
    *estadd scalar pcc = 100-100*normal(_b[Mean:price]/abs(_b[SD:price]))
    *wtp
    estadd scalar wtp = 1000*(_b[bwtGrams]/_b[price])
    nlcom ratio:_b[bwtGrams]/_b[price], post
    local lb = string(1000*(_b[ratio]-1.96*_se[ratio]), "%5.1f")
    local ub = string(1000*(_b[ratio]+1.96*_se[ratio]), "%5.1f")
    estadd local conf95 "[`ub';`lb']": g`n'

    gen WTPpm = 0 in 1/11
    gen WTPlm = 0 in 1/11
    gen WTPum = 0 in 1/11
    gen pcbm  = . in 1/11
    mixlogit chosen price if `c1', id(ID) group(group) rand(`bwts' _sob* _gend*) 
    estimates store h`n'
    *degree of heterogeneity
    foreach num of numlist 2(1)11 {
        replace pcbm = 100*normal(_b[Mean:_bwt`num']/abs(_b[SD:_bwt`num'])) in `num'
    }
    *local pcc = 100-100*normal(_b[Mean:price]/_b[SD:price])
    *wtp
    foreach num of numlist 2(1)11 {
        replace WTPpm = -1000*(_b[_bwt`num']/_b[price]) in `num'
        nlcom ratio:_b[_bwt`num']/_b[price], post
        replace WTPlm = -1000*(_b[ratio]-1.96*_se[ratio]) in `num'
        replace WTPum = -1000*(_b[ratio]+1.96*_se[ratio]) in `num'        
        estimates restore h`n'
    }
    gen nums = _n
    lab var pcbm "Percent Preferring Element"
    #delimit ;
    twoway line WTPpm nums in 1/11, lcolor(black) yaxis(1) ||
           scatter WTPpm nums in 1/11, msymbol(O) yaxis(1) ||
    rcap WTPlm WTPum nums in 1/11, scheme(s1mono) yaxis(1) ||
    scatter pcbm nums in 1/11, yaxis(2)
    ytitle("Willingness to Pay (Dollars)") xtitle("Birth Weight (grams)") 
    xlabel(1 "2500" 2 "2637" 3 "2807" 4 "2948" 5 "3090" 6 "3260" 7 "3402"
           8 "3544" 9 "3714" 10 "3856" 11 "4000") yline(0, lcolor(red) lpattern(dash))
    legend(order(2 "Willingness to Pay" 3 "95% CI (WTP)" 4 "Percent Preferring"));
    #delimit cr
    graph export "$OUT/Figures/WTP_mixed_``n''.eps", replace
    
    local ++n
    drop WTPpm WTPlm WTPum pcbm nums
    
}
lab var _sob4    "Fall"
lab var _sob2    "Spring"
lab var _sob3    "Summer"
lab var price    "Cost (in 1000s of dollars)"
lab var bwtGrams "Birth Weight (in 1000s of grams)"

#delimit ;
esttab g1 g2 g3 g4 g5 using "$OUT/Regressions/WTP-mixedlogit.tex", replace
cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats
(wtp conf95 pcb N, fmt(%5.1f %5.1f %5.1f %9.0g)
    label("WTP for Birth Weight (1000 grams)" "95\% CI"
          "\% Positively Impacted by Birth Weight" Observations))
starlevels(* 0.10 ** 0.05 *** 0.01) collabels(,none) 
mgroups("All" "Parent" "Non-Parents", pattern(1 1 0 1 0) 
        prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
mlabels(" " "Yes" "No" "Planning" "Not Planning") booktabs label style(tex) 
title("Allowing for Preference Heterogeneity with Mixed Logit"\label{WTPmix}) 
postfoot("\bottomrule           "
         "\multicolumn{6}{p{22.1cm}}{\begin{footnotesize} All specifications "
         "are estimated using a Mixed Logit model. Panel A displays mean     "
         "coefficients from the mixed logit, and panel B displays the        "
         "estimated standard deviation of each coefficient.  All coefficients"
         " with the exception of Cost are allowed to vary randomly throughout"
         " the sample.  The WTP is calculated as the ratio of the coefficient"
         " on birth weight to that on costs, and confidence intervals are    "
         "calculated by the delta method. The \% of respondents who value    "
         "birth weight positively based on individual coefficients is        "
         "displayed at the foot of the table.  Standard errors are clustered "
         "by respondent."
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear
exit

*test for prediction power
foreach c1 of local conds {
    local cc if `c1'&round!=5
    mixlogit chosen price `cc', id(ID) group(group) rand(_bwt* _sob* _gend*)
    mixlpred simchoice if `c1'
    gen simchosen = simchoice>0.5
    tab simchosen chosen if round==5&`c1'
    count if simchosen==1&chosen==1&round==5&`c1'
    local Num=r(N)
    count if simchosen==1&chosen==0&round==5&`c1'
    local D1 =r(N)
    dis "proportion chosen correctly is: " `Num'/(`Num'+`D1')
    drop simchoice simchosen
}

*/
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
lab var bwtGrams      "Birth Weight (in 1000s of grams)"

#delimit ;
esttab m1 m2 using "$OUT/Regressions/conjointWTP.tex", replace
cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats
(wtp conf95 N, fmt(%5.1f %5.1f %9.0g) label("WTP for Birth Weight (1000 grams)" "95\% CI"
                                            Observations))
starlevels(* 0.10 ** 0.05 *** 0.01) collabels(,none)
mlabels("Continuous" "Categorical") booktabs label
title("Birth Characteristics and Willingness to Pay for Birth Weight"\label{WTPreg}) 
keep(bwtGrams costNumerical _gend2 _sob2 _sob3 _sob4 `bwts') style(tex) 
order(bwtGrams costNumerical  `bwts' _gend2 _sob2 _sob3 _sob4)
postfoot("\bottomrule           "
         "\multicolumn{3}{p{11.2cm}}{\begin{footnotesize} Average marginal   "
         "effects from a logit regression are displayed. All columns include "
         "option order fixed effects and round fixed effects. Standard       "
         "errors are clustered by respondent. Willingness to pay and its     "
         "95\% confidence interval is estimated based on the ratio of costs  "
         "to the probability of choosing a particular birth weight. The 95\%  "
         "confidence interval is calculated using the delta method for the   "
         "ratio. "
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear

*gen nonparentPlans = RespPlansKids=="Yes"|RespPregnant=="Yes" if parent!=1
gen planner = RespPlansKids=="Yes"|(RespPregnant=="Yes"&parent==0)
foreach c in nonparentPlans==1 nonparentPlans==0 {
    local vars bwtGrams costNumerical `ctrl' 
    qui logit chosen `vars' if mainSample==1&`c', cluster(ID)
    qui margins, dydx(bwtGrams costNumerical _sob2 _sob3 _sob4 _gend2) post
    

    local wtp = -1000*(_b[bwtGrams]/_b[costNumerical])
    qui nlcom ratio:_b[bwtGrams]/_b[costNumerical], post
    local lb = string(-1000*(_b[ratio]-1.96*_se[ratio]), "%5.1f")
    local ub = string(-1000*(_b[ratio]+1.96*_se[ratio]), "%5.1f")

    dis "WTP is `wtp', [`lb'; `ub']" 
}


**WEIGHTS
local wopts [pw=weight] if mainSample==1, cluster(ID)
eststo: logit chosen bwtGrams costNumerical `ctrl' `wopts' 
margins, dydx(bwtGrams costNumerical _sob2 _sob3 _sob4 _gend2) post
est store m1

estadd scalar wtp = -1000*(_b[bwtGrams]/_b[costNumerical])
nlcom ratio:_b[bwtGrams]/_b[costNumerical], post
local lb = string(-1000*(_b[ratio]-1.96*_se[ratio]), "%5.1f")
local ub = string(-1000*(_b[ratio]+1.96*_se[ratio]), "%5.1f")
estadd local conf95 "[`ub';`lb']": m1

eststo: logit chosen `bwts' costNumerical `ctrl' `wopts' 
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
lab var bwtGrams      "Birth Weight (in 1000s of grams)"

#delimit ;
esttab m1 m2 using "$OUT/Regressions/conjointWTP-weighted.tex", replace
cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats
(wtp conf95 N, fmt(%5.1f %5.1f %9.0g) label("WTP for Birth Weight (1000 grams)" "95\% CI"
                                            Observations))
starlevels(* 0.10 ** 0.05 *** 0.01) collabels(,none)
mlabels("Continuous" "Categorical") booktabs label
title("Birth Characteristics and WTP for Birth Weight Re-weighting by State Population"
      \label{WTPregweight}) 
keep(bwtGrams costNumerical _gend2 _sob2 _sob3 _sob4 `bwts') style(tex)
order(bwtGrams costNumerical  `bwts' _gend2 _sob2 _sob3 _sob4)
postfoot("\bottomrule           "
         "\multicolumn{3}{p{11.2cm}}{\begin{footnotesize} Refer to Table    "
         "\ref{WTPreg} for full notes.  This table replicates these results "
         "assigning probability weights to respondents based on their state "
         "of residence so that the likelihood a particular respondent is    "
         "included in the survey is the same as their state's portion of    "
         "the national population."
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear


*-------------------------------------------------------------------------------
*--- (5a) By Parent/non-parent
*-------------------------------------------------------------------------------
gen All = 1
local m = 1
foreach c in All==1 parent==1 parent==0 nonparentP==1 nonparentP==0 {
    local vars bwtGrams costNumerical `ctrl' 
    eststo: logit chosen `vars' if mainSample==1&`c', cluster(ID)
    margins, dydx(bwtGrams costNumerical _sob2 _sob3 _sob4 _gend2) post
    est store m`m'

    estadd scalar wtp = -1000*(_b[bwtGrams]/_b[costNumerical])
    nlcom ratio:_b[bwtGrams]/_b[costNumerical], post
    local lb = string(-1000*(_b[ratio]-1.96*_se[ratio]), "%5.1f")
    local ub = string(-1000*(_b[ratio]+1.96*_se[ratio]), "%5.1f")
    estadd local conf95a "[`ub';`lb']": m`m'
    local ++m
}
#delimit ;
esttab m1 m2 m3 m4 m5 using "$OUT/Regressions/conjointGroups.tex", replace
cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats
(wtp conf95a N, fmt(%5.1f %5.1f %9.0g) label("WTP for Birth Weight (1000 grams)"
                                            "95\% CI" Observations))
starlevels(* 0.10 ** 0.05 *** 0.01) collabels(,none)
mgroups("All" "Parent" "Non-Parents", pattern(1 1 0 1 0)
        prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
mlabels(" " "Yes" "No" "Planning" "Not Planning") booktabs label
title("Birth Characteristics and Willingness to Pay for Birth Weight"\label{WTPgreg}) 
keep(bwtGrams costNumerical _gend2 _sob2 _sob3 _sob4) style(tex)
order(bwtGrams costNumerical  _gend2 _sob2 _sob3 _sob4)
postfoot("\bottomrule           "
         "\multicolumn{6}{p{19.5cm}}{\begin{footnotesize} Average marginal   "
         "effects from a logit regression are displayed. All columns include "
         "option order fixed effects and round fixed effects. Standard       "
         "errors are clustered by respondent. Willingness to pay and its     "
         "95\% confidence interval is estimated based on the ratio of costs  "
         "to the probability of choosing a particular birth weight. The 95\% "
         "confidence interval is calculated using the delta method for the   "
         "ratio. Identical regressions with a continuous measure of          "
         "birth weight are provided in Table \ref{WTPgregc}. Planning and    "
         "Not Planning in columns 4 and 5 refer to decisions regarding       "
         "future children as outlined in Table \ref{sumstats}."
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear


local m = 1
foreach c in All==1 parent==1 parent==0 nonparentP==1 nonparentP==0 {
    local vars costNumerical `bwts' `ctrl' 
    eststo: logit chosen `vars' if mainSample==1&`c', cluster(ID)
    margins, dydx(`bwts' costNumerical _sob2 _sob3 _sob4 _gend2) post
    est store m`m'

    local ++m
}
#delimit ;
esttab m1 m2 m3 m4 m5 using "$OUT/Regressions/conjointGroups-wts.tex", replace
cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats
(N, fmt(%9.0g) label(Observations))
starlevels(* 0.10 ** 0.05 *** 0.01) collabels(,none)
mgroups("All" "Parent" "Non-Parents", pattern(1 1 0 1 0)
        prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
mlabels(" " "Yes" "No" "Planning" "Not-Planning") booktabs label
title("Birth Characteristics and Willingness to Pay for Birth Weight"\label{WTPgregc}) 
keep(costNumerical `bwts' _gend2 _sob2 _sob3 _sob4) style(tex)
order(bwtGrams costNumerical  `bwts' _gend2 _sob2 _sob3 _sob4)
postfoot("\bottomrule           "
         "\multicolumn{6}{p{15.0cm}}{\begin{footnotesize} Average marginal   "
         "effects from a logit regression are displayed. All columns include "
         "option order fixed effects and round fixed effects. Standard       "
         "errors are clustered by respondent. Willingness to pay and its     "
         "95\% confidence interval is estimated based on the ratio of costs  "
         "to the probability of choosing a particular birth weight. The 95\%  "
         "confidence interval is calculated using the delta method for the   "
         "ratio.  No WTP figures are displayed in the table footer as each   "
         "birth weight category is associated with its own WTP. These values "
         "are all displayed in Figure \ref{WTP-marginal}, or are displayed   "
         "for the linear specification in Table \ref{WTPgreg}."
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear

*-------------------------------------------------------------------------------
*--- (5a-i) Interaction models
*-------------------------------------------------------------------------------
gen bwtGxParent = bwtGrams*parent
lab var bwtGxParent "Birth Weight $\times$ Parent"
local vars bwtGrams costNumerical parent bwtGxParent `ctrl'
eststo: logit chosen `vars' if mainSample==1, cluster(ID)
margins, dydx(bwtGrams costNumerical parent bwtGxParent _sob2 _sob3 _sob4 _gend2) post
est store m1
estadd scalar wtp = -1000*(_b[bwtGrams]/_b[costNumerical])
nlcom ratio:_b[bwtGrams]/_b[costNumerical], post
local lb = string(-1000*(_b[ratio]-1.96*_se[ratio]), "%5.1f")
local ub = string(-1000*(_b[ratio]+1.96*_se[ratio]), "%5.1f")
estadd local conf95a "[`ub';`lb']": m1
est restore m1
estadd scalar wtpb = -1000*(_b[bwtGxParent]/_b[costNumerical])
nlcom ratio:_b[bwtGxParent]/_b[costNumerical], post
local lb1 = string(-1000*(_b[ratio]-1.96*_se[ratio]), "%5.1f")
local ub1 = string(-1000*(_b[ratio]+1.96*_se[ratio]), "%5.1f")
estadd local conf95b "[`ub1';`lb1']": m1


local vars bwtGrams costNumerical parent bwtGxParent  `ctrl'
eststo: logit chosen `vars' if mainSample==1&nonparentPlans!=0, cluster(ID)
margins, dydx(bwtGrams costNumerical parent bwtGxParent _sob2 _sob3 _sob4 _gend2) post
est store m2
estadd scalar wtp = -1000*(_b[bwtGrams]/_b[costNumerical])
nlcom ratio:_b[bwtGrams]/_b[costNumerical], post
local lb = string(-1000*(_b[ratio]-1.96*_se[ratio]), "%5.1f")
local ub = string(-1000*(_b[ratio]+1.96*_se[ratio]), "%5.1f")
estadd local conf95a "[`ub';`lb']": m2
est restore m2
estadd scalar wtpb = -1000*(_b[bwtGxParent]/_b[costNumerical])
nlcom ratio:_b[bwtGxParent]/_b[costNumerical], post
local lb1 = string(-1000*(_b[ratio]-1.96*_se[ratio]), "%5.1f")
local ub1 = string(-1000*(_b[ratio]+1.96*_se[ratio]), "%5.1f")
estadd local conf95b "[`ub1';`lb1']": m2

local vars bwtGrams costNumerical parent bwtGxParent  `ctrl'
eststo: logit chosen `vars' if mainSample==1&nonparentPlans!=1, cluster(ID)
margins, dydx(bwtGrams costNumerical parent bwtGxParent _sob2 _sob3 _sob4 _gend2) post
est store m4
estadd scalar wtp = -1000*(_b[bwtGrams]/_b[costNumerical])
nlcom ratio:_b[bwtGrams]/_b[costNumerical], post
local lb = string(-1000*(_b[ratio]-1.96*_se[ratio]), "%5.1f")
local ub = string(-1000*(_b[ratio]+1.96*_se[ratio]), "%5.1f")
estadd local conf95a "[`ub';`lb']": m4
est restore m4
estadd scalar wtpb = -1000*(_b[bwtGxParent]/_b[costNumerical])
nlcom ratio:_b[bwtGxParent]/_b[costNumerical], post
local lb1 = string(-1000*(_b[ratio]-1.96*_se[ratio]), "%5.1f")
local ub1 = string(-1000*(_b[ratio]+1.96*_se[ratio]), "%5.1f")
estadd local conf95b "[`ub1';`lb1']": m4


gen bwtGxPlans = bwtGrams*nonparentPlans
lab var bwtGxPlans "Birth Weight $\times$ Planning Children"
local vars bwtGrams costNumerical nonparentPlans bwtGxPlans  `ctrl'
eststo: logit chosen `vars' if mainSample==1, cluster(ID)
margins, dydx(bwtGrams costNumerical nonparentPlans bwtGxPlans _sob2 _sob3 _sob4 _gend2) post
est store m3
estadd scalar wtp = -1000*(_b[bwtGrams]/_b[costNumerical])
nlcom ratio:_b[bwtGrams]/_b[costNumerical], post
local lb = string(-1000*(_b[ratio]-1.96*_se[ratio]), "%5.1f")
local ub = string(-1000*(_b[ratio]+1.96*_se[ratio]), "%5.1f")
estadd local conf95a "[`ub';`lb']": m3
est restore m3
estadd scalar wtpb = -1000*(_b[bwtGxPlans]/_b[costNumerical])
nlcom ratio:_b[bwtGxPlans]/_b[costNumerical], post
local lb1 = string(-1000*(_b[ratio]-1.96*_se[ratio]), "%5.1f")
local ub1 = string(-1000*(_b[ratio]+1.96*_se[ratio]), "%5.1f")
estadd local conf95b "[`ub1';`lb1']": m3

#delimit ;
esttab m1 m2 m4 m3 using "$OUT/Regressions/conjointWTP-interactions.tex", replace
cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats
(wtp conf95a wtpb conf95b N, fmt(%5.1f %5.1f %9.0g)
    label("WTP for Birth Weight (1000 grams)" "95\% CI (Birth Weight)"
          "WTP for Interation" "95\% CI (Interaction)" Observations))
starlevels(* 0.10 ** 0.05 *** 0.01) collabels(,none)
mlabels("Parents v Non-Parents" "Parents v Planners"
        "Parents v Non-Planners" "Planners v Non-Planners")
booktabs label
title("Birth Characteristics and Willingness to Pay for Birth Weight"\label{WTPpar}) 
keep(bwtGrams costNumerical bwtGxParent bwtGxPlans _gend2 _sob2 _sob3 _sob4)
order(bwtGrams costNumerical bwtGxParent bwtGxPlans _gend2 _sob2 _sob3 _sob4)
style(tex)
postfoot("\bottomrule           "
         "\multicolumn{5}{p{23.6cm}}{\begin{footnotesize} Refer to Table     "
         "\ref{WTPreg} for full notes.  Each specification interacts birth   "
         "weight with a dummy in order to estimate the differential          "
         "importance of birth weight, as well as WTP. Values for WTP of the  "
         "baseline group are displayed first in the footer, followed by the  "
         "\emph{differential} WTP for the interaction group. Each model      "
         "also includes the uninteracted dummy as a control.    Column 1     "
         "consists of all observations, so the interaction is interpreted as "
         "the difference between all parents and all non parents. Column 2   "
         "consists of all parents and all non parents who plan to have       "
         "children (non parents who do not plan to have children are removed "
         "from the sample) so the interaction is interpreted as the          "
         "difference between all parents and non parents who plan to have    "
         "children.  Column 3 consists of all parents and non parents who    "
         "\emph{don't} plan to have children, and column 4 consists of       "
         "non-parents only, where the interaction is interpreted as the      "
         "difference between those who plan to have children and those who   "
         "do not."
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear


*-------------------------------------------------------------------------------
*--- (5b) By gender of respondent
*-------------------------------------------------------------------------------
gen mother = parent==1&RespSe=="Female"
gen father = parent==1&RespSe=="Male"

local m = 1
foreach c in All==1 RespSe=="Female" RespSe=="Male" mother==1 father==1{
    local vars bwtGrams costNumerical `ctrl' 
    eststo: logit chosen `vars' if mainSample==1&`c', cluster(ID)
    margins, dydx(bwtGrams costNumerical _sob2 _sob3 _sob4 _gend2) post
    est store m`m'

    estadd scalar wtp = -1000*(_b[bwtGrams]/_b[costNumerical])
    nlcom ratio:_b[bwtGrams]/_b[costNumerical], post
    local lb = string(-1000*(_b[ratio]-1.96*_se[ratio]), "%5.1f")
    local ub = string(-1000*(_b[ratio]+1.96*_se[ratio]), "%5.1f")
    estadd local conf95a "[`ub';`lb']": m`m'
    local ++m
}
#delimit ;
esttab m1 m2 m3 m4 m5 using "$OUT/Regressions/conjointGender.tex", replace
cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats
(wtp conf95a N, fmt(%5.1f %5.1f %9.0g) label("WTP for Birth Weight (1000 grams)"
                                            "95\% CI" Observations))
starlevels(* 0.10 ** 0.05 *** 0.01) collabels(,none)
mgroups("All" "All Respondents" "Parents Only", pattern(1 1 0 1 0)
        prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
mlabels(" " "Female" "Male" "Mother" "Father") booktabs label
title("Birth Characteristics and Willingness to Pay for Birth Weight by Gender"
      \label{WTPgend}) 
keep(bwtGrams costNumerical _gend2 _sob2 _sob3 _sob4) style(tex)
order(bwtGrams costNumerical _gend2 _sob2 _sob3 _sob4)
postfoot("\bottomrule           "
         "\multicolumn{6}{p{20.2cm}}{\begin{footnotesize} Average marginal   "
         "effects from a logit regression are displayed. All columns include "
         "option order fixed effects and round fixed effects. Standard       "
         "errors are clustered by respondent. Willingness to pay and its     "
         "95\% confidence interval is estimated based on the ratio of costs  "
         "to the probability of choosing a particular birth weight. The 95\% "
         "confidence interval is calculated using the delta method for the   "
         "ratio. Male and Female and Mother and Father refer to              "
         "characteristics of experimental respondents."
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear



*-------------------------------------------------------------------------------
*--- (5c) By gender of profile
*-------------------------------------------------------------------------------
local ctrl `oFEs' _sob*
local bwts _bwt2 _bwt3 _bwt4 _bwt5 _bwt6 _bwt7 _bwt8 _bwt9 _bwt10 _bwt11
local g1 mainSample==1&_gend2==1
local g2 mainSample==1&_gend2==0

eststo: logit chosen bwtGrams costNumerical `ctrl' if `g1', cluster(ID)
margins, dydx(bwtGrams costNumerical _sob2 _sob3 _sob4) post
est store m1
estadd scalar wtp = -1000*(_b[bwtGrams]/_b[costNumerical])
nlcom ratio:_b[bwtGrams]/_b[costNumerical], post
local lb = string(-1000*(_b[ratio]-1.96*_se[ratio]), "%5.1f")
local ub = string(-1000*(_b[ratio]+1.96*_se[ratio]), "%5.1f")
estadd local conf95 "[`ub';`lb']": m1

eststo: logit chosen `bwts' costNumerical `ctrl' if `g1', cluster(ID)
margins, dydx(costNumerical `bwts' _sob2 _sob3 _sob4) post
est store m2

eststo: logit chosen bwtGrams costNumerical `ctrl' if `g2', cluster(ID)
margins, dydx(bwtGrams costNumerical _sob2 _sob3 _sob4) post
est store m3
estadd scalar wtp = -1000*(_b[bwtGrams]/_b[costNumerical])
nlcom ratio:_b[bwtGrams]/_b[costNumerical], post
local lb = string(-1000*(_b[ratio]-1.96*_se[ratio]), "%5.1f")
local ub = string(-1000*(_b[ratio]+1.96*_se[ratio]), "%5.1f")
estadd local conf95 "[`ub';`lb']": m3

eststo: logit chosen `bwts' costNumerical `ctrl' if `g2', cluster(ID)
margins, dydx(costNumerical `bwts' _sob2 _sob3 _sob4) post
est store m4

gen girlBW = _gend2*bwtGrams
lab var girlBW "Birth Weight $\times$ Girl"
local int bwtGrams _gend2 girlBW

eststo: logit chosen `int' costNumerical `ctrl' if mainSample==1, cluster(ID)
margins, dydx(bwtGrams _gend2 girlBW costNumerical _sob2 _sob3 _sob4) post
est store m5


#delimit ;
esttab m1 m2 m3 m4 using "$OUT/Regressions/conjoint-gendInd.tex", replace
cells(b(star fmt(%-9.3f)) se(fmt(%-9.3f) par([ ]) )) stats
(wtp conf95 N, fmt(%5.1f %5.1f %9.0g) label("WTP for Birth Weight (1000 grams)"
                                            "95\% CI" Observations))
starlevels(* 0.10 ** 0.05 *** 0.01) collabels(,none)
mgroups("Girl Experiment" "Boy Experiment", pattern(1 0 1 0)
        prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
booktabs label
title("Gender of Index Child and Willingness to Pay for Birth Weight"\label{WTPgendI}) 
keep(costNumerical bwtGrams `bwts' _sob2 _sob3 _sob4) style(tex)
order(costNumerical bwtGrams `bwts' _sob2 _sob3 _sob4)
postfoot("\bottomrule           "
         "\multicolumn{5}{p{15.4cm}}{\begin{footnotesize} Estimates are      "
         "separated by the gender of the child shown in each profile (girl   "
         "or boy). Average marginal effects from a logit regression are      "
         "displayed. All columns include "
         "option order fixed effects and round fixed effects. Standard       "
         "errors are clustered by respondent. Willingness to pay and its     "
         "95\% confidence interval is estimated based on the ratio of costs  "
         "to the probability of choosing a particular birth weight. The 95\%  "
         "confidence interval is calculated using the delta method for the   "
         "ratio. WTP estimates are only displayed in columns 1 and 3, as     "
         "columns 2 and 4 result in a single WTP for each categorical birth  "
         "weight measure.  Individual WTP values for boys and girls in the   "
         "categorical weights are available in Figure \ref{graphGend}."
         "\end{footnotesize}}\end{tabular}\end{table}");
#delimit cr
estimates clear

*-------------------------------------------------------------------------------
*--- (5d) Block bootstrap robustness test
*-------------------------------------------------------------------------------
local ctrl `oFEs' _gend* _sob*
local nboot 1000
    
foreach c in All==1 parent==1 parent==0 nonparentP==1 nonparentP==0   /*
          */ mother==1 father==1 RespSe=="Female" RespSe=="Male" {
    preserve
    keep if `c'&mainSample==1
    #delimit ;
    bootstrap ratio=(_b[bwtGrams]/_b[costNumerical]),
    reps(`nboot') seed(1201) cluster(ID) idcluster(bID):
    logit chosen bwtGrams costNumerical `ctrl', cluster(bID);
    #delimit cr
    restore
}
preserve
keep if _gend2==1&mainSample==1
#delimit ;
bootstrap ratio=(_b[bwtGrams]/_b[costNumerical]),
reps(`nboot') seed(1201) cluster(ID) idcluster(bID):
logit chosen bwtGrams costNumerical `oFEs' _sob*, cluster(bID);
restore;

preserve;
keep if _gend2==0&mainSample==1;
bootstrap ratio=(_b[bwtGrams]/_b[costNumerical]),
reps(`nboot') seed(1201) cluster(ID) idcluster(bID):
logit chosen bwtGrams costNumerical `oFEs' _sob*, cluster(bID);
#delimit cr
restore


*-------------------------------------------------------------------------------
*--- (6) Full WTP and marginal WTP
*-------------------------------------------------------------------------------
local ctrl `oFEs' _gend* _sob*
local bwts _bwt2 _bwt3 _bwt4 _bwt5 _bwt6 _bwt7 _bwt8 _bwt9 _bwt10 _bwt11
eststo: logit chosen `bwts' costNumerical `ctrl' if mainSample==1, cluster(ID)
margins, dydx(costNumerical `bwts' _gend2 _sob2 _sob3 _sob4) post

gen bwtWTP = 0 in 1
gen bwtUB  = 0 in 1
gen bwtLB  = 0 in 1
foreach num of numlist 2(1)11 {
    est restore est1
    replace bwtWTP = -1000*(_b[_bwt`num']/_b[costNumerical]) in `num'
    nlcom ratio:_b[_bwt`num']/_b[costNumerical], post
    replace bwtUB = -1000*(_b[ratio]+1.96*_se[ratio]) in `num'
    replace bwtLB = -1000*(_b[ratio]-1.96*_se[ratio]) in `num'
}

gen nums = _n
#delimit ;
twoway line bwtWTP nums in 1/11, lcolor(black)   ||
    scatter bwtWTP nums in 1/11, msymbol(O)  ||
    rcap bwtLB bwtUB nums in 1/11, scheme(s1mono) 
ytitle("Willingness to Pay (Dollars)") xtitle("Birth Weight (grams)") 
xlabel(1 "2500" 2 "2637" 3 "2807" 4 "2948" 5 "3090" 6 "3260" 7 "3402"
       8 "3544" 9 "3714" 10 "3856" 11 "4000") yline(0, lcolor(red) lpattern(dash))
legend(order(2 "Willingness to Pay" 3 "95% CI"));
#delimit cr
graph export "$OUT/Figures/WTP_relative.eps", replace

**GIRLS AND BOYS
local ctrl `oFEs' _sob*
local g1 mainSample==1&_gend2==1
local g2 mainSample==1&_gend2==0
                      
eststo: logit chosen `bwts' costNumerical `ctrl' if `g1', cluster(ID)
margins, dydx(costNumerical `bwts' _sob2 _sob3 _sob4) post

gen gbwtWTP = 0 in 1
gen gbwtUB  = 0 in 1
gen gbwtLB  = 0 in 1
foreach num of numlist 2(1)11 {
    est restore est2
    replace gbwtWTP = -1000*(_b[_bwt`num']/_b[costNumerical]) in `num'
    nlcom ratio:_b[_bwt`num']/_b[costNumerical], post
    replace gbwtUB = -1000*(_b[ratio]+1.96*_se[ratio]) in `num'
    replace gbwtLB = -1000*(_b[ratio]-1.96*_se[ratio]) in `num'
}
eststo: logit chosen `bwts' costNumerical `ctrl' if `g2', cluster(ID)
margins, dydx(costNumerical `bwts' _sob2 _sob3 _sob4) post

gen bbwtWTP = 0 in 1
gen bbwtUB  = 0 in 1
gen bbwtLB  = 0 in 1
foreach num of numlist 2(1)11 {
    est restore est3
    replace bbwtWTP = -1000*(_b[_bwt`num']/_b[costNumerical]) in `num'
    nlcom ratio:_b[_bwt`num']/_b[costNumerical], post
    replace bbwtUB = -1000*(_b[ratio]+1.96*_se[ratio]) in `num'
    replace bbwtLB = -1000*(_b[ratio]-1.96*_se[ratio]) in `num'
}

#delimit ;
twoway line gbwtWTP nums in 1/11, lcolor(blue) lwidth(thick)   ||
       line bbwtWTP nums in 1/11, lcolor(red) lwidth(thick) lpattern(dash) ||
       rcap gbwtLB gbwtUB nums in 1/11, ||
       rcap bbwtLB bbwtUB nums in 1/11, scheme(s1mono) 
ytitle("Willingness to Pay (Dollars)") xtitle("Birth Weight (grams)") 
xlabel(1 "2500" 2 "2637" 3 "2807" 4 "2948" 5 "3090" 6 "3260" 7 "3402"
       8 "3544" 9 "3714" 10 "3856" 11 "4000") yline(0, lcolor(red) lpattern(dash))
legend(order(1 "Girl Child" 2 "Boy Child" 3 "95% CI"));
#delimit cr
graph export "$OUT/Figures/WTP_relative_gends.eps", replace



local ctrl `oFEs' _gend* _sob*
gen _bwt1=birthweight=="5 pounds 8 ounces"
gen m_bwtWTP = 0 in 1
gen m_bwtUB  = 0 in 1
gen m_bwtLB  = 0 in 1
foreach num of numlist 2(1)11 {
    local n1 = `num'-1
    preserve
    drop _bwt`n1'
    eststo: logit chosen _bwt* costNumerical `ctrl' if mainSample==1, cluster(ID)
    margins, dydx(costNumerical _bwt`num') post
    restore
    
    replace m_bwtWTP = -1000*(_b[_bwt`num']/_b[costNumerical]) in `num'
    dis "Marginal WTP for bwt `num':" -1000*(_b[_bwt`num']/_b[costNumerical])/136.4
    nlcom ratio:_b[_bwt`num']/_b[costNumerical], post
    replace m_bwtUB = -1000*(_b[ratio]+1.96*_se[ratio]) in `num'
    replace m_bwtLB = -1000*(_b[ratio]-1.96*_se[ratio]) in `num'

}

#delimit ;
twoway line m_bwtWTP nums in 1/11, lcolor(black)   ||
    scatter m_bwtWTP nums in 1/11, msymbol(O)  ||
    rcap m_bwtLB m_bwtUB nums in 1/11, scheme(s1mono) 
ytitle("Marginal Willingness to Pay (Dollars)") xtitle("Birth Weight (grams)") 
xlabel(1 "2500" 2 "2637" 3 "2807" 4 "2948" 5 "3090" 6 "3260" 7 "3402"
       8 "3544" 9 "3714" 10 "3856" 11 "4000") yline(0, lcolor(red) lpattern(dash))
legend(order(2 "Marginal Willingness to Pay" 3 "95% CI"));
#delimit cr
graph export "$OUT/Figures/WTP_marginal.eps", replace

cap gen All=1
foreach c in All==1 parent==1 parent==0 nonparentP==1 nonparentP==0 {
    dis "group is `c'"
    foreach num of numlist 2(1)11 {
        local n1 = `num'-1
        preserve
        qui: drop _bwt`n1'
        qui: logit chosen _bwt* costNumerical `ctrl' if mainSample==1&`c', cluster(ID)
        qui: margins, dydx(costNumerical _bwt`num')
        local pointEst= -1000*(_b[_bwt`num']/_b[costNumerical])/136.4
        qui: nlcom ratio:_b[_bwt`num']/_b[costNumerical], post
        local m_bwtUB = -1000*(_b[ratio]+1.96*_se[ratio])/136.4 in `num'
        local m_bwtLB = -1000*(_b[ratio]-1.96*_se[ratio])/136.4 in `num'
        restore
    
        dis "Marginal WTP for bwt `num': `pointEst' [`m_bwtLB';`m_bwtUB']" 
    }
}
exit
*-------------------------------------------------------------------------------
*--- (7) Assumptions
*-------------------------------------------------------------------------------
gen bw_place1 = ff1=="Birth Weight"
gen bw_place2 = ff2=="Birth Weight"
gen bw_place3 = ff3=="Birth Weight"
gen bw_place4 = ff4=="Birth Weight"

gen _asmEst = .
gen _asmUB  = .
gen _asmLB  = .
gen _asmOrd = .

local c1 `oFEs' _gend* _sob* _cost*
reg chosen bwtGrams `c1' if mainSample==1, cluster(ID)
replace _asmEst = _b[bwtGrams] in 5
replace _asmUB  = _b[bwtGrams]+1.96*_se[bwtGrams] in 5
replace _asmLB  = _b[bwtGrams]-1.96*_se[bwtGrams] in 5
replace _asmOrd = 5 in 5

local oo = 4
foreach num of numlist 1(1)4 {
    reg chosen bwtGrams `c1' if bw_place`num'==1&mainSample==1, cluster(ID)
    replace _asmEst = _b[bwtGrams] in `num'
    replace _asmUB  = _b[bwtGrams]+1.96*_se[bwtGrams] in `num'
    replace _asmLB  = _b[bwtGrams]-1.96*_se[bwtGrams] in `num'
    replace _asmOrd = `oo' in `num'
    local --oo
}
sort _asmOrd

#delimit ;
twoway  scatter _asmOrd _asmEst, ylabel(1 "4" 2 "3" 3 "2" 4 "1" 5 "Pooled", angle(0))
|| rcap _asmUB _asmLB _asmOrd, xline(0, lcolor(blue) lpattern(dash))
legend(lab(1 "Point Estimate") lab(2 "95\% CI")) scheme(s1mono) horizontal
ytitle("Row Position of Birth Weight Attribute") xtitle("{&Delta} Pr Chooses Birth");
graph export "$OUT/Figures/attributeOrder.eps", replace;
#delimit cr

foreach var of varlist _asm* {
    replace `var' = .
}

local c1 bw_place* _gend* _sob* _cost*
reg chosen bwtGrams `c1' if mainSample==1, cluster(ID)
replace _asmEst = _b[bwtGrams] in 8
replace _asmUB  = _b[bwtGrams]+1.96*_se[bwtGrams] in 8
replace _asmLB  = _b[bwtGrams]-1.96*_se[bwtGrams] in 8
replace _asmOrd  = 8 in 8

local oo = 7
foreach num of numlist 1(1)7 {
    reg chosen bwtGrams `c1' if round==`num'&mainSample==1, cluster(ID)
    replace _asmEst = _b[bwtGrams] in `num'
    replace _asmUB  = _b[bwtGrams]+1.96*_se[bwtGrams] in `num'
    replace _asmLB  = _b[bwtGrams]-1.96*_se[bwtGrams] in `num'
    replace _asmOrd = `oo' in `num'
    local --oo
}
sort _asmOrd

#delimit ;
twoway  scatter _asmOrd _asmEst, xline(0, lcolor(blue) lpattern(dash)) ||
    rcap _asmUB _asmLB _asmOrd, scheme(s1mono) horizontal
ylabel(1 "7" 2 "6" 3 "5" 4 "4" 5 "3" 6 "2" 7 "1" 8 "Pooled", angle(0))
ytitle("Round Number of Experiment") xtitle("{&Delta} Pr Chooses Birth")
legend(lab(1 "Point Estimate") lab(2 "95\% CI"));
graph export "$OUT/Figures/roundOrder.eps", replace;
#delimit cr

    
