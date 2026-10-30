# SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors
# SPDX-License-Identifier: GPL-3.0-or-later
# Kiểm chứng công khai (#38): KHÔNG token. Tra theo sê-ri và theo mã băm commit; SHA-256 tính lại khớp; định danh ẩn.
# Cần một lệnh bán đã hoàn tất: chạy sau carbon-tin-chi-ban.hurl (Hurl chạy tuần tự theo tên tệp).

GET {{gateway}}/kiem-chung
HTTP 200
[Asserts]
body contains "<title>"

GET {{gateway}}/kiem-chung/api/commit/khong-hop-le
HTTP 422
[Asserts]
jsonpath "$.loi" contains "32 ký tự"

GET {{gateway}}/kiem-chung/api/commit/00000000000000000000000000000000
HTTP 404

GET {{gateway}}/kiem-chung/api/seri/MCK-DM01-26-9999999999
HTTP 404

# Chỉ GET; ghi bị gateway chặn
POST {{gateway}}/kiem-chung/api/commit/00000000000000000000000000000000
HTTP 404

# Lấy một tín chỉ đã bán (quản trị đọc qua GraphQL)
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
{"query":"{ allCarbonLenhBans(condition: {trangThai: \"hoan_tat\"}) { nodes { daiSeri doltCommit } } }"}
HTTP 200
[Captures]
seri: jsonpath "$.data.allCarbonLenhBans.nodes[0].daiSeri[0].seri_tu"
commit_ban: jsonpath "$.data.allCarbonLenhBans.nodes[0].doltCommit"

# Chuỗi sự kiện của tín chỉ: MRV → cấp → bán, mọi bản ghi khớp SHA-256, chủ sở hữu là người mua
GET {{gateway}}/kiem-chung/api/seri/{{seri}}
HTTP 200
[Asserts]
jsonpath "$.toan_ven" == true
jsonpath "$.su_kien[0].loai" == "ket_qua_mrv"
jsonpath "$.su_kien[1].loai" == "cap_tin_chi"
jsonpath "$.su_kien[*].loai" contains "ban_tin_chi"
jsonpath "$.su_kien[*].sha256_khop" not contains false
jsonpath "$.chu_so_huu_theo_so_cai.ma_so_thue" == "9900000001"
jsonpath "$.su_kien[0].du_lieu.pha_he.phuong_phap" == "v0.1-rung-ngap-man-ipcc-tier1"

GET {{gateway}}/kiem-chung/api/commit/{{commit_ban}}
HTTP 200
[Asserts]
jsonpath "$.commit" == "{{commit_ban}}"
jsonpath "$.ban_ghi[0].loai" == "ban_tin_chi"
jsonpath "$.ban_ghi[0].sha256_khop" == true
jsonpath "$.ban_ghi[0].con_nguyen_ven" == true
# Định danh người dùng (sub Keycloak) không lộ ra ngoài
jsonpath "$.ban_ghi[0].du_lieu.tao_duyet.nguoi_tao_sub" == "(đã ẩn)"
jsonpath "$.ban_ghi[0].du_lieu.tao_duyet.nguoi_duyet_sub" == "(đã ẩn)"
