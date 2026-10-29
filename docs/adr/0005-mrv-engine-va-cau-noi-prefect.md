<!-- SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors -->
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->
# 0005 · MRV engine: flow Prefect + cầu nối CSDL, ảnh Sentinel-2 Collection 1

- Trạng thái: chấp nhận
- Ngày: 2026-10-29
- Người viết: @Minhthuan12
- Issue / PR: #25

## Bối cảnh
Cán bộ hợp tác xã yêu cầu đo một lô trong một kỳ, xem kết quả, rồi duyệt hoặc từ chối. Kết quả được duyệt phải vào sổ cái. Cần quyết định ba điều:
1. người dùng chạm vào workflow bằng đường nào;
2. đọc ảnh từ đâu;
3. thư viện nào xử lý raster.

## Quyết định
**1. Người dùng chỉ đi qua GraphQL; tiến trình `carbon-mrv` làm cầu nối sang Prefect.**
- Yêu cầu đo và duyệt là hai hàm PostgreSQL (`carbonYeuCauMrv`, `carbonDuyetKetQuaMrv`). Quyền (cán bộ của lô hoặc quản trị) và luật chống sai (không đo chồng kỳ, chỉ duyệt khi đang chờ, từ chối phải có lý do) nằm trong CSDL như mọi luật khác (#23).
- Tiến trình `carbon-mrv` (`domains/carbon/mrv/mrv/cau_noi.py`) thăm dò bảng `carbon.ket_qua_mrv` vài giây một lần:
  - dòng mới → tạo lượt chạy deployment `mrv-lo-dat/carbon`;
  - có quyết định → resume lượt chạy đang PAUSED.
- **Phương án loại:**
  - cho web gọi thẳng API Prefect qua `/workflow`: API Prefect không biết lô thuộc hợp tác xã nào, ai có JWT cũng resume được mọi lượt chạy;
  - LISTEN/NOTIFY: mất sự kiện khi tiến trình khởi động lại; thăm dò thì không.

**2. Ảnh: Earth Search, collection `sentinel-2-c1-l2a`.**
- Đã thử collection cũ `sentinel-2-l2a` trên cảnh `S2C_48PVQ_20260414_0_L2A` (baseline 05.12):
  - giá trị thô băng đỏ ≈ 166, tức offset đã bị trừ sẵn, nhưng `raster:bands` vẫn ghi `offset: -0.1`;
  - áp theo metadata cho NDVI > 1 (sai).
- Collection 1 (`sentinel-2-c1-l2a`, cùng ngày) có giá trị thô ≈ 1166, khớp `offset: -0.1`, NDVI tán ≈ 0,89.
- MRV áp scale/offset theo `raster:bands` của chính asset, nên chọn collection mà metadata khớp dữ liệu.

**3. Xử lý raster bằng rasterio** (GDAL đi kèm wheel), đọc cửa sổ quanh lô qua HTTP range (COG), không tải cả cảnh.

## Hệ quả
- Workflow engine (Tầng 1) vẫn tổng quát. Mọi nghiệp vụ và quyền nằm trong miền carbon.
- Kết quả có phả hệ đầy đủ trong `ket_qua_mrv.pha_he`. Sản phẩm NDVI là COG trong S3 nền tảng + item STAC `carbon-mrv/<id>` (`derived_from` → cảnh Earth Search).
- Được duyệt → bản ghi Dolt. CSDL giữ mã băm commit và SHA-256 bản ghi (`tests/tich-hop/test_mrv_so_cai.py` đối chiếu hai phía).
- Flow dừng bằng `pause_flow_run` trong tiến trình, tối đa 24 giờ. Chờ lâu hơn cần chuyển sang `suspend_flow_run` + lưu kết quả task (ghi nhận để làm sau).
- Smoke cần Internet (Earth Search + COG công khai); CI không chạy smoke.
- Thêm thư viện, giấy phép đọc từ metadata gói trong image ngày 29/10/2026:
  - rasterio 1.5.2 (BSD-3-Clause, kèm GDAL 3.12.2, PROJ 9.8.1, GEOS…);
  - numpy 2.5.4 (BSD-3-Clause);
  - psycopg 3.3.6 (LGPL-3.0, tương thích GPL-3.0);
  - PyMySQL 1.2.3 (MIT);
  - boto3 1.43.121 (Apache-2.0).
