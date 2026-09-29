import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';

class OwnerPromptResult {
  final String owner;
  final String riceVariety;
  OwnerPromptResult(this.owner, this.riceVariety);
}

/// Hỏi tên chủ ruộng và giống lúa trước khi vào màn cân.
/// Trả về kết quả hoặc null nếu hủy.
Future<OwnerPromptResult?> promptOwnerName(
  BuildContext context,
  WidgetRef ref, {
  String initialOwner = '',
  String initialVariety = '',
}) async {
  final repo = ref.read(appRepositoryProvider);
  final lastOwner = await repo.getSetting('last_owner');
  final lastVariety = await repo.getSetting('last_variety');
  if (!context.mounted) return null;
  final ownerController = TextEditingController(text: initialOwner);
  final varietyController = TextEditingController(text: initialVariety);
  final result = await showDialog<OwnerPromptResult>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: const Text('Thông tin lần cân'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            autofocus: initialOwner.isEmpty,
            controller: ownerController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Tên chủ ruộng / Lái',
              hintText: 'Ví dụ: Bà Tư',
              border: const OutlineInputBorder(),
              helperText: lastOwner.isEmpty ? null : 'Lần trước: $lastOwner',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: varietyController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Giống lúa',
              hintText: 'Ví dụ: OM18',
              border: const OutlineInputBorder(),
              helperText: lastVariety.isEmpty ? null : 'Lần trước: $lastVariety',
            ),
            onSubmitted: (v) => Navigator.pop(
              ctx,
              OwnerPromptResult(
                ownerController.text.trim(),
                v.trim(),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            ctx,
            OwnerPromptResult(
              ownerController.text.trim(),
              varietyController.text.trim(),
            ),
          ),
          child: const Text('Xong'),
        ),
      ],
    ),
  );
  if (result == null || (result.owner.isEmpty && result.riceVariety.isEmpty)) {
    return null;
  }
  return result;
}
