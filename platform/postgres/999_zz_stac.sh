#!/bin/bash
# SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors
# SPDX-License-Identifier: GPL-3.0-or-later
# Role đăng nhập cho API STAC (stac-fastapi-pgstac). Chạy SAU script pgSTAC của image (999_pgstac.sql tạo các role
# pgstac_*), nên tên tệp xếp sau nó. Danh mục ảnh vệ tinh là dữ liệu phi cấu trúc tổng quát của Tầng 1.
set -euo pipefail
MK=$(cat /run/bimat/stac-db)
psql -v ON_ERROR_STOP=1 -v mk="$MK" --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<'SQL'
CREATE ROLE stac LOGIN PASSWORD :'mk';
GRANT pgstac_read, pgstac_ingest TO stac;
ALTER ROLE stac SET search_path = pgstac, public;
SQL
