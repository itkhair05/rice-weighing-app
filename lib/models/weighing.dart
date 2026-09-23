class Bag {
  final int id;
  final int setId;
  final double weightKg;

  const Bag({
    required this.id,
    required this.setId,
    required this.weightKg,
  });

  factory Bag.fromMap(Map<String, dynamic> map) => Bag(
        id: map['id'] as int,
        setId: map['set_id'] as int,
        weightKg: (map['weight_kg'] as num).toDouble(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'set_id': setId,
        'weight_kg': weightKg,
      };
}

class WeighingSet {
  final int id;
  final int sessionId;
  final List<Bag> bags;

  const WeighingSet({
    required this.id,
    required this.sessionId,
    required this.bags,
  });

  double get totalKg => bags.fold(0, (sum, b) => sum + b.weightKg);

  double realKg(double deductPerBag) =>
      totalKg - bags.length * deductPerBag;

  factory WeighingSet.fromMap(Map<String, dynamic> map, List<Bag> bags) =>
      WeighingSet(
        id: map['id'] as int,
        sessionId: map['session_id'] as int,
        bags: bags,
      );
}

class WeighingSession {
  final int id;
  final DateTime date;
  final int bagsPerSet;
  final double deductPerBag;
  final double deductTotalKg;
  final double pricePerKg;
  final String owner;
  final String note;
  final List<WeighingSet> sets;

  const WeighingSession({
    required this.id,
    required this.date,
    required this.bagsPerSet,
    this.deductPerBag = 0,
    this.deductTotalKg = 0,
    this.pricePerKg = 0,
    this.owner = '',
    required this.note,
    required this.sets,
  });

  bool get isPaid => pricePerKg > 0;

  int get totalBags => sets.fold(0, (sum, s) => sum + s.bags.length);

  double get totalKg => sets.fold(0, (sum, s) => sum + s.totalKg);

  double get totalDeductKg => totalBags * deductPerBag + deductTotalKg;

  double get totalRealKg => totalKg - totalDeductKg;

  int get totalMoney => (totalRealKg * pricePerKg).round();
}

class SessionStats {
  final int bags;
  final double totalKg;
  final int totalMoney;

  const SessionStats({
    required this.bags,
    required this.totalKg,
    this.totalMoney = 0,
  });
}
