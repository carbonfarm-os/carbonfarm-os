<!-- SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors -->
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->
# 0002 · Stack và giấy phép từng thành phần

- Trạng thái: chấp nhận
- Ngày: 2026-10-29
- Người viết: @Minhthuan12 (thay mặt nhóm khi dựng sprint 1; V3 bổ sung khi có tài khoản)
- Issue / PR: #12

## Bối cảnh
Đề DX-OS Open-Core yêu cầu lõi Tầng 1 headless có SSO, API Gateway, dữ liệu có cấu trúc và phi cấu trúc, workflow engine, và ít nhất một ứng dụng Tầng 2. Ràng buộc:
- **Giấy phép.** Mã của đội là GPL-3.0-or-later. Theo BTC (#1362–1376), chỉ mã trong repo tính vào giấy phép dự án; thành phần bên thứ ba ưu tiên OSI; thành phần copyleft hoặc không OSI chỉ chạy như dịch vụ riêng, không sửa mã.
- **Khác hai đội cùng trường** về thành phần chính, để giữ tính nguyên gốc.
- **Chạy được trên laptop**, có bản arm64.
- **Chủ quyền dữ liệu và tái lập được:** dữ liệu vệ tinh mở, xử lý bằng công cụ nguồn mở. Đây là lựa chọn thiết kế, vì BTC vẫn cho dùng dịch vụ ngoài (#1383–1386).

Giấy phép dưới đây đọc trực tiếp từ tệp LICENSE trên repo gốc ngày **29/10/2026**. Danh sách đầy đủ có phiên bản: `DEPENDENCIES.md`.

## Quyết định
| Lớp | Chọn | Giấy phép | Cách dùng | Vì sao chọn / thay cho |
|---|---|---|---|---|
| SSO/MFA | Keycloak 26.8 | Apache-2.0 | Dịch vụ | Chuẩn OIDC, OTP theo điều kiện vai. Cùng loại với hai đội nhưng realm, flow, client viết riêng |
| API Gateway | APISIX 3.19 | Apache-2.0 | Dịch vụ | Kiểm JWT bằng JWKS; route của miền ghép từ `domains/*/gateway` |
| Bí mật | OpenBao 2.7 (raft) | MPL-2.0 | Dịch vụ, image gốc | Sinh và giữ mật khẩu dịch vụ, không để trong `.env`. Thay HashiCorp Vault (Business Source License) |
| Dữ liệu có cấu trúc | PostgreSQL 17 + PostGIS + pgSTAC (image stac-utils) | PostgreSQL / GPL-2.0 (PostGIS) / MIT | Dịch vụ | Một CSDL cho dữ liệu, không gian và danh mục ảnh; image có arm64 (`postgis/postgis` chỉ amd64) |
| API tự sinh | PostGraphile 5 | MIT | Dịch vụ (build từ npm) | GraphQL + RLS. Khác Hasura (Team 1), PostgREST (Team 2) |
| Đối tượng | Versity S3 Gateway 1.10 | Apache-2.0 | Dịch vụ | S3 trên POSIX, nhẹ. MinIO đã lưu trữ (04/2026); SeaweedFS, Garage trùng hai đội |
| Danh mục ảnh | stac-fastapi-pgstac 7.2 | MIT | Dịch vụ | Chuẩn STAC, cùng chuẩn với Copernicus nên tìm và tái lập ảnh dễ |
| Tile | TiTiler 2.4 | MIT | Dịch vụ | Phục vụ COG từ S3 cho bản đồ |
| Workflow | Prefect 3.9 | Apache-2.0 | Dịch vụ + SDK | Hợp pipeline MRV theo lô, có pause/resume chờ duyệt. Khác Temporal (Team 1), Flowable (Team 2) |
| Event bus | Valkey 9.1 (Streams) | BSD-3-Clause | Dịch vụ | Nhẹ. Thay Redis (giấy phép đã đổi khỏi BSD), khác NATS (Team 1), RabbitMQ (Team 2) |
| Sổ cái | Dolt 2.6 | Apache-2.0 | Dịch vụ | Xem ADR 0003. Không dùng immudb (Business Source License) |
| Web | SvelteKit 3 + MapLibre GL JS 6 | MIT / BSD-3-Clause | Thư viện | Khác Nuxt (Team 1), React (Team 2). PKCE tự viết, không thư viện OIDC |
| Dashboard | Metabase OSS (`metabase/metabase`) | AGPL-3.0 | Dịch vụ, image gốc | Khác Grafana, Superset. Không dùng `metabase-enterprise` (giấy phép thương mại) |
| Xử lý ảnh | GDAL, rasterio, pystac | MIT/X, BSD-3, Apache-2.0 | Thư viện | Chuẩn nguồn mở cho ảnh vệ tinh |
| Dữ liệu vệ tinh | Sentinel-2 L2A (Copernicus, STAC) | Dữ liệu mở Copernicus | Ngoài repo | Chủ quyền dữ liệu, tái lập được. Không dùng Google Earth Engine |

## Hệ quả
- Mọi thành phần copyleft (PostGIS, Metabase) chạy như **dịch vụ riêng**, không nhúng, không sửa mã. Mã của đội GPL-3.0-or-later vẫn tương thích với các thư viện Apache-2.0, MIT, BSD, MPL-2.0 dùng kèm.
- Mỗi Release kèm SBOM CycloneDX. Thêm hoặc nâng thành phần thì sửa `DEPENDENCIES.md`, `NOTICE` và viết ADR trong cùng PR.
- Câu hỏi giám khảo có thể hỏi và câu trả lời ngắn:
  - "Sao không dùng immudb?" → Business Source License, không OSI.
  - "Sao không dùng Google Earth Engine?" → dữ liệu và thuật toán phải tái lập được ngoài dịch vụ đóng.
  - "PostGIS là GPL thì sao?" → chạy như dịch vụ riêng, không nhúng.
