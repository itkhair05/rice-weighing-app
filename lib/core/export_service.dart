import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../models/weighing.dart';

class _PdfFonts {
  final pw.Font regular;
  final pw.Font bold;

  const _PdfFonts(this.regular, this.bold);

  static Future<_PdfFonts> load() async {
    final reg =
        pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
    final bold =
        pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Bold.ttf'));
    return _PdfFonts(reg, bold);
  }
}

class ExportService {
  static String _dateStr(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  static String _kg(double v) =>
      v.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');

  static String fmtMoneyInt(int v) =>
      v.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.');

  static String buildCsv(List<WeighingSession> sessions) {
    final sb = StringBuffer();
    sb.writeln(
        'Ngay,Set,So bao,Tong kg,Tru bao,Thuc nhan kg,Gia (dong/kg),Thanh tien,Ghi chu');
    for (final s in sessions) {
      for (var i = 0; i < s.sets.length; i++) {
        final set = s.sets[i];
        sb.writeln(
          '${_dateStr(s.date)},${i + 1},${set.bags.length},'
          '${_kg(set.totalKg)},${_kg(set.bags.length * s.deductPerBag)},'
          '${_kg(set.realKg(s.deductPerBag))},'
          '${s.isPaid ? s.pricePerKg.round() : ""},'
          '${s.isPaid ? s.totalMoney : ""},'
          '"${s.note.replaceAll('"', '""')}"',
        );
      }
      sb.writeln(
        '${_dateStr(s.date)},TONG,${s.totalBags},${_kg(s.totalKg)},'
        '${_kg(s.totalDeductKg)},${_kg(s.totalRealKg)},'
        '${s.isPaid ? s.pricePerKg.round() : ""},'
        '${s.isPaid ? s.totalMoney : ""},'
        '"${s.note.replaceAll('"', '""')}"',
      );
    }
    return sb.toString();
  }

  static Future<File> writeCsvFile(List<WeighingSession> sessions) async {
    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/can_lua_${DateTime.now().millisecondsSinceEpoch}.csv');
    // BOM giúp Excel nhận diện UTF-8, hiển thị đúng tiếng Việt.
    return file.writeAsString('\uFEFF${buildCsv(sessions)}');
  }

  static Future<void> shareCsv(List<WeighingSession> sessions) async {
    final file = await writeCsvFile(sessions);
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
  }

  static Future<void> sharePdf(List<WeighingSession> sessions) async {
    final file = await _buildPdfFile(sessions);
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
  }

  static Future<void> printPdf(List<WeighingSession> sessions) async {
    final doc = await _buildPdfDoc(sessions);
    await Printing.layoutPdf(onLayout: (_) => doc.save());
  }

  static Future<File> _buildPdfFile(List<WeighingSession> sessions) async {
    final doc = await _buildPdfDoc(sessions);
    final dir = await getTemporaryDirectory();
    final owner =
        sessions.length == 1 && sessions.first.owner.isNotEmpty
            ? '_${sessions.first.owner.replaceAll(RegExp(r'\s+'), '_')}'
            : '';
    final file = File(
        '${dir.path}/can_lua${owner}_${DateTime.now().millisecondsSinceEpoch}.pdf');
    return file.writeAsBytes(await doc.save());
  }

  static Future<pw.Document> _buildPdfDoc(
      List<WeighingSession> sessions) async {
    final fonts = await _PdfFonts.load();
    pw.TextStyle style({
      double? fontSize,
      pw.FontWeight? fontWeight,
    }) =>
        pw.TextStyle(
          font: fonts.regular,
          fontBold: fonts.bold,
          fontSize: fontSize,
          fontWeight: fontWeight,
        );

    final doc = pw.Document();
    final totalBags =
        sessions.fold<int>(0, (sum, s) => sum + s.totalBags);
    final totalKg = sessions.fold<double>(0, (sum, s) => sum + s.totalKg);
    final totalRealKg =
        sessions.fold<double>(0, (sum, s) => sum + s.totalRealKg);

    for (final s in sessions) {
      final dateStr = _dateStr(s.date);
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a5,
          build: (context) {
            final rows = <List<String>>[
              ['Set', 'Số bao', 'Tổng kg', 'Trừ bao', 'Thực nhận'],
            ];
            for (var i = 0; i < s.sets.length; i++) {
              final set = s.sets[i];
              rows.add([
                '${i + 1}',
                '${set.bags.length}',
                _kg(set.totalKg),
                _kg(set.bags.length * s.deductPerBag),
                _kg(set.realKg(s.deductPerBag)),
              ]);
            }
            rows.add([
              'TỔNG',
              '${s.totalBags}',
              _kg(s.totalKg),
              _kg(s.totalDeductKg),
              _kg(s.totalRealKg),
            ]);
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text('CÂN LÚA GIA ĐÌNH',
                      style: style(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                ),
                pw.Center(
                  child: pw.Text('Ngày: $dateStr',
                      style: style(fontSize: 14)),
                ),
                if (s.owner.isNotEmpty)
                  pw.Center(
                    child: pw.Text('Chủ ruộng: ${s.owner}',
                        style: style(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  ),
                if (s.note.isNotEmpty) pw.Center(child: pw.Text(s.note, style: style())),
                pw.SizedBox(height: 12),
                pw.TableHelper.fromTextArray(
                  data: rows,
                  headerStyle: style(fontWeight: pw.FontWeight.bold),
                  cellStyle: style(fontSize: 11),
                  border: pw.TableBorder.all(width: 0.5),
                ),
                if (s.isPaid) ...[
                  pw.SizedBox(height: 8),
                  pw.Text('Giá: ${s.pricePerKg.round()} đ/kg',
                      style: style()),
                  pw.Text(
                    'THÀNH TIỀN: ${fmtMoneyInt(s.totalMoney)} đ',
                    style: style(fontSize: 15, fontWeight: pw.FontWeight.bold),
                  ),
                ],
                pw.Spacer(),
                if (sessions.length > 1)
                  pw.Text(
                    'TỔNG CỘNG TOÀN BỘ: $totalBags bao — '
                    '${_kg(totalKg)} kg — Thực nhận ${_kg(totalRealKg)} kg',
                    style: style(fontSize: 13, fontWeight: pw.FontWeight.bold),
                  ),
                pw.SizedBox(height: 8),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    '© 2026 Thế Khải — Cân Lúa Gia Đình',
                    style: style(fontSize: 9),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }
    return doc;
  }
}
