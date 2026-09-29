# Cân Lúa Gia Đình 🌾

Ứng dụng Flutter giúp ghi chép cân lúa theo bao **hoàn toàn offline** — dành cho hộ nông dân thu mua lúa nhỏ lẻ. Không cần internet, không tài khoản, dữ liệu lưu ngay trên máy.

© 2026 **Thế Khải**. All rights reserved.

## Tính năng

- **Cân lúa**: nhập cân nặng từng bao, chia theo set (mặc định 5 bao/set), tính tổng kg tự động.
- **Tính tiền**: 3 chế độ trừ bao (trừ cân mỗi bao, trừ số kg cố định, không trừ) + giá/lít giá theo kg → thành tiền và số tiền thực nhận.
- **Lịch sử**: xem lại mọi lần cân, lọc theo ngày, xem chi tiết từng set/bao, cho phép **sửa lại bao lúa, ghi chú và tính tiền** nếu nhập nhầm.
- **Thống kê**: tổng bao / tổng kg / tổng tiền trong ngày và trong tháng.
- **Xuất dữ liệu**: chia sẻ **CSV** (mở tốt bằng Excel, hỗ trợ tiếng Việt) và **PDF** (font tiếng Việt, có tên chủ ruộng từng lần cân).
- **Sao lưu & Khôi phục**: xuất toàn bộ dữ liệu ra file `.db` và khôi phục lại bất cứ lúc nào — app cập nhật ngay không cần khởi động lại.
- **Hướng dẫn sử dụng** tích hợp trong mục Cài đặt.

## Công nghệ

- [Flutter](https://flutter.dev) + Material 3
- [flutter_riverpod](https://riverpod.dev) quản lý state
- [sqflite](https://pub.dev/packages/sqflite) — SQLite offline, truy vấn batch tối ưu hiệu năng
- `pdf` / `printing` xuất PDF, `share_plus` chia sẻ file

## Cấu trúc thư mục

```
lib/
├── app/          # Widget gốc ứng dụng
├── core/         # Theme, database, định dạng, xuất file, sao lưu
├── models/       # Model dữ liệu (phiên cân, set, bao)
├── providers/    # Riverpod providers
├── repositories/ # Truy cập SQLite
├── screens/      # Các màn hình
└── widgets/      # Widget dùng chung
```

## Chạy dự án

```bash
flutter pub get
flutter run
```

Build APK release:

```bash
flutter build apk --release
```

## Giấy phép

Dự án phục vụ mục đích học tập và sử dụng cá nhân. Vui lòng không sao chép dưới danh nghĩa khác mà không có sự cho phép của tác giả.
