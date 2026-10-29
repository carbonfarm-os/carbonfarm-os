<!-- SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors -->
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->
# domains/carbon/ · Tầng 2 – miền tín chỉ carbon

Ứng dụng H-P-D-I (trọng tâm [P] + [D]) trên Tầng 1, **chỉ gọi lõi qua gateway** hoặc giao thức chuẩn (GraphQL, S3, STAC).

Dự kiến:
- `db/`: schema hợp tác xã, xã viên, lô đất, ví; RLS; dữ liệu giả.
- `mrv/`: MRV engine Python, flow Prefect.
- `web/`: SvelteKit + MapLibre.
- `dashboard/`: câu hỏi và dashboard Metabase dựng bằng mã.
- `compose`: khai báo trong `compose/carbon.yaml`.

Thêm miền khác (ví dụ thủy sản) = thêm `domains/<tên>/`, không sửa `platform/`.
