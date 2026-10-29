<!-- SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors -->
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->
# connectors/ · Kết nối bên ngoài (cắm–rút)

Mỗi connector là một dịch vụ nhỏ có **hợp đồng OpenAPI** (`openapi.yaml`). Bản mock dùng cho demo; khi có đối tác thật, viết bản thật cùng hợp đồng rồi đổi cấu hình, không sửa lõi hay miền carbon.

| Connector | Vai trò | Căn cứ |
|---|---|---|
| `registry/` | Đề nghị cấp, nhận mã tín chỉ, ghi chuyển nhượng | Thiết kế theo Thông tư 11/2026/TT-BNNMT (hệ thống đăng ký quốc gia) |
| `buyer/` | Người mua tín chỉ (doanh nghiệp, quỹ) | Mock |
| `bank/` | Nhận tiền bán tín chỉ vào tài khoản/ví | Mock, không xử lý tiền thật |

Cắm–rút ở đây dành cho người thiết kế hệ thống, không phải người dùng cuối (BTC #1424).
