<!-- SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors -->
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->
# Kịch bản trình bày chung kết – 15 phút

BTC chấm phần sản phẩm (50 điểm) tại chung kết 10/12/2026 theo năm tiêu chí: nguyên gốc kỹ thuật, mức hoàn thiện (chạy demo), thân thiện người dùng, phát triển bền vững, phong cách trình diễn và thu hút cộng đồng. Bài 15 phút phải có đủ bốn ý BTC nêu: giải pháp thiết kế và lựa chọn công nghệ, tính năng nền tảng và bài toán minh họa, demo, định hướng phát triển.

**Nguyên tắc:** mỗi người nói phần mình đã làm và tự trả lời câu hỏi về phần đó. Số liệu nói trên sân khấu (CO₂e, số tín chỉ, số người thử, số issue) đọc từ hệ thống hoặc GitHub ngay trước giờ thi, không học thuộc.

## Phân vai
| Vai | Người | Nói | Thao tác demo |
|---|---|---|---|
| V1 – nền tảng | `Minhthuan12` | bài toán, kiến trúc hai tầng, Tầng 1, giấy phép và phát hành, định hướng | chuyển slide, mở sổ cái và GitHub |
| V2 – dữ liệu, MRV | `Nhvuu918` | phương pháp MRV, ảnh Sentinel-2, phả hệ, sổ cái Dolt | yêu cầu đo, giải thích kết quả, duyệt |
| V3 – web, dashboard, connector | `tamdoannguyen06-cmyk` | trải nghiệm cán bộ, Poka-yoke, connector theo Thông tư 11/2026, dashboard | vẽ lô, cấp và bán tín chỉ, dashboard |

## Dòng thời gian
| Phút | Phần | Người | Nội dung chính | Bằng chứng trên màn hình |
|---|---|---|---|---|
| 0:00–1:30 | Bài toán | V1 | Hợp tác xã rừng ngập mặn Cà Mau có rừng nhưng không có hồ sơ đo đạc đủ tin để bán tín chỉ; đo thủ công đắt, khó kiểm chứng. CarbonFarm OS số hoá hợp tác xã như một doanh nghiệp: lô đất → đo → duyệt → cấp → bán → ai cũng kiểm chứng. | Trang chủ, ảnh vệ tinh lô thật |
| 1:30–4:00 | Thiết kế, công nghệ | V1 | Tầng 1 headless tổng quát (Keycloak, APISIX, OpenBao, PostgreSQL + PostGIS + PostGraphile, S3 + STAC + TiTiler, Prefect, Valkey, Dolt) không chứa chữ "carbon"; Tầng 2 cắm vào bằng migration, route gateway, flow riêng. Chọn dữ liệu mở Copernicus + công cụ mở để tái lập được và giữ chủ quyền dữ liệu. GPL-3.0-or-later để mọi bản sửa MRV phải công khai. | `docs/architecture.md`, sơ đồ hai tầng, `DEPENDENCIES.md` |
| 4:00–5:30 | MRV | V2 | Sentinel-2 qua STAC, chọn cảnh ít mây, cắt theo lô, NDVI + lớp mây SCL, hệ số IPCC 2013 cận dưới (21,74 t CO₂e/ha/năm), trần sinh khối. Mỗi con số lưu phiên bản phương pháp, SHA-256 tham số, cảnh nguồn. | `methodology/`, phả hệ trong chi tiết lô |
| 5:30–11:30 | Demo luồng chính | V3 → V2 → V3 | (1) V3 đăng nhập cán bộ, vẽ lô chồng lấn → bị chặn, vẽ lại đúng → đăng ký. (2) V2 chọn lô đã đo sẵn, mở lớp NDVI, đọc CO₂e, duyệt và ghi sổ. (3) V3 đề nghị cấp tín chỉ → Registry mô phỏng cấp sê-ri; tạo lệnh bán, cán bộ thứ hai duyệt (Thông tư 11/2026 Điều 6 khoản 3). (4) V3 mở dashboard Metabase. | Web, bản đồ, Metabase |
| 11:30–12:30 | Kiểm chứng | V2 | Người ngoài không cần tài khoản: nhập sê-ri vừa bán → chuỗi đo → cấp → bán, SHA-256 tính lại khớp sổ cái Dolt. | `/kiem-chung` trên điện thoại |
| 12:30–14:00 | Hoàn thiện, cộng đồng | V1 | Số release, CI, SBOM; số người dùng thử và issue phản hồi thật; tài liệu, hướng dẫn dùng thử, connector có OpenAPI để Registry thật thay thế. | GitHub: Releases, Issues `phan-hoi`, Projects |
| 14:00–15:00 | Định hướng | V1 | Thêm hệ sinh thái (lúa giảm phát thải, nông lâm kết hợp) bằng phương pháp mới trong `methodology/`, không sửa lõi; [I] trợ lý giải thích kết quả MRV, luôn có người duyệt; nối Registry quốc gia khi có API. | Slide cuối, đường dẫn repo |

## Chuẩn bị trước giờ thi
- **Dữ liệu demo:** một lô đã đo và chờ duyệt, một lô đã ghi sổ, đã cấp và bán một phần – dựng trên volume trống rồi chạy luồng một lượt hôm trước. Không yêu cầu đo mới trên sân khấu (cần Internet, mất 1–2 phút); chỉ duyệt kết quả đã đo.
- **Tài khoản:** hai cán bộ đăng nhập sẵn ở hai cửa sổ trình duyệt riêng (một cửa sổ ẩn danh) để duyệt lệnh bán không phải đăng xuất.
- **Màn hình:** phóng chữ trình duyệt 125 %; tắt thông báo; mở sẵn các tab theo thứ tự demo.
- **Giờ chốt số liệu:** 30 phút trước khi lên, V1 đọc lại số release, số issue phản hồi, số người thử từ GitHub và sửa slide.

## Dự phòng
| Sự cố | Cách xử lý |
|---|---|
| Mất Internet | Chạy toàn bộ trên máy tính mang theo (`task up`); ảnh nền bản đồ là tệp tĩnh, không cần mạng; bỏ bước đo mới. |
| Máy demo hỏng | Máy thứ hai đã dựng sẵn cùng dữ liệu; hoặc chuyển sang video dự phòng. |
| Một bước lỗi giữa chừng | Nói ngắn lý do, chuyển sang video đoạn đó, đi tiếp phần sau; không gỡ lỗi trên sân khấu. |
| Quá giờ | Bỏ dashboard (11:00) và rút phần định hướng còn 30 giây. |

Video dự phòng: quay toàn bộ phần demo 6 phút, lưu trên máy demo và một USB; tên tệp ghi ngày và commit đã quay.

## Câu hỏi dự kiến
| Câu hỏi | Ai trả lời | Ý chính |
|---|---|---|
| NDVI có đo được carbon thật không? | V2 | NDVI chỉ đo diện tích tán; carbon tính bằng hệ số IPCC cận dưới cho rừng ngập mặn, có trần sinh khối. Đây là ước lượng Tier 1 thận trọng, ghi rõ phiên bản phương pháp; thay phương pháp chính xác hơn bằng tệp mới trong `methodology/`. |
| Vì sao sổ cái Dolt mà không phải blockchain? | V2 | Cần lịch sử có phiên bản, kiểm chứng bằng mã băm, truy vấn SQL, chạy được trên một máy; Dolt là Apache-2.0, không cần token hay mạng đồng thuận. ADR 0003. |
| Làm sao biết Tầng 1 không chứa nghiệp vụ? | V1 | Mọi bảng, vai, flow carbon nằm trong `domains/carbon/`; Tầng 1 chỉ có ví dụ tổng quát; tìm từ khoá nghiệp vụ (`carbon`, `tin_chi`, `lo_dat`) trong `platform/` chỉ ra các dòng chú thích ghi ranh giới, không ra bảng hay mã nghiệp vụ. Thêm miền mới không sửa `platform/`. |
| Có tránh tính trùng (double counting) không? | V3 | CSDL chặn lô chồng lấn, mỗi kết quả MRV chỉ cấp một lần, sê-ri do Registry cấp theo Thông tư 11/2026, chuyển quyền trừ ví và ghi sổ. |
| Mây che thì sao? | V2 | Chọn cảnh ít mây trong kỳ, bỏ điểm ảnh mây theo lớp SCL, cảnh báo khi phần lô bị che; cán bộ quyết định duyệt. |
| Vì sao GPL-3.0? | V1 | Ai sửa nền tảng MRV rồi phân phối phải công khai mã, để con số carbon luôn kiểm chứng được. |
| Registry thật thì sao? | V3 | Connector có hợp đồng OpenAPI; khi có API quốc gia chỉ thay dịch vụ mô phỏng, không sửa Tầng 2. ADR 0006. |
| AI ở đâu ([I])? | V1 | Cố ý để sau: H-P-D-I yêu cầu chuẩn hoá [P], [D] trước. Hướng tiếp: trợ lý giải thích kết quả MRV, đề xuất luôn qua người duyệt. |
| Người dùng thật đã thử chưa? | V1 | Nêu số người thử và issue `phan-hoi` thật trên GitHub; không phóng đại. |

## Tập
- Mỗi người tập riêng phần mình đến khi nói không cần đọc; tập chung ít nhất ba lần, bấm giờ.
- Một buổi hỏi vặn: người không trình bày phần đó đặt câu hỏi khó.
- Sau mỗi buổi tập, sửa tài liệu này nếu đổi thứ tự hoặc thời lượng.
