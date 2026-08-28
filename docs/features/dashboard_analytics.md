# Dashboard Analytics & Dynamic Date Filter Engine

## 1. Overview
The Dashboard presents financial charts (Donut Chart & Bar Chart), account balance summaries, and expense vs. income metrics.

---

## 2. Dynamic Date Filtering (`FilterLogic`)
Users filter transactions using choice chips corresponding to canonical internal timeframe keys:

- `'This Month'`: Computes start and end timestamp of current calendar month.
- `'This Week'`: Computes start and end timestamp of current week.
- `'This Year'`: Computes start and end timestamp of current year.
- `'All Time'`: Selects all confirmed transactions without timestamp boundaries.
- `'Custom'`: Allows custom date range selection via DatePicker dialog.

### Locale Independence
State holds canonical English keys (`'This Month'`, `'This Week'`, etc.) in `_selectedTimeframe` while choice chips display localized labels (`strings.timeframeThisMonth`, etc.). This guarantees filtering works consistently across all app languages.

