<!-- SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors -->
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->
# Hướng dẫn dùng thử

Tài liệu cho người được mời thử CarbonFarm OS (cán bộ hợp tác xã, sinh viên) và cho thành viên đội đi mời. Mỗi người thử khoảng **30 phút**, làm lần lượt 6 nhiệm vụ dưới đây; mỗi điều chưa ổn hoặc muốn có ghi thành **một issue** bằng mẫu [Phản hồi dùng thử](https://github.com/carbonfarm-os/carbonfarm-os/issues/new?template=phan-hoi.yml).

Mọi hợp tác xã, xã viên, lô đất, người mua trong bản thử là **dữ liệu giả**. Registry, người mua, ngân hàng là dịch vụ mô phỏng; không có tiền hay tín chỉ thật nào được chuyển.

## Dành cho thành viên đội: chuẩn bị một buổi thử
1. Chạy hệ thống trên volume trống (hoặc dùng bản demo công khai khi #40 xong):
   ```bash
   cp .env.example .env
   task up             # .env.example bật NAP_DU_LIEU_MAU=true: nạp sẵn hợp tác xã, xã viên, lô đất giả
   task smoke          # kiểm hệ thống chạy đúng trước khi mời người thử
   ```
   Người thử tự tạo dữ liệu qua nhiệm vụ 3–5; muốn nhiệm vụ 1 có sẵn tín chỉ để tra thì thành viên làm trước một lượt nhiệm vụ 3–5.
2. Lấy mật khẩu người dùng mẫu (OpenBao sinh lúc dựng, mỗi máy một khác) bằng `docker compose exec keycloak cat /run/bimat/<tên>` và **đưa trực tiếp** cho người thử. Không ghi mật khẩu vào issue, tài liệu hay tin nhắn nhóm.
3. Người thử không có tài khoản GitHub: thành viên ghi phản hồi hộ bằng mẫu trên, ghi rõ "ghi hộ" và vai trò của người thử, không ghi họ tên thật.
4. Sau buổi thử: gắn người phụ trách cho từng issue `phan-hoi`; lỗi sửa trong sprint 4 (trước đóng băng 29/11/2026).

| Người dùng mẫu | Vai | Dùng cho |
|---|---|---|
| `canbo-htx-mau` | cán bộ hợp tác xã | nhiệm vụ 2–6 |
| `canbo-htx-mau-2` | cán bộ hợp tác xã thứ hai | duyệt lệnh bán do người kia tạo (nhiệm vụ 5) |
| `xavien-mau-1` | xã viên | xem lô của mình |

## Sáu nhiệm vụ
Địa chỉ dưới đây là máy chạy cục bộ; với bản demo công khai thay `http://localhost:9080` bằng tên miền của đội.

### 1. Xem trang chủ, tra một tín chỉ (không cần đăng nhập)
Mở http://localhost:9080/. Đọc trang chủ, rồi ở ô "Ai cũng tra được một tín chỉ" bấm **Tra cứu** khi để trống (thử với sê-ri mới nhất). Bấm "Xem từng bản ghi".
*Câu hỏi cho người thử:* bạn hiểu tín chỉ này thuộc về ai, đã qua những bước nào không?

### 2. Đăng nhập, tìm lô trên bản đồ
Bấm **Đăng nhập cán bộ**, đăng nhập bằng `canbo-htx-mau`. Tìm "Lô Đất Mũi 1" bằng ô tìm kiếm hoặc bấm lên bản đồ.
*Câu hỏi:* bạn có nhận ra lô trên ảnh vệ tinh không? Số liệu bên phải có dễ đọc không?

### 3. Vẽ và đăng ký lô mới
Bấm **+ Đăng ký lô mới**, đặt các góc lô trên vùng rừng, nhập tên và diện tích trên giấy tờ. Thử cả trường hợp sai: vẽ chồng lên lô có sẵn, hoặc khai diện tích lệch nhiều.
*Câu hỏi:* thông báo lỗi có cho bạn biết phải sửa gì không?

### 4. Yêu cầu đo, duyệt kết quả MRV
Chọn lô vừa đăng ký, chọn kỳ đo, bấm **Yêu cầu đo** (cần Internet để tải ảnh Sentinel-2; mất 1–2 phút). Khi trạng thái là "Chờ cán bộ duyệt", xem CO₂e, cảnh ảnh, lớp NDVI, rồi **Duyệt và ghi sổ** hoặc **Từ chối** kèm ghi chú.
*Câu hỏi:* bạn có đủ thông tin để tin con số CO₂e không?

### 5. Cấp tín chỉ, tạo và duyệt lệnh bán
Với kết quả đã ghi sổ, bấm **Đề nghị cấp … tín chỉ**. Ở ví tín chỉ, tạo lệnh bán cho một người mua. Đăng xuất, đăng nhập `canbo-htx-mau-2` để duyệt lệnh (người tạo không tự duyệt được – Thông tư 11/2026/TT-BNNMT).
*Câu hỏi:* quy trình hai người duyệt có rõ ràng không?

### 6. Xem dashboard hợp tác xã
Mở http://127.0.0.1:3001/ (Metabase, chỉ trên máy chạy hệ thống). Xem diện tích, CO₂e, tín chỉ, doanh thu.
*Câu hỏi:* cán bộ hợp tác xã cần thêm số liệu nào?

## Sau khi thử
Ghi một issue cho mỗi điều, kể cả điều bạn thấy dùng tốt. Đội trả lời trong issue và đóng khi đã sửa.
