# SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors
# SPDX-License-Identifier: GPL-3.0-or-later
# PostGraphile v5 cài từ npm theo package-lock.json (không vendor, không sửa mã PostGraphile).
FROM node:22.23.4-alpine3.24
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev && npm cache clean --force
COPY graphile.config.mjs ./
USER node
EXPOSE 5678
# Mật khẩu CSDL đọc từ tệp do OpenBao sinh (/run/bimat), không nằm trong biến môi trường của compose.
CMD ["sh", "-c", "export DATABASE_URL=\"postgres://postgraphile:$(cat /run/bimat/postgraphile-db)@postgres:5432/nen_tang\" && exec npx postgraphile -C graphile.config.mjs"]
