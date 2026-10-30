# SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors
# SPDX-License-Identifier: GPL-3.0-or-later
"""Cấp tín chỉ (#36): đề nghị "cho_dang_ky" → Registry mock (TT 11/2026/TT-BNNMT) → sổ cái Dolt → ví hợp tác xã.

Mỗi bước an toàn khi chạy lại: Registry nhận mã tham chiếu `cap-<id đề nghị>` (gửi lại → 409 → đọc lại kết quả cũ),
sổ cái không ghi đôi cùng đối tượng, ví ghi trong cùng transaction với trạng thái "da_cap".
"""
from __future__ import annotations

import logging
import os
from datetime import UTC, datetime

import httpx

from mrv import luu_tru

log = logging.getLogger("mrv.tin_chi")
REGISTRY = os.environ.get("REGISTRY_URL", "http://ket-noi-registry:8000")
MA_CO_CHE = "MCK"  # mã cơ chế MOCK – không phải mã thật do Bộ cấp
TEN_CO_CHE = "Cơ chế mock CarbonFarm OS (không phải cơ chế thật)"


class LoiNghiepVu(Exception):
    """Registry từ chối (4xx khác 409): ghi lý do vào đề nghị, không thử lại."""


def ket_noi_registry() -> httpx.Client:
    return httpx.Client(base_url=REGISTRY, timeout=20,
                        headers={"Authorization": f"Bearer {luu_tru.bi_mat('ket-noi-registry')}"})


def kiem_phan_hoi(r: httpx.Response) -> dict:
    if 400 <= r.status_code < 500:
        raise LoiNghiepVu(f"Registry {r.status_code}: {r.json().get('detail', r.text)}"[:500])
    r.raise_for_status()  # 5xx → lỗi tạm, vòng sau thử lại
    return r.json()


def dam_bao_tai_khoan(reg: httpx.Client, htx: dict) -> None:
    """Tài khoản đăng ký gắn mã số thuế của hợp tác xã (TT 11/2026 Điều 6); đã có (409) là được."""
    r = reg.post("/tai-khoan", json={"ma_so_thue": htx["ma_so_thue"], "ten_to_chuc": htx["ten"], "dau_moi": htx["dau_moi"]})
    if r.status_code != 409:
        kiem_phan_hoi(r)


def cap_mot(c, dn: dict) -> None:
    htx = c.execute("SELECT ten, ma_so_thue, ma_du_an_tin_chi, dau_moi FROM carbon.hop_tac_xa WHERE id = %s",
                    (dn["hop_tac_xa_id"],)).fetchone()
    kq = c.execute("SELECT id::text, ky_tu, ky_den, co2e_tan, dolt_commit, so_cai_sha256 FROM carbon.ket_qua_mrv WHERE id = %s",
                   (dn["ket_qua_mrv_id"],)).fetchone()
    ma_tham_chieu = f"cap-{dn['id']}"
    with ket_noi_registry() as reg:
        dam_bao_tai_khoan(reg, htx)
        r = reg.post("/tin-chi/dang-ky", json={
            "ma_so_thue": htx["ma_so_thue"], "ten_du_an": f"{htx['ten']} – rừng ngập mặn", "ma_du_an": htx["ma_du_an_tin_chi"],
            "ten_co_che": TEN_CO_CHE, "ma_co_che": MA_CO_CHE, "nam_xac_nhan": kq["ky_den"].year,
            "so_luong": dn["so_luong"], "ma_tham_chieu": ma_tham_chieu,
        })
        dk = kiem_phan_hoi(reg.get(f"/nghiep-vu/{ma_tham_chieu}")) if r.status_code == 409 else kiem_phan_hoi(r)
    dai = dk["dai_seri"][0]

    ban_ghi = {
        "de_nghi_cap_id": dn["id"], "ket_qua_mrv_id": kq["id"],
        "ket_qua_mrv_so_cai": {"dolt_commit": kq["dolt_commit"], "sha256": kq["so_cai_sha256"]},
        "ky": {"tu": kq["ky_tu"].isoformat(), "den": kq["ky_den"].isoformat()}, "co2e_tan": kq["co2e_tan"],
        "so_luong_tin_chi": dn["so_luong"], "quy_tac": "1 tín chỉ = 1 t CO2e, làm tròn xuống",
        "chu_so_huu": {"ma_so_thue": htx["ma_so_thue"], "ten": htx["ten"]},
        "registry": {"ma_trong_nuoc": dai["ma_trong_nuoc"], "seri_tu": dai["seri_tu"], "seri_den": dai["seri_den"],
                     "ma_tham_chieu": ma_tham_chieu, "luc": dk["luc"]},
    }
    ma_bam, sha = luu_tru.ghi_so_cai(dn["id"], ban_ghi, f"Cấp {dn['so_luong']} tín chỉ {dai['seri_tu']}..{dai['seri_den']} "
                                     f"cho {htx['ma_so_thue']} (đề nghị {dn['id']})", loai="cap_tin_chi")
    so_tu, so_den = int(dai["seri_tu"].rsplit("-", 1)[1]), int(dai["seri_den"].rsplit("-", 1)[1])
    with c.transaction():
        c.execute("INSERT INTO carbon.khoi_tin_chi (hop_tac_xa_id, ma_trong_nuoc, so_tu, so_den, de_nghi_cap_id) "
                  "VALUES (%s, %s, %s, %s, %s)", (dn["hop_tac_xa_id"], dai["ma_trong_nuoc"], so_tu, so_den, dn["id"]))
        c.execute("UPDATE carbon.de_nghi_cap SET trang_thai = 'da_cap', ma_trong_nuoc = %s, seri_tu = %s, seri_den = %s, "
                  "cap_luc = %s, dolt_commit = %s, so_cai_sha256 = %s WHERE id = %s",
                  (dai["ma_trong_nuoc"], dai["seri_tu"], dai["seri_den"], datetime.now(UTC), ma_bam, sha, dn["id"]))
    log.info("đề nghị %s: cấp %s tín chỉ %s..%s, commit %s", dn["id"], dn["so_luong"], dai["seri_tu"], dai["seri_den"], ma_bam)


def mot_vong(c) -> None:
    for dn in c.execute("SELECT id::text, ket_qua_mrv_id, hop_tac_xa_id, so_luong FROM carbon.de_nghi_cap "
                        "WHERE trang_thai = 'cho_dang_ky' ORDER BY de_nghi_luc").fetchall():
        try:
            cap_mot(c, dn)
        except LoiNghiepVu as e:
            c.execute("UPDATE carbon.de_nghi_cap SET trang_thai = 'loi', ly_do_loi = %s WHERE id = %s", (str(e), dn["id"]))
            log.warning("đề nghị %s bị từ chối: %s", dn["id"], e)

