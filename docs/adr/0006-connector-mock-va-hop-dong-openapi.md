<!-- SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors -->
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->
# 0006 · Connector mock và hợp đồng OpenAPI

- Trạng thái: chấp nhận
- Ngày: 2026-10-30
- Người viết: @Minhthuan12
- Issue / PR: #35

## Bối cảnh
Luồng tín chỉ cần ba bên ngoài: Hệ thống đăng ký quốc gia (Registry), người mua, ngân hàng. Chưa có đối tác thật. Mock phải đủ giống để:
- miền carbon viết một lần;
- sau này thay bản thật mà không sửa Tầng 1 hay miền carbon (nguyên lý cắm–rút, BTC #1424).

## Quyết định
- **Ba dịch vụ HTTP** trong `connectors/` (một image, chọn bằng `KET_NOI`):
  - chỉ trong mạng nội bộ;
  - khóa Bearer riêng từng connector do OpenBao sinh;
  - trạng thái trong SQLite ở volume riêng (không dùng chung PostgreSQL của nền tảng – mock phải tách biệt như hệ thống bên ngoài).
- **Hợp đồng = `connectors/<tên>/openapi.yaml`:**
  - viết mô hình bằng FastAPI + pydantic, xuất ra YAML (`task openapi`);
  - CI kiểm tệp không lệch mã (`task test`);
  - bản thật chỉ cần đúng hợp đồng.
- **Registry bám Thông tư 11/2026/TT-BNNMT** (bản PDF chính thức, đọc 30/10/2026):
  - Điều 6: tài khoản gắn mã số thuế, mỗi tổ chức một tài khoản, ≥ 2 đầu mối;
  - Điều 7: tiểu khoản;
  - Điều 10: thông tin đăng ký;
  - Điều 11: mã trong nước và số sê-ri;
  - Điều 20: bù trừ.

  Phần đơn giản hóa ghi trong `connectors/README.md`. Mã cơ chế dùng giá trị mock `MCK`, không giả danh mã thật.
- **Mọi nghiệp vụ ghi nhận `ma_tham_chieu` của bên gọi:**
  - Registry từ chối lần hai (409) → chặn cấp tín chỉ hai lần ngay cả khi bên gọi gửi lặp;
  - Buyer, Bank trả lại kết quả cũ (idempotent) → gửi lại an toàn khi mạng chập chờn.

## Phương án loại
- **Prism / mock sinh từ OpenAPI tĩnh:** không giữ trạng thái (số dư, sê-ri), không kiểm được luật như vượt số dư.
- **Bảng mock trong PostgreSQL nền tảng:** trộn dữ liệu "bên ngoài" vào CSDL của mình, mất ý nghĩa cắm–rút.

## Hệ quả
- Thêm FastAPI, Starlette, uvicorn, pydantic (MIT/BSD, OSI) – DEPENDENCIES, NOTICE.
- Mock không xử lý tiền thật, người mua và mã số thuế đều giả (`99xxxxxxxx`).
