// SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// PostGraphile v5 – API GraphQL tự sinh cho dữ liệu có cấu trúc của Tầng 1.
// Mỗi request: kiểm lại JWT bằng JWKS của Keycloak (gateway đã kiểm, đây là lớp thứ hai), đổi vai realm thành role
// PostgreSQL và đặt jwt.claims.* để chính sách RLS trong CSDL quyết định ai thấy gì. Không có logic quyền ở đây.
import { createRemoteJWKSet, jwtVerify } from "jose";
import { makePgService } from "postgraphile/adaptors/pg";
import { PostGraphileAmberPreset } from "postgraphile/presets/amber";

const JWKS = createRemoteJWKSet(new URL(process.env.JWKS_URL));
const SCHEMAS = (process.env.GRAPHQL_SCHEMAS ?? "nen_tang").split(",");

/** Vai realm → role PostgreSQL (vai cao nhất thắng). Miền nghiệp vụ thêm vai bằng cách thêm role trong CSDL. */
function roleTuVai(vai) {
  if (vai.includes("quan_tri")) return "vai_quan_tri";
  if (vai.includes("nguoi_dung")) return "vai_nguoi_dung";
  return "vai_an_danh";
}

export default {
  extends: [PostGraphileAmberPreset],
  pgServices: [makePgService({ connectionString: process.env.DATABASE_URL, schemas: SCHEMAS })],
  grafserv: { port: 5678, host: "0.0.0.0", graphqlPath: "/graphql", graphiql: false, watch: false },
  grafast: {
    async context(requestContext) {
      const auth = requestContext.node?.req?.headers?.authorization ?? "";
      const m = /^Bearer (.+)$/i.exec(auth);
      if (!m) return { pgSettings: { role: "vai_an_danh" } };
      const { payload } = await jwtVerify(m[1], JWKS, { issuer: process.env.JWT_ISSUER });
      const vai = payload.realm_access?.roles ?? [];
      return {
        pgSettings: {
          role: roleTuVai(vai),
          "jwt.claims.sub": String(payload.sub ?? ""),
          "jwt.claims.vai": vai.join(","),
        },
      };
    },
  },
};
