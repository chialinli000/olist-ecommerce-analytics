# Olist Operations Report Automation

This tool extends the existing Olist SQL and Power BI portfolio with a CSV-to-report workflow. It validates aggregated data, calculates monthly changes and generates an English HTML report. Optional AI interpretation is available after configuring API access.

## Quick start on Windows

1. Extract the complete package and open the `reporting_automation` folder in Windows File Explorer.
2. Double-click `Start.cmd`. Opening its preview inside a chat does not run it.
3. Enter a month such as `2018-07` or `2018-08`, or press Enter for the latest available month.
4. Choose `1` for offline mode. This requires no API key and makes no network requests.
5. After `Report complete` appears, press any key to close the window. If an error occurs, the window stays open; the PowerShell script also attempts to save last_error.txt.
6. Open `reports/latest.html` in a browser. Each successful run also keeps a separate dated folder containing its own `report.html`.

English examples: [July 2018](examples/2018-07.html) and [August 2018](examples/2018-08.html). GitHub displays HTML source; download a file and open it in a browser to view the report.

The launcher first looks for the bundled Codex Python runtime on this computer, then for Python on PATH. On another computer, install Python 3.10 or later. No additional Python packages are required.

## What is automated

The current workflow is:

**Six CSV files → data validation → calculated findings → rule-based or optional AI interpretation → HTML report → human review.**

- Check required files and columns, empty fields, invalid numbers and duplicate categories.
- Verify cancellation rates, repeat-purchase rates, customer totals and average payment values.
- Compare the selected month with the immediately preceding month. Missing previous-month data does not silently use an earlier month.
- Keep monthly operations, the fixed customer snapshot and full-window observations separate.
- Save calculated facts, interpretation and input-file hashes so results can be traced.

## Input files and existing project

This module reads the six existing SQL-generated reporting outputs in the repository-level `../dashboard_data/` directory:

| File | Use in this version |
|---|---|
| `monthly_performance.csv` | Selected-month findings and month-on-month comparisons |
| `customer_kpis.csv` | Customer snapshot and consistency checks |
| `customer_segments.csv` | Segment shares, interpretation and consistency checks |
| `customer_frequency.csv` | Cross-check one-time and repeat customer counts |
| `executive_kpis.csv` | Validate overall cancellation rates and monthly count bounds |
| `payment_methods.csv` | Basic validation; not yet included in the report's interpretation |

After manually exporting SQL results, update the corresponding files in the repository-level `dashboard_data/` directory. The module uses those files directly; no second data folder is needed. Use `--data` to specify another folder with matching schemas. Keep the full repository structure when downloading; copying Start.cmd alone will not work.

This version does not connect to MySQL, export CSVs, refresh Power BI, schedule runs or send reports. Those are possible later extensions.

## Offline and AI modes

**Offline mode:** Python calculates the findings and adds predefined explanatory text. The numbers change with the month; some interpretation remains the same. This must not be described as a live AI result.

**AI mode:** Choose `2`, enter a model ID available to your API account that supports Responses API structured output, and enter an API key in the hidden local prompt. An existing `OPENAI_API_KEY` environment variable can also be used. Do not paste keys into chat or commit them to project files. API usage may incur charges.

The AI receives aggregate facts and reporting definitions, not raw customer transactions. It returns English explanations and suggested follow-up checks with supporting fact IDs. The request sets `store: false`; this does not constitute a promise of zero data retention.

Checks cover output structure, valid fact references and the absence of digits in interpretation text. They do not guarantee correct meaning, causal reasoning or reporting scope. Human review is always required. An API failure stops the run rather than substituting rule-based text and labelling it as AI output.

The API request and response handling have been tested with mocked responses. A real account connection and the usefulness of model output have not yet been validated.

Implementation reference: [OpenAI structured outputs documentation](https://developers.openai.com/api/docs/guides/structured-outputs?api-mode=responses).

## Reading the report

- **Calculated Findings and Evidence:** numbers calculated by Python, each with a fact ID.
- **Rule-based Interpretation / AI Interpretation Draft:** explanations and proposed next checks.
- **Reporting Periods and Interpretation Limits:** scope definitions that prevent misleading comparisons.

Orders are grouped by purchase month. The recorded order status is not necessarily the status known at that month-end.

The customer snapshot stays fixed at **1 September 2018**, regardless of the selected operating month. It may contain transactions after an earlier selected month, so it must not be treated as customer information available at that earlier date.

Repeat-purchase rate is an observation-window measure, not cohort retention. RFM thresholds are illustrative. Recorded payment value is not recognised revenue or profit. Recommendations are exploratory, not proven improvements.

Cancellation-rate changes use unrounded ratios calculated from counts. They may differ slightly from subtracting displayed rounded rates.

## Output and audit trail

Every successful run creates a uniquely named folder with:

- `report.html`: standalone report, printable to PDF from the browser.
- `facts.json`: calculated facts, values and reporting scopes.
- `insights.json`: rule-based text or AI draft.
- `run.json`: input hashes, mode, model when applicable, processing time and pending-review status.

`reports/latest.html` updates only after a successful run. A failure leaves the previous report intact; check its month and run ID before using it. Review status is not an approval record.

## Evaluate before making portfolio claims

Complete the same reporting task manually and with this tool. Compare total time including human review, numerical errors, unsupported statements, scope errors and required edits. Script processing time alone is not evidence of time saved.

An accurate current description is: “Extended an SQL and Power BI portfolio with a Python workflow that validates aggregated CSV outputs, calculates monthly changes and generates traceable reports. Optional AI interpretation is implemented but awaits live testing.”

## Developer commands

Run from the `reporting_automation` directory:

```text
python report.py --month 2018-07
python report.py --month 2018-08
python report.py --month 2018-08 --ai --model YOUR_MODEL_ID
python -m unittest -v test_report.py
```

Use `OPENAI_API_KEY` and optionally `OPENAI_MODEL` for command-line AI runs. Default execution remains offline.

## Data attribution

Underlying data: Olist's [Brazilian E-Commerce Public Dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce). The original portfolio identifies its licence as CC BY-NC-SA 4.0. These SQL-derived aggregates are included for educational, non-commercial portfolio use; retain the data attribution and applicable licence terms.
