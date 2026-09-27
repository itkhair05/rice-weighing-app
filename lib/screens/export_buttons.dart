import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/export_service.dart';
import '../models/weighing.dart';

class ExportButtonsRow extends StatelessWidget {
  final WeighingSession session;

  const ExportButtonsRow({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => ExportService.sharePdf([session]),
            icon: const Icon(Icons.picture_as_pdf, size: 22),
            label: const Text('PDF', style: TextStyle(fontSize: 16)),
          ),
        ),
        const SizedBox(width: Spacing.s),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => ExportService.shareCsv([session]),
            icon: const Icon(Icons.table_view, size: 22),
            label: const Text('CSV', style: TextStyle(fontSize: 16)),
          ),
        ),
        const SizedBox(width: Spacing.s),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => ExportService.printPdf([session]),
            icon: const Icon(Icons.print, size: 22),
            label: const Text('In', style: TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }
}
