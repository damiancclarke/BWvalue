/* birthDesc.do                  damiancclarke             yyyy-mm-dd:2016-12-25
----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8

*/

vers 11
clear all
set more off
cap log close

*-------------------------------------------------------------------------------
*--- (1) globals and locals
*-------------------------------------------------------------------------------
global DAT "~/investigacion/2017/BWvalue/data/births"
global OUT "~/investigacion/2017/BWvalue/results/births"
global LOG "~/investigacion/2017/BWvalue/log"

log using "$LOG/birthDesc.txt", replace text

*-------------------------------------------------------------------------------
*--- (2) Data
*-------------------------------------------------------------------------------
use "$DAT/natl2013"
replace dbwt=. if dbwt==9999
replace dbwt=. if dbwt>5000
replace dbwt=. if dbwt<500
#delimit ;
twoway hist dbwt if dbwt>=2500&dbwt<=4000, frequency bcolor(gs0)  width(21) ||
       hist dbwt if dbwt< 2500|dbwt >4000, frequency bcolor(gs12) width(21)
legend(label(1 "2500-4000g") label(2 "<2500 or >4000")) scheme(s1mono)
xtitle("Birth Weight (grams)")
ylabel(,angle(0) format(%15.0fc));
#delimit cr
graph export "$OUT/birthweight.eps", replace
