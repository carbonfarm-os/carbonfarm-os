-- SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors
-- SPDX-License-Identifier: GPL-3.0-or-later
-- Sổ cái tổng quát của Tầng 1 (Dolt): mỗi bản ghi là một sự kiện cần niêm phong (loại + đối tượng + dữ liệu + SHA-256).
-- Mỗi lần ghi gọi DOLT_COMMIT → commit có mã băm nội dung; lịch sử (dolt_log, dolt_diff) là bằng chứng kiểm chứng.
-- Miền nghiệp vụ quyết định ghi gì (ví dụ kết quả MRV, cấp tín chỉ); Tầng 1 không biết nghiệp vụ.
CREATE DATABASE IF NOT EXISTS so_cai;
USE so_cai;
CREATE TABLE IF NOT EXISTS ban_ghi (
  id            BIGINT PRIMARY KEY AUTO_INCREMENT,
  loai          VARCHAR(64)  NOT NULL,
  ma_doi_tuong  VARCHAR(128) NOT NULL,
  du_lieu       JSON         NOT NULL,
  sha256        CHAR(64)     NOT NULL,
  tao_luc       DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
);
CALL DOLT_COMMIT('-Am', 'Khởi tạo sổ cái');
