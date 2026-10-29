# SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors
# SPDX-License-Identifier: GPL-3.0-or-later
# Web Tầng 2 (SvelteKit + adapter-node). Build từ mã nguồn, image chạy chỉ chứa bản build.
FROM node:22.23.4-alpine3.24 AS build
WORKDIR /w
COPY package.json package-lock.json ./
RUN npm ci --no-audit --no-fund
COPY . .
RUN npm run build && npm prune --omit=dev

FROM node:22.23.4-alpine3.24
WORKDIR /app
COPY --from=build /w/build ./build
COPY --from=build /w/package.json ./
USER node
ENV PORT=3000 HOST=0.0.0.0
EXPOSE 3000
CMD ["node", "build"]
