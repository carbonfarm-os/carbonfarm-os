<!-- SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors -->
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->
# 0004 · Quy trình trunk-based và phát hành bằng release-please

- Trạng thái: chấp nhận
- Ngày: 2026-10-29
- Người viết: @Minhthuan12
- Issue / PR: #6

## Bối cảnh
- Đội 3 người, 5 tuần, phải có lịch sử commit đều của cả nhóm và bản phát hành có tag + `.tar.gz` trước 17:00 06/12/2026 (PoF tiêu chí 1, 3).
- Thang điểm trừ điểm khi kho mã "có nhưng không thực sự dùng" và khi không có changelog.
- Hai đội cùng trường dùng `main` + `develop` và changelog viết tay hoặc git-cliff. Đội này cần cách làm riêng.

## Các phương án
1. **Git flow (`main` + `develop`).** Quen thuộc. Nhưng thêm một nhánh dài hạn phải đồng bộ, và PR phát hành `develop → main` dễ tồn đọng; với đội nhỏ thì thừa.
2. **Trunk-based (chỉ `main`, nhánh ngắn ≤ 3 ngày).** Ít nhánh, mỗi PR nhỏ nên duyệt nhanh. Đổi lại phải có CI và bảo vệ `main` chặt.
3. **CHANGELOG:** viết tay (dễ quên) / git-cliff (phải chạy lệnh khi phát hành) / **release-please** (Apache-2.0, bot tự mở "PR phát hành" từ Conventional Commits, merge là có tag + Release).

## Quyết định
- **Nhánh:** trunk-based. `main` được bảo vệ: bắt buộc PR, CI `check` xanh, 1 duyệt của chủ vùng mã (CODEOWNERS) khác người viết, lịch sử thẳng, cấm force-push. Nhánh `<loại>/<số-issue>-<tên>`, squash merge.
- **Commit:** Conventional Commits có số issue.
- **Phát hành:** release-please (`release-type: simple`, bản đầu `0.1.0`). Workflow đính kèm `.tar.gz` (git archive), `SHA256SUMS` và SBOM CycloneDX (Syft) vào mỗi Release.
- **Kế hoạch:** GitHub Projects với trường Sprint (1 tuần), thay cho milestone.

## Hệ quả
- PR phát hành luôn mở sẵn. **Chỉ merge khi xong sprint** và smoke đạt trên volume trống (`/release` kiểm trước).
- Tổ chức phải cho GitHub Actions tạo PR (đã bật 29/10/2026).
- Quyền admin được phép merge thiếu duyệt. Chỉ dùng khi người hướng dẫn cho phép rõ, ghi lý do trong PR.
