# SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors
# SPDX-License-Identifier: GPL-3.0-or-later
"""Flow MẪU tổng quát của Tầng 1: xử lý → dừng chờ người duyệt → tiếp tục.

Không có nghiệp vụ carbon. Đây là khuôn để miền nghiệp vụ (ví dụ flow MRV ở domains/carbon) viết flow có bước
Human-in-the-loop: flow dừng ở trạng thái PAUSED, người duyệt gọi API resume (qua gateway /workflow) thì chạy tiếp.
Chạy bằng `python xu_ly_co_duyet.py`: tiến trình này đăng ký deployment "xu-ly-co-duyet/mau" và thực thi các lượt chạy.
"""
from __future__ import annotations

import hashlib

from prefect import flow, get_run_logger, pause_flow_run, task


@task
def xu_ly(noi_dung: str) -> str:
    """Bước xử lý mẫu: tính băm SHA-256 của nội dung đầu vào."""
    return hashlib.sha256(noi_dung.encode("utf-8")).hexdigest()


@task
def hoan_tat(ma_bam: str) -> dict:
    return {"ma_bam": ma_bam, "trang_thai": "da_duyet"}


@flow(name="xu-ly-co-duyet", log_prints=True)
def xu_ly_co_duyet(noi_dung: str = "mau") -> dict:
    logger = get_run_logger()
    ma_bam = xu_ly(noi_dung)
    logger.info("Đã xử lý, chờ người duyệt (resume qua API)")
    pause_flow_run(timeout=3600, poll_interval=2, key="cho-duyet")
    ket_qua = hoan_tat(ma_bam)
    logger.info("Đã duyệt, hoàn tất")
    return ket_qua


if __name__ == "__main__":
    xu_ly_co_duyet.serve(name="mau")
