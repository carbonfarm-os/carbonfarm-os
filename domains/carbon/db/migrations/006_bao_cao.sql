-- SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors
-- SPDX-License-Identifier: GPL-3.0-or-later
-- Báo cáo cho dashboard Metabase (#39): schema carbon_bao_cao chỉ gồm VIEW tổng hợp, không có dữ liệu cá nhân
-- (không họ tên xã viên, không sub, không ranh giới lô). Vai carbon_bao_cao (Metabase đăng nhập bằng vai này) chỉ đọc
-- được các view này, không chạm bảng gốc. View do chủ migration sở hữu nên tổng hợp được mọi hợp tác xã.
CREATE SCHEMA carbon_bao_cao;
COMMENT ON SCHEMA carbon_bao_cao IS 'View báo cáo tổng hợp cho dashboard (chỉ đọc, không dữ liệu cá nhân)';

CREATE VIEW carbon_bao_cao.tong_quan_htx AS
SELECT h.ma AS ma_htx, h.ten AS hop_tac_xa, h.tinh,
       (SELECT count(*) FROM carbon.xa_vien x WHERE x.hop_tac_xa_id = h.id) AS so_xa_vien,
       count(l.id) AS so_lo_hoat_dong,
       coalesce(round(sum(l.dien_tich_ha), 2), 0) AS dien_tich_ha
  FROM carbon.hop_tac_xa h
  LEFT JOIN carbon.xa_vien x ON x.hop_tac_xa_id = h.id
  LEFT JOIN carbon.lo_dat l ON l.xa_vien_id = x.id AND l.trang_thai = 'hoat_dong'
 GROUP BY h.id;

CREATE VIEW carbon_bao_cao.ket_qua_mrv AS
SELECT h.ten AS hop_tac_xa, l.ten AS lo_dat, k.ky_tu, k.ky_den, k.ngay_chup, k.may_phan_tram,
       k.dien_tich_tan_ha, k.co2e_tan, k.trang_thai, k.phuong_phap, k.dolt_commit
  FROM carbon.ket_qua_mrv k
  JOIN carbon.lo_dat l ON l.id = k.lo_dat_id
  JOIN carbon.xa_vien x ON x.id = l.xa_vien_id
  JOIN carbon.hop_tac_xa h ON h.id = x.hop_tac_xa_id;

CREATE VIEW carbon_bao_cao.tin_chi_htx AS
SELECT h.ten AS hop_tac_xa,
       coalesce((SELECT sum(d.so_luong) FROM carbon.de_nghi_cap d WHERE d.hop_tac_xa_id = h.id AND d.trang_thai = 'da_cap'), 0) AS da_cap,
       coalesce((SELECT sum(b.so_luong) FROM carbon.lenh_ban b WHERE b.hop_tac_xa_id = h.id AND b.trang_thai = 'hoan_tat'), 0) AS da_ban,
       coalesce((SELECT sum(k.so_luong) FROM carbon.khoi_tin_chi k WHERE k.hop_tac_xa_id = h.id), 0) AS trong_vi,
       coalesce((SELECT sum(b.thanh_tien_vnd) FROM carbon.lenh_ban b WHERE b.hop_tac_xa_id = h.id AND b.trang_thai = 'hoan_tat'), 0)
         AS doanh_thu_vnd
  FROM carbon.hop_tac_xa h;

CREATE VIEW carbon_bao_cao.giao_dich_ban AS
SELECT b.hoan_tat_luc::date AS ngay, h.ten AS hop_tac_xa, n.ten AS nguoi_mua, b.ma_trong_nuoc, b.so_luong,
       b.don_gia_vnd, b.thanh_tien_vnd, b.dolt_commit
  FROM carbon.lenh_ban b
  JOIN carbon.hop_tac_xa h ON h.id = b.hop_tac_xa_id
  JOIN carbon.nguoi_mua n ON n.ma = b.ma_nguoi_mua
 WHERE b.trang_thai = 'hoan_tat';

-- Vai chỉ đọc của Metabase (mật khẩu do OpenBao sinh, đặt theo db/vai-dang-nhap.txt)
CREATE ROLE carbon_bao_cao LOGIN;
GRANT USAGE ON SCHEMA carbon_bao_cao TO carbon_bao_cao;
GRANT SELECT ON ALL TABLES IN SCHEMA carbon_bao_cao TO carbon_bao_cao;
ALTER ROLE carbon_bao_cao SET default_transaction_read_only = on;
