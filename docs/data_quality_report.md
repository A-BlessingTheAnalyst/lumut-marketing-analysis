# Data Quality and Cleaning Report

Every issue found in the audit, the action taken and the assumption behind it. Generated from `data_clean/cleaning_log.csv`, which is written by `notebooks/01_data_cleaning.ipynb`.

**Action types.** *Fix*: the same value written differently, standardised. *Flag*: cannot be resolved, so the original is kept and a flag column marks it. *Remove*: exact duplicates only.

## Row reconciliation

| Table | Rows before | Rows after | Why it changed |
| --- | --- | --- | --- |
| fx_rates_monthly | 21 | 22 | Missing month added and marked as estimated |
| campaigns | 111 | 111 | Labels fixed and flags added; no rows removed |
| ad_performance_daily | 73,628 | 72,935 | 584 exact duplicates removed; 109 rows with unknown campaign moved to `ad_performance_unmapped.csv` |
| customers | 30,499 | 30,142 | 357 duplicate customer records merged (same `email_hash`) |
| orders | 47,669 | 47,385 | 284 exact duplicate orders removed |

## Decisions

### fx_rates_monthly

| Column | Issue | Rows | Action | Method | Assumption and risk |
| --- | --- | --- | --- | --- | --- |
| month | February 2026 missing (21 of 22 months) | 1 | Fix | Added the missing month with the average of the Jan and Mar 2026 rates; added is_estimated=True | Rate moved smoothly between neighbours (they differ by about 0.1%). Risk is small. |

### campaigns

| Column | Issue | Rows | Action | Method | Assumption and risk |
| --- | --- | --- | --- | --- | --- |
| channel | Label variants (e.g. 'paid social', 'PPC', 'GDN', 'Search') | 16 | Fix | Stripped spaces; mapped every variant to one of 6 official channels with a dictionary | Vague labels were resolved using campaign_name and platform as evidence. Risk: low. |
| platform | Label variants (e.g. 'Facebook Ads', 'AdWords', 'Bing Ads') | 16 | Fix | Mapped every variant to one of 8 official platforms with a dictionary | Each variant clearly refers to one platform. Risk: low. |
| start_date/end_date | End date earlier than start date | 3 | Fix + Flag | Swapped the two dates and set dates_swapped=True; verified against real ad dates in Step 3 | Dates were entered the wrong way round. Risk: low once verified against ad data. |
| planned_budget | Blank budget | 6 | Flag | Left blank; added budget_missing=True | A budget cannot be invented. Pacing analysis excludes these campaigns. |
| campaign_name | Names break the naming convention | 8 | Flag | Added name_follows_convention flag; names unchanged | Names are for people; campaign_id is the key. Risk: none. |
| campaign_name | Same name on different campaign_ids | 14 | Flag | Added name_duplicated flag | Never join on campaign_name, always on campaign_id. |

### ad_performance_daily

| Column | Issue | Rows | Action | Method | Assumption and risk |
| --- | --- | --- | --- | --- | --- |
| campaign_id | Lowercase / spaces in IDs | 220 | Fix | strip() + upper() | None. Pure formatting. |
| date | Two date formats (YYYY-MM-DD and DD/MM/YYYY) | 1,473 | Fix | Parsed each format separately with explicit formats | DD/MM/YYYY confirmed by rows such as 17/01/2025 and by row order. |
| device | Case variants, blanks and 'Unknown' | 5,994 | Fix | Lower-cased then mapped to Mobile/Desktop/Tablet; blank and 'Unknown' both labelled 'Unknown'; kept device_was_blank | Blank and 'Unknown' are assumed to mean the same thing (device not recorded). |
| currency | Label variants (gbp, £, usd, $, US$) | 2,950 | Fix | Mapped to GBP/USD; verified against campaigns.currency | Each variant is unambiguous. Amounts are NOT converted here. |
| (whole row) | Exact duplicate rows | 584 | Remove | drop_duplicates() after standardising | Duplicates would double-count spend. |
| campaign_id | IDs not found in campaigns (CMP-90xx) | 109 | Flag (quarantine) | Moved to ads_unmapped.csv, not deleted | Cannot be attributed to a campaign. Spend in these rows is reported separately. |
| spend | Blank spend | 364 | Flag | spend_flag='missing'; spend_clean left blank | Not filled with 0: that would understate cost. |
| spend | Negative spend | 72 | Flag | spend_flag='negative'; kept in spend_clean | Treated as platform credits (net spend). Risk: could be data errors. |
| spend | Suspected decimal-shift (x100) values | 35 | Fix + Flag | Whole-number spend > 8x the campaign median, divided by 100 in spend_clean; original kept in spend | Corrected cost-per-click becomes normal. Risk: a genuine large spend could be wrongly shrunk (rare). |
| clicks/impressions | Clicks greater than impressions | 146 | Flag | clicks_exceed_impressions=True; values unchanged | Impossible rows. Exclude from CTR/CVR in analysis. |
| conversion_value | Blank | 219 | Flag | conversion_value_missing=True | Not filled; revenue/ROAS for these rows is understated. |

### customers

| Column | Issue | Rows | Action | Method | Assumption and risk |
| --- | --- | --- | --- | --- | --- |
| country | Label variants (United Kingdom, USA) | 3,049 | Fix | Mapped to UK / US | Unambiguous. |
| crm_acquisition_channel | Free-text variants and blanks | 4,692 | Fix | Mapped variants to official channels; blanks labelled 'Unknown' | 'google' is assumed to be Paid Search (it could be Shopping). Risk: small mis-assignment. |
| signup_date | Dates after the end of the data period (2027-01-01) | 304 | Flag | Set to blank and added signup_date_invalid=True | True date unknown, so not guessed. |
| email_hash | Same email on several customer_ids | 357 | Remove (merge) | Kept lowest customer_id per email_hash; orders re-pointed using customer_map | Same email_hash means same person. Customers with a blank email_hash cannot be matched. |

### orders

| Column | Issue | Rows | Action | Method | Assumption and risk |
| --- | --- | --- | --- | --- | --- |
| order_date | Two date formats | 716 | Fix | Parsed each format separately | DD/MM/YYYY, same as ads. |
| country | Label variants (GB, U.K., USA, ...) | 5,719 | Fix | Mapped to UK / US; cross-checked against currency | Verified: GBP orders = UK, USD orders = US. |
| is_refunded | 8 different encodings | 11,905 | Fix | Mapped all to True/False | Y/Yes/TRUE/1 = refunded; N/No/FALSE/0 = not refunded. |
| order_id | Duplicate rows (same order_id) | 284 | Remove | drop_duplicates() | Exact copies; would double-count revenue. |
| customer_id | Orders of merged duplicate customers | 523 | Fix | Re-pointed using customer_map | Same person (shared email_hash). |
| order_value | Zero or negative order value | 94 | Flag | order_value_flag = zero / negative; values unchanged | Could be errors, test orders or adjustments. Exclude from revenue analysis. |
| customer_id | Blank customer_id | 189 | Flag | customer_missing=True | Real orders; excluded only from customer-level analysis. |
| shipping_cost | Blank shipping_cost | 1,421 | Flag (left blank) | Left blank | Blank is not 0: free shipping is already stored as 0. |
| first/last_touch_campaign_id | Blank touch columns | 7,897 | Keep | Added is_direct for last touch | Blank = no marketing touch recorded. Real information, not an error. |

## Judgment calls worth a second look

* **Suspected decimal-shift spend (35 rows).** Whole-number spends more than 8 times their campaign's median were divided by 100 in `spend_clean`. After correction the cost per click falls from roughly 78 to roughly 0.78, which is in the normal range. The original `spend` is kept. Risk: a genuine large spend could be shrunk.
* **Negative spend (72 rows).** Kept in `spend_clean` as platform credits (net spend). They could instead be errors.
* **Blank `device` and `Unknown`.** Treated as the same thing: the device was not recorded.
* **`google` in the CRM channel field.** Assumed to mean Paid Search; it could be Shopping.
* **Merged customers.** Two customer IDs with the same `email_hash` are treated as one person. Customers with a blank `email_hash` cannot be matched.
* **Blank touch columns on orders.** Kept and interpreted as direct or unattributed orders. They are information, not errors.

## Checks that passed after cleaning

Row reconciliation, uniqueness of `campaign_id`, `customer_id` and `order_id`, only official values in device, currency, country and refund fields, all dates within 2025-01-01 to 2026-10-31, every ad `campaign_id` found in campaigns, every order `customer_id` found in customers, an FX rate for every month used, and raw files unchanged.
