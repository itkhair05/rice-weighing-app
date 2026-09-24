import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';

/// Hỏi tên chủ ruộng trước khi vào màn cân.
/// Trả về tên (đã trim) hoặc null nếu hủy.
Future<String?> promptOwnerName(BuildContext context, WidgetRef ref) async {
  final repo = ref.read(appRepositoryProvider);
  final lastOwner = await repo.getSetting('last_owner');
  if (!context.mounted) return null;
  final controller = TextEditingController();
  final name = await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: const Text('Tên chủ ruộng'),
      content: TextField(
        autofocus: true,
        controller: controller,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          hintText: 'Ví dụ: Bà Tư',
          border: const OutlineInputBorder(),
          helperText: lastOwner.isEmpty ? null : 'Lần trước: $lastOwner',
        ),
        onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, controller.text.trim()),
          child: const Text('Vào cân'),
        ),
      ],
    ),
  );
  return (name == null || name.isEmpty) ? null : name;
}
