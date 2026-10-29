#!/bin/sh
# SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors
# SPDX-License-Identifier: GPL-3.0-or-later
# Khởi tạo OpenBao cho máy dev, chạy lại nhiều lần không sao (idempotent):
#   1. chờ OpenBao; nếu chưa init → init 1 khóa (máy dev), lưu khóa + root token vào /khoa (bind .data/openbao, ngoài git);
#   2. nếu đang khóa → mở khóa;
#   3. bật KV v2 ở secret/;
#   4. mỗi bí mật dịch vụ: nếu chưa có thì sinh ngẫu nhiên và ghi vào secret/nen-tang/<tên>;
#   5. ghi từng bí mật ra tệp /run/bimat/<tên> để dịch vụ đọc (*_FILE). Không in bí mật ra log.
set -eu
export BAO_ADDR="${BAO_ADDR:-http://openbao:8200}"
KHOA=/khoa/khoi-tao.txt
BI_MAT="postgres keycloak-db keycloak-admin kc-kiem-thu"

for _ in $(seq 1 60); do
  rc=0; bao status >/dev/null 2>&1 || rc=$?
  [ "$rc" -ne 1 ] && break
  sleep 1
done

if bao status 2>/dev/null | grep -q '^Initialized *false'; then
  umask 077
  bao operator init -key-shares=1 -key-threshold=1 > "$KHOA"
  echo "OpenBao: đã init, khóa lưu ở .data/openbao/khoi-tao.txt"
fi
[ -s "$KHOA" ] || { echo "Thiếu $KHOA: OpenBao đã init ở nơi khác, không mở khóa được" >&2; exit 1; }
KHOA_MO=$(awk -F': ' '/^Unseal Key 1/{print $2}' "$KHOA")
BAO_TOKEN=$(awk -F': ' '/^Initial Root Token/{print $2}' "$KHOA")
export BAO_TOKEN

if bao status 2>/dev/null | grep -q '^Sealed *true'; then
  bao operator unseal "$KHOA_MO" >/dev/null
  echo "OpenBao: đã mở khóa"
fi

bao secrets list 2>/dev/null | grep -q '^secret/' || bao secrets enable -path=secret kv-v2 >/dev/null

mkdir -p /run/bimat
for ten in $BI_MAT; do
  if ! gia_tri=$(bao kv get -field=gia_tri "secret/nen-tang/$ten" 2>/dev/null); then
    gia_tri=$(head -c 48 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c 32)
    bao kv put "secret/nen-tang/$ten" gia_tri="$gia_tri" >/dev/null
    echo "OpenBao: sinh bí mật $ten"
  fi
  printf '%s' "$gia_tri" > "/run/bimat/$ten"
  chmod 0444 "/run/bimat/$ten"
done
echo "OpenBao: sẵn sàng, đã ghi $(echo $BI_MAT | wc -w) bí mật ra /run/bimat"
