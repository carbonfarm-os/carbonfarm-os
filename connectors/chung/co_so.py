# SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors
# SPDX-License-Identifier: GPL-3.0-or-later
"""Khóa truy cập (Bearer, do OpenBao sinh, đọc từ /run/bimat) và CSDL SQLite của từng connector mock."""
from __future__ import annotations

import hmac
import os
import sqlite3
from contextlib import contextmanager
from pathlib import Path
from typing import Annotated

from fastapi import Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

THU_MUC = Path(os.environ.get("KET_NOI_DU_LIEU", "/du-lieu"))
BEARER = HTTPBearer(auto_error=False, scheme_name="khoaConnector")


def kiem_khoa(ten_bi_mat: str):
    """Dependency FastAPI: yêu cầu `Authorization: Bearer <khóa>` khớp bí mật `ten_bi_mat`."""
    tep = Path(os.environ.get("BIMAT", "/run/bimat")) / ten_bi_mat

    def _kiem(cred: Annotated[HTTPAuthorizationCredentials | None, Depends(BEARER)]) -> None:
        dung = tep.read_text().strip()
        if cred is None or not hmac.compare_digest(cred.credentials.encode(), dung.encode()):
            raise HTTPException(401, "Thiếu hoặc sai khóa truy cập connector")

    return _kiem


@contextmanager
def ket_noi(ten: str, luoc_do: str):
    """Kết nối SQLite (tạo lược đồ nếu chưa có); mỗi khối with là một transaction."""
    THU_MUC.mkdir(parents=True, exist_ok=True)
    c = sqlite3.connect(THU_MUC / f"{ten}.sqlite3", isolation_level=None, timeout=10)
    c.row_factory = sqlite3.Row
    c.executescript(luoc_do)
    try:
        c.execute("BEGIN IMMEDIATE")
        yield c
        c.execute("COMMIT")
    except BaseException:
        c.execute("ROLLBACK")
        raise
    finally:
        c.close()
