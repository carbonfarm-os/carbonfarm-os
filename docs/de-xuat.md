<!-- SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors -->
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->
# Đề xuất dự án (tóm tắt)

Tóm tắt từ bản đề xuất của nhóm "CarbonFarm OS – Bản báo cáo v2" (29/10/2026). Phần stack đã điều chỉnh sau khi xác minh giấy phép, xem mục 6.

## 1. Bài toán
- **Tín chỉ carbon** là chứng nhận cho 1 tấn CO₂e được giảm hoặc hấp thụ. Nông dân, chủ rừng, cộng đồng ven biển là "người sản xuất" tín chỉ khi trồng, bảo vệ rừng (nhất là rừng ngập mặn) hoặc canh tác bền vững.
- Muốn được cấp tín chỉ phải qua **MRV** (đo lường – báo cáo – xác minh). MRV số hóa cho nông dân nhỏ ở Việt Nam gần như chưa có ai làm bài bản. Đây là khoảng trống chính của đề tài.
- **Bối cảnh pháp lý theo bản đề xuất của nhóm:**
  - Registry quốc gia vận hành theo Nghị định 29/2026/NĐ-CP và Thông tư 11/2026/TT-BNNMT;
  - sàn carbon trong nước thí điểm từ 29/6/2026, giai đoạn thí điểm đến hết 2028 (Quyết định 232/QĐ-TTg), vận hành chính thức từ 2029.
  - Giai đoạn đầu giao dịch chủ yếu là hạn ngạch của doanh nghiệp lớn; tín chỉ nông, lâm nghiệp còn thiếu hạ tầng MRV.
  - Các số liệu và văn bản này do nhóm trích; cần dẫn nguồn chính thức trong tài liệu nộp.

## 2. Hệ thống làm gì
Chủ thể được số hóa là **hợp tác xã**: quản lý xã viên, lô đất, hồ sơ MRV, tín chỉ và doanh thu.

1. Nông dân hoặc cán bộ hợp tác xã đăng ký lô đất trên bản đồ.
2. Hệ thống lấy ảnh Sentinel-2 qua STAC, chạy ước lượng carbon.
3. Tổng hợp hồ sơ MRV, gửi duyệt.
4. Được duyệt thì cấp tín chỉ vào ví, qua Registry Connector.
5. Bán cho người mua, tiền về qua Bank Connector.

Mọi con số MRV truy vết được: cảnh ảnh nào, ngày chụp, tỷ lệ mây, phiên bản thuật toán, tham số, người duyệt.

**Đầu vào:**
- ảnh vệ tinh mở: Sentinel-2, sau này Landsat;
- dữ liệu nông dân nhập;
- dữ liệu khí hậu, đất: NASA POWER, SoilGrids CC-BY-4.0, để sau MVP.

**Đầu ra:**
- tín chỉ có mã trong ví;
- dashboard cho nông dân, hợp tác xã, cơ quan quản lý.

## 3. Vị thế
- Các nền tảng carbon nông nghiệp trên thế giới (Agreena, Nori, Indigo Ag) đều đóng nguồn, nhắm Mỹ/EU, không có tiếng Việt và rừng ngập mặn.
- Các dự án blue carbon (Mikoko Pamoja, Blue Forests) nhỏ lẻ, không có nền tảng số mở.
- **Khác biệt của CarbonFarm OS:**
  - mã nguồn mở;
  - tiếng Việt;
  - rừng ngập mặn và nông dân nhỏ;
  - Registry Connector theo quy định Việt Nam;
  - kiến trúc mock-first nên demo được mà chưa cần đối tác thật.

## 4. Khớp đề DX-OS Open-Core
- **Tầng 1 headless:** SSO, gateway, dữ liệu có cấu trúc và phi cấu trúc, workflow; không chứa nghiệp vụ carbon.
- **Tầng 2 theo H-P-D-I:** đề chỉ cần 1 không gian (BTC #1358). Đội tập trung **[P]** (quy trình đăng ký → MRV → duyệt → cấp → bán, có Poka-yoke: lô đất không chồng lấn, diện tích khớp bản đồ) và **[D]** (bản đồ, phả hệ dữ liệu MRV, sổ cái, dashboard).
- **[I]** (AI ước lượng, trợ lý RAG) để sau MVP. Mọi đề xuất của AI phải có cán bộ duyệt.
- **Hai nguyên lý kỹ thuật của đề:**
  - phả hệ và chất lượng dữ liệu (mỗi con số MRV có nguồn gốc);
  - lưu trữ chống sửa xóa (mỗi tín chỉ, giao dịch được ghi vào sổ cái có phiên bản).

## 5. Phạm vi MVP
- Một hệ sinh thái: rừng ngập mặn.
- Một khu vực mẫu.
- Dữ liệu hợp tác xã giả.
- Một phương pháp ước lượng đã công bố: chỉ số thực vật từ Sentinel-2 × hệ số quy đổi carbon, có trích dẫn, đặc tả trong `methodology/`.
- Registry, người mua, ngân hàng mô phỏng.
- Mục tiêu: chạy trọn luồng từ đăng ký lô đất đến kiểm chứng trên sổ cái.

## 6. Điều chỉnh so với bản đề xuất v2
| Bản v2 ghi | Đã kiểm | Điều chỉnh |
|---|---|---|
| immudb, Apache-2.0 | LICENSE hiện tại là **Business Source License** (bản 1.9 trở đi), không OSI | Dolt (Apache-2.0) |
| SeaweedFS, Flowable, NATS | Giấy phép ổn, nhưng trùng thành phần chính của hai đội cùng trường | Versity S3, Prefect, Valkey |
| Grafana + Prometheus | Trùng Team 1 | Metabase OSS cho dashboard; giám sát để sau |
| Ollama + Qdrant cho [I] | Ổn | Để sau MVP |
| Mã nhóm theo Apache-2.0 | — | Người hướng dẫn chọn **GPL-3.0-or-later** |
| Google Earth Engine "không dùng vì độc quyền" | BTC cho phép dịch vụ ngoài | Vẫn không dùng, nhưng ghi là **lựa chọn thiết kế** (chủ quyền dữ liệu, tái lập được) |
