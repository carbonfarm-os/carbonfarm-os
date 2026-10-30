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
| PostGraphile v5 | `postgraphile` 5.1.5 (npm, image `carbonfarm/postgraphile` build từ `platform/postgraphile/`, Node 22) | MIT | github.com/graphile/crystal | API GraphQL tự sinh từ PostgreSQL; vai từ JWT, quyền bằng RLS | 1 | ✔ |
| Node.js (nền build) | `node:22.23.4-alpine3.24` | MIT | github.com/nodejs/node | Nền image PostGraphile | 1 | ✔ |
| Versity S3 Gateway | `versity/versitygw:v1.10.0` | Apache-2.0 | github.com/versity/versitygw | Dịch vụ riêng: S3 trên thư mục POSIX, chỉ trong mạng nội bộ; khóa do OpenBao sinh | 1 | ✔ |
| pgSTAC | v0.10.0 (trong image PostgreSQL ở trên) | MIT | github.com/stac-utils/pgstac | Danh mục STAC trong PostgreSQL | 1 | ✔ |
| stac-fastapi-pgstac | `ghcr.io/stac-utils/stac-fastapi-pgstac:7.2.0` | MIT | github.com/stac-utils/stac-fastapi-pgstac | Dịch vụ riêng: API STAC có Transactions, qua gateway `/stac` | 1 | ✔ |
| TiTiler | `ghcr.io/developmentseed/titiler:2.4.0` | MIT | github.com/developmentseed/titiler | Dịch vụ riêng: tile ảnh COG đọc từ S3, qua gateway `/tiles` | 1 | ✔ |
| Prefect (server + tiến trình chạy flow) | `prefecthq/prefect:3.9.0-python3.12` | Apache-2.0 | github.com/PrefectHQ/prefect | Dịch vụ riêng: workflow engine, trạng thái trong PostgreSQL, API qua gateway `/workflow`; flow mẫu có bước chờ duyệt | 1 | ✔ |
| Valkey | `valkey/valkey:9.1.3` | BSD-3-Clause | github.com/valkey-io/valkey | Dịch vụ riêng: event bus (Streams), có mật khẩu, chỉ nội bộ | 1 | ✔ |
| Dolt | `dolthub/dolt-sql-server:2.6.1` | Apache-2.0 | github.com/dolthub/dolt | Dịch vụ riêng: sổ cái có phiên bản, mỗi lần ghi là commit có mã băm (ADR 0003), chỉ nội bộ | 1 | ✔ |
| Metabase **OSS** | `metabase/metabase:v0.64.3` (amd64 + arm64) | AGPL-3.0 (bản OSS) | github.com/metabase/metabase | Dịch vụ riêng, image gốc, không sửa; KHÔNG dùng `metabase-enterprise`. CSDL nội bộ H2 trong volume riêng; đọc dữ liệu bằng vai chỉ đọc `carbon_bao_cao`; dashboard dựng qua API (ADR 0007) | 2 | ✔ |
| Python (chạy script dựng dashboard) | `python:3.12.12-slim-bookworm` | PSF-2.0 | github.com/python/cpython | Container chạy một lần, chỉ thư viện chuẩn | 2 | ✔ |

## 2. Thư viện

| Thành phần | Phiên bản | Giấy phép | Nguồn | Dùng ở |
|---|---|---|---|---|
| rasterio (wheel kèm GDAL 3.12.2, PROJ 9.8.1, GEOS, libtiff, curl… – giấy phép MIT/X, BSD, zlib, curl; GEOS LGPL-2.1, tương thích GPL-3.0) | 1.5.2 | BSD-3-Clause | github.com/rasterio/rasterio | MRV engine (`domains/carbon/mrv`, image `carbonfarm/carbon-mrv` trên nền `prefecthq/prefect:3.9.0-python3.12`) |
| numpy | 2.5.4 | BSD-3-Clause (kèm 0BSD, MIT, Zlib, CC0-1.0) | github.com/numpy/numpy | MRV engine |
| psycopg (+ psycopg-binary) | 3.3.6 | LGPL-3.0-only (tương thích GPL-3.0) | github.com/psycopg/psycopg | MRV engine đọc/ghi PostgreSQL (vai `carbon_mrv`) |
| PyMySQL | 1.2.3 | MIT | github.com/PyMySQL/PyMySQL | MRV engine ghi sổ cái Dolt |
| boto3 / botocore | 1.43.121 | Apache-2.0 | github.com/boto/boto3 | MRV engine ghi COG lên S3 nền tảng |
| httpx, PyYAML (có sẵn trong image Prefect) | 0.28.1 / 6.0.3 | BSD-3-Clause / MIT | github.com/encode/httpx, github.com/yaml/pyyaml | MRV engine gọi STAC, đọc tham số phương pháp |
| FastAPI | 0.162.0 | MIT | github.com/fastapi/fastapi | Connector mock (`connectors/`, image `carbonfarm/ket-noi` trên nền `python:3.12.12-slim-bookworm`) |
| Starlette (kèm FastAPI) | 1.10.0 | BSD-3-Clause | github.com/encode/starlette | Connector mock |
| Gói gián tiếp của connector (pydantic-core, anyio, idna, click, h11, annotated-types, typing-extensions, typing-inspection, annotated-doc) | theo pip, đọc metadata 30/10/2026 | MIT, BSD-3-Clause, PSF-2.0 – đều OSI | PyPI | Connector mock |
| uvicorn | 0.54.0 | BSD-3-Clause | github.com/encode/uvicorn | Connector mock |
| pydantic | 2.14.2 | MIT | github.com/pydantic/pydantic | Connector mock (mô hình dữ liệu, sinh OpenAPI) |
| Python (nền image connector) | 3.12.12 | PSF-2.0 | github.com/python/cpython | Connector mock |
| GDAL (môi trường dev bằng pixi) | 3.13 (conda-forge) | MIT/X (tệp LICENSE.TXT liệt kê giấy phép từng phần) | github.com/OSGeo/gdal | Máy dev |
| jose | 6.2.13 | MIT | github.com/panva/jose | PostGraphile kiểm lại JWT bằng JWKS |
| pg | 8.23.1 | MIT | github.com/brianc/node-postgres | PostGraphile kết nối PostgreSQL |
| Gói phụ thuộc gián tiếp của PostGraphile (186 gói, `platform/postgraphile/package-lock.json`) | — | MIT, Apache-2.0, ISC, BSD-2/3, 0BSD, PSF-2.0 (`argparse`) – đều OSI | npm | |
| SvelteKit (+ adapter-node, Svelte 5, Vite 8) | kit 3.1.0, svelte 5.57.3, vite 8.3.5, adapter-node 6.0.0 | MIT | github.com/sveltejs/kit | Web Tầng 2 (`domains/carbon/web`) |
| MapLibre GL JS | 6.16.0 | BSD-3-Clause | github.com/maplibre/maplibre-gl-js | Bản đồ |
| Source Serif 4 (`@fontsource-variable/source-serif-4`) | 5.3.1 | OFL-1.1 | github.com/adobe-fonts/source-serif · github.com/fontsource/font-files | Chữ tiêu đề web, có bộ ký tự tiếng Việt |
| Inter (`@fontsource-variable/inter`) | 5.3.0 | OFL-1.1 | github.com/rsms/inter · github.com/fontsource/font-files | Chữ thân và điều khiển web, có bộ ký tự tiếng Việt |
| Gói gián tiếp của web (104 gói, `domains/carbon/web/package-lock.json`) | — | MIT, ISC, Apache-2.0, BSD-2/3, MPL-2.0 (`lightningcss`, chỉ lúc build; tương thích GPL-3.0), MIT OR Apache-2.0 – đều OSI | npm | |

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
| Sentinel-2 L2A Collection 1 (danh mục STAC Earth Search `sentinel-2-c1-l2a`, COG công khai trên AWS Open Data) | Dữ liệu mở Copernicus Sentinel, miễn phí, ghi nguồn; sản phẩm NDVI của đội ghi "chứa dữ liệu Copernicus Sentinel đã qua xử lý" | Ước lượng carbon (ADR 0005) |
| Nền bản đồ OpenStreetMap (tile.openstreetmap.org) | ODbL, ghi nguồn "© Những người đóng góp OpenStreetMap"; tuân thủ chính sách dùng tile của OSMF (chỉ máy dev/demo, sẽ thay bằng tile tự phục vụ khi triển khai) | Nền bản đồ web |
| Ảnh chụp trang chủ (`domains/carbon/web/static/anh/`): rễ đước Cà Mau (Nevillenguyen310), bãi bồi Đất Mũi (Alphama), Wikimedia Commons | CC BY-SA 4.0 / CC BY 4.0, ghi công ở chân trang và `static/anh/NGUON.md` | Minh hoạ trang chủ |
| Dữ liệu hợp tác xã, xã viên, lô đất | Dữ liệu **giả** do đội tạo | Demo |

## 5. Không dùng

| Thành phần | Lý do | Dùng thay |
|---|---|---|
| immudb | Business Source License từ bản 1.9 (kiểm LICENSE ngày 29/10/2026), không OSI | Dolt |
| MinIO | Repo đã lưu trữ (archived) 04/2026, bản cộng đồng không còn phát hành | Versity S3 Gateway |
| Google Earth Engine | Dịch vụ đám mây độc quyền; BTC cho phép dịch vụ ngoài, đội chọn STAC + GDAL để tái lập được | Copernicus STAC + GDAL/rasterio |
| `metabase/metabase-enterprise` | Metabase Commercial License | `metabase/metabase` (AGPL-3.0) |
