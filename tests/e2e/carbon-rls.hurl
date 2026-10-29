# SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors
# SPDX-License-Identifier: GPL-3.0-or-later
# Phân quyền dữ liệu miền carbon (#22) bằng RLS: mỗi người dùng mẫu đăng nhập thật (Authorization Code + PKCE,
# đăng xuất OIDC trước khi đổi người) rồi đọc /graphql.
#   xavien-mau-1 → chỉ lô của mình; xavien-mau-2 → chỉ lô của mình; canbo-htx-mau → cả 2 lô của hợp tác xã;
#   nguoi-dung-mau (không thuộc hợp tác xã nào) → 0; quản trị → tất cả. Chỉ đếm lô đang hoạt động (lô do
#   carbon-dang-ky-lo.hurl tạo được chuyển "ngung" khi chạy xong). Cột hình học và sub không lộ qua API.
# Cặp verifier/challenge là ví dụ của RFC 7636 (chỉ dùng trong kiểm thử).

GET {{gateway}}/auth/realms/dxos/protocol/openid-connect/auth?client_id=web&response_type=code&scope=openid&state=xavien-mau-1&redirect_uri=http%3A%2F%2Flocalhost%3A9080%2Fdang-nhap%2Fxong&code_challenge=E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM&code_challenge_method=S256
HTTP 200
[Captures]
action: xpath "string(//form[@id='kc-form-login']/@action)"

POST {{action}}
[FormParams]
username: xavien-mau-1
password: {{bm_mk_xavien_mau_1}}
HTTP 302
[Captures]
code: header "Location" regex "[?&]code=([^&]+)"

POST {{gateway}}/auth/realms/dxos/protocol/openid-connect/token
[FormParams]
grant_type: authorization_code
client_id: web
code: {{code}}
redirect_uri: http://localhost:9080/dang-nhap/xong
code_verifier: dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk
HTTP 200
[Captures]
tk_xv1: jsonpath "$.access_token"
id_tk: jsonpath "$.id_token"

GET {{gateway}}/auth/realms/dxos/protocol/openid-connect/logout?id_token_hint={{id_tk}}&post_logout_redirect_uri=http%3A%2F%2Flocalhost%3A9080%2F
HTTP 302

POST {{gateway}}/graphql
Authorization: Bearer {{tk_xv1}}
Content-Type: application/json
{"query":"{ allCarbonLoDats(orderBy: ROW_ID_ASC, condition: {trangThai: \"hoat_dong\"}) { totalCount nodes { ten dienTichHa dienTichKhaiBaoHa ranhGioi } } allCarbonXaViens { totalCount } allCarbonHopTacXas { totalCount } }"}
HTTP 200
[Asserts]
jsonpath "$.errors" not exists
jsonpath "$.data.allCarbonLoDats.totalCount" == 1
jsonpath "$.data.allCarbonLoDats.nodes[0].ten" == "Lô Đất Mũi 1"
jsonpath "$.data.allCarbonLoDats.nodes[0].ranhGioi.type" == "Polygon"
jsonpath "$.data.allCarbonLoDats.nodes[0].dienTichHa" startsWith "8.87"
jsonpath "$.data.allCarbonXaViens.totalCount" == 1
jsonpath "$.data.allCarbonHopTacXas.totalCount" == 1

GET {{gateway}}/auth/realms/dxos/protocol/openid-connect/auth?client_id=web&response_type=code&scope=openid&state=xavien-mau-2&redirect_uri=http%3A%2F%2Flocalhost%3A9080%2Fdang-nhap%2Fxong&code_challenge=E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM&code_challenge_method=S256
HTTP 200
[Captures]
action: xpath "string(//form[@id='kc-form-login']/@action)"

POST {{action}}
[FormParams]
username: xavien-mau-2
password: {{bm_mk_xavien_mau_2}}
HTTP 302
[Captures]
code: header "Location" regex "[?&]code=([^&]+)"

POST {{gateway}}/auth/realms/dxos/protocol/openid-connect/token
[FormParams]
grant_type: authorization_code
client_id: web
code: {{code}}
redirect_uri: http://localhost:9080/dang-nhap/xong
code_verifier: dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk
HTTP 200
[Captures]
tk_xv2: jsonpath "$.access_token"
id_tk: jsonpath "$.id_token"

GET {{gateway}}/auth/realms/dxos/protocol/openid-connect/logout?id_token_hint={{id_tk}}&post_logout_redirect_uri=http%3A%2F%2Flocalhost%3A9080%2F
HTTP 302

POST {{gateway}}/graphql
Authorization: Bearer {{tk_xv2}}
Content-Type: application/json
{"query":"{ allCarbonLoDats(orderBy: ROW_ID_ASC, condition: {trangThai: \"hoat_dong\"}) { totalCount nodes { ten dienTichHa dienTichKhaiBaoHa ranhGioi } } allCarbonXaViens { totalCount } allCarbonHopTacXas { totalCount } }"}
HTTP 200
[Asserts]
jsonpath "$.errors" not exists
jsonpath "$.data.allCarbonLoDats.totalCount" == 1
jsonpath "$.data.allCarbonLoDats.nodes[0].ten" == "Lô Đất Mũi 2"

GET {{gateway}}/auth/realms/dxos/protocol/openid-connect/auth?client_id=web&response_type=code&scope=openid&state=canbo-htx-mau&redirect_uri=http%3A%2F%2Flocalhost%3A9080%2Fdang-nhap%2Fxong&code_challenge=E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM&code_challenge_method=S256
HTTP 200
[Captures]
action: xpath "string(//form[@id='kc-form-login']/@action)"

POST {{action}}
[FormParams]
username: canbo-htx-mau
password: {{bm_mk_canbo_htx_mau}}
HTTP 302
[Captures]
code: header "Location" regex "[?&]code=([^&]+)"

POST {{gateway}}/auth/realms/dxos/protocol/openid-connect/token
[FormParams]
grant_type: authorization_code
client_id: web
code: {{code}}
redirect_uri: http://localhost:9080/dang-nhap/xong
code_verifier: dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk
HTTP 200
[Captures]
tk_cb: jsonpath "$.access_token"
id_tk: jsonpath "$.id_token"

GET {{gateway}}/auth/realms/dxos/protocol/openid-connect/logout?id_token_hint={{id_tk}}&post_logout_redirect_uri=http%3A%2F%2Flocalhost%3A9080%2F
HTTP 302

POST {{gateway}}/graphql
Authorization: Bearer {{tk_cb}}
Content-Type: application/json
{"query":"{ allCarbonLoDats(orderBy: ROW_ID_ASC, condition: {trangThai: \"hoat_dong\"}) { totalCount nodes { ten dienTichHa dienTichKhaiBaoHa ranhGioi } } allCarbonXaViens { totalCount } allCarbonHopTacXas { totalCount } }"}
HTTP 200
[Asserts]
jsonpath "$.errors" not exists
jsonpath "$.data.allCarbonLoDats.totalCount" == 2
jsonpath "$.data.allCarbonXaViens.totalCount" == 2
jsonpath "$.data.allCarbonHopTacXas.totalCount" == 1

GET {{gateway}}/auth/realms/dxos/protocol/openid-connect/auth?client_id=web&response_type=code&scope=openid&state=nguoi-dung-mau&redirect_uri=http%3A%2F%2Flocalhost%3A9080%2Fdang-nhap%2Fxong&code_challenge=E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM&code_challenge_method=S256
HTTP 200
[Captures]
action: xpath "string(//form[@id='kc-form-login']/@action)"

POST {{action}}
[FormParams]
username: nguoi-dung-mau
password: {{bm_nguoi_dung_mau}}
HTTP 302
[Captures]
code: header "Location" regex "[?&]code=([^&]+)"

POST {{gateway}}/auth/realms/dxos/protocol/openid-connect/token
[FormParams]
grant_type: authorization_code
client_id: web
code: {{code}}
redirect_uri: http://localhost:9080/dang-nhap/xong
code_verifier: dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk
HTTP 200
[Captures]
tk_nd: jsonpath "$.access_token"
id_tk: jsonpath "$.id_token"

GET {{gateway}}/auth/realms/dxos/protocol/openid-connect/logout?id_token_hint={{id_tk}}&post_logout_redirect_uri=http%3A%2F%2Flocalhost%3A9080%2F
HTTP 302

POST {{gateway}}/graphql
Authorization: Bearer {{tk_nd}}
Content-Type: application/json
{"query":"{ allCarbonLoDats(orderBy: ROW_ID_ASC, condition: {trangThai: \"hoat_dong\"}) { totalCount nodes { ten dienTichHa dienTichKhaiBaoHa ranhGioi } } allCarbonXaViens { totalCount } allCarbonHopTacXas { totalCount } }"}
HTTP 200
[Asserts]
jsonpath "$.errors" not exists
jsonpath "$.data.allCarbonLoDats.totalCount" == 0
jsonpath "$.data.allCarbonXaViens.totalCount" == 0
jsonpath "$.data.allCarbonHopTacXas.totalCount" == 0

# Xã viên 1 không sửa được lô của xã viên 2 (RLS lọc → không thấy dòng nào để sửa, kết quả null)
POST {{gateway}}/graphql
Authorization: Bearer {{tk_xv1}}
Content-Type: application/json
{"query":"mutation { updateCarbonLoDatByRowId(input: {rowId: \"00000000-0000-4000-8000-0000000d0002\", carbonLoDatPatch: {ten: \"Chiếm lô\"}}) { carbonLoDat { ten } } }"}
HTTP 200
[Asserts]
jsonpath "$.data.updateCarbonLoDatByRowId.carbonLoDat" == null

POST {{gateway}}/graphql
Authorization: Bearer {{tk_cb}}
Content-Type: application/json
{"query":"{ allCarbonLoDats(orderBy: ROW_ID_ASC, condition: {trangThai: \"hoat_dong\"}) { nodes { ten } } }"}
HTTP 200
[Asserts]
jsonpath "$.data.allCarbonLoDats.nodes[1].ten" == "Lô Đất Mũi 2"

# Xã viên 1 sửa được lô của chính mình (đặt lại đúng tên cũ để không đổi dữ liệu mẫu)
POST {{gateway}}/graphql
Authorization: Bearer {{tk_xv1}}
Content-Type: application/json
{"query":"mutation { updateCarbonLoDatByRowId(input: {rowId: \"00000000-0000-4000-8000-0000000d0001\", carbonLoDatPatch: {ten: \"Lô Đất Mũi 1\"}}) { carbonLoDat { ten } } }"}
HTTP 200
[Asserts]
jsonpath "$.errors" not exists
jsonpath "$.data.updateCarbonLoDatByRowId.carbonLoDat.ten" == "Lô Đất Mũi 1"

# Cột hình học gốc và sub không lộ qua API (trường không tồn tại trong lược đồ → 400)
POST {{gateway}}/graphql
Authorization: Bearer {{tk_cb}}
Content-Type: application/json
{"query":"{ allCarbonXaViens { nodes { sub } } }"}
HTTP 400
[Asserts]
jsonpath "$.errors[0].message" contains "Cannot query field \"sub\""

POST {{gateway}}/graphql
Authorization: Bearer {{tk_cb}}
Content-Type: application/json
{"query":"{ allCarbonLoDats { nodes { hinh } } }"}
HTTP 400
[Asserts]
jsonpath "$.errors[0].message" contains "Cannot query field \"hinh\""

# Quản trị thấy tất cả
POST {{gateway}}/auth/realms/dxos/protocol/openid-connect/token
[FormParams]
grant_type: client_credentials
client_id: kiem-thu-quan-tri
client_secret: {{bm_kc_kiem_thu_quan_tri}}
HTTP 200
[Captures]
tk_qt: jsonpath "$.access_token"

POST {{gateway}}/graphql
Authorization: Bearer {{tk_qt}}
Content-Type: application/json
{"query":"{ allCarbonLoDats(condition: {trangThai: \"hoat_dong\"}) { totalCount } allCarbonXaViens { totalCount } }"}
HTTP 200
[Asserts]
jsonpath "$.errors" not exists
jsonpath "$.data.allCarbonLoDats.totalCount" == 2
jsonpath "$.data.allCarbonXaViens.totalCount" == 2
