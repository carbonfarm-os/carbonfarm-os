# SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors
# SPDX-License-Identifier: GPL-3.0-or-later
# Connector mock (#35) gọi trực tiếp trong mạng nội bộ, đúng hợp đồng connectors/<tên>/openapi.yaml.
# Registry theo TT 11/2026/TT-BNNMT: tài khoản gắn mã số thuế (Điều 6), mã trong nước + số sê-ri (Điều 11), bù trừ (Điều 20).
# Chạy lại được: tài khoản đã có thì 409; mã tham chiếu sinh mới mỗi lần.

GET {{registry}}/suc-khoe
HTTP 200

# Thiếu khóa → 401
GET {{registry}}/tai-khoan/0000000001
HTTP 401

GET {{registry}}/tai-khoan/0000000001
Authorization: Bearer sai-khoa
HTTP 401

# Tài khoản cần tối thiểu 2 đầu mối (Điều 6 khoản 4)
POST {{registry}}/tai-khoan
Authorization: Bearer {{bm_ket_noi_registry}}
{"ma_so_thue":"0000000999","ten_to_chuc":"HTX thiếu đầu mối","dau_moi":[{"ho_ten":"Người Một","chuc_vu":"Giám đốc","email":"a@example.invalid","dien_thoai":"0000000000"}]}
HTTP 422

POST {{registry}}/tai-khoan
Authorization: Bearer {{bm_ket_noi_registry}}
{"ma_so_thue":"0000000001","ten_to_chuc":"HTX Rừng ngập mặn Đất Mũi (dữ liệu giả)","dau_moi":[{"ho_ten":"Cán bộ Mẫu","chuc_vu":"Giám đốc","email":"canbo@example.invalid","dien_thoai":"0000000001"},{"ho_ten":"Kế toán Mẫu","chuc_vu":"Kế toán","email":"ketoan@example.invalid","dien_thoai":"0000000002"}]}
HTTP *
[Asserts]
status toString matches "^(201|409)$"

POST {{registry}}/tai-khoan
Authorization: Bearer {{bm_ket_noi_registry}}
{"ma_so_thue":"9900000001","ten_to_chuc":"Công ty Năng lượng Xanh Mẫu (giả)","dau_moi":[{"ho_ten":"Người Mua Một","chuc_vu":"Giám đốc","email":"mua1@example.invalid","dien_thoai":"0000000003"},{"ho_ten":"Người Mua Hai","chuc_vu":"Kế toán","email":"mua2@example.invalid","dien_thoai":"0000000004"}]}
HTTP *
[Asserts]
status toString matches "^(201|409)$"

# Mỗi tổ chức chỉ một tài khoản (Điều 6 khoản 1)
POST {{registry}}/tai-khoan
Authorization: Bearer {{bm_ket_noi_registry}}
{"ma_so_thue":"0000000001","ten_to_chuc":"Tài khoản thứ hai","dau_moi":[{"ho_ten":"A Một","chuc_vu":"x","email":"x@example.invalid","dien_thoai":"0"},{"ho_ten":"B Hai","chuc_vu":"y","email":"y@example.invalid","dien_thoai":"0"}]}
HTTP 409

# Đăng ký 10 tín chỉ: mã trong nước [cơ chế]-[dự án]-[YY], sê-ri = mã + 10 chữ số (Điều 11)
POST {{registry}}/tin-chi/dang-ky
Authorization: Bearer {{bm_ket_noi_registry}}
{"ma_so_thue":"0000000001","ten_du_an":"Rừng ngập mặn Đất Mũi (giả)","ma_du_an":"CF01","ten_co_che":"Cơ chế mock","ma_co_che":"MCK","nam_xac_nhan":2026,"so_luong":10,"ma_tham_chieu":"dk-{{newUuid}}"}
HTTP 201
[Captures]
ref_dk: jsonpath "$.ma_tham_chieu"
seri_dau: jsonpath "$.dai_seri[0].seri_tu"
[Asserts]
jsonpath "$.dai_seri[0].ma_trong_nuoc" == "MCK-CF01-26"
jsonpath "$.dai_seri[0].seri_tu" matches "^MCK-CF01-26-\\d{10}$"
jsonpath "$.dai_seri[0].so_luong" == 10

# Cùng mã tham chiếu → không cấp lần hai
POST {{registry}}/tin-chi/dang-ky
Authorization: Bearer {{bm_ket_noi_registry}}
{"ma_so_thue":"0000000001","ten_du_an":"Rừng ngập mặn Đất Mũi (giả)","ma_du_an":"CF01","ten_co_che":"Cơ chế mock","ma_co_che":"MCK","nam_xac_nhan":2026,"so_luong":10,"ma_tham_chieu":"{{ref_dk}}"}
HTTP 409

# Mã dự án sai định dạng (cần 4 ký tự)
POST {{registry}}/tin-chi/dang-ky
Authorization: Bearer {{bm_ket_noi_registry}}
{"ma_so_thue":"0000000001","ten_du_an":"Sai mã","ma_du_an":"CF1","ten_co_che":"x","ma_co_che":"MCK","nam_xac_nhan":2026,"so_luong":1,"ma_tham_chieu":"dk-{{newUuid}}"}
HTTP 422

# Chuyển 4 tín chỉ cho người mua (sê-ri nhỏ trước)
POST {{registry}}/tin-chi/chuyen-quyen
Authorization: Bearer {{bm_ket_noi_registry}}
{"tu_ma_so_thue":"0000000001","den_ma_so_thue":"9900000001","ma_trong_nuoc":"MCK-CF01-26","so_luong":4,"ma_tham_chieu":"cq-{{newUuid}}"}
HTTP 201
[Captures]
seri_mua: jsonpath "$.dai_seri[0].seri_tu"
[Asserts]
jsonpath "$.dai_seri" count >= 1
jsonpath "$.nghiep_vu" == "chuyen_quyen"

GET {{registry}}/tin-chi/seri/{{seri_mua}}
Authorization: Bearer {{bm_ket_noi_registry}}
HTTP 200
[Asserts]
jsonpath "$.chu_so_huu" == "9900000001"
jsonpath "$.tieu_khoan" == "dang_ky_chung"
jsonpath "$.lich_su[0].nghiep_vu" == "dang_ky"
jsonpath "$.lich_su[*].nghiep_vu" contains "chuyen_quyen"

# Vượt số dư → từ chối
POST {{registry}}/tin-chi/chuyen-quyen
Authorization: Bearer {{bm_ket_noi_registry}}
{"tu_ma_so_thue":"0000000001","den_ma_so_thue":"9900000001","ma_trong_nuoc":"MCK-CF01-26","so_luong":999999999,"ma_tham_chieu":"cq-{{newUuid}}"}
HTTP 422
[Asserts]
jsonpath "$.detail" contains "Vượt số dư"

# Người mua dùng 1 tín chỉ để bù trừ → tiểu khoản Bù trừ (Điều 20)
POST {{registry}}/tin-chi/bu-tru
Authorization: Bearer {{bm_ket_noi_registry}}
{"ma_so_thue":"9900000001","ma_trong_nuoc":"MCK-CF01-26","so_luong":1,"ma_tham_chieu":"bt-{{newUuid}}"}
HTTP 201
[Captures]
seri_bt: jsonpath "$.dai_seri[0].seri_tu"

GET {{registry}}/tin-chi/seri/{{seri_bt}}
Authorization: Bearer {{bm_ket_noi_registry}}
HTTP 200
[Asserts]
jsonpath "$.tieu_khoan" == "bu_tru"

GET {{registry}}/tai-khoan/9900000001
Authorization: Bearer {{bm_ket_noi_registry}}
HTTP 200
[Asserts]
jsonpath "$.so_du.bu_tru" >= 1

# ---------- Buyer ----------
GET {{buyer}}/nguoi-mua
HTTP 401

GET {{buyer}}/nguoi-mua
Authorization: Bearer {{bm_ket_noi_buyer}}
HTTP 200
[Asserts]
jsonpath "$[0].ma" == "NM-XANH"
jsonpath "$[0].ma_so_thue" == "9900000001"

POST {{buyer}}/don-mua
Authorization: Bearer {{bm_ket_noi_buyer}}
{"ma_nguoi_mua":"NM-XANH","so_luong":4,"don_gia_vnd":999999,"ma_tham_chieu":"dm-{{newUuid}}"}
HTTP 422
[Asserts]
jsonpath "$.detail" contains "đơn giá tối đa"

POST {{buyer}}/don-mua
Authorization: Bearer {{bm_ket_noi_buyer}}
{"ma_nguoi_mua":"NM-XANH","so_luong":4,"don_gia_vnd":200000,"ma_tham_chieu":"dm-{{newUuid}}"}
HTTP 201
[Captures]
ref_dm: jsonpath "$.ma_tham_chieu"
[Asserts]
jsonpath "$.thanh_tien_vnd" == 800000
jsonpath "$.trang_thai" == "chap_nhan"

POST {{buyer}}/don-mua
Authorization: Bearer {{bm_ket_noi_buyer}}
{"ma_nguoi_mua":"NM-XANH","so_luong":4,"don_gia_vnd":200000,"ma_tham_chieu":"{{ref_dm}}"}
HTTP 201
[Asserts]
jsonpath "$.ma_tham_chieu" == "{{ref_dm}}"

# ---------- Bank ----------
POST {{bank}}/ghi-co
Authorization: Bearer {{bm_ket_noi_bank}}
{"so_tai_khoan":"9704000000009999","so_tien_vnd":800000,"noi_dung":"Bán 4 tín chỉ (kiểm thử)","ma_tham_chieu":"{{ref_dm}}"}
HTTP 201

# Gửi lại cùng mã: không cộng hai lần
POST {{bank}}/ghi-co
Authorization: Bearer {{bm_ket_noi_bank}}
{"so_tai_khoan":"9704000000009999","so_tien_vnd":800000,"noi_dung":"Bán 4 tín chỉ (kiểm thử)","ma_tham_chieu":"{{ref_dm}}"}
HTTP 201

POST {{bank}}/ghi-co
Authorization: Bearer {{bm_ket_noi_bank}}
{"so_tai_khoan":"9704000000009999","so_tien_vnd":1,"noi_dung":"Khác số tiền","ma_tham_chieu":"{{ref_dm}}"}
HTTP 409

GET {{bank}}/tai-khoan/9704000000009999
Authorization: Bearer {{bm_ket_noi_bank}}
HTTP 200
[Asserts]
jsonpath "$.giao_dich[?(@.ma_tham_chieu=='{{ref_dm}}')]" count == 1
