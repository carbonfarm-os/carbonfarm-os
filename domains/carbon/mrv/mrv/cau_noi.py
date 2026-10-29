# SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors
# SPDX-License-Identifier: GPL-3.0-or-later
"""Tiến trình MRV: phục vụ deployment `mrv-lo-dat/carbon` và làm cầu nối CSDL ↔ Prefect.

Người dùng chỉ thao tác qua GraphQL (quyền bằng RLS): yêu cầu đo → dòng `cho_chay`; duyệt/từ chối → `da_duyet`/`tu_choi`.
Vòng lặp này thấy dòng mới thì tạo lượt chạy Prefect, thấy quyết định thì resume lượt chạy đang PAUSED.
Dùng thăm dò CSDL (vài giây) thay cho LISTEN/NOTIFY: không mất sự kiện khi tiến trình khởi động lại.
"""
from __future__ import annotations

import logging
import threading
import time

from prefect.client.orchestration import get_client
from prefect.deployments import run_deployment

from mrv import luu_tru
from mrv.flow import mrv_lo_dat

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
            "SELECT id::text, flow_run_id FROM carbon.ket_qua_mrv "
            "WHERE trang_thai IN ('da_duyet', 'tu_choi') AND NOT da_tiep_tuc AND flow_run_id IS NOT NULL"
        ).fetchall()
        if not cho_tiep:
            return
        with get_client(sync_client=True) as p:
            for dong in cho_tiep:
                if p.read_flow_run(dong["flow_run_id"]).state.type.value != "PAUSED":
                    continue  # flow chưa kịp dừng (quyết định đến rất nhanh) → vòng sau
                p.resume_flow_run(dong["flow_run_id"])
                c.execute("UPDATE carbon.ket_qua_mrv SET da_tiep_tuc = true WHERE id = %s", (dong["id"],))
                log.info("quyết định cho %s → resume %s", dong["id"], dong["flow_run_id"])


def vong_lap() -> None:
    time.sleep(5)  # chờ serve() đăng ký deployment
    while True:
        try:
            mot_vong()
        except Exception:  # lỗi tạm (mạng, CSDL khởi động lại) không được làm chết cầu nối
            log.exception("cầu nối: lỗi, thử lại")
        time.sleep(3)


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(name)s %(message)s")
    threading.Thread(target=vong_lap, daemon=True, name="cau-noi").start()
    mrv_lo_dat.serve(name="carbon")
