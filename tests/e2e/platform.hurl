# SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors
# SPDX-License-Identifier: GPL-3.0-or-later
# Smoke Tầng 1 – SSO + gateway (#6). Chạy bằng `task smoke` (Hurl trong Docker, cùng mạng compose).

# Keycloak qua gateway: discovery của realm nền tảng
GET {{gateway}}/auth/realms/dxos/.well-known/openid-configuration
HTTP 200
[Asserts]
jsonpath "$.issuer" endsWith "/auth/realms/dxos"
jsonpath "$.code_challenge_methods_supported" contains "S256"

# Route có JWT: không token → 401
GET {{gateway}}/nen-tang/kiem-tra
HTTP 401

# Token sai chữ ký → 401
GET {{gateway}}/nen-tang/kiem-tra
Authorization: Bearer eyJhbGciOiJSUzI1NiJ9.eyJzdWIiOiJnaWEifQ.c2FpLWNodS1reQ
HTTP 401

# Lấy token bằng tài khoản dịch vụ kiem-thu (secret do OpenBao sinh)
POST {{gateway}}/auth/realms/dxos/protocol/openid-connect/token
[FormParams]
grant_type: client_credentials
client_id: kiem-thu
client_secret: {{kc_secret}}
HTTP 200
[Captures]
token: jsonpath "$.access_token"

# Token hợp lệ → qua gateway
GET {{gateway}}/nen-tang/kiem-tra
Authorization: Bearer {{token}}
HTTP 200
[Asserts]
jsonpath "$.realm" == "dxos"

# Luồng đăng nhập trình duyệt của realm dùng flow có OTP cho quản trị
GET {{gateway}}/auth/realms/dxos/protocol/openid-connect/auth?client_id=web&response_type=code&redirect_uri=http%3A%2F%2Flocalhost%3A9080%2F&code_challenge=E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM&code_challenge_method=S256&scope=openid
HTTP 200
[Asserts]
body contains "kc-form-login"
