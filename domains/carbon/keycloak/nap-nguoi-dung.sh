#!/bin/bash
# SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors
# SPDX-License-Identifier: GPL-3.0-or-later
# Nạp người dùng MẪU của miền carbon vào realm dxos bằng partial import (id cố định để khớp dữ liệu giả).
# Đã có thì bỏ qua (SKIP). Mật khẩu do OpenBao sinh (/run/bimat), không nằm trong repo, không in ra.
set -euo pipefail
KC=/opt/keycloak/bin/kcadm.sh
$KC config credentials --server http://keycloak:8080/auth --realm master --user "${KC_ADMIN_USER:-admin}" \
  --password "$(cat /run/bimat/keycloak-admin)" >/dev/null
TAM=$(mktemp)
sed -e "s/__MK_CANBO__/$(cat /run/bimat/mk-canbo-htx-mau)/" \
    -e "s/__MK_XV1__/$(cat /run/bimat/mk-xavien-mau-1)/" \
    -e "s/__MK_XV2__/$(cat /run/bimat/mk-xavien-mau-2)/" /nguoi-dung-mau.json > "$TAM"
$KC create partialImport -r dxos -f "$TAM" -o --fields added,skipped >/dev/null
rm -f "$TAM"
echo "carbon: đã nạp người dùng mẫu (bỏ qua nếu đã có)"
