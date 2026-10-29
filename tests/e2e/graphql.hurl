# SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors
# SPDX-License-Identifier: GPL-3.0-or-later
# Smoke dữ liệu có cấu trúc (#7): PostGraphile qua gateway, vai từ JWT, quyền bằng RLS trên bảng mẫu nen_tang.ghi_chu_mau.

# Không token → gateway chặn
POST {{gateway}}/graphql
Content-Type: application/json
{"query":"{ allGhiChuMaus { totalCount } }"}
HTTP 401

# Token người dùng (vai nguoi_dung) và quản trị (vai quan_tri)
POST {{gateway}}/auth/realms/dxos/protocol/openid-connect/token
[FormParams]
grant_type: client_credentials
client_id: kiem-thu
client_secret: {{bm_kc_kiem_thu}}
HTTP 200
[Captures]
tk_nd: jsonpath "$.access_token"

POST {{gateway}}/auth/realms/dxos/protocol/openid-connect/token
[FormParams]
grant_type: client_credentials
client_id: kiem-thu-quan-tri
client_secret: {{bm_kc_kiem_thu_quan_tri}}
HTTP 200
[Captures]
tk_qt: jsonpath "$.access_token"

# Người dùng tạo một ghi chú: chủ sở hữu do CSDL lấy từ JWT
POST {{gateway}}/graphql
Authorization: Bearer {{tk_nd}}
Content-Type: application/json
{"query":"mutation { createGhiChuMau(input:{ghiChuMau:{noiDung:\"cua nguoi dung {{newUuid}}\"}}) { ghiChuMau { rowId chuSoHuu } } }"}
HTTP 200
[Asserts]
jsonpath "$.errors" not exists
[Captures]
id_nd: jsonpath "$.data.createGhiChuMau.ghiChuMau.rowId"
chu_nd: jsonpath "$.data.createGhiChuMau.ghiChuMau.chuSoHuu"

# Quản trị tạo một ghi chú
POST {{gateway}}/graphql
Authorization: Bearer {{tk_qt}}
Content-Type: application/json
{"query":"mutation { createGhiChuMau(input:{ghiChuMau:{noiDung:\"cua quan tri {{newUuid}}\"}}) { ghiChuMau { rowId } } }"}
HTTP 200
[Asserts]
jsonpath "$.errors" not exists
[Captures]
id_qt: jsonpath "$.data.createGhiChuMau.ghiChuMau.rowId"

# RLS: người dùng chỉ thấy ghi chú của mình, không thấy của quản trị
POST {{gateway}}/graphql
Authorization: Bearer {{tk_nd}}
Content-Type: application/json
{"query":"{ allGhiChuMaus { nodes { rowId chuSoHuu } } }"}
HTTP 200
[Asserts]
jsonpath "$.data.allGhiChuMaus.nodes[?(@.rowId == '{{id_nd}}')]" count == 1
jsonpath "$.data.allGhiChuMaus.nodes[?(@.rowId == '{{id_qt}}')]" count == 0
jsonpath "$.data.allGhiChuMaus.nodes[?(@.chuSoHuu != '{{chu_nd}}')]" count == 0

# Quản trị thấy cả hai
POST {{gateway}}/graphql
Authorization: Bearer {{tk_qt}}
Content-Type: application/json
{"query":"{ allGhiChuMaus { nodes { rowId } } }"}
HTTP 200
[Asserts]
jsonpath "$.data.allGhiChuMaus.nodes[?(@.rowId == '{{id_nd}}')]" count == 1
jsonpath "$.data.allGhiChuMaus.nodes[?(@.rowId == '{{id_qt}}')]" count == 1

# Người dùng không được xóa: mutation có trong schema nhưng CSDL từ chối (log PostGraphile: permission denied;
# lỗi gửi về client bị che để không lộ chi tiết CSDL)
POST {{gateway}}/graphql
Authorization: Bearer {{tk_nd}}
Content-Type: application/json
{"query":"mutation { deleteGhiChuMauByRowId(input:{rowId:\"{{id_nd}}\"}) { deletedGhiChuMauId } }"}
HTTP 200
[Asserts]
jsonpath "$.errors" exists
jsonpath "$.data.deleteGhiChuMauByRowId" == null
