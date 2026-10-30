# SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors
# SPDX-License-Identifier: GPL-3.0-or-later
# Một image cho cả ba connector mock; KET_NOI=registry|buyer|bank chọn ứng dụng.
FROM python:3.12.12-slim-bookworm
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . ./connectors
# Thư mục dữ liệu thuộc user 1000: volume mới tạo kế thừa quyền này
RUN mkdir /du-lieu && chown 1000:1000 /du-lieu
ENV PYTHONUNBUFFERED=1
USER 1000
CMD ["sh", "-c", "exec uvicorn connectors.${KET_NOI}.app:app --host 0.0.0.0 --port 8000 --no-access-log"]
