-- SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors
-- SPDX-License-Identifier: GPL-3.0-or-later
-- Miền carbon (Tầng 2): hợp tác xã, cán bộ hợp tác xã, xã viên, lô đất.
-- Quyền bằng RLS theo người gọi (nen_tang.nguoi_goi() = sub trong JWT):
--   xã viên  thấy hồ sơ và lô của mình;
--   cán bộ   thấy hợp tác xã mình phụ trách, xã viên và lô của hợp tác xã đó;
--   quản trị (vai_quan_tri) thấy tất cả.
-- Áp bởi cơ chế migration của Tầng 1 (platform/postgres/ap-migration.sh), một transaction.

CREATE SCHEMA carbon;
COMMENT ON SCHEMA carbon IS 'Miền tín chỉ carbon (Tầng 2)';
GRANT USAGE ON SCHEMA carbon TO vai_nguoi_dung, vai_quan_tri;

CREATE TABLE carbon.hop_tac_xa (
  id      uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  ma      text NOT NULL UNIQUE CHECK (ma ~ '^[A-Z0-9-]{3,32}$'),
  ten     text NOT NULL CHECK (length(btrim(ten)) BETWEEN 3 AND 200),
  tinh    text NOT NULL,
  tao_luc timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE carbon.hop_tac_xa IS 'Hợp tác xã – chủ thể được số hóa: quản lý xã viên, lô đất, hồ sơ MRV, tín chỉ';

CREATE TABLE carbon.can_bo_htx (
  sub            text NOT NULL,
  hop_tac_xa_id  uuid NOT NULL REFERENCES carbon.hop_tac_xa (id),
  ho_ten         text NOT NULL,
  PRIMARY KEY (sub, hop_tac_xa_id)
);
COMMENT ON TABLE carbon.can_bo_htx IS 'Cán bộ phụ trách hợp tác xã (sub Keycloak)';

CREATE TABLE carbon.xa_vien (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  hop_tac_xa_id  uuid NOT NULL REFERENCES carbon.hop_tac_xa (id),
  ma_xa_vien     text NOT NULL UNIQUE,
  ho_ten         text NOT NULL CHECK (length(btrim(ho_ten)) BETWEEN 2 AND 120),
  sub            text UNIQUE,
  tao_luc        timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE carbon.xa_vien IS 'Xã viên của hợp tác xã; sub là tài khoản đăng nhập (có thể chưa có)';
COMMENT ON COLUMN carbon.xa_vien.sub IS E'@behavior -*\nKhông lộ qua API';
COMMENT ON CONSTRAINT xa_vien_sub_key ON carbon.xa_vien IS E'@behavior -*';

CREATE TABLE carbon.lo_dat (
  id                     uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  xa_vien_id             uuid NOT NULL REFERENCES carbon.xa_vien (id),
  ten                    text NOT NULL CHECK (length(btrim(ten)) BETWEEN 2 AND 120),
  hinh                   geometry(Polygon, 4326) NOT NULL,
  dien_tich_khai_bao_ha  numeric(10, 4) NOT NULL,
  dien_tich_ha           numeric(10, 4) GENERATED ALWAYS AS (round((ST_Area(hinh::geography) / 10000)::numeric, 4)) STORED,
  he_sinh_thai           text NOT NULL DEFAULT 'rung_ngap_man' CHECK (he_sinh_thai IN ('rung_ngap_man')),
  trang_thai             text NOT NULL DEFAULT 'hoat_dong' CHECK (trang_thai IN ('hoat_dong', 'ngung')),
  nguoi_tao_sub          text NOT NULL DEFAULT coalesce(nen_tang.nguoi_goi(), 'he-thong'),
  tao_luc                timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX ON carbon.lo_dat USING gist (hinh);
COMMENT ON TABLE carbon.lo_dat IS E'@behavior -insert\nLô đất (ranh giới WGS84) của xã viên; MVP chỉ rừng ngập mặn. Tạo lô qua hàm đăng ký có kiểm tra (#23)';
COMMENT ON COLUMN carbon.lo_dat.hinh IS E'@behavior -*\nRanh giới; đọc qua trường ranhGioi (GeoJSON)';
COMMENT ON COLUMN carbon.lo_dat.nguoi_tao_sub IS E'@behavior -*';

-- Ranh giới dạng GeoJSON cho API (cột hình học gốc không lộ trực tiếp)
CREATE FUNCTION carbon.lo_dat_ranh_gioi(l carbon.lo_dat) RETURNS json
LANGUAGE sql STABLE AS $$ SELECT ST_AsGeoJSON(l.hinh, 7)::json $$;
COMMENT ON FUNCTION carbon.lo_dat_ranh_gioi(carbon.lo_dat) IS 'Ranh giới lô dạng GeoJSON Polygon (WGS84)';

-- Hàm quyền (SECURITY DEFINER để không vòng lặp RLS), không lộ qua API
CREATE SCHEMA carbon_noi_bo;
CREATE FUNCTION carbon_noi_bo.htx_toi_phu_trach() RETURNS SETOF uuid
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
  SELECT hop_tac_xa_id FROM carbon.can_bo_htx WHERE sub = nen_tang.nguoi_goi()
$$;
CREATE FUNCTION carbon_noi_bo.xa_vien_cua_toi() RETURNS uuid
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
  SELECT id FROM carbon.xa_vien WHERE sub = nen_tang.nguoi_goi()
$$;
CREATE FUNCTION carbon_noi_bo.htx_cua_xa_vien(p uuid) RETURNS uuid
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
  SELECT hop_tac_xa_id FROM carbon.xa_vien WHERE id = p
$$;
GRANT USAGE ON SCHEMA carbon_noi_bo TO vai_nguoi_dung, vai_quan_tri;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA carbon_noi_bo FROM PUBLIC;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA carbon_noi_bo TO vai_nguoi_dung, vai_quan_tri;

-- Quyền bảng
GRANT SELECT ON carbon.hop_tac_xa, carbon.can_bo_htx, carbon.xa_vien, carbon.lo_dat TO vai_nguoi_dung, vai_quan_tri;
GRANT INSERT (xa_vien_id, ten, hinh, dien_tich_khai_bao_ha) ON carbon.lo_dat TO vai_nguoi_dung, vai_quan_tri;
GRANT UPDATE (ten, trang_thai) ON carbon.lo_dat TO vai_nguoi_dung, vai_quan_tri;
GRANT INSERT, UPDATE ON carbon.hop_tac_xa, carbon.can_bo_htx, carbon.xa_vien TO vai_quan_tri;

ALTER TABLE carbon.hop_tac_xa ENABLE ROW LEVEL SECURITY;
ALTER TABLE carbon.can_bo_htx ENABLE ROW LEVEL SECURITY;
ALTER TABLE carbon.xa_vien ENABLE ROW LEVEL SECURITY;
ALTER TABLE carbon.lo_dat ENABLE ROW LEVEL SECURITY;
ALTER TABLE carbon.hop_tac_xa FORCE ROW LEVEL SECURITY;
ALTER TABLE carbon.can_bo_htx FORCE ROW LEVEL SECURITY;
ALTER TABLE carbon.xa_vien FORCE ROW LEVEL SECURITY;
ALTER TABLE carbon.lo_dat FORCE ROW LEVEL SECURITY;

CREATE POLICY quan_tri ON carbon.hop_tac_xa FOR ALL TO vai_quan_tri USING (true) WITH CHECK (true);
CREATE POLICY quan_tri ON carbon.can_bo_htx FOR ALL TO vai_quan_tri USING (true) WITH CHECK (true);
CREATE POLICY quan_tri ON carbon.xa_vien FOR ALL TO vai_quan_tri USING (true) WITH CHECK (true);
CREATE POLICY quan_tri ON carbon.lo_dat FOR ALL TO vai_quan_tri USING (true) WITH CHECK (true);

CREATE POLICY xem ON carbon.hop_tac_xa FOR SELECT TO vai_nguoi_dung USING (
  id IN (SELECT carbon_noi_bo.htx_toi_phu_trach())
  OR id = carbon_noi_bo.htx_cua_xa_vien(carbon_noi_bo.xa_vien_cua_toi()));
CREATE POLICY xem ON carbon.can_bo_htx FOR SELECT TO vai_nguoi_dung USING (
  sub = nen_tang.nguoi_goi() OR hop_tac_xa_id IN (SELECT carbon_noi_bo.htx_toi_phu_trach()));
CREATE POLICY xem ON carbon.xa_vien FOR SELECT TO vai_nguoi_dung USING (
  sub = nen_tang.nguoi_goi() OR hop_tac_xa_id IN (SELECT carbon_noi_bo.htx_toi_phu_trach()));
CREATE POLICY xem ON carbon.lo_dat FOR SELECT TO vai_nguoi_dung USING (
  xa_vien_id = carbon_noi_bo.xa_vien_cua_toi()
  OR carbon_noi_bo.htx_cua_xa_vien(xa_vien_id) IN (SELECT carbon_noi_bo.htx_toi_phu_trach()));
CREATE POLICY them ON carbon.lo_dat FOR INSERT TO vai_nguoi_dung WITH CHECK (
  xa_vien_id = carbon_noi_bo.xa_vien_cua_toi()
  OR carbon_noi_bo.htx_cua_xa_vien(xa_vien_id) IN (SELECT carbon_noi_bo.htx_toi_phu_trach()));
CREATE POLICY sua ON carbon.lo_dat FOR UPDATE TO vai_nguoi_dung USING (
  xa_vien_id = carbon_noi_bo.xa_vien_cua_toi()
  OR carbon_noi_bo.htx_cua_xa_vien(xa_vien_id) IN (SELECT carbon_noi_bo.htx_toi_phu_trach()));
