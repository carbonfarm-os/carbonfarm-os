-- SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors
-- SPDX-License-Identifier: GPL-3.0-or-later
-- Bán tín chỉ cho người mua mock (#37) theo cơ chế TẠO và DUYỆT giao dịch (TT 11/2026/TT-BNNMT Điều 6 khoản 3):
-- một cán bộ tạo lệnh, cán bộ KHÁC của cùng hợp tác xã duyệt. Được duyệt → tiến trình carbon-mrv: Buyer mock chấp nhận
-- → Registry mock chuyển quyền sở hữu (sê-ri nhỏ trước) → Bank mock ghi có → sổ cái Dolt → trừ ví → "hoan_tat".
--   UC030 vượt số dư khả dụng (đã trừ lệnh đang treo)   UC031 người tạo tự duyệt
--   UC032 lệnh không ở trạng thái chờ duyệt              UC033 người mua không có trong danh sách
--   (dùng lại UC011 quyền cán bộ, UC015 từ chối phải có lý do, UC008 thiếu thông tin)

-- Danh sách người mua: tiến trình carbon-mrv đồng bộ từ Buyer mock (connector là nguồn sự thật)
CREATE TABLE carbon.nguoi_mua (
  ma                  text PRIMARY KEY,
  ten                 text NOT NULL,
  ma_so_thue          text NOT NULL,
  don_gia_toi_da_vnd  bigint NOT NULL,
  cap_nhat_luc        timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE carbon.nguoi_mua IS E'@behavior -insert -update -delete\nNgười mua (đồng bộ từ Buyer connector)';

CREATE TABLE carbon.lenh_ban (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  hop_tac_xa_id    uuid NOT NULL REFERENCES carbon.hop_tac_xa (id),
  ma_nguoi_mua     text NOT NULL REFERENCES carbon.nguoi_mua (ma),
  ma_trong_nuoc    text NOT NULL,
  so_luong         integer NOT NULL CHECK (so_luong > 0),
  don_gia_vnd      bigint NOT NULL CHECK (don_gia_vnd > 0),
  thanh_tien_vnd   bigint GENERATED ALWAYS AS (so_luong * don_gia_vnd) STORED,
  trang_thai       text NOT NULL DEFAULT 'cho_duyet'
                   CHECK (trang_thai IN ('cho_duyet', 'da_duyet', 'tu_choi', 'hoan_tat', 'loi')),
  nguoi_tao_sub    text NOT NULL,
  tao_luc          timestamptz NOT NULL DEFAULT now(),
  nguoi_duyet_sub  text,
  duyet_luc        timestamptz,
  ghi_chu_duyet    text,
  dai_seri         jsonb,
  ma_giao_dich_bank text,
  hoan_tat_luc     timestamptz,
  dolt_commit      text,
  so_cai_sha256    text,
  ly_do_loi        text
);
CREATE INDEX ON carbon.lenh_ban (hop_tac_xa_id);
CREATE INDEX lenh_ban_trang_thai ON carbon.lenh_ban (trang_thai);
COMMENT ON TABLE carbon.lenh_ban IS E'@behavior -insert -update -delete\nLệnh bán tín chỉ: một cán bộ tạo, cán bộ khác duyệt';
COMMENT ON COLUMN carbon.lenh_ban.nguoi_tao_sub IS E'@behavior -*';
COMMENT ON COLUMN carbon.lenh_ban.nguoi_duyet_sub IS E'@behavior -*';

-- Người đang đăng nhập có phải người tạo lệnh không (để web ẩn nút duyệt; CSDL vẫn chặn UC031)
CREATE FUNCTION carbon.lenh_ban_do_toi_tao(l carbon.lenh_ban) RETURNS boolean LANGUAGE sql STABLE AS
  $$ SELECT l.nguoi_tao_sub = nen_tang.nguoi_goi() $$;

GRANT SELECT ON carbon.nguoi_mua, carbon.lenh_ban TO vai_nguoi_dung, vai_quan_tri;
ALTER TABLE carbon.nguoi_mua ENABLE ROW LEVEL SECURITY;
ALTER TABLE carbon.nguoi_mua FORCE ROW LEVEL SECURITY;
ALTER TABLE carbon.lenh_ban ENABLE ROW LEVEL SECURITY;
ALTER TABLE carbon.lenh_ban FORCE ROW LEVEL SECURITY;
CREATE POLICY xem ON carbon.nguoi_mua FOR SELECT TO vai_nguoi_dung, vai_quan_tri USING (true);
CREATE POLICY quan_tri ON carbon.lenh_ban FOR SELECT TO vai_quan_tri USING (true);
CREATE POLICY xem ON carbon.lenh_ban FOR SELECT TO vai_nguoi_dung USING (carbon_noi_bo.thuoc_htx(hop_tac_xa_id));

-- Số dư khả dụng = ví − các lệnh chưa kết thúc (chờ duyệt, đã duyệt đang xử lý)
CREATE FUNCTION carbon_noi_bo.so_du_kha_dung(p_htx uuid, p_ma text) RETURNS bigint
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
  SELECT coalesce((SELECT sum(so_luong) FROM carbon.khoi_tin_chi WHERE hop_tac_xa_id = p_htx AND ma_trong_nuoc = p_ma), 0)
       - coalesce((SELECT sum(so_luong) FROM carbon.lenh_ban WHERE hop_tac_xa_id = p_htx AND ma_trong_nuoc = p_ma
                     AND trang_thai IN ('cho_duyet', 'da_duyet')), 0)
$$;

CREATE FUNCTION carbon.tao_lenh_ban(hop_tac_xa_id uuid, ma_nguoi_mua text, ma_trong_nuoc text, so_luong integer, don_gia_vnd bigint)
RETURNS uuid LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = '' AS $$
DECLARE
  co bigint;
  moi uuid;
BEGIN
  IF tao_lenh_ban.hop_tac_xa_id IS NULL OR tao_lenh_ban.ma_trong_nuoc IS NULL OR coalesce(tao_lenh_ban.so_luong, 0) <= 0
     OR coalesce(tao_lenh_ban.don_gia_vnd, 0) <= 0 THEN
    RAISE EXCEPTION 'Thiếu thông tin: cần hợp tác xã, mã tín chỉ, số lượng và đơn giá dương' USING ERRCODE = 'UC008';
  END IF;
  IF tao_lenh_ban.hop_tac_xa_id NOT IN (SELECT carbon_noi_bo.htx_toi_phu_trach()) THEN
    RAISE EXCEPTION 'Chỉ cán bộ của hợp tác xã mới được tạo lệnh bán tín chỉ' USING ERRCODE = 'UC011';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM carbon.nguoi_mua n WHERE n.ma = tao_lenh_ban.ma_nguoi_mua) THEN
    RAISE EXCEPTION 'Người mua "%" không có trong danh sách', tao_lenh_ban.ma_nguoi_mua USING ERRCODE = 'UC033';
  END IF;
  -- Khóa theo hợp tác xã: hai lệnh tạo đồng thời không cùng vượt số dư
  PERFORM pg_advisory_xact_lock(hashtext('carbon.lenh_ban:' || tao_lenh_ban.hop_tac_xa_id));
  co := carbon_noi_bo.so_du_kha_dung(tao_lenh_ban.hop_tac_xa_id, tao_lenh_ban.ma_trong_nuoc);
  IF tao_lenh_ban.so_luong > co THEN
    RAISE EXCEPTION 'Vượt số dư khả dụng: còn % tín chỉ % (đã trừ lệnh đang chờ), đề nghị bán %',
      co, tao_lenh_ban.ma_trong_nuoc, tao_lenh_ban.so_luong USING ERRCODE = 'UC030';
  END IF;
  INSERT INTO carbon.lenh_ban (hop_tac_xa_id, ma_nguoi_mua, ma_trong_nuoc, so_luong, don_gia_vnd, nguoi_tao_sub)
  VALUES (tao_lenh_ban.hop_tac_xa_id, tao_lenh_ban.ma_nguoi_mua, tao_lenh_ban.ma_trong_nuoc, tao_lenh_ban.so_luong,
          tao_lenh_ban.don_gia_vnd, nen_tang.nguoi_goi())
  RETURNING id INTO moi;
  RETURN moi;
END $$;
COMMENT ON FUNCTION carbon.tao_lenh_ban(uuid, text, text, integer, bigint) IS
  'Cán bộ tạo lệnh bán tín chỉ cho người mua; cần cán bộ khác duyệt (TT 11/2026 Điều 6 khoản 3)';

CREATE FUNCTION carbon.duyet_lenh_ban(lenh_ban_id uuid, dong_y boolean, ghi_chu text DEFAULT NULL) RETURNS uuid
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = '' AS $$
DECLARE
  l record;
BEGIN
  SELECT * INTO l FROM carbon.lenh_ban WHERE id = duyet_lenh_ban.lenh_ban_id FOR UPDATE;
  IF NOT FOUND OR l.hop_tac_xa_id NOT IN (SELECT carbon_noi_bo.htx_toi_phu_trach()) THEN
    RAISE EXCEPTION 'Chỉ cán bộ của hợp tác xã mới được duyệt lệnh bán' USING ERRCODE = 'UC011';
  END IF;
  IF l.nguoi_tao_sub = nen_tang.nguoi_goi() THEN
    RAISE EXCEPTION 'Người tạo lệnh không được tự duyệt – cần cán bộ khác (TT 11/2026/TT-BNNMT Điều 6 khoản 3)'
      USING ERRCODE = 'UC031';
  END IF;
  IF l.trang_thai <> 'cho_duyet' THEN
    RAISE EXCEPTION 'Lệnh đang ở trạng thái "%", chỉ duyệt được khi "cho_duyet"', l.trang_thai USING ERRCODE = 'UC032';
  END IF;
  IF dong_y IS NULL OR (NOT dong_y AND length(btrim(coalesce(ghi_chu, ''))) < 5) THEN
    RAISE EXCEPTION 'Từ chối phải ghi lý do (ít nhất 5 ký tự)' USING ERRCODE = 'UC015';
  END IF;
  UPDATE carbon.lenh_ban
     SET trang_thai = CASE WHEN dong_y THEN 'da_duyet' ELSE 'tu_choi' END,
         nguoi_duyet_sub = nen_tang.nguoi_goi(), duyet_luc = now(), ghi_chu_duyet = ghi_chu
   WHERE id = duyet_lenh_ban.lenh_ban_id;
  RETURN duyet_lenh_ban.lenh_ban_id;
END $$;
COMMENT ON FUNCTION carbon.duyet_lenh_ban(uuid, boolean, text) IS 'Cán bộ khác người tạo duyệt hoặc từ chối (kèm lý do) lệnh bán';

REVOKE ALL ON FUNCTION carbon.tao_lenh_ban(uuid, text, text, integer, bigint), carbon.duyet_lenh_ban(uuid, boolean, text)
  FROM PUBLIC;
GRANT EXECUTE ON FUNCTION carbon.tao_lenh_ban(uuid, text, text, integer, bigint), carbon.duyet_lenh_ban(uuid, boolean, text)
  TO vai_nguoi_dung;

GRANT SELECT, INSERT, UPDATE ON carbon.nguoi_mua TO carbon_mrv;
GRANT SELECT, UPDATE ON carbon.lenh_ban TO carbon_mrv;
CREATE POLICY mrv ON carbon.nguoi_mua FOR ALL TO carbon_mrv USING (true) WITH CHECK (true);
CREATE POLICY mrv ON carbon.lenh_ban FOR ALL TO carbon_mrv USING (true) WITH CHECK (true);
