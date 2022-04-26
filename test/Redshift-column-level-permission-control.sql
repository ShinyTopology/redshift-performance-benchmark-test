-- 0. Prepare environment
CREATE USER sampleuser1 WITH password 'Abcd1234!';

-- 1. Preview customer table to find out 6 PII columns.

/* Set schema */
set search_path = 'tpcds_3tb';

/* Found 6 PII columns 
	- c_first_name
    - c_last_name
    - c_birth_day
    - c_birth_month
    - c_birth_year
    - c_birth_country
*/
select * from customer limit 10;

-- 2. Grant permission of table customer to sampleuser1 at column level , skipping the PII columns.
/* grant select on customer table */
GRANT ALL ON SCHEMA tpcds_3tb to sampleuser1;
GRANT SELECT (
  c_customer_sk				,
  c_customer_id				,
  c_current_cdemo_sk		,
  c_current_hdemo_sk		,
  c_current_addr_sk			,
  c_first_shipto_date_sk	,
  c_first_sales_date_sk		,
  c_salutation				,
  c_preferred_cust_flag		,
  c_login					,
  c_email_address			,
  c_last_review_date_sk
) ON tpcds_3tb.customer to sampleuser1;


-- 3. Simulate user sampleuser1 and encounter permission denied when selecting the whole table
SET SESSION AUTHORIZATION 'sampleuser1';
SELECT CURRENT_USER;
SELECT * FROM tpcds_3tb.customer limit 10; -- Permission denied

--4. Check permission to find columns with permission. 
/* Check column priviledge*/
SELECT * FROM v_get_col_priv; 

/* Select granted columns from a table. */
SELECT   
  c_customer_sk				,
  c_customer_id				,
  c_current_cdemo_sk		,
  c_current_hdemo_sk		,
  c_current_addr_sk			,
  c_first_shipto_date_sk	,
  c_first_sales_date_sk		,
  c_salutation				,
  c_preferred_cust_flag		,
  c_login					,
  c_email_address			,
  c_last_review_date_sk
FROM customer
limit 100;


-- 5. Reset environment
/* Reset*/
RESET SESSION AUTHORIZATION;
REVOKE SELECT on customer from sampleuser1;