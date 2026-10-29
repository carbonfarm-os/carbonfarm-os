# SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors
# SPDX-License-Identifier: GPL-3.0-or-later
"""Tìm cảnh Sentinel-2 L2A trên danh mục STAC mở và phân loại tán rừng trong một lô (methodology v0.1 §2–§3).

Chỉ đọc cửa sổ bao quanh lô từ COG qua HTTP range, không tải nguyên cảnh.
"""
from __future__ import annotations

from dataclasses import dataclass, field
from datetime import date

import httpx
import numpy as np
import rasterio
from rasterio.enums import Resampling
from rasterio.features import geometry_mask
from rasterio.warp import transform_geom
from rasterio.windows import Window, from_bounds


@dataclass
class KetQuaAnh:
    canh_id: str
    ngay_chup: str
    may_toan_canh: float
    so_diem_anh_lo: int
    so_hop_le: int
    so_tan: int
    ndvi_tb_tan: float | None
    crs: str
    transform: list[float]
    ndvi: np.ndarray = field(repr=False)  # float32, NaN ngoài lô hoặc không hợp lệ
    href: dict[str, str] = field(default_factory=dict)

    @property
    def ti_le_hop_le(self) -> float:
        return self.so_hop_le / self.so_diem_anh_lo if self.so_diem_anh_lo else 0.0


def tim_canh(ts: dict, ranh_gioi: dict, tu: date, den: date) -> list[dict]:
    """Các cảnh L2A phủ lô trong kỳ, mây toàn cảnh ≤ ngưỡng, ít mây trước."""
    a = ts["anh"]
    r = httpx.post(
        f"{a['danh_muc_stac']}/search",
        json={
            "collections": [a["collection"]],
            "intersects": ranh_gioi,
            "datetime": f"{tu.isoformat()}T00:00:00Z/{den.isoformat()}T23:59:59Z",
            "query": {"eo:cloud_cover": {"lte": a["may_toan_canh_toi_da_phan_tram"]}},
            "sortby": [{"field": "properties.eo:cloud_cover", "direction": "asc"}],
            "limit": 20,
        },
        timeout=60,
    )
    r.raise_for_status()
    return r.json()["features"]


def _he_so_phan_xa(asset: dict) -> tuple[float, float]:
    """scale, offset của băng (L2A từ baseline 04.00 có offset −0.1); thiếu thì mặc định 1/10000, 0."""
    bang = (asset.get("raster:bands") or [{}])[0]
    return float(bang.get("scale", 0.0001)), float(bang.get("offset", 0.0))


def phan_loai(ts: dict, canh: dict, ranh_gioi: dict) -> KetQuaAnh:
    """Cắt đỏ/NIR/SCL theo lô, tính NDVI, đếm điểm ảnh trong lô / hợp lệ / tán rừng."""
    b = ts["anh"]["bang"]
    pl = ts["phan_loai"]
    assets = canh["assets"]
    href = {k: assets[b[k]]["href"] for k in ("do", "can_hong_ngoai", "phan_lop")}

    with rasterio.Env(AWS_NO_SIGN_REQUEST="YES"):
        with rasterio.open(href["do"]) as src_do:
            hinh = transform_geom("EPSG:4326", src_do.crs, ranh_gioi)
            xs = [p[0] for p in hinh["coordinates"][0]]
            ys = [p[1] for p in hinh["coordinates"][0]]
            res = src_do.res[0]
            w = from_bounds(min(xs) - res, min(ys) - res, max(xs) + res, max(ys) + res, src_do.transform)
            w = Window(int(w.col_off), int(w.row_off), int(np.ceil(w.width)) + 1, int(np.ceil(w.height)) + 1)
            do = src_do.read(1, window=w).astype("float32")
            transform = src_do.window_transform(w)
            crs = src_do.crs
        with rasterio.open(href["can_hong_ngoai"]) as src:
            nir = src.read(1, window=w).astype("float32")
        with rasterio.open(href["phan_lop"]) as src:
            # SCL 20 m → lưới 10 m của băng đỏ, láng giềng gần nhất (§3)
            ty_le = res / src.res[0]
            w20 = Window(w.col_off * ty_le, w.row_off * ty_le, w.width * ty_le, w.height * ty_le)
            scl = src.read(1, window=w20, out_shape=do.shape, resampling=Resampling.nearest)

    s_do, o_do = _he_so_phan_xa(assets[b["do"]])
    s_nir, o_nir = _he_so_phan_xa(assets[b["can_hong_ngoai"]])
    do = do * s_do + o_do
    nir = nir * s_nir + o_nir

    # Điểm ảnh thuộc lô: tâm điểm ảnh nằm trong ranh giới (all_touched=False)
    trong_lo = geometry_mask([hinh], out_shape=do.shape, transform=transform, invert=True, all_touched=False)
    hop_le = trong_lo & ~np.isin(scl, pl["scl_loai_bo"])
    with np.errstate(divide="ignore", invalid="ignore"):
        ndvi = np.where(hop_le & ((nir + do) != 0), (nir - do) / (nir + do), np.nan).astype("float32")
    tan = hop_le & np.isin(scl, pl["scl_thuc_vat"]) & (np.nan_to_num(ndvi, nan=-1) >= pl["nguong_ndvi_tan"])

    p = canh["properties"]
    return KetQuaAnh(
        canh_id=canh["id"],
        ngay_chup=p["datetime"][:10],
        may_toan_canh=float(p.get("eo:cloud_cover", 0.0)),
        so_diem_anh_lo=int(trong_lo.sum()),
        so_hop_le=int(hop_le.sum()),
        so_tan=int(tan.sum()),
        ndvi_tb_tan=float(np.nanmean(ndvi[tan])) if tan.any() else None,
        crs=crs.to_string(),
        transform=list(transform)[:6],
        ndvi=ndvi,
        href=href,
    )


def chon_canh(ts: dict, ranh_gioi: dict, tu: date, den: date, toi_da_thu: int = 4) -> tuple[KetQuaAnh | None, list[dict]]:
    """Cảnh có tỉ lệ điểm ảnh hợp lệ trong lô cao nhất (thử tối đa vài cảnh ít mây nhất); dưới ngưỡng → None."""
    da_thu: list[dict] = []
    tot_nhat: KetQuaAnh | None = None
    for canh in tim_canh(ts, ranh_gioi, tu, den)[:toi_da_thu]:
        kq = phan_loai(ts, canh, ranh_gioi)
        da_thu.append({"canh_id": kq.canh_id, "ti_le_hop_le": round(kq.ti_le_hop_le, 4)})
        if tot_nhat is None or kq.ti_le_hop_le > tot_nhat.ti_le_hop_le:
            tot_nhat = kq
        if kq.ti_le_hop_le >= 0.999:
            break
    if tot_nhat is None or tot_nhat.ti_le_hop_le < ts["anh"]["ti_le_diem_anh_hop_le_toi_thieu"]:
        return None, da_thu
    return tot_nhat, da_thu
