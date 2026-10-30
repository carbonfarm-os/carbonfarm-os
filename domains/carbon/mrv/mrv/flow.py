# SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors
# SPDX-License-Identifier: GPL-3.0-or-later
"""Flow Prefect `mrv-lo-dat`: đo một lô trong một kỳ → dừng chờ cán bộ duyệt → được duyệt thì ghi sổ cái.

Đầu vào là id dòng carbon.ket_qua_mrv do cán bộ tạo qua GraphQL (carbonYeuCauMrv); trạng thái dòng:
cho_chay → dang_chay (cầu nối tạo lượt chạy) → cho_duyet (flow ghi kết quả, PAUSED) → da_duyet | tu_choi (cán bộ)
→ da_ghi_so (flow ghi Dolt) | loi.
"""
from __future__ import annotations

import json
from datetime import UTC, datetime

from prefect import flow, get_run_logger, pause_flow_run, task
from prefect.runtime import flow_run

from mrv import anh, luu_tru
from mrv.phuong_phap import doc_tham_so, uoc_luong

PHIEN_BAN = "v0.1-rung-ngap-man-ipcc-tier1"
EARTH_SEARCH_ITEM = "{goc}/collections/{bo}/items/{id}"


def _cap_nhat(ket_qua_id: str, **cot) -> None:
    gan = ", ".join(f"{k} = %({k})s" for k in cot)
    with luu_tru.csdl() as c:
        c.execute(f"UPDATE carbon.ket_qua_mrv SET {gan} WHERE id = %(id)s", {**cot, "id": ket_qua_id})


@task
def doc_yeu_cau(ket_qua_id: str) -> dict:
    with luu_tru.csdl() as c:
        dong = c.execute(
            """SELECT k.id::text, k.lo_dat_id::text, k.ky_tu, k.ky_den, k.trang_thai, l.ten, l.nam_trong, l.dien_tich_ha,
                      ST_AsGeoJSON(l.hinh, 7)::json AS ranh_gioi, encode(sha256(ST_AsBinary(l.hinh)), 'hex') AS sha_ranh_gioi,
                      (SELECT t.dien_tich_tan_ha FROM carbon.ket_qua_mrv t
                        WHERE t.lo_dat_id = k.lo_dat_id AND t.trang_thai = 'da_ghi_so' AND t.ky_den < k.ky_tu
                        ORDER BY t.ky_den DESC LIMIT 1) AS tan_ky_truoc
                 FROM carbon.ket_qua_mrv k JOIN carbon.lo_dat l ON l.id = k.lo_dat_id WHERE k.id = %s""",
            (ket_qua_id,),
        ).fetchone()
    if dong is None:
        raise ValueError(f"không có yêu cầu MRV {ket_qua_id}")
    return dong


@task(retries=2, retry_delay_seconds=10)
def do_dac(yc: dict, ts: dict) -> tuple[anh.KetQuaAnh | None, list[dict]]:
    return anh.chon_canh(ts, yc["ranh_gioi"], yc["ky_tu"], yc["ky_den"])


@task
def luu_san_pham(yc: dict, kq: anh.KetQuaAnh, ts: dict) -> tuple[str, str]:
    khoa = f"mrv/{yc['lo_dat_id']}/{yc['id']}/ndvi.tif"
    href = luu_tru.ghi_cog(kq.ndvi, kq.crs, kq.transform, khoa)
    a = ts["anh"]
    toa_do = yc["ranh_gioi"]["coordinates"][0]
    luu_tru.dang_ky_stac({
        "type": "Feature", "stac_version": "1.0.0", "id": yc["id"], "collection": luu_tru.BO_SUU_TAP,
        "geometry": yc["ranh_gioi"],
        "bbox": [min(p[0] for p in toa_do), min(p[1] for p in toa_do), max(p[0] for p in toa_do), max(p[1] for p in toa_do)],
        "properties": {
            "datetime": f"{kq.ngay_chup}T00:00:00Z",
            "carbon:lo_dat_id": yc["lo_dat_id"], "carbon:phuong_phap": PHIEN_BAN, "eo:cloud_cover": kq.may_toan_canh,
        },
        "links": [{"rel": "derived_from", "href": EARTH_SEARCH_ITEM.format(goc=a["danh_muc_stac"], bo=a["collection"], id=kq.canh_id),
                   "type": "application/geo+json", "title": "Cảnh Sentinel-2 L2A nguồn"}],
        "assets": {"ndvi": {"href": href, "type": "image/tiff; application=geotiff; profile=cloud-optimized",
                            "title": "NDVI trong lô (NaN: ngoài lô hoặc bị loại theo SCL)", "roles": ["data"]}},
    })
    return yc["id"], href


@flow(name="mrv-lo-dat", log_prints=True)
def mrv_lo_dat(ket_qua_id: str) -> dict:
    log = get_run_logger()
    try:
        ts, sha_ts = doc_tham_so(PHIEN_BAN)
        yc = doc_yeu_cau(ket_qua_id)
        kq, da_thu = do_dac(yc, ts)
        if kq is None:
            ly_do = f"Không có cảnh nào đủ {ts['anh']['ti_le_diem_anh_hop_le_toi_thieu']:.0%} điểm ảnh hợp lệ trong lô (đã thử {da_thu})"
            _cap_nhat(ket_qua_id, trang_thai="loi", ly_do_loi=ly_do)
            log.warning(ly_do)
            return {"trang_thai": "loi"}

        dien_tich_tan = kq.so_tan * (ts["anh"]["do_phan_giai_m"] ** 2) / 10000
        uoc = uoc_luong(ts, dien_tich_tan, yc["ky_tu"], yc["ky_den"], yc["nam_trong"], float(yc["dien_tich_ha"]),
                        float(yc["tan_ky_truoc"]) if yc["tan_ky_truoc"] is not None else None)
        if kq.ti_le_hop_le < 1:
            uoc["canh_bao"].append("thieu_diem_anh_hop_le")
        stac_id, href = luu_san_pham(yc, kq, ts)

        pha_he = {
            "phuong_phap": PHIEN_BAN, "tham_so_sha256": sha_ts,
            "lo_dat": {"id": yc["lo_dat_id"], "ten": yc["ten"], "ranh_gioi": yc["ranh_gioi"], "ranh_gioi_sha256": yc["sha_ranh_gioi"],
                       "nam_trong": yc["nam_trong"]},
            "ky": {"tu": yc["ky_tu"].isoformat(), "den": yc["ky_den"].isoformat()},
            "canh_nguon": {"id": kq.canh_id, "ngay_chup": kq.ngay_chup, "may_toan_canh": kq.may_toan_canh,
                           "danh_muc": ts["anh"]["danh_muc_stac"], "collection": ts["anh"]["collection"], "bang": kq.href},
            "canh_da_thu": da_thu,
            "diem_anh": {"trong_lo": kq.so_diem_anh_lo, "hop_le": kq.so_hop_le, "tan": kq.so_tan,
                         "ndvi_tb_tan": kq.ndvi_tb_tan},
            "uoc_luong": uoc,
            "san_pham": {"stac_item": f"{luu_tru.BO_SUU_TAP}/{stac_id}", "cog": href},
            "flow_run_id": str(flow_run.get_id()),
        }
        _cap_nhat(
            ket_qua_id, trang_thai="cho_duyet", canh_id=kq.canh_id, ngay_chup=kq.ngay_chup, may_phan_tram=kq.may_toan_canh,
            so_diem_anh_lo=kq.so_diem_anh_lo, so_diem_anh_hop_le=kq.so_hop_le, so_diem_anh_tan=kq.so_tan,
            dien_tich_tan_ha=uoc["dien_tich_tinh_ha"], delta_c_tan=uoc["delta_c_tan"], co2e_tan=uoc["co2e_tan"],
            canh_bao=uoc["canh_bao"], phuong_phap=PHIEN_BAN, tham_so_sha256=sha_ts, stac_item_id=stac_id, cog_href=href,
            pha_he=json.dumps(pha_he, ensure_ascii=False, default=str),
        )
        log.info("Lô %s: tán %.2f ha, %s t CO2e – chờ cán bộ duyệt", yc["ten"], uoc["dien_tich_tinh_ha"], uoc["co2e_tan"])
    except Exception as e:
        _cap_nhat(ket_qua_id, trang_thai="loi", ly_do_loi=f"{type(e).__name__}: {e}"[:500])
        raise

    # Human-in-the-loop: cầu nối resume khi cán bộ ghi quyết định qua GraphQL. Quyết định đọc lại từ CSDL (nguồn sự thật).
    pause_flow_run(timeout=24 * 3600, poll_interval=3, key="cho-can-bo-duyet")

    with luu_tru.csdl() as c:
        d = c.execute("SELECT trang_thai, duyet_luc, ghi_chu_duyet, nguoi_duyet_sub, pha_he, co2e_tan, dien_tich_tan_ha "
                      "FROM carbon.ket_qua_mrv WHERE id = %s", (ket_qua_id,)).fetchone()
    if d["trang_thai"] != "da_duyet":
        log.info("Kết quả %s: %s – không ghi sổ cái", ket_qua_id, d["trang_thai"])
        return {"trang_thai": d["trang_thai"]}

    ban_ghi = {"ket_qua_mrv_id": ket_qua_id, "pha_he": d["pha_he"], "co2e_tan": d["co2e_tan"],
               "dien_tich_tan_ha": d["dien_tich_tan_ha"], "duyet": {"nguoi_duyet_sub": d["nguoi_duyet_sub"],
               "luc": d["duyet_luc"].isoformat(), "ghi_chu": d["ghi_chu_duyet"]}}
    ma_bam, sha = luu_tru.ghi_so_cai(ket_qua_id, ban_ghi, f"MRV {yc['ten']} {yc['ky_tu']}..{yc['ky_den']} ({ket_qua_id})")
    _cap_nhat(ket_qua_id, trang_thai="da_ghi_so", dolt_commit=ma_bam, so_cai_sha256=sha, ghi_so_luc=datetime.now(UTC))
    log.info("Đã ghi sổ cái: commit %s", ma_bam)
    return {"trang_thai": "da_ghi_so", "dolt_commit": ma_bam}
