# SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors
# SPDX-License-Identifier: GPL-3.0-or-later
"""Kiểm chứng chéo kết quả MRV đã duyệt (#25): dòng da_ghi_so trong PostgreSQL ↔ bản ghi và commit trong sổ cái Dolt.

Chạy sau tests/e2e/carbon-mrv.hurl (task smoke chạy Hurl trước); không có kết quả nào đã ghi sổ thì bỏ qua.
"""
from __future__ import annotations

import json
import unittest

from test_so_cai_su_kien import dolt, trong_container


def dong_moi_nhat(sql: str) -> dict | None:
    ra = trong_container("postgres", f'psql -U postgres -d nen_tang -Atc "{sql}"')
    return json.loads(ra) if ra else None


def ket_qua_da_ghi_so() -> dict | None:
    sql = ("SELECT json_build_object('id', id, 'dolt_commit', dolt_commit, 'sha', so_cai_sha256, 'co2e', co2e_tan) "
           "FROM carbon.ket_qua_mrv WHERE trang_thai = 'da_ghi_so' ORDER BY ghi_so_luc DESC LIMIT 1")
    ra = trong_container("postgres", f'psql -U postgres -d nen_tang -Atc "{sql}"')
    return json.loads(ra) if ra else None


class MrvSoCai(unittest.TestCase):
    def test_ket_qua_da_duyet_nam_trong_so_cai(self):
        kq = ket_qua_da_ghi_so()
        if kq is None:
            self.skipTest("chưa có kết quả MRV nào đã ghi sổ")
        ban_ghi = dolt(f"SELECT loai, sha256, JSON_EXTRACT(du_lieu, '$.ket_qua_mrv_id') AS id FROM ban_ghi "
                       f"WHERE ma_doi_tuong = '{kq['id']}'")
        self.assertEqual(len(ban_ghi), 1, "mỗi kết quả đã duyệt đúng một bản ghi sổ cái")
        self.assertEqual(ban_ghi[0]["loai"], "ket_qua_mrv")
        self.assertEqual(ban_ghi[0]["sha256"], kq["sha"], "SHA-256 trong CSDL nghiệp vụ khớp sổ cái")
        self.assertEqual(json.loads(ban_ghi[0]["id"]), kq["id"])

        log = dolt(f"SELECT message FROM dolt_log WHERE commit_hash = '{kq['dolt_commit']}'")
        self.assertEqual(len(log), 1, "mã băm commit ghi trong CSDL phải có trong lịch sử Dolt")
        self.assertIn(kq["id"], log[0]["message"])
        thay_doi = dolt(f"SELECT diff_type, to_ma_doi_tuong FROM dolt_diff_ban_ghi WHERE to_commit = '{kq['dolt_commit']}'")
        self.assertEqual(thay_doi, [{"diff_type": "added", "to_ma_doi_tuong": kq["id"]}])


    def test_tin_chi_da_cap_nam_trong_so_cai_va_tro_ve_ket_qua_mrv(self):
        dn = dong_moi_nhat(
            "SELECT json_build_object('id', d.id, 'dolt_commit', d.dolt_commit, 'sha', d.so_cai_sha256, 'seri_tu', d.seri_tu, "
            "'mrv_commit', k.dolt_commit) FROM carbon.de_nghi_cap d JOIN carbon.ket_qua_mrv k ON k.id = d.ket_qua_mrv_id "
            "WHERE d.trang_thai = 'da_cap' ORDER BY d.cap_luc DESC LIMIT 1")
        if dn is None:
            self.skipTest("chưa có tín chỉ nào được cấp")
        ban_ghi = dolt(f"SELECT sha256, JSON_UNQUOTE(JSON_EXTRACT(du_lieu, '$.registry.seri_tu')) AS seri, "
                       f"JSON_UNQUOTE(JSON_EXTRACT(du_lieu, '$.ket_qua_mrv_so_cai.dolt_commit')) AS mrv FROM ban_ghi "
                       f"WHERE loai = 'cap_tin_chi' AND ma_doi_tuong = '{dn['id']}'")
        self.assertEqual(len(ban_ghi), 1, "mỗi lần cấp đúng một bản ghi sổ cái (không ghi đôi)")
        self.assertEqual(ban_ghi[0]["sha256"], dn["sha"])
        self.assertEqual(ban_ghi[0]["seri"], dn["seri_tu"])
        self.assertEqual(ban_ghi[0]["mrv"], dn["mrv_commit"], "bản ghi cấp trỏ về commit của kết quả MRV gốc")
        self.assertEqual(len(dolt(f"SELECT 1 AS co FROM dolt_log WHERE commit_hash = '{dn['dolt_commit']}'")), 1)


if __name__ == "__main__":
    unittest.main()
