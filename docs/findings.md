# Findings: Lumora Home Marketing Performance Review

All figures are USD, Jan 2025 – Oct 2026, from the cleaned data (`data_clean/`). GBP converted at the month's average rate (Feb 2026 rate is an estimate). Every number below comes from [`notebooks/02_analysis.ipynb`](../notebooks/02_analysis.ipynb) and is reproduced in [`sql/03_analysis.sql`](../sql/03_analysis.sql); tables are in [`outputs/`](../outputs/).

**How to read "order-based" figures:** revenue = `order_value - discount_amount` on valid orders (47,291), before refunds, with no margin or product cost available. Each order is credited to its **last-touch** campaign unless stated. ROAS here is revenue / ad spend, not profit.

## Headline

1. Total ad spend was **$1.75M** against **47,291** valid orders. **83%** carry a campaign touch; **17%** (7,885) have none and are direct/unattributed.
2. **Platforms claim 1.4–1.6× more purchases than the order system records**, on every platform. That is a consistent overcount (overlapping attribution), so platform ROAS and CPA flatter every channel.
3. **Paid Search (Brand and Shopping) and Shopping carry the efficiency; Prospecting on Display, Video and Paid Social returns less than $1 of revenue per $1 spent on a last-touch basis.** Video looks very different on a first-touch view, so it should be tested rather than simply cut.
4. **One campaign, CMP-0092 (UK Display Prospecting), took 4.1% of all spend for an order ROAS of 0.44.**
5. **Meta reported zero conversions for 15 days (10–24 Mar 2026) while Meta-attributed orders kept arriving.** Platform-only reporting would have shown that period as a total loss.

## Answers to the business questions

### Q1. Is performance improving?
Not steadily. Blended order ROAS (all revenue / all spend) was 4.5 in Jan 2025 on only $21k spend, fell to about 1.8 in Oct–Dec 2025 as monthly spend grew to $109k–$179k, recovered to 2.8–2.9 in Apr–May 2026, dropped to **1.52 in Aug 2026**, and was 2.5 in Oct 2026. Cost per order rose from $18 to $45–54 in the weakest months. The early months are small-base, so the Jan 2025 figure should not be used as a benchmark. (`outputs/q1_monthly_trend.csv`)

### Q2–Q3. Which channels and platforms earn their spend?

| Channel | Spend | Platform ROAS | Order ROAS | Order CPA | Platform conv. per real order |
|---|---|---|---|---|---|
| Paid Search | $634k | 3.36 | 2.34 | $36 | 1.49 |
| Shopping | $456k | 3.10 | 2.13 | $39 | 1.49 |
| Paid Social | $474k | 1.76 | 1.10 | $73 | 1.61 |
| Display | $139k | 1.12 | 0.77 | $107 | 1.51 |
| Video | $43k | 0.62 | 0.43 | $196 | 1.52 |
| Email | $7k | 35.1 | 26.7 | $3 | 1.37 |

* Within channels, **campaign type matters more than channel**: Paid Search Brand returns 10.3 (spend $77k) but Non-Brand 1.24 (spend $557k); Paid Social Retargeting 2.65 vs Prospecting 0.92; Display Retargeting 2.26 vs Prospecting 0.49.
* Brand search and Email mostly capture people who already intend to buy, so their ROAS says little about what extra spend would do. Email's 26.7 should not be read as a reason to spend more.
* Platform view: Google Ads 2.35, Meta 1.12, Microsoft Ads 0.93, Pinterest 1.31, Google Display Network 0.77, YouTube 0.43, TikTok 0.36 (order ROAS). TikTok is small ($19k) with CPA $259.

### Q4. Which campaigns waste or earn money?
* **CMP-0092** (UK Display Prospecting, started June 2026): $72.2k spend (second-largest campaign), 410 orders, order ROAS **0.44**, order CPA **$176**, CVR 0.1%. Its CTR fell **66%** from the first to the last third of its life, and Display clicks in July 2026 were about four times June's.
* Other large losers (order ROAS): CMP-0047 Non-Brand US search 0.59 ($45k), CMP-0095 Paid Social Prospecting 0.77 ($45k), CMP-0042 TikTok 0.36 ($19k).
* **CMP-0002** (UK Shopping, 13.6% of all spend, $239k) has order ROAS 1.44 against 2.13 for Shopping overall. It is the largest budget line and sits below its own channel average.
* Best large campaigns: CMP-0003 (US Brand search) 14.6 and CMP-0001 (UK Brand) 10.4, both brand terms.
* Note: some campaign names are wrong in the tracker (e.g. CMP-0020's name says Paid Social but it is Microsoft Ads Non-Brand). Analyse by `campaign_id` and channel columns, not by name. (`outputs/q4_campaign_level.csv`)

### Q5. Is there creative/audience fatigue?
Using first-third vs last-third CTR over each campaign's delivery days (65 campaigns with 60+ days): the median change is **+1.5%**, so fatigue is not general. Six campaigns fell more than 30%, all Prospecting on Display or Paid Social: CMP-0050 (−67%), CMP-0092 (−66%), CMP-0075 (−52%), CMP-0016 (−46%), CMP-0021 (−39%), CMP-0049 (−36%). A short campaign (CMP-0074, 70 days) shows CTR *rising*, which this method cannot explain. CTR decay is a hint, not proof, since audience size, bidding and seasonality also move CTR. (`outputs/q5_ctr_decay.csv`)

### Q6. Do devices differ?
Using platform data (orders carry no device): on Paid Search, Desktop CVR is 6.1% vs Mobile 3.5%, and ROAS 3.98 vs 2.96; similar direction for Shopping (3.69 vs 2.72) and Paid Social (2.04 vs 1.58). Mobile takes the largest share of spend (57% of Paid Search). Desktop is more efficient everywhere; whether that justifies shifting bids depends on assisted-conversion behaviour that this data cannot show. (`outputs/q6_device.csv`)

### Q7. Who starts journeys and who closes them?
First-touch vs last-touch orders: **Video 1,203 vs 219**, Paid Social 8,467 vs 6,467, Shopping 14,994 vs 11,785, Display 1,385 vs 1,299, while **Email 153 vs 2,212** and Direct 3,704 vs 7,885. Video, Paid Social and Shopping start more journeys than they close; Email and Direct close journeys others start. Judging Video on last-touch alone understates what it does. (`outputs/q7_first_vs_last_touch.csv`)

### Q8. CAC and customer quality (first-touch, new customers)

| Channel | New customers | CAC | Avg revenue / customer | Repeat rate |
|---|---|---|---|---|
| Shopping | 9,068 | $50 | $136 | 39% |
| Video | 797 | $54 | $120 | 28% |
| Email | 122 | $55 | $105 | 18% |
| Paid Search | 11,042 | $57 | $133 | 37% |
| Paid Social | 5,694 | $83 | $122 | 33% |
| Display | 1,163 | $119 | $96 | 16% |

Display is weak on every view: highest CAC, lowest revenue per customer, lowest repeat rate. Video's last-touch CPA ($196) and first-touch CAC ($54) tell opposite stories; this is the biggest open question in the analysis. Customers with no first-touch campaign (2,142) repeat at 40%, the highest rate. Customers acquired recently have had less time to repeat, so repeat rates are biased low for late cohorts. (`outputs/q8_cac_and_customer_quality.csv`)

### Q9. Can the CRM acquisition field be trusted?
No, not for channel reporting. Only 57–74% of customers agree with the order-system first touch. 2,713 customers are "Unknown", and CRM "Direct / Organic" customers show a paid first touch in about 40% of cases. (`outputs/q9_crm_vs_first_touch.csv`)

### Q10. Budget pacing
Of 105 campaigns with a planned budget, 47 are above plan (39 Ended, 8 Active) and 41 are below 85% of plan (35 Ended, 6 Active). Biggest overspends: CMP-0071 (159% of plan), CMP-0068 (140%), CMP-0091 (125%). CMP-0068 is also one of the worst performers (order ROAS 0.19). Under-spend on a campaign is not automatically good: it can mean unused budget on campaigns that were working. (`outputs/q10_budget_pacing.csv`)

### Q11. Black Friday (15 Nov – 1 Dec 2025)
Spend per day was **$7,562 vs $2,237** on other days (3.4×); orders per day were **177 vs 63** (2.8×). Average discount was **11% vs 2%**. Order ROAS was **1.83 vs 2.38**. Revenue per ad dollar fell during the event and sales were bought partly with discounts. Without margin data, we cannot say whether the event was profitable. (`outputs/q11_black_friday.csv`)

### Q12. Can the platform numbers be trusted?
* **Level:** no. Every platform reports 1.4–1.6 conversions per real order. A fixed ratio across platforms is expected from overlapping attribution (and, for Google, fractional data-driven credit), so platform CPA is about one third lower than the real CPA.
* **Outage:** Meta reported **0 conversions on 15 consecutive days (10–24 Mar 2026)** with $5,047 of spend, while **118 Meta-attributed orders worth $8,989** were recorded. Monthly conversions per order for Meta are 1.5–1.9 in every month except March 2026 (0.81). Meta daily spend also fell from about $590 to about $350 on the first day of the outage; the data can't show whether that was a reaction or a coincidence. TikTok (5 days, Dec 2025) and YouTube (5 days, Feb 2026) also have short zero-conversion runs, but on far smaller volumes ($926 and $653 spend) where a quiet week can happen by chance; only Meta's is long and on a large platform. (`outputs/q12_meta_outage.csv`)

## What I would test next (recommendations, not results)

1. **Pause or cap CMP-0092 and test a smaller budget**, since it has the lowest order ROAS (0.44) and highest order CPA ($176) of the six Display Prospecting campaigns, although the others are also weak (ROAS 0.50–0.62). Impact depends on whether its prospecting role has value not captured by last-touch.
2. **Run a holdout/geo test on Video and Paid Social Prospecting** before cutting them: first-touch evidence suggests they start journeys, last-touch evidence says they are expensive.
3. **Reduce Display Prospecting** — it is the weakest channel on last-touch ROAS, CAC and repeat rate, and no view in this data supports it.
4. **Review CMP-0002**: largest budget line, below its channel average.
5. **Fix measurement:** alert on platform-days with spend and zero conversions; reconcile platform vs order counts monthly; correct the CRM acquisition field.
6. **Add margin and refund data** before any budget decision: ROAS is not profit, and refunds (about 5.6% of orders, similar across channels) are not deducted here.

## Limitations

* Synthetic data: results show a method, not a real company's performance.
* Last-touch credit gives all of an order to one campaign; first-touch gives it to a different one. Neither measures incrementality.
* 189 orders without a customer ID are excluded from customer analysis. 94 zero/negative-value orders are excluded from revenue.
* Feb 2026 FX rate is estimated (neighbours averaged); effect on totals is small but non-zero.
* Order revenue excludes shipping and is before refunds; there is no cost-of-goods or margin data.
* Orders carry no device, so device analysis uses platform-reported conversions only.
