import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/format.dart';

class SectionHeader extends StatelessWidget {
  final String text;

  const SectionHeader(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: Spacing.xs,
        top: Spacing.xl,
        bottom: Spacing.s,
      ),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

/// Số liệu nổi bật: giá trị to + nhãn nhỏ bên dưới/trên.
class AmountText extends StatelessWidget {
  final String value;
  final String? unit;
  final String? label;
  final Color? color;

  const AmountText(
    this.value, {
    super.key,
    this.unit,
    this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (label != null) ...[
          Text(label!, style: AppTheme.label),
          const SizedBox(height: Spacing.xs),
        ],
        Text.rich(
          TextSpan(
            text: value,
            style: AppTheme.numberXL.copyWith(color: color),
            children: [
              if (unit != null)
                TextSpan(
                  text: ' $unit',
                  style: AppTheme.numberL.copyWith(color: color),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: Spacing.l),
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: Colors.grey.shade700)),
            if (message != null) ...[
              const SizedBox(height: Spacing.xs),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
            if (actionLabel != null) ...[
              const SizedBox(height: Spacing.l),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorState({
    super.key,
    this.message = 'Không thể tải dữ liệu',
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: Colors.grey.shade500),
            const SizedBox(height: Spacing.l),
            Text(message, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: Spacing.l),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

/// Hộp thoại xác nhận dùng chung. Trả về true nếu người dùng đồng ý.
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String content,
  String confirmLabel = 'Đồng ý',
  bool destructive = false,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Hủy'),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error)
              : null,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return ok == true;
}

/// Badge trạng thái đã/chưa tính tiền.
class PayBadge extends StatelessWidget {
  final bool paid;

  const PayBadge({super.key, required this.paid});

  @override
  Widget build(BuildContext context) {
    final color = paid ? const Color(0xFF2E7D32) : const Color(0xFFF9A825);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.m, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        paid ? 'Đã tính tiền' : 'Chưa tính tiền',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

/// Hàng nhãn–giá trị, giá trị tự xuống dòng khi dài.
class KeyValueRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  const KeyValueRow(
    this.label,
    this.value, {
    super.key,
    this.bold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: bold ? 20 : 17,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      color: valueColor,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: style),
          const SizedBox(width: Spacing.m),
          Expanded(
            child: Text(value, style: style, textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}

String kg(double v) => '${fmtKg(v)} kg';
