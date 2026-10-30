<!-- SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors -->
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->
# connectors/ · Kết nối bên ngoài (cắm–rút)

Mỗi connector là một dịch vụ nhỏ có **hợp đồng OpenAPI** (`openapi.yaml`). Bản mock dùng cho demo; khi có đối tác thật, viết bản thật cùng hợp đồng rồi đổi cấu hình, không sửa lõi hay miền carbon.

| Connector | Vai trò | Căn cứ |
|---|---|---|
| `registry/` | Tài khoản đăng ký, đăng ký tín chỉ (mã trong nước + dải sê-ri), chuyển quyền, bù trừ, tra sê-ri | Thông tư 11/2026/TT-BNNMT (đã đọc bản PDF chính thức trên chinhphu.vn) |
| `buyer/` | Người mua tín chỉ GIẢ (doanh nghiệp, quỹ), đặt mua theo đơn giá tối đa | Mock |
| `bank/` | Ghi có tiền bán tín chỉ, idempotent theo mã tham chiếu | Mock, không xử lý tiền thật |

**Chạy:** compose `compose/connectors.yaml` dựng ba dịch vụ từ một image:
- `ket-noi-registry`, `ket-noi-buyer`, `ket-noi-bank`, cổng 8000;
- chỉ trong mạng nội bộ;
- khóa Bearer do OpenBao sinh: `ket-noi-*` trong `domains/carbon/bi-mat.txt`;
- dữ liệu SQLite trong volume `ket-noi-du-lieu`.

**Hợp đồng:**
- `openapi.yaml` sinh từ mã bằng `task openapi`;
- `task test` và CI kiểm tệp không lệch mã;
- kiểm thử đầu-cuối: `tests/e2e/ket-noi.hurl`.

**Registry bám thông tư ở:**
- Điều 6: tài khoản gắn mã số thuế, mỗi tổ chức một tài khoản, tối thiểu 2 đầu mối;
- Điều 7: tiểu khoản Đăng ký chung, Bù trừ, Phong tỏa;
- Điều 10: thông tin đăng ký tín chỉ;
- Điều 11: mã trong nước `[cơ chế 3]-[dự án 4]-[YY]` (9 ký tự không kể gạch nối), số sê-ri = mã + 10 chữ số (19 ký tự);
- Điều 20: bù trừ từ Đăng ký chung, vượt số dư thì từ chối.

**Đơn giản hóa (không phải quy định):**
- Bộ không duyệt tay;
- chuyển quyền sở hữu do bán được ghi thẳng ở Registry, thực tế đi qua sàn giao dịch và Tổng công ty lưu ký (Điều 14–17);
- mã cơ chế là giá trị mock (`MCK`), không giả danh mã thật;
- không có định danh qua Cổng dịch vụ công (Điều 4 khoản 5).

Cắm–rút ở đây dành cho người thiết kế hệ thống, không phải người dùng cuối (BTC #1424).
