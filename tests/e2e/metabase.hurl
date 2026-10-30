# SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors
# SPDX-License-Identifier: GPL-3.0-or-later
# Dashboard Metabase (#39): dựng sẵn từ volume trống, đọc dữ liệu thật qua view báo cáo, vai chỉ đọc không chạm bảng gốc.
# Gọi trong mạng nội bộ (UI chỉ mở ở 127.0.0.1). Chạy sau các tệp carbon-* để đã có kết quả đo và giao dịch.

GET {{metabase}}/api/health
HTTP 200

POST {{metabase}}/api/session
{"username":"quan-tri@carbonfarm.invalid","password":"{{bm_metabase_admin}}"}
HTTP 200
[Captures]
phien: jsonpath "$.id"

GET {{metabase}}/api/dashboard
X-Metabase-Session: {{phien}}
HTTP 200
[Captures]
db: jsonpath "$[?(@.name=='Hợp tác xã – tín chỉ carbon')].id" nth 0

GET {{metabase}}/api/dashboard/{{db}}
X-Metabase-Session: {{phien}}
HTTP 200
[Captures]
the_tin_chi: jsonpath "$.dashcards[?(@.card.name=='Tín chỉ: đã cấp, đã bán, trong ví')].card_id" nth 0
the_ket_qua: jsonpath "$.dashcards[?(@.card.name=='Kết quả đo MRV')].card_id" nth 0
ma_csdl: jsonpath "$.dashcards[0].card.database_id"
[Asserts]
jsonpath "$.dashcards" count == 7

# Thẻ chạy được trên dữ liệu thật
POST {{metabase}}/api/card/{{the_tin_chi}}/query
X-Metabase-Session: {{phien}}
HTTP 202
[Asserts]
jsonpath "$.status" == "completed"
jsonpath "$.data.rows" count >= 1
jsonpath "$.data.rows[0][1]" >= 1

POST {{metabase}}/api/card/{{the_ket_qua}}/query
X-Metabase-Session: {{phien}}
HTTP 202
[Asserts]
jsonpath "$.status" == "completed"
jsonpath "$.data.rows" count >= 1

# Vai carbon_bao_cao không đọc được bảng gốc (chỉ view báo cáo), không ghi được – Metabase trả 400 cho truy vấn lỗi
POST {{metabase}}/api/dataset
X-Metabase-Session: {{phien}}
{"database":{{ma_csdl}},"type":"native","native":{"query":"SELECT * FROM carbon.lo_dat"}}
HTTP 400
[Asserts]
jsonpath "$.status" == "failed"
jsonpath "$.error" contains "permission denied"

POST {{metabase}}/api/dataset
X-Metabase-Session: {{phien}}
{"database":{{ma_csdl}},"type":"native","native":{"query":"DELETE FROM carbon_bao_cao.tin_chi_htx"}}
HTTP 400
[Asserts]
jsonpath "$.status" == "failed"
