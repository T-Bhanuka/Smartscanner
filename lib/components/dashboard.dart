import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../types.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class Dashboard extends StatefulWidget {
  final List<Receipt> receipts;
  final double monthlyBudget;
  final List<dynamic> familyConnections;
  final String? selectedUserId;
  final ValueChanged<String?> onFamilyMemberSelected;

  const Dashboard({
    super.key,
    required this.receipts,
    required this.monthlyBudget,
    required this.familyConnections,
    required this.selectedUserId,
    required this.onFamilyMemberSelected,
  });

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  bool _isLoadingAdvice = false;

  Future<void> _fetchAiAdvice() async {
    setState(() {
      _isLoadingAdvice = true;
    });

    try {
      final token = await StorageService.getToken();
      if (token == null) {
        throw Exception('User is not authenticated.');
      }
      final advice = await ApiService.getAiBudgetAdvice(token, targetUserId: widget.selectedUserId);
      if (!mounted) return;
      _showAdviceModal(advice);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to get AI Advice: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAdvice = false;
        });
      }
    }
  }

  Widget _buildFormattedAdvice(String text) {
    const baseStyle = TextStyle(
      color: Color(0xFFE2E8F0),
      fontSize: 15,
      height: 1.6,
      fontWeight: FontWeight.w400,
    );

    final List<TextSpan> spans = [];
    final RegExp regExp = RegExp(r'\*\*(.*?)\*\*');
    int start = 0;

    for (final Match match in regExp.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(
          text: text.substring(start, match.start),
          style: baseStyle,
        ));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: baseStyle.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ));
      start = match.end;
    }

    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: baseStyle,
      ));
    }

    return RichText(
      text: TextSpan(
        children: spans.isEmpty
            ? [TextSpan(text: text, style: baseStyle)]
            : spans,
      ),
    );
  }

  void _showAdviceModal(String advice) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
            border: Border(
              top: BorderSide(color: Color(0xFF334155), width: 1.5),
            ),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            top: 10,
            left: 24,
            right: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF334155),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0xFF8B5CF6),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'AI Financial Advisor',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: _buildFormattedAdvice(advice),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Got it, thanks!',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final receipts = widget.receipts;
    final monthlyBudget = widget.monthlyBudget;
    final familyConnections = widget.familyConnections;
    final selectedUserId = widget.selectedUserId;
    final onFamilyMemberSelected = widget.onFamilyMemberSelected;
    final totalSpent = receipts.fold<double>(0.0, (sum, r) => sum + r.total);
    final budgetProgress = (monthlyBudget > 0)
        ? (totalSpent / monthlyBudget).clamp(0.0, 1.0)
        : 0.0;

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
        x: i,
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
        categoryTotals[item.category] =
            (categoryTotals[item.category] ?? 0) + item.price;
      }
      if (receipt.items.isEmpty) {
        categoryTotals[receipt.category] =
            (categoryTotals[receipt.category] ?? 0) + receipt.total;
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
      pieSections.add(
        PieChartSectionData(
          value: 1,
          title: 'No Expenses',
          color: const Color(0xFF1E293B),
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF64748B),
          ),
        ),
      );
    }

    // Find selected member's name
    String viewerName = "Me";
    if (selectedUserId != null) {
      final selectedMember = familyConnections.firstWhere(
        (c) => c['_id'] == selectedUserId,
        orElse: () => null,
      );
      if (selectedMember != null) {
        viewerName = selectedMember['name'] ?? 'Family Member';
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Family Avatars List
          Container(
            height: 90,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: familyConnections.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildFamilyAvatar(
                    label: 'Me',
                    isSelected: selectedUserId == null,
                    onTap: () => onFamilyMemberSelected(null),
                    icon: Icons.person_rounded,
                  );
                }

                final member = familyConnections[index - 1];
                final name = member['name'] ?? 'Unknown';
                final memberId = member['_id'];

                final parts = name.trim().split(' ');
                final firstName = parts.isNotEmpty ? parts.first : 'User';
                final initials = name.isNotEmpty
                    ? (parts.length > 1
                        ? (parts[0][0] + parts[1][0]).toUpperCase()
                        : parts[0][0].toUpperCase())
                    : '?';

                return _buildFamilyAvatar(
                  label: firstName,
                  initials: initials,
                  isSelected: selectedUserId == memberId,
                  onTap: () => onFamilyMemberSelected(memberId),
                );
              },
            ),
          ),
          // Visual Indicator (Subtitle / Banner)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Icon(
                  selectedUserId == null ? Icons.person_rounded : Icons.people_alt_rounded,
                  color: const Color(0xFF818CF8),
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    selectedUserId == null
                        ? "Viewing: Personal Financial Data (Me)"
                        : "Viewing: $viewerName's Financial Data",
                    style: const TextStyle(
                      color: Color(0xFF818CF8),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
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
                    // ==========================================
                    // UI Fix: Expanded and FittedBox applied here
                    // ==========================================
                    Expanded(
                      flex: 6,
                      child: Column(
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
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Rs. ${totalSpent.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 4,
                      child: Column(
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
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Rs. ${monthlyBudget.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Color(0xFF818CF8),
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // ==========================================
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
                        color: totalSpent > monthlyBudget
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF8B5CF6),
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
                        color: totalSpent > monthlyBudget
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF8B5CF6),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                if (monthlyBudget > 0 && (totalSpent / monthlyBudget) >= 0.80) ...[
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFEF4444).withValues(alpha: 0.15),
                          const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isLoadingAdvice ? null : _fetchAiAdvice,
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              if (_isLoadingAdvice)
                                const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEF4444)),
                                  ),
                                )
                              else
                                const Icon(
                                  Icons.auto_awesome_rounded,
                                  color: Color(0xFFEF4444),
                                  size: 22,
                                ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'AI Alert',
                                      style: TextStyle(
                                        color: Color(0xFFFCA5A5),
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'You have used 80% of your budget. Tap for AI Advice',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (!_isLoadingAdvice)
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: Color(0xFF94A3B8),
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
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
                              final index = value.toInt();
                              if (index < 0 || index >= dayLabels.length) {
                                return const SizedBox.shrink();
                              }
                              return Text(
                                dayLabels[index],
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
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? color.withValues(alpha: 0.1)
                            : Colors.transparent,
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
                              color: isActive
                                  ? Colors.white
                                  : const Color(0xFF64748B),
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

  Widget _buildFamilyAvatar({
    required String label,
    String? initials,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF8B5CF6) : const Color(0xFF334155),
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: isSelected
                    ? const Color(0xFF8B5CF6).withValues(alpha: 0.2)
                    : const Color(0xFF1E293B),
                child: icon != null
                    ? Icon(icon, color: isSelected ? const Color(0xFF818CF8) : const Color(0xFF64748B), size: 24)
                    : Text(
                        initials ?? '?',
                        style: TextStyle(
                          color: isSelected ? const Color(0xFF818CF8) : const Color(0xFF94A3B8),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 60,
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
