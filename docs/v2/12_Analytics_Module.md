# Analytics Module

The Analytics Module aggregates receipt expenses and renders visual spending charts.

## Dashboard Visualization

*   **Daily Trends Chart:** Draws a BarChart representing daily spending totals for the last 7 calendar days.
    *   *Calculation:* Loops through the last 7 calendar days, parses each receipt date string (`DateTime.parse(receipt.date)`), matches receipt records against day intervals, and accumulates the total expense values.
*   **Category Mix Chart:** Draws a PieChart displaying spending distribution across the 10 expense categories.
    *   *Calculation:* Accumulates category totals. Loops through receipt items (if items are present) or sums up the main receipt category value (if items are empty).

## Chart Integration
The module integrates with the `fl_chart` library:
*   `BarChart` utilizes `BarChartData` containing computed `BarChartGroupData` lists.
*   `PieChart` utilizes `PieChartData` containing computed `PieChartSectionData` lists.
*   Category colors are mapped using helper `_getCategoryColor(category)` mappings ([dashboard.dart:L403](file:///c:/Flutter/flutter_windows_3.41.9-stable/development/first_project/lib/components/dashboard.dart#L403)).
