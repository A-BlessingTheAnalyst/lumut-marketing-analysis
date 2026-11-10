# Project Brief: Lumora Home Marketing Performance & Acquisition Efficiency Review

**Type:** marketing analytics case study (Python, SQL, Power BI)
**Period analysed:** 1 January 2025 to 31 October 2026 (22 months)
**Markets:** United Kingdom (GBP) and United States (USD)
**Role:** Marketing Performance Analyst
**Data:** synthetic. Lumora Home is a fictional company and the data is built to behave like real ad-platform and e-commerce exports.

## 1. Business context

Lumora Home is a direct-to-consumer retailer of home furnishings and decor (sofas and armchairs, rugs, lighting, bedding, storage, decor). It sells online only, to customers in the UK and the US.

Marketing spend is spread across Paid Search (Google Ads, Microsoft Ads, brand and non-brand), Shopping (Google), Paid Social (Meta, TikTok, Pinterest), Display (Google Display Network), Video (YouTube) and Email / CRM (Klaviyo).

Each platform reports its own conversions. The business also keeps its own order records. The two sources do not agree and have never been reconciled.

## 2. The situation

It is early November 2026. The company is preparing its 2027 marketing plan and its Black Friday and Christmas trading. The CMO has asked for a review of the last 22 months of marketing activity. Finance reports that marketing spend has grown faster than revenue and wants to know where the money works and where it does not. Exports from the ad platforms, the order system and the CRM were handed over without any quality checks.

## 3. Stakeholders

| Stakeholder | What they need |
| --- | --- |
| Chief Marketing Officer | Where to allocate the 2027 budget; whether weekly channel numbers can be trusted |
| Head of Performance Marketing | Which campaigns to scale, fix or stop; budget pacing |
| Finance Director | Whether spend is efficient and whether platform numbers reconcile to actual orders |
| CRM / Retention Manager | Whether acquired customers return or buy once |
| Paid Social Lead | How Meta, TikTok and Pinterest perform, and whether measurement is fair to social |

## 4. Objectives

1. Produce a trusted, documented, cleaned dataset for marketing reporting.
2. Measure channel, platform and campaign performance with standard KPIs.
3. Assess how reliable platform-reported results are compared with actual orders.
4. Evaluate customer acquisition efficiency and the quality of acquired customers.
5. Recommend evidence-based budget actions, stating what the data does and does not support.
6. Deliver an interactive dashboard and a short executive summary.

## 5. Business questions

**A. Performance**
1. How did spend, clicks, conversions and revenue evolve over 22 months, by market and channel?
2. Which channels, platforms and campaigns are most and least efficient (CTR, CPC, CVR, CPA, ROAS)?
3. How do results differ by device?
4. How strong is seasonality (Black Friday, Christmas), and how should it affect how trends are read?

**B. Budget**
5. How did actual spend compare with planned budget?
6. Where is money spent with weak return, and where is there evidence that efficient campaigns could take more?

**C. Measurement and trust**
7. Do platform-reported conversions and revenue agree with actual orders? Where and why do they differ?
8. Can any period or platform be considered unreliable, and what is the evidence?
9. How does the picture change under first-touch versus last-touch attribution?

**D. Customers**
10. What does it cost to acquire a new customer (CAC) by channel, and how does that compare with first-order value?
11. Do customers acquired through different channels behave differently afterwards?

**E. Recommendation**
12. What should the business do differently in 2027, what would be tested next, and what can the data not show?

## 6. Tools

| Tool | Use |
| --- | --- |
| Python (pandas) | Audit, cleaning, reconciliation and exploratory analysis; repeatable and documented |
| SQL (MySQL) | Aggregation, joins, KPI queries, cohort and attribution logic |
| Excel / Power Query | Spot checks and stakeholder-friendly validation |
| Power BI + DAX | Interactive dashboard on a clean star-schema model |
| GitHub | Version control and portfolio home |

## 7. Approach

1. Business understanding (this document)
2. Data understanding: audit of the raw files (`notebooks/00_data_audit.ipynb`)
3. Data cleaning: documented decisions (`notebooks/01_data_cleaning.ipynb`, `docs/data_quality_report.md`)
4. Analysis in SQL and Python
5. Dashboard in Power BI
6. Insights and recommendations
7. Presentation

## 8. Principles

* Raw data is never edited. All fixes happen in code and are logged.
* Platform-reported numbers are treated as claims until reconciled to orders.
* Every recommendation must be backed by evidence. Where the data cannot support a conclusion, the analysis says so.
* Real findings are reported even when unflattering to a channel or to the business.
