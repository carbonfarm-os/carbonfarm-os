#!/bin/bash
# SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors
# SPDX-License-Identifier: GPL-3.0-or-later
# Khởi tạo CSDL tổng quát của nền tảng (chạy một lần khi volume trống, trước script pgSTAC của image).
# Chỉ tạo thứ dùng chung: CSDL riêng cho Keycloak. Không có bảng nghiệp vụ nào ở đây.
set -euo pipefail
MK_KC=$(cat /run/bimat/keycloak-db)
psql -v ON_ERROR_STOP=1 -v mk="$MK_KC" --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<'SQL'
CREATE ROLE keycloak LOGIN PASSWORD :'mk';
CREATE DATABASE keycloak OWNER keycloak;
SQL
