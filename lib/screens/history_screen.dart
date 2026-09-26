import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_theme.dart';
import '../core/format.dart';
import '../models/weighing.dart';
import '../providers/app_providers.dart';
import '../widgets/common.dart';
import '../widgets/owner_prompt.dart';
import 'session_detail_screen.dart';
import 'weighing_screen.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  Future<void> _pickDate(BuildContext context, WidgetRef ref) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null || !context.mounted) return;
    final repo = ref.read(appRepositoryProvider);
    final sessions = await repo.getSessions(
      from: DateTime(picked.year, picked.month, picked.day),
      to: DateTime(picked.year, picked.month, picked.day, 23, 59, 59),
    );
    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _DaySessionsScreen(date: picked, sessions: sessions),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(sessionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            tooltip: 'Lọc theo ngày',
            onPressed: () => _pickDate(context, ref),
          ),
        ],
      ),
      body: sessionsAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) =>
            ErrorState(onRetry: () => ref.invalidate(sessionsProvider)),
        data: (sessions) {
          if (sessions.isEmpty) {
            return EmptyState(
              icon: Icons.history_outlined,
              title: 'Chưa có lần cân nào',
              message: 'Các lần cân đã lưu sẽ hiện ở đây.',
              actionLabel: 'Bắt đầu cân',
              onAction: () => _startWeighing(context, ref),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(sessionsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(Spacing.l),
              itemCount: sessions.length,
              itemBuilder: (context, index) =>
                  _SessionCard(session: sessions[index]),
            ),
          );
        },
      ),
    );
  }

  Future<void> _startWeighing(BuildContext context, WidgetRef ref) async {
    final name = await promptOwnerName(context, ref);
    if (name == null || !context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WeighingScreen(owner: name)),
    );
    ref.invalidate(sessionsProvider);
  }
}

class _SessionCard extends ConsumerWidget {
  final WeighingSession session;

  const _SessionCard({required this.session});

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await confirmDialog(
      context,
      title: 'Xóa lần cân này?',
      content: 'Dữ liệu sẽ không thể khôi phục.',
      confirmLabel: 'Xóa',
      destructive: true,
    );
    if (ok != true) return;
    final repo = ref.read(appRepositoryProvider);
    await repo.deleteSession(session.id);
    ref.invalidate(sessionsProvider);
    ref.invalidate(todayStatsProvider);
    ref.invalidate(monthStatsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = session;
    final title = s.owner.isEmpty
        ? fmtDate(s.date)
        : '${fmtDate(s.date)} - ${s.owner}';
    return Card(
      margin: const EdgeInsets.only(bottom: Spacing.s),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SessionDetailScreen(sessionId: s.id),
            ),
          );
          ref.invalidate(sessionsProvider);
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Spacing.l, Spacing.m, Spacing.s, Spacing.m),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: Spacing.xs),
                    Text(
                      '${s.totalBags} bao • ${fmtKg(s.totalKg)} kg',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: Spacing.s),
                    Row(
                      children: [
                        PayBadge(paid: s.isPaid),
                        const SizedBox(width: Spacing.s),
                        if (s.isPaid) ...[
                          Flexible(
                            child: Text(
                              'Thực nhận ${fmtKg(s.totalRealKg)} kg',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey.shade600),
                            ),
                          ),
                          const SizedBox(width: Spacing.s),
                          Text(
                            '${fmtMoney(s.totalMoney)} đ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: 'Xóa',
                onPressed: () => _confirmDelete(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DaySessionsScreen extends StatelessWidget {
  final DateTime date;
  final List<WeighingSession> sessions;

  const _DaySessionsScreen({required this.date, required this.sessions});

  @override
  Widget build(BuildContext context) {
    final totalBags = sessions.fold<int>(0, (sum, s) => sum + s.totalBags);
    final totalKg = sessions.fold<double>(0, (sum, s) => sum + s.totalKg);
    final totalMoney =
        sessions.fold<int>(0, (sum, s) => sum + (s.isPaid ? s.totalMoney : 0));
    return Scaffold(
      appBar: AppBar(title: Text('Ngày ${fmtDate(date)}')),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(Spacing.l),
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsets.all(Spacing.l),
              child: Column(
                children: [
                  Text(
                    '${sessions.length} lần cân • $totalBags bao • ${fmtKg(totalKg)} kg',
                    style: const TextStyle(fontSize: 17),
                  ),
                  if (totalMoney > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: Spacing.xs),
                      child: Text(
                        'Tổng tiền: ${fmtMoney(totalMoney)} đ',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: sessions.isEmpty
                ? const EmptyState(
                    icon: Icons.event_busy,
                    title: 'Không có lần cân nào ngày này',
                  )
                : ListView(
                    padding:
                        const EdgeInsets.symmetric(horizontal: Spacing.l),
                    children: [
                      for (final s in sessions)
                        Card(
                          margin: const EdgeInsets.only(bottom: Spacing.s),
                          child: ListTile(
                            title: Text(
                              s.owner.isEmpty
                                  ? '${s.totalBags} bao — ${fmtKg(s.totalKg)} kg'
                                  : '${s.owner} — ${s.totalBags} bao • ${fmtKg(s.totalKg)} kg',
                            ),
                            subtitle: Text(s.isPaid
                                ? 'Đã tính tiền: ${fmtMoney(s.totalMoney)} đ'
                                : 'Chưa tính tiền'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    SessionDetailScreen(sessionId: s.id),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
