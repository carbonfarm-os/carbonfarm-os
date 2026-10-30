# SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors
# SPDX-License-Identifier: GPL-3.0-or-later
"""Buyer mock – người mua tín chỉ (doanh nghiệp, quỹ) GIẢ. Nhận đơn mua khi đơn giá không vượt mức người mua chấp nhận.

Tên, mã số thuế đều giả (mã số thuế dạng 99xxxxxxxx, không thuộc tổ chức thật). Không có tiền thật.
"""
from __future__ import annotations

from datetime import UTC, datetime
from typing import Literal

from fastapi import APIRouter, Depends, FastAPI, HTTPException
from pydantic import BaseModel, Field

from connectors.chung.co_so import ket_noi, kiem_khoa

LUOC_DO = """
CREATE TABLE IF NOT EXISTS don_mua (ma_tham_chieu TEXT PRIMARY KEY, ma_nguoi_mua TEXT NOT NULL, so_luong INTEGER NOT NULL,
  don_gia_vnd INTEGER NOT NULL, thanh_tien_vnd INTEGER NOT NULL, trang_thai TEXT NOT NULL, luc TEXT NOT NULL);
"""


class NguoiMua(BaseModel):
    ma: str
    ten: str
    ma_so_thue: str = Field(description="Mã số thuế GIẢ (dùng làm tài khoản đăng ký bên nhận ở Registry mock)")
    so_tai_khoan_ngan_hang: str
    don_gia_toi_da_vnd: int = Field(description="Đơn giá cao nhất người mua chấp nhận cho 1 tín chỉ (1 t CO₂e)")


NGUOI_MUA = [
    NguoiMua(ma="NM-XANH", ten="Công ty Năng lượng Xanh Mẫu (giả)", ma_so_thue="9900000001",
             so_tai_khoan_ngan_hang="9704000000000001", don_gia_toi_da_vnd=300_000),
    NguoiMua(ma="NM-QUY", ten="Quỹ Khí hậu Cộng đồng Mẫu (giả)", ma_so_thue="9900000002",
             so_tai_khoan_ngan_hang="9704000000000002", don_gia_toi_da_vnd=250_000),
]

app = FastAPI(title="Buyer mock – người mua tín chỉ", version="0.1.0", description=__doc__)
ql = APIRouter(dependencies=[Depends(kiem_khoa("ket-noi-buyer"))])


class DatMua(BaseModel):
    ma_nguoi_mua: str
    so_luong: int = Field(gt=0, le=1_000_000)
    don_gia_vnd: int = Field(gt=0)
    ma_tham_chieu: str = Field(min_length=8, description="Mã lệnh bán của bên gọi; gửi lại cùng mã trả đơn cũ")


class DonMua(BaseModel):
    ma_tham_chieu: str
    ma_nguoi_mua: str
    so_luong: int
    don_gia_vnd: int
    thanh_tien_vnd: int
    trang_thai: Literal["chap_nhan"]
    luc: str


@app.get("/suc-khoe", tags=["Hệ thống"])
def suc_khoe() -> dict:
    return {"trang_thai": "ok"}


@ql.get("/nguoi-mua", tags=["Người mua"], response_model=list[NguoiMua])
def danh_sach() -> list[NguoiMua]:
    return NGUOI_MUA


@ql.post("/don-mua", status_code=201, tags=["Đơn mua"], response_model=DonMua)
def dat_mua(d: DatMua) -> DonMua:
    """Người mua chấp nhận nếu đơn giá ≤ mức tối đa; gửi lại cùng mã tham chiếu thì trả đơn đã có (idempotent)."""
    nm = next((n for n in NGUOI_MUA if n.ma == d.ma_nguoi_mua), None)
    if nm is None:
        raise HTTPException(404, f"Không có người mua {d.ma_nguoi_mua}")
    with ket_noi("buyer", LUOC_DO) as c:
        cu = c.execute("SELECT * FROM don_mua WHERE ma_tham_chieu = ?", (d.ma_tham_chieu,)).fetchone()
        if cu:
            return DonMua(**dict(cu))
        if d.don_gia_vnd > nm.don_gia_toi_da_vnd:
            raise HTTPException(422, f"{nm.ten} chỉ mua với đơn giá tối đa {nm.don_gia_toi_da_vnd:,} đ/tín chỉ".replace(",", "."))
        don = DonMua(ma_tham_chieu=d.ma_tham_chieu, ma_nguoi_mua=nm.ma, so_luong=d.so_luong, don_gia_vnd=d.don_gia_vnd,
                     thanh_tien_vnd=d.so_luong * d.don_gia_vnd, trang_thai="chap_nhan", luc=datetime.now(UTC).isoformat())
        c.execute("INSERT INTO don_mua VALUES (:ma_tham_chieu, :ma_nguoi_mua, :so_luong, :don_gia_vnd, :thanh_tien_vnd, "
                  ":trang_thai, :luc)", don.model_dump())
    return don


@ql.get("/don-mua/{ma_tham_chieu}", tags=["Đơn mua"], response_model=DonMua)
def xem_don(ma_tham_chieu: str) -> DonMua:
    with ket_noi("buyer", LUOC_DO) as c:
        cu = c.execute("SELECT * FROM don_mua WHERE ma_tham_chieu = ?", (ma_tham_chieu,)).fetchone()
    if not cu:
        raise HTTPException(404, "Không có đơn mua này")
    return DonMua(**dict(cu))


app.include_router(ql)
