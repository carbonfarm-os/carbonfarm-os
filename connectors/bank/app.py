# SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors
# SPDX-License-Identifier: GPL-3.0-or-later
"""Bank mock – ghi có tiền bán tín chỉ vào tài khoản hợp tác xã. KHÔNG xử lý tiền thật, không kết nối ngân hàng nào.

Tài khoản tự mở ở lần ghi có đầu tiên. Ghi có idempotent theo mã tham chiếu (gửi lại không cộng hai lần).
"""
from __future__ import annotations

from datetime import UTC, datetime

from fastapi import APIRouter, Depends, FastAPI, HTTPException
from pydantic import BaseModel, Field

from connectors.chung.co_so import ket_noi, kiem_khoa

LUOC_DO = """
CREATE TABLE IF NOT EXISTS giao_dich (ma_tham_chieu TEXT PRIMARY KEY, so_tai_khoan TEXT NOT NULL, so_tien_vnd INTEGER NOT NULL,
  noi_dung TEXT NOT NULL, luc TEXT NOT NULL);
"""

app = FastAPI(title="Bank mock – ghi có tiền bán tín chỉ", version="0.1.0", description=__doc__)
ql = APIRouter(dependencies=[Depends(kiem_khoa("ket-noi-bank"))])


class GhiCo(BaseModel):
    so_tai_khoan: str = Field(pattern=r"^\d{8,19}$")
    so_tien_vnd: int = Field(gt=0)
    noi_dung: str = Field(min_length=3, max_length=200)
    ma_tham_chieu: str = Field(min_length=8)


class GiaoDich(BaseModel):
    ma_tham_chieu: str
    so_tai_khoan: str
    so_tien_vnd: int
    noi_dung: str
    luc: str


class TaiKhoan(BaseModel):
    so_tai_khoan: str
    so_du_vnd: int
    giao_dich: list[GiaoDich]


@app.get("/suc-khoe", tags=["Hệ thống"])
def suc_khoe() -> dict:
    return {"trang_thai": "ok"}


@ql.post("/ghi-co", status_code=201, tags=["Tài khoản"], response_model=GiaoDich)
def ghi_co(g: GhiCo) -> GiaoDich:
    with ket_noi("bank", LUOC_DO) as c:
        cu = c.execute("SELECT * FROM giao_dich WHERE ma_tham_chieu = ?", (g.ma_tham_chieu,)).fetchone()
        if cu:
            if cu["so_tai_khoan"] != g.so_tai_khoan or cu["so_tien_vnd"] != g.so_tien_vnd:
                raise HTTPException(409, "Mã tham chiếu đã dùng cho giao dịch khác")
            return GiaoDich(**dict(cu))
        gd = GiaoDich(**g.model_dump(), luc=datetime.now(UTC).isoformat())
        c.execute("INSERT INTO giao_dich VALUES (:ma_tham_chieu, :so_tai_khoan, :so_tien_vnd, :noi_dung, :luc)", gd.model_dump())
    return gd


@ql.get("/tai-khoan/{so_tai_khoan}", tags=["Tài khoản"], response_model=TaiKhoan)
def xem(so_tai_khoan: str) -> TaiKhoan:
    with ket_noi("bank", LUOC_DO) as c:
        ds = [GiaoDich(**dict(r)) for r in
              c.execute("SELECT * FROM giao_dich WHERE so_tai_khoan = ? ORDER BY luc", (so_tai_khoan,)).fetchall()]
    if not ds:
        raise HTTPException(404, "Tài khoản chưa có giao dịch nào")
    return TaiKhoan(so_tai_khoan=so_tai_khoan, so_du_vnd=sum(g.so_tien_vnd for g in ds), giao_dich=ds)


app.include_router(ql)
