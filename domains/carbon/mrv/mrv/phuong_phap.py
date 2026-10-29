# SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors
# SPDX-License-Identifier: GPL-3.0-or-later
"""Công thức của phương pháp (methodology/v0.1-…md §4). Thuần Python, không I/O ngoài đọc tệp tham số – kiểm thử đơn vị được."""
from __future__ import annotations

import hashlib
from datetime import date
from pathlib import Path

import yaml

THU_MUC = Path("/phuong-phap")


def doc_tham_so(phien_ban: str, thu_muc: Path = THU_MUC) -> tuple[dict, str]:
    """Tham số + SHA-256 của tệp (ghi vào phả hệ để bên xác minh biết đúng bộ hệ số đã dùng)."""
    noi_dung = (thu_muc / f"{phien_ban}.yaml").read_bytes()
    ts = yaml.safe_load(noi_dung)
    if ts.get("phien_ban") != phien_ban:
        raise ValueError(f"tệp tham số khai phiên bản {ts.get('phien_ban')!r}, cần {phien_ban!r}")
    return ts, hashlib.sha256(noi_dung).hexdigest()


def _tuoi_nam(nam_trong: int, ngay: date) -> float:
    return (ngay - date(nam_trong, 1, 1)).days / 365.25


def uoc_luong(
    ts: dict,
    dien_tich_tan_ha: float,
    ky_tu: date,
    ky_den: date,
    nam_trong: int | None,
    dien_tich_lo_ha: float,
    dien_tich_tan_ky_truoc_ha: float | None = None,
) -> dict:
    """ΔC_G = A × G_W × (1 + R) × CF × số năm tính; ΔCO2e = ΔC_G × 44/12 (§4.1), có trần sinh khối (§4.3), mất tán (§4.4).

    A không vượt diện tích lô: quy tắc tâm điểm ảnh ở mép có thể đếm dư vài điểm ảnh (§3, §6).
    """
    h = ts["he_so"]
    g, r, cf, b_max = h["g_w_t_ha_nam"]["dung"], h["r"]["dung"], h["cf"]["dung"], h["b_max_t_ha"]["dung"]
    canh_bao: list[str] = []

    a = min(dien_tich_tan_ha, dien_tich_lo_ha)
    if dien_tich_tan_ky_truoc_ha is not None:
        if a < dien_tich_tan_ky_truoc_ha * (1 - ts["mat_tan"]["ti_le_giam_can_duyet"]):
            canh_bao.append("mat_tan")
        a = min(a, dien_tich_tan_ky_truoc_ha)

    so_ngay = (ky_den - ky_tu).days + 1
    nam_ky = so_ngay / 365
    if nam_trong is None:
        canh_bao.append("thieu_nam_trong")
        nam_tinh = None
    else:
        con_lai = max(0.0, b_max / g - _tuoi_nam(nam_trong, ky_tu))  # số năm còn được tăng trước khi chạm trần
        nam_tinh = min(nam_ky, con_lai)
        if nam_tinh < nam_ky:
            canh_bao.append("cham_tran_sinh_khoi")

    delta_c = None if nam_tinh is None else a * g * (1 + r) * cf * nam_tinh
    return {
        "dien_tich_tan_do_ha": round(dien_tich_tan_ha, 4),
        "dien_tich_lo_ha": round(dien_tich_lo_ha, 4),
        "dien_tich_tinh_ha": round(a, 4),
        "so_ngay": so_ngay,
        "nam_tinh": None if nam_tinh is None else round(nam_tinh, 6),
        "delta_c_tan": None if delta_c is None else round(delta_c, 3),
        "co2e_tan": None if delta_c is None else round(delta_c * h["co2_tren_c"], 3),
        "he_so": {"g_w": g, "r": r, "cf": cf, "b_max": b_max, "co2_tren_c": h["co2_tren_c"]},
        "canh_bao": canh_bao,
    }
