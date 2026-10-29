<!-- SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors -->
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->
# Lộ trình · Roadmap (30/10 – 10/12/2026)

Mỗi dòng `- [ ]` là **một issue** (mẫu "Việc cần làm"), đưa vào sprint 1 tuần trên GitHub Projects. Vai:
- **V1** – nền tảng Tầng 1, DevOps, bảo mật (`Minhthuan12`, trưởng nhóm)
- **V2** – dữ liệu, ảnh vệ tinh, MRV, sổ cái (`Nhvuu918`)
- **V3** – web, bản đồ, dashboard, connector (thành viên 3, bổ sung sau)

Hạn nộp 17:00 06/12/2026; PoF chấm theo kho lúc gửi bài. **Đóng băng tính năng 29/11.**

## Sprint 1 · 30/10–08/11 · Chốt stack, lõi Tầng 1 chạy được → v0.1.0
- [ ] V1 · Dựng repo trên GitHub: bảo vệ `main`, bật Issues, Projects (Iteration 1 tuần), Discussions
- [ ] V1 · Lõi Tầng 1: Keycloak realm nền tảng + OTP vai quản trị, APISIX kiểm JWT, OpenBao giữ bí mật (bỏ chế độ dev)
- [ ] V1 · PostgreSQL + PostGIS + PostGraphile (RLS theo claim JWT), qua gateway
- [ ] V2 · Lưu trữ đối tượng Versity S3 + pgSTAC + stac-fastapi + TiTiler, qua gateway
- [ ] V2 · Prefect server + worker, một flow mẫu tổng quát (không nghiệp vụ), qua gateway
- [ ] V1 · Valkey (event bus) + Dolt (sổ cái) chạy trong compose
- [ ] Mọi người · Mỗi người viết một ADR cho phần mình chọn (0002 stack + giấy phép, 0003 sổ cái Dolt, 0004 quy trình trunk-based)
- [ ] V3 · Khung SvelteKit + MapLibre, đăng nhập Keycloak (PKCE)
- [ ] V1 · `task smoke` (Hurl) phủ toàn bộ Tầng 1; release-please ra **v0.1.0**

## Sprint 2 · 09–15/11 · Đăng ký lô đất, pipeline MRV → v0.2.0
- [ ] V2 · Schema miền carbon trong `domains/carbon/` (hợp tác xã, xã viên, lô đất), dữ liệu giả, RLS theo vai
- [ ] V3 · Vẽ và đăng ký lô đất trên bản đồ; Poka-yoke chồng lấn và diện tích trong CSDL
- [ ] V2 · `methodology/`: đặc tả phương pháp v0.1 (chỉ số thực vật × hệ số carbon, có trích dẫn)
- [ ] V2 · Flow MRV: tìm Sentinel-2 qua STAC, cắt theo lô, tính chỉ số, lưu COG + item STAC, ghi phả hệ
- [ ] V3 · Xem ảnh vệ tinh và kết quả MRV của lô trên bản đồ (TiTiler)
- [ ] V1 · Ra **v0.2.0**

## Sprint 3 · 16–22/11 · Duyệt, ví, sổ cái, connector, demo công khai → v0.3.0
- [ ] V2 · Duyệt MRV (flow dừng chờ cán bộ), ghi kết quả + phả hệ vào Dolt
- [ ] V3 · Connector mock Registry (theo TT 11/2026/TT-BNNMT), Buyer, Bank, mỗi cái có OpenAPI
- [ ] V2 · Ví tín chỉ, cấp và chuyển nhượng ghi vào Dolt; trang kiểm chứng theo mã băm commit
- [ ] V3 · Dashboard hợp tác xã trên Metabase OSS
- [ ] V1 · Demo công khai trên VPS + HTTPS
- [ ] V1 · Ra **v0.3.0**

## Sprint 4 · 23–29/11 · Người dùng thử, sửa lỗi, tài liệu · đóng băng 29/11
- [ ] Mọi người · Mời 3–5 người dùng thử (cán bộ hợp tác xã, sinh viên), mỗi phản hồi một issue
- [ ] Mọi người · Sửa lỗi theo phản hồi
- [ ] V3 · Trang tài liệu Starlight (README, kiến trúc, ADR, phương pháp MRV)
- [ ] V1 · Kịch bản demo 15 phút, phân vai trình bày

## Sprint 5 · 30/11–06/12 · Nộp bài
- [ ] V1 · `/pof-check`, sửa thiếu sót, **v1.0.0**, gửi email trước 17:00 06/12

## 07–10/12 · Luyện trình bày
- [ ] Mọi người · Tập 15 phút + hỏi đáp, video demo dự phòng; chỉ sửa lỗi demo
