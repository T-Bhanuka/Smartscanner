# Budget Module

The Budget Module tracks monthly spending limits against actual expense totals.

## Setting Monthly Limits
*   **Trigger:** Tap on the header budget card in `HomePage`.
*   **Interface:** Opens `_buildBudgetModal` ([main.dart:L853](file:///c:/Flutter/flutter_windows_3.41.9-stable/development/first_project/lib/main.dart#L853)), overlaying a custom input form field.
*   **Validation:** Inputs are validated to be non-negative numeric strings.
*   **Persistence:** Triggers `_saveData()`, calling `ApiService.updateBudget` to save the value to `/budget/:month` on the server.

## Progress Calculations

Budget utilization calculations are performed in `Dashboard` ([dashboard.dart:L18-20](file:///c:/Flutter/flutter_windows_3.41.9-stable/development/first_project/lib/components/dashboard.dart#L18-L20)):

```dart
final totalSpent = receipts.fold<double>(0.0, (sum, r) => sum + r.total);
final budgetProgress = (monthlyBudget > 0)
    ? (totalSpent / monthlyBudget).clamp(0.0, 1.0)
    : 0.0;
```

A progress bar reflects the calculated utilization. The progress bar turns red if `totalSpent > monthlyBudget`.
