#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors
# SPDX-License-Identifier: GPL-3.0-or-later
"""Kiểm và thêm header SPDX cho mọi tệp được git theo dõi (hoặc sắp thêm).

    python3 scripts/spdx.py check   # liệt kê tệp thiếu header, thoát mã 1 nếu có
    python3 scripts/spdx.py fix     # thêm header cho tệp thiếu

Header gồm hai dòng, viết theo cú pháp chú thích của từng loại tệp:
    SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors
    SPDX-License-Identifier: GPL-3.0-or-later
Tệp không chú thích được (JSON, ảnh, LICENSE) nằm trong BO_QUA; giấy phép của chúng ghi ở NOTICE.
"""
from __future__ import annotations

import subprocess
import sys
from pathlib import Path

BAN_QUYEN = "SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors"
GIAY_PHEP = "SPDX-License-Identifier: GPL-3.0-or-later"

# Đuôi tệp → (mở chú thích, đóng chú thích)
KIEU_CHU_THICH: dict[str, tuple[str, str]] = {
    ".py": ("# ", ""), ".sh": ("# ", ""), ".yaml": ("# ", ""), ".yml": ("# ", ""),
    ".toml": ("# ", ""), ".hurl": ("# ", ""), ".hcl": ("# ", ""), ".txt": ("# ", ""), ".env": ("# ", ""), ".example": ("# ", ""),
    ".sql": ("-- ", ""), ".ts": ("// ", ""), ".js": ("// ", ""), ".mjs": ("// ", ""),
    ".css": ("/* ", " */"), ".md": ("<!-- ", " -->"), ".svelte": ("<!-- ", " -->"),
    ".html": ("<!-- ", " -->"),
}
TEN_DAC_BIET: dict[str, tuple[str, str]] = {
    "Dockerfile": ("# ", ""), ".gitignore": ("# ", ""), ".dockerignore": ("# ", ""),
    "CODEOWNERS": ("# ", ""), ".gitattributes": ("# ", ""), ".npmrc": ("# ", ""),
}
# CHANGELOG.md do release-please sinh và ghi đè mỗi lần phát hành
BO_QUA_TEN = {"LICENSE", "NOTICE", "pixi.lock", "CHANGELOG.md"}
BO_QUA_DUOI = {".json", ".png", ".jpg", ".jpeg", ".gif", ".svg", ".ico", ".tif", ".tiff", ".lock", ".woff2"}


def danh_sach_tep() -> list[Path]:
    ra = subprocess.run(
        ["git", "ls-files", "--cached", "--others", "--exclude-standard"],
        check=True, capture_output=True, text=True,
    ).stdout.splitlines()
    return [Path(p) for p in ra if Path(p).is_file()]


def kieu(p: Path) -> tuple[str, str] | None:
    if p.name in BO_QUA_TEN or p.suffix.lower() in BO_QUA_DUOI:
        return None
    if p.name in TEN_DAC_BIET:
        return TEN_DAC_BIET[p.name]
    return KIEU_CHU_THICH.get(p.suffix.lower())


def co_header(noi_dung: str) -> bool:
    dau = "\n".join(noi_dung.splitlines()[:6])
    return BAN_QUYEN in dau and GIAY_PHEP in dau


def them_header(p: Path, mo: str, dong: str) -> None:
    noi_dung = p.read_text(encoding="utf-8")
    header = f"{mo}{BAN_QUYEN}{dong}\n{mo}{GIAY_PHEP}{dong}\n"
    dong_dau = noi_dung.split("\n", 1)
    if noi_dung.startswith("#!") and len(dong_dau) == 2:
        noi_dung = dong_dau[0] + "\n" + header + dong_dau[1]
    else:
        noi_dung = header + noi_dung
    p.write_text(noi_dung, encoding="utf-8")


def main() -> int:
    if len(sys.argv) != 2 or sys.argv[1] not in {"check", "fix"}:
        print(__doc__)
        return 2
    thieu, khong_ro = [], []
    for p in danh_sach_tep():
        k = kieu(p)
        if k is None:
            if p.name not in BO_QUA_TEN and p.suffix.lower() not in BO_QUA_DUOI:
                khong_ro.append(p)
            continue
        if not co_header(p.read_text(encoding="utf-8", errors="replace")):
            thieu.append((p, k))
    if sys.argv[1] == "fix":
        for p, (mo, dong) in thieu:
            them_header(p, mo, dong)
            print(f"thêm header: {p}")
        thieu = []
    for p in khong_ro:
        print(f"CHƯA BIẾT KIỂU CHÚ THÍCH: {p} (thêm vào KIEU_CHU_THICH hoặc BO_QUA)")
    for p, _ in thieu:
        print(f"THIẾU SPDX: {p}")
    if thieu or khong_ro:
        return 1
    print("OK: mọi tệp có header SPDX GPL-3.0-or-later")
    return 0


if __name__ == "__main__":
    sys.exit(main())
