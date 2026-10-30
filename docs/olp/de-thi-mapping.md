<!-- SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors -->
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->
# Đối chiếu đề thi OLP PMNM 2026

Trạng thái: ☐ chưa làm · ◐ đang làm · ☑ xong (ghi đường dẫn làm bằng chứng). Cập nhật sau mỗi PR (lệnh `/update-mapping`).

## A. Yêu cầu bắt buộc
| # | Yêu cầu | Cách đáp ứng | Bằng chứng | Trạng thái |
|---|---|---|---|---|
| A1 | Lõi Tầng 1 headless, không UI cho người dùng cuối (UI quản trị được phép, BTC #1393) | `platform/`: chỉ API, không nghiệp vụ carbon | `platform/README.md`, `compose/platform.yaml` | ◐ |
| A2 | Identity / SSO | Keycloak, realm tổng quát `dxos`, OTP bắt buộc với vai `quan_tri` (luồng đăng nhập riêng) | `platform/keycloak/realm-dxos.json`, `tests/e2e/platform.hurl` (#6) | ☑ |
| A3 | API Gateway | APISIX standalone, kiểm JWT bằng JWKS của Keycloak (`plugin_configs.kiem-jwt`) | `platform/apisix/apisix.yaml`, smoke 401/200 (#6) | ☑ |
| A4 | Dữ liệu có cấu trúc | PostgreSQL 17 + PostGIS; PostGraphile v5 tự sinh GraphQL, vai realm → role PostgreSQL, quyền bằng RLS (bảng mẫu `nen_tang.ghi_chu_mau`) | `platform/postgraphile/`, `platform/postgres/110_postgraphile.sh`, `tests/e2e/graphql.hurl` (#7) | ☑ |
| A5 | Dữ liệu phi cấu trúc | Versity S3 (nội bộ) + danh mục STAC (pgSTAC + stac-fastapi, Transactions) + TiTiler tile COG | `compose/platform.yaml`, `tests/e2e/luu-tru.hurl` (#8) | ☑ |
| A6 | Workflow engine | Prefect 3.9 (CSDL PostgreSQL), API qua gateway `/workflow`; flow mẫu tổng quát xử lý → PAUSED chờ duyệt → resume → COMPLETED | `platform/prefect/flows/xu_ly_co_duyet.py`, `tests/e2e/workflow.hurl` (#9) | ☑ |
| A7 | ≥1 ứng dụng Tầng 2 có giao diện theo H-P-D-I, chỉ gọi lõi qua gateway | `domains/carbon/` – trọng tâm [P] + [D]. Đã có: web SvelteKit + MapLibre, đăng nhập PKCE, gọi `/graphql` qua gateway; route của miền khai riêng (`domains/carbon/gateway/routes.yaml`) | `domains/carbon/web/`, `tests/e2e/web.hurl` (#11) | ◐ |
| A8 | Tầng 1 độc lập nghiệp vụ (BTC #1396, #1423) | Ranh giới ở `docs/architecture.md` §1; `/pof-check` dò từ khóa nghiệp vụ trong `platform/` | | ◐ |

## B. H-P-D-I (Tầng 2)
| Không gian | Nội dung | Trạng thái |
|---|---|---|
| [H] | Cổng nông dân / cán bộ hợp tác xã: xã viên, lô đất, hồ sơ MRV, ví tín chỉ. Đã có: mô hình dữ liệu hợp tác xã, cán bộ, xã viên, lô đất (PostGIS) + RLS theo người đăng nhập, dữ liệu giả (#22, `domains/carbon/db/`, `tests/e2e/carbon-rls.hurl`); web: bản đồ + danh sách lô, chi tiết lô với kết quả MRV, lớp NDVI từ TiTiler, phả hệ, cán bộ yêu cầu đo và duyệt/từ chối (#26, `domains/carbon/web/src/lib/ChiTietLo.svelte`) | ◐ |
| [P] | Đăng ký lô → MRV → duyệt → cấp tín chỉ → bán; Poka-yoke: ranh giới không chồng lấn, diện tích khớp bản đồ, không cấp hai lần cho cùng lô và kỳ. Đã có: cấp tín chỉ vào ví qua Registry mock – chỉ kết quả đã ghi sổ, mỗi kết quả một lần, làm tròn xuống (#36, `domains/carbon/db/migrations/004_tin_chi.sql`); đăng ký lô bằng vẽ ranh giới trên bản đồ; CSDL chặn hình sai, diện tích ngoài 0,05–500 ha, lệch khai báo >10 %, chồng lấn, sai quyền – mã lỗi UC00x, thông báo tiếng Việt hiện nguyên văn trên web (#23, `domains/carbon/db/migrations/002_dang_ky_lo.sql`, `tests/e2e/carbon-dang-ky-lo.hurl`) | ◐ |
| [D] | Bản đồ lô + ảnh vệ tinh, phả hệ dữ liệu MRV, sổ cái Dolt kiểm chứng được, dashboard Metabase. Đã có: sổ cái Dolt + event bus Valkey ở Tầng 1 (#10, ADR 0003); MRV trên Sentinel-2 thật – NDVI/tán theo lô, COG + item STAC, phả hệ đầy đủ (phương pháp + SHA-256 tham số, cảnh nguồn, số điểm ảnh, hệ số), cán bộ duyệt rồi ghi Dolt (#25, ADR 0005, `domains/carbon/mrv/`, `tests/e2e/carbon-mrv.hurl`, `tests/tich-hop/test_mrv_so_cai.py`) | ◐ |
| [I] | Để sau MVP (AI ước lượng, trợ lý giải thích); mọi đề xuất AI có người duyệt | ☐ |

## C. Sáu tiêu chí PoF (50 điểm)
| # | Tiêu chí | Cách đáp ứng | Trạng thái |
|---|---|---|---|
| 1 | Quản lý mã nguồn trên Internet | Repo GitHub công khai; commit đều của cả nhóm; PR có người duyệt (CODEOWNERS) | ☐ chưa đẩy lên GitHub |
| 2 | Giấy phép OSI | `LICENSE` GPL-3.0-or-later; SPDX mọi tệp (`task check`); `DEPENDENCIES.md`, `NOTICE`, SBOM mỗi Release; README nêu lý do chọn giấy phép | ◐ |
| 3 | Release `.tar.gz` trước hạn | release-please: tag + `.tar.gz` + `SHA256SUMS` + SBOM | ◐ (đã có workflow) |
| 4 | Build từ mã nguồn | `task up` từ máy sạch, `.env.example`, Dev Container | ◐ |
| 5 | Thư viện, gói đính kèm | Không vendor; pixi (conda-forge), npm/pnpm có lockfile | ◐ |
| 6 | Tài liệu, giao tiếp | README song ngữ, CHANGELOG (release-please), Issue Forms, CONTRIBUTING, CODE_OF_CONDUCT, ADR | ◐ |

## D. Cộng đồng
- [ ] Demo công khai trên Internet, người dùng thật (cán bộ hợp tác xã, sinh viên) thử, phản hồi thành issue.
- [ ] Bài giới thiệu (VFOSSA, diễn đàn); Discussions.
- [ ] Connector mock có hợp đồng OpenAPI để đối tác thật thay thế: Registry theo TT 11/2026/TT-BNNMT, Buyer, Bank (#35, `connectors/`, ADR 0006).
- [ ] Công bố đặc tả phương pháp MRV cho cộng đồng dùng lại. Đã có v0.1 (`methodology/v0.1-rung-ngap-man-ipcc-tier1.md`, #24), chưa giới thiệu ra ngoài.
