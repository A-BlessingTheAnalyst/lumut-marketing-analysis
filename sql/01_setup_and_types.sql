-- ======================================================================
-- 01_setup_and_types.sql
-- Project : Lumora Home marketing performance review
-- Purpose : set correct data types on the five tables imported from data_clean/
--           and verify the import (row counts, NULLs, date ranges)
-- Author  : [Your Name]
-- Database: MySQL 8 (MySQL Workbench)
-- Before running: import the CSVs from data_clean/ with the Table Data Import Wizard as
--   campaigns_clean.csv -> campaigns          ad_performance_daily_clean.csv -> ads
--   orders_clean.csv    -> orders             customers_clean.csv            -> customers
--   fx_rates_monthly_clean.csv -> fx
-- Run section by section, top to bottom.
-- ======================================================================
CREATE DATABASE IF NOT EXISTS lumora;
USE lumora;

-- ----------------------------------------------------------------------
-- STEP 0. Diagnostic: short code columns should hold exactly 2 characters ('UK', 'US').
-- A longer length means a hidden character (often a carriage return from Windows line
-- endings) or spaces. Step 2 removes them.
-- ----------------------------------------------------------------------
SELECT market, LENGTH(market) AS len, HEX(market) AS hex_value, COUNT(*) AS n
FROM campaigns
GROUP BY market, LENGTH(market), HEX(market);

-- ----------------------------------------------------------------------
-- STEP 1. Allow bulk updates in this session
-- ----------------------------------------------------------------------
SET SQL_SAFE_UPDATES = 0;

-- ----------------------------------------------------------------------
-- STEP 2. Clean up what the import wizard left behind
-- 2a. Remove hidden carriage returns (CHAR(13)) and stray spaces from short text columns.
--     Windows files end each line with a hidden character that sticks to the LAST column.
-- ----------------------------------------------------------------------
UPDATE campaigns SET market = TRIM(REPLACE(market, CHAR(13), '')),
                     currency = TRIM(REPLACE(currency, CHAR(13), '')),
                     name_duplicated = TRIM(REPLACE(name_duplicated, CHAR(13), ''));
UPDATE ads       SET currency = TRIM(REPLACE(currency, CHAR(13), '')),
                     conversion_value_missing = TRIM(REPLACE(conversion_value_missing, CHAR(13), ''));
UPDATE orders    SET country = TRIM(REPLACE(country, CHAR(13), '')),
                     currency = TRIM(REPLACE(currency, CHAR(13), '')),
                     is_direct = TRIM(REPLACE(is_direct, CHAR(13), ''));
UPDATE customers SET country = TRIM(REPLACE(country, CHAR(13), '')),
                     signup_date_invalid = TRIM(REPLACE(signup_date_invalid, CHAR(13), ''));
UPDATE fx        SET is_estimated = TRIM(REPLACE(is_estimated, CHAR(13), ''));

-- 2b. Turn empty text into real NULLs.
--     CAST(col AS CHAR) = '' is safe on text AND number columns. (A plain  col = ''  on a
--     number column would wrongly match real zeros, because MySQL treats '' as 0.)
UPDATE campaigns SET planned_budget = NULL           WHERE CAST(planned_budget AS CHAR) = '';
UPDATE ads       SET spend = NULL                    WHERE CAST(spend AS CHAR) = '';
UPDATE ads       SET spend_clean = NULL              WHERE CAST(spend_clean AS CHAR) = '';
UPDATE ads       SET conversion_value = NULL         WHERE CAST(conversion_value AS CHAR) = '';
UPDATE orders    SET shipping_cost = NULL            WHERE CAST(shipping_cost AS CHAR) = '';
UPDATE orders    SET customer_id = NULL              WHERE CAST(customer_id AS CHAR) = '';
UPDATE orders    SET first_touch_campaign_id = NULL  WHERE CAST(first_touch_campaign_id AS CHAR) = '';
UPDATE orders    SET last_touch_campaign_id = NULL   WHERE CAST(last_touch_campaign_id AS CHAR) = '';
UPDATE customers SET signup_date = NULL              WHERE CAST(signup_date AS CHAR) = '';
UPDATE customers SET email_hash = NULL               WHERE CAST(email_hash AS CHAR) = '';

-- ----------------------------------------------------------------------
-- STEP 3. Set the data types
-- Short codes use VARCHAR(10) (not CHAR(2)/CHAR(3)) so a stray character cannot cause 1406 again.
-- ----------------------------------------------------------------------
ALTER TABLE campaigns
  MODIFY campaign_id              VARCHAR(10) NOT NULL,
  MODIFY campaign_name            VARCHAR(100),
  MODIFY channel                  VARCHAR(20),
  MODIFY platform                 VARCHAR(30),
  MODIFY campaign_type            VARCHAR(20),
  MODIFY objective                VARCHAR(30),
  MODIFY market                   VARCHAR(10),
  MODIFY start_date               DATE,
  MODIFY end_date                 DATE,
  MODIFY planned_budget           DECIMAL(12,2),
  MODIFY currency                 VARCHAR(10),
  MODIFY status                   VARCHAR(10),
  MODIFY owner_team               VARCHAR(20),
  MODIFY dates_swapped            VARCHAR(10),
  MODIFY budget_missing           VARCHAR(10),
  MODIFY name_follows_convention  VARCHAR(10),
  MODIFY name_duplicated          VARCHAR(10);

ALTER TABLE ads
  MODIFY date                       DATE,
  MODIFY campaign_id                VARCHAR(10) NOT NULL,
  MODIFY ad_group_id                VARCHAR(15),
  MODIFY ad_group_name              VARCHAR(50),
  MODIFY device                     VARCHAR(10),
  MODIFY impressions                BIGINT,
  MODIFY clicks                     BIGINT,
  MODIFY spend                      DECIMAL(12,2),
  MODIFY currency                   VARCHAR(10),
  MODIFY conversions                DECIMAL(10,2),
  MODIFY conversion_value           DECIMAL(12,2),
  MODIFY device_was_blank           VARCHAR(10),
  MODIFY spend_flag                 VARCHAR(20),
  MODIFY spend_clean                DECIMAL(12,2),
  MODIFY clicks_exceed_impressions  VARCHAR(10),
  MODIFY conversion_value_missing   VARCHAR(10);

ALTER TABLE customers
  MODIFY customer_id              VARCHAR(10) NOT NULL,
  MODIFY signup_date              DATE,
  MODIFY country                  VARCHAR(10),
  MODIFY email_hash               VARCHAR(30),
  MODIFY marketing_opt_in         VARCHAR(10),
  MODIFY crm_acquisition_channel  VARCHAR(30),
  MODIFY signup_date_invalid      VARCHAR(10);

ALTER TABLE orders
  MODIFY order_id                 VARCHAR(12) NOT NULL,
  MODIFY customer_id              VARCHAR(10),
  MODIFY order_date               DATE,
  MODIFY country                  VARCHAR(10),
  MODIFY currency                 VARCHAR(10),
  MODIFY product_category         VARCHAR(30),
  MODIFY order_value              DECIMAL(12,2),
  MODIFY discount_amount          DECIMAL(12,2),
  MODIFY shipping_cost            DECIMAL(8,2),
  MODIFY is_refunded              VARCHAR(10),
  MODIFY first_touch_campaign_id  VARCHAR(10),
  MODIFY last_touch_campaign_id   VARCHAR(10),
  MODIFY order_value_flag         VARCHAR(10),
  MODIFY customer_missing         VARCHAR(10),
  MODIFY is_direct                VARCHAR(10);

ALTER TABLE fx
  MODIFY month         DATE NOT NULL,
  MODIFY gbp_to_usd    DECIMAL(8,4),
  MODIFY is_estimated  VARCHAR(10);

-- ----------------------------------------------------------------------
-- STEP 4. Verify (every line has the value you should see)
-- ----------------------------------------------------------------------
SELECT COUNT(*) AS spend_clean_nulls FROM ads       WHERE spend_clean IS NULL;       -- 364
SELECT COUNT(*) AS conv_value_nulls  FROM ads       WHERE conversion_value IS NULL;  -- 219
SELECT COUNT(*) AS shipping_nulls    FROM orders    WHERE shipping_cost IS NULL;     -- 1421
SELECT COUNT(*) AS customer_id_nulls FROM orders    WHERE customer_id IS NULL;       -- 189
SELECT COUNT(*) AS signup_nulls      FROM customers WHERE signup_date IS NULL;       -- 304
SELECT COUNT(*) AS budget_nulls      FROM campaigns WHERE planned_budget IS NULL;    -- 6
SELECT MIN(date) AS first_ad, MAX(date) AS last_ad FROM ads;                         -- 2025-01-01, 2026-10-31
SELECT MIN(order_date) AS first_order, MAX(order_date) AS last_order FROM orders;    -- 2025-01-01, 2026-10-31
SELECT DISTINCT clicks_exceed_impressions FROM ads;                                  -- exactly: False, True (no hidden characters)

-- ----------------------------------------------------------------------
-- OPTIONAL: keys and indexes. Run ONCE only (re-running gives a "duplicate" error you can ignore).
-- ----------------------------------------------------------------------
-- ALTER TABLE campaigns ADD PRIMARY KEY (campaign_id);
-- ALTER TABLE customers ADD PRIMARY KEY (customer_id);
-- ALTER TABLE orders    ADD PRIMARY KEY (order_id);
-- ALTER TABLE fx        ADD PRIMARY KEY (month);
-- CREATE INDEX idx_ads_campaign    ON ads (campaign_id);
-- CREATE INDEX idx_ads_date        ON ads (date);
-- CREATE INDEX idx_orders_customer ON orders (customer_id);
-- CREATE INDEX idx_orders_date     ON orders (order_date);
