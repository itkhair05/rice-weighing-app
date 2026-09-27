import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

import 'database_helper.dart';

class BackupService {
  static Future<File> _dbFile() async {
    final helper = await DatabaseHelper.instance;
    return File(helper.path);
  }

  static Future<void> backup() async {
    final dbFile = await _dbFile();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final dir = await Directory.systemTemp.createTemp();
    final copy = File(p.join(dir.path, 'can_lua_gia_dinh_$stamp.db'));
    await dbFile.copy(copy.path);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(copy.path)],
        subject: 'Backup dữ liệu Cân Lúa Gia Đình',
      ),
    );
  }

  /// Returns an error message, or null on success.
  /// The DB is closed before copying; the next access reopens it fresh.
  static Future<String?> restore() async {
    final picked = await FilePicker.pickFile();
    if (picked == null || picked.path == null) return null;
    final file = File(picked.path!);
    if (!p.extension(file.path).toLowerCase().endsWith('.db')) {
      return 'File phải có đuôi .db';
    }
    final helper = await DatabaseHelper.instance;
    await helper.close();
    final dbFile = await _dbFile();
    await file.copy(dbFile.path);
    return null;
  }

  static Future<void> deleteAllData() async {
    final helper = await DatabaseHelper.instance;
    final db = helper.db;
    await db.transaction((txn) async {
      await txn.delete('bags');
      await txn.delete('weighing_sets');
      await txn.delete('weighing_sessions');
      await txn.delete('sales');
      await txn.delete('rice_batches');
      await txn.delete('app_settings');
    });
  }
}
