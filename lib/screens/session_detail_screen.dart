import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_theme.dart';
import '../core/format.dart';
import '../models/weighing.dart';
import '../providers/app_providers.dart';
import '../widgets/common.dart';
import 'export_buttons.dart';
import 'payment_screen.dart';
import 'weighing_screen.dart';

class SessionDetailScreen extends ConsumerStatefulWidget {
  const SessionDetailScreen({super.key, required this.sessionId});

  final int sessionId;

  @override
  ConsumerState<SessionDetailScreen> createState() =>
      _SessionDetailScreenState();
}

class _SessionDetailScreenState extends ConsumerState<SessionDetailScreen> {
  late Future<WeighingSession?> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final repo = ref.read(appRepositoryProvider);
    _future = repo.getSession(widget.sessionId);
  }

  Future<void> _delete(WeighingSession s) async {
    final ok = await confirmDialog(
      context,
      title: 'Xóa lần cân này?',
      content: 'Dữ liệu sẽ không thể khôi phục.',
      confirmLabel: 'Xóa',
      destructive: true,
    );
    if (ok != true) return;
    final repo = ref.read(appRepositoryProvider);
    await repo.deleteSession(s.id);
    ref.invalidate(sessionsProvider);
    ref.invalidate(todayStatsProvider);
    ref.invalidate(monthStatsProvider);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết lần cân'),
        actions: [
          FutureBuilder<WeighingSession?>(
            future: _future,
            builder: (context, snap) {
              final s = snap.data;
              return Row(
                children: [
                  if (s != null)
                    IconButton(
                      icon: const Icon(Icons.edit),
                      tooltip: 'Sửa',
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => WeighingScreen(session: s),
                          ),
                        );
                        setState(_reload);
                        ref.invalidate(sessionsProvider);
                      },
                    ),
                  if (s != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Xóa',
                      onPressed: () => _delete(s),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<WeighingSession?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LoadingView();
          }
          final s = snapshot.data;
          if (s == null) {
            return const Center(child: Text('Không tìm thấy lần cân'));
          }
          return ListView(
            padding: const EdgeInsets.all(Spacing.l),
            children: [
              Text(
                'Ngày ${fmtDate(s.date)}'
                '${s.owner.isEmpty ? '' : ' - ${s.owner}'}',
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold),
              ),
              if (s.note.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: Spacing.xs),
                  child: Text(s.note, style: const TextStyle(fontSize: 16)),
                ),
              const SizedBox(height: Spacing.l),
              for (var i = 0; i < s.sets.length; i++)
                _SetDetailCard(
                  index: i,
                  set: s.sets[i],
                ),
              const SizedBox(height: Spacing.l),
              Card(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.08),
                child: Padding(
                  padding: const EdgeInsets.all(Spacing.l),
                  child: Column(
                    children: [
                      KeyValueRow('Số bao', '${s.totalBags} bao'),
                      KeyValueRow('Tổng cân', kg(s.totalKg)),
                      if (s.isPaid) ...[
                        if (s.deductTotalKg > 0)
                          KeyValueRow('Trừ bao (tổng)', kg(s.deductTotalKg))
                        else if (s.deductPerBag > 0)
                          KeyValueRow('Trừ bao',
                              '${fmtKg(s.deductPerBag)} kg × ${s.totalBags} bao = ${kg(s.totalDeductKg)}')
                        else
                          const KeyValueRow('Trừ bao', 'Không trừ'),
                        KeyValueRow('Giá',
                            '${fmtMoney(s.pricePerKg.round())} đ/kg'),
                        const Divider(),
                        const SizedBox(height: Spacing.xs),
                        AmountText(
                          fmtKg(s.totalRealKg),
                          unit: 'kg',
                          label: 'THỰC NHẬN',
                        ),
                        const SizedBox(height: Spacing.m),
                        AmountText(
                          fmtMoney(s.totalMoney),
                          unit: 'đ',
                          label: 'THÀNH TIỀN',
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ] else ...[
                        const Divider(),
                        const KeyValueRow('Thực nhận', 'chưa tính tiền'),
                        PayBadge(paid: false),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: Spacing.l),
              ExportButtonsRow(session: s),
              const SizedBox(height: Spacing.s),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PaymentScreen(sessionId: s.id),
                      ),
                    );
                    setState(_reload);
                    ref.invalidate(sessionsProvider);
                  },
                  icon: const Icon(Icons.payments, size: 28),
                  label: Text(
                    s.isPaid ? 'Sửa tính tiền' : 'Tính tiền',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(height: Spacing.xl),
            ],
          );
        },
      ),
    );
  }
}

class _SetDetailCard extends StatelessWidget {
  final int index;
  final WeighingSet set;

  const _SetDetailCard({required this.index, required this.set});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: Spacing.s),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Set ${index + 1} — ${set.bags.length} bao — ${kg(set.totalKg)}',
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: Spacing.xs),
            Wrap(
              spacing: Spacing.s,
              runSpacing: Spacing.xs,
              children: [
                for (var i = 0; i < set.bags.length; i++)
                  Chip(
                    label: Text(
                      '${i + 1}: ${fmtKg(set.bags[i].weightKg)} kg',
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
