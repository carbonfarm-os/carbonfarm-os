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

	// Kỳ mặc định: tháng trọn vẹn gần nhất
	const nay = new Date();
	const dauThangTruoc = new Date(Date.UTC(nay.getUTCFullYear(), nay.getUTCMonth() - 1, 1));
	const cuoiThangTruoc = new Date(Date.UTC(nay.getUTCFullYear(), nay.getUTCMonth(), 0));
	const iso = (d: Date) => d.toISOString().slice(0, 10);

	let ketQua = $state<KetQua[]>([]);
	let dangTai = $state(true);
	let kyTu = $state(iso(dauThangTruoc));
	let kyDen = $state(iso(cuoiThangTruoc));
	let lyDo = $state<Record<string, string>>({});
	let loi = $state<{ thongBao: string; goiY?: string } | null>(null);
	let dangGui = $state(false);
	let hen: ReturnType<typeof setTimeout> | undefined;
	let daCoCho = false;

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
		// Tự làm mới khi còn kết quả đang chạy trên máy chủ
		const dangCap = ketQua.some((k) => k.carbonDeNghiCapByKetQuaMrvId?.trangThai === 'cho_dang_ky');
		if (dangCap || ketQua.some((k) => DANG_XU_LY.includes(k.trangThai))) hen = setTimeout(tai, 4000);
		// Vừa cấp xong → trang chính tải lại ví
		if (daCoCho && !dangCap) onThayDoi();
		daCoCho = dangCap;
	}

	async function goi(mutation: string, bien: Record<string, unknown>) {
		loi = null;
		dangGui = true;
		try {
			await goiGraphql(token, mutation, bien);
			await tai();
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
		<button type="button" class="chu" onclick={onDong}>Lô đất</button><span>/</span>
	</div>
	<div class="tieu-de">
		<h1>{lo.ten}</h1>
		<span class="chip">rừng ngập mặn</span>
	</div>
	<p class="phu">{so(lo.dienTichHa)} ha theo ranh giới · {lo.namTrong ? `trồng năm ${lo.namTrong}` : 'chưa khai năm trồng'}</p>

	{#if laCanBo}
		<form class="yeu-cau" onsubmit={yeuCau}>
			<label class="o-nhap">Đo từ ngày <input type="date" bind:value={kyTu} required /></label>
			<label class="o-nhap">Đến ngày <input type="date" bind:value={kyDen} required /></label>
			<button class="nut nhat nho" type="submit" disabled={dangGui}>Yêu cầu đo</button>
		</form>
	{/if}

	{#if loi}
		<div role="alert" class="loi"><b>{loi.thongBao}</b>{#if loi.goiY}<br />{loi.goiY}{/if}</div>
	{/if}

	<h2>Kết quả đo</h2>
	{#if dangTai}
		<p class="phu">Đang tải…</p>
	{:else if !ketQua.length}
		<p class="phu">Chưa có kết quả đo cho lô này.{#if laCanBo} Chọn kỳ rồi bấm Yêu cầu đo.{/if}</p>
	{/if}
	{#each ketQua as k (k.rowId)}
		<article class="kq" data-trang-thai={k.trangThai}>
			<header>
				<span>{k.kyTu.split('-').reverse().join('/')} – {k.kyDen.split('-').reverse().join('/')}</span>
				<span class="nhan {NHAN[k.trangThai] ?? ''}">{TRANG_THAI[k.trangThai] ?? k.trangThai}</span>
			</header>
			{#if k.trangThai === 'loi'}
				<p class="loi">{k.lyDoLoi}</p>
			{:else if !k.canhId}
				<p class="phu">Đang tìm cảnh ảnh vệ tinh ít mây và tính toán.</p>
			{:else}
				<p class="co2e">{so(k.co2ETan, 2)} <span>t CO₂e</span></p>
				<p class="co2e-giai">ước tính hấp thụ trong kỳ, phương pháp cận dưới</p>
				<dl>
					<div><dt>Diện tích tán</dt><dd>{so(k.dienTichTanHa)} ha</dd></div>
					<div><dt>Điểm ảnh tán / hợp lệ / trong lô</dt><dd>{k.soDiemAnhTan} / {k.soDiemAnhHopLe} / {k.soDiemAnhLo}</dd></div>
					<div><dt>Cảnh Sentinel-2</dt><dd>{k.ngayChup?.split('-').reverse().join('/')} · mây {so(k.mayPhanTram, 1)} %</dd></div>
					<div><dt>Phương pháp</dt><dd>{k.phuongPhap}</dd></div>
					{#if k.doltCommit}
						<div><dt>Sổ cái</dt><dd><a href="/kiem-chung?q={k.doltCommit}"><code>{k.doltCommit.slice(0, 12)}…</code></a></dd></div>
					{/if}
					{#if k.ghiChuDuyet}<div><dt>Ghi chú duyệt</dt><dd>{k.ghiChuDuyet}</dd></div>{/if}
				</dl>
				{#each k.canhBao as cb (cb)}<p class="canh-bao">{CANH_BAO[cb] ?? cb}</p>{/each}
				{#if k.cogHref}
					<button type="button" class="chu" onclick={() => onXemLop(lopDangXem === k.cogHref ? null : k.cogHref)}>
						{lopDangXem === k.cogHref ? 'Ẩn lớp NDVI trên bản đồ' : 'Xem lớp NDVI trên bản đồ'}
					</button>
				{/if}

				{@const cap = k.carbonDeNghiCapByKetQuaMrvId}
				{#if cap}
					<p class="cap">
						{#if cap.trangThai === 'da_cap'}
							Đã cấp <b>{cap.soLuong} tín chỉ</b>, sê-ri <a href="/kiem-chung?q={cap.seriTu}"><code>{cap.seriTu}</code></a> đến <code>{cap.seriDen?.slice(-10)}</code>.
						{:else if cap.trangThai === 'cho_dang_ky'}
							Đang đăng ký {cap.soLuong} tín chỉ với Registry.
						{:else}
							<span class="xau">Registry từ chối: {cap.lyDoLoi}</span>
						{/if}
					</p>
				{:else if laCanBo && k.trangThai === 'da_ghi_so'}
					<button type="button" class="nut rong" disabled={dangGui || Number(k.co2ETan) < 1} onclick={() => deNghiCap(k.rowId)}>
						Đề nghị cấp {Math.floor(Number(k.co2ETan))} tín chỉ
					</button>
				{/if}

				{#if laCanBo && k.trangThai === 'cho_duyet'}
					<div class="duyet">
						<label class="o-nhap">
							Ghi chú duyệt, bắt buộc khi từ chối
							<textarea bind:value={lyDo[k.rowId]} rows="2"></textarea>
						</label>
						<button type="button" class="nut rong" disabled={dangGui} onclick={() => duyet(k.rowId, true)}>Duyệt và ghi sổ</button>
						<button type="button" class="chu xau giua" disabled={dangGui} onclick={() => duyet(k.rowId, false)}>Từ chối</button>
					</div>
				{/if}
				<details>
					<summary>Phả hệ dữ liệu</summary>
					<pre><code>{JSON.stringify(k.phaHe, null, 2)}</code></pre>
				</details>
			{/if}
		</article>
	{/each}
</div>

<style>
	.chi-tiet {
		display: flex;
		flex-direction: column;
		gap: 16px;
	}
	.vet {
		display: flex;
		gap: 6px;
		color: var(--mo);
	}
	.chu {
		align-self: start;
		min-height: 32px;
		padding: 0;
		border: 0;
		background: none;
		color: var(--teal);
		font: 500 0.9375rem var(--sans);
		text-decoration: underline;
		text-underline-offset: 0.25em;
		cursor: pointer;
	}
	.chu:hover {
		color: var(--teal-dam);
	}
	.chu.xau {
		color: var(--xau);
	}
	.chu.giua {
		align-self: center;
		justify-self: center;
	}
	.tieu-de {
		display: flex;
		align-items: center;
		flex-wrap: wrap;
		gap: 10px 12px;
	}
	h1 {
		font-size: 1.875rem;
	}
	.chip {
		padding: 4px 12px;
		border-radius: 999px;
		background: var(--teal-nhat);
		color: var(--teal);
		font-size: 0.8125rem;
		font-weight: 500;
		white-space: nowrap;
	}
	.phu {
		color: var(--mo);
	}
	.yeu-cau {
		display: grid;
		grid-template-columns: 1fr 1fr;
		gap: 12px;
		align-items: end;
		padding: 16px;
		border-radius: 18px;
		background: var(--giay);
	}
	.yeu-cau .nut {
		grid-column: 1 / -1;
	}
	h2 {
		margin-top: 8px;
		font-size: 1.25rem;
	}
	.kq {
		display: flex;
		flex-direction: column;
		gap: 14px;
		padding-top: 20px;
		border-top: 1px solid var(--ke);
	}
	.kq + .kq {
		margin-top: 12px;
	}
	.kq header {
		display: flex;
		justify-content: space-between;
		align-items: center;
		flex-wrap: wrap;
		gap: 8px 12px;
		color: var(--muc);
		font-weight: 500;
	}
	.co2e {
		margin-top: 4px;
		color: var(--muc);
		font: 600 3.25rem/1 var(--serif);
		letter-spacing: -0.03em;
	}
	.co2e span {
		color: var(--mo);
		font: 500 1.125rem var(--sans);
		letter-spacing: 0;
	}
	.co2e-giai {
		margin-top: -6px;
		color: var(--mo);
		font-size: 0.875rem;
	}
	dl {
		display: grid;
		margin: 0;
	}
	dl div {
		display: flex;
		justify-content: space-between;
		align-items: baseline;
		gap: 16px;
		padding: 12px 0;
		border-bottom: 1px solid var(--ke);
	}
	dt {
		color: var(--mo);
	}
	dd {
		margin: 0;
		color: var(--muc);
		font-weight: 500;
		text-align: right;
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
		font-size: 0.875rem;
	}
	.cap {
		padding: 14px 16px;
		border-radius: 14px;
		background: var(--teal-nhat);
		color: var(--teal-dam);
		overflow-wrap: anywhere;
	}
	.cap a {
		color: inherit;
	}
	.xau {
		color: var(--xau);
	}
	.duyet {
		display: grid;
		gap: 12px;
		margin-top: 4px;
	}
	code {
		font-size: 0.85em;
	}
	details {
		padding-top: 4px;
	}
	summary {
		color: var(--muc);
		font-weight: 500;
		cursor: pointer;
	}
	pre {
		max-height: 16rem;
		overflow: auto;
		margin: 8px 0 0;
		padding: 14px;
		border-radius: 14px;
		background: var(--giay);
		font-size: 0.75rem;
	}
</style>
