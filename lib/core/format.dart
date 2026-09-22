/// Format số dùng chung toàn app (UI chỉ hiển thị, không tự tính).
String fmtKg(double v) {
  var s = v.toStringAsFixed(2);
  s = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  return s.isEmpty ? '0' : s;
}

/// 4900000 -> "4.900.000"
String fmtMoney(int v) =>
    v.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.');

String fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
