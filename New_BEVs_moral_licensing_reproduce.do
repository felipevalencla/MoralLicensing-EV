* STEPS TO REPLICATE THE RESULTS IN STATA
* Author: Felipe Valencia Clavijo

* BEFORE STARTING HERE YOU NEED TO PREPARE THE DATASET. THE INITIAL QUERIES AND VARIABLE GENERATION WERE DONE IN GOOGLE SHEETS, BUT CAN BE ACHIEVED USING PROPER QUERIES (SEE THE FIRST STEPS IN THE README FILE)

* Set the working directory and import the csv file:
* MAKE SURE TO USE THE CLONED REPOSITORY FOLDER (YOU CAN ALWAYS CHANGE THE PATH)
* Example:
cd "C:\Documents\MoralLicensing-EV"
 
import delimited "BEVs_with_attitudes_California.csv"

* Generate additional variables & fix errors:
gen older_than_50 = (age > 50)
replace annual_vmt_est = . if annual_vmt_est < 0
gen log_annual_vmt_est = log(annual_vmt_est)

** Remove edu_level == 1 because there are only 17 observations.
**drop if edu_level == 1
replace edu_level = . if edu_level == 1

** Rename variables properly for better understanding and graphs

** Adding labels (if desired)
label var id "Respondent id"
label var attitude_reduce_ghge_fix "Importance of reducing GHG Emissions (-3=low importance to 3=high importance)"
label var prev_evs "=1 if Previously owned EVs (either PHEVs, HEVs, or BEVs)"
label var prev_phevs "=1 if Previously owned PHEVs"
label var prev_hevs "=1 if Previously owned HEVs"
label var prev_bevs "=1 if Previously owned BEVs"
label var carmain "Model of the Car"
label var age "Age"
label var older_than_50 "=1 if age > 50"
label var year "Year the respondent answered the survey"
label var hi "Household Income"
label var gender "=1 if respondent is male"
label var edu_level "Educational Level (1=low to 4=high)"
label var home_ownership "=1 if respondent owns the house"
label var detached_home "=1 if the type of house is detached"
label var people_household "Number of People in the Household"
label var vehicles_household "Number of Vehicles in the Household"
label var longest_trip12 "Longest trip in miles in the last 12 months"
label var trips_over200miles12 "Number of Trips with over 200 miles in the last 12 months"
label var annual_vmt_est "Annual vehicle miles traveled (VMT)"
label var log_annual_vmt_est "Log VMT"
label var oneway_commute_distance "One-way Commute Distance"


* NEW ADOPTERS OF EVs vs PREVIOUS ADOPTERS OF EVs

* Checks:

** Multicollinearity:
regress attitude_reduce_ghge_fix ib1.prev_evs c.age##c.age  i.edu_level hi i.gender c.people_household c.vehicles_household trips_over200miles12 longest_trip12 annual_vmt_est i.year, vce(robust)
vif
**** NOTE: There was evidence that particularly the observations from Educational Level 1 were too few, which cause a lot of the multicollinearity and other problems when trying to interpret the regressions; therefore the edu_level ==1 was removed.

** Correlogram:
corr attitude_reduce_ghge_fix prev_evs age edu_level hi gender people_household vehicles_household trips_over200miles12 longest_trip12 annual_vmt_est year

** Heteroscedasticity:
*** To solve potential heteroscedasticity and other things I decided to implement a vce(robust) in all my regressions.


* Regressions:

*** Attitudes with Coefficients:

*** Ordered Probit Models with Robust:

**** Ordered Probit with Coefficients
oprobit attitude_reduce_ghge_fix ib1.prev_evs c.age##c.age i.edu_level hi i.gender c.people_household c.vehicles_household c.trips_over200miles12 c.longest_trip12 c.annual_vmt_est i.year, vce(robust)
est store attitudes_co

**** Ordered Probit with Coefficients & Interaction Terms
******* Interaction Term with Age
oprobit attitude_reduce_ghge_fix ib1.prev_evs##c.age##c.age i.edu_level hi i.gender c.people_household c.vehicles_household c.trips_over200miles12 c.longest_trip12 c.annual_vmt_est i.year, vce(robust)
est store attitudes_co_prev_age

******* Interaction Term with Household Income
oprobit attitude_reduce_ghge_fix ib1.prev_evs##c.hi c.age##c.age i.edu_level i.gender c.people_household c.vehicles_household c.trips_over200miles12 c.longest_trip12 c.annual_vmt_est i.year, vce(robust)
est store attitudes_co_prev_hi

******* Interaction Term with Education Level (EL)
oprobit attitude_reduce_ghge_fix ib1.prev_evs##i.edu_level c.age##c.age hi i.gender c.people_household c.vehicles_household c.trips_over200miles12 c.longest_trip12 c.annual_vmt_est i.year, vce(robust)
est store attitudes_co_prev_edu

******* Interaction Term with Gender
oprobit attitude_reduce_ghge_fix ib1.prev_evs##i.gender c.age##c.age hi i.edu_level c.people_household c.vehicles_household c.trips_over200miles12 c.longest_trip12 c.annual_vmt_est i.year, vce(robust)
est store attitudes_co_prev_gen

******* Interaction Term with Vehicles
oprobit attitude_reduce_ghge_fix ib1.prev_evs##c.vehicles_household c.age##c.age hi i.edu_level i.gender c.people_household c.trips_over200miles12 c.longest_trip12 c.annual_vmt_est i.year, vce(robust)
est store attitudes_co_prev_veh

******* Interaction Term with Trips>200
oprobit attitude_reduce_ghge_fix ib1.prev_evs##c.trips_over200miles12 c.age##c.age i.edu_level hi i.gender c.people_household c.vehicles_household c.longest_trip12 c.annual_vmt_est i.year, vce(robust)
est store attitudes_co_prev_trip200



**** (OPTIONAL) Generate a scientific journal table of the results of my Ordered Probit Regressions with Interaction Terms:

*esttab attitudes_co attitudes_co_prev_age attitudes_co_prev_hi attitudes_co_prev_edu attitudes_co_prev_gen attitudes_co_prev_veh attitudes_co_prev_trip200 using Table1.rtf, replace se pr2 star(* 0.10 ** 0.05 *** 0.01) b(%5.3f) no gap

**** Attitudes with Marginal Effects:

* Ordered Probit Model with Robust
quietly oprobit attitude_reduce_ghge_fix ib1.prev_evs c.age##c.age i.edu_level hi i.gender c.people_household c.vehicles_household c.trips_over200miles12 c.longest_trip12 c.annual_vmt_est i.year, vce(robust)

* Marginal effects instead of coefficients
* NOTE: Only 3 was used because the distribution of the attitudes is very skewed, so the major differences are found in the extremely important group.
margins, dydx(*) predict(pr outcome(3)) post
est store attitudes_me

**** (OPTIONAL) Generate a scientific journal table of the results of my Ordered Probit Regression with Marginal Effects for the extremes of the Likert Scale

*esttab attitudes_me using Table2.rtf, replace se star(* 0.10 ** 0.05 *** 0.01) b(%5.3f) no gap

**** Verifying that the control variables are not different between groups, and robustly determining if the prev_evs is the only variable working towards the attitudes differences

** ANOVAs:

** ANOVA without Interaction Terms:
anova attitude_reduce_ghge_fix ib1.prev_evs c.age##c.age i.edu_level hi i.gender c.people_household c.vehicles_household c.trips_over200miles12 c.longest_trip12 c.annual_vmt_est i.year

** ANOVA with Interaction Terms: Age
anova attitude_reduce_ghge_fix ib1.prev_evs##c.age##c.age i.edu_level hi i.gender c.people_household c.vehicles_household c.trips_over200miles12 c.longest_trip12 c.annual_vmt_est i.year

** ANOVA with Interaction Terms: Household Income
anova attitude_reduce_ghge_fix ib1.prev_evs##c.hi c.age##c.age i.edu_level i.gender c.people_household c.vehicles_household c.trips_over200miles12 c.longest_trip12 c.annual_vmt_est i.year

** ANOVA with Interaction Terms: Education Level
anova attitude_reduce_ghge_fix ib1.prev_evs##i.edu_level c.age##c.age hi i.gender c.people_household c.vehicles_household c.trips_over200miles12 c.longest_trip12 c.annual_vmt_est i.year

** ANOVA with Interaction Terms: Gender
anova attitude_reduce_ghge_fix ib1.prev_evs##i.gender c.age##c.age hi i.edu_level c.people_household c.vehicles_household c.trips_over200miles12 c.longest_trip12 c.annual_vmt_est i.year

** ANOVA with Interaction Terms: Vehicles
anova attitude_reduce_ghge_fix ib1.prev_evs##c.vehicles_household c.age##c.age hi i.edu_level i.gender c.people_household c.trips_over200miles12 c.longest_trip12 c.annual_vmt_est i.year

** ANOVA with Interaction Terms: Trips>200
anova attitude_reduce_ghge_fix ib1.prev_evs##c.trips_over200miles12 c.age##c.age i.edu_level hi i.gender c.people_household c.vehicles_household c.longest_trip12 c.annual_vmt_est i.year

**** Generate a scientific journal table of the results of my ANOVA with Interaction Terms
**** NOTE: I manually do it in Excel.

* Plots:

**** Marginal effect of age in determining being in the Extremely Important (3) group
oprobit attitude_reduce_ghge_fix ib1.prev_evs c.age##c.age i.edu_level hi i.gender c.people_household c.vehicles_household c.trips_over200miles12 c.longest_trip12 c.annual_vmt_est i.year, vce(robust)
margins, dydx(age) predict(pr outcome(3))
margins, at(age=(20(10)90)) predict(pr outcome(3))
marginsplot, ytitle("Probability") title("Predicted probability by age of being in" `newline' "the group of new adopters of EVs that consider" `newline' "reducing GHG emissions as 'extremely important'") plotopts(lcolor(green) mcolor(green)) ciopts(lcolor(green)) yscale(range(0 .))

**** Save the graph as a high-resolution TIFF (600 DPI)
graph export "figure_3.tif", as(tif) replace width(2126) height(1600)

**** THE INFLECTION POINT IS AROUND 72 YEARS OLD
oprobit attitude_reduce_ghge_fix ib1.prev_evs##c.age##c.age i.edu_level hi i.gender c.people_household c.vehicles_household c.trips_over200miles12 c.longest_trip12 c.annual_vmt_est i.year, vce(robust)
nlcom -_b[age]/(2*_b[c.age#c.age])

**** Marginal effect of prev_evs#vehicles_household in determining being in the Extremely Important (3) group
* I THINK HERE IT WILL BE COOL TO PLOT THEM TOGETHER TO SEE THE DIFFERENCE IN THE GROUP PREV_EVS=0 and PREV_EVS=1
oprobit attitude_reduce_ghge_fix ib1.prev_evs c.age##c.age i.edu_level hi i.gender c.people_household c.vehicles_household c.trips_over200miles12 c.longest_trip12 c.annual_vmt_est i.year, vce(robust)
margins, at(vehicles_household=(1(1)6)) predict(pr outcome(3))
marginsplot, ytitle("Probability") title("Predicted probability by number of vehicles of being in" `newline' "the group of new adopters of EVs that consider reducing" `newline' "GHG emissions as 'extremely important'") plotopts(lcolor(green) mcolor(green)) ciopts(lcolor(green)) yscale(range(0 .)) ylabel(0(0.2).65)

**** Save the graph as a high-resolution TIFF (600 DPI)
graph export "figure_4.tif", as(tif) replace width(2126) height(1600)

**** Marginal effect of age in determining being in the Extremely Important (3) and Not at all important (-3) group
oprobit attitude_reduce_ghge_fix ib1.prev_evs c.age##c.age i.edu_level hi i.gender c.people_household c.vehicles_household c.trips_over200miles12 c.longest_trip12 c.annual_vmt_est i.year, vce(robust)
margins, at(age=(20(10)90)) predict(pr outcome(-3))
marginsplot, ytitle("Probability") ///
    title("Not at all important") ///
    plotopts(lcolor(red) mcolor(red)) ///
    ciopts(fcolor(red%30) lcolor(red)) ///
    yscale(range(0 .)) ///
    name(plot_outcome_neg3, replace)
margins, at(age=(20(10)90)) predict(pr outcome(3))
marginsplot, ytitle("Probability") ///
    title("Extremely important") ///
    plotopts(lcolor(green) mcolor(green)) ///
    ciopts(fcolor(green%30) lcolor(green)) ///
    yscale(range(0 .)) ///
    name(plot_outcome_pos3, replace)
graph combine plot_outcome_neg3 plot_outcome_pos3, ///
    title("Predicted probability by age of being in the group of new adopters of EVs that consider reducing GHG emissions as:") ///
    ycommon
**** Save the graph as a high-resolution TIFF (600 DPI)
graph export "figure_A1.tif", as(tif) replace width(4488) height(1600)


**** Marginal effect of vehicles in determining being in the Extremely Important (3) and Not at all important (-3) group
oprobit attitude_reduce_ghge_fix ib1.prev_evs c.age##c.age i.edu_level hi i.gender c.people_household c.vehicles_household c.trips_over200miles12 c.longest_trip12 c.annual_vmt_est i.year, vce(robust)
margins, at(vehicles_household=(1(1)6)) predict(pr outcome(-3))
marginsplot, ytitle("Probability") ///
    title("Not at all important") ///
    plotopts(lcolor(red) mcolor(red)) ///
    ciopts(fcolor(red%30) lcolor(red)) ///
    yscale(range(0 .)) ///
    name(plot_outcome_neg3, replace)
margins, at(vehicles_household=(1(1)6)) predict(pr outcome(3))
marginsplot, ytitle("Probability") ///
    title("Extremely important") ///
    plotopts(lcolor(green) mcolor(green)) ///
    ciopts(fcolor(green%30) lcolor(green)) ///
    yscale(range(0 .)) ///
    name(plot_outcome_pos3, replace)
graph combine plot_outcome_neg3 plot_outcome_pos3, ///
    title("Predicted probability by number of vehicles of being in the group of new adopters of EVs that consider reducing GHG emissions as:") ///
    ycommon
**** Save the graph as a high-resolution TIFF (600 DPI)
graph export "figure_A2.tif", as(tif) replace width(4488) height(1600)


*** Driving behaviour with Coefficients: LTrip

* Regression Model with Robust:
reg longest_trip12 ib1.prev_evs i.older_than_50 c.hi i.gender vehicles_household people_household c.trips_over200miles12 c.annual_vmt_est i.edu_level i.year, vce(robust)
est store driving_co

* Regression Model with Interaction Term: Age>50
reg longest_trip12 ib1.prev_ev##i.older_than_50 c.hi i.gender vehicles_household people_household c.trips_over200miles12 c.annual_vmt_est i.edu_level i.year, vce(robust)
est store driving_co_prev_older50

* Regression Model with Interaction Term: Household Income
reg longest_trip12 ib1.prev_ev##c.hi i.older_than_50 i.gender vehicles_household people_household c.trips_over200miles12 c.annual_vmt_est i.edu_level i.year, vce(robust)
est store driving_co_prev_hi

* Regression Model with Interaction Term: Gender
reg longest_trip12 ib1.prev_evs##i.gender i.older_than_50 c.hi vehicles_household people_household c.trips_over200miles12 c.annual_vmt_est i.edu_level i.year, vce(robust)
est store driving_co_prev_gend
************GENDER NOT SIGNIFICANT ALONE

* Regression Model with Interaction Term: Education Level
reg longest_trip12 ib1.prev_evs##i.edu_level i.older_than_50 c.hi i.gender vehicles_household people_household c.trips_over200miles12 c.annual_vmt_est i.year, vce(robust)
est store driving_co_prev_edu
************EDUCATIONAL LEVEL NOT SIGNIFICANT ALONE

* Regression Model with Interaction Term: Vehicles
reg longest_trip12 ib1.prev_evs##c.vehicles_household i.older_than_50 i.gender c.hi people_household c.trips_over200miles12 c.annual_vmt_est i.edu_level i.year, vce(robust)
est store driving_co_prev_veh

* Regression Model with Interaction Term: Trips>200
reg longest_trip12 ib1.prev_evs##c.trips_over200miles12 i.older_than_50 i.gender c.hi vehicles_household people_household c.annual_vmt_est i.edu_level i.year, vce(robust)
est store driving_co_prev_trip200

*NOTE: In our analysis we found mild evidence (only p<0.1) to support the claim of the researchers about an increased in the quantity of driving.

* (OPTIONAL) Generate a scientific journal table of the results of my Linear Regressions with different interaction terms

*esttab driving_co driving_co_prev_older50 driving_co_prev_hi driving_co_prev_gend driving_co_prev_edu driving_co_prev_veh driving_co_prev_trip200 using Table3.rtf, replace se r2 ar2 star(* 0.10 ** 0.05 *** 0.01) b(%5.3f) no gap


*** Driving behaviour with Coefficients: Log Annual VMT

* Regression Model with Robust:
reg log_annual_vmt_est ib1.prev_evs i.older_than_50 c.hi i.gender vehicles_household people_household c.trips_over200miles12 longest_trip12 i.edu_level i.year, vce(robust)
est store driving2_co

* Regression Model with Interaction Term: Age>50
reg log_annual_vmt_est ib1.prev_evs##i.older_than_50 c.hi i.gender vehicles_household people_household c.trips_over200miles12 longest_trip12 i.edu_level i.year, vce(robust)
est store driving2_co_prev_older50

* Regression Model with Interaction Term: Household Income
reg log_annual_vmt_est ib1.prev_evs##c.hi i.older_than_50 i.gender vehicles_household people_household c.trips_over200miles12 longest_trip12 i.edu_level i.year, vce(robust)
est store driving2_co_prev_hi

* Regression Model with Interaction Term: Gender
reg log_annual_vmt_est ib1.prev_evs##i.gender i.older_than_50 c.hi vehicles_household people_household c.trips_over200miles12 longest_trip12 i.edu_level i.year, vce(robust)
est store driving2_co_prev_gend

* Regression Model with Interaction Term: People
reg log_annual_vmt_est ib1.prev_evs##c.people_household i.older_than_50 c.hi i.gender vehicles_household c.trips_over200miles12 longest_trip12 i.edu_level i.year, vce(robust)
est store driving2_co_prev_people

* Regression Model with Interaction Term: Trips>200
reg log_annual_vmt_est ib1.prev_evs##c.trips_over200miles12 i.older_than_50 c.hi i.gender vehicles_household people_household longest_trip12 i.edu_level i.year, vce(robust)
est store driving2_co_prev_trip200

* Regression Model with Interaction Term: LTrip
reg log_annual_vmt_est ib1.prev_evs##c.longest_trip12 i.older_than_50 c.hi i.gender vehicles_household people_household c.trips_over200miles12 i.edu_level i.year, vce(robust)
est store driving2_co_prev_longtrip

* Regression Model with Interaction Term: Education Level
reg log_annual_vmt_est ib1.prev_evs##i.edu_level i.older_than_50 i.gender c.hi vehicles_household people_household c.trips_over200miles12 longest_trip12 i.year, vce(robust)
est store driving2_co_prev_edu

*NOTE: In our analysis we couldn't find evidence to support the claim of the researchers about an increased in the quantity of driving with Log Annual VMT.

* (OPTIONAL) Generate a scientific journal table of the results of my Linear Regressions with different interaction terms

*esttab driving2_co driving2_co_prev_older50 driving2_co_prev_hi driving2_co_prev_gend driving2_co_prev_people driving2_co_prev_trip200 driving2_co_prev_longtrip driving2_co_prev_edu using Table4.rtf, replace se r2 ar2 star(* 0.10 ** 0.05 *** 0.01) b(%5.3f) no gap


**** TO GET THE DATASET USED IN THE REGRESSION FOR MY KDE PLOTS IN PYTHON:

// Run the regression
oprobit attitude_reduce_ghge_fix ib1.prev_evs c.age##c.age i.edu_level hi i.gender c.people_household c.vehicles_household c.trips_over200miles12 c.longest_trip12 c.annual_vmt_est i.year, vce(robust)

// Create a binary variable indicating whether an observation was used
gen used_in_oprobitregression = e(sample)

// Keep only the observations used in the regression
keep if used_in_oprobitregression == 1

// Save the subset to a new file
save used_in_oprobitregression_data.dta, replace

// Export the subset to a CSV file
export delimited used_in_oprobitregression_data.csv, replace

*ENJOY :)