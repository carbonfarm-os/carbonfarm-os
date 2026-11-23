# SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors
# SPDX-License-Identifier: GPL-3.0-or-later
"""Dạng JSON chuẩn để băm: dữ liệu đọc lại từ sổ cái (Dolt chuẩn hóa JSON) phải cho cùng SHA-256 với lúc ghi."""
from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from mrv.json_chuan import json_chuan


class JsonChuan(unittest.TestCase):
    def test_so_nguyen_dang_thuc_giong_so_nguyen(self):
        # Dolt trả {"ti_le": 1} cho dữ liệu ghi {"ti_le": 1.0}
        self.assertEqual(json_chuan({"ti_le": 1.0, "ds": [2.0, 0.5]}), json_chuan({"ti_le": 1, "ds": [2, 0.5]}))

    def test_khoa_sap_xep_khong_khoang_trang_giu_unicode(self):
        self.assertEqual(json_chuan({"b": 1, "a": "rừng"}), '{"a":"rừng","b":1}')

    def test_doc_lai_tu_json_ra_cung_chuoi(self):
        goc = {"pha_he": {"canh_da_thu": [{"ti_le_hop_le": 1.0}], "ndvi": 0.8912345, "toa_do": [[104.8, 8.64]]}, "co2e": "15.543"}
        self.assertEqual(json_chuan(json.loads(json.dumps(goc))), json_chuan(goc))

    def test_sap_xep_de_quy_dict_long_nhau(self):
        d1 = {"z": {"b": 2, "a": 1}, "a": [{"d": 4, "c": 3}]}
        d2 = {"a": [{"c": 3, "d": 4}], "z": {"a": 1, "b": 2}}
        self.assertEqual(json_chuan(d1), json_chuan(d2))

    def test_giu_nguyen_thu_tu_phan_tu_trong_mang_toa_do(self):
        vong = {"coordinates": [[104.75, 8.61], [104.76, 8.62], [104.75, 8.61]]}
        self.assertEqual(json_chuan(vong), '{"coordinates":[[104.75,8.61],[104.76,8.62],[104.75,8.61]]}')

    def test_so_khong_am_chuan_hoa_ve_0(self):
        self.assertEqual(json_chuan({"x": -0.0, "y": 0.0, "z": 0}), '{"x":0,"y":0,"z":0}')


if __name__ == "__main__":
    unittest.main()
