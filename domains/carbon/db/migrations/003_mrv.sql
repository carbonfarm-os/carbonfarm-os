-- SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors
-- SPDX-License-Identifier: GPL-3.0-or-later
-- Kết quả đo đạc MRV (#25). Người dùng chỉ thao tác qua hai hàm (GraphQL); tiến trình MRV (vai carbon_mrv) ghi kết quả.
-- Vòng đời: cho_chay → dang_chay → cho_duyet → da_duyet | tu_choi → da_ghi_so (sổ cái Dolt) ; lỗi → loi.
-- Chống sai: một lô không được đo hai lần cho các kỳ chồng nhau (trừ lần bị từ chối/lỗi) – nền cho luật
-- "không cấp tín chỉ hai lần cho cùng lô và kỳ"; chỉ cán bộ hợp tác xã của lô (hoặc quản trị) được yêu cầu và duyệt.
--   UC010 kỳ đo chồng kỳ đã đo   UC011 không phải cán bộ của lô   UC012 lô không hoạt động
--   UC013 kỳ không hợp lệ        UC014 kết quả không ở trạng thái chờ duyệt   UC015 từ chối phải có lý do
CREATE EXTENSION IF NOT EXISTS btree_gist;

CREATE TABLE carbon.ket_qua_mrv (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  lo_dat_id          uuid NOT NULL REFERENCES carbon.lo_dat (id),
  ky_tu              date NOT NULL,
  ky_den             date NOT NULL,
  trang_thai         text NOT NULL DEFAULT 'cho_chay'
                     CHECK (trang_thai IN ('cho_chay', 'dang_chay', 'cho_duyet', 'da_duyet', 'tu_choi', 'da_ghi_so', 'loi')),
  nguoi_yeu_cau_sub  text NOT NULL,
  yeu_cau_luc        timestamptz NOT NULL DEFAULT now(),
  flow_run_id        uuid,
  canh_id            text,
  ngay_chup          date,
  may_phan_tram      numeric(6, 3),
  so_diem_anh_lo     integer,
  so_diem_anh_hop_le integer,
  so_diem_anh_tan    integer,
  dien_tich_tan_ha   numeric(10, 4),
  delta_c_tan        numeric(12, 3),
  co2e_tan           numeric(12, 3),
  canh_bao           text[] NOT NULL DEFAULT '{}',
  phuong_phap        text,
  tham_so_sha256     text,
  stac_item_id       text,
  cog_href           text,
  pha_he             jsonb,
  ly_do_loi          text,
  nguoi_duyet_sub    text,
  duyet_luc          timestamptz,
  ghi_chu_duyet      text,
  da_tiep_tuc        boolean NOT NULL DEFAULT false,
  dolt_commit        text,
  so_cai_sha256      text,
  ghi_so_luc         timestamptz,
  CHECK (ky_tu <= ky_den),
  CONSTRAINT ket_qua_mrv_khong_do_lai EXCLUDE USING gist (lo_dat_id WITH =, daterange(ky_tu, ky_den, '[]') WITH &&)
    WHERE (trang_thai NOT IN ('tu_choi', 'loi'))
);
CREATE INDEX ON carbon.ket_qua_mrv (lo_dat_id);
CREATE INDEX ket_qua_mrv_trang_thai ON carbon.ket_qua_mrv (trang_thai);
COMMENT ON TABLE carbon.ket_qua_mrv IS E'@behavior -insert -update -delete\nKết quả đo đạc MRV của một lô trong một kỳ, kèm phả hệ; tạo bằng carbonYeuCauMrv, duyệt bằng carbonDuyetKetQuaMrv';
COMMENT ON COLUMN carbon.ket_qua_mrv.nguoi_yeu_cau_sub IS E'@behavior -*';
COMMENT ON COLUMN carbon.ket_qua_mrv.nguoi_duyet_sub IS E'@behavior -*';
COMMENT ON COLUMN carbon.ket_qua_mrv.da_tiep_tuc IS E'@behavior -*\nCầu nối đã resume lượt chạy Prefect sau quyết định';
COMMENT ON COLUMN carbon.ket_qua_mrv.pha_he IS 'Phả hệ: phương pháp + SHA-256 tham số, ranh giới, cảnh nguồn, số điểm ảnh, hệ số, sản phẩm';

-- Hai hàm dưới chạy SECURITY DEFINER (cần ghi bảng mà người dùng chỉ được đọc) nên tự kiểm quyền: vai quản trị lấy từ
-- claim JWT (jwt.claims.vai do PostGraphile đặt), cán bộ lấy từ bảng can_bo_htx.
-- Cán bộ của hợp tác xã sở hữu lô (dùng chung cho quyền yêu cầu/duyệt)
CREATE FUNCTION carbon_noi_bo.la_can_bo_cua_lo(p_lo uuid) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
  SELECT EXISTS (
    SELECT 1 FROM carbon.lo_dat l JOIN carbon.xa_vien x ON x.id = l.xa_vien_id
      JOIN carbon.can_bo_htx c ON c.hop_tac_xa_id = x.hop_tac_xa_id
     WHERE l.id = p_lo AND c.sub = nen_tang.nguoi_goi())
$$;
GRANT EXECUTE ON FUNCTION carbon_noi_bo.la_can_bo_cua_lo(uuid) TO vai_nguoi_dung, vai_quan_tri;

GRANT SELECT ON carbon.ket_qua_mrv TO vai_nguoi_dung, vai_quan_tri;
ALTER TABLE carbon.ket_qua_mrv ENABLE ROW LEVEL SECURITY;
ALTER TABLE carbon.ket_qua_mrv FORCE ROW LEVEL SECURITY;
CREATE POLICY quan_tri ON carbon.ket_qua_mrv FOR SELECT TO vai_quan_tri USING (true);
CREATE POLICY xem ON carbon.ket_qua_mrv FOR SELECT TO vai_nguoi_dung USING (EXISTS (SELECT 1 FROM carbon.lo_dat l WHERE l.id = lo_dat_id));

-- Yêu cầu đo: cán bộ của lô hoặc quản trị
CREATE FUNCTION carbon.yeu_cau_mrv(lo_dat_id uuid, ky_tu date, ky_den date) RETURNS uuid
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = '' AS $$
DECLARE
  la_quan_tri boolean := string_to_array(current_setting('jwt.claims.vai', true), ',') @> ARRAY['quan_tri'];
  trung record;
  moi uuid;
BEGIN
  IF yeu_cau_mrv.lo_dat_id IS NULL OR yeu_cau_mrv.ky_tu IS NULL OR yeu_cau_mrv.ky_den IS NULL THEN
    RAISE EXCEPTION 'Thiếu thông tin: cần lô và kỳ đo (từ ngày – đến ngày)' USING ERRCODE = 'UC008';
  END IF;
  IF NOT la_quan_tri AND NOT carbon_noi_bo.la_can_bo_cua_lo(yeu_cau_mrv.lo_dat_id) THEN
    RAISE EXCEPTION 'Chỉ cán bộ của hợp tác xã sở hữu lô mới được yêu cầu đo đạc' USING ERRCODE = 'UC011';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM carbon.lo_dat l WHERE l.id = yeu_cau_mrv.lo_dat_id AND l.trang_thai = 'hoat_dong') THEN
    RAISE EXCEPTION 'Lô không tồn tại hoặc đã ngừng hoạt động' USING ERRCODE = 'UC012';
  END IF;
  IF yeu_cau_mrv.ky_tu > yeu_cau_mrv.ky_den OR yeu_cau_mrv.ky_den > current_date
     OR yeu_cau_mrv.ky_den - yeu_cau_mrv.ky_tu > 365 THEN
    RAISE EXCEPTION 'Kỳ đo không hợp lệ: từ ngày ≤ đến ngày ≤ hôm nay, dài tối đa 1 năm' USING ERRCODE = 'UC013';
  END IF;
  -- Khóa theo lô: hai yêu cầu đồng thời cho cùng lô xếp hàng, báo lỗi rõ thay vì lỗi ràng buộc
  PERFORM pg_advisory_xact_lock(hashtext('carbon.ket_qua_mrv:' || yeu_cau_mrv.lo_dat_id));
  SELECT k.ky_tu, k.ky_den, k.trang_thai INTO trung FROM carbon.ket_qua_mrv k
   WHERE k.lo_dat_id = yeu_cau_mrv.lo_dat_id AND k.trang_thai NOT IN ('tu_choi', 'loi')
     AND daterange(k.ky_tu, k.ky_den, '[]') && daterange(yeu_cau_mrv.ky_tu, yeu_cau_mrv.ky_den, '[]')
   LIMIT 1;
  IF FOUND THEN
    RAISE EXCEPTION 'Lô đã có kết quả đo cho kỳ % – % (trạng thái %), không đo chồng kỳ', trung.ky_tu, trung.ky_den, trung.trang_thai
      USING ERRCODE = 'UC010', HINT = 'Chọn kỳ khác, hoặc từ chối kết quả cũ trước khi đo lại.';
  END IF;
  INSERT INTO carbon.ket_qua_mrv (lo_dat_id, ky_tu, ky_den, nguoi_yeu_cau_sub)
  VALUES (yeu_cau_mrv.lo_dat_id, yeu_cau_mrv.ky_tu, yeu_cau_mrv.ky_den, coalesce(nen_tang.nguoi_goi(), 'he-thong'))
  RETURNING id INTO moi;
  RETURN moi;
END $$;
COMMENT ON FUNCTION carbon.yeu_cau_mrv(uuid, date, date) IS 'Cán bộ yêu cầu đo MRV một lô trong một kỳ; tiến trình MRV chạy flow Prefect';

-- Duyệt / từ chối: cán bộ của lô hoặc quản trị, chỉ khi đang chờ duyệt
CREATE FUNCTION carbon.duyet_ket_qua_mrv(ket_qua_id uuid, dong_y boolean, ghi_chu text DEFAULT NULL) RETURNS uuid
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = '' AS $$
DECLARE
  la_quan_tri boolean := string_to_array(current_setting('jwt.claims.vai', true), ',') @> ARRAY['quan_tri'];
  k record;
BEGIN
  SELECT * INTO k FROM carbon.ket_qua_mrv WHERE id = duyet_ket_qua_mrv.ket_qua_id FOR UPDATE;
  IF NOT FOUND OR (NOT la_quan_tri AND NOT carbon_noi_bo.la_can_bo_cua_lo(k.lo_dat_id)) THEN
    RAISE EXCEPTION 'Chỉ cán bộ của hợp tác xã sở hữu lô mới được duyệt kết quả này' USING ERRCODE = 'UC011';
  END IF;
  IF k.trang_thai <> 'cho_duyet' THEN
    RAISE EXCEPTION 'Kết quả đang ở trạng thái "%", chỉ duyệt được khi "cho_duyet"', k.trang_thai USING ERRCODE = 'UC014';
  END IF;
  IF dong_y IS NULL OR (NOT dong_y AND length(btrim(coalesce(ghi_chu, ''))) < 5) THEN
    RAISE EXCEPTION 'Từ chối phải ghi lý do (ít nhất 5 ký tự)' USING ERRCODE = 'UC015';
  END IF;
  UPDATE carbon.ket_qua_mrv
     SET trang_thai = CASE WHEN dong_y THEN 'da_duyet' ELSE 'tu_choi' END,
         nguoi_duyet_sub = coalesce(nen_tang.nguoi_goi(), 'he-thong'), duyet_luc = now(), ghi_chu_duyet = ghi_chu
   WHERE id = duyet_ket_qua_mrv.ket_qua_id;
  RETURN duyet_ket_qua_mrv.ket_qua_id;
END $$;
COMMENT ON FUNCTION carbon.duyet_ket_qua_mrv(uuid, boolean, text) IS 'Cán bộ duyệt (ghi sổ cái) hoặc từ chối (kèm lý do) kết quả MRV đang chờ duyệt';

REVOKE ALL ON FUNCTION carbon.yeu_cau_mrv(uuid, date, date), carbon.duyet_ket_qua_mrv(uuid, boolean, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION carbon.yeu_cau_mrv(uuid, date, date), carbon.duyet_ket_qua_mrv(uuid, boolean, text)
  TO vai_nguoi_dung, vai_quan_tri;

-- Vai đăng nhập của tiến trình MRV (mật khẩu do OpenBao sinh, Tầng 1 đặt theo db/vai-dang-nhap.txt)
CREATE ROLE carbon_mrv LOGIN;
GRANT USAGE ON SCHEMA carbon TO carbon_mrv;
GRANT SELECT ON carbon.lo_dat TO carbon_mrv;
GRANT SELECT, UPDATE ON carbon.ket_qua_mrv TO carbon_mrv;
CREATE POLICY mrv ON carbon.lo_dat FOR SELECT TO carbon_mrv USING (true);
CREATE POLICY mrv ON carbon.ket_qua_mrv FOR ALL TO carbon_mrv USING (true) WITH CHECK (true);
