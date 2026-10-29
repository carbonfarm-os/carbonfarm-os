#!/bin/bash
# SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors
# SPDX-License-Identifier: GPL-3.0-or-later
# Role và schema dùng chung cho API GraphQL (PostGraphile) – Tầng 1, không nghiệp vụ.
#   postgraphile   role đăng nhập của PostGraphile, NOINHERIT: chỉ có quyền khi SET ROLE sang vai bên dưới
#   vai_an_danh    không token
#   vai_nguoi_dung vai realm nguoi_dung
#   vai_quan_tri   vai realm quan_tri
# nen_tang.ghi_chu_mau là bảng MẪU để chứng minh RLS theo JWT; miền nghiệp vụ (domains/*) tạo schema và bảng riêng.
set -euo pipefail
MK=$(cat /run/bimat/postgraphile-db)
psql -v ON_ERROR_STOP=1 -v mk="$MK" --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<'SQL'
CREATE ROLE postgraphile LOGIN NOINHERIT PASSWORD :'mk';
CREATE ROLE vai_an_danh NOLOGIN;
CREATE ROLE vai_nguoi_dung NOLOGIN;
CREATE ROLE vai_quan_tri NOLOGIN;
GRANT vai_an_danh, vai_nguoi_dung, vai_quan_tri TO postgraphile;

CREATE SCHEMA nen_tang;
COMMENT ON SCHEMA nen_tang IS 'Tầng 1: hàm và bảng dùng chung, không nghiệp vụ';
GRANT USAGE ON SCHEMA nen_tang TO vai_an_danh, vai_nguoi_dung, vai_quan_tri;

-- sub của người gọi lấy từ JWT (PostGraphile đặt jwt.claims.sub cho mỗi request)
CREATE FUNCTION nen_tang.nguoi_goi() RETURNS text
LANGUAGE sql STABLE AS $$ SELECT nullif(current_setting('jwt.claims.sub', true), '') $$;
COMMENT ON FUNCTION nen_tang.nguoi_goi() IS E'@omit\nsub (Keycloak) của người gọi, rỗng nếu không có token';

CREATE TABLE nen_tang.ghi_chu_mau (
  id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  noi_dung    text NOT NULL CHECK (length(btrim(noi_dung)) BETWEEN 1 AND 500),
  chu_so_huu  text NOT NULL DEFAULT nen_tang.nguoi_goi(),
  tao_luc     timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE nen_tang.ghi_chu_mau IS 'Bảng mẫu tổng quát chứng minh RLS theo JWT: người dùng thấy ghi chú của mình, quản trị thấy tất cả';
ALTER TABLE nen_tang.ghi_chu_mau ENABLE ROW LEVEL SECURITY;
ALTER TABLE nen_tang.ghi_chu_mau FORCE ROW LEVEL SECURITY;
GRANT SELECT, INSERT (noi_dung) ON nen_tang.ghi_chu_mau TO vai_nguoi_dung, vai_quan_tri;
GRANT DELETE ON nen_tang.ghi_chu_mau TO vai_quan_tri;
CREATE POLICY nguoi_dung_xem_cua_minh ON nen_tang.ghi_chu_mau FOR SELECT TO vai_nguoi_dung
  USING (chu_so_huu = nen_tang.nguoi_goi());
CREATE POLICY nguoi_dung_them_cua_minh ON nen_tang.ghi_chu_mau FOR INSERT TO vai_nguoi_dung
  WITH CHECK (chu_so_huu = nen_tang.nguoi_goi());
CREATE POLICY quan_tri_toan_quyen ON nen_tang.ghi_chu_mau FOR ALL TO vai_quan_tri USING (true) WITH CHECK (true);
SQL
