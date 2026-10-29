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

from mrv.phuong_phap import doc_tham_so, uoc_luong

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


if __name__ == "__main__":
    unittest.main()
