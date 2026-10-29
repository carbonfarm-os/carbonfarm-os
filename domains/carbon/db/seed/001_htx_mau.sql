-- SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors
-- SPDX-License-Identifier: GPL-3.0-or-later
-- DỮ LIỆU GIẢ cho demo: một hợp tác xã ở vùng rừng ngập mặn ven biển Mũi Cà Mau, một cán bộ, hai xã viên, hai lô.
-- Tên người và mã là giả. sub khớp id người dùng mẫu trong domains/carbon/keycloak/nguoi-dung-mau.json.
-- Chạy lại được (id cố định, ON CONFLICT DO NOTHING).
INSERT INTO carbon.hop_tac_xa (id, ma, ten, tinh) VALUES
  ('00000000-0000-4000-8000-0000000f0001', 'HTX-MAU-01', 'HTX Rừng ngập mặn Đất Mũi (dữ liệu giả)', 'Cà Mau')
ON CONFLICT (id) DO NOTHING;

INSERT INTO carbon.can_bo_htx (sub, hop_tac_xa_id, ho_ten) VALUES
  ('00000000-0000-4000-8000-0000000c0001', '00000000-0000-4000-8000-0000000f0001', 'Cán bộ Mẫu')
ON CONFLICT DO NOTHING;

INSERT INTO carbon.xa_vien (id, hop_tac_xa_id, ma_xa_vien, ho_ten, sub) VALUES
  ('00000000-0000-4000-8000-0000000b0001', '00000000-0000-4000-8000-0000000f0001', 'XV-001', 'Xã viên Mẫu Một', '00000000-0000-4000-8000-0000000a0001'),
  ('00000000-0000-4000-8000-0000000b0002', '00000000-0000-4000-8000-0000000f0001', 'XV-002', 'Xã viên Mẫu Hai', '00000000-0000-4000-8000-0000000a0002')
ON CONFLICT (id) DO NOTHING;

-- Hai lô khoảng 9 ha, không chồng lấn, trong vùng rừng ngập mặn Mũi Cà Mau (tọa độ để demo, không phải ranh giới thật)
INSERT INTO carbon.lo_dat (id, xa_vien_id, ten, hinh, dien_tich_khai_bao_ha, nguoi_tao_sub) VALUES
  ('00000000-0000-4000-8000-0000000d0001', '00000000-0000-4000-8000-0000000b0001', 'Lô Đất Mũi 1',
   ST_GeomFromText('POLYGON((104.7600 8.6200, 104.7627 8.6200, 104.7627 8.6227, 104.7600 8.6227, 104.7600 8.6200))', 4326),
   8.9, 'he-thong'),
  ('00000000-0000-4000-8000-0000000d0002', '00000000-0000-4000-8000-0000000b0002', 'Lô Đất Mũi 2',
   ST_GeomFromText('POLYGON((104.7700 8.6250, 104.7727 8.6250, 104.7727 8.6277, 104.7700 8.6277, 104.7700 8.6250))', 4326),
   8.9, 'he-thong')
ON CONFLICT (id) DO NOTHING;
