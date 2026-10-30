# SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors
# SPDX-License-Identifier: GPL-3.0-or-later
"""Kết nối dịch vụ Tầng 1 trong mạng nội bộ: PostgreSQL (vai carbon_mrv), S3, STAC Transactions, sổ cái Dolt.

Bí mật đọc từ /run/bimat (OpenBao sinh), không qua biến môi trường hay dòng lệnh.
"""
from __future__ import annotations

import hashlib
import os
from pathlib import Path

import boto3
import httpx
import numpy as np
import psycopg
import pymysql
import rasterio
from psycopg.rows import dict_row
from rasterio.io import MemoryFile

from mrv.json_chuan import json_chuan

BIMAT = Path("/run/bimat")
BUCKET = os.environ.get("MRV_BUCKET", "anh-ve-tinh")
STAC = os.environ.get("STAC_URL", "http://stac:8080")
BO_SUU_TAP = "carbon-mrv"


def bi_mat(ten: str) -> str:
    return (BIMAT / ten).read_text().strip()


def csdl() -> psycopg.Connection:
    return psycopg.connect(
        host="postgres", dbname="nen_tang", user="carbon_mrv", password=bi_mat("carbon-mrv-db"),
        row_factory=dict_row, autocommit=True,
    )


def ghi_cog(ndvi: np.ndarray, crs: str, transform: list[float], khoa: str) -> str:
    """NDVI (float32, NaN = ngoài lô/không hợp lệ) → COG trong bộ nhớ → S3 nền tảng. Trả href s3://."""
    with MemoryFile() as mf:
        with mf.open(
            driver="COG", width=ndvi.shape[1], height=ndvi.shape[0], count=1, dtype="float32", nodata=np.nan,
            crs=crs, transform=rasterio.Affine(*transform), compress="DEFLATE",
        ) as dst:
            dst.write(ndvi, 1)
            dst.set_band_description(1, "NDVI")
        du_lieu = mf.read()
    boto3.client(
        "s3", endpoint_url="http://s3:7070", region_name="us-east-1",
        aws_access_key_id=bi_mat("s3-truy-cap"), aws_secret_access_key=bi_mat("s3-bi-mat"),
    ).put_object(Bucket=BUCKET, Key=khoa, Body=du_lieu, ContentType="image/tiff; application=geotiff; profile=cloud-optimized")
    return f"s3://{BUCKET}/{khoa}"


def dang_ky_stac(item: dict) -> None:
    """Thêm item vào bộ sưu tập carbon-mrv (tạo bộ sưu tập nếu chưa có); chạy lại thì cập nhật."""
    with httpx.Client(base_url=STAC, timeout=30) as c:
        if c.get(f"/collections/{BO_SUU_TAP}").status_code == 404:
            tao = c.post("/collections", json={
                "type": "Collection", "stac_version": "1.0.0", "id": BO_SUU_TAP,
                "description": "Sản phẩm MRV của miền carbon: NDVI đã cắt theo lô, kèm phả hệ tới cảnh Sentinel-2 nguồn",
                # Sản phẩm dẫn xuất từ dữ liệu Copernicus Sentinel (điều khoản dữ liệu mở của Copernicus, ghi nguồn)
                "license": "other",
                "extent": {"spatial": {"bbox": [[-180, -90, 180, 90]]}, "temporal": {"interval": [[None, None]]}},
                "links": [],
            })
            # Hai lượt đo chạy song song trên hệ thống mới cùng thấy 404; lượt tạo sau nhận 409 – bộ sưu tập đã có là đủ.
            if tao.status_code != 409:
                tao.raise_for_status()
        r = c.post(f"/collections/{BO_SUU_TAP}/items", json=item)
        if r.status_code == 409:
            r = c.put(f"/collections/{BO_SUU_TAP}/items/{item['id']}", json=item)
        r.raise_for_status()


def ghi_so_cai(ma_doi_tuong: str, du_lieu: dict, thong_diep: str, loai: str = "ket_qua_mrv") -> tuple[str, str]:
    """Ghi một bản ghi vào sổ cái Dolt rồi DOLT_COMMIT. Trả (mã băm commit, sha256 dữ liệu).

    Đã có bản ghi cùng (loai, ma_doi_tuong) – lần trước ghi xong nhưng chưa kịp báo về – thì trả commit cũ, không ghi đôi.
    """
    noi_dung = json_chuan(du_lieu)
    sha = hashlib.sha256(noi_dung.encode()).hexdigest()
    ket_noi = pymysql.connect(host="dolt", port=3306, user="so_cai", password=bi_mat("dolt-so-cai"), database="so_cai",
                              autocommit=True)
    try:
        with ket_noi.cursor() as cur:
            cur.execute("SELECT d.to_commit, b.sha256 FROM ban_ghi b JOIN dolt_diff_ban_ghi d ON d.to_id = b.id "
                        "AND d.diff_type = 'added' WHERE b.loai = %s AND b.ma_doi_tuong = %s LIMIT 1", (loai, ma_doi_tuong))
            cu = cur.fetchone()
            if cu:
                return cu[0], cu[1]
            cur.execute("INSERT INTO ban_ghi (loai, ma_doi_tuong, du_lieu, sha256) VALUES (%s, %s, %s, %s)",
                        (loai, ma_doi_tuong, noi_dung, sha))
            cur.execute("CALL DOLT_COMMIT('-am', %s)", (thong_diep,))
            ma_bam = cur.fetchone()[0]
    finally:
        ket_noi.close()
    return ma_bam, sha
