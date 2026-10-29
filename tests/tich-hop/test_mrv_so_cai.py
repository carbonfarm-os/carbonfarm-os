# SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors
# SPDX-License-Identifier: GPL-3.0-or-later
"""Kiểm chứng chéo kết quả MRV đã duyệt (#25): dòng da_ghi_so trong PostgreSQL ↔ bản ghi và commit trong sổ cái Dolt.

Chạy sau tests/e2e/carbon-mrv.hurl (task smoke chạy Hurl trước); không có kết quả nào đã ghi sổ thì bỏ qua.
"""
from __future__ import annotations

import json
import unittest

from test_so_cai_su_kien import dolt, trong_container


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


if __name__ == "__main__":
    unittest.main()
