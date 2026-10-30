<!-- SPDX-FileCopyrightText: 2026 CarbonFarm OS contributors -->
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->
<!--
	Trang kiểm chứng CÔNG KHAI (#38), không cần đăng nhập: nhập mã băm commit Dolt hoặc số sê-ri tín chỉ, xem bản ghi gốc
	trong sổ cái, SHA-256 tính lại có khớp không, và chuỗi sự kiện MRV → cấp → bán. Gọi /kiem-chung/api (chỉ đọc).
-->
<script lang="ts">
	import { onMount } from 'svelte';

	type BanGhi = {
		loai: string;
		ma_doi_tuong: string;
		commit: string;
		luc: string;
		sha256_so_cai: string;
		sha256_tinh_lai: string;
		sha256_khop: boolean;
		con_nguyen_ven: boolean;
		du_lieu: Record<string, unknown>;
	};
	type KetQua =
		| { kieu: 'commit'; commit: string; luc: string; thong_diep: string; ban_ghi: BanGhi[] }
		| { kieu: 'seri'; so_seri: string; chu_so_huu_theo_so_cai: { ten: string; ma_so_thue: string }; toan_ven: boolean; su_kien: BanGhi[] };

	const LOAI: Record<string, string> = {
		ket_qua_mrv: 'Đo từ vệ tinh, cán bộ đã duyệt',
		cap_tin_chi: 'Registry cấp tín chỉ',
		ban_tin_chi: 'Bán, chuyển quyền sở hữu'
	};

	let q = $state('');
	let kq = $state<KetQua | null>(null);
	let loi = $state('');
	let dangTra = $state(false);

	async function tra(e?: SubmitEvent) {
		e?.preventDefault();
		const v = q.trim();
		if (!v) return;
		const laSeri = v.includes('-');
		loi = '';
		kq = null;
		dangTra = true;
		history.replaceState(null, '', `?q=${encodeURIComponent(v)}`);
		try {
			const res = await fetch(`/kiem-chung/api/${laSeri ? 'seri' : 'commit'}/${encodeURIComponent(v)}`);
			const j = await res.json().catch(() => ({ loi: `Máy chủ trả mã ${res.status}` }));
			if (!res.ok) throw new Error(j.loi ?? `Máy chủ trả mã ${res.status}`);
			kq = { kieu: laSeri ? 'seri' : 'commit', ...j };
		} catch (err) {
			loi = (err as Error).message;
		} finally {
			dangTra = false;
		}
	}

	onMount(() => {
		q = new URLSearchParams(location.search).get('q') ?? '';
		if (q) tra();
	});

	const tom = (b: BanGhi) => {
		const d = b.du_lieu as Record<string, any>;
		if (b.loai === 'ket_qua_mrv') return `${d.co2e_tan} t CO₂e · tán ${d.dien_tich_tan_ha} ha · phương pháp ${d.pha_he?.phuong_phap}`;
		if (b.loai === 'cap_tin_chi') return `${d.so_luong_tin_chi} tín chỉ ${d.registry?.seri_tu} → ${d.registry?.seri_den} cho ${d.chu_so_huu?.ten}`;
		if (b.loai === 'ban_tin_chi') return `${d.so_luong} tín chỉ: ${d.ben_ban?.ten} → ${d.ben_mua?.ten}`;
		return b.ma_doi_tuong;
	};
	const dsBanGhi = $derived(kq ? (kq.kieu === 'seri' ? kq.su_kien : kq.ban_ghi) : []);
</script>

<svelte:head><title>Kiểm chứng tín chỉ · CarbonFarm OS</title></svelte:head>

<div class="trang">
<section class="mo" aria-labelledby="td">
	<header class="dau">
		<a class="ten" href="/">CarbonFarm OS</a>
		<nav aria-label="Trang chủ">
			<a href="/#cach-lam">Cách làm</a>
			<a href="/#phuong-phap">Phương pháp</a>
		</nav>
	</header>
	<div class="mo-giua">
		<div>
			<h1 id="td">Tra một tín chỉ trên sổ cái</h1>
			<p class="dan">
				Hệ thống tính lại SHA-256 của từng bản ghi và cho biết bản ghi còn nguyên vẹn hay không. Không cần tài khoản.
			</p>
		</div>
		<form onsubmit={tra}>
			<label class="o-nhap">
				Số sê-ri hoặc mã băm commit
				<input bind:value={q} placeholder="MCK-DM01-26-0000000001" autocomplete="off" spellcheck="false" />
			</label>
			<button class="nut rong" type="submit" disabled={dangTra}>{dangTra ? 'Đang tra…' : 'Kiểm chứng'}</button>
			{#if loi}<p role="alert" class="loi">{loi}</p>{/if}
		</form>
	</div>
</section>

<main>
	{#if kq}
		<section class="ket-luan" class:hong={kq.kieu === 'seri' && !kq.toan_ven} aria-labelledby="kl">
			{#if kq.kieu === 'seri'}
				<h2 id="kl">{kq.toan_ven ? 'Toàn vẹn.' : 'Có bản ghi không khớp.'}</h2>
				<p>
					Tín chỉ <code>{kq.so_seri}</code> thuộc <b>{kq.chu_so_huu_theo_so_cai.ten}</b> (mã số thuế
					{kq.chu_so_huu_theo_so_cai.ma_so_thue}), qua {kq.su_kien.length} bản ghi trên sổ cái.
				</p>
			{:else}
				<h2 id="kl">Một commit trên sổ cái.</h2>
				<p><code>{kq.commit}</code> · {kq.luc}<br />{kq.thong_diep}</p>
			{/if}
		</section>

		<section class="chuoi" aria-labelledby="chuoi-td">
			<h2 id="chuoi-td">Các bản ghi</h2>
			<ol>
				{#each dsBanGhi as b (b.commit + b.ma_doi_tuong)}
					<li>
						<div class="dong-dau">
							<h3>{LOAI[b.loai] ?? b.loai}</h3>
							<span class="nhan" class:tot={b.sha256_khop && b.con_nguyen_ven} class:xau={!b.sha256_khop || !b.con_nguyen_ven}>
								{b.sha256_khop && b.con_nguyen_ven ? 'SHA-256 khớp' : b.sha256_khop ? 'Đã bị sửa sau' : 'SHA-256 không khớp'}
							</span>
						</div>
						<p class="tom">{tom(b)}</p>
						<p class="phu">
							Commit <a href="?q={b.commit}" onclick={(e) => { e.preventDefault(); q = b.commit; tra(); }}><code>{b.commit}</code></a> · {b.luc}
						</p>
						<details>
							<summary>Bản ghi gốc (định danh người dùng đã ẩn)</summary>
							<p class="phu">SHA-256 sổ cái <code>{b.sha256_so_cai}</code><br />SHA-256 tính lại <code>{b.sha256_tinh_lai}</code></p>
							<pre><code>{JSON.stringify(b.du_lieu, null, 2)}</code></pre>
						</details>
					</li>
				{/each}
			</ol>
		</section>
	{/if}
</main>
</div>

<style>
	.trang {
		padding: 12px;
	}
	.mo {
		padding: 0 var(--le) clamp(48px, 6vw, 80px);
		border-radius: 24px 24px 64px 64px;
		background: var(--teal);
		color: #e4efec;
	}
	.dau {
		display: flex;
		align-items: center;
		gap: 24px;
		max-width: 1120px;
		min-height: 80px;
		margin: 0 auto;
	}
	.ten {
		color: #fff;
		font: 600 1.375rem var(--serif);
		letter-spacing: -0.02em;
		text-decoration: none;
	}
	.dau nav {
		display: flex;
		gap: 28px;
		margin-left: auto;
	}
	.dau nav a {
		color: #d3e4e0;
		font-size: 0.9375rem;
		text-decoration: none;
	}
	.dau nav a:hover {
		color: #fff;
	}
	.mo-giua {
		display: grid;
		grid-template-columns: minmax(0, 1fr) minmax(0, 0.9fr);
		gap: clamp(32px, 5vw, 72px);
		align-items: center;
		max-width: 1120px;
		margin: clamp(16px, 4vw, 48px) auto 0;
	}
	h1 {
		color: #fff;
		font-size: clamp(2.25rem, 4.6vw, 3.75rem);
		line-height: 1.06;
	}
	.dan {
		max-width: 44ch;
		margin-top: 20px;
		font-size: 1.125rem;
	}
	form {
		display: grid;
		gap: 14px;
		padding: 28px;
		border-radius: 28px;
		background: #fff;
	}
	main {
		max-width: 1120px;
		margin: 0 auto;
		padding: clamp(40px, 6vw, 80px) var(--le) 120px;
	}
	code {
		font-size: 0.85em;
		overflow-wrap: anywhere;
	}
	.ket-luan {
		display: grid;
		gap: 14px;
		padding: clamp(28px, 4vw, 48px);
		border-radius: 32px;
		background: var(--dao);
		color: #d6d5cf;
	}
	.ket-luan.hong {
		background: #5e1810;
	}
	.ket-luan h2 {
		color: #fff;
		font-size: clamp(2rem, 3.6vw, 3rem);
	}
	.ket-luan p {
		max-width: 60ch;
		font-size: 1.125rem;
	}
	.ket-luan b {
		color: #fff;
	}
	.ket-luan code {
		color: var(--amber);
	}
	.chuoi {
		padding-top: clamp(48px, 6vw, 80px);
	}
	.chuoi > h2 {
		margin-bottom: 20px;
		font-size: 1.75rem;
	}
	ol {
		display: grid;
		gap: 12px;
		margin: 0;
		padding: 0;
		list-style: none;
	}
	li {
		display: grid;
		gap: 10px;
		min-width: 0;
		padding: clamp(20px, 2.4vw, 32px);
		border-radius: 24px;
		background: #fff;
	}
	.dong-dau {
		display: flex;
		justify-content: space-between;
		align-items: center;
		gap: 16px;
	}
	h3 {
		font-size: 1.375rem;
	}
	.tom {
		color: var(--muc);
	}
	.phu {
		color: var(--mo);
		font-size: 0.875rem;
	}
	.phu a {
		color: var(--teal);
	}
	summary {
		color: var(--muc);
		font-size: 0.9375rem;
		font-weight: 500;
		cursor: pointer;
	}
	pre {
		max-height: 20rem;
		overflow: auto;
		margin: 12px 0 0;
		padding: 16px;
		border-radius: 14px;
		background: var(--giay);
		font-size: 0.8125rem;
	}
	@media (max-width: 860px) {
		.mo-giua {
			grid-template-columns: 1fr;
		}
	}
	@media (max-width: 640px) {
		.trang {
			padding: 8px;
		}
		.mo {
			border-radius: 20px 20px 40px 40px;
		}
		.dau nav {
			display: none;
		}
		form {
			padding: 22px;
		}
		.dong-dau {
			flex-direction: column;
			align-items: start;
			gap: 8px;
		}
	}
</style>
