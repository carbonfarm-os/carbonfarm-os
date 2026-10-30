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

<section class="vi" aria-label="Ví tín chỉ hợp tác xã">
	<h2>Ví tín chỉ: {tong} tín chỉ</h2>
	<ul class="khoi">
		{#each vi as k (k.rowId)}
			<li><b>{k.soLuong}</b> · <small>{k.seriTu} → {k.seriDen}</small></li>
		{/each}
	</ul>

	{#if laCanBo && tong > 0}
		<form onsubmit={taoLenh}>
			<label>
				Người mua
				<select bind:value={form.maNguoiMua} required>
					{#each nguoiMua as n (n.ma)}<option value={n.ma}>{n.ten} (tối đa {vnd(n.donGiaToiDaVnd)})</option>{/each}
				</select>
			</label>
			<div class="hang">
				<label>Số tín chỉ <input bind:value={form.soLuong} inputmode="numeric" required /></label>
				<label>Đơn giá (đ) <input bind:value={form.donGia} inputmode="numeric" required placeholder="200000" /></label>
			</div>
			<button type="submit" disabled={dangGui}>Tạo lệnh bán</button>
			<small>Lệnh cần một cán bộ khác duyệt (TT 11/2026/TT-BNNMT Điều 6 khoản 3).</small>
		</form>
	{/if}
</section>

{#if loi}
	<div role="alert" class="loi"><b>{loi.thongBao}</b>{#if loi.goiY}<br />{loi.goiY}{/if}</div>
{/if}

{#if lenh.length}
	<h2>Lệnh bán</h2>
	{#each lenh as l (l.rowId)}
		<article class="lenh" data-trang-thai={l.trangThai}>
			<header>
				<b>{l.soLuong} tín chỉ → {nguoiMua.find((n) => n.ma === l.maNguoiMua)?.ten ?? l.maNguoiMua}</b>
				<span class="nhan">{TRANG_THAI[l.trangThai] ?? l.trangThai}</span>
			</header>
			<small>{vnd(l.donGiaVnd)}/tín chỉ · {vnd(l.thanhTienVnd)}{#if l.doToiTao} · do bạn tạo{/if}</small>
			{#if l.lyDoLoi}<p class="loi">{l.lyDoLoi}</p>{/if}
			{#if l.ghiChuDuyet}<p><small>Ghi chú duyệt: {l.ghiChuDuyet}</small></p>{/if}
			{#if l.doltCommit}<p><small>Sổ cái: <a href="/kiem-chung?q={l.doltCommit}"><code>{l.doltCommit}</code></a></small></p>{/if}
			{#if laCanBo && l.trangThai === 'cho_duyet' && !l.doToiTao}
				<textarea bind:value={lyDo[l.rowId]} rows="2" placeholder="Ghi chú (bắt buộc khi từ chối)"></textarea>
				<div class="nut">
					<button type="button" disabled={dangGui} onclick={() => duyet(l.rowId, true)}>Duyệt bán</button>
					<button type="button" class="tu-choi" disabled={dangGui} onclick={() => duyet(l.rowId, false)}>Từ chối</button>
				</div>
			{/if}
		</article>
	{/each}
{/if}

<style>
	.vi {
		margin-bottom: 1rem;
		padding: 0.6rem 0.7rem;
		border-radius: 8px;
		background: #1b4332;
		color: #fff;
	}
	h2 {
		margin: 0 0 0.5rem;
		font-size: 1.1rem;
	}
	.khoi {
		margin: 0 0 0.5rem;
		padding-left: 1rem;
		font-size: 0.85rem;
		overflow-wrap: anywhere;
	}
	form {
		display: grid;
		gap: 0.4rem;
	}
	.hang {
		display: flex;
		gap: 0.5rem;
	}
	label {
		display: grid;
		gap: 0.2rem;
		font-size: 0.85rem;
		flex: 1;
	}
	input,
	select,
	textarea {
		font: inherit;
		padding: 0.3rem 0.45rem;
		border: 1px solid #b7c9b2;
		border-radius: 6px;
		background: #fff;
		color: #1b2b22;
		min-width: 0;
	}
	textarea {
		width: 100%;
		box-sizing: border-box;
		margin-top: 0.4rem;
	}
	.lenh {
		margin-bottom: 0.6rem;
		padding: 0.5rem 0.7rem;
		border: 1px solid #cfdccb;
		border-radius: 8px;
		background: #fff;
	}
	.lenh header {
		display: flex;
		justify-content: space-between;
		gap: 0.5rem;
	}
	.lenh p {
		margin: 0.3rem 0 0;
		overflow-wrap: anywhere;
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
	[data-trang-thai='hoan_tat'] .nhan {
		background: #1b4332;
		color: #fff;
	}
	[data-trang-thai='tu_choi'] .nhan,
	[data-trang-thai='loi'] .nhan {
		background: #fde2e1;
		color: #7a1c17;
	}
	.loi {
		padding: 0.5rem 0.7rem;
		border-radius: 6px;
		background: #fde2e1;
		color: #7a1c17;
	}
	.nut {
		display: flex;
		gap: 0.5rem;
		margin-top: 0.4rem;
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
	button.tu-choi {
		background: #f6c9c6;
		color: #7a1c17;
	}
	code {
		font-size: 0.75rem;
	}
</style>
