# MoralLicensing-EV

This repository contains the full step-by-step guide to replicate the data preparation, analysis, and visualization process described in `When Green Choices Backfire: Evidence of Moral Licensing and Increased Driving in EV Adoption`. It covers operations in **Google Sheets**, **Stata**, and **Python**, including regression modeling and KDE plot generation.

---

**NOTE:** An Excel version where the Steps 1-3 can be seen is in the file `Reproduce MoralLicensing-EV.xlsx` so you can jump this steps and go directly to step 4 to run the `.do` file. 

## Step 1: Filter dataset to include only Battery Electric Vehicles (BEVs) and valid GHG attitude responses

1. **Open the raw data** from the Excel file `FCV&EVMT+Data_6.18.19.xlxs` into a **new sheet** named:
   ```
   Raw_Data
   ```
2. **Open a new sheet**:

    **Goal:** Keep only Battery Electric Vehicle (BEV) respondents (`"FCV, BEV Dummy" = 1`) and those who answered the question on GHG reduction importance.

3. **Write** the following formula in the first cell A1:

### Google Sheets
```excel
=QUERY('Raw_Data'!A1:Y27022, "SELECT * WHERE Y = '1' AND M IS NOT NULL", 1)
```
- `Y` = `"FCV, BEV Dummy"` <---- NOTE THAT THIS IS A TEXT STRING
- `M` = `"Importance of reducing greenhouse gas emissions (-3 not important, 3 important)"`

### SQL Equivalent
```sql
SELECT *
FROM raw_data
WHERE "FCV, BEV Dummy" = 1
  AND "Importance of reducing greenhouse gas emissions (-3 not important, 3 important)" IS NOT NULL;
```

---

## Step 2: Prepare the dataset by copying, cleaning, and renaming columns

1. **Copy and paste only the values from the filtered data with `Ctrl+Shift+V`** from Step 1 into a **new sheet** named:
   ```
   BEVs_with_attitudes_California
   ```

2. **Delete the column**:
   - `"FCV, BEV Dummy"` — no longer needed after filtering

3. **Rename all columns** for easier coding.  
   **IMPORTANT!** *All names must match exactly for Stata and Python scripts to work properly.*

| Old Column Name                                                                  | New Variable Name            |
|----------------------------------------------------------------------------------|------------------------------|
| Response ID                                                                      | `id`                         |
| Date submitted                                                                   | `sub_date`                   |
| Month Year[submitdate]                                                           | `month_year`                 |
| Month[Month Year[submitdate]]                                                    | `month`                      |
| Year[Month Year[submitdate]]                                                     | `year`                       |
| Last page                                                                        | `lastpage`                   |
| Carmain                                                                          | `carmain`                    |
| Previous PHEVs                                                                   | `prev_PHEVs`                 |
| Previous BEVs                                                                    | `prev_BEVs`                  |
| Previous HEVs                                                                    | `prev_HEVs`                  |
| Previous CNGs                                                                    | `prev_CNGs`                  |
| Household Income                                                                 | `HI`                         |
| Importance of reducing greenhouse gas emissions (-3 not important, 3 important)  | `attitude_reduce_GHGE`       |
| Home ownership (own 1)                                                           | `home_ownership`             |
| Home Type (detached 1)                                                           | `detached_home`              |
| Highest Level of Education                                                       | `edu_level`                  |
| Longest trip in the last 12 months                                               | `longest_trip12`             |
| Number of trips over 200 miles in the last 12 months                             | `trips_over200miles12`       |
| One-way commute distance                                                         | `one-way_commute_distance`   |
| Number of people in the household                                                | `people_household`           |
| Age                                                                              | `age`                        |
| Gender (Male 1)                                                                  | `gender`                     |
| Number of vehicles in the household                                              | `vehicles_household`         |
| Annual VMT Estimate                                                              | `annual_VMT_Est`            |

---

## Step 3: Create key derived variables

### A. Previous EV Ownership (`prev_EVs`)

**Definition:** A binary indicator for whether the respondent previously owned any EV (PHEV, HEV, or BEV).

1. **Insert a new column** left to column `prev_PHEVs`. Call the new variable `prev_EVs`. This means that `prev_EVs` is now _column H_. **Please ensure you follow the same steps otherwise the formulas won't work**.

2. **Write** the following formula and **drag down** to capture all the rows.

### Google Sheets:
```excel
IF(OR(I2<>"", J2<>"", K2<>""), IF(SUM(I2:K2)>0, 1, 0), "")
```

### SQL:
```sql
SELECT *,
  CASE
    WHEN prev_PHEVs IS NOT NULL OR prev_HEVs IS NOT NULL OR prev_BEVs IS NOT NULL THEN
      CASE
        WHEN COALESCE(prev_PHEVs, 0) + COALESCE(prev_HEVs, 0) + COALESCE(prev_BEVs, 0) > 0 THEN 1
        ELSE 0
      END
    ELSE NULL
  END AS prev_EVs
FROM raw_data;
```

---

### B. Round GHG Attitude to Integers (`attitude_reduce_GHGE_fix`)

**Purpose:** For ordered probit modeling, we need to round the attitude score to integers.

1. **Insert a new column** right to column `attitude_reduce_GHGE`. Call the new variable `attitude_reduce_GHGE_fix`. This means that `attitude_reduce_GHGE_fix` is now _column O_. **Please ensure you follow the same steps otherwise the formulas won't work**.

2. **Write** the following formula and **drag down** to capture all the rows.

### Google Sheets:
```excel
=ROUND(N2)
```

### SQL:
```sql
SELECT *,
  ROUND(attitude_reduce_GHGE) AS attitude_reduce_GHGE_fix
FROM raw_data;
```

---

## Step 4: Download dataset for analysis

1. Go to the `BEVs_with_attitudes_California` sheet
2. Click `File → Download → CSV (.csv, current sheet)`
3. Save the file as:
   ```
   BEVs_with_attitudes_California.csv
   ```
**NOTE:** An Excel version where the Steps 1-3 can be seen is in the file `Reproduce MoralLicensing-EV.xlsx` and also a final version of the `BEVs_with_attitudes_California.csv` 

4. Open the Stata `.do` file provided in the repository called `New_BEVs_moral_licensing_reproduce.do`
5. Replace the initial lines of the code (see below) with the file path to your cloned repository or the location you stored the `BEVs_with_attitudes_California.csv`:
```stata
* Set the working directory and import the csv file:
* MAKE SURE TO USE THE CLONED REPOSITORY FOLDER (YOU CAN ALWAYS CHANGE THE PATH)
* Example:
cd "C:\Documents\MoralLicensing-EV"
 
import delimited "BEVs_with_attitudes_California.csv"
```

6. Once you have defined the working directory and imported the csv file, **run the `.do` file to produce:**
   - Ordered probit regressions
   - OLS regressions
   - ANOVAs
   - Robustness checks (interaction terms)
   - Figures 3, 4, A1, and A2
   - The dataset for creating figure 1 and 2 on Python (see Step 5)

---

## Step 5: Export regression dataset for KDE plots in Python

At the end of the Stata `.do` file you will see the following lines that create a csv file called `used_in_oprobitregression_data.csv` that you will need to create figure 1 and 2 on Python:

```stata
// Run the regression
oprobit attitude_reduce_ghge_fix ib1.prev_evs c.age##c.age i.edu_level hi i.gender ///
       c.people_household c.vehicles_household c.trips_over200miles12 ///
       c.longest_trip12 c.annual_vmt_est i.year, vce(robust)

// Tag observations used in regression
gen used_in_oprobitregression = e(sample)
keep if used_in_oprobitregression == 1

// Export the regression dataset
export delimited used_in_oprobitregression_data.csv, replace
```

---

### KDE Plotting in Python

To generate **Figure 1** and **Figure 2**, open the Jupyter Notebook:

```
KDE_Plots.ipynb
```

Ensure the following Python libraries are installed:
```
- python------------version: 3.11.9
- pandas------------version: 2.2.3
- seaborn-----------version: 0.13.2
- matplotlib--------version: 3.8.2
- os
```

The notebook contains all code to generate the plots from the exported CSV file.

---

## Repository Structure

```
├── README.md                                   # This file with step by step guide for replication
├── FCV&EVMT+Data_6.18.19.xlsx                  # Original raw data
├── Reproduce MoralLicensing-EV.xlsx            # Excel file of the reproduction of steps 1-3
├── BEVs_with_attitudes_California.csv          # Cleaned dataset for analysis in Stata
├── New_BEVs_moral_licensing_reproduce.do       # Stata script for regressions and figures
├── used_in_oprobitregression_data.dta          # Subset for KDE plotting in dta format
├── used_in_oprobitregression_data.csv          # Subset for KDE plotting in csv format
├── KDE_Plots.ipynb                             # Jupyter notebook for KDE plots
```

---

## Notes

- All variable names must match **exactly** to avoid errors in Stata and Python.
- Change file paths in the Stata and Python code to match your system.
- This workflow is fully reproducible from raw data to final figures.