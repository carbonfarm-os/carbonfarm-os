# SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors
# SPDX-License-Identifier: GPL-3.0-or-later
# OpenBao chạy thật (không -dev): lưu bằng raft (integrated storage) trong volume, UI quản trị chỉ mở 127.0.0.1.
storage "raft" {
  path    = "/openbao/file"
  node_id = "bao-1"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = 1
}

api_addr      = "http://openbao:8200"
cluster_addr  = "http://openbao:8201"
disable_mlock = true
ui            = true
