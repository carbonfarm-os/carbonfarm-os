<!-- SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors -->
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->
<!--
	Chi tiết một lô: kết quả MRV + phả hệ, xem lớp NDVI trên bản đồ; cán bộ yêu cầu đo và duyệt/từ chối.
	Quyền và luật nằm trong CSDL (UC010–UC015); ở đây chỉ hiện nút cho đúng người và hiện nguyên văn lỗi tiếng Việt.
-->
<script lang="ts">
	import { onDestroy } from 'svelte';
	import type { Token } from './dang-nhap.ts';
	import { goiGraphql, LoiNghiepVu } from './graphql.ts';

	type CapTinChi = {
		trangThai: string;
		soLuong: number;
		maTrongNuoc: string | null;
		seriTu: string | null;
		seriDen: string | null;
		doltCommit: string | null;
		lyDoLoi: string | null;
	};
	type KetQua = {
		rowId: string;
		kyTu: string;
		kyDen: string;
		trangThai: string;
		canhId: string | null;
		ngayChup: string | null;
		mayPhanTram: string | null;
		soDiemAnhLo: number | null;
		soDiemAnhHopLe: number | null;
		soDiemAnhTan: number | null;
		dienTichTanHa: string | null;
		co2ETan: string | null;
		canhBao: string[];
		phuongPhap: string | null;
		cogHref: string | null;
		lyDoLoi: string | null;
		ghiChuDuyet: string | null;
		duyetLuc: string | null;
		doltCommit: string | null;
		phaHe: Record<string, unknown> | null;
		carbonDeNghiCapByKetQuaMrvId: CapTinChi | null;
	};
	type Lo = { rowId: string; ten: string; dienTichHa: string; namTrong: number | null };

	let {
		token,
		lo,
		laCanBo,
		lopDangXem,
		onXemLop,
		onThayDoi,
		onDong
	}: {
		token: Token;
		lo: Lo;
		laCanBo: boolean;
		lopDangXem: string | null;
		onXemLop: (cog: string | null) => void;
		onThayDoi: () => void;
		onDong: () => void;
	} = $props();

	const TRANG_THAI: Record<string, string> = {
		cho_chay: 'Đang xếp hàng',
		dang_chay: 'Đang đo',
		cho_duyet: 'Chờ cán bộ duyệt',
		da_duyet: 'Đã duyệt, đang ghi sổ',
		tu_choi: 'Bị từ chối',
		da_ghi_so: 'Đã ghi sổ cái',
		loi: 'Lỗi'
	};
	const CANH_BAO: Record<string, string> = {
		mat_tan: 'Tán giảm quá 10 % so với kỳ trước – cần xem kỹ',
		thieu_nam_trong: 'Lô chưa khai năm trồng – không tính được, duyệt thủ công',
		cham_tran_sinh_khoi: 'Đã chạm trần sinh khối – chỉ tính phần tới trần',
		thieu_diem_anh_hop_le: 'Một phần lô bị mây/bóng mây che'
	};
	const NHAN: Record<string, string> = { cho_duyet: 'cho', da_ghi_so: 'tot', tu_choi: 'xau', loi: 'xau' };
	const DANG_XU_LY = ['cho_chay', 'dang_chay', 'da_duyet'];
	const TRUY_VAN = `query($lo: UUID!) { allCarbonKetQuaMrvs(condition: { loDatId: $lo }) { nodes {
		rowId kyTu kyDen trangThai canhId ngayChup mayPhanTram soDiemAnhLo soDiemAnhHopLe soDiemAnhTan dienTichTanHa co2ETan
		canhBao phuongPhap cogHref lyDoLoi ghiChuDuyet duyetLuc doltCommit phaHe
		carbonDeNghiCapByKetQuaMrvId { trangThai soLuong maTrongNuoc seriTu seriDen doltCommit lyDoLoi } } } }`;

	// Kỳ mặc định: ưu tiên kỳ mẫu mùa khô ít mây ở Mũi Cà Mau (tháng 04/2026) để người dùng thử đo vệ tinh thật ngay
	const GOI_Y_KY = [
		{ nhan: 'Tháng 04/2026 (mùa khô, ít mây)', tu: '2026-04-01', den: '2026-04-30' },
		{ nhan: 'Tháng 03/2026', tu: '2026-03-01', den: '2026-03-31' },
		{ nhan: 'Quý I/2026', tu: '2026-01-01', den: '2026-03-31' }
	] as const;

	let ketQua = $state<KetQua[]>([]);
	let dangTai = $state(true);
	let kyTu = $state('2026-04-01');
	let kyDen = $state('2026-04-30');
	let lyDo = $state<Record<string, string>>({});
	let loi = $state<{ thongBao: string; goiY?: string } | null>(null);
	let dangGui = $state(false);
	let hen: ReturnType<typeof setTimeout> | undefined;
	let daCoCho = false;

	const TEN_PHUONG_PHAP: Record<string, string> = {
		'v0.1-rung-ngap-man-ipcc-tier1': 'IPCC 2013 Wetlands Tier 1 (v0.1)'
	};

	function dinhDangLoiMrv(s: string | null): string {
		if (!s) return 'Không hoàn tất được phép đo vệ tinh cho kỳ này.';
		if (s.includes('đã thử [') || s.includes('ti_le_hop_le')) {
			const m = [...s.matchAll(/ti_le_hop_le['"]:\s*([0-9.]+)/g)].map((x) => Number(x[1]));
			if (m.length) {
				const maxTl = (Math.max(...m) * 100).toLocaleString('vi-VN', { maximumFractionDigits: 1 });
				return `Ảnh vệ tinh trong kỳ bị mây che phủ, chỉ đạt tối đa ${maxTl}% diện tích lô rõ nét qua ${m.length} cảnh kiểm tra (yêu cầu tối thiểu 80%). Vui lòng chọn kỳ mùa khô ít mây hơn (ví dụ: 01/04/2026 – 30/04/2026).`;
			}
			return 'Không tìm thấy cảnh ảnh vệ tinh Sentinel-2 nào đủ 80% diện tích lô rõ nét trong kỳ giám sát đã chọn. Vui lòng chọn kỳ mùa khô ít mây (ví dụ: 01/04/2026 – 30/04/2026).';
		}
		return s;
	}

	function chonKyNhanh(tu: string, den: string) {
		kyTu = tu;
		kyDen = den;
	}

	async function tai() {
		clearTimeout(hen);
		try {
			const d = await goiGraphql<{ allCarbonKetQuaMrvs: { nodes: KetQua[] } }>(token, TRUY_VAN, { lo: lo.rowId });
			ketQua = d.allCarbonKetQuaMrvs.nodes.sort((a, b) => b.kyTu.localeCompare(a.kyTu));
		} catch (e) {
			loi = { thongBao: (e as Error).message };
		} finally {
			dangTai = false;
		}
		const dangCap = ketQua.some((k) => k.carbonDeNghiCapByKetQuaMrvId?.trangThai === 'cho_dang_ky');
		if (dangCap || ketQua.some((k) => DANG_XU_LY.includes(k.trangThai))) hen = setTimeout(tai, 4000);
		if (daCoCho && !dangCap) onThayDoi();
		daCoCho = dangCap;
	}

	async function goi(mutation: string, bien: Record<string, unknown>) {
		loi = null;
		dangGui = true;
		try {
			await goiGraphql(token, mutation, bien);
			await tai();
			onThayDoi();
		} catch (e) {
			loi = e instanceof LoiNghiepVu ? { thongBao: e.message, goiY: e.goiY } : { thongBao: (e as Error).message };
		} finally {
			dangGui = false;
		}
	}

	const yeuCau = (e: SubmitEvent) => {
		e.preventDefault();
		return goi(
			'mutation($lo: UUID, $tu: Date, $den: Date) { carbonYeuCauMrv(input: { loDatId: $lo, kyTu: $tu, kyDen: $den }) { result } }',
			{ lo: lo.rowId, tu: kyTu, den: kyDen }
		);
	};
	const deNghiCap = (id: string) =>
		goi('mutation($id: UUID) { carbonDeNghiCapTinChi(input: { ketQuaMrvId: $id }) { result } }', { id });
	const duyet = (id: string, dongY: boolean) =>
		goi(
			'mutation($id: UUID, $dy: Boolean, $gc: String) { carbonDuyetKetQuaMrv(input: { ketQuaId: $id, dongY: $dy, ghiChu: $gc }) { result } }',
			{ id, dy: dongY, gc: lyDo[id] || null }
		);

	$effect(() => {
		void lo.rowId;
		dangTai = true;
		ketQua = [];
		loi = null;
		tai();
	});
	onDestroy(() => clearTimeout(hen));

	const so = (v: string | null, n = 2) => (v === null ? '–' : Number(v).toLocaleString('vi-VN', { maximumFractionDigits: n }));
</script>

<div class="chi-tiet">
	<div class="vet">
		<button type="button" class="chu" onclick={onDong}>← Tất cả lô đất</button>
	</div>

	<div class="dau-lo">
		<div class="tieu-de">
			<h1>{lo.ten}</h1>
			<span class="chip">Rừng ngập mặn</span>
		</div>
		<p class="phu">
			<b>{so(lo.dienTichHa)} ha</b> theo ranh giới vệ tinh · {lo.namTrong ? `Trồng năm ${lo.namTrong}` : 'Chưa khai năm trồng'}
		</p>
	</div>

	{#if laCanBo}
		<div class="khung-yeu-cau">
			<div class="goi-y-ky">
				<span>Chọn nhanh kỳ giám sát:</span>
				{#each GOI_Y_KY as g (g.tu + g.den)}
					<button
						type="button"
						class="chip-ky"
						class:chon={kyTu === g.tu && kyDen === g.den}
						onclick={() => chonKyNhanh(g.tu, g.den)}
					>
						{g.nhan}
					</button>
				{/each}
			</div>
			<form class="yeu-cau" onsubmit={yeuCau}>
				<label class="o-nhap">Đo từ ngày <input type="date" bind:value={kyTu} required /></label>
				<label class="o-nhap">Đến ngày <input type="date" bind:value={kyDen} required /></label>
				<button class="nut nhat nho" type="submit" disabled={dangGui}>Yêu cầu đo</button>
			</form>
		</div>
	{/if}

	{#if loi}
		<div role="alert" class="loi"><b>{loi.thongBao}</b>{#if loi.goiY}<br />{loi.goiY}{/if}</div>
	{/if}

	<div class="muc-kq">
		<h2>Kết quả đo ({ketQua.length})</h2>
	</div>

	{#if dangTai}
		<p class="phu">Đang tải kết quả đo…</p>
	{:else if !ketQua.length}
		<p class="phu">Chưa có kết quả đo cho lô này.{#if laCanBo}{' '}Chọn kỳ rồi bấm Yêu cầu đo.{/if}</p>
	{/if}

	{#each ketQua as k (k.rowId)}
		<article class="kq" data-trang-thai={k.trangThai}>
			<header class="kq-dau">
				<div>
					<span class="nhan-nho">Kỳ giám sát</span>
					<strong>{k.kyTu.split('-').reverse().join('/')} – {k.kyDen.split('-').reverse().join('/')}</strong>
				</div>
				<span class="nhan {NHAN[k.trangThai] ?? ''}">{TRANG_THAI[k.trangThai] ?? k.trangThai}</span>
			</header>

			{#if k.trangThai === 'loi'}
				<p class="loi">{dinhDangLoiMrv(k.lyDoLoi)}</p>
			{:else if !k.canhId}
				<p class="phu">Đang tìm cảnh ảnh vệ tinh ít mây và tính toán.</p>
			{:else}
				<div class="hop-co2e">
					<div>
						<p class="co2e">{so(k.co2ETan, 2)} <span>t CO₂e</span></p>
						<p class="co2e-giai">Ước tính hấp thụ trong kỳ (phương pháp cận dưới IPCC Tier 1)</p>
					</div>
					{#if k.cogHref}
						<button
							type="button"
							class="nut-ndvi"
							class:dang-bat={lopDangXem === k.cogHref}
							onclick={() => onXemLop(lopDangXem === k.cogHref ? null : k.cogHref)}
						>
							<svg viewBox="0 0 20 20" width="14" height="14" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M10 4C5 4 1.7 8 1.7 10s3.3 6 8.3 6 8.3-4 8.3-6-3.3-6-8.3-6z"/><circle cx="10" cy="10" r="3"/></svg>
							<span>{lopDangXem === k.cogHref ? 'Ẩn lớp NDVI trên bản đồ' : 'Xem lớp NDVI trên bản đồ'}</span>
						</button>
					{/if}
				</div>

				<dl class="luoi-thong-so">
					<div>
						<dt>Diện tích tán</dt>
						<dd>{so(k.dienTichTanHa)} ha</dd>
					</div>
					<div>
						<dt>Điểm ảnh tán / hợp lệ</dt>
						<dd>{k.soDiemAnhTan?.toLocaleString('vi-VN')} / {k.soDiemAnhHopLe?.toLocaleString('vi-VN')} ({k.soDiemAnhLo?.toLocaleString('vi-VN')} tổng)</dd>
					</div>
					<div>
						<dt>Cảnh Sentinel-2</dt>
						<dd>{k.ngayChup?.split('-').reverse().join('/')} · mây {so(k.mayPhanTram, 1)} %</dd>
					</div>
					<div>
						<dt>Phương pháp</dt>
						<dd>{TEN_PHUONG_PHAP[k.phuongPhap ?? ''] ?? k.phuongPhap}</dd>
					</div>
					{#if k.doltCommit}
						<div class="toan-hang">
							<dt>Cam kết sổ cái Dolt</dt>
							<dd><a href="/kiem-chung?q={k.doltCommit}"><code>{k.doltCommit}</code></a></dd>
						</div>
					{/if}
					{#if k.ghiChuDuyet}
						<div class="toan-hang">
							<dt>Ghi chú duyệt</dt>
							<dd>{k.ghiChuDuyet}</dd>
						</div>
					{/if}
				</dl>

				{#each k.canhBao as cb (cb)}
					<p class="canh-bao">{CANH_BAO[cb] ?? cb}</p>
				{/each}

				{@const cap = k.carbonDeNghiCapByKetQuaMrvId}
				{#if cap}
					<div class="cap">
						{#if cap.trangThai === 'da_cap'}
							<div class="cap-dau">
								<span class="nhan tot">Đã cấp {cap.soLuong} tín chỉ</span>
								{#if cap.doltCommit}
									<a class="chu-nho" href="/kiem-chung?q={cap.doltCommit}">Xem commit cấp</a>
								{/if}
							</div>
							<p>
								Dải sê-ri: <a href="/kiem-chung?q={cap.seriTu}"><code>{cap.seriTu}</code></a> đến
								<code>{cap.seriDen?.slice(-10)}</code>
							</p>
						{:else if cap.trangThai === 'cho_dang_ky'}
							<p>Đang đăng ký <b>{cap.soLuong} tín chỉ</b> với Registry…</p>
						{:else}
							<p class="xau">Registry từ chối: {cap.lyDoLoi}</p>
						{/if}
					</div>
				{:else if laCanBo && k.trangThai === 'da_ghi_so'}
					<button type="button" class="nut rong" disabled={dangGui || Number(k.co2ETan) < 1} onclick={() => deNghiCap(k.rowId)}>
						Đề nghị cấp {Math.floor(Number(k.co2ETan))} tín chỉ
					</button>
				{/if}

				{#if laCanBo && k.trangThai === 'cho_duyet'}
					<div class="duyet">
						<label class="o-nhap">
							Ghi chú duyệt (bắt buộc khi từ chối)
							<textarea bind:value={lyDo[k.rowId]} rows="2" placeholder="Nhận xét về độ phủ tán và chất lượng ảnh vệ tinh…"></textarea>
						</label>
						<div class="hang-duyet">
							<button type="button" class="nut rong" disabled={dangGui} onclick={() => duyet(k.rowId, true)}>
								<svg viewBox="0 0 16 16" width="15" height="15" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><path d="M3 8.5 6.5 12 13 4"/></svg>
								Duyệt và ghi sổ cái Dolt
							</button>
							<button type="button" class="nut-tu-choi" disabled={dangGui} onclick={() => duyet(k.rowId, false)}>Từ chối</button>
						</div>
					</div>
				{/if}

				{#if k.phaHe}
					{@const ph = k.phaHe as Record<string, any>}
					<div class="khung-pha-he">
						<span class="nhan-nho">Đối chứng phả hệ vệ tinh & tham số IPCC</span>
						<dl class="luoi-pha-he">
							<div>
								<dt>Mã cảnh nguồn</dt>
								<dd><code>{ph.canh_nguon?.id ?? k.canhId}</code></dd>
							</div>
							<div>
								<dt>Bộ sưu tập STAC</dt>
								<dd><code>{ph.canh_nguon?.collection ?? 'sentinel-2-c1-l2a'}</code></dd>
							</div>
							{#if ph.lo_dat?.ranh_gioi_sha256}
								<div>
									<dt>SHA-256 ranh giới lô</dt>
									<dd><code>{String(ph.lo_dat.ranh_gioi_sha256).slice(0, 16)}…</code></dd>
								</div>
							{/if}
							{#if ph.tham_so_sha256}
								<div>
									<dt>SHA-256 bộ tham số</dt>
									<dd><code>{String(ph.tham_so_sha256).slice(0, 16)}…</code></dd>
								</div>
							{/if}
						</dl>
						<details>
							<summary>Xem bản ghi phả hệ gốc (JSON kiểm toán)</summary>
							<pre><code>{JSON.stringify(k.phaHe, null, 2)}</code></pre>
						</details>
					</div>
				{/if}
			{/if}
		</article>
	{/each}
</div>

<style>
	.chi-tiet {
		display: flex;
		flex-direction: column;
		gap: 11px;
		font-family: var(--sans);
	}
	.vet {
		display: flex;
		gap: 6px;
		color: var(--mo);
	}
	.chu {
		align-self: start;
		min-height: 28px;
		padding: 0;
		border: 0;
		background: none;
		color: var(--teal);
		font: 600 0.875rem var(--sans);
		text-decoration: underline;
		text-underline-offset: 0.22em;
		cursor: pointer;
	}
	.chu:hover {
		color: var(--teal-dam);
	}

	.dau-lo {
		display: grid;
		gap: 6px;
	}
	.tieu-de {
		display: flex;
		align-items: center;
		flex-wrap: wrap;
		gap: 10px;
	}
	h1 {
		font: 700 1.5rem/1.2 var(--sans);
		letter-spacing: -0.02em;
	}
	.chip {
		padding: 4px 10px;
		border: 1px solid #b5dcce;
		border-radius: 999px;
		background: var(--teal-nhat);
		color: var(--teal-dam);
		font-size: 0.75rem;
		font-weight: 600;
		white-space: nowrap;
	}
	.phu {
		color: var(--mo);
		font-size: 0.875rem;
	}
	.phu b {
		color: var(--muc);
		font-variant-numeric: tabular-nums;
	}

	.khung-yeu-cau {
		display: grid;
		gap: 8px;
		padding: 12px 0;
		border-top: 1px solid var(--ke);
		border-bottom: 1px solid var(--ke);
	}
	.goi-y-ky {
		display: flex;
		flex-wrap: wrap;
		align-items: center;
		gap: 6px;
		color: var(--mo);
		font-size: 0.75rem;
	}
	.chip-ky {
		padding: 4px 10px;
		border: 1px solid var(--ke-dam);
		border-radius: 999px;
		background: #fff;
		color: var(--muc);
		font: 500 0.75rem var(--sans);
		cursor: pointer;
		transition: border-color 0.15s var(--de), background-color 0.15s var(--de);
	}
	.chip-ky:hover,
	.chip-ky.chon {
		border-color: var(--teal);
		background: var(--teal-nhat);
		color: var(--teal-dam);
		font-weight: 600;
	}
	.yeu-cau {
		display: grid;
		grid-template-columns: 1fr 1fr auto;
		align-items: end;
		gap: 8px;
	}
	.yeu-cau label,
	.yeu-cau input {
		min-width: 0;
	}
	.yeu-cau input {
		padding: 0 8px;
		font-size: 0.8125rem;
	}
	.yeu-cau .nut {
		height: 44px;
		padding: 0 14px;
	}

	.khung-pha-he {
		display: grid;
		gap: 8px;
		padding: 12px 14px;
		border: 1px solid var(--ke);
		border-radius: 14px;
		background: var(--nen-mem);
	}
	.luoi-pha-he {
		display: grid;
		grid-template-columns: 1fr 1fr;
		gap: 8px 12px;
		margin: 0;
	}
	.luoi-pha-he div {
		display: grid;
		gap: 2px;
	}

	.muc-kq {
		display: flex;
		justify-content: space-between;
		align-items: center;
		padding-top: 4px;
	}
	h2 {
		font: 700 1.0625rem var(--sans);
	}

	.kq {
		display: flex;
		flex-direction: column;
		gap: 10px;
		padding-top: 10px;
		border-top: 1px solid var(--ke);
	}
	.kq-dau {
		display: flex;
		justify-content: space-between;
		align-items: center;
		flex-wrap: wrap;
		gap: 8px 12px;
	}
	.kq-dau > div {
		display: grid;
		gap: 2px;
	}
	.nhan-nho {
		color: var(--mo);
		font-size: 0.6875rem;
		font-weight: 600;
		letter-spacing: 0.04em;
		text-transform: uppercase;
	}
	.kq-dau strong {
		color: var(--muc);
		font-size: 0.9375rem;
		font-variant-numeric: tabular-nums;
	}

	.hop-co2e {
		display: flex;
		justify-content: space-between;
		align-items: center;
		flex-wrap: wrap;
		gap: 12px;
		padding: 14px 16px;
		border-radius: 14px;
		background: var(--teal-nhat);
	}
	.co2e {
		color: var(--teal-dam);
		font: 700 2.125rem/1.05 var(--sans);
		letter-spacing: -0.03em;
		font-variant-numeric: tabular-nums;
	}
	.co2e span {
		color: var(--teal);
		font: 600 1rem var(--sans);
		letter-spacing: 0;
	}
	.co2e-giai {
		margin-top: 4px;
		color: var(--mo);
		font-size: 0.75rem;
	}
	.nut-ndvi {
		display: inline-flex;
		align-items: center;
		gap: 6px;
		min-height: 36px;
		padding: 0 14px;
		border: 1px solid var(--teal);
		border-radius: 999px;
		background: #ffffff;
		color: var(--teal-dam);
		font: 600 0.8125rem var(--sans);
		cursor: pointer;
		box-shadow: 0 1px 2px rgba(11, 99, 81, 0.1);
		transition: all 0.15s var(--de);
	}
	.nut-ndvi:hover,
	.nut-ndvi.dang-bat {
		background: var(--teal);
		border-color: var(--teal);
		color: #ffffff;
		box-shadow: 0 4px 10px -2px rgba(11, 99, 81, 0.25);
	}

	.luoi-thong-so {
		display: grid;
		grid-template-columns: 1fr 1fr;
		gap: 10px 16px;
		margin: 0;
		padding: 12px 0;
		border-top: 1px solid var(--ke);
		border-bottom: 1px solid var(--ke);
	}
	.luoi-thong-so div {
		display: grid;
		gap: 2px;
	}
	.luoi-thong-so .toan-hang {
		grid-column: 1 / -1;
		padding-top: 8px;
		border-top: 1px dashed var(--ke);
	}
	dt {
		color: var(--mo);
		font-size: 0.75rem;
	}
	dd {
		margin: 0;
		color: var(--muc);
		font-size: 0.8125rem;
		font-weight: 600;
		font-variant-numeric: tabular-nums;
		overflow-wrap: anywhere;
	}
	dd a {
		color: var(--teal);
	}

	.canh-bao {
		padding: 10px 14px;
		border-radius: 12px;
		background: var(--amber-nhat);
		color: var(--amber-chu);
		font-size: 0.8125rem;
		font-weight: 500;
	}
	.cap {
		display: grid;
		gap: 6px;
		padding: 14px 16px;
		border-radius: 14px;
		background: var(--teal-nhat);
		color: var(--teal-dam);
		font-size: 0.8125rem;
		overflow-wrap: anywhere;
	}
	.cap-dau {
		display: flex;
		justify-content: space-between;
		align-items: center;
		gap: 8px;
	}
	.cap a {
		color: var(--teal-dam);
		font-weight: 600;
	}
	.chu-nho {
		font-size: 0.75rem;
	}
	.xau {
		color: var(--xau);
	}
	.duyet {
		display: grid;
		gap: 12px;
		padding-top: 8px;
	}
	.hang-duyet {
		display: grid;
		grid-template-columns: 1fr auto;
		gap: 10px;
	}
	.nut-tu-choi {
		min-height: 46px;
		padding: 0 16px;
		border: 0;
		border-radius: 999px;
		background: var(--xau-nhat);
		color: var(--xau);
		font: 600 0.875rem var(--sans);
		cursor: pointer;
	}
	code {
		font-size: 0.85em;
	}
	details {
		padding-top: 2px;
	}
	summary {
		color: var(--mo);
		font-size: 0.8125rem;
		font-weight: 600;
		cursor: pointer;
	}
	pre {
		max-height: 15rem;
		overflow: auto;
		margin: 8px 0 0;
		padding: 12px;
		border-radius: 12px;
		background: var(--giay);
		font-size: 0.75rem;
	}
</style>
