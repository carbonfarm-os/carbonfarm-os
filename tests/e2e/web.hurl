# SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors
# SPDX-License-Identifier: GPL-3.0-or-later
# Smoke web Tầng 2 (#11): trang SvelteKit qua gateway, và luồng đăng nhập Authorization Code + PKCE của client "web"
# như trình duyệt làm (form Keycloak → code → token), rồi gọi /graphql bằng token người dùng.
# Cặp verifier/challenge là ví dụ của RFC 7636 (chỉ dùng trong kiểm thử).

GET {{gateway}}/
HTTP 200
[Asserts]
header "Content-Type" contains "text/html"
body contains "<title>CarbonFarm OS</title>"

GET {{gateway}}/dang-nhap/xong
HTTP 200

GET {{gateway}}/auth/realms/dxos/protocol/openid-connect/auth?client_id=web&response_type=code&scope=openid&state=kiem-thu&redirect_uri=http%3A%2F%2Flocalhost%3A9080%2Fdang-nhap%2Fxong&code_challenge=E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM&code_challenge_method=S256
HTTP 200
[Captures]
action: xpath "string(//form[@id='kc-form-login']/@action)"

POST {{action}}
[FormParams]
username: nguoi-dung-mau
password: {{mk_nguoi_dung_mau}}
HTTP 302
[Asserts]
header "Location" startsWith "http://localhost:9080/dang-nhap/xong?"
[Captures]
code: header "Location" regex "[?&]code=([^&]+)"

# Sai verifier → từ chối (Keycloak hủy luôn code này: code chỉ dùng một lần)
POST {{gateway}}/auth/realms/dxos/protocol/openid-connect/token
[FormParams]
grant_type: authorization_code
client_id: web
code: {{code}}
redirect_uri: http://localhost:9080/dang-nhap/xong
code_verifier: sai-verifier-sai-verifier-sai-verifier-sai-verifier
HTTP 400

# Phiên đăng nhập còn (cookie) → xin code mới không cần nhập lại mật khẩu
GET {{gateway}}/auth/realms/dxos/protocol/openid-connect/auth?client_id=web&response_type=code&scope=openid&state=kiem-thu-2&redirect_uri=http%3A%2F%2Flocalhost%3A9080%2Fdang-nhap%2Fxong&code_challenge=E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM&code_challenge_method=S256
HTTP 302
[Captures]
code2: header "Location" regex "[?&]code=([^&]+)"

POST {{gateway}}/auth/realms/dxos/protocol/openid-connect/token
[FormParams]
grant_type: authorization_code
client_id: web
code: {{code2}}
redirect_uri: http://localhost:9080/dang-nhap/xong
code_verifier: dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk
HTTP 200
[Captures]
tk: jsonpath "$.access_token"
[Asserts]
jsonpath "$.token_type" == "Bearer"
jsonpath "$.id_token" exists

POST {{gateway}}/graphql
Authorization: Bearer {{tk}}
Content-Type: application/json
{"query":"{ allGhiChuMaus { totalCount } }"}
HTTP 200
[Asserts]
jsonpath "$.errors" not exists
jsonpath "$.data.allGhiChuMaus.totalCount" == 0
