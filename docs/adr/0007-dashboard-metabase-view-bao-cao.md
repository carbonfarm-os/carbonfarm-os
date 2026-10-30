<!-- SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors -->
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->
# 0007 · Dashboard Metabase trên view báo cáo chỉ đọc

- Trạng thái: chấp nhận
- Ngày: 2026-10-30
- Người viết: @Minhthuan12
- Issue / PR: #39

## Bối cảnh
ADR 0002 đã chọn Metabase OSS (AGPL-3.0, dịch vụ riêng) cho dashboard. Còn phải quyết định ba điều:
1. Metabase đọc dữ liệu bằng quyền gì;
2. dashboard được tạo ra sao để dựng từ volume trống là có;
3. Metabase lưu cấu hình ở đâu.

## Quyết định
- **Đọc qua view báo cáo:** schema `carbon_bao_cao` (migration 006) chỉ gồm view tổng hợp:
  - tổng quan hợp tác xã;
  - kết quả MRV;
  - tín chỉ cấp/bán/trong ví, doanh thu;
  - giao dịch bán.

  Không có họ tên xã viên, `sub`, ranh giới lô. Vai `carbon_bao_cao` chỉ có `USAGE` schema này + `SELECT` các view, `default_transaction_read_only = on`; không đọc được bảng gốc (Hurl kiểm "permission denied").
- **Dựng dashboard bằng mã:** `domains/carbon/dashboard/dung_dashboard.py` (thư viện chuẩn) gọi API Metabase:
  - lần đầu hoàn tất cài đặt (tài khoản quản trị, mật khẩu OpenBao), nối PostgreSQL bằng vai chỉ đọc;
  - tạo 7 thẻ SQL + dashboard;
  - chạy lại thì bỏ qua.

  Dashboard là mã trong repo, xem xét được qua PR, không phải thao tác tay trên UI.
- **CSDL nội bộ của Metabase:** H2 trong volume `metabase-du-lieu`. Đủ cho demo, không trộn cấu hình Metabase vào PostgreSQL của nền tảng (Tầng 1 không chứa thứ của miền).
- **UI chỉ mở ở `127.0.0.1:3001`**, như Prefect UI. Demo công khai đặt sau proxy có xác thực (#40).

## Phương án loại
- **Cho Metabase đăng nhập bằng vai có RLS** (`vai_nguoi_dung`): Metabase dùng một kết nối chung, không mang JWT của từng người → RLS không có tác dụng; view tổng hợp rõ ràng hơn.
- **Lưu cấu hình Metabase trong PostgreSQL nền tảng:** phải tạo CSDL riêng ở Tầng 1 cho một dịch vụ của miền.

## Hệ quả
- Muốn thêm chỉ số: thêm view (migration mới) + thẻ trong script; dashboard đã có thì script bỏ qua. Cần xóa dashboard hoặc tăng tên/phiên bản để dựng lại – ghi nhận để làm sau nếu cần.
- H2 không hợp cho vận hành thật; khi triển khai thật chuyển `MB_DB_*` sang PostgreSQL riêng.
