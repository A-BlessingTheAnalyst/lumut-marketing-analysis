-- ======================================================================
-- 03_analysis.sql
-- Project : Lumora Home marketing performance review
-- Purpose : USD-normalised performance, platform-reported vs order-based
--           efficiency, attribution, CAC, pacing and tracking checks.
-- Database: MySQL 8 (run 01_setup_and_types.sql first). Flags are stored as
--           text 'True'/'False' because the CSV import creates text columns.
-- Same logic as notebooks/02_analysis.ipynb; totals are cross-checked there.
-- ======================================================================
USE lumora;

-- ----------------------------------------------------------------------
-- C1. Reusable views: everything in USD, orders tagged with attributed channel
--   * GBP rows are multiplied by that calendar month's average rate (fx table)
--   * spend_clean is used (x100 errors corrected, blanks stay NULL)
--   * Orders: only order_value_flag = 'ok' count; revenue = order_value - discount
-- ----------------------------------------------------------------------
CREATE OR REPLACE VIEW ads_usd AS
SELECT a.date,
       DATE_FORMAT(a.date, '%Y-%m-01')                       AS month_start,
       a.campaign_id, c.channel, c.platform, c.campaign_type, c.market,
       a.device, a.impressions, a.clicks, a.conversions,
       a.spend_clean * CASE WHEN a.currency = 'GBP' THEN f.gbp_to_usd ELSE 1 END       AS spend_usd,
       a.conversion_value * CASE WHEN a.currency = 'GBP' THEN f.gbp_to_usd ELSE 1 END AS platform_rev_usd
FROM ads AS a
JOIN campaigns AS c ON c.campaign_id = a.campaign_id          -- inner join drops quarantined orphan IDs (none remain after cleaning)
JOIN fx AS f        ON f.month = CAST(DATE_FORMAT(a.date, '%Y-%m-01') AS DATE);

CREATE OR REPLACE VIEW orders_usd AS
SELECT o.order_id, o.customer_id, o.order_date,
       CAST(DATE_FORMAT(o.order_date, '%Y-%m-01') AS DATE)   AS month_start,
       (o.order_value - o.discount_amount) * CASE WHEN o.currency = 'GBP' THEN f.gbp_to_usd ELSE 1 END AS net_usd,
       COALESCE(lc.channel,  'Direct / none') AS last_channel,
       COALESCE(lc.platform, 'Direct / none') AS last_platform,
       COALESCE(lc.campaign_type, 'Direct / none') AS last_campaign_type,
       COALESCE(fc.channel,  'Direct / none') AS first_channel,
       o.last_touch_campaign_id, o.first_touch_campaign_id
FROM orders AS o
JOIN fx AS f ON f.month = CAST(DATE_FORMAT(o.order_date, '%Y-%m-01') AS DATE)
LEFT JOIN campaigns AS lc ON lc.campaign_id = o.last_touch_campaign_id   -- NULL last touch = direct
LEFT JOIN campaigns AS fc ON fc.campaign_id = o.first_touch_campaign_id
WHERE o.order_value_flag = 'ok';

-- ----------------------------------------------------------------------
-- C2. Monthly trend in USD
-- ----------------------------------------------------------------------
SELECT s.month_start,
       ROUND(s.spend_usd, 0)                       AS spend_usd,
       ROUND(s.platform_rev_usd / s.spend_usd, 2)  AS platform_roas,
       o.orders,
       ROUND(o.net_usd / s.spend_usd, 2)           AS blended_order_roas,
       ROUND(s.spend_usd / o.orders, 2)            AS cost_per_order
FROM (SELECT month_start, SUM(spend_usd) AS spend_usd, SUM(platform_rev_usd) AS platform_rev_usd
      FROM ads_usd GROUP BY month_start) AS s
JOIN (SELECT month_start, COUNT(*) AS orders, SUM(net_usd) AS net_usd
      FROM orders_usd GROUP BY month_start) AS o
  ON o.month_start = CAST(s.month_start AS DATE)
ORDER BY s.month_start;

-- ----------------------------------------------------------------------
-- C3. Channel efficiency: platform-reported vs order-based (last touch)
-- ----------------------------------------------------------------------
SELECT s.channel,
       ROUND(s.spend_usd, 0)                          AS spend_usd,
       ROUND(s.conversions, 0)                        AS platform_conversions,
       o.orders                                       AS real_orders,
       ROUND(s.platform_rev_usd / s.spend_usd, 2)     AS platform_roas,
       ROUND(o.net_usd / s.spend_usd, 2)              AS order_roas,
       ROUND(s.spend_usd / s.conversions, 2)          AS platform_cpa,
       ROUND(s.spend_usd / o.orders, 2)               AS order_cpa,
       ROUND(s.conversions / o.orders, 2)             AS platform_overcount_x
FROM (SELECT channel, SUM(spend_usd) AS spend_usd, SUM(conversions) AS conversions,
             SUM(platform_rev_usd) AS platform_rev_usd
      FROM ads_usd GROUP BY channel) AS s
JOIN (SELECT last_channel AS channel, COUNT(*) AS orders, SUM(net_usd) AS net_usd
      FROM orders_usd GROUP BY last_channel) AS o ON o.channel = s.channel
ORDER BY spend_usd DESC;

-- ----------------------------------------------------------------------
-- C4. Campaigns with >= $5,000 spend, worst order-based ROAS first
-- ----------------------------------------------------------------------
SELECT s.campaign_id, c.campaign_name, c.campaign_type,
       ROUND(s.spend_usd, 0)                       AS spend_usd,
       COALESCE(o.orders, 0)                       AS orders,
       ROUND(COALESCE(o.net_usd, 0) / s.spend_usd, 2) AS order_roas,
       ROUND(s.spend_usd / NULLIF(o.orders, 0), 2) AS order_cpa
FROM (SELECT campaign_id, SUM(spend_usd) AS spend_usd FROM ads_usd GROUP BY campaign_id) AS s
JOIN campaigns AS c ON c.campaign_id = s.campaign_id
LEFT JOIN (SELECT last_touch_campaign_id AS campaign_id, COUNT(*) AS orders, SUM(net_usd) AS net_usd
           FROM orders_usd GROUP BY last_touch_campaign_id) AS o ON o.campaign_id = s.campaign_id
WHERE s.spend_usd >= 5000
ORDER BY order_roas
LIMIT 10;

-- ----------------------------------------------------------------------
-- C5. First-touch vs last-touch orders by channel
-- ----------------------------------------------------------------------
SELECT channel,
       SUM(is_first) AS first_touch_orders,
       SUM(is_last)  AS last_touch_orders
FROM (SELECT first_channel AS channel, 1 AS is_first, 0 AS is_last FROM orders_usd
      UNION ALL
      SELECT last_channel  AS channel, 0 AS is_first, 1 AS is_last FROM orders_usd) AS t
GROUP BY channel
ORDER BY first_touch_orders DESC;

-- ----------------------------------------------------------------------
-- C6. CAC by first-touch channel: spend / customers whose FIRST order came from that channel
--   Orders without a customer_id cannot be tracked, so they are excluded.
-- ----------------------------------------------------------------------
WITH ranked AS (
  SELECT customer_id, first_channel,
         ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date, order_id) AS order_n
  FROM orders_usd
  WHERE customer_id IS NOT NULL
), new_cust AS (
  SELECT first_channel AS channel, COUNT(*) AS new_customers FROM ranked WHERE order_n = 1 GROUP BY first_channel
)
SELECT n.channel, n.new_customers,
       ROUND(s.spend_usd, 0)                    AS spend_usd,
       ROUND(s.spend_usd / n.new_customers, 2)  AS cac_first_touch
FROM new_cust AS n
JOIN (SELECT channel, SUM(spend_usd) AS spend_usd FROM ads_usd GROUP BY channel) AS s ON s.channel = n.channel
ORDER BY cac_first_touch;

-- ----------------------------------------------------------------------
-- C7. Budget pacing: actual spend vs planned budget (campaign currency)
-- ----------------------------------------------------------------------
SELECT c.status,
       COUNT(*)                                                     AS campaigns,
       SUM(CASE WHEN x.actual / c.planned_budget > 1.00 THEN 1 ELSE 0 END) AS over_plan,
       SUM(CASE WHEN x.actual / c.planned_budget > 1.25 THEN 1 ELSE 0 END) AS over_125pct,
       SUM(CASE WHEN x.actual / c.planned_budget < 0.85 THEN 1 ELSE 0 END) AS under_85pct,
       ROUND(AVG(x.actual / c.planned_budget), 2)                   AS avg_pacing
FROM campaigns AS c
JOIN (SELECT campaign_id, SUM(spend_clean) AS actual FROM ads GROUP BY campaign_id) AS x ON x.campaign_id = c.campaign_id
WHERE c.budget_missing = 'False'
GROUP BY c.status;

-- ----------------------------------------------------------------------
-- C8. Tracking check: platform-days with spend > $100 and ZERO reported conversions
--   A run of consecutive days like this is an outage signature, not a bad campaign.
-- ----------------------------------------------------------------------
SELECT platform, COUNT(*) AS zero_conversion_days, MIN(date) AS first_day, MAX(date) AS last_day
FROM (SELECT platform, date, SUM(conversions) AS conv, SUM(spend_usd) AS spend_usd
      FROM ads_usd GROUP BY platform, date) AS d
WHERE conv = 0 AND spend_usd > 100 AND platform = 'Meta'
  AND date BETWEEN '2026-03-01' AND '2026-03-31'
GROUP BY platform;

-- Meta: platform conversions vs real orders per month (ratio is ~1.6 except the outage month)
SELECT s.month_start, ROUND(s.conv, 0) AS platform_conv, o.orders,
       ROUND(s.conv / o.orders, 2) AS conv_per_order
FROM (SELECT month_start, SUM(conversions) AS conv FROM ads_usd WHERE platform = 'Meta' GROUP BY month_start) AS s
JOIN (SELECT month_start, COUNT(*) AS orders FROM orders_usd WHERE last_platform = 'Meta' GROUP BY month_start) AS o
  ON o.month_start = CAST(s.month_start AS DATE)
ORDER BY s.month_start;
