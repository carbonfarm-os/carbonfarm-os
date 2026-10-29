<!-- SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors -->
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->
# 0001 · Ghi quyết định kiến trúc bằng ADR

- Trạng thái: chấp nhận
- Ngày: 2026-10-29
- Người viết: khung dự án (người hướng dẫn)

## Bối cảnh
Đội mới, ít thời gian, phải giải thích được mọi lựa chọn công nghệ trước giám khảo. Mỗi thành viên cần một bằng chứng viết tay cho phần mình phụ trách.

## Quyết định
Mỗi quyết định có ảnh hưởng lâu dài là một tệp `docs/adr/NNNN-ten.md` theo mẫu `0000-mau.md` (dạng MADR rút gọn), đi kèm PR thực hiện nó. Người viết ADR là người trình bày phần đó ở chung kết.

Ba ADR đầu do thành viên viết trong sprint 1:
- **0002** stack và giấy phép từng thành phần;
- **0003** sổ cái có phiên bản bằng Dolt;
- **0004** quy trình trunk-based + release-please.

## Hệ quả
ADR là tài liệu sống, được trang tài liệu Starlight hiển thị từ sprint 4. Không sửa ADR đã chấp nhận; muốn đổi thì viết ADR mới thay thế.
