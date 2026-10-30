# Changelog

## [0.4.0](https://github.com/carbonfarm-os/carbonfarm-os/compare/v0.3.0...v0.4.0) (2026-10-30)


### Tính năng mới

* **web:** làm lại giao diện trang chủ, màn hình cán bộ và trang kiểm chứng ([#51](https://github.com/carbonfarm-os/carbonfarm-os/issues/51)) ([#52](https://github.com/carbonfarm-os/carbonfarm-os/issues/52)) ([6046859](https://github.com/carbonfarm-os/carbonfarm-os/commit/6046859ff6971c2824c275d77a0db60ffafc9fe8))


### Sửa lỗi

* **mrv:** hai lượt đo song song trên hệ thống mới không còn lỗi 409 khi tạo bộ sưu tập STAC ([#60](https://github.com/carbonfarm-os/carbonfarm-os/issues/60)) ([#61](https://github.com/carbonfarm-os/carbonfarm-os/issues/61)) ([1ad58d1](https://github.com/carbonfarm-os/carbonfarm-os/commit/1ad58d134312fd01feeca371ab0fdac23dce979e))


### Tài liệu

* **demo:** kịch bản trình bày chung kết 15 phút và phân vai ([#56](https://github.com/carbonfarm-os/carbonfarm-os/issues/56)) ([#58](https://github.com/carbonfarm-os/carbonfarm-os/issues/58)) ([e41811e](https://github.com/carbonfarm-os/carbonfarm-os/commit/e41811e3d5017b77a3ead07e066c736e2f2d417d))
* **kien-truc:** thêm ảnh sơ đồ kiến trúc hai tầng ([#59](https://github.com/carbonfarm-os/carbonfarm-os/issues/59)) ([ddc5ce6](https://github.com/carbonfarm-os/carbonfarm-os/commit/ddc5ce6bc97aa205715237f41c6c1560495a8a10))
* **roadmap:** đánh dấu sprint 1–3 đã xong, ghi tiến độ 30/10 ([#49](https://github.com/carbonfarm-os/carbonfarm-os/issues/49)) ([72e17cc](https://github.com/carbonfarm-os/carbonfarm-os/commit/72e17cce4fde2c24d3dd0b47b4f46b437341d332))
* **thu-nghiem:** mẫu phản hồi dùng thử, hướng dẫn 6 nhiệm vụ, cập nhật README ([#55](https://github.com/carbonfarm-os/carbonfarm-os/issues/55)) ([#57](https://github.com/carbonfarm-os/carbonfarm-os/issues/57)) ([b417c61](https://github.com/carbonfarm-os/carbonfarm-os/commit/b417c617988684989986961297903e7e19da8be4))

## [0.3.0](https://github.com/carbonfarm-os/carbonfarm-os/compare/v0.2.0...v0.3.0) (2026-10-30)


### Tính năng mới

* **carbon:** bán tín chỉ cho người mua mock – tạo và duyệt bởi hai người, tiền về Bank mock, ghi sổ cái ([#37](https://github.com/carbonfarm-os/carbonfarm-os/issues/37)) ([#46](https://github.com/carbonfarm-os/carbonfarm-os/issues/46)) ([d9486d6](https://github.com/carbonfarm-os/carbonfarm-os/commit/d9486d639ab53f57886fca5f2835302fd6fda1ab))
* **carbon:** cấp tín chỉ vào ví hợp tác xã qua Registry mock, mỗi kết quả MRV một lần, ghi sổ cái ([#36](https://github.com/carbonfarm-os/carbonfarm-os/issues/36)) ([#45](https://github.com/carbonfarm-os/carbonfarm-os/issues/45)) ([a2c1307](https://github.com/carbonfarm-os/carbonfarm-os/commit/a2c13079b8333d7050a3904f127aeb1484263e3b))
* **carbon:** dashboard hợp tác xã trên Metabase OSS, dựng tự động trên view báo cáo chỉ đọc ([#39](https://github.com/carbonfarm-os/carbonfarm-os/issues/39)) ([#48](https://github.com/carbonfarm-os/carbonfarm-os/issues/48)) ([0bb09fc](https://github.com/carbonfarm-os/carbonfarm-os/commit/0bb09fccc0cc24fa12e7df17c0934aad8f0747af))
* **carbon:** trang kiểm chứng công khai theo mã băm commit hoặc số sê-ri tín chỉ ([#38](https://github.com/carbonfarm-os/carbonfarm-os/issues/38)) ([#47](https://github.com/carbonfarm-os/carbonfarm-os/issues/47)) ([b3c6c4d](https://github.com/carbonfarm-os/carbonfarm-os/commit/b3c6c4d130cecbae2aa2d545c87153ee49d9423a))
* **connectors:** mock Registry theo TT 11/2026/TT-BNNMT, Buyer, Bank – hợp đồng OpenAPI ([#35](https://github.com/carbonfarm-os/carbonfarm-os/issues/35)) ([#42](https://github.com/carbonfarm-os/carbonfarm-os/issues/42)) ([b72886b](https://github.com/carbonfarm-os/carbonfarm-os/commit/b72886b127d1d444751d035ae83329e92ff0fe47))


### Sửa lỗi

* **carbon:** giới hạn thời gian đọc ảnh Sentinel-2 qua mạng để task MRV tự thử lại thay vì treo ([#44](https://github.com/carbonfarm-os/carbonfarm-os/issues/44)) ([a34ec62](https://github.com/carbonfarm-os/carbonfarm-os/commit/a34ec628fae476e2a320ad6abe165379c96b1ee7))

## [0.2.0](https://github.com/carbonfarm-os/carbonfarm-os/compare/v0.1.0...v0.2.0) (2026-10-29)


### Tính năng mới

* **carbon:** đăng ký lô bằng vẽ ranh giới, CSDL chặn sai theo Poka-yoke ([#23](https://github.com/carbonfarm-os/carbonfarm-os/issues/23)) ([#31](https://github.com/carbonfarm-os/carbonfarm-os/issues/31)) ([92f6118](https://github.com/carbonfarm-os/carbonfarm-os/commit/92f61188cd209c7bdc1fff84dd920809044b2af3))
* **carbon:** luồng MRV Prefect trên Sentinel-2, cán bộ duyệt, ghi sổ cái Dolt ([#25](https://github.com/carbonfarm-os/carbonfarm-os/issues/25)) ([#32](https://github.com/carbonfarm-os/carbonfarm-os/issues/32)) ([8d13144](https://github.com/carbonfarm-os/carbonfarm-os/commit/8d1314445950d72a9695dcd0522bf88e851f77d1))
* **carbon:** mô hình dữ liệu hợp tác xã, xã viên, lô đất + RLS và dữ liệu giả ([#22](https://github.com/carbonfarm-os/carbonfarm-os/issues/22)) ([#28](https://github.com/carbonfarm-os/carbonfarm-os/issues/28)) ([7030826](https://github.com/carbonfarm-os/carbonfarm-os/commit/7030826c5c5aa6f4bb40b2b30351546d46e81960))
* **carbon:** web xem lô, lớp NDVI, kết quả MRV + phả hệ, cán bộ yêu cầu đo và duyệt ([#26](https://github.com/carbonfarm-os/carbonfarm-os/issues/26)) ([#33](https://github.com/carbonfarm-os/carbonfarm-os/issues/33)) ([e15eac6](https://github.com/carbonfarm-os/carbonfarm-os/commit/e15eac648f307293b00355b7831857ab503a67d3))


### Sửa lỗi

* **platform:** healthcheck PostgreSQL kiểm qua TCP, tránh báo sẵn sàng khi initdb chưa xong ([#34](https://github.com/carbonfarm-os/carbonfarm-os/issues/34)) ([f891e81](https://github.com/carbonfarm-os/carbonfarm-os/commit/f891e813c3b004fd93c62a6a72a9acc44998acc3))


### Tài liệu

* **methodology:** đặc tả v0.1 rừng ngập mặn IPCC Tier 1, tham số máy đọc ([#24](https://github.com/carbonfarm-os/carbonfarm-os/issues/24)) ([#30](https://github.com/carbonfarm-os/carbonfarm-os/issues/30)) ([c22dfc2](https://github.com/carbonfarm-os/carbonfarm-os/commit/c22dfc257bbd5b78c47590a2596d769ca34c3e25))

## 0.1.0 (2026-10-29)


### Tính năng mới

* **carbon:** web SvelteKit + MapLibre, đăng nhập Keycloak PKCE, gọi API nền tảng qua gateway ([#11](https://github.com/carbonfarm-os/carbonfarm-os/issues/11)) ([#20](https://github.com/carbonfarm-os/carbonfarm-os/issues/20)) ([6c4f3c0](https://github.com/carbonfarm-os/carbonfarm-os/commit/6c4f3c0923c69c6107b2147fe4cd450b42f2de42))
* **platform:** Keycloak realm dxos có OTP cho quản trị, APISIX kiểm JWT, OpenBao giữ mật khẩu dịch vụ ([#6](https://github.com/carbonfarm-os/carbonfarm-os/issues/6)) ([#15](https://github.com/carbonfarm-os/carbonfarm-os/issues/15)) ([0e0452d](https://github.com/carbonfarm-os/carbonfarm-os/commit/0e0452d947de186014aaec73e56ed18192eff010))
* **platform:** lưu trữ ảnh vệ tinh – Versity S3, danh mục STAC (pgSTAC + stac-fastapi), tile TiTiler ([#8](https://github.com/carbonfarm-os/carbonfarm-os/issues/8)) ([#17](https://github.com/carbonfarm-os/carbonfarm-os/issues/17)) ([06dcf7d](https://github.com/carbonfarm-os/carbonfarm-os/commit/06dcf7d611610e51a9fbb62a50c5cb3cd78a3aa3))
* **platform:** PostGraphile v5 qua /graphql, vai từ JWT, quyền bằng RLS trên bảng mẫu tổng quát ([#7](https://github.com/carbonfarm-os/carbonfarm-os/issues/7)) ([#16](https://github.com/carbonfarm-os/carbonfarm-os/issues/16)) ([4be454d](https://github.com/carbonfarm-os/carbonfarm-os/commit/4be454d5e6672a945b9714866cda86c6a29c3984))
* **platform:** Prefect workflow engine qua /workflow, flow mẫu có bước chờ người duyệt ([#9](https://github.com/carbonfarm-os/carbonfarm-os/issues/9)) ([#18](https://github.com/carbonfarm-os/carbonfarm-os/issues/18)) ([58059bd](https://github.com/carbonfarm-os/carbonfarm-os/commit/58059bd42a87a32f889399b2cff24aad607fb1b6))
* **platform:** sổ cái có phiên bản Dolt và event bus Valkey, ADR 0003 ([#10](https://github.com/carbonfarm-os/carbonfarm-os/issues/10)) ([#19](https://github.com/carbonfarm-os/carbonfarm-os/issues/19)) ([477e32f](https://github.com/carbonfarm-os/carbonfarm-os/commit/477e32f44454f1322d6021230cf05fcd655b6540))


### Sửa lỗi

* **build:** đặt lệnh echo của task check trong ngoặc để Taskfile hợp lệ ([#1](https://github.com/carbonfarm-os/carbonfarm-os/issues/1)) ([407fc15](https://github.com/carbonfarm-os/carbonfarm-os/commit/407fc153bbd4db8bf27140f26daeca7ebca8f980))


### Tài liệu

* **adr:** 0002 stack và giấy phép từng thành phần; README trỏ repo và kế hoạch sprint ([#12](https://github.com/carbonfarm-os/carbonfarm-os/issues/12)) ([#21](https://github.com/carbonfarm-os/carbonfarm-os/issues/21)) ([cd13f6e](https://github.com/carbonfarm-os/carbonfarm-os/commit/cd13f6eda4d5f0bba516597d431350115f863c7f))
* **readme:** banner và logo của dự án ([#2](https://github.com/carbonfarm-os/carbonfarm-os/issues/2)) ([f0a837f](https://github.com/carbonfarm-os/carbonfarm-os/commit/f0a837ff2711cd7107d74f8f9355722276ea883e))


### Hạ tầng và CI

* **release:** bản phát hành đầu tiên là 0.1.0, không phải 1.0.0 ([#4](https://github.com/carbonfarm-os/carbonfarm-os/issues/4)) ([9319862](https://github.com/carbonfarm-os/carbonfarm-os/commit/931986215ef349fdc5a804feb88831898182557d))

<!-- SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors -->
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->
## Changelog

Tệp này do **release-please** viết từ Conventional Commits trên `main`; không sửa tay. Phiên bản theo [SemVer](https://semver.org/lang/vi/).
