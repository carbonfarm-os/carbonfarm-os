<!-- SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors -->
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->
# Lộ trình · Roadmap (30/10 – 10/12/2026)

Mỗi dòng `- [ ]` là **một issue** (mẫu "Việc cần làm"), đưa vào sprint 1 tuần trên GitHub Projects. Vai:
- **V1** – nền tảng Tầng 1, DevOps, bảo mật (`Minhthuan12`, trưởng nhóm)
- **V2** – dữ liệu, ảnh vệ tinh, MRV, sổ cái (`Nhvuu918`)
- **V3** – web, bản đồ, dashboard, connector (thành viên 3, bổ sung sau)

Hạn nộp 17:00 06/12/2026; PoF chấm theo kho lúc gửi bài. **Đóng băng tính năng 29/11.**

**Tiến độ 30/10/2026:** xong sprint 1–3 sớm (v0.1.0, v0.2.0, v0.3.0) và phần chuẩn bị của sprint 4 (v0.4.0: giao diện mới, hướng dẫn dùng thử, kịch bản demo, sơ đồ kiến trúc); còn demo công khai trên VPS (#40, chờ máy chủ và tên miền), người dùng thử thật (#54), trang tài liệu (#53). Phần lớn mã do trưởng nhóm viết; các sprint sau ưu tiên **mỗi thành viên commit phần mình** và duyệt chéo.

## Sprint 1 · 30/10–08/11 · Chốt stack, lõi Tầng 1 chạy được → v0.1.0
- [x] V1 · Dựng repo trên GitHub: bảo vệ `main`, bật Issues, Projects (Iteration 1 tuần), Discussions (#5)
- [x] V1 · Lõi Tầng 1: Keycloak realm nền tảng + OTP vai quản trị, APISIX kiểm JWT, OpenBao giữ bí mật (bỏ chế độ dev) (#6)
- [x] V1 · PostgreSQL + PostGIS + PostGraphile (RLS theo claim JWT), qua gateway (#7)
- [x] V2 · Lưu trữ đối tượng Versity S3 + pgSTAC + stac-fastapi + TiTiler, qua gateway (#8)
- [x] V2 · Prefect server + worker, một flow mẫu tổng quát (không nghiệp vụ), qua gateway (#9)
- [x] V1 · Valkey (event bus) + Dolt (sổ cái) chạy trong compose (#10)
- [x] Mọi người · Mỗi người viết một ADR cho phần mình chọn (0002 stack + giấy phép, 0003 sổ cái Dolt, 0004 quy trình trunk-based) (#12)
- [x] V3 · Khung SvelteKit + MapLibre, đăng nhập Keycloak (PKCE) (#11)
- [x] V1 · `task smoke` (Hurl) phủ toàn bộ Tầng 1; release-please ra **v0.1.0** (#14)

## Sprint 2 · 09–15/11 · Đăng ký lô đất, pipeline MRV → v0.2.0
- [x] V2 · Schema miền carbon trong `domains/carbon/` (hợp tác xã, xã viên, lô đất), dữ liệu giả, RLS theo vai (#22)
- [x] V3 · Vẽ và đăng ký lô đất trên bản đồ; Poka-yoke chồng lấn và diện tích trong CSDL (#23)
- [x] V2 · `methodology/`: đặc tả phương pháp v0.1 (chỉ số thực vật × hệ số carbon, có trích dẫn) (#24)
- [x] V2 · Flow MRV: tìm Sentinel-2 qua STAC, cắt theo lô, tính chỉ số, lưu COG + item STAC, ghi phả hệ (#25)
- [x] V3 · Xem ảnh vệ tinh và kết quả MRV của lô trên bản đồ (TiTiler) (#26)
- [x] V1 · Ra **v0.2.0** (#27)

## Sprint 3 · 16–22/11 · Duyệt, ví, sổ cái, connector, demo công khai → v0.3.0
- [x] V2 · Duyệt MRV (flow dừng chờ cán bộ), ghi kết quả + phả hệ vào Dolt (#25)
- [x] V3 · Connector mock Registry (theo TT 11/2026/TT-BNNMT), Buyer, Bank, mỗi cái có OpenAPI (#35)
- [x] V2 · Ví tín chỉ, cấp và chuyển nhượng ghi vào Dolt; trang kiểm chứng theo mã băm commit (#36, #37, #38)
- [x] V3 · Dashboard hợp tác xã trên Metabase OSS (#39)
- [ ] V1 · Demo công khai trên VPS + HTTPS
- [x] V1 · Ra **v0.3.0** (#41)

## Sprint 4 · 23–29/11 · Người dùng thử, sửa lỗi, tài liệu · đóng băng 29/11
- [ ] Mọi người · Mời 3–5 người dùng thử (cán bộ hợp tác xã, sinh viên), mỗi phản hồi một issue (#54)
- [ ] Mọi người · Sửa lỗi theo phản hồi
- [ ] V3 · Trang tài liệu Starlight (README, kiến trúc, ADR, phương pháp MRV) (#53)
- [x] V1 · Kịch bản demo 15 phút, phân vai trình bày (#56)
- [x] V1 · Mẫu phản hồi và hướng dẫn dùng thử (#55); giao diện mới (#51); sửa lỗi MRV song song (#60); ra **v0.4.0**

## Sprint 5 · 30/11–06/12 · Nộp bài
- [ ] V1 · `/pof-check`, sửa thiếu sót, **v1.0.0**, gửi email trước 17:00 06/12

## 07–10/12 · Luyện trình bày
- [ ] Mọi người · Tập 15 phút + hỏi đáp, video demo dự phòng; chỉ sửa lỗi demo
