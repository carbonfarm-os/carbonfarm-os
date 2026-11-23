# Changelog

## [0.9.0](https://github.com/carbonfarm-os/carbonfarm-os/compare/v0.8.0...v0.9.0) (2026-11-23)


### Tính năng mới

* **carbon:** chuẩn hóa thông báo MRV, hồi phục ghi sổ Dolt và hoàn thiện bàn làm việc ([#111](https://github.com/carbonfarm-os/carbonfarm-os/issues/111)) ([#112](https://github.com/carbonfarm-os/carbonfarm-os/issues/112)) ([7d6c6dd](https://github.com/carbonfarm-os/carbonfarm-os/commit/7d6c6dd370c64f35c0aafceaed4e05f07a3da4fd))


### Tài liệu

* chuẩn hóa kiến trúc 2 tầng DX-OS và đồng bộ sổ tay HTX vào docs-site ([#117](https://github.com/carbonfarm-os/carbonfarm-os/issues/117)) ([8074460](https://github.com/carbonfarm-os/carbonfarm-os/commit/80744606f04b37c2a1dd03b31b4ebe59dd008706))
* **htx:** bổ sung bảng giải thích các trạng thái đợt thẩm tra MRV trên bàn làm việc ([#119](https://github.com/carbonfarm-os/carbonfarm-os/issues/119)) ([5d6c25d](https://github.com/carbonfarm-os/carbonfarm-os/commit/5d6c25ddf895755e4325159424fe28eb2e2c5d9c))
* **htx:** bổ sung bước đối chiếu lịch sử thay đổi bảng khối tín chỉ và lệnh bán ([#119](https://github.com/carbonfarm-os/carbonfarm-os/issues/119)) ([1ec7288](https://github.com/carbonfarm-os/carbonfarm-os/commit/1ec7288a8ffc112beec856d33c839c2725ea7263))
* **htx:** bổ sung bước kiểm tra chữ ký SHA-256 của tệp tham số phương pháp IPCC ([#119](https://github.com/carbonfarm-os/carbonfarm-os/issues/119)) ([744e853](https://github.com/carbonfarm-os/carbonfarm-os/commit/744e8532710a1a758c3c9e9eaa0ac9f21fcacddc))
* **htx:** bổ sung hướng dẫn đối soát độc lập bằng mã băm commit Dolt ([#119](https://github.com/carbonfarm-os/carbonfarm-os/issues/119)) ([83de8fa](https://github.com/carbonfarm-os/carbonfarm-os/commit/83de8fab39485811893a0cb61eb8614985d60fcf))
* **htx:** bổ sung hướng dẫn kiểm tra cảnh báo mất tán và chạm trần sinh khối ([#119](https://github.com/carbonfarm-os/carbonfarm-os/issues/119)) ([7905aaf](https://github.com/carbonfarm-os/carbonfarm-os/commit/7905aafb2502cb33aebdc3c061373a432604675c))
* **htx:** bổ sung quy tắc phân bổ doanh thu cho xã viên theo diện tích nhận khoán ([#119](https://github.com/carbonfarm-os/carbonfarm-os/issues/119)) ([55de428](https://github.com/carbonfarm-os/carbonfarm-os/commit/55de428a1e5cf480ad33b2d5ab8d2ee004758aa2))
* **htx:** bổ sung quy trình xuất bảng kê chi trả cho xã viên tại hợp tác xã ([#119](https://github.com/carbonfarm-os/carbonfarm-os/issues/119)) ([6c5895a](https://github.com/carbonfarm-os/carbonfarm-os/commit/6c5895a1e5bc66993fa7cb2b5a4049629112efdf))
* **htx:** bổ sung trạng thái đã chuyển nhượng và đã thu hồi của tín chỉ ([#119](https://github.com/carbonfarm-os/carbonfarm-os/issues/119)) ([6591729](https://github.com/carbonfarm-os/carbonfarm-os/commit/65917297b9101a9980c1cbd726e7e9da3dbdbe23))
* **htx:** bổ sung trạng thái đã duyệt và không đủ ảnh trong bảng thẩm tra MRV ([#119](https://github.com/carbonfarm-os/carbonfarm-os/issues/119)) ([4edc402](https://github.com/carbonfarm-os/carbonfarm-os/commit/4edc40206aabdb1df2191aaf7ca865717a399819))
* **htx:** bổ sung vòng đời trạng thái khối tín chỉ trên sổ cái Dolt ([#119](https://github.com/carbonfarm-os/carbonfarm-os/issues/119)) ([a59f148](https://github.com/carbonfarm-os/carbonfarm-os/commit/a59f148431876335e4ae802d61385fbe37244f82))
* **phuong-phap:** bổ sung bảng đối chiếu mã cảnh báo tự động trong động cơ MRV ([#120](https://github.com/carbonfarm-os/carbonfarm-os/issues/120)) ([929adf2](https://github.com/carbonfarm-os/carbonfarm-os/commit/929adf2d47de4db2daf58503c163fe05d5ba7be6))
* **phuong-phap:** bổ sung giải thích chuẩn hóa JSON tất định trước khi băm SHA-256 ([#120](https://github.com/carbonfarm-os/carbonfarm-os/issues/120)) ([75be4f6](https://github.com/carbonfarm-os/carbonfarm-os/commit/75be4f60a2d9fe2296c7d82f07269409755903c6))
* **phuong-phap:** bổ sung mục kiểm soát sai số mép điểm ảnh 10 m trên lô nhỏ ([#120](https://github.com/carbonfarm-os/carbonfarm-os/issues/120)) ([5f0ea9f](https://github.com/carbonfarm-os/carbonfarm-os/commit/5f0ea9f6e36defb5c0f876a8e79d35eb1a085936))
* **phuong-phap:** bổ sung quy tắc cắt trần diện tích tán theo diện tích địa chính PostGIS ([#120](https://github.com/carbonfarm-os/carbonfarm-os/issues/120)) ([9dc0367](https://github.com/carbonfarm-os/carbonfarm-os/commit/9dc0367b8bb54d9a56b0689f99739ca3be4ad1a2))
* **phuong-phap:** bổ sung quy tắc khử sai biệt kiểu số thực và thứ tự khóa trong phả hệ ([#120](https://github.com/carbonfarm-os/carbonfarm-os/issues/120)) ([08c6fb8](https://github.com/carbonfarm-os/carbonfarm-os/commit/08c6fb8daf301ac6e0023a568484a23ecb03832c))
* **phuong-phap:** hoàn thiện báo cáo giải trình phương pháp luận IPCC Tier 1 và dữ liệu viễn thám Sentinel-2 ([#118](https://github.com/carbonfarm-os/carbonfarm-os/issues/118)) ([a8a2def](https://github.com/carbonfarm-os/carbonfarm-os/commit/a8a2def4b260004ec0ee6dc09c44fca2bceb3a45))


### Kiểm thử

* **e2e:** kiểm tra diện tích tán rừng và lượng CO2e ước tính trên kết quả MRV ([#119](https://github.com/carbonfarm-os/carbonfarm-os/issues/119)) ([87c680d](https://github.com/carbonfarm-os/carbonfarm-os/commit/87c680d99d8abac174b6d90986941e0421963e63))
* **e2e:** kiểm tra đơn giá, thành tiền VNĐ và danh mục người mua trên lệnh bán ([#119](https://github.com/carbonfarm-os/carbonfarm-os/issues/119)) ([705f6bc](https://github.com/carbonfarm-os/carbonfarm-os/commit/705f6bc3c8d11aa2b2d596289bcddc3be9c35c05))
* **e2e:** kiểm tra số lượng tín chỉ và mã hợp tác xã trong khối tín chỉ phát hành ([#119](https://github.com/carbonfarm-os/carbonfarm-os/issues/119)) ([a5ce633](https://github.com/carbonfarm-os/carbonfarm-os/commit/a5ce6333b3e7dc629188e0f23413eb778d2c947f))
* **e2e:** kiểm tra thông tin tên và mã số thuế hợp tác xã trên bàn làm việc ([#119](https://github.com/carbonfarm-os/carbonfarm-os/issues/119)) ([b3220df](https://github.com/carbonfarm-os/carbonfarm-os/commit/b3220df1ddf44b804d75b8deca826b31dcc069bf))
* **e2e:** kiểm tra trường trạng thái và phương pháp luận của kết quả MRV ([#119](https://github.com/carbonfarm-os/carbonfarm-os/issues/119)) ([39f2f4e](https://github.com/carbonfarm-os/carbonfarm-os/commit/39f2f4e77d51c938289e26999ec32983ed986336))
* **mrv:** kiểm thử cắt trần diện tích tán khi vượt diện tích ranh giới lô nhỏ ([#120](https://github.com/carbonfarm-os/carbonfarm-os/issues/120)) ([d68c5ca](https://github.com/carbonfarm-os/carbonfarm-os/commit/d68c5ca3d6096d88b3381cc7376760f549585e92))
* **mrv:** kiểm thử cấu trúc từ điển hệ số trả về trong kết quả ước lượng ([#120](https://github.com/carbonfarm-os/carbonfarm-os/issues/120)) ([6c1df43](https://github.com/carbonfarm-os/carbonfarm-os/commit/6c1df43b0ee86d4bf02b878804821b1d99ab70e1))
* **mrv:** kiểm thử chuẩn hóa JSON bảo toàn giá trị boolean và None không biến thành số ([#120](https://github.com/carbonfarm-os/carbonfarm-os/issues/120)) ([5f7c6e0](https://github.com/carbonfarm-os/carbonfarm-os/commit/5f7c6e03b3604c047bd6741ec71b37f878fd39af))
* **mrv:** kiểm thử chuẩn hóa JSON giữ nguyên thứ tự mảng tọa độ GeoJSON ([#120](https://github.com/carbonfarm-os/carbonfarm-os/issues/120)) ([7131a2d](https://github.com/carbonfarm-os/carbonfarm-os/commit/7131a2dec7bf7b9852b9465dbe9277ec762128d3))
* **mrv:** kiểm thử chuẩn hóa JSON hỗ trợ tuple tương đương với list ([#120](https://github.com/carbonfarm-os/carbonfarm-os/issues/120)) ([20ef93d](https://github.com/carbonfarm-os/carbonfarm-os/commit/20ef93d347777ec0a078fa480080e111c6342823))
* **mrv:** kiểm thử chuẩn hóa JSON sắp xếp đệ quy các khóa trong dict lồng nhau ([#120](https://github.com/carbonfarm-os/carbonfarm-os/issues/120)) ([ed7fa90](https://github.com/carbonfarm-os/carbonfarm-os/commit/ed7fa900d758c58b75be1a0b95674d8b6c70d897))
* **mrv:** kiểm thử chuẩn hóa JSON xử lý số không âm -0.0 về số nguyên 0 ([#120](https://github.com/carbonfarm-os/carbonfarm-os/issues/120)) ([8aae0df](https://github.com/carbonfarm-os/carbonfarm-os/commit/8aae0dfc4a1ff6ebaa8c0f9e0b0c213b840badae))
* **mrv:** kiểm thử đồng thời cảnh báo mất tán và thiếu năm trồng trên cùng một lô ([#120](https://github.com/carbonfarm-os/carbonfarm-os/issues/120)) ([72390b5](https://github.com/carbonfarm-os/carbonfarm-os/commit/72390b5166802e55e678ca888d49f9f6a78be781))
* **mrv:** kiểm thử kỳ giám sát rơi vào năm nhuận 366 ngày ([#120](https://github.com/carbonfarm-os/carbonfarm-os/issues/120)) ([c223109](https://github.com/carbonfarm-os/carbonfarm-os/commit/c22310975a8186c69c0c59fc40ef62cda7faf6d0))
* **mrv:** kiểm thử làm tròn 4 chữ số thập phân cho diện tích và 3 chữ số cho carbon ([#120](https://github.com/carbonfarm-os/carbonfarm-os/issues/120)) ([c3cdf7f](https://github.com/carbonfarm-os/carbonfarm-os/commit/c3cdf7fed82f0b091ab3314d1e4a903face38f26))
* **web:** bổ sung kịch bản kiểm thử E2E và hướng dẫn vận hành bàn làm việc HTX ([#114](https://github.com/carbonfarm-os/carbonfarm-os/issues/114)) ([#116](https://github.com/carbonfarm-os/carbonfarm-os/issues/116)) ([51ef429](https://github.com/carbonfarm-os/carbonfarm-os/commit/51ef42913f5def46e8ee8ffefc2f5d1f1716b38d))

## [0.8.0](https://github.com/carbonfarm-os/carbonfarm-os/compare/v0.7.0...v0.8.0) (2026-11-13)


### Tính năng mới

* **di-dong:** app Flutter cho nông dân và hợp tác xã ([#102](https://github.com/carbonfarm-os/carbonfarm-os/issues/102)) ([fed74ba](https://github.com/carbonfarm-os/carbonfarm-os/commit/fed74baef0f1afbce7a5a67fe0c69ae5e0d109a9))
* **di-dong:** giao diện mới dùng forui, trang đăng nhập CarbonFarm và ảnh màn hình ([#110](https://github.com/carbonfarm-os/carbonfarm-os/issues/110)) ([da487dc](https://github.com/carbonfarm-os/carbonfarm-os/commit/da487dcb33d16b6e5875abb16a3fa68a7318aa3b))


### Tài liệu

* **demo:** thay kịch bản trình bày bằng hướng dẫn chạy demo ([#107](https://github.com/carbonfarm-os/carbonfarm-os/issues/107)) ([3c33aa8](https://github.com/carbonfarm-os/carbonfarm-os/commit/3c33aa8cb9f0aea7dfcc158c5558620b7a13dfa8))
* **readme:** viết lại README theo bố cục mới, thêm bản tiếng Anh ([#105](https://github.com/carbonfarm-os/carbonfarm-os/issues/105)) ([0ecc9b1](https://github.com/carbonfarm-os/carbonfarm-os/commit/0ecc9b140ab2992e205daa789e95e634e440ef10))

## [0.7.0](https://github.com/carbonfarm-os/carbonfarm-os/compare/v0.6.0...v0.7.0) (2026-11-12)


### Tính năng mới

* **web:** tiêu đề tab riêng cho trang chủ, bàn làm việc và trang hoàn tất đăng nhập ([#92](https://github.com/carbonfarm-os/carbonfarm-os/issues/92)) ([#96](https://github.com/carbonfarm-os/carbonfarm-os/issues/96)) ([07df93c](https://github.com/carbonfarm-os/carbonfarm-os/commit/07df93c120cdc65c980d7ea62970b1e4dc6c1550))


### Sửa lỗi

* **web:** trang đăng nhập Keycloak tiếng Việt, form đăng ký lô ghi đúng mã lỗi UC004 ([#83](https://github.com/carbonfarm-os/carbonfarm-os/issues/83)) ([#84](https://github.com/carbonfarm-os/carbonfarm-os/issues/84)) ([ee178e3](https://github.com/carbonfarm-os/carbonfarm-os/commit/ee178e3a28310064c085dcdd39aafc21f8e1bd0a))


### Tài liệu

* **methodology:** giải thích con số 15,85 t CO₂e của Lô Đất Mũi 2 trên bản demo ([#91](https://github.com/carbonfarm-os/carbonfarm-os/issues/91)) ([#95](https://github.com/carbonfarm-os/carbonfarm-os/issues/95)) ([06237ad](https://github.com/carbonfarm-os/carbonfarm-os/commit/06237ad1eb823fdf20b924f302af78248dd2e389))
* **readme:** bổ sung mục lục, tính năng theo vai, công nghệ, cấu trúc thư mục, thông tin đội ([#89](https://github.com/carbonfarm-os/carbonfarm-os/issues/89)) ([139738d](https://github.com/carbonfarm-os/carbonfarm-os/commit/139738d1dfd7565fa7c014528faa6e3c4139eb2c))
* **readme:** cập nhật theo v0.6.0 và thêm ảnh demo ([#87](https://github.com/carbonfarm-os/carbonfarm-os/issues/87)) ([31df104](https://github.com/carbonfarm-os/carbonfarm-os/commit/31df104b57d767fb2210d2d474334bc0ae0f69e2))
* **readme:** ghi bản mới nhất v0.7.0 ([#98](https://github.com/carbonfarm-os/carbonfarm-os/issues/98)) ([89d79d9](https://github.com/carbonfarm-os/carbonfarm-os/commit/89d79d94a30c7ed2ea107feb1db03d4629e8c80d))


### Kiểm thử

* **e2e:** Hurl kiểm trang đăng nhập tiếng Việt và cảnh báo UC004 ([#93](https://github.com/carbonfarm-os/carbonfarm-os/issues/93)) ([#97](https://github.com/carbonfarm-os/carbonfarm-os/issues/97)) ([4ee0717](https://github.com/carbonfarm-os/carbonfarm-os/commit/4ee07178c6879c5981db1550a887f4708858c8e8))
* **mrv:** thêm ca kiểm biên cho uoc_luong và doc_tham_so ([#90](https://github.com/carbonfarm-os/carbonfarm-os/issues/90)) ([#94](https://github.com/carbonfarm-os/carbonfarm-os/issues/94)) ([ed6b0c3](https://github.com/carbonfarm-os/carbonfarm-os/commit/ed6b0c397848361d7f17aad13ed53f1deb5356db))

## [0.6.0](https://github.com/carbonfarm-os/carbonfarm-os/compare/v0.5.1...v0.6.0) (2026-11-12)


### Tính năng mới

* **web:** làm mới giao diện web, chỉ hiện dữ liệu thật từ API và sổ cái ([#80](https://github.com/carbonfarm-os/carbonfarm-os/issues/80)) ([#81](https://github.com/carbonfarm-os/carbonfarm-os/issues/81)) ([016530b](https://github.com/carbonfarm-os/carbonfarm-os/commit/016530b02ffb169ecd896a72fa0984a2b6ffa202))

## [0.5.1](https://github.com/carbonfarm-os/carbonfarm-os/compare/v0.5.0...v0.5.1) (2026-11-11)


### Sửa lỗi

* **web:** màn hình cán bộ – ô ngày tràn thẻ, thiếu dấu cách, trạng thái tải, chọn lô trên điện thoại ([#75](https://github.com/carbonfarm-os/carbonfarm-os/issues/75)) ([#78](https://github.com/carbonfarm-os/carbonfarm-os/issues/78)) ([a0ea843](https://github.com/carbonfarm-os/carbonfarm-os/commit/a0ea8436658442c6cac6eeee47d926c778a9ef50))


### Tài liệu

* **readme:** đồng bộ README, hướng dẫn dùng thử, lộ trình với v0.5.0 và demo công khai ([#74](https://github.com/carbonfarm-os/carbonfarm-os/issues/74)) ([#77](https://github.com/carbonfarm-os/carbonfarm-os/issues/77)) ([102d173](https://github.com/carbonfarm-os/carbonfarm-os/commit/102d173be04342d5817dba95a505f334ea9a3a4e))
* **trien-khai:** hướng dẫn triển khai demo công khai sau reverse proxy HTTPS ([#40](https://github.com/carbonfarm-os/carbonfarm-os/issues/40)) ([#76](https://github.com/carbonfarm-os/carbonfarm-os/issues/76)) ([6d6a2bd](https://github.com/carbonfarm-os/carbonfarm-os/commit/6d6a2bda0381fb883668ae978f1006caa19cd9a8))

## [0.5.0](https://github.com/carbonfarm-os/carbonfarm-os/compare/v0.4.1...v0.5.0) (2026-11-03)


### Tính năng mới

* **platform:** PUBLIC_URL – địa chỉ công khai khi chạy sau reverse proxy HTTPS ([#40](https://github.com/carbonfarm-os/carbonfarm-os/issues/40)) ([#69](https://github.com/carbonfarm-os/carbonfarm-os/issues/69)) ([44747c2](https://github.com/carbonfarm-os/carbonfarm-os/commit/44747c26289964fb23b9e34db215c06e8a37db1f))


### Sửa lỗi

* **kiem-chung:** giới hạn tần suất theo IP thật của người dùng khi chạy sau Cloudflare ([#71](https://github.com/carbonfarm-os/carbonfarm-os/issues/71)) ([#72](https://github.com/carbonfarm-os/carbonfarm-os/issues/72)) ([90c9c34](https://github.com/carbonfarm-os/carbonfarm-os/commit/90c9c34dd2f9efaf83de872a12dc0722f160e371))


### Tài liệu

* **mien:** hướng dẫn viết miền cắm–rút và miền mẫu thủy sản ([#73](https://github.com/carbonfarm-os/carbonfarm-os/issues/73)) ([1fd921a](https://github.com/carbonfarm-os/carbonfarm-os/commit/1fd921a2f8bac6edf7cd888fa0fad5db662a65f3))

## [0.4.1](https://github.com/carbonfarm-os/carbonfarm-os/compare/v0.4.0...v0.4.1) (2026-11-02)


### Tài liệu

* **roadmap:** ghi tiến độ sprint 4 và v0.4.0; README trỏ v0.4.0; task seed mô tả đúng cách nạp dữ liệu giả ([#62](https://github.com/carbonfarm-os/carbonfarm-os/issues/62)) ([d53abab](https://github.com/carbonfarm-os/carbonfarm-os/commit/d53abab48927db7b31fa798fd9ce9af13fbf316e))
* **site:** trang tài liệu Starlight, nội dung chép từ docs/, methodology/, README ([#53](https://github.com/carbonfarm-os/carbonfarm-os/issues/53)) ([#67](https://github.com/carbonfarm-os/carbonfarm-os/issues/67)) ([51a54e3](https://github.com/carbonfarm-os/carbonfarm-os/commit/51a54e38f84489e63e23b6a4b7bfd1d82fa5f0a7))


### Kiểm thử

* **mrv:** kiểm thử dang_ky_stac trên STAC giả lập, gồm ca 409 khi tạo bộ sưu tập song song ([#64](https://github.com/carbonfarm-os/carbonfarm-os/issues/64)) ([#66](https://github.com/carbonfarm-os/carbonfarm-os/issues/66)) ([0fa2051](https://github.com/carbonfarm-os/carbonfarm-os/commit/0fa2051336f70873e9f86fbc3b4cdba8777fc481))


### Hạ tầng và CI

* **tai-lieu:** đăng trang tài liệu lên GitHub Pages khi main đổi tài liệu; README trỏ trang ([#68](https://github.com/carbonfarm-os/carbonfarm-os/issues/68)) ([abc19d8](https://github.com/carbonfarm-os/carbonfarm-os/commit/abc19d80939e1beff5a9e66f6a09708e93a3a88e))

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
