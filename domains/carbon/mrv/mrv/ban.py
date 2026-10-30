# SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors
# SPDX-License-Identifier: GPL-3.0-or-later
"""Bán tín chỉ (#37): lệnh "da_duyet" (đã qua tạo + duyệt hai người) → Buyer mock chấp nhận → Registry mock chuyển quyền
sở hữu → Bank mock ghi có → sổ cái Dolt → trừ ví → "hoan_tat". Cũng đồng bộ danh sách người mua từ Buyer mock.

Mọi lời gọi connector dùng cùng mã tham chiếu `ban-<id lệnh>`: chạy lại sau sự cố không mua, chuyển hay ghi có hai lần.
"""
from __future__ import annotations

import json
import logging
import os
import time
from datetime import UTC, datetime

import httpx

from mrv import luu_tru
from mrv.tin_chi import LoiNghiepVu, dam_bao_tai_khoan, ket_noi_registry, kiem_phan_hoi

log = logging.getLogger("mrv.ban")
BUYER = os.environ.get("BUYER_URL", "http://ket-noi-buyer:8000")
BANK = os.environ.get("BANK_URL", "http://ket-noi-bank:8000")
_dong_bo_luc = 0.0


def _client(goc: str, bi_mat: str) -> httpx.Client:
    return httpx.Client(base_url=goc, timeout=20, headers={"Authorization": f"Bearer {luu_tru.bi_mat(bi_mat)}"})


def dong_bo_nguoi_mua(c) -> list[dict]:
    with _client(BUYER, "ket-noi-buyer") as b:
        ds = kiem_phan_hoi(b.get("/nguoi-mua"))
    for n in ds:
        c.execute("INSERT INTO carbon.nguoi_mua (ma, ten, ma_so_thue, don_gia_toi_da_vnd, cap_nhat_luc) "
                  "VALUES (%s, %s, %s, %s, now()) ON CONFLICT (ma) DO UPDATE SET ten = EXCLUDED.ten, "
                  "ma_so_thue = EXCLUDED.ma_so_thue, don_gia_toi_da_vnd = EXCLUDED.don_gia_toi_da_vnd, cap_nhat_luc = now()",
                  (n["ma"], n["ten"], n["ma_so_thue"], n["don_gia_toi_da_vnd"]))
    return ds


def tru_vi(c, htx_id: str, ma: str, dai_seri: list[dict]) -> None:
    """Bỏ các dải sê-ri đã chuyển khỏi ví (tách khối khi cần). Ví lệch Registry → lỗi, không tự sửa."""
    for d in dai_seri:
        tu, den = int(d["seri_tu"].rsplit("-", 1)[1]), int(d["seri_den"].rsplit("-", 1)[1])
        da_bo = 0
        for k in c.execute("SELECT id, so_tu, so_den, de_nghi_cap_id FROM carbon.khoi_tin_chi WHERE hop_tac_xa_id = %s "
                           "AND ma_trong_nuoc = %s AND so_tu <= %s AND so_den >= %s ORDER BY so_tu",
                           (htx_id, ma, den, tu)).fetchall():
            c.execute("DELETE FROM carbon.khoi_tin_chi WHERE id = %s", (k["id"],))
            for a, b in ((k["so_tu"], tu - 1), (den + 1, k["so_den"])):
                if a <= b:
                    c.execute("INSERT INTO carbon.khoi_tin_chi (hop_tac_xa_id, ma_trong_nuoc, so_tu, so_den, de_nghi_cap_id) "
                              "VALUES (%s, %s, %s, %s, %s)", (htx_id, ma, a, b, k["de_nghi_cap_id"]))
            da_bo += min(den, k["so_den"]) - max(tu, k["so_tu"]) + 1
        if da_bo != den - tu + 1:
            raise RuntimeError(f"Ví lệch Registry ở dải {d['seri_tu']}..{d['seri_den']}: ví chỉ có {da_bo} tín chỉ")


def ban_mot(c, l: dict, nguoi_mua: dict) -> None:
    htx = c.execute("SELECT ten, ma_so_thue, so_tai_khoan_ngan_hang, dau_moi FROM carbon.hop_tac_xa WHERE id = %s",
                    (l["hop_tac_xa_id"],)).fetchone()
    nm = nguoi_mua.get(l["ma_nguoi_mua"])
    if nm is None:
        raise LoiNghiepVu(f"Buyer không còn người mua {l['ma_nguoi_mua']}")
    ref = f"ban-{l['id']}"

    with _client(BUYER, "ket-noi-buyer") as b:
        don = kiem_phan_hoi(b.post("/don-mua", json={"ma_nguoi_mua": nm["ma"], "so_luong": l["so_luong"],
                                             "don_gia_vnd": l["don_gia_vnd"], "ma_tham_chieu": ref}))
    with ket_noi_registry() as reg:
        dam_bao_tai_khoan(reg, {"ma_so_thue": nm["ma_so_thue"], "ten": nm["ten"], "dau_moi": nm["dau_moi"]})
        r = reg.post("/tin-chi/chuyen-quyen", json={"tu_ma_so_thue": htx["ma_so_thue"], "den_ma_so_thue": nm["ma_so_thue"],
                                                   "ma_trong_nuoc": l["ma_trong_nuoc"], "so_luong": l["so_luong"],
                                                   "ma_tham_chieu": ref})
        cq = kiem_phan_hoi(reg.get(f"/nghiep-vu/{ref}")) if r.status_code == 409 else kiem_phan_hoi(r)
    with _client(BANK, "ket-noi-bank") as bank:
        gd = kiem_phan_hoi(bank.post("/ghi-co", json={
            "so_tai_khoan": htx["so_tai_khoan_ngan_hang"], "so_tien_vnd": don["thanh_tien_vnd"], "ma_tham_chieu": ref,
            "noi_dung": f"Bán {l['so_luong']} tín chỉ {l['ma_trong_nuoc']} cho {nm['ten']}"[:200]}))

    ban_ghi = {
        "lenh_ban_id": l["id"], "ma_trong_nuoc": l["ma_trong_nuoc"], "so_luong": l["so_luong"],
        "don_gia_vnd": l["don_gia_vnd"], "thanh_tien_vnd": don["thanh_tien_vnd"],
        "ben_ban": {"ma_so_thue": htx["ma_so_thue"], "ten": htx["ten"]},
        "ben_mua": {"ma_so_thue": nm["ma_so_thue"], "ten": nm["ten"]},
        "dai_seri": cq["dai_seri"], "tao_duyet": {"nguoi_tao_sub": l["nguoi_tao_sub"], "nguoi_duyet_sub": l["nguoi_duyet_sub"],
                                                 "duyet_luc": l["duyet_luc"].isoformat()},
        "connector": {"don_mua": don["ma_tham_chieu"], "registry_luc": cq["luc"], "bank_luc": gd["luc"]},
    }
    ma_bam, sha = luu_tru.ghi_so_cai(l["id"], ban_ghi, f"Bán {l['so_luong']} tín chỉ {l['ma_trong_nuoc']} "
                                     f"{htx['ma_so_thue']} → {nm['ma_so_thue']} (lệnh {l['id']})", loai="ban_tin_chi")
    with c.transaction():
        tru_vi(c, l["hop_tac_xa_id"], l["ma_trong_nuoc"], cq["dai_seri"])
        c.execute("UPDATE carbon.lenh_ban SET trang_thai = 'hoan_tat', dai_seri = %s, ma_giao_dich_bank = %s, "
                  "hoan_tat_luc = %s, dolt_commit = %s, so_cai_sha256 = %s WHERE id = %s",
                  (json.dumps(cq["dai_seri"]), ref, datetime.now(UTC), ma_bam, sha, l["id"]))
    log.info("lệnh %s: bán %s tín chỉ cho %s, commit %s", l["id"], l["so_luong"], nm["ma"], ma_bam)


def mot_vong(c) -> None:
    global _dong_bo_luc
    lenh = c.execute("SELECT id::text, hop_tac_xa_id, ma_nguoi_mua, ma_trong_nuoc, so_luong, don_gia_vnd, nguoi_tao_sub, "
                     "nguoi_duyet_sub, duyet_luc FROM carbon.lenh_ban WHERE trang_thai = 'da_duyet' ORDER BY duyet_luc").fetchall()
    if not lenh and time.monotonic() - _dong_bo_luc < 60:
        return
    nguoi_mua = {n["ma"]: n for n in dong_bo_nguoi_mua(c)}
    _dong_bo_luc = time.monotonic()
    for l in lenh:
        try:
            ban_mot(c, l, nguoi_mua)
        except LoiNghiepVu as e:
            c.execute("UPDATE carbon.lenh_ban SET trang_thai = 'loi', ly_do_loi = %s WHERE id = %s", (str(e), l["id"]))
            log.warning("lệnh %s bị từ chối: %s", l["id"], e)
