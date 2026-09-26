import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_theme.dart';
import '../core/format.dart';
import '../models/weighing.dart';
import '../providers/app_providers.dart';
import '../widgets/common.dart';
import '../widgets/owner_prompt.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'session_detail_screen.dart';
import 'stats_screen.dart';
import 'weighing_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  static const _pages = <Widget>[
    _HomeTab(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final tab = ref.watch(_tabIndexProvider);
    return Scaffold(
      body: IndexedStack(index: tab, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab == 0 ? 0 : tab + 1,
        onDestinationSelected: (i) {
          if (i == 1) {
            _openWeighing(context, ref);
            return;
          }
          ref.read(_tabIndexProvider.notifier).state = i == 0 ? 0 : i - 1;
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: Icon(Icons.scale_outlined),
            selectedIcon: Icon(Icons.scale),
            label: 'Cân lúa',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Lịch sử',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Cài đặt',
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends ConsumerWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayStatsProvider);
    final sessionsAsync = ref.watch(sessionsProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cân Lúa Gia Đình'),
        actions: [
          IconButton(
            tooltip: 'Thống kê',
            icon: const Icon(Icons.bar_chart),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StatsScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(Spacing.l),
        children: [
          const SizedBox(height: Spacing.s),
          Text('Xin chào 👋',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade700)),
          const SizedBox(height: Spacing.xs),
          Text(
            'Hôm nay cân lúa chưa?',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: Spacing.l),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: cs.primary,
              minimumSize: const Size.fromHeight(64),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
            ),
            onPressed: () => _openWeighing(context, ref),
            icon: const Icon(Icons.scale, size: 34),
            label: const Text(
              'Bắt đầu cân',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: Spacing.l),
          _TodayCard(today: today),
          SectionHeader('Lần cân gần đây'),
          sessionsAsync.when(
            loading: () => const LoadingView(),
            error: (e, _) =>
                ErrorState(onRetry: () => ref.invalidate(sessionsProvider)),
            data: (sessions) {
              if (sessions.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(Spacing.xl),
                    child: EmptyState(
                      icon: Icons.grass_outlined,
                      title: 'Chưa có lần cân nào',
                      message: 'Bấm "Bắt đầu cân" để lưu lần cân đầu tiên.',
                    ),
                  ),
                );
              }
              return Column(
                children: [
                  for (final s in sessions.take(3))
                    Card(
                      margin: const EdgeInsets.only(bottom: Spacing.s),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: Spacing.l, vertical: Spacing.xs),
                        title: Text(
                          s.owner.isEmpty
                              ? fmtDate(s.date)
                              : '${fmtDate(s.date)} - ${s.owner}',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${s.totalBags} bao • ${fmtKg(s.totalKg)} kg',
                          style: const TextStyle(fontSize: 15),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _openDetail(context, s.id),
                      ),
                    ),
                  if (sessions.length > 3)
                    TextButton(
                      onPressed: () => ref.read(_tabIndexProvider.notifier).state = 1,
                      child: const Text('Xem tất cả trong Lịch sử'),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: Spacing.xl),
        ],
      ),
    );
  }

  Future<void> _openDetail(BuildContext context, int sessionId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => SessionDetailScreen(sessionId: sessionId)),
    );
  }
}

Future<void> _openWeighing(BuildContext context, WidgetRef ref) async {
  final name = await promptOwnerName(context, ref);
  if (name == null || !context.mounted) return;
  await Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => WeighingScreen(owner: name)),
  );
  ref.invalidate(sessionsProvider);
  ref.invalidate(todayStatsProvider);
}

final _tabIndexProvider = StateProvider<int>((ref) => 0);

class _TodayCard extends ConsumerWidget {
  final AsyncValue<SessionStats> today;

  const _TodayCard({required this.today});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      color: const Color(0xFFF9A825).withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.l),
        child: today.when(
          loading: () => const SizedBox(
            height: 64,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) =>
              ErrorState(onRetry: () => ref.invalidate(todayStatsProvider)),
          data: (s) => Row(
            children: [
              const Icon(Icons.wb_sunny,
                  size: 40, color: Color(0xFFF9A825)),
              const SizedBox(width: Spacing.l),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hôm nay', style: AppTheme.label),
                    const SizedBox(height: Spacing.xs),
                    Text(
                      '${s.bags} bao • ${fmtKg(s.totalKg)} kg',
                      style: AppTheme.numberL,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Thống kê',
                icon: const Icon(Icons.chevron_right, size: 30),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StatsScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
