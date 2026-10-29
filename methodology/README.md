<!-- SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors -->
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->
# methodology/ · Phương pháp ước lượng carbon

Mỗi phiên bản phương pháp là một tệp đặc tả có số phiên bản (`v0.1-…md`). MRV engine ghi phiên bản đã dùng vào phả hệ của mọi kết quả, để bên xác minh tái lập được con số.

Mỗi đặc tả phải có:
1. phạm vi (hệ sinh thái, khu vực);
2. dữ liệu đầu vào (Sentinel-2 L2A: băng phổ, ngưỡng mây);
3. công thức (chỉ số thực vật, hệ số quy đổi sinh khối → carbon → CO₂e);
4. **nguồn trích dẫn** cho mọi hệ số (bài báo, hướng dẫn IPCC, tài liệu chính thức);
5. sai số và giới hạn đã biết.

**Không đưa hệ số không có nguồn vào đặc tả.** Đặc tả v0.1 viết ở sprint 2 (`docs/roadmap.md`).
