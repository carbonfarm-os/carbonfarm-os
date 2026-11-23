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

### Bảng trạng thái đợt thẩm tra MRV

| Mã trạng thái | Ý nghĩa trên Bàn làm việc HTX | Hành động tiếp theo |
|---|---|---|
| `cho_do` | Yêu cầu đo mới tạo, đang chờ luồng Prefect cắt ảnh Sentinel-2 | Chờ worker MRV hoàn tất tính toán NDVI |
| `cho_duyet` | Đã có kết quả diện tích tán và ước lượng $\text{CO}_2\text{e}$ | Cán bộ thẩm định đối chiếu bản đồ và bấm duyệt |
| `da_duyet` | Kết quả MRV đã được phê duyệt và ghi phả hệ | Sẵn sàng lập đề nghị cấp dải tín chỉ |
| `khong_du_anh` | Ảnh vệ tinh trong kỳ bị mây che phủ trên 20% diện tích lô | Chọn lại kỳ mùa khô ít mây (ví dụ tháng 01–04) |
| `tu_choi` | Đợt đo bị từ chối do phát hiện suy thoái tán hoặc sai lệch ranh giới | Kiểm tra thực địa tại lô rừng ngập mặn |

### Xử lý cờ cảnh báo tự động trên kết quả MRV

- **`mat_tan`:** Xuất hiện khi diện tích tán rừng kỳ này giảm quá 10% so với kỳ liền trước; cán bộ HTX cần kiểm tra lớp ảnh phân loại cảnh SCL trên bản đồ để phân biệt mất rừng thật với hiện tượng triều cường ngập tán thấp.
- **`cham_tran_sinh_khoi`:** Xuất hiện khi rừng đạt ngưỡng sinh khối ổn định $B_{\max} = 187\text{ t d.m./ha}$ (khoảng 19,9 năm tuổi); hệ thống chỉ ghi nhận phần tăng trưởng tới trần.

---

## 4. Vòng đời khối tín chỉ và đối soát giao dịch

Mỗi dải tín chỉ sau khi phát hành trên sổ cái Dolt đi qua các trạng thái được kiểm soát chặt chẽ để không xảy ra bán trùng:

- **`dang_giu`:** Khối tín chỉ đang thuộc sở hữu của Hợp tác xã, sẵn sàng niêm yết hoặc khớp lệnh chuyển nhượng.
- **`da_chuyen`:** Khối tín chỉ đã được chuyển giao cho bên mua thông qua hợp đồng chuyển nhượng và thanh toán ngân hàng.
- **`da_thu_hoi` (Retired):** Tín chỉ đã được bên mua sử dụng để bù đắp phát thải (offset) và khóa vĩnh viễn trên sổ cái, không thể mua bán lại.

---

## 5. Phân bổ doanh thu tín chỉ carbon cho xã viên

Khi lệnh bán tín chỉ hoàn tất thanh toán qua cổng kết nối ngân hàng (`connectors/bank`):

1. Hệ thống tổng hợp diện tích rừng ngập mặn hợp lệ của từng hộ xã viên đã góp vào đợt thẩm tra MRV.
2. Tỷ lệ phân bổ của mỗi hộ được tính minh bạch theo công thức: $T_i = A_i / \sum A_k$.
3. Ban quản trị HTX đối chiếu bảng kê phân bổ trên Bàn làm việc, xác nhận số tiền chi trả (VNĐ) ứng với từng mã xã viên và lưu mã giao dịch ngân hàng vào nhật ký kiểm toán.

---

## 6. Quy trình kiểm toán độc lập trên sổ cái Dolt

Đơn vị thẩm định độc lập (VVBs) có thể kiểm tra toàn bộ lịch sử biến động của từng dải tín chỉ qua ba bước:

1. Lấy mã `dolt_commit` (32 ký tự chữ thường và số base32) trên trang `/kiem-chung` hoặc từ chứng nhận PDF của HTX.
