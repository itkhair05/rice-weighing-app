import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hướng dẫn sử dụng')),
      body: ListView(
        padding: const EdgeInsets.all(Spacing.l),
        children: const [
          _HelpSection(
            icon: Icons.scale,
            title: 'Cân lúa',
            items: [
              'Bấm nút "Bắt đầu cân" ở Trang chủ hoặc tab "Cân lúa" bên dưới.',
              'Nhập tên chủ ruộng (app sẽ nhớ tên cũ cho lần sau).',
              'Nhập cân nặng từng bao — app tự thêm dấu chấm thập phân '
                  '(gõ "452" sẽ thành "45,2"). Xong bao cuối, ô mới tự hiện.',
              'Có thể thêm set mới, thêm/bớt bao, xóa set tùy ý.',
              'Bấm "LƯU LẦN CÂN" để lưu lại toàn bộ lần cân.',
            ],
          ),
          _HelpSection(
            icon: Icons.payments,
            title: 'Tính tiền',
            items: [
              'Sau khi lưu lần cân, app hỏi "Tính tiền luôn?" — chọn Có để tính ngay.',
              'Nhập giá lúa (đ/kg).',
              'Chọn cách trừ bao: Không trừ, Trừ theo kg/bao, hoặc Trừ tổng kg.',
              'Khối lượng tính tiền và THÀNH TIỀN tự động cập nhật bên dưới.',
              'Bấm "LƯU THANH TOÁN" để hoàn tất.',
            ],
          ),
          _HelpSection(
            icon: Icons.history,
            title: 'Lịch sử & Chi tiết',
            items: [
              'Tab "Lịch sử" hiện tất cả lần cân, bấm vào để xem chi tiết từng bao.',
              'Ở Chi tiết: bấm hình bút chì để sửa bao lúa, ghi chú.',
              'Bấm "TÍNH TIỀN" / "SỬA TÍNH TIỀN" để tính lại tiền bất cứ lúc nào '
                  'khi nhập nhầm số.',
              'Từ Chi tiết có thể xuất PDF, CSV hoặc in ngay lần cân đó.',
            ],
          ),
          _HelpSection(
            icon: Icons.backup,
            title: 'Sao lưu & Khôi phục',
            items: [
              'Sao lưu: lưu toàn bộ dữ liệu thành file .db để gửi qua Zalo, '
                  'email, Drive... Nên sao lưu thường xuyên!',
              'Khôi phục: chọn file backup (.db) đã lưu trước đó. Dữ liệu mới '
                  'sẽ được thay bằng dữ liệu trong file backup.',
              'Sau khi khôi phục, app tự cập nhật dữ liệu mới ngay, '
                  'không cần thoát app.',
              'Lưu ý: file backup chứa toàn bộ lịch sử cân, hãy giữ cẩn thận.',
            ],
          ),
          _HelpSection(
            icon: Icons.table_view,
            title: 'Xuất CSV / PDF',
            items: [
              'CSV: mở bằng Excel để xem lại hoặc tính toán thêm.',
              'PDF: định dạng sẵn để in hoặc gửi cho người mua, kèm tên chủ ruộng.',
            ],
          ),
          _HelpSection(
            icon: Icons.delete_forever,
            title: 'Xóa dữ liệu',
            items: [
              '"Xóa toàn bộ dữ liệu" xóa MỌI lần cân — không thể hoàn tác.',
              'Hãy sao lưu trước khi xóa!',
            ],
          ),
        ],
      ),
    );
  }
}

class _HelpSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> items;

  const _HelpSection({
    required this.icon,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: Spacing.m),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: cs.primary, size: 26),
                const SizedBox(width: Spacing.s),
                Text(title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: Spacing.s),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Icon(Icons.circle, size: 6),
                    ),
                    const SizedBox(width: Spacing.s),
                    Expanded(
                        child: Text(item, style: const TextStyle(fontSize: 15))),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
