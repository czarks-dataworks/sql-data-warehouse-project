/*
===============================================================================
Quality Checks
===============================================================================
Script Purpose:
    This script performs quality checks for data consistency, accuracy,
    and standardization across the 'silver' layer. It includes checks for:
    - Null or duplicate primary keys.
    - Unwanted spaces in string fields.
    - Data standardization and consistency.
    - Invalid date ranges and orders.
    - Data consistency between related fields.

Usage Notes:
    - Run these checks after loading data to the Silver Layer.
    - Investigate and resolve any discrepancies found during the checks.
===============================================================================
*/

-- ====================================================================
-- Checking 'silver.crm_cust_info' (Table 1 of 6)
-- ====================================================================

-- Check for Nulls or Duplicates in the Primary Key
-- Expectation: No Result
SELECT 
cst_id,
COUNT (*) PK_Count
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT (*) > 1 OR cst_id IS NULL;

-- Check for unwanted spaces (both at the start and the end of the word)
-- Expectation: No results
SELECT cst_key
FROM silver.crm_cust_info
WHERE cst_key != TRIM(cst_key);

SELECT cst_firstname
FROM silver.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname)

-- Data Standardization & Consistency
SELECT DISTINCT cst_gndr
FROM silver.crm_cust_info;

SELECT DISTINCT cst_marital_status
FROM silver.crm_cust_info

-- ====================================================================
-- Checking 'silver.crm_prd_info' (Table 2 of 6)
-- ====================================================================

-- Check for Nulls or Duplicates in Primary Key
-- Expectation: No Result
SELECT
prd_id,
COUNT (*) PK_Count
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT (*) > 1 OR prd_id IS NULL

-- Check for unwanted spaces
-- Expectation: No results
SELECT prd_key
FROM silver.crm_prd_info
WHERE TRIM(prd_key) != prd_key;

SELECT prd_nm
FROM silver.crm_prd_info
WHERE TRIM(prd_nm) != prd_nm

-- Check for NULLS or Negative Numbers
-- Expectation: No Reults
SELECT prd_cost
FROM silver.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL

-- Data Standardization & consistency
SELECT DISTINCT prd_line
FROM silver.crm_prd_info

-- Check for invalid date orders
SELECT
*
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt;

-- Final check
SELECT
*
FROM silver.crm_prd_info
ORDER BY prd_id ASC

-- ====================================================================
-- Checking 'silver.crm_sales_details' (Table 3 of 6)
-- ====================================================================

-- Check for unwanted spaces
-- Expectation: No results
SELECT *
FROM silver.crm_sales_details
WHERE sls_ord_num != TRIM(sls_ord_num);

-- Check if all product keys in the sales_details details are in the product keys in the prd_info silver table
-- Expectation: No results
SELECT *
FROM silver.crm_sales_details
WHERE sls_prd_key NOT IN (SELECT prd_key FROM silver.crm_prd_info)

-- Check integrity of the customer ID in sales details (compare with cust id in cust_info silver table)
-- Expectation: No results
SELECT *
FROM silver.crm_sales_details
WHERE sls_cust_id NOT IN (SELECT cst_id FROM silver.crm_cust_info)

-- Check for invalid dates.
-- Expectation: No results

-- 1. Negative number and zeroes cannot be cast to date
-- 2. There has to be eight digits for it to be cast into date format.
-- 3.Check for outliers

SELECT
	NULLIF(sls_order_dt, 0) sls_order_dt,
	sls_ship_dt,
	sls_due_dt
FROM silver.crm_sales_details
WHERE sls_order_dt <= 0
OR LEN(sls_order_dt) != 8 
OR sls_order_dt > 20261104
OR sls_order_dt < 19000101;

SELECT
	sls_ship_dt
FROM silver.crm_sales_details
WHERE sls_ship_dt <= 0
OR LEN(sls_ship_dt) != 8 
OR sls_ship_dt > 20261104
OR sls_ship_dt < 19000101;

SELECT
	sls_due_dt
FROM silver.crm_sales_details
WHERE sls_due_dt <= 0
OR LEN(sls_due_dt) != 8 
OR sls_due_dt > 20261104
OR sls_due_dt < 19000101;

-- Check Data Consistency: Between Sales, Quantity, and Price
-- >> Sales = Quantty * Price
-- >> Values must not be NULL, zero, or negative.

SELECT DISTINCT
sls_sales,
sls_quantity,
sls_price
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0
ORDER BY sls_sales, sls_quantity, sls_price

-- Final check
SELECT *
FROM silver.crm_sales_details

-- ====================================================================
-- Checking 'silver.erp_cust_az12' (Table 4 of 6)
-- ====================================================================

-- Identify Out-of-Range Dates
-- Expectation: Birthdates between 1924-01-01 and Today

SELECT DISTINCT
bdate
FROM silver.erp_cust_az12
WHERE bdate < '1924-01-01' OR bdate > GETDATE()

-- Data Standardization & Consistency

SELECT DISTINCT
gen
FROM silver.erp_cust_az12

-- ====================================================================
-- Checking 'silver.erp_loc_a101' (Table 5 of 6)
-- ====================================================================

-- Check primary key: If no duplicates
-- Expectation: No results
SELECT
cid,
COUNT(*) AS count_ck
FROM silver.erp_loc_a101
GROUP BY cid
HAVING COUNT(*) != 1;

-- Check primary key: If same length
-- Expectation: No results
SELECT
LEN(cid) AS length_ck,
cid
FROM silver.erp_loc_a101
WHERE LEN(cid) != 10

-- Data Standardization & Consistency
SELECT DISTINCT
cntry AS old_cntry,
CASE
	WHEN TRIM(cntry) = 'DE' THEN 'Germany'
	WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
	WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
	ELSE TRIM(cntry)
END AS cntry
FROM silver.erp_loc_a101

-- Final check
SELECT *
FROM silver.erp_loc_a101

-- ====================================================================
-- Checking 'silver.erp_px_cat_g1v2' (Table 6 of 6)
-- ====================================================================

-- Primary Key: Check if match with cat_id in crm_prd_info
-- Expectation: No results
SELECT
id
FROM silver.erp_px_cat_g1v2
WHERE id NOT IN (SELECT cat_id FROM silver.crm_prd_info);

-- Check columns cat, subcat, and maintenance for unwanted spaces 
-- Data Standardization & Consistency
-- Expectation: No results

SELECT DISTINCT
cat
FROM silver.erp_px_cat_g1v2
WHERE TRIM(cat) != cat

SELECT DISTINCT
subcat
FROM silver.erp_px_cat_g1v2
WHERE TRIM(subcat) != subcat

SELECT DISTINCT
maintenance
FROM silver.erp_px_cat_g1v2
WHERE TRIM(maintenance) != maintenance

-- Final check:
SELECT *
FROM silver.erp_px_cat_g1v2
