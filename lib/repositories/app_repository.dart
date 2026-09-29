import 'package:riverpod/riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../core/database_helper.dart';
import '../models/weighing.dart';

class SqlAppRepository {}

final appRepositoryProvider = Provider<SqlAppRepository>((ref) {
  return SqlAppRepository();
});
// ---------- Weighing sessions (Phase 2) ----------

extension WeighingRepository on SqlAppRepository {
  Future<List<WeighingSession>> getSessions(
      {DateTime? from, DateTime? to}) async {
    final dbHelper = await DatabaseHelper.instance;
    final db = dbHelper.db;
    final result = await db.query(
      'weighing_sessions',
      where: from != null || to != null ? 'date >= ? AND date <= ?' : null,
      whereArgs: from != null || to != null
          ? [
              from?.millisecondsSinceEpoch ?? 0,
              to?.millisecondsSinceEpoch ??
                  DateTime.now().millisecondsSinceEpoch,
            ]
          : null,
      orderBy: 'date DESC',
    );
    if (result.isEmpty) return [];
    final sessionIds = result.map((r) => r['id'] as int).toList();
    final placeholders = List.filled(sessionIds.length, '?').join(',');

    // 3 truy vấn cho toàn bộ danh sách thay vì N+1.
    final allSets = await db.query(
      'weighing_sets',
      where: 'session_id IN ($placeholders)',
      whereArgs: sessionIds,
      orderBy: 'id ASC',
    );
    final setIds = allSets.map((r) => r['id'] as int).toList();
    final allBags = setIds.isEmpty
        ? const <Map<String, Object?>>[]
        : await db.query(
            'bags',
            where: 'set_id IN (${List.filled(setIds.length, '?').join(',')})',
            whereArgs: setIds,
            orderBy: 'id ASC',
          );

    final bagsBySet = <int, List<Bag>>{};
    for (final b in allBags) {
      bagsBySet.putIfAbsent(b['set_id'] as int, () => []).add(Bag.fromMap(b));
    }
    final setsBySession = <int, List<WeighingSet>>{};
    for (final s in allSets) {
      final setId = s['id'] as int;
      setsBySession
          .putIfAbsent(s['session_id'] as int, () => [])
          .add(WeighingSet.fromMap(s, bagsBySet[setId] ?? const []));
    }

    final sessions = <WeighingSession>[];
    for (final row in result) {
      final sessionId = row['id'] as int;
      sessions.add(WeighingSession(
        id: sessionId,
        date: DateTime.fromMillisecondsSinceEpoch(row['date'] as int),
        bagsPerSet: row['bags_per_set'] as int,
        deductPerBag: (row['deduct_per_bag'] as num).toDouble(),
        deductTotalKg: (row['deduct_total'] as num?)?.toDouble() ?? 0,
        pricePerKg: (row['price_per_kg'] as num?)?.toDouble() ?? 0,
        owner: (row['owner'] as String?) ?? '',
        riceVariety: (row['rice_variety'] as String?) ?? '',
        deposit: (row['deposit'] as num?)?.toDouble() ?? 0,
        note: (row['note'] as String?) ?? '',
        sets: setsBySession[sessionId] ?? const [],
      ));
    }
    return sessions;
  }

  Future<WeighingSession?> getSession(int id) async {
    final dbHelper = await DatabaseHelper.instance;
    final db = dbHelper.db;
    final rows = await db.query(
      'weighing_sessions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final row = rows.first;
    final setsResult = await db.query(
      'weighing_sets',
      where: 'session_id = ?',
      whereArgs: [id],
      orderBy: 'id ASC',
    );
    final setIds = setsResult.map((r) => r['id'] as int).toList();
    final allBags = setIds.isEmpty
        ? const <Map<String, Object?>>[]
        : await db.query(
            'bags',
            where: 'set_id IN (${List.filled(setIds.length, '?').join(',')})',
            whereArgs: setIds,
            orderBy: 'id ASC',
          );
    final bagsBySet = <int, List<Bag>>{};
    for (final b in allBags) {
      bagsBySet.putIfAbsent(b['set_id'] as int, () => []).add(Bag.fromMap(b));
    }
    final sets = setsResult
        .map((s) =>
            WeighingSet.fromMap(s, bagsBySet[s['id'] as int] ?? const []))
        .toList();
    return WeighingSession(
      id: id,
      date: DateTime.fromMillisecondsSinceEpoch(row['date'] as int),
      bagsPerSet: row['bags_per_set'] as int,
      deductPerBag: (row['deduct_per_bag'] as num).toDouble(),
      deductTotalKg: (row['deduct_total'] as num?)?.toDouble() ?? 0,
      pricePerKg: (row['price_per_kg'] as num?)?.toDouble() ?? 0,
      owner: (row['owner'] as String?) ?? '',
      riceVariety: (row['rice_variety'] as String?) ?? '',
      deposit: (row['deposit'] as num?)?.toDouble() ?? 0,
      note: (row['note'] as String?) ?? '',
      sets: sets,
    );
  }

  Future<int> addSession(WeighingSession session) async {
    final dbHelper = await DatabaseHelper.instance;
    final db = dbHelper.db;
    return db.transaction((txn) async {
      final sessionId = await txn.insert('weighing_sessions', {
        'date': session.date.millisecondsSinceEpoch,
        'bags_per_set': session.bagsPerSet,
        'deduct_per_bag': session.deductPerBag,
        'deduct_total': session.deductTotalKg,
        'note': session.note,
        'price_per_kg': session.pricePerKg,
        'owner': session.owner,
        'rice_variety': session.riceVariety,
        'deposit': session.deposit,
      });
      for (final set in session.sets) {
        final setId = await txn.insert('weighing_sets', {
          'session_id': sessionId,
        });
        for (final bag in set.bags) {
          await txn.insert('bags', {
            'set_id': setId,
            'weight_kg': bag.weightKg,
          });
        }
      }
      return sessionId;
    });
  }

  Future<int> updateSession(WeighingSession session) async {
    final dbHelper = await DatabaseHelper.instance;
    final db = dbHelper.db;
    return db.transaction((txn) async {
      final count = await txn.update(
        'weighing_sessions',
        {
          'date': session.date.millisecondsSinceEpoch,
          'bags_per_set': session.bagsPerSet,
          'deduct_per_bag': session.deductPerBag,
          'deduct_total': session.deductTotalKg,
          'note': session.note,
          'price_per_kg': session.pricePerKg,
          'owner': session.owner,
          'rice_variety': session.riceVariety,
          'deposit': session.deposit,
        },
        where: 'id = ?',
        whereArgs: [session.id],
      );
      final oldSets = await txn.query(
        'weighing_sets',
        columns: ['id'],
        where: 'session_id = ?',
        whereArgs: [session.id],
      );
      for (final s in oldSets) {
        await txn.delete('bags', where: 'set_id = ?', whereArgs: [s['id']]);
      }
      await txn.delete(
        'weighing_sets',
        where: 'session_id = ?',
        whereArgs: [session.id],
      );
      for (final set in session.sets) {
        final setId = await txn.insert('weighing_sets', {
          'session_id': session.id,
        });
        for (final bag in set.bags) {
          await txn.insert('bags', {
            'set_id': setId,
            'weight_kg': bag.weightKg,
          });
        }
      }
      return count;
    });
  }

  Future<void> updatePayment(
    int sessionId, {
    required double deductPerBag,
    required double deductTotalKg,
    required double pricePerKg,
    required double deposit,
  }) async {
    final dbHelper = await DatabaseHelper.instance;
    await dbHelper.db.update(
      'weighing_sessions',
      {
        'deduct_per_bag': deductPerBag,
        'deduct_total': deductTotalKg,
        'price_per_kg': pricePerKg,
        'deposit': deposit,
      },
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<int> deleteSession(int id) async {
    final dbHelper = await DatabaseHelper.instance;
    final db = dbHelper.db;
    return db.transaction((txn) async {
      final sets = await txn.query(
        'weighing_sets',
        columns: ['id'],
        where: 'session_id = ?',
        whereArgs: [id],
      );
      for (final s in sets) {
        await txn.delete('bags', where: 'set_id = ?', whereArgs: [s['id']]);
      }
      await txn.delete(
        'weighing_sets',
        where: 'session_id = ?',
        whereArgs: [id],
      );
      return txn.delete('weighing_sessions', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<SessionStats> getStats(DateTime from, DateTime to) async {
    final sessions = await getSessions(from: from, to: to);
    var bags = 0;
    var totalKg = 0.0;
    var money = 0;
    for (final s in sessions) {
      bags += s.totalBags;
      totalKg += s.totalRealKg;
      if (s.isPaid) money += s.finalMoney;
    }
    return SessionStats(bags: bags, totalKg: totalKg, totalMoney: money);
  }

  Future<String> getSetting(String key, {String defaultValue = ''}) async {
    final dbHelper = await DatabaseHelper.instance;
    final rows = await dbHelper.db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (rows.isEmpty) return defaultValue;
    return rows.first['value'] as String;
  }

  Future<void> setSetting(String key, String value) async {
    final dbHelper = await DatabaseHelper.instance;
    await dbHelper.db.insert(
      'app_settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
