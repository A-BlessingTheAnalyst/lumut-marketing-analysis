# Data Dictionary: Lumora Home

## Where the data comes from

| File | Source system | How it is produced |
|---|---|---|
| `campaigns.csv` | Marketing team's campaign tracker (manually maintained spreadsheet) | One row per campaign; names and labels are typed by different team members |
| `ad_performance_daily.csv` | Ad platform exports (Google Ads, Microsoft Ads, Meta, TikTok, Pinterest, YouTube) and Klaviyo, combined into one file | One row per campaign × ad group × device × day that had delivery. Days with no delivery have no row. |
| `orders.csv` | E-commerce order system | One row per order |
| `customers.csv` | CRM | One row per customer record |
| `fx_rates_monthly.csv` | Finance team | Monthly average GBP→USD rate |

All five files are **raw exports** and were not cleaned before the analysis began.

## Table relationships

```
campaigns (1) ──────< ad_performance_daily (many)      via campaign_id
campaigns (1) ──────< orders (many)                    via last_touch_campaign_id
campaigns (1) ──────< orders (many)                    via first_touch_campaign_id
customers (1) ──────< orders (many)                    via customer_id
fx_rates_monthly                                       joins on month of the date (to convert GBP ↔ USD)
```

Grain (one row represents):

- `campaigns`: one campaign
- `ad_performance_daily`: one campaign × ad group × device × day
- `orders`: one order
- `customers`: one customer record
- `fx_rates_monthly`: one month

---

## campaigns.csv

| Column | Description |
|---|---|
| `campaign_id` | Unique campaign identifier, format `CMP-0001` |
| `campaign_name` | Campaign name. The intended convention is `Market_Channel_Type_Theme_YYYYMM` (start month). |
| `channel` | Marketing channel (Paid Search, Paid Social, Display, Shopping, Video, Email) |
| `platform` | Platform the campaign runs on (e.g. Google Ads, Meta, TikTok) |
| `campaign_type` | Brand, Non-Brand, Shopping, Prospecting (reaching new audiences), Retargeting (people who already visited), or CRM (email) |
| `objective` | Business objective of the campaign |
| `market` | UK or US |
| `start_date` | Campaign start date |
| `end_date` | Campaign end date (for always-on campaigns this is the end of the data period) |
| `planned_budget` | Total budget planned for the campaign's lifetime, in the campaign's currency |
| `currency` | Currency of the campaign (GBP for UK, USD for US) |
| `status` | Active, Ended or Paused |
| `owner_team` | Team responsible for managing the campaign |

## ad_performance_daily.csv

| Column | Description |
|---|---|
| `date` | Date of delivery |
| `campaign_id` | Links to `campaigns.campaign_id` |
| `ad_group_id` | Ad group identifier (unique within the campaign) |
| `ad_group_name` | Ad group name: keyword theme, audience or creative concept |
| `device` | Device the ads were served on (Mobile, Desktop, Tablet) |
| `impressions` | Number of times ads were shown (for Email, number of emails delivered) |
| `clicks` | Number of clicks on ads (for Email, clicks on email links) |
| `spend` | Media cost for the row, in the currency given in `currency` |
| `currency` | Currency of `spend` and `conversion_value` |
| `conversions` | Purchases attributed to the ad **by the platform's own attribution model**. Some platforms use data-driven attribution, which can produce fractional conversions. |
| `conversion_value` | Revenue the platform attributes to those conversions, in `currency` |

## orders.csv

| Column | Description |
|---|---|
| `order_id` | Order identifier, format `ORD-000001` |
| `customer_id` | Links to `customers.customer_id` |
| `order_date` | Date the order was placed |
| `country` | Delivery country |
| `currency` | Currency the order was placed in (GBP or USD) |
| `product_category` | Main product category of the order |
| `order_value` | Order value **before** discounts, excluding shipping, in `currency` |
| `discount_amount` | Discount applied to the order, in `currency` |
| `shipping_cost` | Shipping charged to the customer, in `currency` |
| `is_refunded` | Whether the order was refunded |
| `first_touch_campaign_id` | Campaign recorded as the first marketing touchpoint in the customer's journey (blank if none recorded) |
| `last_touch_campaign_id` | Campaign recorded as the last marketing touchpoint before purchase (blank means direct / no attributed campaign) |

## customers.csv

| Column | Description |
|---|---|
| `customer_id` | Customer identifier, format `C0000001` |
| `signup_date` | Date the customer record was created (can be before the first order, e.g. newsletter signup) |
| `country` | Customer country |
| `email_hash` | Hashed email address (the real email is not stored in this extract) |
| `marketing_opt_in` | Whether the customer agreed to receive marketing emails |
| `crm_acquisition_channel` | Acquisition channel as recorded in the CRM when the customer was created |

## fx_rates_monthly.csv

| Column | Description |
|---|---|
| `month` | First day of the month the rate applies to |
| `gbp_to_usd` | Average monthly rate: how many USD one GBP buys |

---

## Notes

- Spend, conversion value and order values are in **local currency** (GBP for the UK market, USD for the US). Think carefully before adding them together.
- Platform conversions and `orders.csv` are **different sources of truth** about the same business outcomes.
- This dictionary describes what each column is **meant** to contain. It does not guarantee the data matches the definitions. Verifying that was the purpose of the data audit.

---

## Columns added during cleaning (files in `data_clean/`)

| File | Column | Meaning |
| --- | --- | --- |
| campaigns | `dates_swapped` | True if start and end dates were entered the wrong way round and were swapped back |
| campaigns | `budget_missing` | True if `planned_budget` is blank |
| campaigns | `name_follows_convention` | True if the name matches `Market_Channel_Type_Theme_YYYYMM` |
| campaigns | `name_duplicated` | True if another campaign shares the same name |
| ad_performance_daily | `device_was_blank` | True if the device was originally blank (now labelled `Unknown`) |
| ad_performance_daily | `spend_flag` | `ok`, `missing`, `negative` or `suspected_x100` |
| ad_performance_daily | `spend_clean` | Spend to use in analysis: decimal-shift errors divided by 100, blanks left blank, negatives kept as credits |
| ad_performance_daily | `clicks_exceed_impressions` | True for impossible rows; exclude from CTR and CVR |
| ad_performance_daily | `conversion_value_missing` | True if `conversion_value` was blank |
| customers | `signup_date_invalid` | True if the signup date fell after the end of the data period (date set to blank) |
| orders | `order_value_flag` | `ok`, `zero` or `negative` |
| orders | `customer_missing` | True if `customer_id` is blank |
| orders | `is_direct` | True if no last-touch campaign was recorded (direct / unattributed) |
| fx_rates_monthly | `is_estimated` | True for the month that was missing and was estimated |

Other cleaning outputs: `ad_performance_unmapped.csv` (ad rows whose `campaign_id` does not exist in campaigns), `customer_id_map.csv` (merged duplicate customers) and `cleaning_log.csv` (every decision, with counts).
