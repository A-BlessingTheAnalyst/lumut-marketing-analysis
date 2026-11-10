# Power BI Dashboard Brief

Build target: a 4-page report that answers the questions in [`findings.md`](findings.md) for a CMO audience. 

Data: the CSVs in [`powerbi/`](../powerbi/) (already USD-converted and attributed).

## Data model (star schema)

| Table | Grain | Key |
|---|---|---|
| `fact_ad_performance` | campaign × ad group × device × day | `date`, `campaign_id` |
| `fact_orders` | one order | `order_date`, `customer_id`, `last_touch_campaign_id`, `first_touch_campaign_id` |
| `dim_campaign` | one campaign | `campaign_id` |
| `dim_date` | one day | `date` |
| `dim_customer` | one customer | `customer_id` |
| `dim_fx_rates` | one month | `month` (reference only) |

Relationships (one-to-many, single direction): `dim_date[date]` → `fact_ad_performance[date]` and `fact_orders[order_date]`; `dim_campaign[campaign_id]` → `fact_ad_performance[campaign_id]` and **`fact_orders[last_touch_campaign_id]`** (active). Make `first_touch_campaign_id` an *inactive* relationship and use `USERELATIONSHIP` for first-touch measures. `dim_customer[customer_id]` → `fact_orders[customer_id]`.

Gotchas to handle in Power Query: `valid` and `is_first_order` are text/boolean (filter `valid = TRUE` in measures, not the table); orders with blank `last_touch_campaign_id` are direct — do not drop them.

## Measures to write yourself
Spend (USD), Impressions, Clicks, Platform Conversions, Platform Revenue, Valid Orders, Order Revenue (USD), Platform ROAS, **Order ROAS**, Platform CPA, **Order CPA**, CTR, CPC, CVR, Platform-to-Order Ratio, New Customers (`is_first_order`), CAC, Repeat Rate, Budget Pacing %. Always compute ratios as SUM / SUM with `DIVIDE`.

## Pages

1. **Executive summary** — KPI cards (Spend, Valid Orders, Order Revenue, Order ROAS, Order CPA, Platform-to-Order Ratio); monthly line of Spend vs Order ROAS; channel bar of Order ROAS with Platform ROAS marker. Slicers: Date, Market, Channel.
2. **Channel & campaign efficiency** — table/matrix by channel → campaign type with Spend, Order ROAS, Order CPA; scatter of Spend (x) vs Order ROAS (y) per campaign, highlight CMP-0092; top/bottom 10 campaigns (spend ≥ $5k).
3. **Attribution & customers** — first-touch vs last-touch orders by channel (clustered bar); CAC and Repeat Rate by acquisition channel; Revenue per customer.
4. **Data trust & operations** — monthly Meta conversions vs orders (line) with outage dates annotated (use `dim_date[is_meta_tracking_outage]`); platform-to-order ratio by platform; budget pacing by campaign; Black Friday comparison; device CVR/ROAS.

## Design notes
One colour per channel used consistently on every page; titles that state the finding (e.g. "Display Prospecting returns $0.49 per $1"); caveat text box on page 1 ("Revenue is pre-refund, no margin; last-touch attribution"); tooltips showing both platform and order-based values. Check every page total against `outputs/` tables before publishing.
