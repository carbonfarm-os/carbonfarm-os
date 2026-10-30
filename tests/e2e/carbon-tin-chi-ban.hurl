# SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors
# SPDX-License-Identifier: GPL-3.0-or-later
# Bán tín chỉ (#37) theo cơ chế tạo và duyệt hai người (TT 11/2026/TT-BNNMT Điều 6 khoản 3):
# canbo-htx-mau tạo lệnh, canbo-htx-mau-2 duyệt → Buyer mock → Registry mock chuyển quyền → Bank mock → sổ cái → ví.
# Cần ví đã có tín chỉ: chạy sau carbon-mrv.hurl (Hurl chạy tuần tự theo tên tệp, --jobs 1).

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
tk1: jsonpath "$.access_token"
id_tk: jsonpath "$.id_token"

GET {{gateway}}/auth/realms/dxos/protocol/openid-connect/logout?id_token_hint={{id_tk}}&post_logout_redirect_uri=http%3A%2F%2Flocalhost%3A9080%2F
HTTP 302

GET {{gateway}}/auth/realms/dxos/protocol/openid-connect/auth?client_id=web&response_type=code&scope=openid&state=canbo-htx-mau-2&redirect_uri=http%3A%2F%2Flocalhost%3A9080%2Fdang-nhap%2Fxong&code_challenge=E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM&code_challenge_method=S256
HTTP 200
[Captures]
action: xpath "string(//form[@id='kc-form-login']/@action)"

POST {{action}}
[FormParams]
username: canbo-htx-mau-2
password: {{bm_mk_canbo_htx_mau_2}}
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
tk2: jsonpath "$.access_token"
id_tk: jsonpath "$.id_token"

# Ví và danh sách người mua (tiến trình carbon-mrv đồng bộ từ Buyer mock)
POST {{gateway}}/graphql
Authorization: Bearer {{tk1}}
Content-Type: application/json
[Options]
retry: 20
retry-interval: 1500
{"query":"{ allCarbonKhoiTinChis { nodes { maTrongNuoc soLuong } } allCarbonNguoiMuas { nodes { ma donGiaToiDaVnd } } }"}
HTTP 200
[Captures]
ma: jsonpath "$.data.allCarbonKhoiTinChis.nodes[0].maTrongNuoc"
[Asserts]
jsonpath "$.data.allCarbonKhoiTinChis.nodes" count >= 1
jsonpath "$.data.allCarbonNguoiMuas.nodes[*].ma" contains "NM-XANH"

# UC030 – vượt số dư khả dụng
POST {{gateway}}/graphql
Authorization: Bearer {{tk1}}
Content-Type: application/json
{"query":"mutation($htx: UUID, $nm: String, $ma: String, $sl: Int, $gia: BigInt) { carbonTaoLenhBan(input: {hopTacXaId: $htx, maNguoiMua: $nm, maTrongNuoc: $ma, soLuong: $sl, donGiaVnd: $gia}) { result } }","variables":{"htx":"00000000-0000-4000-8000-0000000f0001","nm":"NM-XANH","ma":"{{ma}}","sl":999999,"gia":"200000"}}
HTTP 200
[Asserts]
jsonpath "$.errors[0].extensions.code" == "UC030"

# UC033 – người mua không có trong danh sách
POST {{gateway}}/graphql
Authorization: Bearer {{tk1}}
Content-Type: application/json
{"query":"mutation($htx: UUID, $nm: String, $ma: String, $sl: Int, $gia: BigInt) { carbonTaoLenhBan(input: {hopTacXaId: $htx, maNguoiMua: $nm, maTrongNuoc: $ma, soLuong: $sl, donGiaVnd: $gia}) { result } }","variables":{"htx":"00000000-0000-4000-8000-0000000f0001","nm":"NM-KHONG-CO","ma":"{{ma}}","sl":1,"gia":"200000"}}
HTTP 200
[Asserts]
jsonpath "$.errors[0].extensions.code" == "UC033"

# Cán bộ 1 tạo lệnh bán 5 tín chỉ, 200.000 đ/tín chỉ
POST {{gateway}}/graphql
Authorization: Bearer {{tk1}}
Content-Type: application/json
{"query":"mutation($htx: UUID, $nm: String, $ma: String, $sl: Int, $gia: BigInt) { carbonTaoLenhBan(input: {hopTacXaId: $htx, maNguoiMua: $nm, maTrongNuoc: $ma, soLuong: $sl, donGiaVnd: $gia}) { result } }","variables":{"htx":"00000000-0000-4000-8000-0000000f0001","nm":"NM-XANH","ma":"{{ma}}","sl":5,"gia":"200000"}}
HTTP 200
[Captures]
lenh: jsonpath "$.data.carbonTaoLenhBan.result"
[Asserts]
jsonpath "$.errors" not exists

POST {{gateway}}/graphql
Authorization: Bearer {{tk1}}
Content-Type: application/json
{"query":"query($id: UUID!) { carbonLenhBanByRowId(rowId: $id) { trangThai doToiTao thanhTienVnd daiSeri maGiaoDichBank doltCommit lyDoLoi } }","variables":{"id":"{{lenh}}"}}
HTTP 200
[Asserts]
jsonpath "$.data.carbonLenhBanByRowId.trangThai" == "cho_duyet"
jsonpath "$.data.carbonLenhBanByRowId.doToiTao" == true
jsonpath "$.data.carbonLenhBanByRowId.thanhTienVnd" == "1000000"

# UC031 – người tạo không tự duyệt
POST {{gateway}}/graphql
Authorization: Bearer {{tk1}}
Content-Type: application/json
{"query":"mutation($id: UUID, $dy: Boolean, $gc: String) { carbonDuyetLenhBan(input: {lenhBanId: $id, dongY: $dy, ghiChu: $gc}) { result } }","variables":{"id":"{{lenh}}","dy":true,"gc":null}}
HTTP 200
[Asserts]
jsonpath "$.errors[0].extensions.code" == "UC031"
jsonpath "$.errors[0].message" contains "Điều 6 khoản 3"

# Cán bộ 2 duyệt
POST {{gateway}}/graphql
Authorization: Bearer {{tk2}}
Content-Type: application/json
{"query":"mutation($id: UUID, $dy: Boolean, $gc: String) { carbonDuyetLenhBan(input: {lenhBanId: $id, dongY: $dy, ghiChu: $gc}) { result } }","variables":{"id":"{{lenh}}","dy":true,"gc":"Đã kiểm giá với người mua"}}
HTTP 200
[Asserts]
jsonpath "$.errors" not exists

# UC032 – không duyệt hai lần
POST {{gateway}}/graphql
Authorization: Bearer {{tk2}}
Content-Type: application/json
{"query":"mutation($id: UUID, $dy: Boolean, $gc: String) { carbonDuyetLenhBan(input: {lenhBanId: $id, dongY: $dy, ghiChu: $gc}) { result } }","variables":{"id":"{{lenh}}","dy":true,"gc":null}}
HTTP 200
[Asserts]
jsonpath "$.errors[0].extensions.code" == "UC032"

# Tiến trình carbon-mrv: Buyer → Registry → Bank → sổ cái → trừ ví
POST {{gateway}}/graphql
Authorization: Bearer {{tk2}}
Content-Type: application/json
[Options]
retry: 20
retry-interval: 1500
{"query":"query($id: UUID!) { carbonLenhBanByRowId(rowId: $id) { trangThai doToiTao thanhTienVnd daiSeri maGiaoDichBank doltCommit lyDoLoi } }","variables":{"id":"{{lenh}}"}}
HTTP 200
[Captures]
seri_ban: jsonpath "$.data.carbonLenhBanByRowId.daiSeri[0].seri_tu"
[Asserts]
jsonpath "$.data.carbonLenhBanByRowId.trangThai" == "hoan_tat"
jsonpath "$.data.carbonLenhBanByRowId.doToiTao" == false
jsonpath "$.data.carbonLenhBanByRowId.doltCommit" matches "^[0-9a-v]{32}$"
jsonpath "$.data.carbonLenhBanByRowId.maGiaoDichBank" == "ban-{{lenh}}"

# Registry: sê-ri đã thuộc người mua
GET {{registry}}/tin-chi/seri/{{seri_ban}}
Authorization: Bearer {{bm_ket_noi_registry}}
HTTP 200
[Asserts]
jsonpath "$.chu_so_huu" == "9900000001"
jsonpath "$.lich_su[*].nghiep_vu" contains "chuyen_quyen"

# Bank: tiền về tài khoản hợp tác xã đúng một lần
GET {{bank}}/tai-khoan/9704000000009001
Authorization: Bearer {{bm_ket_noi_bank}}
HTTP 200
[Asserts]
jsonpath "$.giao_dich[?(@.ma_tham_chieu=='ban-{{lenh}}')]" count == 1
jsonpath "$.giao_dich[?(@.ma_tham_chieu=='ban-{{lenh}}')].so_tien_vnd" nth 0 == 1000000

# Người mua từ chối đơn giá vượt mức tối đa → lệnh "loi", không chuyển gì
POST {{gateway}}/graphql
Authorization: Bearer {{tk2}}
Content-Type: application/json
{"query":"mutation($htx: UUID, $nm: String, $ma: String, $sl: Int, $gia: BigInt) { carbonTaoLenhBan(input: {hopTacXaId: $htx, maNguoiMua: $nm, maTrongNuoc: $ma, soLuong: $sl, donGiaVnd: $gia}) { result } }","variables":{"htx":"00000000-0000-4000-8000-0000000f0001","nm":"NM-XANH","ma":"{{ma}}","sl":1,"gia":"999999"}}
HTTP 200
[Captures]
lenh2: jsonpath "$.data.carbonTaoLenhBan.result"
[Asserts]
jsonpath "$.errors" not exists

POST {{gateway}}/graphql
Authorization: Bearer {{tk1}}
Content-Type: application/json
{"query":"mutation($id: UUID, $dy: Boolean, $gc: String) { carbonDuyetLenhBan(input: {lenhBanId: $id, dongY: $dy, ghiChu: $gc}) { result } }","variables":{"id":"{{lenh2}}","dy":true,"gc":"Thử giá cao"}}
HTTP 200
[Asserts]
jsonpath "$.errors" not exists

POST {{gateway}}/graphql
Authorization: Bearer {{tk1}}
Content-Type: application/json
[Options]
retry: 20
retry-interval: 1500
{"query":"query($id: UUID!) { carbonLenhBanByRowId(rowId: $id) { trangThai doToiTao thanhTienVnd daiSeri maGiaoDichBank doltCommit lyDoLoi } }","variables":{"id":"{{lenh2}}"}}
HTTP 200
[Asserts]
jsonpath "$.data.carbonLenhBanByRowId.trangThai" == "loi"
jsonpath "$.data.carbonLenhBanByRowId.lyDoLoi" contains "đơn giá tối đa"

# UC015 – từ chối phải có lý do
POST {{gateway}}/graphql
Authorization: Bearer {{tk1}}
Content-Type: application/json
{"query":"mutation($htx: UUID, $nm: String, $ma: String, $sl: Int, $gia: BigInt) { carbonTaoLenhBan(input: {hopTacXaId: $htx, maNguoiMua: $nm, maTrongNuoc: $ma, soLuong: $sl, donGiaVnd: $gia}) { result } }","variables":{"htx":"00000000-0000-4000-8000-0000000f0001","nm":"NM-XANH","ma":"{{ma}}","sl":1,"gia":"200000"}}
HTTP 200
[Captures]
lenh3: jsonpath "$.data.carbonTaoLenhBan.result"
[Asserts]
jsonpath "$.errors" not exists

POST {{gateway}}/graphql
Authorization: Bearer {{tk2}}
Content-Type: application/json
{"query":"mutation($id: UUID, $dy: Boolean, $gc: String) { carbonDuyetLenhBan(input: {lenhBanId: $id, dongY: $dy, ghiChu: $gc}) { result } }","variables":{"id":"{{lenh3}}","dy":false,"gc":null}}
HTTP 200
[Asserts]
jsonpath "$.errors[0].extensions.code" == "UC015"

POST {{gateway}}/graphql
Authorization: Bearer {{tk2}}
Content-Type: application/json
{"query":"mutation($id: UUID, $dy: Boolean, $gc: String) { carbonDuyetLenhBan(input: {lenhBanId: $id, dongY: $dy, ghiChu: $gc}) { result } }","variables":{"id":"{{lenh3}}","dy":false,"gc":"Người mua đổi ý"}}
HTTP 200
[Asserts]
jsonpath "$.errors" not exists

POST {{gateway}}/graphql
Authorization: Bearer {{tk2}}
Content-Type: application/json
{"query":"query($id: UUID!) { carbonLenhBanByRowId(rowId: $id) { trangThai doToiTao thanhTienVnd daiSeri maGiaoDichBank doltCommit lyDoLoi } }","variables":{"id":"{{lenh3}}"}}
HTTP 200
[Asserts]
jsonpath "$.data.carbonLenhBanByRowId.trangThai" == "tu_choi"
