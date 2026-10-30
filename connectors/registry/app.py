# SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors
# SPDX-License-Identifier: GPL-3.0-or-later
"""Registry mock – mô phỏng Hệ thống đăng ký quốc gia theo Thông tư 11/2026/TT-BNNMT (đọc bản PDF chính thức).

Bám thông tư ở: tài khoản gắn mã số thuế, mỗi tổ chức một tài khoản, ≥ 2 đầu mối (Điều 6); tiểu khoản Đăng ký chung,
Bù trừ, Phong tỏa (Điều 7); thông tin đăng ký tín chỉ (Điều 10); mã trong nước 9 ký tự và số sê-ri 19 ký tự (Điều 11);
bù trừ từ Đăng ký chung, từ chối khi vượt số dư (Điều 20).
Đơn giản hóa (KHÔNG phải quy định): Bộ không duyệt tay; chuyển quyền sở hữu do bán được ghi thẳng ở đây thay vì qua
sàn giao dịch và Tổng công ty lưu ký (Điều 14–17); mã cơ chế là giá trị mock do bên gọi đưa.
"""
from __future__ import annotations

import json
from datetime import UTC, datetime
from typing import Literal

from fastapi import APIRouter, Depends, FastAPI, HTTPException
from pydantic import BaseModel, Field

from connectors.chung.co_so import ket_noi, kiem_khoa

LUOC_DO = """
CREATE TABLE IF NOT EXISTS tai_khoan (mst TEXT PRIMARY KEY, ten TEXT NOT NULL, dau_moi TEXT NOT NULL, tao_luc TEXT NOT NULL);
CREATE TABLE IF NOT EXISTS ma_tin_chi (ma TEXT PRIMARY KEY, ten_du_an TEXT NOT NULL, ten_co_che TEXT NOT NULL,
  so_cuoi INTEGER NOT NULL DEFAULT 0);
CREATE TABLE IF NOT EXISTS khoi (id INTEGER PRIMARY KEY, ma TEXT NOT NULL, tu INTEGER NOT NULL, den INTEGER NOT NULL,
  mst TEXT NOT NULL, tieu_khoan TEXT NOT NULL);
CREATE TABLE IF NOT EXISTS nghiep_vu (ma_tham_chieu TEXT PRIMARY KEY, loai TEXT NOT NULL, ket_qua TEXT NOT NULL);
CREATE TABLE IF NOT EXISTS lich_su (id INTEGER PRIMARY KEY, luc TEXT NOT NULL, nghiep_vu TEXT NOT NULL, ma TEXT NOT NULL,
  tu INTEGER NOT NULL, den INTEGER NOT NULL, tu_mst TEXT, den_mst TEXT, tieu_khoan TEXT NOT NULL, ma_tham_chieu TEXT);
"""
TieuKhoan = Literal["dang_ky_chung", "bu_tru", "phong_toa"]
MST = Field(pattern=r"^\d{10}(-\d{3})?$", description="Mã số thuế (10 số, hoặc 13 với mã chi nhánh)", examples=["0000000001"])

app = FastAPI(
    title="Registry mock – Hệ thống đăng ký quốc gia (TT 11/2026/TT-BNNMT)",
    version="0.1.0",
    description=__doc__,
)
ql = APIRouter(dependencies=[Depends(kiem_khoa("ket-noi-registry"))])


def _db():
    return ket_noi("registry", LUOC_DO)


def _luc() -> str:
    return datetime.now(UTC).isoformat()


def _seri(ma: str, n: int) -> str:
    return f"{ma}-{n:010d}"


class DauMoi(BaseModel):
    ho_ten: str = Field(min_length=2)
    chuc_vu: str
    email: str
    dien_thoai: str


class TaoTaiKhoan(BaseModel):
    ma_so_thue: str = MST
    ten_to_chuc: str = Field(min_length=3)
    dau_moi: list[DauMoi] = Field(min_length=2, description="Tối thiểu 02 cá nhân đầu mối (Điều 6 khoản 4)")


class DaiSeri(BaseModel):
    ma_trong_nuoc: str
    seri_tu: str
    seri_den: str
    so_luong: int


class TaiKhoan(BaseModel):
    ma_so_thue: str
    ten_to_chuc: str
    tieu_khoan: dict[str, list[DaiSeri]]
    so_du: dict[str, int]


class DangKyTinChi(BaseModel):
    ma_so_thue: str = MST
    ten_du_an: str = Field(min_length=3)
    ma_du_an: str = Field(pattern=r"^[A-Z0-9]{4}$", description="Mã dự án, 4 ký tự chữ/số (Điều 11 khoản 4)")
    ten_co_che: str
    ma_co_che: str = Field(pattern=r"^[A-Z0-9]{3}$", description="Mã cơ chế, 3 ký tự (mock – không phải mã thật)")
    nam_xac_nhan: int = Field(ge=2020, le=2100, description="Năm lượng giảm/hấp thụ được xác nhận")
    so_luong: int = Field(gt=0)
    ma_tham_chieu: str = Field(min_length=8, description="Mã của bên gọi; gửi lại cùng mã → 409 (chống cấp hai lần)")


class ChuyenQuyen(BaseModel):
    tu_ma_so_thue: str = MST
    den_ma_so_thue: str = MST
    ma_trong_nuoc: str = Field(pattern=r"^[A-Z0-9]{3}-[A-Z0-9]{4}-\d{2}$")
    so_luong: int = Field(gt=0)
    ma_tham_chieu: str = Field(min_length=8)


class BuTru(BaseModel):
    ma_so_thue: str = MST
    ma_trong_nuoc: str = Field(pattern=r"^[A-Z0-9]{3}-[A-Z0-9]{4}-\d{2}$")
    so_luong: int = Field(gt=0)
    ma_tham_chieu: str = Field(min_length=8)


class KetQuaNghiepVu(BaseModel):
    ma_tham_chieu: str
    nghiep_vu: str
    dai_seri: list[DaiSeri]
    luc: str


class SuKien(BaseModel):
    luc: str
    nghiep_vu: str
    tu_ma_so_thue: str | None
    den_ma_so_thue: str | None
    tieu_khoan: str
    ma_tham_chieu: str | None


class TraSeri(BaseModel):
    so_seri: str
    ma_trong_nuoc: str
    ten_du_an: str
    chu_so_huu: str
    tieu_khoan: str
    lich_su: list[SuKien]


def _da_lam(c, ma_tham_chieu: str) -> None:
    if c.execute("SELECT 1 FROM nghiep_vu WHERE ma_tham_chieu = ?", (ma_tham_chieu,)).fetchone():
        raise HTTPException(409, f"Mã tham chiếu {ma_tham_chieu} đã được xử lý – không thực hiện lần hai")


def _can_tai_khoan(c, mst: str) -> None:
    if not c.execute("SELECT 1 FROM tai_khoan WHERE mst = ?", (mst,)).fetchone():
        raise HTTPException(404, f"Không có tài khoản đăng ký gắn mã số thuế {mst}")


def _rut(c, mst: str, ma: str, tieu_khoan: str, so_luong: int) -> list[tuple[int, int]]:
    """Lấy `so_luong` đơn vị (số sê-ri nhỏ trước) khỏi tiểu khoản; tách khối nếu cần. Thiếu → 422."""
    khoi = c.execute("SELECT id, tu, den FROM khoi WHERE mst = ? AND ma = ? AND tieu_khoan = ? ORDER BY tu",
                     (mst, ma, tieu_khoan)).fetchall()
    co = sum(k["den"] - k["tu"] + 1 for k in khoi)
    if so_luong > co:
        raise HTTPException(422, f"Vượt số dư: tiểu khoản {tieu_khoan} có {co} tín chỉ {ma}, đề nghị {so_luong}")
    lay, con = [], so_luong
    for k in khoi:
        if con == 0:
            break
        n = min(con, k["den"] - k["tu"] + 1)
        lay.append((k["tu"], k["tu"] + n - 1))
        if n == k["den"] - k["tu"] + 1:
            c.execute("DELETE FROM khoi WHERE id = ?", (k["id"],))
        else:
            c.execute("UPDATE khoi SET tu = ? WHERE id = ?", (k["tu"] + n, k["id"]))
        con -= n
    return lay


def _ghi(c, nghiep_vu: str, ma: str, dai: list[tuple[int, int]], tu_mst, den_mst, tieu_khoan, ma_tham_chieu) -> KetQuaNghiepVu:
    luc = _luc()
    for tu, den in dai:
        if den_mst:
            c.execute("INSERT INTO khoi (ma, tu, den, mst, tieu_khoan) VALUES (?, ?, ?, ?, ?)", (ma, tu, den, den_mst, tieu_khoan))
        c.execute("INSERT INTO lich_su (luc, nghiep_vu, ma, tu, den, tu_mst, den_mst, tieu_khoan, ma_tham_chieu) "
                  "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)", (luc, nghiep_vu, ma, tu, den, tu_mst, den_mst, tieu_khoan, ma_tham_chieu))
    kq = KetQuaNghiepVu(ma_tham_chieu=ma_tham_chieu, nghiep_vu=nghiep_vu, luc=luc, dai_seri=[
        DaiSeri(ma_trong_nuoc=ma, seri_tu=_seri(ma, tu), seri_den=_seri(ma, den), so_luong=den - tu + 1) for tu, den in dai])
    c.execute("INSERT INTO nghiep_vu (ma_tham_chieu, loai, ket_qua) VALUES (?, ?, ?)", (ma_tham_chieu, nghiep_vu, kq.model_dump_json()))
    return kq


@app.get("/suc-khoe", tags=["Hệ thống"])
def suc_khoe() -> dict:
    return {"trang_thai": "ok"}


@ql.post("/tai-khoan", status_code=201, tags=["Tài khoản đăng ký"], response_model=TaiKhoan)
def tao_tai_khoan(tk: TaoTaiKhoan) -> TaiKhoan:
    """Cấp tài khoản đăng ký gắn mã số thuế; mỗi tổ chức chỉ một tài khoản (Điều 6 khoản 1, 2)."""
    with _db() as c:
        if c.execute("SELECT 1 FROM tai_khoan WHERE mst = ?", (tk.ma_so_thue,)).fetchone():
            raise HTTPException(409, f"Mã số thuế {tk.ma_so_thue} đã có tài khoản đăng ký – mỗi tổ chức chỉ một tài khoản")
        c.execute("INSERT INTO tai_khoan VALUES (?, ?, ?, ?)",
                  (tk.ma_so_thue, tk.ten_to_chuc, json.dumps([d.model_dump() for d in tk.dau_moi], ensure_ascii=False), _luc()))
    return xem_tai_khoan(tk.ma_so_thue)


@ql.get("/tai-khoan/{ma_so_thue}", tags=["Tài khoản đăng ký"], response_model=TaiKhoan)
def xem_tai_khoan(ma_so_thue: str) -> TaiKhoan:
    """Số dư và dải sê-ri theo từng tiểu khoản (Điều 7)."""
    with _db() as c:
        tk = c.execute("SELECT * FROM tai_khoan WHERE mst = ?", (ma_so_thue,)).fetchone()
        if not tk:
            raise HTTPException(404, f"Không có tài khoản đăng ký gắn mã số thuế {ma_so_thue}")
        khoi = c.execute("SELECT * FROM khoi WHERE mst = ? ORDER BY ma, tu", (ma_so_thue,)).fetchall()
    tieu: dict[str, list[DaiSeri]] = {t: [] for t in ("dang_ky_chung", "bu_tru", "phong_toa")}
    for k in khoi:
        tieu[k["tieu_khoan"]].append(DaiSeri(ma_trong_nuoc=k["ma"], seri_tu=_seri(k["ma"], k["tu"]),
                                             seri_den=_seri(k["ma"], k["den"]), so_luong=k["den"] - k["tu"] + 1))
    return TaiKhoan(ma_so_thue=tk["mst"], ten_to_chuc=tk["ten"], tieu_khoan=tieu,
                    so_du={t: sum(d.so_luong for d in ds) for t, ds in tieu.items()})


@ql.post("/tin-chi/dang-ky", status_code=201, tags=["Tín chỉ"], response_model=KetQuaNghiepVu)
def dang_ky(dk: DangKyTinChi) -> KetQuaNghiepVu:
    """Đăng ký tín chỉ vào tiểu khoản Đăng ký chung; cấp mã trong nước và dải số sê-ri liên tiếp (Điều 10, 11)."""
    ma = f"{dk.ma_co_che}-{dk.ma_du_an}-{dk.nam_xac_nhan % 100:02d}"
    with _db() as c:
        _da_lam(c, dk.ma_tham_chieu)
        _can_tai_khoan(c, dk.ma_so_thue)
        c.execute("INSERT OR IGNORE INTO ma_tin_chi (ma, ten_du_an, ten_co_che) VALUES (?, ?, ?)", (ma, dk.ten_du_an, dk.ten_co_che))
        cuoi = c.execute("SELECT so_cuoi FROM ma_tin_chi WHERE ma = ?", (ma,)).fetchone()["so_cuoi"]
        if cuoi + dk.so_luong > 9_999_999_999:
            raise HTTPException(422, "Vượt dải số sê-ri 10 chữ số của mã trong nước")
        c.execute("UPDATE ma_tin_chi SET so_cuoi = ? WHERE ma = ?", (cuoi + dk.so_luong, ma))
        return _ghi(c, "dang_ky", ma, [(cuoi + 1, cuoi + dk.so_luong)], None, dk.ma_so_thue, "dang_ky_chung", dk.ma_tham_chieu)


@ql.post("/tin-chi/chuyen-quyen", status_code=201, tags=["Tín chỉ"], response_model=KetQuaNghiepVu)
def chuyen_quyen(cq: ChuyenQuyen) -> KetQuaNghiepVu:
    """Ghi nhận chủ sở hữu mới sau giao dịch bán (mock; thực tế qua sàn và lưu ký – Điều 14–17).
    Chỉ chuyển từ tiểu khoản Đăng ký chung; số sê-ri nhỏ trước."""
    if cq.tu_ma_so_thue == cq.den_ma_so_thue:
        raise HTTPException(422, "Bên chuyển và bên nhận trùng nhau")
    with _db() as c:
        _da_lam(c, cq.ma_tham_chieu)
        _can_tai_khoan(c, cq.tu_ma_so_thue)
        _can_tai_khoan(c, cq.den_ma_so_thue)
        dai = _rut(c, cq.tu_ma_so_thue, cq.ma_trong_nuoc, "dang_ky_chung", cq.so_luong)
        return _ghi(c, "chuyen_quyen", cq.ma_trong_nuoc, dai, cq.tu_ma_so_thue, cq.den_ma_so_thue, "dang_ky_chung", cq.ma_tham_chieu)


@ql.post("/tin-chi/bu-tru", status_code=201, tags=["Tín chỉ"], response_model=KetQuaNghiepVu)
def bu_tru(bt: BuTru) -> KetQuaNghiepVu:
    """Dùng tín chỉ để bù trừ: chuyển từ Đăng ký chung sang Bù trừ; vượt số dư → từ chối (Điều 20 khoản 1)."""
    with _db() as c:
        _da_lam(c, bt.ma_tham_chieu)
        _can_tai_khoan(c, bt.ma_so_thue)
        dai = _rut(c, bt.ma_so_thue, bt.ma_trong_nuoc, "dang_ky_chung", bt.so_luong)
        return _ghi(c, "bu_tru", bt.ma_trong_nuoc, dai, bt.ma_so_thue, bt.ma_so_thue, "bu_tru", bt.ma_tham_chieu)


@ql.get("/tin-chi/seri/{so_seri}", tags=["Tín chỉ"], response_model=TraSeri)
def tra_seri(so_seri: str) -> TraSeri:
    """Tra một số sê-ri: chủ sở hữu, tiểu khoản hiện tại, lịch sử nghiệp vụ (Điều 4 khoản 3)."""
    ma, _, so = so_seri.rpartition("-")
    if not so.isdigit() or len(so) != 10:
        raise HTTPException(422, "Số sê-ri phải có dạng <mã trong nước>-<10 chữ số>")
    n = int(so)
    with _db() as c:
        mtc = c.execute("SELECT * FROM ma_tin_chi WHERE ma = ?", (ma,)).fetchone()
        k = c.execute("SELECT * FROM khoi WHERE ma = ? AND tu <= ? AND den >= ?", (ma, n, n)).fetchone()
        if not mtc or not k:
            raise HTTPException(404, f"Không có tín chỉ số sê-ri {so_seri}")
        ls = c.execute("SELECT * FROM lich_su WHERE ma = ? AND tu <= ? AND den >= ? ORDER BY id", (ma, n, n)).fetchall()
    return TraSeri(so_seri=so_seri, ma_trong_nuoc=ma, ten_du_an=mtc["ten_du_an"], chu_so_huu=k["mst"], tieu_khoan=k["tieu_khoan"],
                   lich_su=[SuKien(luc=r["luc"], nghiep_vu=r["nghiep_vu"], tu_ma_so_thue=r["tu_mst"], den_ma_so_thue=r["den_mst"],
                                   tieu_khoan=r["tieu_khoan"], ma_tham_chieu=r["ma_tham_chieu"]) for r in ls])


app.include_router(ql)
