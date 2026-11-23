# SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors
# SPDX-License-Identifier: GPL-3.0-or-later
"""Kiểm thử đơn vị công thức phương pháp v0.1 trên tệp tham số thật trong methodology/ (không cần mạng, không cần GDAL).

Chạy: python3 -m unittest discover -s domains/carbon/mrv/tests   (cần pyyaml)
"""
from __future__ import annotations

import sys
import unittest
from datetime import date
from pathlib import Path

GOC = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(GOC / "domains/carbon/mrv"))

from mrv.phuong_phap import doc_tham_so, mo_ta_khong_du_anh, uoc_luong

PB = "v0.1-rung-ngap-man-ipcc-tier1"


class PhuongPhapV01(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.ts, cls.sha = doc_tham_so(PB, GOC / "methodology")

    def test_he_so_can_duoi_ktc_va_sha(self):
        h = self.ts["he_so"]
        self.assertEqual((h["cf"]["dung"], h["g_w_t_ha_nam"]["dung"], h["r"]["dung"], h["b_max_t_ha"]["dung"]),
                         (0.429, 9.4, 0.47, 187))
        for k in ("cf", "g_w_t_ha_nam", "r", "b_max_t_ha"):
            self.assertEqual(h[k]["dung"], h[k]["ktc95"][0], f"{k} phải dùng cận dưới KTC 95 %")
        self.assertRegex(self.sha, r"^[0-9a-f]{64}$")

    def test_mot_ha_mot_nam_bang_he_so_tong_hop(self):
        kq = uoc_luong(self.ts, 1.0, date(2025, 1, 1), date(2025, 12, 31), 2018, 1.0)
        self.assertAlmostEqual(kq["co2e_tan"], 21.736, places=2)  # 9,4 × 1,47 × 0,429 × 44/12
        self.assertEqual(kq["canh_bao"], [])

    def test_ky_30_ngay_ti_le_theo_ngay(self):
        kq = uoc_luong(self.ts, 9.0, date(2026, 4, 1), date(2026, 4, 30), 2019, 8.8746)
        self.assertEqual(kq["so_ngay"], 30)
        self.assertEqual(kq["dien_tich_tinh_ha"], 8.8746, "A không vượt diện tích lô")
        self.assertAlmostEqual(kq["co2e_tan"], 8.8746 * 21.7357 * 30 / 365, places=2)

    def test_cham_tran_sinh_khoi(self):
        # 187 / 9,4 ≈ 19,9 năm: rừng trồng 1990 đã đạt trần → không ghi nhận tăng
        kq = uoc_luong(self.ts, 5.0, date(2026, 1, 1), date(2026, 3, 31), 1990, 5.0)
        self.assertEqual(kq["co2e_tan"], 0)
        self.assertIn("cham_tran_sinh_khoi", kq["canh_bao"])

    def test_thieu_nam_trong_chuyen_duyet_tay(self):
        kq = uoc_luong(self.ts, 5.0, date(2026, 1, 1), date(2026, 3, 31), None, 5.0)
        self.assertIsNone(kq["co2e_tan"])
        self.assertIn("thieu_nam_trong", kq["canh_bao"])

    def test_mat_tan_lay_dien_tich_nho_hon_va_gan_co(self):
        kq = uoc_luong(self.ts, 7.0, date(2026, 4, 1), date(2026, 4, 30), 2019, 9.0, dien_tich_tan_ky_truoc_ha=8.5)
        self.assertEqual(kq["dien_tich_tinh_ha"], 7.0)
        self.assertIn("mat_tan", kq["canh_bao"])
        kq = uoc_luong(self.ts, 8.9, date(2026, 4, 1), date(2026, 4, 30), 2019, 9.0, dien_tich_tan_ky_truoc_ha=8.5)
        self.assertEqual(kq["dien_tich_tinh_ha"], 8.5, "tán tăng không được tính quá kỳ trước")
        self.assertNotIn("mat_tan", kq["canh_bao"])

    # --- Ca biên (#90): kiểm đúng hành vi hiện tại của hàm ---

    def test_tan_bang_0_thi_co2e_bang_0(self):
        kq = uoc_luong(self.ts, 0.0, date(2026, 4, 1), date(2026, 4, 30), 2019, 8.8746)
        self.assertEqual(kq["dien_tich_tinh_ha"], 0)
        self.assertEqual(kq["co2e_tan"], 0)
        self.assertEqual(kq["canh_bao"], [])

    def test_ky_mot_ngay_tinh_ca_hai_dau(self):
        # Từ ngày = đến ngày: kỳ dài 1 ngày (hai đầu đều tính), không phải 0
        kq = uoc_luong(self.ts, 1.0, date(2026, 4, 1), date(2026, 4, 1), 2019, 1.0)
        self.assertEqual(kq["so_ngay"], 1)
        self.assertAlmostEqual(kq["co2e_tan"], 21.7357 / 365, places=3)

    def test_ky_do_dai_0_ngay_thi_co2e_bang_0(self):
        # Đến ngày ngay trước từ ngày → 0 ngày. CSDL đã chặn kỳ ngược bằng UC013 (003_mrv.sql) trước khi tới hàm.
        kq = uoc_luong(self.ts, 1.0, date(2026, 4, 2), date(2026, 4, 1), 2019, 1.0)
        self.assertEqual(kq["so_ngay"], 0)
        self.assertEqual(kq["co2e_tan"], 0)

    def test_nam_trong_sau_ngay_do_hien_tai_van_tinh_ca_ky(self):
        # Hành vi hiện tại: tuổi rừng âm không bị chặn, kỳ vẫn tính đủ và không gắn cảnh báo.
        # CSDL chỉ chặn năm trồng > năm hiện tại (UC007), chưa so với kỳ đo.
        kq = uoc_luong(self.ts, 1.0, date(2025, 1, 1), date(2025, 12, 31), 2026, 1.0)
        self.assertEqual(kq["so_ngay"], 365)
        self.assertEqual(kq["nam_tinh"], 1.0)
        self.assertAlmostEqual(kq["co2e_tan"], 21.736, places=2)
        self.assertEqual(kq["canh_bao"], [])

    def test_vuot_tran_giua_ky_chi_tinh_phan_toi_tran(self):
        # Trần đạt sau 187 / 9,4 ≈ 19,894 năm; rừng trồng 2006, kỳ 2025 → còn ≈ 0,894 năm trong kỳ 1 năm
        kq = uoc_luong(self.ts, 1.0, date(2025, 1, 1), date(2025, 12, 31), 2006, 1.0)
        con_lai = 187 / 9.4 - (date(2025, 1, 1) - date(2006, 1, 1)).days / 365.25
        self.assertAlmostEqual(kq["nam_tinh"], con_lai, places=5)
        self.assertIn("cham_tran_sinh_khoi", kq["canh_bao"])
        self.assertAlmostEqual(kq["co2e_tan"], 21.7357 * con_lai, places=2)

    def test_phien_ban_khong_ton_tai_bao_loi(self):
        with self.assertRaises(FileNotFoundError) as loi:
            doc_tham_so("v9.9-khong-co", GOC / "methodology")
        self.assertIn("v9.9-khong-co.yaml", str(loi.exception))

    def test_tep_khai_sai_phien_ban_bao_loi(self):
        import tempfile

        with tempfile.TemporaryDirectory() as tm:
            (Path(tm) / "v0.2-thu.yaml").write_text("phien_ban: v0.1-rung-ngap-man-ipcc-tier1\n", encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "cần 'v0.2-thu'"):
                doc_tham_so("v0.2-thu", Path(tm))

    def test_khop_vi_du_tinh_tay_muc_4_5(self):
        # methodology §4.5: Lô Đất Mũi 1, 8,8746 ha toàn bộ là tán, rừng 5 năm tuổi, kỳ 1 năm ≈ 192,9 t CO₂e
        kq = uoc_luong(self.ts, 8.8746, date(2026, 1, 1), date(2026, 12, 31), 2021, 8.8746)
        self.assertEqual(kq["so_ngay"], 365)
        self.assertAlmostEqual(kq["co2e_tan"], 192.9, delta=0.05)
        self.assertEqual(kq["canh_bao"], [], "47 t/ha < 187 t/ha → chưa chạm trần")

    def test_mo_ta_khong_du_anh_khong_do_json_tho(self):
        tb_rong = mo_ta_khong_du_anh(0.8, [])
        self.assertIn("80%", tb_rong)
        self.assertNotIn("[{", tb_rong)

        tb_may = mo_ta_khong_du_anh(0.8, [{"canh_id": "S2C_T48PVQ_20261021T033144_L2A", "ti_le_hop_le": 0.3652}])
        self.assertIn("36,5%", tb_may)
        self.assertIn("80%", tb_may)
        self.assertNotIn("canh_id", tb_may)
        self.assertNotIn("ti_le_hop_le", tb_may)

    def test_khop_vi_du_lo_dat_mui_2_muc_4_5(self):
        # methodology §4.5 Ví dụ 2: Lô Đất Mũi 2, diện tích lô 8,8745 ha, tán đo 9,00 ha → cắt về 8,8745 ha
        # Kỳ 30 ngày (01/04/2026 – 30/04/2026), năm trồng 2021 → ΔC_G = 4,324 t C, ΔCO₂e = 15,854 t CO₂e
        kq = uoc_luong(self.ts, 9.0, date(2026, 4, 1), date(2026, 4, 30), 2021, 8.8745)
        self.assertEqual(kq["dien_tich_tinh_ha"], 8.8745)
        self.assertEqual(kq["so_ngay"], 30)
        self.assertAlmostEqual(kq["delta_c_tan"], 4.324, places=3)
        self.assertAlmostEqual(kq["co2e_tan"], 15.854, places=3)
        self.assertEqual(kq["canh_bao"], [])

    def test_mat_tan_nguong_bien_10_phan_tram(self):
        # Giảm đúng 10% (từ 10,0 ha xuống 9,0 ha): chưa vượt ngưỡng > 10% nên không gắn cờ mat_tan
        kq_bien = uoc_luong(
            self.ts, 9.0, date(2026, 4, 1), date(2026, 4, 30), 2020, 10.0, dien_tich_tan_ky_truoc_ha=10.0
        )
        self.assertEqual(kq_bien["dien_tich_tinh_ha"], 9.0)
        self.assertNotIn("mat_tan", kq_bien["canh_bao"])

        # Giảm quá 10% (từ 10,0 ha xuống 8,95 ha): gắn cờ mat_tan và tính theo diện tích nhỏ hơn
        kq_vuot = uoc_luong(
            self.ts, 8.95, date(2026, 4, 1), date(2026, 4, 30), 2020, 10.0, dien_tich_tan_ky_truoc_ha=10.0
        )
        self.assertEqual(kq_vuot["dien_tich_tinh_ha"], 8.95)
        self.assertIn("mat_tan", kq_vuot["canh_bao"])

    def test_mo_ta_khong_du_anh_nhieu_canh_chon_tot_nhat(self):
        da_thu = [
            {"canh_id": "S2A_1", "ti_le_hop_le": 0.25},
            {"canh_id": "S2B_2", "ti_le_hop_le": 0.642},
            {"canh_id": "S2C_3", "ti_le_hop_le": 0.51},
        ]
        tb = mo_ta_khong_du_anh(0.8, da_thu)
        self.assertIn("64,2%", tb)
        self.assertIn("3 cảnh kiểm tra", tb)

    def test_cat_tran_dien_tich_tan_khi_vuot_dien_tich_lo_nho(self):
        kq = uoc_luong(self.ts, 0.08, date(2026, 4, 1), date(2026, 4, 30), 2022, 0.05)
        self.assertEqual(kq["dien_tich_tan_do_ha"], 0.08)
        self.assertEqual(kq["dien_tich_tinh_ha"], 0.05)

    def test_ky_nam_nhuan_366_ngay(self):
        kq = uoc_luong(self.ts, 1.0, date(2024, 1, 1), date(2024, 12, 31), 2018, 1.0)
        self.assertEqual(kq["so_ngay"], 366)
        self.assertAlmostEqual(kq["nam_tinh"], 366 / 365, places=5)

    def test_ket_qua_tra_ve_day_du_bang_he_so_da_dung(self):
        kq = uoc_luong(self.ts, 2.0, date(2026, 1, 1), date(2026, 1, 31), 2020, 2.5)
        self.assertEqual(
            kq["he_so"],
            {"g_w": 9.4, "r": 0.47, "cf": 0.429, "b_max": 187, "co2_tren_c": self.ts["he_so"]["co2_tren_c"]},
        )

    def test_lam_tron_chu_so_thap_phan_dien_tich_va_carbon(self):
        kq = uoc_luong(self.ts, 1.234567, date(2026, 4, 1), date(2026, 4, 30), 2021, 2.0)
        self.assertEqual(kq["dien_tich_tan_do_ha"], 1.2346)
        self.assertEqual(kq["dien_tich_tinh_ha"], 1.2346)
        self.assertEqual(kq["delta_c_tan"], round(kq["delta_c_tan"], 3))
        self.assertEqual(kq["co2e_tan"], round(kq["co2e_tan"], 3))

    def test_ket_hop_canh_bao_mat_tan_va_thieu_nam_trong(self):
        kq = uoc_luong(
            self.ts, 4.0, date(2026, 4, 1), date(2026, 4, 30), None, 6.0, dien_tich_tan_ky_truoc_ha=5.0
        )
        self.assertIsNone(kq["co2e_tan"])
        self.assertIn("mat_tan", kq["canh_bao"])
        self.assertIn("thieu_nam_trong", kq["canh_bao"])


if __name__ == "__main__":
    unittest.main()
