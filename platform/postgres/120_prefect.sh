#!/bin/bash
# SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors
# SPDX-License-Identifier: GPL-3.0-or-later
# CSDL riêng cho Prefect server (trạng thái workflow). Tầng 1, không nghiệp vụ.
set -euo pipefail
MK=$(cat /run/bimat/prefect-db)
psql -v ON_ERROR_STOP=1 -v mk="$MK" --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<'SQL'
CREATE ROLE prefect LOGIN PASSWORD :'mk';
CREATE DATABASE prefect OWNER prefect;
SQL
