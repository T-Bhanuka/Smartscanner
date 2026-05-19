import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../types.dart';

class Dashboard extends StatelessWidget {
  final List<Receipt> receipts;
  final double monthlyBudget;

  const Dashboard({super.key, required this.receipts, required this.monthlyBudget});

  @override
  Widget build(BuildContext context) {
    final totalSpent = receipts.fold<double>(0.0, (sum, r) => sum + r.total);
    final budgetProgress = ((totalSpent / monthlyBudget).clamp(0, 1) as double);

    // Last 7 days spending
    final last7Days = List.generate(7, (i) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dayTotal = receipts
          .where((r) {
            try {
              final parsed = DateTime.parse(r.date);
              return parsed.day == date.day &&
                     parsed.month == date.month &&
                     parsed.year == date.year;
            } catch (e) {
              return false; // Skip receipts with invalid dates
            }
          })
          .fold<double>(0.0, (sum, r) => sum + r.total);
      return BarChartGroupData(
        x: i.toDouble(),
        barRods: [
          BarChartRodData(
            toY: dayTotal,
            color: const Color(0xFF8B5CF6),
            width: 16.0,
          ),
        ],
      );
    }).reversed.toList();

    final dayLabels = List.generate(7, (i) {
      final date = DateTime.now().subtract(Duration(days: 6 - i));
      return DateFormat('E').format(date);
    });

    // Category data
    final categoryTotals = <Category, double>{};
    for (final receipt in receipts) {
      for (final item in receipt.items) {
        categoryTotals[item.category] = (categoryTotals[item.category] ?? 0) + item.price;
      }
      if (receipt.items.isEmpty) {
        categoryTotals[receipt.category] = (categoryTotals[receipt.category] ?? 0) + receipt.total;
      }
    }

    final pieSections = categoryTotals.entries.map((entry) {
      final color = _getCategoryColor(entry.key);
      return PieChartSectionData(
        value: entry.value,
        title: entry.key.name,
        color: color,
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    if (pieSections.isEmpty) {
      pieSections.add(PieChartSectionData(
        value: 1,
        title: 'No Expenses',
        color: const Color(0xFF1E293B),
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF64748B),
        ),
      ));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Budget Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withValues(alpha: 0.4),
              border: Border.all(color: const Color(0xFF334155), width: 1),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Spent this month',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Rs. ${totalSpent.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Budget',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Rs. ${monthlyBudget.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Color(0xFF818CF8),
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFF334155),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: budgetProgress,
                    child: Container(
                      decoration: BoxDecoration(
                        color: totalSpent > monthlyBudget ? const Color(0xFFEF4444) : const Color(0xFF8B5CF6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Progress',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${(budgetProgress * 100).toStringAsFixed(1)}% Utilized',
                      style: TextStyle(
                        color: totalSpent > monthlyBudget ? const Color(0xFFEF4444) : const Color(0xFF8B5CF6),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Daily Trend Chart
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withValues(alpha: 0.6),
              border: Border.all(color: const Color(0xFF334155), width: 1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                const Row(
                  children: [
                    Icon(Icons.bar_chart, color: Color(0xFF818CF8), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Daily Trend (Rs.)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      barGroups: last7Days,
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                dayLabels[value.toInt()],
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 12,
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                'Rs.${value.toInt()}',
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 10,
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(show: false),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Category Pie Chart
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withValues(alpha: 0.6),
              border: Border.all(color: const Color(0xFF334155), width: 1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                const Row(
                  children: [
                    Icon(Icons.pie_chart, color: Color(0xFF8B5CF6), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Category Mix',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: pieSections,
                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: Category.values.map((category) {
                    final isActive = categoryTotals.containsKey(category);
                    final color = _getCategoryColor(category);
                    return Container(
                      width: (MediaQuery.of(context).size.width - 72) / 2,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isActive ? color.withValues(alpha: 0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isActive ? color : const Color(0xFF334155),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            category.name,
                            style: TextStyle(
                              color: isActive ? Colors.white : const Color(0xFF64748B),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(Category category) {
    switch (category) {
      case Category.Food:
        return const Color(0xFF10B981);
      case Category.Furniture:
        return const Color(0xFFF59E0B);
      case Category.Stationery:
        return const Color(0xFF3B82F6);
      case Category.Medicine:
        return const Color(0xFFF43F5E);
      case Category.BabyAccessories:
        return const Color(0xFFEC4899);
      case Category.MobileAccessories:
        return const Color(0xFF14B8A6);
      case Category.PetItems:
        return const Color(0xFFF97316);
      case Category.BankPayment:
        return const Color(0xFF8B5CF6);
      case Category.Transport:
        return const Color(0xFFEAB308);
      case Category.Other:
        return const Color(0xFF64748B);
    }
  }
}