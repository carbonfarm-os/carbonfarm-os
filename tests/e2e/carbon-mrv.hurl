# SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors
# SPDX-License-Identifier: GPL-3.0-or-later
# Trọn luồng MRV (#25) trên dữ liệu Sentinel-2 THẬT (cần Internet: Earth Search + COG công khai):
# cán bộ đăng ký lô rừng ngập mặn ở Mũi Cà Mau → yêu cầu đo tháng 4/2026 → flow Prefect chọn cảnh, tính NDVI/tán,
# lưu COG + item STAC, ghi kết quả + phả hệ, dừng chờ duyệt → cán bộ duyệt → flow ghi sổ cái Dolt.
# Lô tạo ở đây được chuyển "ngung" khi xong để chạy lại không vấp luật chồng lấn.

GET {{gateway}}/auth/realms/dxos/protocol/openid-connect/auth?client_id=web&response_type=code&scope=openid&state=mrv&redirect_uri=http%3A%2F%2Flocalhost%3A9080%2Fdang-nhap%2Fxong&code_challenge=E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM&code_challenge_method=S256
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
tk: jsonpath "$.access_token"

# Cán bộ đăng ký lô cho xã viên 1 (≈ 8,87 ha, trồng 2020)
POST {{gateway}}/graphql
Authorization: Bearer {{tk}}
Content-Type: application/json
{"query":"mutation($r: JSON) { carbonDangKyLoDat(input: {xaVienId: \"00000000-0000-4000-8000-0000000b0001\", ten: \"Lô kiểm thử MRV\", ranhGioi: $r, dienTichKhaiBaoHa: \"8.9\", namTrong: 2020}) { result } }","variables":{"r":{"type":"Polygon","coordinates":[[[104.8,8.64],[104.8027,8.64],[104.8027,8.6427],[104.8,8.6427],[104.8,8.64]]]}}}
HTTP 200
[Captures]
lo: jsonpath "$.data.carbonDangKyLoDat.result"
[Asserts]
jsonpath "$.errors" not exists

POST {{gateway}}/graphql
Authorization: Bearer {{tk}}
Content-Type: application/json
{"query":"mutation($lo: UUID) { carbonYeuCauMrv(input: {loDatId: $lo, kyTu: \"2026-04-01\", kyDen: \"2026-04-30\"}) { result } }","variables":{"lo":"{{lo}}"}}
HTTP 200
[Captures]
kq: jsonpath "$.data.carbonYeuCauMrv.result"
[Asserts]
jsonpath "$.errors" not exists

# UC010 – không đo chồng kỳ cho cùng lô
POST {{gateway}}/graphql
Authorization: Bearer {{tk}}
Content-Type: application/json
{"query":"mutation($lo: UUID) { carbonYeuCauMrv(input: {loDatId: $lo, kyTu: \"2026-04-15\", kyDen: \"2026-05-10\"}) { result } }","variables":{"lo":"{{lo}}"}}
HTTP 200
[Asserts]
jsonpath "$.errors[0].extensions.code" == "UC010"
jsonpath "$.errors[0].message" contains "không đo chồng kỳ"

# UC013 – kỳ ở tương lai
POST {{gateway}}/graphql
Authorization: Bearer {{tk}}
Content-Type: application/json
{"query":"mutation($lo: UUID) { carbonYeuCauMrv(input: {loDatId: $lo, kyTu: \"2099-01-01\", kyDen: \"2099-01-31\"}) { result } }","variables":{"lo":"{{lo}}"}}
HTTP 200
[Asserts]
jsonpath "$.errors[0].extensions.code" == "UC013"

# UC014 – chưa đo xong thì chưa duyệt được
POST {{gateway}}/graphql
Authorization: Bearer {{tk}}
Content-Type: application/json
{"query":"mutation($id: UUID) { carbonDuyetKetQuaMrv(input: {ketQuaId: $id, dongY: true}) { result } }","variables":{"id":"{{kq}}"}}
HTTP 200
[Asserts]
jsonpath "$.errors[0].extensions.code" == "UC014"

# Chờ flow đo xong và dừng chờ duyệt (đọc ảnh qua Internet: tới ~3 phút)
POST {{gateway}}/graphql
Authorization: Bearer {{tk}}
Content-Type: application/json
[Options]
retry: 60
retry-interval: 3000
{"query":"query($id: UUID!) { carbonKetQuaMrvByRowId(rowId: $id) { trangThai lyDoLoi canhId ngayChup soDiemAnhLo soDiemAnhTan dienTichTanHa co2ETan canhBao phuongPhap thamSoSha256 stacItemId cogHref phaHe } }","variables":{"id":"{{kq}}"}}
HTTP 200
[Captures]
cog: jsonpath "$.data.carbonKetQuaMrvByRowId.cogHref"
[Asserts]
jsonpath "$.data.carbonKetQuaMrvByRowId.trangThai" == "cho_duyet"
jsonpath "$.data.carbonKetQuaMrvByRowId.canhId" startsWith "S2"
jsonpath "$.data.carbonKetQuaMrvByRowId.soDiemAnhTan" > 700
jsonpath "$.data.carbonKetQuaMrvByRowId.dienTichTanHa" toFloat > 7
jsonpath "$.data.carbonKetQuaMrvByRowId.dienTichTanHa" toFloat <= 8.88
jsonpath "$.data.carbonKetQuaMrvByRowId.co2ETan" toFloat > 10
jsonpath "$.data.carbonKetQuaMrvByRowId.phuongPhap" == "v0.1-rung-ngap-man-ipcc-tier1"
jsonpath "$.data.carbonKetQuaMrvByRowId.thamSoSha256" matches "^[0-9a-f]{64}$"
jsonpath "$.data.carbonKetQuaMrvByRowId.stacItemId" == "{{kq}}"
jsonpath "$.data.carbonKetQuaMrvByRowId.cogHref" startsWith "s3://anh-ve-tinh/mrv/"
jsonpath "$.data.carbonKetQuaMrvByRowId.phaHe.canh_nguon.collection" == "sentinel-2-c1-l2a"
jsonpath "$.data.carbonKetQuaMrvByRowId.phaHe.lo_dat.ranh_gioi_sha256" matches "^[0-9a-f]{64}$"
jsonpath "$.data.carbonKetQuaMrvByRowId.phaHe.uoc_luong.he_so.g_w" == 9.4

# Sản phẩm trong danh mục STAC của nền tảng, trỏ về cảnh nguồn
GET {{gateway}}/stac/collections/carbon-mrv/items/{{kq}}
Authorization: Bearer {{tk}}
HTTP 200
[Asserts]
jsonpath "$.assets.ndvi.href" == "{{cog}}"
jsonpath "$.links[?(@.rel=='derived_from')].href" nth 0 contains "earth-search"

GET {{gateway}}/tiles/cog/info?url={{cog}}
Authorization: Bearer {{tk}}
HTTP 200
[Asserts]
jsonpath "$.dtype" == "float32"

# UC015 – từ chối phải có lý do
POST {{gateway}}/graphql
Authorization: Bearer {{tk}}
Content-Type: application/json
{"query":"mutation($id: UUID) { carbonDuyetKetQuaMrv(input: {ketQuaId: $id, dongY: false}) { result } }","variables":{"id":"{{kq}}"}}
HTTP 200
[Asserts]
jsonpath "$.errors[0].extensions.code" == "UC015"

POST {{gateway}}/graphql
Authorization: Bearer {{tk}}
Content-Type: application/json
{"query":"mutation($id: UUID) { carbonDuyetKetQuaMrv(input: {ketQuaId: $id, dongY: true, ghiChu: \"Ảnh rõ, tán khớp ranh giới\"}) { result } }","variables":{"id":"{{kq}}"}}
HTTP 200
[Asserts]
jsonpath "$.errors" not exists

# Duyệt lần hai bị chặn
POST {{gateway}}/graphql
Authorization: Bearer {{tk}}
Content-Type: application/json
{"query":"mutation($id: UUID) { carbonDuyetKetQuaMrv(input: {ketQuaId: $id, dongY: true}) { result } }","variables":{"id":"{{kq}}"}}
HTTP 200
[Asserts]
jsonpath "$.errors[0].extensions.code" == "UC014"

# Flow tiếp tục và ghi sổ cái: có mã băm commit Dolt
POST {{gateway}}/graphql
Authorization: Bearer {{tk}}
Content-Type: application/json
[Options]
retry: 30
retry-interval: 2000
{"query":"query($id: UUID!) { carbonKetQuaMrvByRowId(rowId: $id) { trangThai doltCommit soCaiSha256 } }","variables":{"id":"{{kq}}"}}
HTTP 200
[Asserts]
jsonpath "$.data.carbonKetQuaMrvByRowId.trangThai" == "da_ghi_so"
jsonpath "$.data.carbonKetQuaMrvByRowId.doltCommit" matches "^[0-9a-v]{32}$"
jsonpath "$.data.carbonKetQuaMrvByRowId.soCaiSha256" matches "^[0-9a-f]{64}$"

# Dọn: ngừng lô kiểm thử
POST {{gateway}}/graphql
Authorization: Bearer {{tk}}
Content-Type: application/json
{"query":"mutation($id: UUID!) { updateCarbonLoDatByRowId(input: {rowId: $id, carbonLoDatPatch: {trangThai: \"ngung\"}}) { carbonLoDat { trangThai } } }","variables":{"id":"{{lo}}"}}
HTTP 200
[Asserts]
jsonpath "$.data.updateCarbonLoDatByRowId.carbonLoDat.trangThai" == "ngung"
