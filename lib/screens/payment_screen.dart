import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_theme.dart';
import '../core/format.dart';
import '../models/weighing.dart';
import '../providers/app_providers.dart';
import '../widgets/common.dart';
import 'session_detail_screen.dart';

enum _DeductMode { none, perBag, total }

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({
    super.key,
    required this.sessionId,
    this.showDetailAfterSave = false,
  });

  final int sessionId;
  final bool showDetailAfterSave;

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  final _deductController = TextEditingController();
  final _priceController = TextEditingController();
  final _depositController = TextEditingController();
  WeighingSession? _session;
  _DeductMode _mode = _DeductMode.none;
  bool _loaded = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final repo = ref.read(appRepositoryProvider);
    final session = await repo.getSession(widget.sessionId);
    if (session == null) {
      if (mounted) Navigator.pop(context);
      return;
    }
    _session = session;
    if (session.deductTotalKg > 0) {
      _mode = _DeductMode.total;
      _deductController.text = fmtKg(session.deductTotalKg);
    } else if (session.deductPerBag > 0) {
      _mode = _DeductMode.perBag;
      _deductController.text = fmtKg(session.deductPerBag);
    } else {
      final defaults = await ref.read(defaultsProvider.future);
      final savedDeduct =
          double.tryParse(defaults['deduct_per_bag'] ?? '') ?? 0;
      if (savedDeduct > 0) {
        _mode = _DeductMode.perBag;
        _deductController.text = fmtKg(savedDeduct);
      }
    }
    _priceController.text = session.isPaid ? fmtKg(session.pricePerKg) : '';
    _depositController.text = session.deposit > 0 ? fmtKg(session.deposit) : '';
    setState(() => _loaded = true);
  }

  double get _deductValue =>
      double.tryParse(_deductController.text.replaceAll(',', '.')) ?? 0;
  double get _price =>
      double.tryParse(_priceController.text.replaceAll(',', '.')) ?? 0;
  double get _deposit =>
      double.tryParse(_depositController.text.replaceAll(',', '.')) ?? 0;

  double get _totalDeduct {
    final s = _session!;
    return switch (_mode) {
      _DeductMode.none => 0,
      _DeductMode.perBag => s.totalBags * _deductValue,
      _DeductMode.total => _deductValue,
    };
  }

  Future<void> _save() async {
    if (_price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nhập giá bán (đ/kg)')),
      );
      return;
    }
    if (_mode != _DeductMode.none && _deductValue <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nhập số kg trừ bao')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = ref.read(appRepositoryProvider);
      final perBag = _mode == _DeductMode.perBag ? _deductValue : 0.0;
      final totalDeduct = _mode == _DeductMode.total ? _deductValue : 0.0;
      await repo.updatePayment(
        widget.sessionId,
        deductPerBag: perBag,
        deductTotalKg: totalDeduct,
        pricePerKg: _price,
        deposit: _deposit,
      );
      await repo.setSetting(
          'deduct_per_bag', _mode == _DeductMode.perBag ? fmtKg(perBag) : '0');
      await repo.setSetting('price_per_kg', fmtKg(_price));
      ref.invalidate(sessionsProvider);
      ref.invalidate(todayStatsProvider);
      ref.invalidate(monthStatsProvider);
      ref.invalidate(defaultsProvider);
      if (!mounted) return;
      if (widget.showDetailAfterSave) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SessionDetailScreen(sessionId: widget.sessionId),
          ),
        );
      } else {
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Lỗi lưu thanh toán: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Lỗi lưu: $e'),
              duration: const Duration(seconds: 5)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _deductController.dispose();
    _priceController.dispose();
    _depositController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: LoadingView());
    }
    final s = _session;
    if (s == null) {
      return const Scaffold(
        body: Center(child: Text('Không tìm thấy lần cân')),
      );
    }
    final realKg = s.totalKg - _totalDeduct;
    final money = (realKg * _price).round();
    final finalMoney = money - _deposit.round();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Tính tiền')),
      body: ListView(
        padding: const EdgeInsets.all(Spacing.l),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(Spacing.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (s.owner.isNotEmpty) KeyValueRow('Chủ ruộng', s.owner),
                  KeyValueRow('Tổng cân',
                      '${s.totalBags} bao • ${fmtKg(s.totalKg)} kg'),
                  if (s.note.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: Spacing.xs),
                      child: Text(s.note),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Spacing.l),
          _PayField(
            controller: _priceController,
            label: 'Giá lúa (đ/kg)',
            onChanged: () => setState(() {}),
          ),
          const SizedBox(height: Spacing.l),
          Text('Trừ bao', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: Spacing.xs),
          Card(
            child: Column(
              children: [
                RadioGroup<_DeductMode>(
                  groupValue: _mode,
                  onChanged: (v) => setState(() => _mode = v!),
                  child: Column(
                    children: [
                      RadioListTile<_DeductMode>(
                        value: _DeductMode.none,
                        title: const Text('Không trừ',
                            style: TextStyle(fontSize: 17)),
                      ),
                      RadioListTile<_DeductMode>(
                        value: _DeductMode.perBag,
                        title: const Text('Trừ theo kg/bao',
                            style: TextStyle(fontSize: 17)),
                      ),
                      RadioListTile<_DeductMode>(
                        value: _DeductMode.total,
                        title: const Text('Trừ tổng kg',
                            style: TextStyle(fontSize: 17)),
                      ),
                    ],
                  ),
                ),
                if (_mode != _DeductMode.none)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        Spacing.l, 0, Spacing.l, Spacing.l),
                    child: _PayField(
                      controller: _deductController,
                      label: _mode == _DeductMode.perBag
                          ? 'Số kg trừ mỗi bao'
                          : 'Tổng số kg trừ',
                      suffix: 'kg',
                      onChanged: () => setState(() {}),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.l),
          _PayField(
            controller: _depositController,
            label: 'Tiền cọc (đã nhận)',
            suffix: 'đ',
            onChanged: () => setState(() {}),
          ),
          const SizedBox(height: Spacing.xl),
          Card(
            color: cs.primary.withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsets.all(Spacing.xl),
              child: Column(
                children: [
                  KeyValueRow(
                    'Khối lượng tính tiền',
                    '${fmtKg(s.totalKg)} − ${fmtKg(_totalDeduct)} = ${fmtKg(realKg)} kg',
                  ),
                  KeyValueRow('Đơn giá', '${fmtMoney(_price.round())} đ/kg'),
                  const Divider(height: Spacing.xl),
                  const SizedBox(height: Spacing.s),
                  const Text('TỔNG TIỀN (CHƯA TRỪ CỌC)', style: AppTheme.label),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    '${fmtMoney(money)} đ',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: Spacing.m),
                  const Text('TIỀN CÒN LẠI', style: AppTheme.label),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    '${fmtMoney(finalMoney)} đ',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Spacing.xl),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              Spacing.l, Spacing.m, Spacing.l, Spacing.l),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.payments, size: 28),
              label: Text(_saving ? 'Đang lưu...' : 'Lưu thanh toán',
                  style: const TextStyle(fontSize: 18)),
            ),
          ),
        ),
      ),
    );
  }
}

class _PayField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String suffix;
  final VoidCallback onChanged;

  const _PayField({
    required this.controller,
    required this.label,
    required this.onChanged,
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
      ],
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix.isEmpty ? null : suffix,
      ),
      onChanged: (_) => onChanged(),
    );
  }
}
