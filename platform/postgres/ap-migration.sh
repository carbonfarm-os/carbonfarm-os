#!/bin/sh
# SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors
# SPDX-License-Identifier: GPL-3.0-or-later
# Cơ chế migration TỔNG QUÁT của Tầng 1: áp migration của mọi miền (/mien/<miền>/db/migrations/*.sql) theo thứ tự tên,
# mỗi tệp một transaction, ghi sổ nen_tang.lich_su_migration (tên + SHA-256). Tệp đã áp mà nội dung đổi → dừng với lỗi
# (migration không được sửa, chỉ thêm tệp mới). NAP_DU_LIEU_MAU=true thì nạp thêm /mien/<miền>/db/seed/*.sql
# (dữ liệu GIẢ, viết idempotent). db/vai-dang-nhap.txt: đặt mật khẩu (từ OpenBao) cho vai đăng nhập của miền.
# Tầng 1 không biết nội dung nghiệp vụ của các tệp này.
set -eu
PGPASSWORD="$(cat /run/bimat/postgres)"
export PGPASSWORD PGHOST=postgres PGUSER=postgres PGDATABASE=nen_tang
PSQL="psql -X -q -v ON_ERROR_STOP=1"
$PSQL -c "CREATE TABLE IF NOT EXISTS nen_tang.lich_su_migration (
  ten text PRIMARY KEY, sha256 text NOT NULL, ap_luc timestamptz NOT NULL DEFAULT now())"

so=0
for f in /mien/*/db/migrations/*.sql; do   # glob của sh đã sắp theo tên
  [ -e "$f" ] || continue
  ten="${f#/mien/}"
  bam=$(sha256sum "$f" | cut -d' ' -f1)
  cu=$($PSQL -tA -c "SELECT sha256 FROM nen_tang.lich_su_migration WHERE ten = '$ten'")
  if [ -n "$cu" ]; then
    [ "$cu" = "$bam" ] || { echo "LỖI: $ten đã áp nhưng nội dung đã đổi – viết migration mới thay vì sửa" >&2; exit 1; }
    continue
  fi
  # tệp + dòng ghi sổ trong CÙNG một transaction: lỗi giữa chừng thì không áp gì, không ghi gì
  $PSQL -1 -f "$f" -c "INSERT INTO nen_tang.lich_su_migration (ten, sha256) VALUES ('$ten', '$bam')"
  echo "migration: đã áp $ten"; so=$((so + 1))
done
echo "migration: xong ($so tệp mới)"

# Vai đăng nhập của miền: /mien/<miền>/db/vai-dang-nhap.txt, mỗi dòng "<vai> <tên bí mật>" (vai do migration tạo).
# Mật khẩu đọc từ /run/bimat bằng \set của psql: không lộ trên dòng lệnh, không ghi log.
for tep in /mien/*/db/vai-dang-nhap.txt; do
  [ -e "$tep" ] || continue
  grep -v '^#' "$tep" | while read -r vai bm; do
    [ -n "$vai" ] || continue
    case "$bm" in ''|*[!a-z0-9-]*) echo "LỖI: tên bí mật không hợp lệ trong $tep: '$bm'" >&2; exit 1 ;; esac
    # shellcheck disable=SC2016 # backtick do psql thực thi (\set), không phải shell
    printf '\\set mk `cat /run/bimat/%s`\nALTER ROLE :"vai" LOGIN PASSWORD :'"'"'mk'"'"';\n' "$bm" | $PSQL -v vai="$vai"
    echo "vai đăng nhập: đã đặt mật khẩu cho $vai"
  done
done

if [ "${NAP_DU_LIEU_MAU:-false}" = "true" ]; then
  for f in /mien/*/db/seed/*.sql; do
    [ -e "$f" ] || continue
    $PSQL -1 -f "$f"; echo "dữ liệu mẫu: đã nạp ${f#/mien/}"
  done
fi
