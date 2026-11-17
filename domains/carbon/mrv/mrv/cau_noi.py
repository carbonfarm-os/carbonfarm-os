# SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors
# SPDX-License-Identifier: GPL-3.0-or-later
"""Tiến trình MRV: phục vụ deployment `mrv-lo-dat/carbon` và làm cầu nối CSDL ↔ Prefect / connector.

Người dùng chỉ thao tác qua GraphQL (quyền bằng RLS): yêu cầu đo → dòng `cho_chay`; duyệt/từ chối → `da_duyet`/`tu_choi`.
Vòng lặp này thấy dòng mới thì tạo lượt chạy Prefect, thấy quyết định thì resume lượt chạy đang PAUSED,
thấy đề nghị cấp tín chỉ thì gọi Registry mock và ghi sổ cái (mrv/tin_chi.py), thấy lệnh bán đã duyệt thì gọi
Buyer → Registry → Bank và ghi sổ cái (mrv/ban.py).
Dùng thăm dò CSDL (vài giây) thay cho LISTEN/NOTIFY: không mất sự kiện khi tiến trình khởi động lại.
"""
from __future__ import annotations

import logging
import threading
import time

from prefect.client.orchestration import get_client
from prefect.deployments import run_deployment

from mrv import ban, luu_tru, tin_chi
from mrv.flow import ghi_so_cai_mrv, mrv_lo_dat

log = logging.getLogger("mrv.cau_noi")
DEPLOYMENT = "mrv-lo-dat/carbon"


def mot_vong() -> None:
    with luu_tru.csdl() as c:
        for dong in c.execute("SELECT id::text FROM carbon.ket_qua_mrv WHERE trang_thai = 'cho_chay' ORDER BY yeu_cau_luc").fetchall():
            # Giành dòng trước khi tạo lượt chạy: chỉ một tiến trình thắng
            if c.execute("UPDATE carbon.ket_qua_mrv SET trang_thai = 'dang_chay' WHERE id = %s AND trang_thai = 'cho_chay'",
                         (dong["id"],)).rowcount != 1:
                continue
            lr = run_deployment(DEPLOYMENT, parameters={"ket_qua_id": dong["id"]}, timeout=0)
            c.execute("UPDATE carbon.ket_qua_mrv SET flow_run_id = %s WHERE id = %s", (lr.id, dong["id"]))
            log.info("yêu cầu %s → lượt chạy %s", dong["id"], lr.id)

        cho_tiep = c.execute(
            "SELECT id::text, trang_thai, flow_run_id, (duyet_luc < now() - interval '15 seconds') AS da_qua_15s "
            "FROM carbon.ket_qua_mrv "
            "WHERE (trang_thai IN ('da_duyet', 'tu_choi') AND NOT da_tiep_tuc) "
            "   OR (trang_thai = 'da_duyet' AND dolt_commit IS NULL AND da_tiep_tuc AND duyet_luc < now() - interval '30 seconds')"
        ).fetchall()
        if not cho_tiep:
            return
        with get_client(sync_client=True) as p:
            for dong in cho_tiep:
                trang_thai_flow = None
                if dong["flow_run_id"]:
                    try:
                        trang_thai_flow = p.read_flow_run(dong["flow_run_id"]).state.type.value
                    except Exception:  # noqa: BLE001
                        trang_thai_flow = None
                if trang_thai_flow == "PAUSED":
                    p.resume_flow_run(dong["flow_run_id"])
                    c.execute("UPDATE carbon.ket_qua_mrv SET da_tiep_tuc = true WHERE id = %s", (dong["id"],))
                    log.info("quyết định cho %s → resume %s", dong["id"], dong["flow_run_id"])
                elif trang_thai_flow in ("RUNNING", "PENDING", "SCHEDULED") and not dong["da_qua_15s"]:
                    continue  # flow chưa kịp dừng (quyết định đến rất nhanh) → vòng sau
                else:
                    # Tiến trình Prefect cũ đã kết thúc hoặc mất trạng thái sau khi container khởi động lại: ghi sổ cái trực tiếp.
                    if dong["trang_thai"] == "da_duyet":
                        kq = ghi_so_cai_mrv(dong["id"])
                        log.info("ghi sổ cái trực tiếp cho %s → %s", dong["id"], kq.get("dolt_commit"))
                    c.execute("UPDATE carbon.ket_qua_mrv SET da_tiep_tuc = true WHERE id = %s", (dong["id"],))


def vong_tin_chi() -> None:
    with luu_tru.csdl() as c:
        tin_chi.mot_vong(c)
        ban.mot_vong(c)


def vong_lap() -> None:
    time.sleep(5)  # chờ serve() đăng ký deployment
    while True:
        try:
            mot_vong()
            vong_tin_chi()
        except Exception:  # lỗi tạm (mạng, CSDL khởi động lại) không được làm chết cầu nối
            log.exception("cầu nối: lỗi, thử lại")
        time.sleep(3)


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(name)s %(message)s")
    threading.Thread(target=vong_lap, daemon=True, name="cau-noi").start()
    mrv_lo_dat.serve(name="carbon")
