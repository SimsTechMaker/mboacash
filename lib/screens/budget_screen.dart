import 'package:flutter/material.dart';

import '../i18n.dart';
import 'categories_screen.dart';
import 'stats_screen.dart';

/// Budget tab: where the money goes by category, the analyses and the figures.
class BudgetScreen extends StatefulWidget {
  final VoidCallback onShowOps;
  const BudgetScreen({super.key, required this.onShowOps});
  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  int part = 0;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<int>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: 0, label: Text(l.tabCategories)),
                ButtonSegment(value: 1, label: Text(l.budgetAnalyses)),
                ButtonSegment(value: 2, label: Text(l.statsTabFigures)),
              ],
              selected: {part},
              onSelectionChanged: (v) => setState(() => part = v.first),
            ),
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: part,
            children: [
              CategoriesScreen(onShowOps: widget.onShowOps),
              const StatsScreen(),
              const StatsScreen(figures: true),
            ],
          ),
        ),
      ],
    );
  }
}
