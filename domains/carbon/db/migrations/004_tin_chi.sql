-- SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors
-- SPDX-License-Identifier: GPL-3.0-or-later
-- Cấp tín chỉ vào ví hợp tác xã (#36). 1 tín chỉ = 1 t CO2e, làm tròn XUỐNG (thận trọng).
-- Cán bộ đề nghị qua GraphQL → dòng "cho_dang_ky"; tiến trình carbon-mrv gọi Registry mock (TT 11/2026/TT-BNNMT), nhận mã
-- trong nước + dải sê-ri, ghi sổ cái Dolt, ghi khối sê-ri vào ví → "da_cap". Registry là nguồn sự thật; ví là bản phản chiếu.
--   UC020 kết quả MRV chưa ghi sổ cái   UC021 kết quả đã được đề nghị cấp   UC022 dưới 1 t CO2e
--   UC023 hợp tác xã chưa có mã số thuế / mã dự án tín chỉ

-- Thông tin hợp tác xã cần cho Registry (TT 11/2026 Điều 6: tài khoản gắn mã số thuế, tối thiểu 2 đầu mối)
ALTER TABLE carbon.hop_tac_xa
  ADD COLUMN ma_so_thue text UNIQUE CHECK (ma_so_thue ~ '^\d{10}(-\d{3})?$'),
  ADD COLUMN ma_du_an_tin_chi text UNIQUE CHECK (ma_du_an_tin_chi ~ '^[A-Z0-9]{4}$'),
  ADD COLUMN so_tai_khoan_ngan_hang text CHECK (so_tai_khoan_ngan_hang ~ '^\d{8,19}$'),
  ADD COLUMN dau_moi jsonb NOT NULL DEFAULT '[]';
COMMENT ON COLUMN carbon.hop_tac_xa.ma_du_an_tin_chi IS 'Mã dự án 4 ký tự trong mã trong nước của tín chỉ (TT 11/2026 Điều 11 khoản 4)';
COMMENT ON COLUMN carbon.hop_tac_xa.dau_moi IS E'@behavior -*\nĐầu mối liên hệ với Registry (họ tên, chức vụ, email, điện thoại)';

CREATE TABLE carbon.de_nghi_cap (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  ket_qua_mrv_id    uuid NOT NULL UNIQUE REFERENCES carbon.ket_qua_mrv (id),
  hop_tac_xa_id     uuid NOT NULL REFERENCES carbon.hop_tac_xa (id),
  so_luong          integer NOT NULL CHECK (so_luong > 0),
  trang_thai        text NOT NULL DEFAULT 'cho_dang_ky' CHECK (trang_thai IN ('cho_dang_ky', 'da_cap', 'loi')),
  nguoi_de_nghi_sub text NOT NULL,
  de_nghi_luc       timestamptz NOT NULL DEFAULT now(),
  ma_trong_nuoc     text,
  seri_tu           text,
  seri_den          text,
  cap_luc           timestamptz,
  dolt_commit       text,
  so_cai_sha256     text,
  ly_do_loi         text
);
CREATE INDEX ON carbon.de_nghi_cap (hop_tac_xa_id);
CREATE INDEX de_nghi_cap_trang_thai ON carbon.de_nghi_cap (trang_thai);
COMMENT ON TABLE carbon.de_nghi_cap IS E'@behavior -insert -update -delete\nĐề nghị cấp tín chỉ cho một kết quả MRV đã ghi sổ; mỗi kết quả chỉ một lần (UNIQUE)';
COMMENT ON COLUMN carbon.de_nghi_cap.nguoi_de_nghi_sub IS E'@behavior -*';

-- Ví: các khối sê-ri liên tiếp hợp tác xã đang giữ (bản phản chiếu tiểu khoản Đăng ký chung ở Registry)
CREATE TABLE carbon.khoi_tin_chi (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  hop_tac_xa_id  uuid NOT NULL REFERENCES carbon.hop_tac_xa (id),
  ma_trong_nuoc  text NOT NULL CHECK (ma_trong_nuoc ~ '^[A-Z0-9]{3}-[A-Z0-9]{4}-\d{2}$'),
  so_tu          bigint NOT NULL,
  so_den         bigint NOT NULL,
  so_luong       integer GENERATED ALWAYS AS ((so_den - so_tu + 1)::integer) STORED,
  de_nghi_cap_id uuid REFERENCES carbon.de_nghi_cap (id),
  CHECK (so_tu BETWEEN 1 AND so_den),
  -- Một số sê-ri không nằm trong hai khối
  CONSTRAINT khoi_tin_chi_khong_trung EXCLUDE USING gist (ma_trong_nuoc WITH =, int8range(so_tu, so_den, '[]') WITH &&)
);
CREATE INDEX ON carbon.khoi_tin_chi (hop_tac_xa_id);
CREATE INDEX ON carbon.khoi_tin_chi (de_nghi_cap_id);
COMMENT ON TABLE carbon.khoi_tin_chi IS E'@behavior -insert -update -delete\nVí tín chỉ: dải sê-ri hợp tác xã đang giữ';

CREATE FUNCTION carbon.khoi_tin_chi_seri_tu(k carbon.khoi_tin_chi) RETURNS text LANGUAGE sql STABLE AS
  $$ SELECT k.ma_trong_nuoc || '-' || lpad(k.so_tu::text, 10, '0') $$;
CREATE FUNCTION carbon.khoi_tin_chi_seri_den(k carbon.khoi_tin_chi) RETURNS text LANGUAGE sql STABLE AS
  $$ SELECT k.ma_trong_nuoc || '-' || lpad(k.so_den::text, 10, '0') $$;

-- Xem: cán bộ của hợp tác xã và xã viên của hợp tác xã đó (minh bạch trong hợp tác xã)
CREATE FUNCTION carbon_noi_bo.thuoc_htx(p_htx uuid) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
  SELECT p_htx IN (SELECT carbon_noi_bo.htx_toi_phu_trach())
      OR p_htx = carbon_noi_bo.htx_cua_xa_vien(carbon_noi_bo.xa_vien_cua_toi())
$$;
GRANT EXECUTE ON FUNCTION carbon_noi_bo.thuoc_htx(uuid) TO vai_nguoi_dung, vai_quan_tri;

GRANT SELECT ON carbon.de_nghi_cap, carbon.khoi_tin_chi TO vai_nguoi_dung, vai_quan_tri;
ALTER TABLE carbon.de_nghi_cap ENABLE ROW LEVEL SECURITY;
ALTER TABLE carbon.de_nghi_cap FORCE ROW LEVEL SECURITY;
ALTER TABLE carbon.khoi_tin_chi ENABLE ROW LEVEL SECURITY;
ALTER TABLE carbon.khoi_tin_chi FORCE ROW LEVEL SECURITY;
CREATE POLICY quan_tri ON carbon.de_nghi_cap FOR SELECT TO vai_quan_tri USING (true);
CREATE POLICY quan_tri ON carbon.khoi_tin_chi FOR SELECT TO vai_quan_tri USING (true);
CREATE POLICY xem ON carbon.de_nghi_cap FOR SELECT TO vai_nguoi_dung USING (carbon_noi_bo.thuoc_htx(hop_tac_xa_id));
CREATE POLICY xem ON carbon.khoi_tin_chi FOR SELECT TO vai_nguoi_dung USING (carbon_noi_bo.thuoc_htx(hop_tac_xa_id));

CREATE FUNCTION carbon.de_nghi_cap_tin_chi(ket_qua_mrv_id uuid) RETURNS uuid
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = '' AS $$
DECLARE
  la_quan_tri boolean := string_to_array(current_setting('jwt.claims.vai', true), ',') @> ARRAY['quan_tri'];
  k record;
  moi uuid;
BEGIN
  SELECT kq.id, kq.lo_dat_id, kq.trang_thai, kq.co2e_tan, x.hop_tac_xa_id, h.ma_so_thue, h.ma_du_an_tin_chi
    INTO k
    FROM carbon.ket_qua_mrv kq JOIN carbon.lo_dat l ON l.id = kq.lo_dat_id
    JOIN carbon.xa_vien x ON x.id = l.xa_vien_id JOIN carbon.hop_tac_xa h ON h.id = x.hop_tac_xa_id
   WHERE kq.id = de_nghi_cap_tin_chi.ket_qua_mrv_id
     FOR UPDATE OF kq;
  IF NOT FOUND OR (NOT la_quan_tri AND NOT carbon_noi_bo.la_can_bo_cua_lo(k.lo_dat_id)) THEN
    RAISE EXCEPTION 'Chỉ cán bộ của hợp tác xã sở hữu lô mới được đề nghị cấp tín chỉ' USING ERRCODE = 'UC011';
  END IF;
  IF k.trang_thai <> 'da_ghi_so' THEN
    RAISE EXCEPTION 'Kết quả đo đang ở trạng thái "%": chỉ cấp tín chỉ cho kết quả đã duyệt và ghi sổ cái', k.trang_thai
      USING ERRCODE = 'UC020';
  END IF;
  IF EXISTS (SELECT 1 FROM carbon.de_nghi_cap d WHERE d.ket_qua_mrv_id = k.id) THEN
    RAISE EXCEPTION 'Kết quả đo này đã được đề nghị cấp tín chỉ – mỗi kết quả chỉ cấp một lần' USING ERRCODE = 'UC021';
  END IF;
  IF coalesce(floor(k.co2e_tan), 0) < 1 THEN
    RAISE EXCEPTION 'Lượng hấp thụ % t CO2e chưa đủ 1 tín chỉ (1 tín chỉ = 1 t CO2e, làm tròn xuống)', coalesce(k.co2e_tan, 0)
      USING ERRCODE = 'UC022';
  END IF;
  IF k.ma_so_thue IS NULL OR k.ma_du_an_tin_chi IS NULL THEN
    RAISE EXCEPTION 'Hợp tác xã chưa khai mã số thuế hoặc mã dự án tín chỉ – cần cho tài khoản Registry' USING ERRCODE = 'UC023';
  END IF;
  INSERT INTO carbon.de_nghi_cap (ket_qua_mrv_id, hop_tac_xa_id, so_luong, nguoi_de_nghi_sub)
  VALUES (k.id, k.hop_tac_xa_id, floor(k.co2e_tan)::integer, coalesce(nen_tang.nguoi_goi(), 'he-thong'))
  RETURNING id INTO moi;
  RETURN moi;
END $$;
COMMENT ON FUNCTION carbon.de_nghi_cap_tin_chi(uuid) IS 'Cán bộ đề nghị cấp tín chỉ (làm tròn xuống) cho kết quả MRV đã ghi sổ; mỗi kết quả một lần';
REVOKE ALL ON FUNCTION carbon.de_nghi_cap_tin_chi(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION carbon.de_nghi_cap_tin_chi(uuid) TO vai_nguoi_dung, vai_quan_tri;

-- Tiến trình carbon-mrv: đọc hợp tác xã + kết quả, cập nhật đề nghị, ghi ví
GRANT SELECT ON carbon.hop_tac_xa, carbon.xa_vien TO carbon_mrv;
GRANT SELECT, UPDATE ON carbon.de_nghi_cap TO carbon_mrv;
GRANT SELECT, INSERT, UPDATE, DELETE ON carbon.khoi_tin_chi TO carbon_mrv;
CREATE POLICY mrv ON carbon.hop_tac_xa FOR SELECT TO carbon_mrv USING (true);
CREATE POLICY mrv ON carbon.xa_vien FOR SELECT TO carbon_mrv USING (true);
CREATE POLICY mrv ON carbon.de_nghi_cap FOR ALL TO carbon_mrv USING (true) WITH CHECK (true);
CREATE POLICY mrv ON carbon.khoi_tin_chi FOR ALL TO carbon_mrv USING (true) WITH CHECK (true);
