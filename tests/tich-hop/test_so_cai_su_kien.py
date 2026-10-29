# SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors
# SPDX-License-Identifier: GPL-3.0-or-later
"""Kiểm thử tích hợp sổ cái Dolt và event bus Valkey (#10) trên hệ thống đang chạy.

Hai dịch vụ dùng giao thức MySQL và RESP (không phải HTTP) nên không kiểm bằng Hurl. Lệnh chạy bên trong container
qua `docker compose exec`; mật khẩu đọc từ tệp do OpenBao sinh, không đi qua dòng lệnh của máy chủ, không in ra.
Chỉ dùng thư viện chuẩn: `python3 -m unittest discover -s tests/tich-hop -v` (task smoke gọi lệnh này).
"""
from __future__ import annotations

import json
import subprocess
import unittest
import uuid
from pathlib import Path

GOC = Path(__file__).resolve().parents[2]
COMPOSE = ["docker", "compose", "-f", str(GOC / "compose.yaml")]


def trong_container(dich_vu: str, lenh: str) -> str:
    ra = subprocess.run([*COMPOSE, "exec", "-T", dich_vu, "sh", "-c", lenh], capture_output=True, text=True, check=True)
    return ra.stdout.strip()


def dolt(sql: str) -> list[dict]:
    """Chạy SQL trên sổ cái bằng tài khoản so_cai; trả các dòng của câu lệnh cuối."""
    lenh = (
        'dolt --host 127.0.0.1 --port 3306 --no-tls -u so_cai -p "$(cat /run/bimat/dolt-so-cai)" '
        f"--use-db so_cai sql -r json -q {json.dumps(sql)}"
    )
    dong = [d for d in trong_container("dolt", lenh).splitlines() if d.strip()]
    return json.loads(dong[-1]).get("rows", []) if dong else []


def valkey(*tham_so: str) -> str:
    lenh = 'valkey-cli --no-auth-warning -a "$(cat /run/bimat/valkey)" ' + " ".join(json.dumps(t) for t in tham_so)
    return trong_container("valkey", lenh)


class SoCaiDolt(unittest.TestCase):
    def test_ghi_tao_commit_co_ma_bam_va_truy_vet_duoc(self):
        ma = f"kiem-thu-{uuid.uuid4()}"
        ket_qua = dolt(
            "INSERT INTO ban_ghi (loai, ma_doi_tuong, du_lieu, sha256) "
            f"VALUES ('kiem_thu', '{ma}', JSON_OBJECT('so_luong', 3), SHA2('{ma}', 256)); "
            f"CALL DOLT_COMMIT('-am', 'kiem thu {ma}')"
        )
        ma_bam = ket_qua[0]["hash"]
        self.assertRegex(ma_bam, r"^[0-9a-v]{32}$", "commit Dolt phải có mã băm 32 ký tự")

        dau = dolt("SELECT commit_hash, message FROM dolt_log LIMIT 1")[0]
        self.assertEqual(dau["commit_hash"], ma_bam, "commit mới nhất phải là commit vừa ghi")
        self.assertIn(ma, dau["message"])

        thay_doi = dolt(f"SELECT diff_type, to_ma_doi_tuong FROM dolt_diff_ban_ghi WHERE to_commit = '{ma_bam}'")
        self.assertEqual(thay_doi, [{"diff_type": "added", "to_ma_doi_tuong": ma}],
                         "diff của commit chỉ gồm đúng bản ghi vừa thêm")

    def test_doi_du_lieu_cu_de_lai_dau_vet_trong_lich_su(self):
        ma = f"sua-{uuid.uuid4()}"
        dolt(f"INSERT INTO ban_ghi (loai, ma_doi_tuong, du_lieu, sha256) VALUES ('kiem_thu', '{ma}', '{{}}', SHA2('a', 256)); "
             f"CALL DOLT_COMMIT('-am', 'them {ma}')")
        ma_bam = dolt(f"UPDATE ban_ghi SET sha256 = SHA2('b', 256) WHERE ma_doi_tuong = '{ma}'; "
                      f"CALL DOLT_COMMIT('-am', 'sua {ma}')")[0]["hash"]
        thay_doi = dolt(f"SELECT diff_type, from_sha256 <> to_sha256 AS khac FROM dolt_diff_ban_ghi "
                        f"WHERE to_commit = '{ma_bam}'")
        self.assertEqual(thay_doi, [{"diff_type": "modified", "khac": "1"}],
                         "mọi lần sửa đều hiện trong lịch sử, giá trị cũ vẫn đọc lại được")


class SuKienValkey(unittest.TestCase):
    def test_phat_va_doc_su_kien_qua_stream(self):
        luong = f"su-kien-kiem-thu-{uuid.uuid4()}"
        ma = valkey("XADD", luong, "*", "loai", "kiem_thu", "ma", "1")
        self.assertRegex(ma, r"^\d+-\d+$")
        self.assertEqual(valkey("XLEN", luong), "1")
        self.assertIn("kiem_thu", valkey("XRANGE", luong, "-", "+"))
        valkey("DEL", luong)

    def test_khong_mat_khau_bi_tu_choi(self):
        ra = trong_container("valkey", "valkey-cli ping")
        self.assertIn("NOAUTH", ra)


if __name__ == "__main__":
    unittest.main()
