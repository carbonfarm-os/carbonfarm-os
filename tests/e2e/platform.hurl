# SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors
# SPDX-License-Identifier: GPL-3.0-or-later
# Smoke Tầng 1 qua gateway. Mỗi khối là một request và các kiểm tra; thêm khối khi dựng thêm dịch vụ.
GET {{gateway}}/auth/realms/master/.well-known/openid-configuration
HTTP 200
[Asserts]
jsonpath "$.issuer" contains "/auth/realms/master"
