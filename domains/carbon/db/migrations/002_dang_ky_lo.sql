-- SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors
-- SPDX-License-Identifier: GPL-3.0-or-later
-- Đăng ký lô đất có chống sai (Poka-yoke, #23). Luật nằm trong CSDL (trigger), nên mọi đường ghi đều bị chặn,
-- kể cả quản trị ghi thẳng bảng. Mỗi luật có mã lỗi riêng và thông báo tiếng Việt. SQLSTATE bắt đầu bằng "U" là quy ước
-- lỗi nghiệp vụ của Tầng 1: PostGraphile trả nguyên văn (extensions.code, extensions.hint) để web hiện cho người dùng.
--   UC001 ranh giới không phải GeoJSON Polygon đọc được     UC002 hình không hợp lệ (tự cắt…)
--   UC003 diện tích ngoài 0,05–500 ha                         UC004 diện tích khai báo lệch hình vẽ quá 10 %
--   UC005 chồng lấn lô đang hoạt động khác                    UC006 không có quyền với xã viên này
--   UC007 năm trồng ngoài khoảng hợp lệ                       UC008 thiếu thông tin bắt buộc

-- Năm trồng / phục hồi: phương pháp v0.1 cần để áp trần sinh khối (methodology/v0.1-…md §4.3)
ALTER TABLE carbon.lo_dat ADD COLUMN nam_trong smallint;
COMMENT ON COLUMN carbon.lo_dat.nam_trong IS 'Năm trồng hoặc phục hồi rừng (khai báo khi đăng ký)';
GRANT INSERT (nam_trong) ON carbon.lo_dat TO vai_nguoi_dung, vai_quan_tri;

-- Kiểm chồng lấn chỉ xét lô đang hoạt động; index trạng thái cũng cho API lọc condition: {trangThai}
CREATE INDEX lo_dat_hoat_dong_hinh ON carbon.lo_dat USING gist (hinh) WHERE trang_thai = 'hoat_dong';
CREATE INDEX lo_dat_trang_thai ON carbon.lo_dat (trang_thai);

CREATE FUNCTION carbon_noi_bo.kiem_tra_lo_dat() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE
  dien_tich numeric;
  lech numeric;
  trung record;
BEGIN
  IF NOT public.ST_IsValid(NEW.hinh) THEN
    RAISE EXCEPTION 'Ranh giới lô không hợp lệ: %', public.ST_IsValidReason(NEW.hinh)
      USING ERRCODE = 'UC002', HINT = 'Vẽ lại ranh giới, các cạnh không được cắt nhau.';
  END IF;

  dien_tich := round((public.ST_Area(NEW.hinh::public.geography) / 10000)::numeric, 4);
  IF dien_tich < 0.05 OR dien_tich > 500 THEN
    RAISE EXCEPTION 'Diện tích lô % ha nằm ngoài khoảng cho phép 0,05–500 ha', dien_tich
      USING ERRCODE = 'UC003';
  END IF;

  lech := abs(NEW.dien_tich_khai_bao_ha - dien_tich) / dien_tich;
  IF lech > 0.10 THEN
    RAISE EXCEPTION 'Diện tích khai báo % ha lệch % %% so với ranh giới vẽ (% ha), quá mức cho phép 10 %%',
      NEW.dien_tich_khai_bao_ha, round(lech * 100, 1), dien_tich
      USING ERRCODE = 'UC004', HINT = 'Kiểm tra lại số trên giấy tờ hoặc vẽ lại ranh giới.';
  END IF;

  IF NEW.nam_trong IS NOT NULL AND (NEW.nam_trong < 1950 OR NEW.nam_trong > extract(year FROM now())) THEN
    RAISE EXCEPTION 'Năm trồng % không hợp lệ (1950 – năm hiện tại)', NEW.nam_trong USING ERRCODE = 'UC007';
  END IF;

  IF NEW.trang_thai = 'hoat_dong' THEN
    -- Tuần tự hóa kiểm tra chồng lấn: hai lô chèn đồng thời không thể cùng lọt
    PERFORM pg_advisory_xact_lock(hashtext('carbon.lo_dat.chong_lan'));
    SELECT l.ten, round((public.ST_Area(public.ST_Intersection(l.hinh, NEW.hinh)::public.geography) / 10000)::numeric, 4) AS ha
      INTO trung
      FROM carbon.lo_dat l
     WHERE l.trang_thai = 'hoat_dong' AND l.id <> NEW.id
       AND public.ST_Intersects(l.hinh, NEW.hinh) AND NOT public.ST_Touches(l.hinh, NEW.hinh)
     LIMIT 1;
    IF FOUND THEN
      RAISE EXCEPTION 'Ranh giới chồng lấn lô đang hoạt động "%" (phần trùng % ha)', trung.ten, trung.ha
        USING ERRCODE = 'UC005', HINT = 'Hai lô chỉ được chung cạnh, không được trùm lên nhau.';
    END IF;
  END IF;
  RETURN NEW;
END $$;
REVOKE ALL ON FUNCTION carbon_noi_bo.kiem_tra_lo_dat() FROM PUBLIC;

CREATE TRIGGER kiem_tra_lo_dat
  BEFORE INSERT OR UPDATE OF hinh, dien_tich_khai_bao_ha, trang_thai, nam_trong ON carbon.lo_dat
  FOR EACH ROW EXECUTE FUNCTION carbon_noi_bo.kiem_tra_lo_dat();

-- Mutation carbonDangKyLoDat: nhận ranh giới GeoJSON (đúng thứ web vẽ ra), chạy với quyền người gọi (RLS áp dụng).
-- Trả id lô mới (đọc chi tiết bằng carbonLoDatByRowId): trả nguyên dòng lo_dat thì PostGraphile v5 dựng lại bản ghi
-- thiếu cột hình học đã ẩn khỏi API, làm lệch cột khi tính ranhGioi.
CREATE FUNCTION carbon.dang_ky_lo_dat(
  xa_vien_id uuid, ten text, ranh_gioi json, dien_tich_khai_bao_ha numeric, nam_trong integer DEFAULT NULL
) RETURNS uuid
LANGUAGE plpgsql VOLATILE SET search_path = '' AS $$
DECLARE
  hinh public.geometry;
  moi uuid;
BEGIN
  IF dang_ky_lo_dat.xa_vien_id IS NULL OR dang_ky_lo_dat.ranh_gioi IS NULL OR dang_ky_lo_dat.dien_tich_khai_bao_ha IS NULL
     OR length(btrim(coalesce(dang_ky_lo_dat.ten, ''))) < 2 THEN
    RAISE EXCEPTION 'Thiếu thông tin: cần xã viên, tên lô (ít nhất 2 ký tự), ranh giới và diện tích khai báo'
      USING ERRCODE = 'UC008';
  END IF;
  IF current_user <> 'vai_quan_tri'
     AND dang_ky_lo_dat.xa_vien_id IS DISTINCT FROM carbon_noi_bo.xa_vien_cua_toi()
     AND NOT coalesce(carbon_noi_bo.htx_cua_xa_vien(dang_ky_lo_dat.xa_vien_id) IN (SELECT carbon_noi_bo.htx_toi_phu_trach()), false) THEN
    RAISE EXCEPTION 'Bạn không có quyền đăng ký lô cho xã viên này' USING ERRCODE = 'UC006';
  END IF;

  BEGIN
    hinh := public.ST_SetSRID(public.ST_GeomFromGeoJSON(ranh_gioi::text), 4326);
  EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'Ranh giới không đọc được: cần GeoJSON Polygon, tọa độ kinh độ/vĩ độ WGS84' USING ERRCODE = 'UC001';
  END;
  IF public.GeometryType(hinh) <> 'POLYGON' THEN
    RAISE EXCEPTION 'Ranh giới phải là một đa giác (Polygon), nhận được %', public.GeometryType(hinh) USING ERRCODE = 'UC001';
  END IF;
  IF public.ST_XMin(hinh) < -180 OR public.ST_XMax(hinh) > 180 OR public.ST_YMin(hinh) < -90 OR public.ST_YMax(hinh) > 90 THEN
    RAISE EXCEPTION 'Tọa độ ngoài phạm vi kinh độ/vĩ độ' USING ERRCODE = 'UC001';
  END IF;

  INSERT INTO carbon.lo_dat (xa_vien_id, ten, hinh, dien_tich_khai_bao_ha, nam_trong)
  VALUES (dang_ky_lo_dat.xa_vien_id, dang_ky_lo_dat.ten, hinh, dang_ky_lo_dat.dien_tich_khai_bao_ha, dang_ky_lo_dat.nam_trong::smallint)
  RETURNING id INTO moi;
  RETURN moi;
END $$;
COMMENT ON FUNCTION carbon.dang_ky_lo_dat(uuid, text, json, numeric, integer) IS
  'Đăng ký lô đất từ ranh giới GeoJSON; CSDL chặn hình sai, diện tích ngoài 0,05–500 ha, lệch khai báo >10 %, chồng lấn';
REVOKE ALL ON FUNCTION carbon.dang_ky_lo_dat(uuid, text, json, numeric, integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION carbon.dang_ky_lo_dat(uuid, text, json, numeric, integer) TO vai_nguoi_dung, vai_quan_tri;
