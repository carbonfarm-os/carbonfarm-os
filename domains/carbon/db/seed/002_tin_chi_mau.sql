-- SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors
-- SPDX-License-Identifier: GPL-3.0-or-later
-- DỮ LIỆU GIẢ cho tài khoản Registry của hợp tác xã mẫu: mã số thuế, mã dự án, số tài khoản, đầu mối đều giả
-- (mã số thuế 0000000001 không thuộc tổ chức nào; email miền example.invalid). Chạy lại được.
UPDATE carbon.hop_tac_xa
   SET ma_so_thue = '0000000001', ma_du_an_tin_chi = 'DM01', so_tai_khoan_ngan_hang = '9704000000009001',
       dau_moi = '[{"ho_ten": "Cán bộ Mẫu", "chuc_vu": "Giám đốc", "email": "canbo@example.invalid", "dien_thoai": "0000000001"},
                   {"ho_ten": "Kế toán Mẫu", "chuc_vu": "Kế toán", "email": "ketoan@example.invalid", "dien_thoai": "0000000002"}]'
 WHERE id = '00000000-0000-4000-8000-0000000f0001' AND ma_so_thue IS NULL;
