import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_theme.dart';
import '../core/format.dart';
import '../models/weighing.dart';
import '../providers/app_providers.dart';
import '../widgets/common.dart';
import 'payment_screen.dart';
import 'session_detail_screen.dart';

class WeighingScreen extends ConsumerStatefulWidget {
  const WeighingScreen({super.key, this.session, this.owner = ''});

  final WeighingSession? session;
  final String owner;

  @override
  ConsumerState<WeighingScreen> createState() => _WeighingScreenState();
}

class _WeighingScreenState extends ConsumerState<WeighingScreen> {
  final _controllers = <List<TextEditingController>>[];
  final _focus = <List<FocusNode>>[];
  final _setTotals = <ValueNotifier<double>>[];
  final _grandTotal = ValueNotifier<double>(0);
  int _defaultBagsPerSet = 5;
  late String _owner;
  final _noteController = TextEditingController();
  bool _loaded = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _owner = widget.session?.owner ?? widget.owner;
    _initFromSessionOrDefaults();
  }

  Future<void> _initFromSessionOrDefaults() async {
    final session = widget.session;
    if (session != null) {
      _noteController.text = session.note;
      for (final set in session.sets) {
        _controllers.add([
          for (final bag in set.bags)
            TextEditingController(text: fmtKg(bag.weightKg)),
        ]);
        _focus.add([for (final _ in set.bags) FocusNode()]);
        _setTotals.add(ValueNotifier<double>(0));
      }
      _recomputeTotals();
      setState(() => _loaded = true);
      return;
    }
    final defaults = await ref.read(defaultsProvider.future);
    _defaultBagsPerSet = int.tryParse(defaults['bags_per_set'] ?? '') ?? 5;
    _addSet();
    setState(() => _loaded = true);
  }

  void _addSet() {
    setState(() {
      _controllers.add([
        for (var i = 0; i < _defaultBagsPerSet; i++) TextEditingController(),
      ]);
      _focus.add([for (var i = 0; i < _defaultBagsPerSet; i++) FocusNode()]);
      _setTotals.add(ValueNotifier<double>(0));
    });
    _recomputeTotals();
  }

  void _removeSet(int index) {
    setState(() {
      for (final c in _controllers[index]) {
        c.dispose();
      }
      for (final f in _focus[index]) {
        f.dispose();
      }
      _setTotals[index].dispose();
      _controllers.removeAt(index);
      _focus.removeAt(index);
      _setTotals.removeAt(index);
    });
    _recomputeTotals();
  }

  void _addBag(int setIndex) {
    setState(() {
      _controllers[setIndex].add(TextEditingController());
      _focus[setIndex].add(FocusNode());
    });
    _recomputeTotals();
    _focus[setIndex].last.requestFocus();
  }

  void _removeBag(int setIndex, int bagIndex) {
    setState(() {
      _controllers[setIndex][bagIndex].dispose();
      _focus[setIndex][bagIndex].dispose();
      _controllers[setIndex].removeAt(bagIndex);
      _focus[setIndex].removeAt(bagIndex);
    });
    _recomputeTotals();
  }

  double _setTotal(int index) => _controllers[index].fold(
        0,
        (sum, c) => sum + (double.tryParse(c.text.replaceAll(',', '.')) ?? 0),
      );

  void _recomputeTotals() {
    var grand = 0.0;
    for (var i = 0; i < _controllers.length; i++) {
      final t = _setTotal(i);
      _setTotals[i].value = t;
      grand += t;
    }
    _grandTotal.value = grand;
  }

  int get _totalBags => _controllers.fold(0, (sum, set) => sum + set.length);

  void _onBagChanged(int setIndex, int bagIndex, String text) {
    final formatted = _autoFormat(text);
    if (formatted != null) {
      _controllers[setIndex][bagIndex].text = formatted;
      _controllers[setIndex][bagIndex].selection = TextSelection.collapsed(
        offset: formatted.length,
      );
      if (bagIndex + 1 < _controllers[setIndex].length) {
        _focus[setIndex][bagIndex + 1].requestFocus();
      } else if (setIndex + 1 < _controllers.length &&
          _controllers[setIndex + 1].isNotEmpty) {
        _focus[setIndex + 1][0].requestFocus();
      }
    }
    _recomputeTotals();
  }

  /// "452" -> "45.2". Trả về null nếu không cần sửa.
  static String? _autoFormat(String text) {
    final t = text.replaceAll(',', '.');
    if (t.contains('.') || t.isEmpty || t.length < 3) return null;
    if (!RegExp(r'^\d{3,}$').hasMatch(t)) return null;
    return '${t.substring(0, t.length - 1)}.${t.substring(t.length - 1)}';
  }

  WeighingSession _buildSession() {
    final sets = <WeighingSet>[];
    for (final setControllers in _controllers) {
      final bags = <Bag>[];
      for (final c in setControllers) {
        final v = double.tryParse(c.text.replaceAll(',', '.'));
        if (v != null && v > 0) {
          bags.add(Bag(id: 0, setId: 0, weightKg: v));
        }
      }
      if (bags.isNotEmpty) {
        sets.add(WeighingSet(id: 0, sessionId: 0, bags: bags));
      }
    }
    return WeighingSession(
      id: widget.session?.id ?? 0,
      date: widget.session?.date ?? DateTime.now(),
      bagsPerSet: _defaultBagsPerSet,
      deductPerBag: widget.session?.deductPerBag ?? 0,
      deductTotalKg: widget.session?.deductTotalKg ?? 0,
      pricePerKg: widget.session?.pricePerKg ?? 0,
      owner: _owner.trim(),
      note: _noteController.text.trim(),
      sets: sets,
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await _doSave();
    } catch (e) {
      debugPrint('Lỗi lưu lần cân: $e');
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

  Future<void> _doSave() async {
    for (var i = 0; i < _controllers.length; i++) {
      for (var j = 0; j < _controllers[i].length; j++) {
        final text = _controllers[i][j].text.trim();
        if (text.isNotEmpty &&
            double.tryParse(text.replaceAll(',', '.')) == null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text('Set ${i + 1}, bao ${j + 1}: "$text" không phải số'),
          ));
          return;
        }
      }
    }
    final session = _buildSession();
    if (session.sets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa nhập bao nào')),
      );
      return;
    }
    final repo = ref.read(appRepositoryProvider);
    if (widget.session == null) {
      final id = await repo.addSession(session);
      await repo.setSetting('bags_per_set', '$_defaultBagsPerSet');
      await repo.setSetting('last_owner', _owner.trim());
      ref.invalidate(sessionsProvider);
      ref.invalidate(todayStatsProvider);
      ref.invalidate(monthStatsProvider);
      if (!mounted) return;
      final goPay = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Đã lưu lần cân'),
          content: const Text('Bạn có muốn tính tiền luôn không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Để sau'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Tính tiền'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (goPay == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentScreen(
              sessionId: id,
              showDetailAfterSave: true,
            ),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SessionDetailScreen(sessionId: id),
          ),
        );
      }
    } else {
      await repo.updateSession(session);
      ref.invalidate(sessionsProvider);
      ref.invalidate(todayStatsProvider);
      ref.invalidate(monthStatsProvider);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    for (final set in _controllers) {
      for (final c in set) {
        c.dispose();
      }
    }
    for (final set in _focus) {
      for (final f in set) {
        f.dispose();
      }
    }
    for (final n in _setTotals) {
      n.dispose();
    }
    _grandTotal.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: LoadingView());
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.session == null
            ? 'Cân lúa — $_owner'
            : 'Sửa lần cân'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(Spacing.l),
        children: [
          for (var i = 0; i < _controllers.length; i++)
            _SetCard(
              key: ValueKey('set_$i'),
              index: i,
              controllers: _controllers[i],
              focus: _focus[i],
              total: _setTotals[i],
              onRemove: () => _removeSet(i),
              onAddBag: () => _addBag(i),
              onRemoveBag: (bagIndex) => _removeBag(i, bagIndex),
              onChanged: (bagIndex, text) => _onBagChanged(i, bagIndex, text),
            ),
          Padding(
            padding: const EdgeInsets.only(top: Spacing.s),
            child: OutlinedButton.icon(
              onPressed: _addSet,
              icon: const Icon(Icons.add, size: 26),
              label: const Text('Thêm set', style: TextStyle(fontSize: 18)),
            ),
          ),
          if (widget.session == null) ...[
            const SizedBox(height: Spacing.s),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Ghi chú (không bắt buộc)',
              ),
            ),
          ],
          if (widget.session == null)
            Padding(
              padding: const EdgeInsets.only(top: Spacing.s, left: Spacing.xs),
              child: Text(
                'Gõ 3 số sẽ tự thành số lẻ (452 → 45.2) và nhảy sang bao kế tiếp.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ),
          const SizedBox(height: Spacing.xl),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border:
                Border(top: BorderSide(color: Colors.grey.shade300)),
          ),
          padding: const EdgeInsets.fromLTRB(
              Spacing.l, Spacing.m, Spacing.l, Spacing.l),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ValueListenableBuilder<double>(
                valueListenable: _grandTotal,
                builder: (context, total, _) => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('TỔNG CÂN', style: AppTheme.label),
                    const SizedBox(width: Spacing.m),
                    Text(
                      '${fmtKg(total)} kg • $_totalBags bao',
                      style: AppTheme.numberL,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Spacing.m),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child:
                              CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.save, size: 28),
                  label: Text(_saving ? 'Đang lưu...' : 'Lưu lần cân',
                      style: const TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SetCard extends StatelessWidget {
  final int index;
  final List<TextEditingController> controllers;
  final List<FocusNode> focus;
  final ValueNotifier<double> total;
  final VoidCallback onRemove;
  final VoidCallback onAddBag;
  final ValueChanged<int> onRemoveBag;
  final void Function(int bagIndex, String text) onChanged;

  const _SetCard({
    super.key,
    required this.index,
    required this.controllers,
    required this.focus,
    required this.total,
    required this.onRemove,
    required this.onAddBag,
    required this.onRemoveBag,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: Spacing.m),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.m, vertical: Spacing.xs),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Set ${index + 1}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Xóa set',
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: onRemove,
                ),
              ],
            ),
            for (var i = 0; i < controllers.length; i++)
              _BagField(
                bagNumber: i + 1,
                controller: controllers[i],
                focusNode: focus[i],
                onRemove: controllers.length > 1 ? () => onRemoveBag(i) : null,
                onChanged: (text) => onChanged(i, text),
              ),
            const SizedBox(height: Spacing.xs),
            Row(
              children: [
                Expanded(
                  child: ValueListenableBuilder<double>(
                    valueListenable: total,
                    builder: (context, t, _) => Text(
                      'Tổng set: ${fmtKg(t)} kg',
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: onAddBag,
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Thêm bao'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BagField extends StatelessWidget {
  final int bagNumber;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback? onRemove;
  final ValueChanged<String> onChanged;

  const _BagField({
    required this.bagNumber,
    required this.controller,
    required this.focusNode,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text('Bao $bagNumber', style: const TextStyle(fontSize: 17)),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: TextInputType.number,
              inputFormatters: [_DecimalFormatter()],
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w600),
              scrollPadding: const EdgeInsets.all(Spacing.xxl),
              decoration: const InputDecoration(
                hintText: '0',
                suffixText: 'kg',
              ),
              onChanged: onChanged,
            ),
          ),
          SizedBox(
            width: 44,
            child: onRemove == null
                ? const SizedBox.shrink()
                : IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    tooltip: 'Bỏ bao này',
                    onPressed: onRemove,
                  ),
          ),
        ],
      ),
    );
  }
}

/// Chỉ cho số và 1 dấu chấm.
class _DecimalFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final t = newValue.text.replaceAll(',', '.');
    var allowed = t.replaceAll(RegExp(r'[^0-9.]'), '');
    final firstDot = allowed.indexOf('.');
    if (firstDot != -1) {
      allowed = allowed.substring(0, firstDot + 1) +
          allowed.substring(firstDot + 1).replaceAll('.', '');
    }
    if (allowed == newValue.text) return newValue;
    return TextEditingValue(
      text: allowed,
      selection: TextSelection.collapsed(offset: allowed.length),
    );
  }
}
