# SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors
# SPDX-License-Identifier: GPL-3.0-or-later
# Smoke workflow engine (#9): Prefect qua gateway /workflow. Flow mẫu xu-ly-co-duyet: chạy → PAUSED chờ duyệt →
# người duyệt resume → COMPLETED.

GET {{gateway}}/workflow/health
HTTP 401

POST {{gateway}}/auth/realms/dxos/protocol/openid-connect/token
[FormParams]
grant_type: client_credentials
client_id: kiem-thu-quan-tri
client_secret: {{kc_secret_qt}}
HTTP 200
[Captures]
tk: jsonpath "$.access_token"

# Deployment mẫu đã đăng ký (tiến trình prefect-chay-mau có thể cần vài giây sau khi khởi động)
GET {{gateway}}/workflow/deployments/name/xu-ly-co-duyet/mau
Authorization: Bearer {{tk}}
[Options]
retry: 30
retry-interval: 2000
HTTP 200
[Captures]
dep: jsonpath "$.id"

POST {{gateway}}/workflow/deployments/{{dep}}/create_flow_run
Authorization: Bearer {{tk}}
Content-Type: application/json
{"parameters": {"noi_dung": "kiem thu {{newUuid}}"}}
HTTP 201
[Captures]
run: jsonpath "$.id"

# Flow dừng chờ duyệt
GET {{gateway}}/workflow/flow_runs/{{run}}
Authorization: Bearer {{tk}}
[Options]
retry: 45
retry-interval: 2000
HTTP 200
[Asserts]
jsonpath "$.state.type" == "PAUSED"

# Người duyệt cho chạy tiếp
POST {{gateway}}/workflow/flow_runs/{{run}}/resume
Authorization: Bearer {{tk}}
Content-Type: application/json
{}
HTTP 201
[Asserts]
jsonpath "$.status" == "ACCEPT"

GET {{gateway}}/workflow/flow_runs/{{run}}
Authorization: Bearer {{tk}}
[Options]
retry: 45
retry-interval: 2000
HTTP 200
[Asserts]
jsonpath "$.state.type" == "COMPLETED"
