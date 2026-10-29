# SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors
# SPDX-License-Identifier: GPL-3.0-or-later
# Đăng ký lô có chống sai (#23): mỗi luật Poka-yoke một ca, lỗi trả mã UC00x + thông báo tiếng Việt nguyên văn.
# Người gọi là xavien-mau-1 (đăng nhập PKCE thật). Ca thành công tạo lô mới rồi chuyển "ngung" ở cuối,
# để chạy lại smoke trên cùng hệ thống không vấp luật chồng lấn.

GET {{gateway}}/auth/realms/dxos/protocol/openid-connect/auth?client_id=web&response_type=code&scope=openid&state=dk&redirect_uri=http%3A%2F%2Flocalhost%3A9080%2Fdang-nhap%2Fxong&code_challenge=E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM&code_challenge_method=S256
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
tk: jsonpath "$.access_token"

# UC001 – không phải Polygon
POST {{gateway}}/graphql
Authorization: Bearer {{tk}}
Content-Type: application/json
{"query": "mutation($xv: UUID, $ten: String, $r: JSON, $dt: BigFloat, $nam: Int) { carbonDangKyLoDat(input: {xaVienId: $xv, ten: $ten, ranhGioi: $r, dienTichKhaiBaoHa: $dt, namTrong: $nam}) { result } }", "variables": {"xv": "00000000-0000-4000-8000-0000000b0001", "ten": "Lô kiểm thử", "dt": "8.9", "nam": 2022, "r": {"type": "Point", "coordinates": [104.78, 8.63]}}}
HTTP 200
[Asserts]
jsonpath "$.data.carbonDangKyLoDat" == null
jsonpath "$.errors[0].extensions.code" == "UC001"
jsonpath "$.errors[0].message" contains "phải là một đa giác"

# UC001 – không đọc được GeoJSON
POST {{gateway}}/graphql
Authorization: Bearer {{tk}}
Content-Type: application/json
{"query": "mutation($xv: UUID, $ten: String, $r: JSON, $dt: BigFloat, $nam: Int) { carbonDangKyLoDat(input: {xaVienId: $xv, ten: $ten, ranhGioi: $r, dienTichKhaiBaoHa: $dt, namTrong: $nam}) { result } }", "variables": {"xv": "00000000-0000-4000-8000-0000000b0001", "ten": "Lô kiểm thử", "dt": "8.9", "nam": 2022, "r": {"type": "Polygon", "coordinates": "sai"}}}
HTTP 200
[Asserts]
jsonpath "$.data.carbonDangKyLoDat" == null
jsonpath "$.errors[0].extensions.code" == "UC001"
jsonpath "$.errors[0].message" contains "không đọc được"

# UC002 – hình tự cắt (nơ con bướm)
POST {{gateway}}/graphql
Authorization: Bearer {{tk}}
Content-Type: application/json
{"query": "mutation($xv: UUID, $ten: String, $r: JSON, $dt: BigFloat, $nam: Int) { carbonDangKyLoDat(input: {xaVienId: $xv, ten: $ten, ranhGioi: $r, dienTichKhaiBaoHa: $dt, namTrong: $nam}) { result } }", "variables": {"xv": "00000000-0000-4000-8000-0000000b0001", "ten": "Lô kiểm thử", "dt": "8.9", "nam": 2022, "r": {"type": "Polygon", "coordinates": [[[104.78, 8.63], [104.7827, 8.6327], [104.7827, 8.63], [104.78, 8.6327], [104.78, 8.63]]]}}}
HTTP 200
[Asserts]
jsonpath "$.data.carbonDangKyLoDat" == null
jsonpath "$.errors[0].extensions.code" == "UC002"
jsonpath "$.errors[0].message" contains "không hợp lệ"
jsonpath "$.errors[0].extensions.hint" exists

# UC003 – quá nhỏ (≈ 0,012 ha)
POST {{gateway}}/graphql
Authorization: Bearer {{tk}}
Content-Type: application/json
{"query": "mutation($xv: UUID, $ten: String, $r: JSON, $dt: BigFloat, $nam: Int) { carbonDangKyLoDat(input: {xaVienId: $xv, ten: $ten, ranhGioi: $r, dienTichKhaiBaoHa: $dt, namTrong: $nam}) { result } }", "variables": {"xv": "00000000-0000-4000-8000-0000000b0001", "ten": "Lô kiểm thử", "dt": "0.0123", "nam": 2022, "r": {"type": "Polygon", "coordinates": [[[104.78, 8.63], [104.7801, 8.63], [104.7801, 8.6301], [104.78, 8.6301], [104.78, 8.63]]]}}}
HTTP 200
[Asserts]
jsonpath "$.data.carbonDangKyLoDat" == null
jsonpath "$.errors[0].extensions.code" == "UC003"
jsonpath "$.errors[0].message" contains "0,05–500 ha"

# UC003 – quá lớn (≈ 12.000 ha)
POST {{gateway}}/graphql
Authorization: Bearer {{tk}}
Content-Type: application/json
{"query": "mutation($xv: UUID, $ten: String, $r: JSON, $dt: BigFloat, $nam: Int) { carbonDangKyLoDat(input: {xaVienId: $xv, ten: $ten, ranhGioi: $r, dienTichKhaiBaoHa: $dt, namTrong: $nam}) { result } }", "variables": {"xv": "00000000-0000-4000-8000-0000000b0001", "ten": "Lô kiểm thử", "dt": "12000", "nam": 2022, "r": {"type": "Polygon", "coordinates": [[[104.6, 8.5], [104.69999999999999, 8.5], [104.69999999999999, 8.6], [104.6, 8.6], [104.6, 8.5]]]}}}
HTTP 200
[Asserts]
jsonpath "$.data.carbonDangKyLoDat" == null
jsonpath "$.errors[0].extensions.code" == "UC003"
jsonpath "$.errors[0].message" contains "0,05–500 ha"

# UC004 – khai báo 12 ha, vẽ ≈ 8,87 ha (lệch ≈ 35 %)
POST {{gateway}}/graphql
Authorization: Bearer {{tk}}
Content-Type: application/json
{"query": "mutation($xv: UUID, $ten: String, $r: JSON, $dt: BigFloat, $nam: Int) { carbonDangKyLoDat(input: {xaVienId: $xv, ten: $ten, ranhGioi: $r, dienTichKhaiBaoHa: $dt, namTrong: $nam}) { result } }", "variables": {"xv": "00000000-0000-4000-8000-0000000b0001", "ten": "Lô kiểm thử", "dt": "12", "nam": 2022, "r": {"type": "Polygon", "coordinates": [[[104.78, 8.63], [104.7827, 8.63], [104.7827, 8.632700000000002], [104.78, 8.632700000000002], [104.78, 8.63]]]}}}
HTTP 200
[Asserts]
jsonpath "$.data.carbonDangKyLoDat" == null
jsonpath "$.errors[0].extensions.code" == "UC004"
jsonpath "$.errors[0].message" contains "quá mức cho phép 10 %"

# UC005 – chồng lấn "Lô Đất Mũi 1"
POST {{gateway}}/graphql
Authorization: Bearer {{tk}}
Content-Type: application/json
{"query": "mutation($xv: UUID, $ten: String, $r: JSON, $dt: BigFloat, $nam: Int) { carbonDangKyLoDat(input: {xaVienId: $xv, ten: $ten, ranhGioi: $r, dienTichKhaiBaoHa: $dt, namTrong: $nam}) { result } }", "variables": {"xv": "00000000-0000-4000-8000-0000000b0001", "ten": "Lô kiểm thử", "dt": "8.9", "nam": 2022, "r": {"type": "Polygon", "coordinates": [[[104.761, 8.621], [104.7637, 8.621], [104.7637, 8.623700000000001], [104.761, 8.623700000000001], [104.761, 8.621]]]}}}
HTTP 200
[Asserts]
jsonpath "$.data.carbonDangKyLoDat" == null
jsonpath "$.errors[0].extensions.code" == "UC005"
jsonpath "$.errors[0].message" contains "Lô Đất Mũi 1"

# UC006 – xã viên 1 đăng ký lô cho xã viên 2
POST {{gateway}}/graphql
Authorization: Bearer {{tk}}
Content-Type: application/json
{"query": "mutation($xv: UUID, $ten: String, $r: JSON, $dt: BigFloat, $nam: Int) { carbonDangKyLoDat(input: {xaVienId: $xv, ten: $ten, ranhGioi: $r, dienTichKhaiBaoHa: $dt, namTrong: $nam}) { result } }", "variables": {"xv": "00000000-0000-4000-8000-0000000b0002", "ten": "Lô kiểm thử", "dt": "8.9", "nam": 2022, "r": {"type": "Polygon", "coordinates": [[[104.78, 8.63], [104.7827, 8.63], [104.7827, 8.632700000000002], [104.78, 8.632700000000002], [104.78, 8.63]]]}}}
HTTP 200
[Asserts]
jsonpath "$.data.carbonDangKyLoDat" == null
jsonpath "$.errors[0].extensions.code" == "UC006"
jsonpath "$.errors[0].message" contains "không có quyền"

# UC007 – năm trồng 1800
POST {{gateway}}/graphql
Authorization: Bearer {{tk}}
Content-Type: application/json
{"query": "mutation($xv: UUID, $ten: String, $r: JSON, $dt: BigFloat, $nam: Int) { carbonDangKyLoDat(input: {xaVienId: $xv, ten: $ten, ranhGioi: $r, dienTichKhaiBaoHa: $dt, namTrong: $nam}) { result } }", "variables": {"xv": "00000000-0000-4000-8000-0000000b0001", "ten": "Lô kiểm thử", "dt": "8.9", "nam": 1800, "r": {"type": "Polygon", "coordinates": [[[104.78, 8.63], [104.7827, 8.63], [104.7827, 8.632700000000002], [104.78, 8.632700000000002], [104.78, 8.63]]]}}}
HTTP 200
[Asserts]
jsonpath "$.data.carbonDangKyLoDat" == null
jsonpath "$.errors[0].extensions.code" == "UC007"
jsonpath "$.errors[0].message" contains "Năm trồng"

# UC008 – thiếu tên lô
POST {{gateway}}/graphql
Authorization: Bearer {{tk}}
Content-Type: application/json
{"query": "mutation($xv: UUID, $ten: String, $r: JSON, $dt: BigFloat, $nam: Int) { carbonDangKyLoDat(input: {xaVienId: $xv, ten: $ten, ranhGioi: $r, dienTichKhaiBaoHa: $dt, namTrong: $nam}) { result } }", "variables": {"xv": "00000000-0000-4000-8000-0000000b0001", "ten": " ", "dt": "8.9", "nam": 2022, "r": {"type": "Polygon", "coordinates": [[[104.78, 8.63], [104.7827, 8.63], [104.7827, 8.632700000000002], [104.78, 8.632700000000002], [104.78, 8.63]]]}}}
HTTP 200
[Asserts]
jsonpath "$.data.carbonDangKyLoDat" == null
jsonpath "$.errors[0].extensions.code" == "UC008"
jsonpath "$.errors[0].message" contains "Thiếu thông tin"

# Hợp lệ – diện tích tính từ ranh giới, lệch khai báo < 10 %
POST {{gateway}}/graphql
Authorization: Bearer {{tk}}
Content-Type: application/json
{"query": "mutation($xv: UUID, $ten: String, $r: JSON, $dt: BigFloat, $nam: Int) { carbonDangKyLoDat(input: {xaVienId: $xv, ten: $ten, ranhGioi: $r, dienTichKhaiBaoHa: $dt, namTrong: $nam}) { result } }", "variables": {"xv": "00000000-0000-4000-8000-0000000b0001", "ten": "Lô kiểm thử", "dt": "8.9", "nam": 2022, "r": {"type": "Polygon", "coordinates": [[[104.78, 8.63], [104.7827, 8.63], [104.7827, 8.632700000000002], [104.78, 8.632700000000002], [104.78, 8.63]]]}}}
HTTP 200
[Captures]
lo_moi: jsonpath "$.data.carbonDangKyLoDat.result"
[Asserts]
jsonpath "$.errors" not exists

POST {{gateway}}/graphql
Authorization: Bearer {{tk}}
Content-Type: application/json
{"query":"query($id: UUID!) { carbonLoDatByRowId(rowId: $id) { ten dienTichHa namTrong trangThai ranhGioi } }","variables":{"id":"{{lo_moi}}"}}
HTTP 200
[Asserts]
jsonpath "$.errors" not exists
jsonpath "$.data.carbonLoDatByRowId.ten" == "Lô kiểm thử"
jsonpath "$.data.carbonLoDatByRowId.dienTichHa" startsWith "8.8"
jsonpath "$.data.carbonLoDatByRowId.namTrong" == 2022
jsonpath "$.data.carbonLoDatByRowId.trangThai" == "hoat_dong"
jsonpath "$.data.carbonLoDatByRowId.ranhGioi.type" == "Polygon"

# UC005 – đăng ký lại đúng lô vừa tạo
POST {{gateway}}/graphql
Authorization: Bearer {{tk}}
Content-Type: application/json
{"query": "mutation($xv: UUID, $ten: String, $r: JSON, $dt: BigFloat, $nam: Int) { carbonDangKyLoDat(input: {xaVienId: $xv, ten: $ten, ranhGioi: $r, dienTichKhaiBaoHa: $dt, namTrong: $nam}) { result } }", "variables": {"xv": "00000000-0000-4000-8000-0000000b0001", "ten": "Lô kiểm thử", "dt": "8.9", "nam": 2022, "r": {"type": "Polygon", "coordinates": [[[104.78, 8.63], [104.7827, 8.63], [104.7827, 8.632700000000002], [104.78, 8.632700000000002], [104.78, 8.63]]]}}}
HTTP 200
[Asserts]
jsonpath "$.data.carbonDangKyLoDat" == null
jsonpath "$.errors[0].extensions.code" == "UC005"
jsonpath "$.errors[0].message" contains "Lô kiểm thử"

# Chung cạnh với lô vừa tạo thì được (chạm, không trùm) – kiểm bằng lô quá nhỏ để chỉ vấp UC003, không vấp UC005
POST {{gateway}}/graphql
Authorization: Bearer {{tk}}
Content-Type: application/json
{"query": "mutation($xv: UUID, $ten: String, $r: JSON, $dt: BigFloat, $nam: Int) { carbonDangKyLoDat(input: {xaVienId: $xv, ten: $ten, ranhGioi: $r, dienTichKhaiBaoHa: $dt, namTrong: $nam}) { result } }", "variables": {"xv": "00000000-0000-4000-8000-0000000b0001", "ten": "Lô kiểm thử", "dt": "0.0123", "nam": 2022, "r": {"type": "Polygon", "coordinates": [[[104.7827, 8.63], [104.78280000000001, 8.63], [104.78280000000001, 8.6301], [104.7827, 8.6301], [104.7827, 8.63]]]}}}
HTTP 200
[Asserts]
jsonpath "$.data.carbonDangKyLoDat" == null
jsonpath "$.errors[0].extensions.code" == "UC003"
jsonpath "$.errors[0].message" contains "0,05–500 ha"

# Dọn: chuyển lô vừa tạo sang "ngung" → không còn tính chồng lấn ở lần chạy sau
POST {{gateway}}/graphql
Authorization: Bearer {{tk}}
Content-Type: application/json
{"query":"mutation($id: UUID!) { updateCarbonLoDatByRowId(input: {rowId: $id, carbonLoDatPatch: {trangThai: \"ngung\"}}) { carbonLoDat { trangThai } } }","variables":{"id":"{{lo_moi}}"}}
HTTP 200
[Asserts]
jsonpath "$.errors" not exists
jsonpath "$.data.updateCarbonLoDatByRowId.carbonLoDat.trangThai" == "ngung"
