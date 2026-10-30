# SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors
# SPDX-License-Identifier: GPL-3.0-or-later
# Tài khoản CHỈ ĐỌC của sổ cái (so_cai_doc): dịch vụ kiểm chứng công khai dùng tài khoản này, nên dù bị khai thác cũng
# không ghi hay viết lại lịch sử được. Entrypoint của image Dolt "source" tệp này (không đặt quyền thực thi) sau
# khoi-tao.sql, nên dùng được hàm exec_mysql của entrypoint. Mật khẩu do OpenBao sinh (chỉ chữ và số).
printf "CREATE USER IF NOT EXISTS 'so_cai_doc'@'%%' IDENTIFIED BY '%s';\nGRANT SELECT ON so_cai.* TO 'so_cai_doc'@'%%';\n" \
  "$(cat /run/bimat/dolt-so-cai-doc)" | exec_mysql "Không tạo được tài khoản chỉ đọc so_cai_doc: "
