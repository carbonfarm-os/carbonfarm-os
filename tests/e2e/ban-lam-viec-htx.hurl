# SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors
# SPDX-License-Identifier: GPL-3.0-or-later
# Kiểm thử E2E bàn làm việc HTX (#114): thẩm tra mùa vụ, khối tín chỉ và nhật ký Dolt
# Chạy với quyền quản trị kiểm thử để xác minh dữ liệu phục vụ bàn làm việc cán bộ HTX.

POST {{gateway}}/auth/realms/dxos/protocol/openid-connect/token
[FormParams]
grant_type: client_credentials
client_id: kiem-thu-quan-tri
client_secret: {{bm_kc_kiem_thu_quan_tri}}
HTTP 200
[Captures]
tk_qt: jsonpath "$.access_token"

# 1. Bàn làm việc - Phân khu 1: Rà soát đợt thẩm tra mùa vụ
POST {{gateway}}/graphql
Authorization: Bearer {{tk_qt}}
Content-Type: application/json
{"query":"{ allCarbonKetQuaMrvs { totalCount nodes { rowId kyTu kyDen trangThai canhId ngayChup mayPhanTram soDiemAnhLo soDiemAnhHopLe soDiemAnhTan dienTichTanHa co2ETan canhBao phuongPhap cogHref doltCommit carbonDeNghiCapByKetQuaMrvId { rowId trangThai soLuong maTrongNuoc seriTu seriDen doltCommit } } } }"}
HTTP 200
[Asserts]
jsonpath "$.errors" not exists
jsonpath "$.data.allCarbonKetQuaMrvs.totalCount" >= 1
jsonpath "$.data.allCarbonKetQuaMrvs.nodes[0].rowId" exists
jsonpath "$.data.allCarbonKetQuaMrvs.nodes[0].doltCommit" matches "^[0-9a-v]{32}$"
jsonpath "$.data.allCarbonKetQuaMrvs.nodes[0].trangThai" exists
jsonpath "$.data.allCarbonKetQuaMrvs.nodes[0].phuongPhap" exists

# 2. Bàn làm việc - Phân khu 2: Dải tín chỉ đã phát hành cho HTX
POST {{gateway}}/graphql
Authorization: Bearer {{tk_qt}}
Content-Type: application/json
{"query":"{ allCarbonKhoiTinChis { totalCount nodes { rowId soLuong maTrongNuoc seriTu seriDen hopTacXaId taoLuc } } allCarbonHopTacXas { nodes { rowId ten maSoThue diaChi } } }"}
HTTP 200
[Asserts]
jsonpath "$.errors" not exists
jsonpath "$.data.allCarbonKhoiTinChis.totalCount" >= 1
jsonpath "$.data.allCarbonKhoiTinChis.nodes[0].maTrongNuoc" exists
jsonpath "$.data.allCarbonKhoiTinChis.nodes[0].seriTu" exists
jsonpath "$.data.allCarbonKhoiTinChis.nodes[0].seriDen" exists

# 3. Bàn làm việc - Phân khu 3: Nhật ký giao dịch và lệnh bán
POST {{gateway}}/graphql
Authorization: Bearer {{tk_qt}}
Content-Type: application/json
{"query":"{ allCarbonLenhBans { totalCount nodes { rowId maNguoiMua maTrongNuoc soLuong donGiaVnd thanhTienVnd trangThai taoLuc doltCommit } } allCarbonNguoiMuas { nodes { ma ten } } }"}
HTTP 200
[Asserts]
jsonpath "$.errors" not exists
jsonpath "$.data.allCarbonLenhBans.totalCount" >= 1
jsonpath "$.data.allCarbonLenhBans.nodes[0].doltCommit" matches "^[0-9a-v]{32}$"
