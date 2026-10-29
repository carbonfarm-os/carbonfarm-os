<!-- SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors -->
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->
# Khai báo phụ thuộc · Dependencies

Mã của dự án: **GPL-3.0-or-later**. Tệp này ghi từng thành phần bên thứ ba: phiên bản, giấy phép, nguồn, cách dùng. Giấy phép đọc trực tiếp từ tệp LICENSE trên repo gốc ngày **29/10/2026**; mỗi lần nâng phiên bản phải kiểm lại và sửa tệp này trong cùng PR. Từ bản v0.1.0, mỗi Release kèm SBOM CycloneDX (`sbom.cdx.json`) sinh tự động.

Nguyên tắc (theo trả lời của BTC OLP PMNM 2026, tin #1362–1376, #1383–1386):
- Chỉ mã trong repo tính vào giấy phép dự án. Thành phần bên thứ ba ưu tiên giấy phép OSI.
- Thành phần copyleft (GPL/AGPL) hoặc không OSI chỉ chạy như **dịch vụ riêng**, image gốc, không nhúng, không sửa mã.
- Đội **chủ động** chọn dữ liệu mở Copernicus/STAC và công cụ nguồn mở để bảo đảm chủ quyền dữ liệu và tái lập được kết quả MRV. Đây là lựa chọn thiết kế, không phải vì bị cấm.

Trạng thái: ✔ đang chạy · ◐ đã chọn, đang dựng · ☐ dự kiến.

## 1. Dịch vụ (image Docker)

| Thành phần | Phiên bản | Giấy phép | Nguồn | Cách dùng | Tầng | Trạng thái |
|---|---|---|---|---|---|---|
| PostgreSQL 17 + PostGIS + pgSTAC | `ghcr.io/stac-utils/pgstac:v0.10.0` (image chính thức của stac-utils, có arm64; `postgis/postgis` chỉ có amd64) | PostgreSQL License / GPL-2.0-or-later (PostGIS) / MIT (pgSTAC) | github.com/stac-utils/pgstac | Dịch vụ riêng, image gốc | 1 | ✔ |
| Keycloak | `quay.io/keycloak/keycloak:26.8.1` | Apache-2.0 | github.com/keycloak/keycloak | Dịch vụ riêng; realm `dxos` | 1 | ✔ |
| Apache APISIX | `apache/apisix:3.19.0-debian` | Apache-2.0 | github.com/apache/apisix | Dịch vụ riêng, standalone, kiểm JWT bằng JWKS | 1 | ✔ |
| OpenBao | `openbao/openbao:2.7.2` | MPL-2.0 | github.com/openbao/openbao | Dịch vụ riêng, image gốc, lưu raft; sinh và giữ mật khẩu dịch vụ | 1 | ✔ |
| PostGraphile v5 | `postgraphile` 5.x (npm, image tự build tuần 1) | MIT | github.com/graphile/crystal | API GraphQL tự sinh từ PostgreSQL (RLS) | 1 | ☐ |
| Versity S3 Gateway | `versity/versitygw` v1.10.0 | Apache-2.0 | github.com/versity/versitygw | Lưu trữ đối tượng S3 trên thư mục POSIX | 1 | ☐ |
| pgSTAC | v0.10.0 (trong image PostgreSQL ở trên) | MIT | github.com/stac-utils/pgstac | Danh mục STAC trong PostgreSQL | 1 | ◐ |
| stac-fastapi-pgstac | 7.2.0 | MIT | github.com/stac-utils/stac-fastapi-pgstac | API STAC | 1 | ☐ |
| TiTiler | 2.4.0 | MIT | github.com/developmentseed/titiler | Tile ảnh COG cho bản đồ | 1 | ☐ |
| Prefect (server + worker) | 3.9.0 | Apache-2.0 | github.com/PrefectHQ/prefect | Workflow engine, pipeline MRV có bước chờ duyệt | 1 | ☐ |
| Valkey | 9.1.3 | BSD-3-Clause | github.com/valkey-io/valkey | Event bus (Streams) | 1 | ☐ |
| Dolt (`dolt-sql-server`) | 2.6.1 | Apache-2.0 | github.com/dolthub/dolt | Sổ cái có phiên bản: mỗi lần ghi là một commit có mã băm (ADR) | 1 | ☐ |
| Metabase **OSS** | `metabase/metabase:v0.64.3` | AGPL-3.0 (bản OSS) | github.com/metabase/metabase | Dịch vụ riêng, image gốc; KHÔNG dùng `metabase-enterprise` | 2 | ☐ |

## 2. Thư viện

| Thành phần | Phiên bản | Giấy phép | Nguồn | Dùng ở |
|---|---|---|---|---|
| GDAL | 3.13 (conda-forge) | MIT/X (tệp LICENSE.TXT liệt kê giấy phép từng phần) | github.com/OSGeo/gdal | MRV engine |
| rasterio | 1.5 | BSD-3-Clause | github.com/rasterio/rasterio | MRV engine |
| pystac / pystac-client | 1.15 / mới nhất | Apache-2.0 | github.com/stac-utils | MRV engine |
| SvelteKit | 2.x | MIT | github.com/sveltejs/kit | Web Tầng 2 |
| MapLibre GL JS | 6.16 | BSD-3-Clause | github.com/maplibre/maplibre-gl-js | Bản đồ |

## 3. Công cụ phát triển (không nằm trong sản phẩm)

| Công cụ | Giấy phép | Dùng cho |
|---|---|---|
| go-task | MIT | Chạy lệnh (`Taskfile.yml`) |
| pixi | BSD-3-Clause | Môi trường Python + GDAL |
| Hurl (`ghcr.io/orange-opensource/hurl:7.0.0`, chạy bằng Docker trong `task smoke`) | Apache-2.0 | Kiểm thử đầu-cuối |
| pre-commit, ruff, yamllint | MIT / MIT / GPL-3.0 | Kiểm trước commit |
| release-please | Apache-2.0 | CHANGELOG, phiên bản, Release |
| Syft (anchore/sbom-action) | Apache-2.0 | SBOM CycloneDX |

## 4. Dữ liệu

| Dữ liệu | Giấy phép / điều khoản | Dùng cho |
|---|---|---|
| Sentinel-2 L2A (Copernicus Data Space Ecosystem, STAC) | Dữ liệu mở Copernicus, miễn phí, ghi nguồn | Ước lượng carbon |
| Dữ liệu hợp tác xã, xã viên, lô đất | Dữ liệu **giả** do đội tạo | Demo |

## 5. Không dùng

| Thành phần | Lý do | Dùng thay |
|---|---|---|
| immudb | Business Source License từ bản 1.9 (kiểm LICENSE ngày 29/10/2026), không OSI | Dolt |
| MinIO | Repo đã lưu trữ (archived) 04/2026, bản cộng đồng không còn phát hành | Versity S3 Gateway |
| Google Earth Engine | Dịch vụ đám mây độc quyền; BTC cho phép dịch vụ ngoài, đội chọn STAC + GDAL để tái lập được | Copernicus STAC + GDAL/rasterio |
| `metabase/metabase-enterprise` | Metabase Commercial License | `metabase/metabase` (AGPL-3.0) |
