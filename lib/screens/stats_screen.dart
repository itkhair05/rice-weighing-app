import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_theme.dart';
import '../core/format.dart';
import '../providers/app_providers.dart';
import '../widgets/common.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayStatsProvider);
    final month = ref.watch(monthStatsProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Thống kê')),
      body: ListView(
        padding: const EdgeInsets.all(Spacing.l),
        children: [
          today.when(
            loading: () => const LoadingView(),
            error: (e, _) =>
                ErrorState(onRetry: () => ref.invalidate(todayStatsProvider)),
            data: (s) => _StatsCard(
              title: 'Hôm nay',
              bags: s.bags,
              totalKg: s.totalKg,
              money: s.totalMoney,
              color: cs.primary,
            ),
          ),
          const SizedBox(height: Spacing.l),
          month.when(
            loading: () => const LoadingView(),
            error: (e, _) =>
                ErrorState(onRetry: () => ref.invalidate(monthStatsProvider)),
            data: (s) => _StatsCard(
              title: 'Tháng này',
              bags: s.bags,
              totalKg: s.totalKg,
              money: s.totalMoney,
              color: cs.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final String title;
  final int bags;
  final double totalKg;
  final int money;
  final Color color;

  const _StatsCard({
    required this.title,
    required this.bags,
    required this.totalKg,
    required this.money,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333))),
            const SizedBox(height: Spacing.l),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Icon(Icons.inventory_2, size: 34, color: color),
                    Text('$bags', style: AppTheme.numberXL),
                    const Text('bao', style: AppTheme.label),
                  ],
                ),
                Container(width: 1, height: 64, color: Colors.grey.shade300),
                Column(
                  children: [
                    Icon(Icons.scale, size: 34, color: color),
                    Text(fmtKg(totalKg), style: AppTheme.numberXL),
                    const Text('kg', style: AppTheme.label),
                  ],
                ),
              ],
            ),
            if (money > 0) ...[
              const Divider(height: Spacing.xl),
              Text(
                'Đã tính tiền: ${fmtMoney(money)} đ',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
