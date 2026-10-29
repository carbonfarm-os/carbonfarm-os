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
	};
	type Lo = { rowId: string; ten: string; dienTichHa: string; namTrong: number | null };

	let {
		token,
		lo,
		laCanBo,
		lopDangXem,
		onXemLop,
		onDong
	}: {
		token: Token;
		lo: Lo;
		laCanBo: boolean;
		lopDangXem: string | null;
		onXemLop: (cog: string | null) => void;
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
	const DANG_XU_LY = ['cho_chay', 'dang_chay', 'da_duyet'];
	const TRUY_VAN = `query($lo: UUID!) { allCarbonKetQuaMrvs(condition: { loDatId: $lo }) { nodes {
		rowId kyTu kyDen trangThai canhId ngayChup mayPhanTram soDiemAnhLo soDiemAnhHopLe soDiemAnhTan dienTichTanHa co2ETan
		canhBao phuongPhap cogHref lyDoLoi ghiChuDuyet duyetLuc doltCommit phaHe } } }`;

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
		if (ketQua.some((k) => DANG_XU_LY.includes(k.trangThai))) hen = setTimeout(tai, 4000);
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

<section>
	<div class="tieu-de">
		<h2>{lo.ten}</h2>
		<button type="button" class="phu" onclick={onDong} aria-label="Đóng chi tiết lô">✕</button>
	</div>
	<p class="phu-de">{so(lo.dienTichHa)} ha{#if lo.namTrong} · trồng {lo.namTrong}{:else} · chưa khai năm trồng{/if}</p>

	{#if laCanBo}
		<form class="yeu-cau" onsubmit={yeuCau}>
			<label>Từ <input type="date" bind:value={kyTu} required /></label>
			<label>Đến <input type="date" bind:value={kyDen} required /></label>
			<button type="submit" disabled={dangGui}>Yêu cầu đo carbon</button>
		</form>
	{/if}

	{#if loi}
		<div role="alert" class="loi"><b>{loi.thongBao}</b>{#if loi.goiY}<br />{loi.goiY}{/if}</div>
	{/if}

	<h3>Kết quả đo (MRV)</h3>
	{#if dangTai}
		<p>Đang tải…</p>
	{:else if !ketQua.length}
		<p>Chưa có kết quả đo cho lô này.</p>
	{/if}
	{#each ketQua as k (k.rowId)}
		<article class="kq" data-trang-thai={k.trangThai}>
			<header>
				<b>{k.kyTu} → {k.kyDen}</b>
				<span class="nhan">{TRANG_THAI[k.trangThai] ?? k.trangThai}</span>
			</header>
			{#if k.trangThai === 'loi'}
				<p class="loi">{k.lyDoLoi}</p>
			{:else if k.canhId}
				<dl>
					<dt>Hấp thụ ước lượng</dt>
					<dd><b>{so(k.co2ETan, 1)} t CO₂e</b></dd>
					<dt>Diện tích tán tính</dt>
					<dd>{so(k.dienTichTanHa)} ha</dd>
					<dt>Điểm ảnh tán / hợp lệ / trong lô</dt>
					<dd>{k.soDiemAnhTan} / {k.soDiemAnhHopLe} / {k.soDiemAnhLo}</dd>
					<dt>Cảnh Sentinel-2</dt>
					<dd>{k.ngayChup} · mây {so(k.mayPhanTram, 1)} %<br /><small>{k.canhId}</small></dd>
					<dt>Phương pháp</dt>
					<dd><small>{k.phuongPhap}</small></dd>
					{#if k.doltCommit}
						<dt>Sổ cái Dolt</dt>
						<dd><code title="Mã băm commit">{k.doltCommit}</code></dd>
					{/if}
					{#if k.ghiChuDuyet}
						<dt>Ghi chú duyệt</dt>
						<dd>{k.ghiChuDuyet}</dd>
					{/if}
				</dl>
				{#each k.canhBao as cb (cb)}<p class="canh-bao">⚠ {CANH_BAO[cb] ?? cb}</p>{/each}
				<div class="nut">
					{#if k.cogHref}
						{#if lopDangXem === k.cogHref}
							<button type="button" class="phu" onclick={() => onXemLop(null)}>Ẩn lớp NDVI</button>
						{:else}
							<button type="button" class="phu" onclick={() => onXemLop(k.cogHref)}>Xem lớp NDVI</button>
						{/if}
					{/if}
				</div>
				{#if laCanBo && k.trangThai === 'cho_duyet'}
					<div class="duyet">
						<textarea bind:value={lyDo[k.rowId]} rows="2" placeholder="Ghi chú (bắt buộc khi từ chối)"></textarea>
						<div class="nut">
							<button type="button" disabled={dangGui} onclick={() => duyet(k.rowId, true)}>Duyệt và ghi sổ</button>
							<button type="button" class="tu-choi" disabled={dangGui} onclick={() => duyet(k.rowId, false)}>Từ chối</button>
						</div>
					</div>
				{/if}
				<details>
					<summary>Phả hệ dữ liệu</summary>
					<pre>{JSON.stringify(k.phaHe, null, 2)}</pre>
				</details>
			{/if}
		</article>
	{/each}
</section>

<style>
	.tieu-de {
		display: flex;
		justify-content: space-between;
		align-items: center;
	}
	h2 {
		margin: 0;
		font-size: 1.1rem;
	}
	h3 {
		margin: 1rem 0 0.5rem;
		font-size: 1rem;
	}
	.phu-de {
		margin: 0.2rem 0 0.8rem;
		color: #40594a;
		font-size: 0.9rem;
	}
	.yeu-cau {
		display: flex;
		flex-wrap: wrap;
		gap: 0.5rem;
		align-items: end;
	}
	label {
		display: grid;
		gap: 0.2rem;
		font-size: 0.85rem;
	}
	input,
	textarea {
		font: inherit;
		padding: 0.3rem 0.45rem;
		border: 1px solid #b7c9b2;
		border-radius: 6px;
		background: #fff;
		color: #1b2b22;
	}
	textarea {
		width: 100%;
		box-sizing: border-box;
	}
	.kq {
		margin-bottom: 0.7rem;
		padding: 0.6rem 0.7rem;
		border: 1px solid #cfdccb;
		border-radius: 8px;
		background: #fff;
	}
	.kq header {
		display: flex;
		justify-content: space-between;
		gap: 0.5rem;
		align-items: center;
	}
	.nhan {
		font-size: 0.75rem;
		padding: 0.1rem 0.5rem;
		border-radius: 999px;
		background: #e3ebe0;
		color: #1b4332;
		white-space: nowrap;
	}
	[data-trang-thai='cho_duyet'] .nhan {
		background: #fff1c2;
		color: #6b4e00;
	}
	[data-trang-thai='da_ghi_so'] .nhan {
		background: #1b4332;
		color: #fff;
	}
	[data-trang-thai='tu_choi'] .nhan,
	[data-trang-thai='loi'] .nhan {
		background: #fde2e1;
		color: #7a1c17;
	}
	dl {
		display: grid;
		grid-template-columns: auto 1fr;
		gap: 0.2rem 0.7rem;
		margin: 0.5rem 0;
		font-size: 0.85rem;
	}
	dt {
		color: #40594a;
	}
	dd {
		margin: 0;
		overflow-wrap: anywhere;
	}
	code {
		font-size: 0.75rem;
	}
	.loi {
		padding: 0.5rem 0.7rem;
		border-radius: 6px;
		background: #fde2e1;
		color: #7a1c17;
	}
	.canh-bao {
		margin: 0.2rem 0;
		font-size: 0.85rem;
		color: #8a4b00;
	}
	.duyet {
		display: grid;
		gap: 0.4rem;
		margin-top: 0.5rem;
	}
	.nut {
		display: flex;
		gap: 0.5rem;
		margin-top: 0.4rem;
	}
	details {
		margin-top: 0.5rem;
		font-size: 0.8rem;
	}
	pre {
		max-height: 16rem;
		overflow: auto;
		padding: 0.5rem;
		background: #f4f7f2;
		border-radius: 6px;
		font-size: 0.72rem;
	}
	button {
		font: inherit;
		padding: 0.35rem 0.9rem;
		border: 0;
		border-radius: 6px;
		background: #95d5b2;
		color: #1b4332;
		cursor: pointer;
	}
	button:disabled {
		opacity: 0.5;
		cursor: not-allowed;
	}
	button.phu {
		background: #e3ebe0;
	}
	button.tu-choi {
		background: #f6c9c6;
		color: #7a1c17;
	}
</style>
