<!-- SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors -->
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->
# platform/ · Tầng 1 (headless)

Dịch vụ lõi **tổng quát**, dùng được cho miền nghiệp vụ bất kỳ (BTC #1400, #1423: "độc lập hoàn toàn với nghiệp vụ, tổng quát nhất có thể").

**Được đặt ở đây:**
- cấu hình dịch vụ (APISIX, Keycloak realm nền tảng, OpenBao policy);
- khởi tạo PostgreSQL tổng quát (role, extension, schema dùng chung);
- route tổng quát của gateway (`/auth`, `/graphql`, `/s3`, `/stac`, `/tiles`, `/workflow`).

**KHÔNG đặt ở đây:**
- bảng, vai trò, quy trình, dữ liệu mẫu của miền carbon (hợp tác xã, lô đất, tín chỉ…);
- giao diện cho người dùng cuối.

Những thứ đó thuộc `domains/carbon/`.

Kiểm nhanh: `grep -riE "carbon|tin.chi|lo.dat|hop.tac" platform/` phải rỗng (`/pof-check` kiểm mục này).

| Thư mục | Dịch vụ |
|---|---|
| `apisix/` | API Gateway (standalone) |
| `keycloak/` | SSO, realm nền tảng (tạo ở sprint 1) |
| `postgres/` | Khởi tạo CSDL tổng quát; `ap-migration.sh` áp migration và dữ liệu mẫu của các miền (`domains/*/db/`) |
| `openbao/` | Bí mật: khởi tạo, mở khóa, sinh bí mật nền tảng + tên bí mật miền khai trong `domains/*/bi-mat.txt` |
| `postgraphile/` | GraphQL tự sinh; schema lộ ra chọn bằng `GRAPHQL_SCHEMAS` |
| `prefect/` | Workflow engine, flow mẫu tổng quát |
| `dolt/` | Sổ cái có phiên bản |
