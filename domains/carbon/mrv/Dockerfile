# SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors
# SPDX-License-Identifier: GPL-3.0-or-later
# MRV engine của miền carbon: flow Prefect + cầu nối CSDL ↔ Prefect. GDAL đi kèm wheel rasterio.
# Đọc COG qua Internet: giới hạn thời gian để mạng chập chờn thì hỏng nhanh, task tự thử lại (retries) thay vì treo vài phút.
FROM prefecthq/prefect:3.9.0-python3.12
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY mrv ./mrv
ENV PYTHONUNBUFFERED=1 \
    GDAL_DISABLE_READDIR_ON_OPEN=EMPTY_DIR \
    GDAL_HTTP_MAX_RETRY=3 \
    GDAL_HTTP_RETRY_DELAY=2 \
    GDAL_HTTP_CONNECTTIMEOUT=10 \
    GDAL_HTTP_TIMEOUT=30 \
    CPL_VSIL_CURL_ALLOWED_EXTENSIONS=.tif
CMD ["python", "-m", "mrv.cau_noi"]
