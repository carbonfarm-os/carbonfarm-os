# Changelog

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
