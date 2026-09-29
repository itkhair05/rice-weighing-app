import 'package:riverpod/riverpod.dart';
export '../repositories/app_repository.dart';

import '../models/weighing.dart';
import '../repositories/app_repository.dart';

final sessionsProvider = FutureProvider<List<WeighingSession>>((ref) async {
  final repo = ref.read(appRepositoryProvider);
  return repo.getSessions();
});

final todayStatsProvider = FutureProvider<SessionStats>((ref) async {
  final repo = ref.read(appRepositoryProvider);
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day);
  return repo.getStats(start, now);
});

final monthStatsProvider = FutureProvider<SessionStats>((ref) async {
  final repo = ref.read(appRepositoryProvider);
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, 1);
  return repo.getStats(start, now);
});

final defaultsProvider = FutureProvider<Map<String, String>>((ref) async {
  final repo = ref.read(appRepositoryProvider);
  return {
    'bags_per_set': await repo.getSetting('bags_per_set', defaultValue: '5'),
    'deduct_per_bag':
        await repo.getSetting('deduct_per_bag', defaultValue: '0'),
    'price_per_kg': await repo.getSetting('price_per_kg', defaultValue: ''),
  };
});
