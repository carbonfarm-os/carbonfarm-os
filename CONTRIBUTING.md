<!-- SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors -->
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->
# Đóng góp · Contributing

Dự án làm theo **trunk-based development**: chỉ có một nhánh dài hạn là `main`, mọi thay đổi đi qua nhánh ngắn và PR. *English summary at the end.*

## 1. Chuẩn bị máy (một lần)
- Cách nhanh nhất: mở repo bằng **Dev Container** (VS Code: "Reopen in Container"). Container có sẵn Docker, Node 22, pixi; `postCreateCommand` cài môi trường Python + GDAL và hook pre-commit.
- Không dùng Dev Container: cài [pixi](https://pixi.sh), rồi `pixi install` và `pixi run pre-commit install`. Lệnh dự án chạy bằng `task` (go-task, có trong môi trường pixi).
- `cp .env.example .env`, rồi `task up` và `task smoke`.

## 2. Một việc đi từ issue tới `main`
1. **Issue.** Tạo bằng mẫu "Việc cần làm" (Issue Form): chọn vai V1/V2/V3, mô tả, tiêu chí hoàn thành. Issue nằm trong bảng GitHub Projects của đội, gắn vào **sprint 1 tuần** (trường Iteration). Không dùng milestone theo tuần.
2. **Nhánh ngắn** tách từ `main` mới nhất, tên `<loại>/<số-issue>-<tên-ngắn>`, ví dụ `feat/12-dang-ky-lo-dat`, `docs/15-adr-so-cai`. Một nhánh một issue, **sống tối đa 3 ngày**; việc lớn hơn thì chia issue.
3. **Commit** theo [Conventional Commits](https://www.conventionalcommits.org/): `feat|fix|docs|test|build|ci|chore(phạm-vi): mô tả tiếng Việt (#số)`. `release-please` dựa vào tiền tố này để viết CHANGELOG và nâng phiên bản, nên **không sửa CHANGELOG bằng tay**.
4. **PR về `main`** theo mẫu PR, ghi `Closes #số`. CI (`task check`, `task lint`) phải xanh.
5. **Duyệt.** GitHub tự gán chủ vùng mã theo `.github/CODEOWNERS`. Cần **1 lượt duyệt của người khác người viết**; người viết không tự duyệt, không merge bằng quyền admin.
6. **Squash merge**, xóa nhánh.

**Ai làm thì người đó commit bằng tài khoản GitHub của mình.** Lịch sử commit là bằng chứng đóng góp của từng thành viên.

## 3. Quyết định kỹ thuật: ADR
Mỗi lựa chọn có ảnh hưởng lâu dài (thêm thành phần, đổi cấu trúc, đổi phương pháp MRV) ghi thành một **ADR** trong `docs/adr/`, theo mẫu `docs/adr/0000-mau.md`. ADR đi cùng PR thực hiện nó. Người viết ADR là người trình bày phần đó ở chung kết.

## 4. Giấy phép và phụ thuộc
- Mọi tệp mã có header SPDX hai dòng (`task license` tự thêm, `task check` kiểm):
  `SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors` và `SPDX-License-Identifier: GPL-3.0-or-later`.
- Thêm hoặc nâng thành phần bên thứ ba: sửa `DEPENDENCIES.md` và `NOTICE` trong cùng PR, kèm ADR nếu là dịch vụ mới. Thành phần copyleft/không OSI chỉ chạy như dịch vụ riêng, image gốc, không sửa mã.
- Không vendor, không sửa mã thư viện bên thứ ba. Không commit `.env`, `.data/`, ảnh vệ tinh tải về, dữ liệu thật của người dân.

## 5. Phát hành
`release-please` mở sẵn một "PR phát hành" khi có commit `feat`/`fix` mới trên `main`. Merge PR đó thì workflow tự gắn tag `vX.Y.Z`, tạo GitHub Release và đính kèm `carbonfarm-os-X.Y.Z.tar.gz`, `SHA256SUMS`, `sbom.cdx.json`. Trước khi merge PR phát hành: `task up` + `task smoke` trên volume trống.

## English summary
Trunk-based: short-lived branches `<type>/<issue>-<slug>` off `main`, Conventional Commits, PR with green CI and one approval from a code owner other than the author, squash merge. Releases are automated by release-please (tag, tarball, checksums, CycloneDX SBOM). Every source file carries a GPL-3.0-or-later SPDX header; third-party components are listed in `DEPENDENCIES.md` and `NOTICE`.
