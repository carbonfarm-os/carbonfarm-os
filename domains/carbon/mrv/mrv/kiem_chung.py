# SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors
# SPDX-License-Identifier: GPL-3.0-or-later
"""API kiểm chứng CÔNG KHAI (#38), chỉ đọc sổ cái Dolt bằng tài khoản so_cai_doc (chỉ có quyền SELECT).

  GET /api/commit/<mã băm>   các bản ghi do commit đó thêm, SHA-256 tính lại có khớp không, bản ghi có bị sửa sau không
  GET /api/seri/<số sê-ri>   chuỗi sự kiện của một tín chỉ: kết quả MRV → cấp → (các lần) bán, mỗi bước kèm commit
  GET /api/tong-quan         số liệu tổng hợp từ sổ cái + kết quả đo mới nhất (trang chủ công khai hiển thị)

Qua gateway: /kiem-chung/api/* (không cần đăng nhập, giới hạn tần suất). Trường định danh người dùng (*_sub) được ẩn
khi trả ra; SHA-256 được tính trên dữ liệu đầy đủ trong sổ cái. Chỉ thư viện chuẩn + PyMySQL.
"""
from __future__ import annotations

import hashlib
import json
import logging
import re
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

import pymysql
from pymysql.cursors import DictCursor

from mrv.json_chuan import json_chuan
from mrv.luu_tru import bi_mat

log = logging.getLogger("mrv.kiem_chung")
MA_BAM = re.compile(r"^[0-9a-v]{32}$")
SO_SERI = re.compile(r"^([A-Z0-9]{3}-[A-Z0-9]{4}-\d{2})-(\d{10})$")
AN = "(đã ẩn)"


class Loi(Exception):
    def __init__(self, ma: int, thong_diep: str):
        super().__init__(thong_diep)
        self.ma = ma


def _db():
    return pymysql.connect(host="dolt", port=3306, user="so_cai_doc", password=bi_mat("dolt-so-cai-doc"),
                           database="so_cai", cursorclass=DictCursor, autocommit=True)


def an_dinh_danh(x):
    """Thay giá trị các khóa *_sub (mã người dùng Keycloak) bằng '(đã ẩn)' – đệ quy."""
    if isinstance(x, dict):
        return {k: (AN if k.endswith("_sub") else an_dinh_danh(v)) for k, v in x.items()}
    if isinstance(x, list):
        return [an_dinh_danh(v) for v in x]
    return x


def _ban_ghi(r: dict, hien_tai: dict[int, str]) -> dict:
    du_lieu = json.loads(r["du_lieu"])
    tinh_lai = hashlib.sha256(json_chuan(du_lieu).encode()).hexdigest()
    return {
        "loai": r["loai"], "ma_doi_tuong": r["ma_doi_tuong"], "commit": r["commit"], "luc": str(r["luc"]),
        "sha256_so_cai": r["sha256"], "sha256_tinh_lai": tinh_lai, "sha256_khop": tinh_lai == r["sha256"],
        # Bản ghi ở HEAD còn y như lúc commit không (Dolt giữ cả lịch sử nếu có ai sửa sau)
        "con_nguyen_ven": hien_tai.get(r["id"]) == r["sha256"],
        "du_lieu": an_dinh_danh(du_lieu),
    }


SQL_THEM = ("SELECT d.to_id AS id, d.to_loai AS loai, d.to_ma_doi_tuong AS ma_doi_tuong, d.to_du_lieu AS du_lieu, "
            "d.to_sha256 AS sha256, d.to_commit AS commit, d.to_commit_date AS luc FROM dolt_diff_ban_ghi d "
            "WHERE d.diff_type = 'added'")


def _hien_tai(cur) -> dict[int, str]:
    cur.execute("SELECT id, sha256 FROM ban_ghi")
    return {r["id"]: r["sha256"] for r in cur.fetchall()}


def theo_commit(ma_bam: str) -> dict:
    if not MA_BAM.match(ma_bam):
        raise Loi(422, "Mã băm commit Dolt gồm 32 ký tự 0-9, a-v")
    with _db() as c, c.cursor() as cur:
        cur.execute("SELECT commit_hash, committer, date, message FROM dolt_log WHERE commit_hash = %s", (ma_bam,))
        cm = cur.fetchone()
        if not cm:
            raise Loi(404, f"Không có commit {ma_bam} trong lịch sử sổ cái")
        cur.execute(SQL_THEM + " AND d.to_commit = %s", (ma_bam,))
        rows = cur.fetchall()
        hien_tai = _hien_tai(cur)
    return {"commit": cm["commit_hash"], "luc": str(cm["date"]), "thong_diep": cm["message"],
            "ban_ghi": [_ban_ghi(r, hien_tai) for r in rows]}


def _chua(ma: str, so: int, tu: str, den: str) -> bool:
    a, b = SO_SERI.match(tu), SO_SERI.match(den)
    return bool(a and b and a.group(1) == ma and int(a.group(2)) <= so <= int(b.group(2)))


def theo_seri(so_seri: str) -> dict:
    m = SO_SERI.match(so_seri)
    if not m:
        raise Loi(422, "Số sê-ri có dạng <mã trong nước 3-4-2>-<10 chữ số>, ví dụ MCK-DM01-26-0000000001")
    ma, so = m.group(1), int(m.group(2))
    with _db() as c, c.cursor() as cur:
        cur.execute(SQL_THEM + " AND d.to_loai IN ('cap_tin_chi', 'ban_tin_chi') ORDER BY d.to_commit_date", ())
        rows = cur.fetchall()
        cap = next((r for r in rows if r["loai"] == "cap_tin_chi"
                    and _chua(ma, so, (g := json.loads(r["du_lieu"])["registry"])["seri_tu"], g["seri_den"])), None)
        if cap is None:
            raise Loi(404, f"Sổ cái không có bản ghi cấp cho tín chỉ {so_seri}")
        mrv_id = json.loads(cap["du_lieu"])["ket_qua_mrv_id"]
        cur.execute(SQL_THEM + " AND d.to_loai = 'ket_qua_mrv' AND d.to_ma_doi_tuong = %s", (mrv_id,))
        mrv = cur.fetchall()
        hien_tai = _hien_tai(cur)
    ban = [r for r in rows if r["loai"] == "ban_tin_chi"
           and any(_chua(ma, so, d["seri_tu"], d["seri_den"]) for d in json.loads(r["du_lieu"])["dai_seri"])]
    su_kien = [_ban_ghi(r, hien_tai) for r in (*mrv, cap, *ban)]
    chu = su_kien[-1]["du_lieu"]["ben_mua" if ban else "chu_so_huu"]
    return {"so_seri": so_seri, "chu_so_huu_theo_so_cai": chu, "toan_ven": all(s["sha256_khop"] and s["con_nguyen_ven"]
                                                                                  for s in su_kien), "su_kien": su_kien}


def _so(x) -> float:
    try:
        return float(x)
    except (TypeError, ValueError):
        return 0.0


def tong_quan() -> dict:
    """Số liệu công khai đọc thẳng từ sổ cái: tổng CO2e đã ghi sổ, tín chỉ đã cấp / đã bán, các lô đã đo (ranh giới),
    và kết quả đo mới nhất. Không có định danh người dùng."""
    with _db() as c, c.cursor() as cur:
        cur.execute(SQL_THEM + " AND d.to_loai IN ('ket_qua_mrv', 'cap_tin_chi', 'ban_tin_chi') ORDER BY d.to_commit_date", ())
        rows = cur.fetchall()
    mrv = [(r, json.loads(r["du_lieu"])) for r in rows if r["loai"] == "ket_qua_mrv"]
    cap = [json.loads(r["du_lieu"]) for r in rows if r["loai"] == "cap_tin_chi"]
    ban = [json.loads(r["du_lieu"]) for r in rows if r["loai"] == "ban_tin_chi"]
    lo: dict[str, dict] = {}
    for _, d in mrv:
        ld = d["pha_he"]["lo_dat"]
        lo[ld["id"]] = {"id": ld["id"], "ten": ld.get("ten"), "ranh_gioi": ld["ranh_gioi"]}
    moi_nhat = None
    if mrv:
        r, d = mrv[-1]
        ph = d["pha_he"]
        moi_nhat = {
            "lo_dat_id": ph["lo_dat"]["id"], "ten_lo": ph["lo_dat"].get("ten"), "ranh_gioi": ph["lo_dat"]["ranh_gioi"],
            "dien_tich_tan_ha": d.get("dien_tich_tan_ha"), "co2e_tan": d.get("co2e_tan"), "ky": ph["ky"],
            "ndvi_tb_tan": ph["diem_anh"].get("ndvi_tb_tan"), "canh_id": ph["canh_nguon"]["id"],
            "ngay_chup": ph["canh_nguon"]["ngay_chup"], "may_toan_canh": ph["canh_nguon"].get("may_toan_canh"),
            "phuong_phap": ph["phuong_phap"], "commit": r["commit"],
        }
    return {
        "so_ket_qua_mrv": len(mrv),
        "co2e_da_ghi_so_tan": round(sum(_so(d.get("co2e_tan")) for _, d in mrv), 3),
        "tin_chi_da_cap": sum(int(d.get("so_luong_tin_chi", 0)) for d in cap),
        "tin_chi_da_ban": sum(int(d.get("so_luong", 0)) for d in ban),
        "lo_da_do": list(lo.values()),
        "seri_moi_nhat": cap[-1]["registry"]["seri_tu"] if cap else None,
        "ket_qua_moi_nhat": moi_nhat,
    }


class XuLy(BaseHTTPRequestHandler):
    server_version = "carbon-kiem-chung"

    def _tra(self, ma: int, du_lieu: dict) -> None:
        than = json.dumps(du_lieu, ensure_ascii=False, default=str).encode()
        self.send_response(ma)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(than)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(than)

    def do_GET(self) -> None:  # tên phương thức do http.server quy định
        duong = self.path.split("?", 1)[0]
        try:
            if duong == "/suc-khoe":
                return self._tra(200, {"trang_thai": "ok"})
            if duong == "/api/tong-quan":
                return self._tra(200, tong_quan())
            if duong.startswith("/api/commit/"):
                return self._tra(200, theo_commit(duong.removeprefix("/api/commit/")))
            if duong.startswith("/api/seri/"):
                return self._tra(200, theo_seri(duong.removeprefix("/api/seri/")))
            raise Loi(404, "Không có đường dẫn này")
        except Loi as e:
            return self._tra(e.ma, {"loi": str(e)})
        except Exception:  # lỗi nội bộ: ghi log, không lộ chi tiết
            log.exception("kiểm chứng lỗi: %s", duong)
            return self._tra(500, {"loi": "Lỗi máy chủ kiểm chứng"})

    def log_message(self, fmt: str, *args) -> None:
        log.info(fmt, *args)


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(name)s %(message)s")
    ThreadingHTTPServer(("0.0.0.0", 8080), XuLy).serve_forever()
