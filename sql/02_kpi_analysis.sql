-- ======================================================================
-- 02_kpi_analysis.sql
-- Project : Lumut Home marketing performance review
-- Purpose : first KPI view of paid media performance, by channel and currency
-- Author  : Blessing Ajibokun
-- Database: MySQL 8. Tables created by 01_setup_and_types.sql.
-- Results : each query is followed by its output (also exported to sql/results/).
-- ======================================================================
USE lumut;

-- ----------------------------------------------------------------------
-- B1. Row counts (expected 111 / 72,935 / 47,385 / 30,142 / 22)
-- ----------------------------------------------------------------------

SELECT 'campaigns' AS table_name, COUNT(*) AS row_count FROM campaigns
UNION ALL SELECT 'ads',       COUNT(*) FROM ads
UNION ALL SELECT 'orders',    COUNT(*) FROM orders
UNION ALL SELECT 'customers', COUNT(*) FROM customers
UNION ALL SELECT 'fx',        COUNT(*) FROM fx;
-- Result (run on the cleaned data):
-- table_name  row_count
--  campaigns        111
--        ads      72935
--     orders      47385
--  customers      30142
--         fx         22

-- ----------------------------------------------------------------------
-- B2. Ad rows per channel (ads has no channel column, so join to campaigns)
-- ----------------------------------------------------------------------
SELECT c.channel,
       COUNT(*) AS ad_rows
FROM ads AS a
JOIN campaigns AS c ON a.campaign_id = c.campaign_id
GROUP BY c.channel
ORDER BY ad_rows DESC;
-- Result (run on the cleaned data):
--     channel  ad_rows
-- Paid Search    28549
-- Paid Social    18184
--    Shopping    14099
--     Display     6238
--       Video     3185
--       Email     2680

-- ----------------------------------------------------------------------
-- C1. Totals by channel and currency (GBP and USD are never added together)
-- ----------------------------------------------------------------------
-- spend_clean is used instead of spend. Conversions are platform-reported.
SELECT c.channel,
       a.currency,
       SUM(a.impressions)      AS impressions,
       SUM(a.clicks)           AS clicks,
       ROUND(SUM(a.spend_clean), 2)       AS spend,
       ROUND(SUM(a.conversions), 2)       AS conversions,
       ROUND(SUM(a.conversion_value), 2)  AS conversion_value
FROM ads AS a
JOIN campaigns AS c ON a.campaign_id = c.campaign_id
GROUP BY c.channel, a.currency
ORDER BY c.channel, a.currency;
-- Result (run on the cleaned data):
--     channel currency  impressions   clicks     spend  conversions  conversion_value
--     Display      GBP   68945881.0 544024.0  83426.79      1301.26          81748.62
--     Display      USD   21451999.0 133040.0  37824.00       666.46          56065.66
--       Email      GBP    3877727.0 121572.0   3793.54      2399.00         150779.21
--       Email      USD     893567.0  35792.0   2092.66       626.00          52331.95
-- Paid Search      GBP    2798385.0 144666.0 101875.61      6595.42         415453.08
-- Paid Search      USD    9097254.0 451090.0 508454.82     19324.09        1619529.25
-- Paid Social      GBP   28715800.0 367631.0 198367.70      6510.00         407015.47
-- Paid Social      USD   34031911.0 432141.0 229546.43      3909.00         331239.05
--    Shopping      GBP   29343822.0 451830.0 263300.78     10586.86         667544.36
--    Shopping      USD   14273392.0 252733.0 131666.04      7017.39         591247.54
--       Video      GBP   17147315.0  75985.0  14889.94       182.26          11280.20
--       Video      USD   14407689.0  84306.0  24543.57       150.87          12576.27

-- ----------------------------------------------------------------------
-- C2. KPIs by channel and currency
-- ----------------------------------------------------------------------
-- Each KPI = SUM(numerator) / SUM(denominator), never an average of row-level ratios.
--   * CTR / CVR / CPC ignore rows where clicks exceed impressions (impossible rows).
--   * CPC / CPA / ROAS only use rows where spend is known, so blank-spend rows do not
--     inflate the denominator (clicks or conversions with no cost attached).
--   * ROAS also needs conversion_value to be known on the same row.
--   * NULLIF(x, 0) turns a zero denominator into NULL instead of a divide-by-zero error.
--   * spend_clean is used (decimal-shift errors corrected, blanks left NULL).
--   * Conversions and conversion_value are what the PLATFORMS claim. They have not been
--     reconciled to orders.csv yet, and GBP / USD are not converted (grouped separately).
SELECT channel,
       currency,
       ROUND(SUM(spend_all), 2)                                   AS spend,
       ROUND(SUM(clk_v)   / NULLIF(SUM(imp_v), 0), 4)             AS ctr,
       ROUND(SUM(spd_v)   / NULLIF(SUM(clk_spd_v), 0), 3)         AS cpc,
       ROUND(SUM(conv_v)  / NULLIF(SUM(clk_v), 0), 4)             AS cvr,
       ROUND(SUM(spd_known) / NULLIF(SUM(conv_spd), 0), 2)        AS cpa,
       ROUND(SUM(cv_both) / NULLIF(SUM(spd_both), 0), 2)          AS roas
FROM (
    SELECT c.channel,
           a.currency,
           a.spend_clean AS spend_all,
           CASE WHEN a.clicks_exceed_impressions = 'False' THEN a.impressions END  AS imp_v,
           CASE WHEN a.clicks_exceed_impressions = 'False' THEN a.clicks END       AS clk_v,
           CASE WHEN a.clicks_exceed_impressions = 'False' THEN a.conversions END  AS conv_v,
           CASE WHEN a.clicks_exceed_impressions = 'False' AND a.spend_clean IS NOT NULL
                THEN a.spend_clean END AS spd_v,
           CASE WHEN a.clicks_exceed_impressions = 'False' AND a.spend_clean IS NOT NULL
                THEN a.clicks END      AS clk_spd_v,
           CASE WHEN a.spend_clean IS NOT NULL THEN a.spend_clean END   AS spd_known,
           CASE WHEN a.spend_clean IS NOT NULL THEN a.conversions END   AS conv_spd,
           CASE WHEN a.spend_clean IS NOT NULL AND a.conversion_value IS NOT NULL
                THEN a.conversion_value END AS cv_both,
           CASE WHEN a.spend_clean IS NOT NULL AND a.conversion_value IS NOT NULL
                THEN a.spend_clean END      AS spd_both
    FROM ads AS a
    JOIN campaigns AS c ON a.campaign_id = c.campaign_id
) AS x
GROUP BY channel, currency
ORDER BY channel, currency;
-- Result (run on the cleaned data):
--     channel currency     spend    ctr   cpc    cvr    cpa  roas
--     Display      GBP  83426.79 0.0044 0.276 0.0043  64.28  0.98
--     Display      USD  37824.00 0.0043 0.409 0.0072  57.03  1.48
--       Email      GBP   3793.54 0.0295 0.033 0.0209   1.59 39.62
--       Email      USD   2092.66 0.0401 0.059 0.0175   3.36 24.90
-- Paid Search      GBP 101875.61 0.0511 0.716 0.0461  15.53  4.06
-- Paid Search      USD 508454.82 0.0480 1.172 0.0443  26.44  3.18
-- Paid Social      GBP 198367.70 0.0112 0.618 0.0202  30.57  2.05
-- Paid Social      USD 229546.43 0.0096 0.708 0.0120  58.92  1.44
--    Shopping      GBP 263300.78 0.0138 0.651 0.0261  25.00  2.53
--    Shopping      USD 131666.04 0.0155 0.598 0.0317  18.85  4.48
--       Video      GBP  14889.94 0.0031 0.278 0.0034  82.24  0.76
--       Video      USD  24543.57 0.0033 0.521 0.0031 162.68  0.51
