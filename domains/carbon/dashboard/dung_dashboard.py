# SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors
# SPDX-License-Identifier: GPL-3.0-or-later
"""Dựng dashboard hợp tác xã trên Metabase OSS qua API (#39) – chạy một lần lúc khởi động, chạy lại không tạo trùng.

1. Lần đầu: hoàn tất cài đặt Metabase (tài khoản quản trị, mật khẩu do OpenBao sinh) + kết nối PostgreSQL bằng vai
   chỉ đọc carbon_bao_cao (chỉ thấy schema carbon_bao_cao).
2. Tạo các thẻ (truy vấn SQL trên view báo cáo) và dashboard; dashboard đã có thì bỏ qua.
Chỉ thư viện chuẩn của Python.
"""
from __future__ import annotations

import json
import os
import time
import urllib.error
import urllib.request
from pathlib import Path

GOC = os.environ.get("METABASE_URL", "http://metabase:3000")
EMAIL = os.environ.get("METABASE_EMAIL", "quan-tri@carbonfarm.invalid")
TEN_CSDL = "CarbonFarm – báo cáo"
TEN_DASHBOARD = "Hợp tác xã – tín chỉ carbon"
BIMAT = Path("/run/bimat")

# (tên thẻ, kiểu hiển thị, SQL, cột, hàng, rộng, cao) – lưới Metabase rộng 24 cột
THE = [
    ("Tổng quan hợp tác xã", "table", ("SELECT hop_tac_xa, tinh, so_xa_vien, so_lo_hoat_dong, dien_tich_ha "
     "FROM carbon_bao_cao.tong_quan_htx ORDER BY hop_tac_xa"), 0, 0, 12, 4),
    ("Tín chỉ: đã cấp, đã bán, trong ví", "bar", ("SELECT hop_tac_xa, da_cap, da_ban, trong_vi "
     "FROM carbon_bao_cao.tin_chi_htx ORDER BY hop_tac_xa"), 12, 0, 12, 4),
    ("Doanh thu bán tín chỉ (đ)", "scalar", ("SELECT coalesce(sum(doanh_thu_vnd), 0) AS doanh_thu_vnd "
     "FROM carbon_bao_cao.tin_chi_htx"), 0, 4, 6, 3),
    ("CO₂e đã ghi sổ (t)", "scalar", ("SELECT coalesce(sum(co2e_tan), 0) AS co2e_tan FROM carbon_bao_cao.ket_qua_mrv "
     "WHERE trang_thai = 'da_ghi_so'"), 6, 4, 6, 3),
    ("CO₂e theo kỳ đo (đã ghi sổ)", "bar", ("SELECT ky_den, sum(co2e_tan) AS co2e_tan FROM carbon_bao_cao.ket_qua_mrv "
     "WHERE trang_thai = 'da_ghi_so' GROUP BY ky_den ORDER BY ky_den"), 12, 4, 12, 5),
    ("Kết quả đo MRV", "table", ("SELECT hop_tac_xa, lo_dat, ky_tu, ky_den, ngay_chup, dien_tich_tan_ha, co2e_tan, trang_thai, "
     "dolt_commit FROM carbon_bao_cao.ket_qua_mrv ORDER BY ky_den DESC, lo_dat"), 0, 9, 24, 5),
    ("Giao dịch bán", "table", ("SELECT ngay, hop_tac_xa, nguoi_mua, so_luong, don_gia_vnd, thanh_tien_vnd, dolt_commit "
     "FROM carbon_bao_cao.giao_dich_ban ORDER BY ngay DESC"), 0, 14, 24, 5),
]


def bi_mat(ten: str) -> str:
    return (BIMAT / ten).read_text().strip()


def goi(phuong_thuc: str, duong: str, du_lieu: dict | None = None, phien: str | None = None):
    req = urllib.request.Request(GOC + duong, method=phuong_thuc,
                                 data=None if du_lieu is None else json.dumps(du_lieu).encode(),
                                 headers={"Content-Type": "application/json",
                                          **({"X-Metabase-Session": phien} if phien else {})})
    with urllib.request.urlopen(req, timeout=60) as r:
        than = r.read()
    return json.loads(than) if than else None


def cho_metabase() -> None:
    for _ in range(180):
        try:
            if goi("GET", "/api/health").get("status") == "ok":
                return
        except (urllib.error.URLError, ConnectionError, json.JSONDecodeError):
            pass
        time.sleep(2)
    raise SystemExit("Metabase không sẵn sàng sau 6 phút")


def phien_quan_tri() -> str:
    mk = bi_mat("metabase-admin")
    token = goi("GET", "/api/session/properties").get("setup-token")
    if token and not goi("GET", "/api/session/properties").get("has-user-setup"):
        print("Metabase: cài đặt lần đầu")
        goi("POST", "/api/setup", {
            "token": token,
            "user": {"email": EMAIL, "password": mk, "first_name": "Quản trị", "last_name": "CarbonFarm",
                     "site_name": "CarbonFarm OS"},
            "prefs": {"site_name": "CarbonFarm OS", "site_locale": "vi", "allow_tracking": False},
        })
    return goi("POST", "/api/session", {"username": EMAIL, "password": mk})["id"]


def csdl(phien: str) -> int:
    ds = goi("GET", "/api/database", phien=phien)
    ds = ds.get("data", ds) if isinstance(ds, dict) else ds
    for d in ds:
        if d["name"] == TEN_CSDL:
            return d["id"]
    print("Metabase: kết nối PostgreSQL bằng vai chỉ đọc carbon_bao_cao")
    return goi("POST", "/api/database", {
        "engine": "postgres", "name": TEN_CSDL,
        "details": {"host": "postgres", "port": 5432, "dbname": "nen_tang", "user": "carbon_bao_cao",
                    "password": bi_mat("carbon-bao-cao-db"), "ssl": False, "schema-filters-type": "inclusion",
                    "schema-filters-patterns": "carbon_bao_cao"},
    }, phien)["id"]


def main() -> None:
    cho_metabase()
    phien = phien_quan_tri()
    ma_csdl = csdl(phien)
    if any(d["name"] == TEN_DASHBOARD for d in goi("GET", "/api/dashboard", phien=phien)):
        print("Metabase: dashboard đã có, bỏ qua")
        return
    the = []
    for ten, kieu, sql, cot, hang, rong, cao in THE:
        c = goi("POST", "/api/card", {"name": ten, "display": kieu, "visualization_settings": {},
                                      "dataset_query": {"type": "native", "database": ma_csdl, "native": {"query": sql}}}, phien)
        the.append({"id": -len(the) - 1, "card_id": c["id"], "col": cot, "row": hang, "size_x": rong, "size_y": cao})
    db = goi("POST", "/api/dashboard", {"name": TEN_DASHBOARD,
                                        "description": "Dựng tự động từ view carbon_bao_cao (chỉ đọc, không dữ liệu cá nhân)"}, phien)
    goi("PUT", f"/api/dashboard/{db['id']}", {"dashcards": the}, phien)
    print(f"Metabase: đã dựng dashboard \"{TEN_DASHBOARD}\" ({len(the)} thẻ)")


if __name__ == "__main__":
    main()
