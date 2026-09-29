import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_theme.dart';
import '../core/backup_service.dart';
import '../core/export_service.dart';
import '../providers/app_providers.dart';
import '../widgets/common.dart';
import 'help_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _bagsController;
  bool _bagsLoaded = false;

  @override
  void initState() {
    super.initState();
    _bagsController = TextEditingController();
    _loadDefaults();
  }

  Future<void> _loadDefaults() async {
    final repo = ref.read(appRepositoryProvider);
    final v = await repo.getSetting('bags_per_set', defaultValue: '5');
    _bagsController.text = v;
    if (mounted) setState(() => _bagsLoaded = true);
  }

  Future<void> _saveBags(String v) async {
    final n = int.tryParse(v);
    if (n == null || n <= 0 || n > 50) return;
    final repo = ref.read(appRepositoryProvider);
    await repo.setSetting('bags_per_set', '$n');
    ref.invalidate(defaultsProvider);
  }

  Future<void> _restore() async {
    final error = await BackupService.restore();
    if (error != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
      return;
    }
    // DB đã đóng sau khi chép file — lần truy cập sau sẽ mở lại tự động.
    ref.invalidate(sessionsProvider);
    ref.invalidate(todayStatsProvider);
    ref.invalidate(monthStatsProvider);
    ref.invalidate(defaultsProvider);
    final repo = ref.read(appRepositoryProvider);
    final v = await repo.getSetting('bags_per_set', defaultValue: '5');
    _bagsController.text = v;
    if (mounted) {
      setState(() => _bagsLoaded = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã khôi phục dữ liệu thành công')),
      );
    }
  }

  Future<void> _deleteAll() async {
    await BackupService.deleteAllData();
    ref.invalidate(sessionsProvider);
    ref.invalidate(todayStatsProvider);
    ref.invalidate(monthStatsProvider);
    ref.invalidate(defaultsProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa toàn bộ dữ liệu')),
      );
    }
  }

  Future<void> _confirmAndRun({
    required String title,
    required String content,
    required Future<void> Function() action,
    String confirmLabel = 'Đồng ý',
  }) async {
    final ok = await confirmDialog(
      context,
      title: title,
      content: content,
      confirmLabel: confirmLabel,
    );
    if (ok != true || !mounted) return;
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: ListView(
        padding: const EdgeInsets.all(Spacing.l),
        children: [
          _GroupHeader('Ứng dụng'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(Spacing.l),
              child: _bagsLoaded
                  ? TextField(
                      controller: _bagsController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Số bao mặc định mỗi set',
                        suffixText: 'bao',
                      ),
                      onSubmitted: _saveBags,
                      onChanged: _saveBags,
                    )
                  : const SizedBox(
                      height: 64,
                      child: Center(child: CircularProgressIndicator()),
                    ),
            ),
          ),
          _GroupHeader('Xuất dữ liệu'),
          _ActionCard(
            icon: Icons.table_view,
            label: 'Xuất toàn bộ CSV',
            onTap: () async {
              final repo = ref.read(appRepositoryProvider);
              await ExportService.shareCsv(await repo.getSessions());
            },
          ),
          const SizedBox(height: Spacing.s),
          _ActionCard(
            icon: Icons.picture_as_pdf,
            label: 'Xuất toàn bộ PDF',
            onTap: () async {
              final repo = ref.read(appRepositoryProvider);
              await ExportService.sharePdf(await repo.getSessions());
            },
          ),
          _GroupHeader('Dữ liệu'),
          _ActionCard(
            icon: Icons.backup,
            label: 'Sao lưu dữ liệu',
            onTap: () => BackupService.backup(),
          ),
          const SizedBox(height: Spacing.s),
          _ActionCard(
            icon: Icons.restore,
            label: 'Khôi phục dữ liệu',
            onTap: () => _confirmAndRun(
              title: 'Khôi phục dữ liệu?',
              content: 'Dữ liệu hiện tại sẽ được thay bằng file backup. '
                  'Sau khi khôi phục, app sẽ tự cập nhật dữ liệu mới.',
              action: _restore,
            ),
          ),
          const SizedBox(height: Spacing.s),
          _ActionCard(
            icon: Icons.delete_forever,
            destructive: true,
            label: 'Xóa toàn bộ dữ liệu',
            onTap: () => _confirmAndRun(
              title: 'Xóa TOÀN BỘ dữ liệu?',
              content: 'Mọi lần cân, bao lúa sẽ bị xóa vĩnh viễn. '
                  'Hãy sao lưu trước!',
              confirmLabel: 'Xóa hết',
              action: _deleteAll,
            ),
          ),
          _GroupHeader('Trợ giúp'),
          _ActionCard(
            icon: Icons.help_outline,
            label: 'Hướng dẫn sử dụng',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HelpScreen()),
            ),
          ),
          const SizedBox(height: Spacing.xxl),
          Center(
            child: Column(
              children: [
                Text(
                  'Cân Lúa Gia Đình • Phiên bản 1.0.0',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  '© 2026 Thế Khải. All rights reserved.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.l),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _bagsController.dispose();
    super.dispose();
  }
}

class _GroupHeader extends StatelessWidget {
  final String text;

  const _GroupHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.xs, Spacing.l, 0, Spacing.s),
      child: Text(text, style: AppTheme.label),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool destructive;
  final Future<void> Function() onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        destructive ? Theme.of(context).colorScheme.error : Colors.black87;
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 28, color: color),
        title: Text(label,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w600, color: color)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
