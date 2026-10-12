import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../data/default_categories.dart';
import '../services/summary_service.dart';
import '../utils/formatters.dart';

/// Donut chart of spending per category. Tapping a slice shows its value
/// in the centre.
class CategoryPieChart extends StatefulWidget {
  const CategoryPieChart({super.key, required this.summary});

  final MonthlySummary summary;

  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart> {
  int _touchedIndex = -1;

  @override
  void didUpdateWidget(covariant CategoryPieChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.summary.month != widget.summary.month) {
      _touchedIndex = -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.summary.expensesSorted;
    final total = widget.summary.totalExpense;
    final textTheme = Theme.of(context).textTheme;

    final touched = _touchedIndex >= 0 && _touchedIndex < entries.length
        ? entries[_touchedIndex]
        : null;
    final centerLabel =
        touched == null ? 'Total spent' : categoryById(touched.key).name;
    final centerValue = touched == null ? total : touched.value;

    return AspectRatio(
      aspectRatio: 1.25,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 64,
              startDegreeOffset: -90,
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  setState(() {
                    final section = response?.touchedSection;
                    if (!event.isInterestedForInteractions || section == null) {
                      _touchedIndex = -1;
                      return;
                    }
                    _touchedIndex = section.touchedSectionIndex;
                  });
                },
              ),
              sections: [
                for (var i = 0; i < entries.length; i++)
                  _buildSection(entries[i], total, isTouched: i == _touchedIndex),
              ],
            ),
          ),
          IgnorePointer(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(centerLabel, style: textTheme.labelMedium),
                const SizedBox(height: 2),
                Text(
                  formatCurrency(centerValue),
                  style: textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PieChartSectionData _buildSection(
    MapEntry<String, double> entry,
    double total, {
    required bool isTouched,
  }) {
    final category = categoryById(entry.key);
    final share = total <= 0 ? 0.0 : entry.value / total;
    return PieChartSectionData(
      value: entry.value,
      color: category.color,
      radius: isTouched ? 58 : 48,
      // Hide labels on tiny slices so they don't overlap.
      title: share >= 0.07 ? formatPercent(share) : '',
      titleStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        shadows: [Shadow(color: Colors.black38, blurRadius: 2)],
      ),
    );
  }
}
