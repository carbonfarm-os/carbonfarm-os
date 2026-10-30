<!-- SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors -->
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->
<!--
	Ví tín chỉ của hợp tác xã + lệnh bán. Cơ chế tạo và duyệt hai người (TT 11/2026/TT-BNNMT Điều 6 khoản 3):
	cán bộ tạo lệnh, cán bộ KHÁC duyệt; CSDL chặn tự duyệt (UC031), vượt số dư (UC030). Lỗi hiện nguyên văn tiếng Việt.
-->
<script lang="ts">
	import { onDestroy } from 'svelte';
	import type { Token } from './dang-nhap.ts';
	import { goiGraphql, LoiNghiepVu } from './graphql.ts';

	type Khoi = { rowId: string; soLuong: number; maTrongNuoc: string; seriTu: string; seriDen: string; hopTacXaId: string };
	type NguoiMua = { ma: string; ten: string; donGiaToiDaVnd: string };
	type Lenh = {
		rowId: string;
		maNguoiMua: string;
		maTrongNuoc: string;
		soLuong: number;
		donGiaVnd: string;
		thanhTienVnd: string;
		trangThai: string;
		taoLuc: string;
		doToiTao: boolean;
		ghiChuDuyet: string | null;
		doltCommit: string | null;
		lyDoLoi: string | null;
	};

	let { token, laCanBo, vi, onThayDoi }: { token: Token; laCanBo: boolean; vi: Khoi[]; onThayDoi: () => void } = $props();

	const TRANG_THAI: Record<string, string> = {
		cho_duyet: 'Chờ cán bộ khác duyệt',
		da_duyet: 'Đang giao dịch',
		tu_choi: 'Bị từ chối',
		hoan_tat: 'Hoàn tất',
		loi: 'Lỗi'
	};
	const TRUY_VAN = `{ allCarbonNguoiMuas { nodes { ma ten donGiaToiDaVnd } }
		allCarbonLenhBans { nodes { rowId maNguoiMua maTrongNuoc soLuong donGiaVnd thanhTienVnd trangThai taoLuc doToiTao
			ghiChuDuyet doltCommit lyDoLoi } } }`;

	let nguoiMua = $state<NguoiMua[]>([]);
	let lenh = $state<Lenh[]>([]);
	let form = $state({ maNguoiMua: '', soLuong: '', donGia: '' });
	let lyDo = $state<Record<string, string>>({});
	let loi = $state<{ thongBao: string; goiY?: string } | null>(null);
	let dangGui = $state(false);
	let hen: ReturnType<typeof setTimeout> | undefined;

	const tong = $derived(vi.reduce((t, k) => t + k.soLuong, 0));
	const maTin = $derived(vi[0]?.maTrongNuoc ?? '');
	const vnd = (v: string | number) => `${Number(v).toLocaleString('vi-VN')} đ`;

	async function tai() {
		clearTimeout(hen);
		try {
			const d = await goiGraphql<{ allCarbonNguoiMuas: { nodes: NguoiMua[] }; allCarbonLenhBans: { nodes: Lenh[] } }>(
				token,
				TRUY_VAN
			);
			nguoiMua = d.allCarbonNguoiMuas.nodes;
			const dangGiaoDich = lenh.some((l) => l.trangThai === 'da_duyet');
			lenh = d.allCarbonLenhBans.nodes.sort((a, b) => b.taoLuc.localeCompare(a.taoLuc));
			if (!form.maNguoiMua && nguoiMua.length) form.maNguoiMua = nguoiMua[0].ma;
			// Giao dịch vừa xong → ví đổi
			if (dangGiaoDich && !lenh.some((l) => l.trangThai === 'da_duyet')) onThayDoi();
		} catch (e) {
			loi = { thongBao: (e as Error).message };
		}
		if (lenh.some((l) => l.trangThai === 'da_duyet')) hen = setTimeout(tai, 3000);
	}

	async function goi(mutation: string, bien: Record<string, unknown>) {
		loi = null;
		dangGui = true;
		try {
			await goiGraphql(token, mutation, bien);
			await tai();
			return true;
		} catch (e) {
			loi = e instanceof LoiNghiepVu ? { thongBao: e.message, goiY: e.goiY } : { thongBao: (e as Error).message };
			return false;
		} finally {
			dangGui = false;
		}
	}

	async function taoLenh(e: SubmitEvent) {
		e.preventDefault();
		const ok = await goi(
			`mutation($htx: UUID, $nm: String, $ma: String, $sl: Int, $gia: BigInt) {
				carbonTaoLenhBan(input: { hopTacXaId: $htx, maNguoiMua: $nm, maTrongNuoc: $ma, soLuong: $sl, donGiaVnd: $gia }) { result } }`,
			{
				htx: vi[0]?.hopTacXaId,
				nm: form.maNguoiMua,
				ma: maTin,
				sl: Number(form.soLuong),
				gia: form.donGia.replace(/\D/g, '')
			}
		);
		if (ok) form = { ...form, soLuong: '', donGia: '' };
	}

	const duyet = (id: string, dongY: boolean) =>
		goi(
			'mutation($id: UUID, $dy: Boolean, $gc: String) { carbonDuyetLenhBan(input: { lenhBanId: $id, dongY: $dy, ghiChu: $gc }) { result } }',
			{ id, dy: dongY, gc: lyDo[id] || null }
		);

	$effect(() => {
		void token;
		tai();
	});
	onDestroy(() => clearTimeout(hen));
</script>

<section class="vi" aria-labelledby="vi-td">
	<h2 id="vi-td">Ví tín chỉ</h2>
	<p class="tong">{tong} <span>tín chỉ, mỗi tín chỉ là 1 t CO₂e</span></p>
	{#if vi.length}
		<ul class="khoi">
			{#each vi as k (k.rowId)}
				<li><span class="sl">{k.soLuong}</span> <a href="/kiem-chung?q={k.seriTu}"><code>{k.seriTu}</code></a> đến <code>{k.seriDen.slice(-10)}</code></li>
			{/each}
		</ul>
	{/if}

	{#if laCanBo && tong > 0}
		<form onsubmit={taoLenh}>
			<h3>Bán tín chỉ</h3>
			<label class="o-nhap">
				Người mua
				<select bind:value={form.maNguoiMua} required>
					{#each nguoiMua as n (n.ma)}<option value={n.ma}>{n.ten}, tối đa {vnd(n.donGiaToiDaVnd)}</option>{/each}
				</select>
			</label>
			<div class="hang">
				<label class="o-nhap">Số tín chỉ <input bind:value={form.soLuong} inputmode="numeric" required /></label>
				<label class="o-nhap">Đơn giá (đ) <input bind:value={form.donGia} inputmode="numeric" required placeholder="200000" /></label>
			</div>
			<button class="nut rong" type="submit" disabled={dangGui}>Tạo lệnh bán</button>
			<p class="phu">Lệnh cần một cán bộ khác duyệt, theo Thông tư 11/2026/TT-BNNMT, Điều 6 khoản 3.</p>
		</form>
	{/if}
</section>

{#if loi}
	<div role="alert" class="loi"><b>{loi.thongBao}</b>{#if loi.goiY}<br />{loi.goiY}{/if}</div>
{/if}

{#if lenh.length}
	<section class="ds-lenh" aria-labelledby="lenh-td">
		<h2 id="lenh-td">Lệnh bán</h2>
		{#each lenh as l (l.rowId)}
			<article class="lenh" data-trang-thai={l.trangThai}>
				<header>
					<span>{l.soLuong} tín chỉ cho {nguoiMua.find((n) => n.ma === l.maNguoiMua)?.ten ?? l.maNguoiMua}</span>
					<span class="nhan {({ cho_duyet: 'cho', hoan_tat: 'tot', tu_choi: 'xau', loi: 'xau' } as Record<string, string>)[l.trangThai] ?? ''}">{TRANG_THAI[l.trangThai] ?? l.trangThai}</span>
				</header>
				<p class="phu">{vnd(l.donGiaVnd)} mỗi tín chỉ · tổng {vnd(l.thanhTienVnd)}{#if l.doToiTao} · bạn tạo{/if}</p>
				{#if l.lyDoLoi}<p class="loi">{l.lyDoLoi}</p>{/if}
				{#if l.ghiChuDuyet}<p class="phu">Ghi chú duyệt: {l.ghiChuDuyet}</p>{/if}
				{#if l.doltCommit}<p class="phu">Sổ cái <a href="/kiem-chung?q={l.doltCommit}"><code>{l.doltCommit.slice(0, 12)}…</code></a></p>{/if}
				{#if laCanBo && l.trangThai === 'cho_duyet' && !l.doToiTao}
					<label class="o-nhap">
						Ghi chú, bắt buộc khi từ chối
						<textarea bind:value={lyDo[l.rowId]} rows="2"></textarea>
					</label>
					<button type="button" class="nut rong" disabled={dangGui} onclick={() => duyet(l.rowId, true)}>Duyệt bán</button>
					<button type="button" class="chu xau" disabled={dangGui} onclick={() => duyet(l.rowId, false)}>Từ chối</button>
				{/if}
			</article>
		{/each}
	</section>
{/if}

<style>
	.vi,
	.ds-lenh {
		display: flex;
		flex-direction: column;
		gap: 14px;
		padding-top: 20px;
		border-top: 1px solid var(--ke);
	}
	h2 {
		font-size: 1.25rem;
	}
	h3 {
		font-size: 1.125rem;
	}
	.tong {
		color: var(--muc);
		font: 600 3.25rem/1 var(--serif);
		letter-spacing: -0.03em;
	}
	.tong span {
		color: var(--mo);
		font: 400 0.9375rem var(--sans);
		letter-spacing: 0;
	}
	.khoi {
		display: grid;
		margin: 0;
		padding: 0;
		list-style: none;
		overflow-wrap: anywhere;
	}
	.khoi li {
		padding: 10px 0;
		border-bottom: 1px solid var(--ke);
	}
	.khoi a {
		color: var(--teal);
	}
	.sl {
		display: inline-grid;
		place-items: center;
		min-width: 36px;
		height: 28px;
		margin-right: 6px;
		border-radius: 999px;
		background: var(--teal-nhat);
		color: var(--teal);
		font-weight: 600;
	}
	code {
		font-size: 0.85em;
	}
	form {
		display: grid;
		gap: 12px;
		padding: 18px;
		border-radius: 18px;
		background: var(--giay);
	}
	.hang {
		display: grid;
		grid-template-columns: 1fr 1fr;
		gap: 12px;
	}
	.phu {
		color: var(--mo);
		font-size: 0.875rem;
	}
	.phu a {
		color: var(--teal);
	}
	.lenh {
		display: grid;
		gap: 10px;
		padding: 16px 0;
	}
	.lenh + .lenh {
		border-top: 1px solid var(--ke);
	}
	.lenh header {
		display: flex;
		justify-content: space-between;
		align-items: center;
		flex-wrap: wrap;
		gap: 8px 12px;
		color: var(--muc);
		font-weight: 500;
	}
	.chu {
		justify-self: center;
		min-height: 32px;
		padding: 0;
		border: 0;
		background: none;
		font: 500 0.9375rem var(--sans);
		text-decoration: underline;
		text-underline-offset: 0.25em;
		cursor: pointer;
	}
	.chu.xau {
		color: var(--xau);
	}
</style>
