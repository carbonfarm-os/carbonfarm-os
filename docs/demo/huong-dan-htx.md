<!-- SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors -->
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->
# Sổ tay Hướng dẫn Vận hành Bàn làm việc Hợp tác xã (HTX)

Tài liệu này hướng dẫn cán bộ ban quản trị Hợp tác xã (HTX) vận hành Bàn làm việc MRV trên giao diện CarbonFarm OS: từ việc giám sát viễn thám, thẩm tra kết quả đo carbon, phê duyệt phát hành dải tín chỉ nội địa, đến việc tra cứu đối soát sổ cái Dolt và chia sẻ thông tin cho xã viên.

---

## 1. Truy cập Bàn làm việc HTX

1. Mở trình duyệt và truy cập Cổng CarbonFarm OS (mặc định máy chủ demo: `http://localhost:9080` hoặc tên miền triển khai).
2. Bấm nút **Đăng nhập** ở góc phải trên cùng màn hình.
3. Sử dụng tài khoản cán bộ HTX mẫu (`canbo-htx-mau` hoặc tài khoản được cấp quyền vai trò `can_bo_htx`).
4. Sau khi đăng nhập thành công, giao diện sẽ kích hoạt ba phân khu của **Bàn làm việc HTX** ở khung điều khiển chính.

---

## 2. Quy trình 3 bước trên Bàn làm việc

### Phân khu 1: Đợt thẩm tra mùa vụ (MRV Verification)
- **Mục đích:** Theo dõi chỉ số viễn thám thực tế từ vệ tinh Sentinel-2 (ESA) và số liệu cảm biến hiện trường nhằm thẩm định lượng giảm phát thải trước khi cấp tín chỉ.
- **Các thao tác chính:**
  1. Chọn lô đất cần thẩm tra trên bản đồ hoặc danh sách lô (ví dụ: *Lô Đất Mũi 2*).
  2. Bấm **Yêu cầu đo** cho kỳ mùa khô hoặc kỳ canh tác mong muốn.
  3. Quan sát các thông số hiển thị:
     - **Tỉ lệ mây che (`mayPhanTram`):** Phải dưới ngưỡng 20% để đảm bảo ảnh vệ tinh đạt độ tin cậy quang phổ.
     - **Chỉ số sinh khối NDVI & Diện tích tán rừng:** Đo đạc qua các băng sóng B4 (Red) và B8 (NIR).
     - **Lượng giảm phát thải ước tính (`co2ETan`):** Tính toán theo phương pháp luận IPCC Tier 1 cho rừng ngập mặn / canh tác lúa nước (AWD).
  4. Nếu thông số hợp lệ, bấm **Duyệt kết quả MRV** để chuyển trạng thái sang sẵn sàng cấp tín chỉ.

### Phân khu 2: Dải tín chỉ đã phát hành (Issuance & Registry)
- **Mục đích:** Quản lý hạn ngạch tín chỉ carbon đã được cấp theo đúng quy chuẩn mã số quốc gia.
- **Cấu trúc mã dải tín chỉ:**
  - Định dạng chuẩn: `MCK-DM01-26-0000000001` → `MCK-DM01-26-0000000015`
  - Trong đó:
    - `MCK`: Mã phương pháp luận (Mangrove Conservation & Kyoto compliant)
    - `DM01`: Mã định danh lô đất / hợp tác xã
    - `26`: Năm mùa vụ (2026)
    - Dãy số 10 chữ số: Số thứ tự từng tấn CO2e được niêm phong duy nhất.
- **Thao tác:** Bấm **Cấp tín chỉ** từ đợt MRV đã duyệt. Hệ thống sẽ tự động sinh dải sê-ri liên tục, ghi số dư vào ví HTX và đồng bộ lên Sổ cái Dolt.

### Phân khu 3: Nhật ký xác minh Dolt (Audit Log & Anti-Greenwashing)
- **Mục đích:** Đảm bảo tính minh bạch, bất biến và đối soát độc lập chống gian lận phát hành hai lần (double spending).
- **Đặc điểm kỹ thuật:**
  - Mỗi hành động (Đo đạc → Cấp tín chỉ → Khớp lệnh bán) đều tạo một commit băm 32 ký tự trên CSDL phân phiên bản Dolt.
  - Chuỗi SHA-256 bảo đảm toàn vẹn dữ liệu gốc không thể bị chỉnh sửa hay xóa bỏ trái phép.
  - Cán bộ và người mua có thể bấm vào mã commit để sao chép chuỗi kiểm chứng.

---

## 3. Hướng dẫn Xã viên tra cứu công khai

Xã viên và các đối tác mua tín chỉ không cần tài khoản đăng nhập vẫn có thể tra cứu toàn bộ bằng chứng pháp lý qua **Cổng kiểm chứng công khai** (`/kiem-chung`):
1. Truy cập đường dẫn `/kiem-chung`.
2. Nhập số sê-ri tín chỉ (ví dụ: `MCK-DM01-26-0000000217`) hoặc mã commit Dolt (32 ký tự).
3. Hệ thống trả về toàn bộ cây phả hệ: ngày chụp ảnh vệ tinh, tọa độ ranh giới lô đất, thông tin phương pháp IPCC, và bằng chứng mã hóa.
4. Thông tin cá nhân của xã viên được ẩn danh tự động theo chuẩn bảo vệ dữ liệu cá nhân (chỉ hiển thị mã xã viên).
