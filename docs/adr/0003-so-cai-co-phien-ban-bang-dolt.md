<!-- SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors -->
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->
# 0003 · Sổ cái có phiên bản bằng Dolt

- Trạng thái: chấp nhận
- Ngày: 2026-10-29
- Người viết: @Minhthuan12 (bổ sung bởi @Nhvuu918 khi làm MRV)
- Issue / PR: #10

## Bối cảnh
Mỗi tín chỉ carbon phải truy vết được: kết quả MRV nào, ảnh nào, ai duyệt, bao giờ cấp, chuyển cho ai. Đề thi nêu nguyên lý "lưu trữ lạnh bằng sổ cái mật mã bất biến". Bên mua và Registry cần kiểm lại mà không phải tin máy chủ của đội.

## Các phương án (giấy phép đọc từ LICENSE trên repo gốc ngày 29/10/2026)
| Phương án | Giấy phép | Ưu | Nhược |
|---|---|---|---|
| immudb | **Business Source License** từ bản 1.9 | Sổ cái chuyên dụng, có bằng chứng | Không phải OSI → loại |
| Trillian / Tessera (nhật ký Merkle) | Apache-2.0 | Bằng chứng inclusion/consistency chuẩn | Trillian đang ở chế độ bảo trì; Tessera là lựa chọn của một đội cùng trường – tránh trùng |
| Bảng chỉ-thêm + chuỗi băm trong PostgreSQL | (mã của đội) | Không thêm dịch vụ | Cách một đội cùng trường đã làm – tránh trùng; phải tự viết xác minh |
| **Dolt** | Apache-2.0 | CSDL SQL có phiên bản kiểu git: mỗi lần ghi là commit có mã băm nội dung (Merkle DAG), có `dolt_log`, `dolt_diff`, xem lại mọi thời điểm. Khớp nhu cầu **phả hệ dữ liệu MRV** | Không có bằng chứng inclusion kiểu nhật ký minh bạch; người có quyền quản trị máy chủ vẫn có thể viết lại lịch sử |

## Quyết định
- Dùng **Dolt** (`dolthub/dolt-sql-server`) làm sổ cái của Tầng 1: CSDL `so_cai`, bảng tổng quát `ban_ghi` (loại, mã đối tượng, dữ liệu JSON, SHA-256).
- Mỗi lần ghi gọi `DOLT_COMMIT` và trả mã băm commit cho bên gọi.
- Miền nghiệp vụ quyết định ghi gì. Không ghi dữ liệu cá nhân, chỉ mã xã viên, mã lô, số liệu.

## Hệ quả
- **Kiểm chứng:** mã băm commit được công bố cho người mua và Registry (sprint 3). Họ đối chiếu với `dolt_log` / `dolt_diff` qua API đọc công khai.
- **Chống viết lại lịch sử:** định kỳ neo mã băm commit đầu (HEAD) ra nơi công khai bên ngoài máy chủ, ví dụ ghi vào Release hoặc issue công khai của repo. Một ADR sau sẽ quyết định cách neo.
- **Kiểm thử:** `tests/tich-hop/test_so_cai_su_kien.py` (thêm → commit có mã băm → `dolt_log` và `dolt_diff` khớp; sửa → lịch sử giữ giá trị cũ).
