# SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors
# SPDX-License-Identifier: GPL-3.0-or-later
"""Dạng JSON chuẩn để băm bản ghi sổ cái – dùng chung khi ghi (luu_tru) và khi kiểm chứng (kiem_chung). Chỉ thư viện chuẩn."""
from __future__ import annotations

import json


def _chuan_so(x):
    """Số thực có giá trị nguyên → số nguyên (Dolt lưu JSON 1.0 thành 1); đệ quy trong dict/list."""
    if isinstance(x, float) and x.is_integer():
        return int(x)
    if isinstance(x, dict):
        return {k: _chuan_so(v) for k, v in x.items()}
    if isinstance(x, list):
        return [_chuan_so(v) for v in x]
    return x


def json_chuan(du_lieu: dict) -> str:
    """JSON dạng chuẩn để băm ổn định: khóa sắp xếp, không khoảng trắng, số nguyên không có ".0".

    Bên kiểm chứng đọc bản ghi từ sổ cái rồi tính lại bằng đúng hàm này (mrv/kiem_chung.py) phải ra cùng SHA-256.
    """
    return json.dumps(_chuan_so(du_lieu), ensure_ascii=False, sort_keys=True, separators=(",", ":"), default=str)
