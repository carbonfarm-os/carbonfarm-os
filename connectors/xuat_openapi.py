# SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors
# SPDX-License-Identifier: GPL-3.0-or-later
"""Xuất hợp đồng OpenAPI của từng connector ra connectors/<tên>/openapi.yaml; `--kiem` chỉ so, lệch thì thoát mã 1.

Hợp đồng là thứ bên ngoài dựa vào (bản thật thay mock phải giữ đúng); CI chạy `--kiem` để tệp không lệch mã.
Chạy từ gốc repo: python3 -m connectors.xuat_openapi [--kiem]
"""
from __future__ import annotations

import importlib
import sys
from pathlib import Path

import yaml

TEN = ("registry", "buyer", "bank")
DAU = "# SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors\n# SPDX-License-Identifier: GPL-3.0-or-later\n" \
      "# TỰ SINH bằng `python3 -m connectors.xuat_openapi` – không sửa tay.\n"


def noi_dung(ten: str) -> str:
    app = importlib.import_module(f"connectors.{ten}.app").app
    return DAU + yaml.safe_dump(app.openapi(), allow_unicode=True, sort_keys=False, width=120)


def main() -> int:
    kiem = "--kiem" in sys.argv
    lech = []
    for ten in TEN:
        tep = Path(__file__).parent / ten / "openapi.yaml"
        moi = noi_dung(ten)
        if kiem:
            if not tep.exists() or tep.read_text(encoding="utf-8") != moi:
                lech.append(str(tep))
        else:
            tep.write_text(moi, encoding="utf-8")
            print(f"đã ghi {tep}")
    if lech:
        print("Hợp đồng OpenAPI lệch mã, chạy `task openapi`:", *lech, sep="\n  ")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
